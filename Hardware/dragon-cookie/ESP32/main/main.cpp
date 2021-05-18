
#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "esp_netif.h"
#include "esp_spi_flash.h"
#include "nvs_flash.h"

#include "light_handler.h"
#include "indicators.h"

#include <lwip/apps/sntp.h>

#include <math.h>
#include <string>

#include <xnm/net_helpers.h>

#include <cJSON.h>

using namespace Xasin;
using namespace HW;

#include <esp_log.h>
#include <esp_http_client.h>

esp_err_t event_handler(void *context, system_event_t *event) {
    HW::mqtt.wifi_handler(event);
	Xasin::MQTT::Handler::try_wifi_reconnect(event);

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
    TickType_t last_pir_tick = 0;

    static bool last_occupation = false;

    while(true) { 
        vTaskDelay(6);
        
        while(XNM::NetHelpers::OTA::get_state() == XNM::NetHelpers::OTA::DOWNLOADING) {
            vTaskDelayUntil(&tick, 150);

            for(int i=0; i<6; i++)
                leds.colors[i].merge_overlay(i == ((xTaskGetTickCount() / 150) % 6) ? Material::BLUE : 0, 120);
            
            leds.update();
            auto buffer = HW::ambient_recommendation;
            buffer.merge_overlay(Material::BLUE, 120);

            HW::set_rgbww(buffer);

            if(XNM::NetHelpers::OTA::get_state() == XNM::NetHelpers::OTA::REBOOT_NEEDED)
                esp_restart();
        }

        if(HW::is_motion_triggered()) {
            last_pir_tick = xTaskGetTickCount();
        }
        HW::room_occupied = (xTaskGetTickCount() - last_pir_tick) < (10*60*1000 / portTICK_PERIOD_MS);
        if(HW::room_occupied != last_occupation)
            mqtt.publish_to("sensors/occupancy", HW::room_occupied ? "1" : "0", 1, true, 1);
        last_occupation = HW::room_occupied;

        HW::IND::tick();
        
        leds.update();

        HW::light_tick();

        auto buffer = HW::ambient_recommendation;
        buffer.merge_overlay(HW::IND::overlay_color);
        
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

    setenv("TZ", "GMT-2", 1);
    tzset();

    Xasin::MQTT::Handler::set_nvs_uri("mqtt://192.168.178.230");
    Xasin::MQTT::Handler::set_nvs_wifi("TP-LINK_84CDC2", "f36eebda48");
    Xasin::MQTT::Handler::start_wifi_from_nvs();

    XNM::NetHelpers::init_global_r3_ca();
    XNM::NetHelpers::set_mqtt(mqtt);

    XNM::NetHelpers::init();

    HW::init();
    HW::IND::init();

    HW::microphone.start();

    HW::init_ambient_mqtt();

    // Connection start detection. 
    // Allows for offline use if it can not connect to the broker
    TickType_t start_tick = xTaskGetTickCount();
    while(mqtt.is_disconnected() && ((xTaskGetTickCount() - start_tick) < (20000/portTICK_PERIOD_MS)))
        vTaskDelay(10);

    XNM::NetHelpers::report_boot_reason();

    xTaskCreatePinnedToCore(test_lights, "Lights", 4096, nullptr, configMAX_PRIORITIES - 2, nullptr, 1);

    cJSON * sensor_data = cJSON_CreateObject();
    auto brightness_json = cJSON_AddNumberToObject(sensor_data, "ambient_brightness", 0);
    auto temp_json = cJSON_AddNumberToObject(sensor_data, "ambient_temp", 0);
    auto humid_json = cJSON_AddNumberToObject(sensor_data, "ambient_humidity", 0);
    auto airq_json = cJSON_AddNumberToObject(sensor_data, "ambient_air_q", 0);

    auto motion_sensor = cJSON_AddNumberToObject(sensor_data, "pir_motion", 0);

    while(true) { 
        vTaskDelay(6000);

        auto data = HW::lt303als.get_brightness();
        cJSON_SetNumberValue(brightness_json, data.als_ch1);

        HW::bme.force_measurement();
        vTaskDelay(100);

        HW::bme.fetch_data();
        cJSON_SetNumberValue(temp_json, HW::bme.get_temp());
        cJSON_SetNumberValue(humid_json, HW::bme.get_humidity());
        cJSON_SetNumberValue(airq_json, HW::bme.get_gas_res());

        cJSON_SetNumberValue(motion_sensor, HW::is_motion_triggered() ? 1 : 0);

        char * push_json = cJSON_Print(sensor_data);
        mqtt.publish_to("sensors", push_json, strlen(push_json));
        delete push_json;
    }
}
