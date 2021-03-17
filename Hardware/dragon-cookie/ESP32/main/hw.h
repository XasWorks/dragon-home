
#include "xasin/mqtt.h"
#include "xasin/neocontroller.h"

#include "xasin/audio.h"
#include "xasin/TrekAudio.h"

namespace HW {
	extern Xasin::MQTT::Handler mqtt;

	extern Xasin::NeoController::NeoController leds;
	extern Xasin::Audio::TX speaker;
	extern Xasin::Audio::RX microphone;

	void set_rgbww(float r, float g, float b, float ww);
	void set_rgbww(Xasin::NeoController::Color color);

	void init();
}