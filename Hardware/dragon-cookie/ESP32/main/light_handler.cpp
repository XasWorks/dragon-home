
#include "hw.h"

#include <time.h>
#include <xasin/neocontroller.h>

#include <esp_log.h>
#include <cmath>

#include "indicators.h"

#include "connectivity.h"

using namespace Xasin;
using namespace NeoController;

namespace HW {
    Color ambient_smoothing = 0;
    Color ambient_recommendation = 0;

    Color user_color = 0xFF000000;
    float ambient_brightness = -1;

    uint8_t ambient_fade_speed = 5;

    TickType_t wakeup_light_start = 0;

    void set_wakeup_lights(bool state) {
        wakeup_light_start = state ? xTaskGetTickCount() : 0;
    }

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

    uint8_t get_current_light_bmod() {
        int brightness = std::max<int>(-1, std::min<int>(255, 255*ambient_brightness));

        if(brightness == -1) {
            brightness = std::max(0, std::min<int>(255, 255 - (255 * (HW::smoothed_lt_meas - 1500)) / 6000));

            if(!HW::room_occupied)
                brightness = 0;
        }
        
        return brightness;
    }

    Color get_current_daytime_rec() {
        time_t now;
        time(&now);

        struct tm timeinfo;
        localtime_r(&now, &timeinfo);

        float daytime = timeinfo.tm_sec / 3600.0F + timeinfo.tm_min / 60.0F + timeinfo.tm_hour;
        Color ambient_color = interpolate_color(daytime, daytime_profile);


        if(wakeup_light_start != 0) {
            float wakeup_time = ((xTaskGetTickCount() - wakeup_light_start)) / (60000.0F / portTICK_PERIOD_MS);
        
            if(wakeup_time < 10) {
                auto wake_color = Color::Temperature(std::min<float>(7000, 300+640*wakeup_time));

                ambient_color.merge_overlay(wake_color, 
                    std::max<int>(0, std::min<int>(255, 510 - 51.0F*wakeup_time)));
            }
        }

        return ambient_color;
    }

    Color get_current_ambient_rec() {
        Color ambient_color;
        
 
        ambient_color = get_current_daytime_rec();
        ambient_color.merge_overlay(user_color);

        ambient_color.bMod(get_current_light_bmod());

        return ambient_color;
    }

    void light_tick() {
        static TickType_t mqtt_tick = 0;
        static uint8_t last_indicator_brightness = 0;

        ambient_smoothing.merge_overlay(get_current_ambient_rec(), ambient_fade_speed);
        ambient_recommendation.merge_overlay(ambient_smoothing, ambient_fade_speed);

        if((xTaskGetTickCount() - mqtt_tick) > 300/portTICK_PERIOD_MS) {
            mqtt_tick = xTaskGetTickCount();

            CON::current_ambient_color.update_value(ambient_recommendation);
        }

        if(fabs(IND::get_current_indicator_brightness() - int(last_indicator_brightness)) > 10) {
            last_indicator_brightness = IND::get_current_indicator_brightness();

            mqtt.publish_int("notification/brightness", last_indicator_brightness, true, 1);
        }
    }

    void cancel_fade() {
        ambient_recommendation = get_current_ambient_rec();
        ambient_smoothing = ambient_recommendation;
    }
}