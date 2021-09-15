
#include "pins.h"
#include "hw.h"

#include <MasterAction.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#include <xnm/net_helpers.h>

#include <driver/ledc.h>

#include <math.h>

#define LOG_LOCAL_LEVEL ESP_LOG_DEBUG
#include <esp_log.h>
#include <cJSON.h>

#include <esp_wn_iface.h>
#include <esp_wn_models.h>

#include <esp_agc.h>
#include <esp_ns.h>

void  print_memory_state();

namespace HW {
	Xasin::I2C::LT303ALS lt303als;
	float smoothed_lt_meas;
	
	Xasin::I2C::BME680   bme(0b1110111);

	Xasin::MQTT::Handler & mqtt = XNM::NetHelpers::mqtt; 

	Xasin::NeoController::NeoController leds(GPIO_NUM_23, RMT_CHANNEL_0, 7);
	Xasin::Audio::TX speaker;
	Xasin::Audio::RX microphone(0);

	bool room_occupied = false;

	Xasin::Audio::TXStream audio_tx_stream(speaker);
	bool transmit_audio     = false;
	int audio_silence_ticks = 0;

	// void *agc_handle = nullptr;
	// ns_handle_t ns_handle  = nullptr;

	int whistle_detect_ticks = 0;
	int whistle_detect_fail_ticks = 0;
	enum whistle_detect_stage_t {
		WAIT_WHISTLE_1,
		WAIT_WHISTLE_2
	} whistle_stage = WAIT_WHISTLE_1;

	void run_whistle_detec() {
		int wanted_tone = (whistle_stage == WAIT_WHISTLE_1) ? 800 : 1200;
				if(microphone.get_goertzel(wanted_tone, 160) > 0.0015) {
					whistle_detect_fail_ticks = std::max(0, whistle_detect_fail_ticks - 1);
					whistle_detect_ticks++;
				}
				else {
					if((whistle_detect_ticks >= 6) && (whistle_detect_ticks < 15)) {
						if(whistle_stage == WAIT_WHISTLE_2) {
							ESP_LOGI("Whistle", "Got one!");
							mqtt.publish_int("whistle_detect", 1);
						
							whistle_detect_ticks = 0;
							whistle_detect_fail_ticks = 0;
							whistle_stage = WAIT_WHISTLE_1;
						}
						else {
							whistle_detect_ticks = 0;
							whistle_detect_fail_ticks = 0;
							whistle_stage = WAIT_WHISTLE_2;
						}
					}
					else {
						if(whistle_detect_fail_ticks == 25) {
							whistle_stage = WAIT_WHISTLE_1;
							whistle_detect_ticks = 0;
						}

						if(whistle_detect_fail_ticks <= 25)
							whistle_detect_fail_ticks++;
					}
				}
	}

	void audio_processing_loop(void *args) {
		while (true)
		{
			xTaskNotifyWait(0, 0, nullptr, portMAX_DELAY);

			if(XNM::NetHelpers::OTA::get_state() == XNM::NetHelpers::OTA::DOWNLOADING) {
				microphone.get_buffer();
				continue;
			}

			speaker.largestack_process();

			while(microphone.has_new_audio()) {
				Xasin::Audio::rx_buffer_t b1 = microphone.get_buffer();
				Xasin::Audio::rx_buffer_t b2;
				Xasin::Audio::rx_buffer_t bfr = {};

				// ns_process(ns_handle, b1.data(), b2.data());
				// for(int i=0; i<3; i++) {
				// 	int ptr_shift = i*160;
				// 	esp_agc_process(agc_handle, b2.data() + ptr_shift, bfr.data() + ptr_shift, 160, 16000);
				// }

				if(transmit_audio)
					mqtt.publish_to("audio/record", bfr.data(), bfr.size() * 2);

				if(audio_silence_ticks < 50) {
					if((microphone.get_volume_estimate() > -18))
						audio_silence_ticks = 0;
					else
						audio_silence_ticks++;

					if(audio_silence_ticks >= 50)
						mqtt.publish_int("audio/recording_silence", 1);
				}
			}
		}
	}

	void init_gpios() {
		gpio_set_direction(HW_PIN_MIC_PWR, GPIO_MODE_OUTPUT);
		gpio_set_drive_capability(HW_PIN_MIC_PWR, GPIO_DRIVE_CAP_3);

		gpio_pulldown_en(GPIO_NUM_17);

		ledc_timer_config_t timer_cfg = {
			LEDC_HIGH_SPEED_MODE,
			LEDC_TIMER_11_BIT,

			LEDC_TIMER_0,

			16000,
			LEDC_AUTO_CLK
		};

		ledc_timer_config(&timer_cfg);
		ledc_fade_func_install(0);

		for(int i=0; i<4; i++) {
			ledc_channel_config_t channel_cfg = {
				HW_PINS_RGBW[i],
				LEDC_HIGH_SPEED_MODE,
				static_cast<ledc_channel_t>(i),
				LEDC_INTR_DISABLE,
				LEDC_TIMER_0,
				0,
				0,
			};

			ledc_channel_config(&channel_cfg);
		}

		XaI2C::MasterAction::init(HW_PIN_I2C_SDA, HW_PIN_I2C_SCL);

		gpio_set_direction(HW_PIN_IR_OUT, GPIO_MODE_OUTPUT);
		gpio_set_pull_mode(HW_PIN_IR_OUT, GPIO_PULLDOWN_ONLY);
		gpio_set_level(HW_PIN_IR_OUT, 0);
	}

