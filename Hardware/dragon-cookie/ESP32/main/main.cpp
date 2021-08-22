
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

#include "hw.h"

#include "connectivity.h"

using namespace Xasin;
using namespace HW;

#include <esp_log.h>
#include <esp_http_client.h>

#include <xnm/ble.h>

XNM::BLE::Server test_host;
XNM::BLE::BatService ble_battery(test_host);

esp_err_t event_handler(void *context, system_event_t *event) {
    HW::mqtt.wifi_handler(event);
	
    // Xasin::MQTT::Handler::try_wifi_reconnect(event);

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
        HW::fx_tick();

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
    // Initialize NVS — it is used to store PHY calibration data
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        ESP_ERROR_CHECK(nvs_flash_erase());
        ret = nvs_flash_init();
    }
    ESP_ERROR_CHECK(ret);
    
    // tcpip_adapter_init();

    esp_event_loop_create_default();
    
    esp_event_loop_init(event_handler, nullptr);
    
    ESP_LOGI("HEAP", "Heap free is: %d", esp_get_free_heap_size());

    setenv("TZ", "GMT-2", 1);
    tzset();

    XNM::NetHelpers::init_global_r3_ca();
    XNM::NetHelpers::set_mqtt(mqtt);

    XNM::NetHelpers::init();

    HW::init();
    HW::IND::init();

    CON::init();

    ble_battery.init();

    test_host.init();
    test_host.start_advertising();

    int i=0;
    char buffer[255] = {};
    while(true) {
        vTaskDelay(1000/portTICK_PERIOD_MS);

        snprintf(buffer, 254, "What about a really really long test message that is definitely more than 20 bytes? %d\n", i++);
    
        test_host.DBG_send_str(buffer);

        ble_battery.update_bat(100 - (i % 100));
    }

    // Connection start detection. 
    // Allows for offline use if it can not connect to the broker
    TickType_t start_tick = xTaskGetTickCount();
    while(true) {
        vTaskDelay(200/portTICK_PERIOD_MS);

        auto ota_state = XNM::NetHelpers::OTA::get_state();
        if(ota_state == XNM::NetHelpers::OTA::DOWNLOADING)
            continue;

        if(ota_state == XNM::NetHelpers::OTA::UP_TO_DATE)
            break;
        if(xTaskGetTickCount() - start_tick > (20000/portTICK_PERIOD_MS))
            break;
    }

    XNM::NetHelpers::report_boot_reason();

    xTaskCreatePinnedToCore(test_lights, "Lights", 4096, nullptr, configMAX_PRIORITIES - 2, nullptr, 1);

    cJSON * sensor_data = cJSON_CreateObject();
    auto motion_sensor = cJSON_AddNumberToObject(sensor_data, "pir_motion", 0);

    while(true) { 
        vTaskDelay(6000);

        XNM::NetHelpers::WIFI::housekeep_tick();

        HW::bme.force_measurement();
        vTaskDelay(100);

        HW::bme.fetch_data();
        CON::sensor_data.set_num(HW::bme.get_temp(), "ambient_temp");
        CON::sensor_data.set_num(HW::bme.get_humidity(), "ambient_humidity");
        CON::sensor_data.set_num(HW::bme.get_gas_res(), "ambient_air_q");

        CON::sensor_data.update_done();

        cJSON_SetNumberValue(motion_sensor, HW::is_motion_triggered() ? 1 : 0);

        char * push_json = cJSON_Print(sensor_data);
        mqtt.publish_to("sensors", push_json, strlen(push_json));
        delete push_json;
    }
}
