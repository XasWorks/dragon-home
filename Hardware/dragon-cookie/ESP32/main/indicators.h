
#pragma once

#include "hw.h"

namespace HW {
namespace IND {

    extern Xasin::NeoController::Color overlay_color;

    enum ind_state_t {
        OFF,
        IDLE,
        
        INFO,
        WORKING,

        WARN_DISCO,
        WARN_FLASH,

        DRAMATIC,

        IND_MAX
    };

    extern ind_state_t state;

    uint8_t get_current_indicator_brightness();

    void tick();
    void init();

    void set_indicator(ind_state_t state);
    void set_indicator(const char *json_ptr);
}
}