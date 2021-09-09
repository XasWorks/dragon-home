
#include <xasin/xai2c/LT303ALS.h>
#include <xasin/BME680.h>

#include "xasin/neocontroller.h"

#include "xasin/mqtt.h"

#include "xasin/audio.h"

namespace HW {
	extern Xasin::I2C::LT303ALS lt303als;
	extern float smoothed_lt_meas;
	
	extern Xasin::I2C::BME680   bme;

	extern Xasin::NeoController::NeoController leds;
	extern Xasin::MQTT::Handler & mqtt;

	extern Xasin::Audio::TX speaker;
	extern Xasin::Audio::RX microphone;

	extern bool room_occupied;
	extern bool transmit_audio;

	float get_recommended_notification_brightness();

	void set_rgbww(float r, float g, float b, float ww);
	void set_rgbww(Xasin::NeoController::Color color);

	void fx_tick();
	void init();

	bool is_motion_triggered();
}