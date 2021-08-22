
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

    uint8_t get_current_light_bmod() {
        int brightness = std::max<int>(-1, std::min<int>(255, CON::light_mode.get_value()));

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

        return ambient_color;
    }

    Color get_current_ambient_rec() {
        Color ambient_color;
        
        int light_source = CON::light_source.get_value();
        if(light_source == 0)
            ambient_color = get_current_daytime_rec();
        else if(light_source == 1)
            ambient_color = CON::user_color.get_value();
        else
            ambient_color = Color::Temperature(light_source);

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