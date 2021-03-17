
#include <driver/gpio.h>
#include <vector>

#define HW_PIN_MIC_PWR	GPIO_NUM_25

#define HW_PIN_I2C_SDA	GPIO_NUM_2
#define HW_PIN_I2C_SCL	GPIO_NUM_4

#define HW_PIN_WS2812_OUT 	GPIO_NUM_23
#define HW_RMT_WS2812		RMT_CHANNEL_0
#define HW_PIN_IR_OUT	GPIO_NUM_15
#define HW_RMT_IR_OUT	RMT_CHANNEL_1
#define HW_PIN_IR_IN	GPIO_NUM_32
#define HW_RMT_IR_IN	RMT_CHANNEL_2

#define HW_PINS_AUDIO_TX {\
	GPIO_NUM_19, GPIO_NUM_21, GPIO_NUM_18, -1\
}

#define HW_PINS_AUDIO_RX { GPIO_NUM_16, GPIO_NUM_5, -1, GPIO_NUM_17 }

static const std::vector<gpio_num_t> HW_PINS_RGBW = { GPIO_NUM_26, GPIO_NUM_27, GPIO_NUM_14, GPIO_NUM_12 };