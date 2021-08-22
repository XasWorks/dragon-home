
#pragma once

#include <cJSON.h>
#include <string>

#include "hw.h"

#include <xnm/property_point/BaseHandler.h>
#include <xnm/property_point/MQTTOutput.h>

#include <xnm/property_point/SingleProperty.h>
#include <xnm/property_point/JSONProperty.h>

namespace CON {
	extern XNM::PropertyPoint::Handler propp;
	extern XNM::PropertyPoint::MQTTOutput propp_output;

	template<class T>
	using Property = XNM::PropertyPoint::SingleProperty<T>;

	extern Property<Xasin::NeoController::Color> current_ambient_color;
	extern Property<Xasin::NeoController::Color> user_color;

	extern Property<int> light_mode;
	enum light_mode_t {
		OFF,
		AUTO,
		ON
	};

	extern Property<int> light_source;

	extern XNM::PropertyPoint::JSONObjProperty sensor_data;

	void init();
}