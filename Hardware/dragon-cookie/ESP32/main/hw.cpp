
#include "pins.h"
#include "hw.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#include <driver/ledc.h>

#include <math.h>

#include <esp_log.h>

namespace HW {
	Xasin::MQTT::Handler mqtt;

	Xasin::NeoController::NeoController leds(GPIO_NUM_23, RMT_CHANNEL_0, 7);
	Xasin::Audio::TX speaker;
	Xasin::Audio::RX microphone(0);

	void audio_processing_loop(void *args) {
		static int mic_dbg_presc = 0;

		while (true)
		{
			xTaskNotifyWait(0, 0, nullptr, portMAX_DELAY);

			speaker.largestack_process();

			while(microphone.has_new_audio()) {
				// if(mic_dbg_presc++ % 2 == 0) {
				// 	char bar_buffer[67] = {};
				// 	bar_buffer[0] = '[';
				// 	bar_buffer[65] = ']';
				// 	bar_buffer[66] = '\0';

				// 	auto ac = microphone.get_goertzel(1200) * 100;

				// 	for(int i=0; i<64; i++) {
				// 		if(ac > (i)/64.0F)
				// 			bar_buffer[i+1] = '#';
				// 		else
				// 			bar_buffer[i+1] = ' ';
				// 	}

				// 	ESP_LOGI("Audio", "Autocorrelation is %1.8f %s", ac, bar_buffer);
				// }

				auto bfr = microphone.get_buffer();

				// if(!mqtt.is_disconnected())
				// 	mqtt.publish_to("/tmp/AUDIO_COOKIE", bfr.data(), 20);
			}
		}
	}

	void init_gpios() {
		gpio_set_direction(HW_PIN_MIC_PWR, GPIO_MODE_OUTPUT);
		gpio_set_drive_capability(HW_PIN_MIC_PWR, GPIO_DRIVE_CAP_3);

		gpio_pulldown_en(GPIO_NUM_17);

		gpio_set_direction(HW_PIN_IR_OUT, GPIO_MODE_OUTPUT);
		gpio_set_level(HW_PIN_IR_OUT, false);

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
				1 << 5,
				0,
			};

			ledc_channel_config(&channel_cfg);
		} 
	}

#define RGBWWSET(value, ch) ledc_set_duty_and_update(LEDC_HIGH_SPEED_MODE, static_cast<ledc_channel_t>(ch), ((1<<11) - 1) * std::max(0.0F, std::min(1.0F, powf(value,2))), 0xFFFFF)
	void set_rgbww(float r, float g, float b, float ww) {
		RGBWWSET(r, 0);
		RGBWWSET(g, 1);
		RGBWWSET(b, 2);
		RGBWWSET(ww, 3);
	}

	void set_rgbww(Xasin::NeoController::Color color) {
		float max_w_count = std::min<float>(65025, color.g / (0.8F));
		max_w_count = std::min<float>(color.r, max_w_count);
		max_w_count = std::min<float>(color.b / (0.5F), max_w_count);

		color.g -= max_w_count * (0.35F);
		color.r -= max_w_count * 0.6F;
		color.b -= max_w_count * 0.2F;

		set_rgbww(color.r / (0.8F * 65025.0F), color.g / (0.8F * 65025.0F), color.b / (0.8F * 65025.0F), max_w_count / 65025);
	}

	void init() {
		init_gpios();

		TaskHandle_t processing_handle;
		xTaskCreatePinnedToCore(audio_processing_loop, "Audio", 32768, nullptr, 10, &processing_handle, 1);

		i2s_pin_config_t speaker_tx_cfg = HW_PINS_AUDIO_TX;
		speaker.init(processing_handle, speaker_tx_cfg);
	
		i2s_pin_config_t microphone_cfg = HW_PINS_AUDIO_RX;
		microphone.init(processing_handle, microphone_cfg);
		microphone.gain = 15*255;

		gpio_set_level(HW_PIN_MIC_PWR, true);

		vTaskDelay(100);

	    mqtt.start("mqtts://xaseiresh.hopto.org");

		Xasin::Trek::init(speaker);
		Xasin::Trek::play(Xasin::Trek::PROG_DONE);
	}

}
