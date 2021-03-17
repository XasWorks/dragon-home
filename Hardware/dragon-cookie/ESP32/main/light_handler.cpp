
#include "hw.h"

#include <time.h>
#include <xasin/neocontroller.h>

#include <esp_log.h>

using namespace Xasin;
using namespace NeoController;

namespace HW {
    Color ambiant_recommendation = 0;

    Color ambient_override = Color(0, 0, 0);
    bool  ambient_on = true;

    struct lightprofile_t {
        float t;
        Color c;
    };

    static const std::vector<lightprofile_t> daytime_profile = {
        {0,     Color::Temperature(800)},
        {6,     Color::Temperature(800)},
        {7.5,   Color::Temperature(3000)},
        {9,     Color::Temperature(7500)},
        {11.5,  Color::Temperature(7500)},
        {12,    Color::Temperature(3500)},
        {13.3,  Color::Temperature(3000)},
        {13.5,  Color::Temperature(2500)},
        {13.9,  Color::Temperature(2500)},
        {14.1,  Color::Temperature(3500)},
        {16.5,  Color::Temperature(3500)},
        {17,    Color::Temperature(2300)},
        {17.8,  Color::Temperature(2300)},
        {18,    Color::Temperature(3000)},
        {22,    Color::Temperature(2300)},
        {22.75, Color::Temperature(1500)},
        {23.25, Color::Temperature(800)},
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

    void light_tick() {
        static Color b1 = 0;

        time_t now;
        time(&now);

        struct tm timeinfo;
        localtime_r(&now, &timeinfo);

        float daytime = timeinfo.tm_sec / 3600.0F + timeinfo.tm_min / 60.0F + timeinfo.tm_hour;
        Color ambient_color = interpolate_color(daytime, daytime_profile);

        ambient_color.merge_overlay(ambient_override);

        if(!ambient_on)
            ambient_color = 0;

        b1.merge_overlay(ambient_color, 3);
        ambiant_recommendation.merge_overlay(b1, 3);
    }
}