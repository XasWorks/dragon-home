
#include "pins.h"
#include "hw.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

namespace HW {
	Xasin::NeoController::NeoController leds(GPIO_NUM_23, RMT_CHANNEL_0, 7);
	Xasin::Audio::TX speaker;
	Xasin::Audio::RX microphone(0);

	void audio_processing_loop(void *args) {
		static int mic_dbg_presc = 0;

		while (true)
		{
			xTaskNotifyWait(0, 0, nullptr, portMAX_DELAY);
			speaker.largestack_process();
			if(microphone.has_new_audio()) {
				auto bfr = microphone.get_buffer().data();
				
				if(mic_dbg_presc++ % 10 == 0) {
					printf("Volume is %f\n", microphone.get_volume_estimate());
					for(int i=0; i<10; i++)
						printf("%+05d ", bfr[i]);
				}
			}
		}
	}

	void init() {
		TaskHandle_t processing_handle;
		xTaskCreate(audio_processing_loop, "Audio", 32768, nullptr, 5, &processing_handle);

		i2s_pin_config_t speaker_tx_cfg = HW_PINS_AUDIO_TX;
		speaker.init(processing_handle, speaker_tx_cfg);
	
		i2s_pin_config_t microphone_cfg = HW_PINS_AUDIO_RX;
		microphone.init(processing_handle, microphone_cfg);

		Xasin::Trek::init(speaker);
		Xasin::Trek::play(Xasin::Trek::PROG_DONE);

		gpio_set_direction(HW_PIN_MIC_PWR, GPIO_MODE_OUTPUT);
		gpio_set_drive_capability(HW_PIN_MIC_PWR, GPIO_DRIVE_CAP_3);

		gpio_pulldown_en(GPIO_NUM_17);

		gpio_set_level(HW_PIN_MIC_PWR, true);
	}

}