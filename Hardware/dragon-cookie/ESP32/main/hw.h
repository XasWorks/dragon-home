
#include "xasin/mqtt.h"
#include "xasin/neocontroller.h"

#include "xasin/audio.h"
#include "xasin/TrekAudio.h"

namespace HW {
	extern Xasin::NeoController::NeoController leds;
	extern Xasin::Audio::TX speaker;
	extern Xasin::Audio::RX microphone;

	void init();
}