
#include "hw.h"

namespace HW {
    extern Xasin::NeoController::Color ambient_recommendation;

	extern Xasin::NeoController::Color user_color;

	extern float ambient_brightness;

    void set_wakeup_lights(bool state = true);

    void light_tick();
    void cancel_fade();
}