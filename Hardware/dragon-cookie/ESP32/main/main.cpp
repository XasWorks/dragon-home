
#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "esp_netif.h"
#include "esp_spi_flash.h"
#include "nvs_flash.h"

#include "light_handler.h"

#include <lwip/apps/sntp.h>

#include <math.h>
#include <string>

#include <xnm/net_helpers.h>

using namespace Xasin;
using namespace HW;

#include <esp_log.h>
#include <esp_http_client.h>

esp_err_t event_handler(void *context, system_event_t *event) {
	Xasin::MQTT::Handler::try_wifi_reconnect(event);
    HW::mqtt.wifi_handler(event);

	return ESP_OK;
}

void set_light_ktemp(float temperature) {
    static Xasin::NeoController::Color b1 = 0;
    static Xasin::NeoController::Color b2 = 0;

    Xasin::NeoController::Color c = Xasin::NeoController::Color::Temperature(temperature);

    b1.merge_overlay(c, 10);
    b2.merge_overlay(b1, 10);

    HW::set_rgbww(b2);
}

bool lights_enabled = true;
int whistle_count = 0;

void test_lights(void *arg) {
    NeoController::Color dl_overlay = NeoController::Color(0, 0, 0);

    TickType_t tick = xTaskGetTickCount();

    while(true) { 
        vTaskDelayUntil(&tick, 10);
        
        while(XNM::NetHelpers::OTA::get_state() == XNM::NetHelpers::OTA::DOWNLOADING) {
            vTaskDelayUntil(&tick, 150);

            for(int i=0; i<6; i++)
                leds.colors[i].merge_overlay(i == ((xTaskGetTickCount() / 150) % 6) ? Material::BLUE : 0, 200);
            
            leds.update();
            HW::set_rgbww(Material::BLUE);

            if(XNM::NetHelpers::OTA::get_state() == XNM::NetHelpers::OTA::REBOOT_NEEDED)
                esp_restart();
        }

        time_t now;
        struct tm timeinfo;
        time(&now);
        localtime_r(&now, &timeinfo);

        static float last_max = 0;
        const float g = microphone.get_goertzel(2540, 100) / 0.02F;
        if(g > 0.5) {
            whistle_count++;
            last_max = std::max(last_max, g);
        }
        else {
            if(whistle_count > 3)
                HW::ambient_on ^= 1;
            
            if(last_max > 0)
                ESP_LOGI("Audio", "Latest signal was, strongest: %f", last_max);
            
            last_max = 0;

            whistle_count = 0;
        }

        for(int i=0; i<6; i++)
            leds.colors[i] = NeoController::Color(Material::GREEN, 124 + 124 * sinf(xTaskGetTickCount()/1000.0F + 2 * M_PI / 6 * i));
        leds.update();

        HW::light_tick();

        auto buffer = HW::ambiant_recommendation;
        
        HW::set_rgbww(buffer);
    }
}

extern "C"
void app_main(void)
{
    nvs_flash_init();
    tcpip_adapter_init();
    esp_event_loop_create_default();
    
    esp_event_loop_init(event_handler, nullptr);

    setenv("TZ", "UTC-1", 1);
    tzset();

    HW::init();

    HW::microphone.start();

    Xasin::MQTT::Handler::start_wifi_from_nvs();

    XNM::NetHelpers::init_global_r3_ca();
    XNM::NetHelpers::set_mqtt(mqtt);
    XNM::NetHelpers::init();

    while(mqtt.is_disconnected())
        vTaskDelay(10);

    ESP_LOGI("XNM", "System restarted, device name is %s", XNM::NetHelpers::get_device_id().data());

    leds.colors.fill(NeoController::Color(Material::GREEN, 50)); 
    leds.update();

    xTaskCreatePinnedToCore(test_lights, "Lights", 4096, nullptr, configMAX_PRIORITIES - 2, nullptr, 1);

    while(true) { 
        vTaskDelay(100);
    }
}
