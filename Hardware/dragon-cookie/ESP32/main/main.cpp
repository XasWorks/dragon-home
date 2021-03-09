
#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "esp_spi_flash.h"
#include "nvs_flash.h"

#include "hw.h"

using namespace Xasin;
using namespace HW;

esp_err_t event_handler(void *context, system_event_t *event) {
	Xasin::MQTT::Handler::try_wifi_reconnect(event);

	return ESP_OK;
}

extern "C"
void app_main(void)
{
    nvs_flash_init();
    esp_event_loop_init(event_handler, nullptr);

    HW::init();

    HW::microphone.start();

    leds.colors.fill(NeoController::Color(Material::GREEN, 50)); 
    leds.update();

    while(true) {
        vTaskDelay(10);

        for(int i=0; i<6; i++)
        leds.colors[i] = i < (30 + HW::microphone.get_volume_estimate())/(5) ? Material::GREEN : 0;
        leds.update();
    }

    printf("Restarting now.\n");
    fflush(stdout);
    esp_restart();
}
