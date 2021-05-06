
#include "hw.h"

#include <time.h>
#include <xasin/neocontroller.h>

#include <esp_log.h>

using namespace Xasin;
using namespace NeoController;

namespace HW {
    Color ambient_smoothing = 0;
    Color ambient_recommendation = 0;

    Color ambient_override = Color(0, 0, 0);
    bool  ambient_on = true;

    uint8_t ambient_fade_speed = 5;

    struct lightprofile_t {
        float t;
        Color c;
    };

    static const std::vector<lightprofile_t> daytime_profile = {
        {0,     Color::Temperature(800)},
        {6,     Color::Temperature(800)},
        {7.5,   Color::Temperature(3500)},
        {9,     Color::Temperature(7500)},
        {11.5,  Color::Temperature(7500)},
        {12,    Color::Temperature(3900)},
        {13.3,  Color::Temperature(3400)},
        {13.5,  Color::Temperature(2800)},
        {13.9,  Color::Temperature(2800)},
        {14.1,  Color::Temperature(3900)},
        {16.5,  Color::Temperature(3900)},
        {17,    Color::Temperature(2800)},
        {17.8,  Color::Temperature(2800)},
        {18,    Color::Temperature(3800)},
        {20,    Color::Temperature(3400)},
        {22,    Color::Temperature(2500)},
        {22.75, Color::Temperature(1500)},
        {23.25, Color::Temperature(900)},
        {24,    Color::Temperature(800)}
    };

    Color interpolate_color(float time, const std::vector<lightprofile_t> &profile) {
        if(time < profile[0].t)
            return Color(0, 0, 0);
        if(time > profile[profile.size()-1].t)
            return Color(0, 0, 0);

        int i = 1;
        while(time >= profile[i].t)
            i++;


        time -= profile[i-1].t;
        time /= (profile[i].t - profile[i-1].t);

        return profile[i-1].c * (255 - 255*time) + profile[i].c * (255*time);
    }

    Color get_current_ambient_rec() {
        time_t now;
        time(&now);

        struct tm timeinfo;
        localtime_r(&now, &timeinfo);

        float daytime = timeinfo.tm_sec / 3600.0F + timeinfo.tm_min / 60.0F + timeinfo.tm_hour;
        Color ambient_color = interpolate_color(daytime, daytime_profile);

        ambient_color.bMod(std::max(0, std::min(255, 255 - (255 * (HW::lt303als.get_brightness().als_ch1 - 1500)) / 6000)));

        if((!ambient_on) || (!HW::room_occupied))
            ambient_color = 0;

        ambient_color.merge_overlay(ambient_override);
    
        return ambient_color;
    }

    void light_tick() {
        static TickType_t mqtt_tick = 0;

        ambient_smoothing.merge_overlay(get_current_ambient_rec(), ambient_fade_speed);
        ambient_recommendation.merge_overlay(ambient_smoothing, ambient_fade_speed);

        if((xTaskGetTickCount() - mqtt_tick) > 1000/portTICK_PERIOD_MS) {
            mqtt_tick = xTaskGetTickCount();

            char bfr[10] = {};
            snprintf(bfr, 10, "#%06X", ambient_recommendation.getPrintable());
            mqtt.publish_to("AmbientCurrent", bfr, strlen(bfr), 1);
        }
    }


    void init_ambient_mqtt() {
        mqtt.subscribe_to("AmbientSpeed", [](Xasin::MQTT::MQTT_Packet packet) {
            if(packet.data.size() == 0)
                ambient_fade_speed = 5;
            else
                ambient_fade_speed = strtol(packet.data.data(), nullptr, 10);
        });
        mqtt.subscribe_to("AmbientJump", [](Xasin::MQTT::MQTT_Packet packet) {
            ambient_smoothing      = Xasin::NeoController::Color::strtoc(packet.data.data());
            ambient_recommendation = ambient_smoothing;
        });
        mqtt.subscribe_to("AmbientOverride", [](Xasin::MQTT::MQTT_Packet packet) {
            ambient_override = Xasin::NeoController::Color::strtoc(packet.data.data());

            if(ambient_override.r == 0 && ambient_override.g == 0 && ambient_override.b == 0)
                ambient_override.alpha = 0;
        });
        mqtt.subscribe_to("AmbientOn", [](Xasin::MQTT::MQTT_Packet packet) {
            ambient_on = (packet.data == "1");
        });
        mqtt.subscribe_to("AmbientTemp", [](Xasin::MQTT::MQTT_Packet packet) {
            ambient_override = Xasin::NeoController::Color::Temperature(strtol(packet.data.data(), nullptr, 10));
        });
    }

    void cancel_fade() {
        ambient_recommendation = get_current_ambient_rec();
        ambient_smoothing = ambient_recommendation;
    }
}