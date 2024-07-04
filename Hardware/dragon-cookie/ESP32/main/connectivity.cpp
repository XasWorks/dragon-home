
#include <xnm/ble.h>
#include <xnm/property_point/BLEOutput.h>

#include "connectivity.h"

#include "light_handler.h"

#include <xnm/net_helpers.h>

namespace CON {
	XNM::PropertyPoint::Handler & propp = XNM::NetHelpers::propp;

	XNM::PropertyPoint::JSONObjProperty sensor_data(propp, "sensors");

	Property<Xasin::NeoController::Color> current_ambient_color(propp, "current_ambient", 0);

	XNM::PropertyPoint::CustomProperty light_config(propp, "lights");


cJSON * light_config_get() {
	auto out = cJSON_CreateObject();

	cJSON_AddItemToObjectCS(out, "user_color", 
		cJSON_CreateString(HW::user_color.to_s().c_str()));
	
	if(HW::ambient_brightness == 0)
		cJSON_AddItemToObjectCS(out, "brightness", cJSON_CreateFalse());
	else if(HW::ambient_brightness == -1)
		cJSON_AddItemToObjectCS(out, "brightness", cJSON_CreateTrue());
	else
		cJSON_AddItemToObjectCS(out, "brightness", cJSON_CreateNumber(HW::ambient_brightness));

	return out;
}

void light_config_set(const cJSON * in) {
	cJSON * item = cJSON_GetObjectItem(in, "brightness");

	if(cJSON_IsTrue(item))
		HW::ambient_brightness = -1;
	else if(cJSON_IsFalse(item))
		HW::ambient_brightness = 0;
	else if(cJSON_IsNumber(item))
		HW::ambient_brightness = item->valuedouble;

	item = cJSON_GetObjectItem(in, "user_color");
	if(cJSON_IsNumber(item))
		HW::user_color = Xasin::NeoController::Color::Temperature(item->valueint);
	else if(cJSON_IsFalse(item))
		HW::user_color.alpha = 0;
	else if(cJSON_IsString(item))
		HW::user_color = Xasin::NeoController::Color::strtoc(item->valuestring);

	item = cJSON_GetObjectItem(in, "wakeup");
	if(cJSON_IsTrue(item) || cJSON_IsFalse(item))
		HW::set_wakeup_lights(cJSON_IsTrue(item));

	light_config.poke_update();
}

void init() {
	light_config.on_process   = light_config_set;
	light_config.on_get_state = light_config_get;

	light_config.initialized = false;
	light_config.init();

	sensor_data.init();
	current_ambient_color.init();
}

}