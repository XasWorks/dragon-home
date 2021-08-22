
#include "indicators.h"

#include <cmath>

#include <cJSON.h>

namespace HW {
namespace IND {

using namespace Xasin;
using namespace NeoController;

ind_state_t state = IDLE;
const ind_state_t statelist[] = {IDLE, INFO, WORKING, WARN_DISCO, WARN_FLASH};


TickType_t notification_start = 0;
Color notification_color = Color(0, 0, 0);

Color overlay_color = Color(0, 0, 0);

Color get_default_idle_color() {
    if(HW::mqtt.is_disconnected() == 0)
        return Material::GREEN;
    else if(HW::mqtt.is_disconnected() == 1)
        return Material::ORANGE;
    
    return Material::PURPLE;
}

uint8_t get_current_indicator_brightness() {
    ind_state_t local_state = state;

    if(HW::transmit_audio)
        local_state = WORKING;

    switch(local_state) {
        default: return 0;
        case IDLE:
        case WORKING:
        case INFO: return 255 * HW::get_recommended_notification_brightness();
        case WARN_DISCO: return 100 + 155 * HW::get_recommended_notification_brightness();
        case WARN_FLASH: return 255;
    }
}

void tick() {
    Color speaker_color = Color(Material::PURPLE, std::min(255, std::max<int>(0, (150 * (HW::speaker.get_volume_estimate() + 30)) / 20)));
    speaker_color.bMod(255 * HW::get_recommended_notification_brightness());

    leds.colors.fill(speaker_color);

    overlay_color.merge_transition(Color(0, 0, 0), state == IDLE ? 2000 : 5000);

    ind_state_t local_state = state;
    Color local_notification_color = notification_color;

    if(HW::transmit_audio) {
        local_notification_color = Material::PURPLE;
        local_state = WORKING;
    }

    uint32_t indicator_ticks = xTaskGetTickCount() - notification_start;
    switch(local_state) {
    default: break;
    
    case IDLE: {
        Color idle_c = get_default_idle_color();
        idle_c.merge_overlay(local_notification_color);

        idle_c.bMod(160 * HW::get_recommended_notification_brightness());

        float ind_position = indicator_ticks / (5000.0F/portTICK_PERIOD_MS) * 20;
        for(int i=0; i<6; i++) {
            float dist = fabs(fmodf(ind_position - i, 20) - 3);
            float brightness = std::max<float>(0.0F, 1.0F - dist/2.0F);

            leds.colors[i].merge_overlay(idle_c, 255 * brightness);
        }
    }
    break;

    case INFO: {
        Color info_c = Material::GREEN;
        info_c.merge_overlay(local_notification_color);
        info_c.bMod(255.0F * HW::get_recommended_notification_brightness());

        float info_time = (indicator_ticks / (500.0F/portTICK_PERIOD_MS));

        for(int i=0; i<std::min<int>(3, ceilf(info_time)); i++) {
            Color fill_color = info_c;
            fill_color.bMod(255 * (0.7F + 0.3F * sinf(info_time + i)));

            leds.colors[i] = fill_color;
            leds.colors[5-i] = fill_color;
        }

        overlay_color = info_c;
        
        if(info_time < 4)
            overlay_color.alpha = 50 + 150 * (1 - fmodf(info_time, 1));
        else
            overlay_color.alpha = 255 * (0.5F + 0.1F * cosf(info_time - 5));
    }
    break;

    case WORKING: {
        Color work_c = Material::PURPLE;
        work_c.merge_overlay(local_notification_color);
        work_c.bMod(255 * HW::get_recommended_notification_brightness());

        float work_phase = 2 * M_PI * indicator_ticks / (3000.0F / portTICK_PERIOD_MS);
        float work_pos = 3.0F + 2.0F * sinf(work_phase);

        for(int i=0; i<6; i++)
            leds.colors[i].merge_overlay(work_c, std::min<int>(255, std::max<int>(0, 255 * (1.0F - fabsf(work_pos - i))/2.0F)));
   
        overlay_color = work_c;
        overlay_color.alpha = 255 * (0.5F + 0.15F * cosf(2*work_phase));
    }
    break;

    case WARN_DISCO: {
        Color warn_c = Material::ORANGE;
        warn_c.merge_overlay(local_notification_color);
        warn_c.bMod(100 + 155 * HW::get_recommended_notification_brightness());

        overlay_color = Color(0xBBBBBB, 255, 150);

        float ind_position = indicator_ticks / (1000.0F/portTICK_PERIOD_MS) * 6;
        for(int i=0; i<6; i++) {
            float dist = fmodf(ind_position - i, 6);
            float brightness = std::max<float>(0.0F, 1.0F - dist/3.5F);

            leds.colors[i].merge_overlay(warn_c, 255 * brightness);

            if(i == 0)
                overlay_color.merge_overlay(warn_c, ((indicator_ticks < (5000/portTICK_PERIOD_MS)) ? 255 : 100) * brightness);
        }
    }
    break;

    case WARN_FLASH: {
        Color warn_c = Material::RED;
        warn_c.merge_overlay(local_notification_color);

        static bool has_flashed = false;
        overlay_color = Color(0xBBBBBB);
        overlay_color.merge_overlay(warn_c, 150);
        overlay_color.alpha = 150;

        int anim_phase = (indicator_ticks) / (20) % 12;
        if((anim_phase & 1) == 0) {
            has_flashed = false;
            break;
        }
        else if(has_flashed)
            break;

        for(int i = (anim_phase <= 6) ? 0 : 1; i < 6; i +=2 )
            leds.colors[i] = warn_c;
        

        if(anim_phase <= 6)
            overlay_color.merge_overlay(warn_c, ((indicator_ticks < (5000/portTICK_PERIOD_MS)) ? 255 : 100));

        has_flashed = true;
    }
    break;

    case DRAMATIC: {
        Color warn_c = Material::RED;
        warn_c.merge_overlay(local_notification_color);

        int anim_phase = (indicator_ticks) / (50) % 10;
        if((1<<anim_phase & 0b1001010010) == 0 || (indicator_ticks % 50 > 30))
            break;

        for(int i = (anim_phase <= 5) ? 0 : 1; i < 6; i +=2 )
            leds.colors[i] = warn_c;

        if(anim_phase == 1)
            overlay_color = warn_c;
    }
    break;
    }
}

void set_indicator(const char *str) {
    cJSON * json = cJSON_Parse(str);
    
    if(json == nullptr || !cJSON_IsObject(json)) {
        set_indicator(IDLE);

        if(json)
            cJSON_Delete(json);
        
        return;
    }

    cJSON * item = cJSON_GetObjectItem(json, "colour");
    if(cJSON_IsString(item))
        notification_color = Color::strtoc(cJSON_GetStringValue(item));
    else
        notification_color = Color(0, 0, 0);

    item = cJSON_GetObjectItem(json, "state");
    if(cJSON_IsNumber(item))
        state = static_cast<ind_state_t>(std::max<int>(OFF, std::min<int>(IND_MAX-1, item->valueint)));

    if(!cJSON_IsTrue(cJSON_GetObjectItem(json, "no_reset")))
        notification_start = xTaskGetTickCount();

    cJSON_Delete(json);
}
void set_indicator(ind_state_t next_state) {
    state = static_cast<ind_state_t>(std::max<int>(OFF, std::min<int>(IND_MAX-1, next_state)));
    
    notification_start = xTaskGetTickCount();
    notification_color = Color(0, 0, 0);
}

void init() {
    HW::mqtt.subscribe_to("notification/set", [](Xasin::MQTT::MQTT_Packet data) {
        set_indicator(data.data.data());
    });
}

}
}