	float get_recommended_notification_brightness() {
		return std::max<float>(0.15F, std::min<float>(1, (smoothed_lt_meas - 16) / 200.F));
	}

#define RGBWWSETNOSQR(value, ch) ledc_set_duty_and_update(LEDC_HIGH_SPEED_MODE, static_cast<ledc_channel_t>(ch), ((1<<11) - 1) * std::max(0.0F, std::min(1.0F, value)), 0xFFFFF)
#define RGBWWSET(value, ch) ledc_set_duty_and_update(LEDC_HIGH_SPEED_MODE, static_cast<ledc_channel_t>(ch), ((1<<11) - 1) * std::max(0.0F, std::min(1.0F, powf(value,2))), 0xFFFFF)
	void set_rgbww(float r, float g, float b, float ww) {
		RGBWWSET(r, 0);
		RGBWWSET(g, 1);
		RGBWWSET(b, 2);
		RGBWWSET(ww, 3);
	}

	void set_rgbww(Xasin::NeoController::Color color) {
		float r_sqr = powf(color.r/(255*255.0F), 2) * BR_SCALING_FACT;
		float g_sqr = powf(color.g/(255*255.0F), 2) * BR_SCALING_FACT;
		float b_sqr = powf(color.b/(255*255.0F), 2) * BR_SCALING_FACT;

		float max_w_count = 1;
		max_w_count = std::min<float>(max_w_count, r_sqr / RGBWW_R_FACT);
		max_w_count = std::min<float>(max_w_count, g_sqr / RGBWW_G_FACT);
		max_w_count = std::min<float>(max_w_count, b_sqr / RGBWW_B_FACT);

		r_sqr -= max_w_count * RGBWW_R_FACT;
		g_sqr -= max_w_count * RGBWW_G_FACT;
		b_sqr -= max_w_count * RGBWW_B_FACT;

		g_sqr *= GREEN_CALIB_FACT;
		b_sqr *= BLUE_CALIB_FACT;

		float downscale_fact = 1;
		if(r_sqr > 1)
			downscale_fact = std::min<float>(downscale_fact, 1/r_sqr);
		if(g_sqr > 1)
			downscale_fact = std::min<float>(downscale_fact, 1/g_sqr);
		if(b_sqr > 1)
			downscale_fact = std::min<float>(downscale_fact, 1/b_sqr);

		RGBWWSETNOSQR(r_sqr * downscale_fact, 0);
		RGBWWSETNOSQR(g_sqr * downscale_fact, 1);
		RGBWWSETNOSQR(b_sqr * downscale_fact, 2);
		RGBWWSETNOSQR(max_w_count * downscale_fact, 3);
	}

	void fx_tick() {
		smoothed_lt_meas = 0.992 * smoothed_lt_meas + 0.008 * HW::lt303als.get_brightness().als_ch1;
	}

	void init() {
		init_gpios();

		lt303als.init();
		bme.init_quickstart();

		TaskHandle_t processing_handle;
		xTaskCreatePinnedToCore(audio_processing_loop, "Audio", 30000, nullptr, 10, &processing_handle, 1);

		i2s_pin_config_t speaker_tx_cfg = HW_PINS_AUDIO_TX;
		speaker.init(processing_handle, speaker_tx_cfg);
		speaker.calculate_volume = true;
	
		i2s_pin_config_t microphone_cfg = HW_PINS_AUDIO_RX;
		microphone.init(processing_handle, microphone_cfg);
		microphone.gain = 200;

		gpio_set_level(HW_PIN_MIC_PWR, true);

		mqtt.subscribe_to("audio/play", [](Xasin::MQTT::MQTT_Packet data) {
			const int payload_len = data.data.size()-1;
			const uint8_t packet_count = *reinterpret_cast<const uint8_t*>(data.data.data());

			
			audio_tx_stream.feed_packets(
				reinterpret_cast<const uint8_t *>(data.data.data())+1, 
				payload_len/packet_count,
				packet_count);
		});
		mqtt.subscribe_to("audio/set_recording", [](Xasin::MQTT::MQTT_Packet data) {
			transmit_audio = (data.data == "Y");
			if(transmit_audio)
				audio_silence_ticks = -150;
		});

		audio_tx_stream.start(false);

		// agc_handle = esp_agc_open(3, 16000);
		// set_agc_config(agc_handle, 40, 1, -6);
		// ns_handle  = ns_create(30);

		microphone.start();

		vTaskDelay(100);
	}

	bool is_motion_triggered() {
		return gpio_get_level(GPIO_NUM_22);
	}
}
