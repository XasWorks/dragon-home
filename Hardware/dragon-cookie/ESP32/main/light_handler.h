
#include "hw.h"

namespace HW {
    extern Xasin::NeoController::Color ambient_recommendation;

	extern Xasin::NeoController::Color ambient_override;
	extern bool ambient_on;

    void light_tick();

    void init_ambient_mqtt();
    void cancel_fade();
}