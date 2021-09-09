
#include <xnm/ble.h>
#include <xnm/property_point/BLEOutput.h>

#include "connectivity.h"

#include <xnm/net_helpers.h>

namespace CON {
	XNM::PropertyPoint::Handler propp;

	XNM::PropertyPoint::MQTTOutput propp_mqtt(propp, HW::mqtt);
	XNM::PropertyPoint::BLEOutput  propp_ble(propp, XNM::NetHelpers::ble);

	XNM::PropertyPoint::JSONObjProperty sensor_data(propp, "sensors");

	Property<Xasin::NeoController::Color> current_ambient_color(propp, "current_ambient", 0);
	Property<Xasin::NeoController::Color> user_color(propp, "user_light", 0);
	
	Property<int> light_mode(propp, "light_mode", -1);
	Property<int> light_source(propp, "light_source", 0);

	XNM::PropertyPoint::JSONObjProperty system_data(propp, "_system");

void init() {
	propp_mqtt.init();
	propp_ble.init();

	user_color.initialized = false;
	sensor_data.initialized = false;

	light_mode.initialized = false;
	light_source.initialized = false;

	current_ambient_color.readonly = true;
	sensor_data.readonly = true;

	user_color.on_update = []() {
		if(user_color.initialized)
			light_source.set_value(1);
	};

	user_color.init();
	sensor_data.init();
	light_mode.init();
	light_source.init();
	current_ambient_color.init();

	system_data.init();
}

}