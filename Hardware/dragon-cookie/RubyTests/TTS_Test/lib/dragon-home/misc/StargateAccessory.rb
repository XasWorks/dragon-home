
require_relative '../interface/Room.rb'

module XNM
    module DragonHome
        class StargateAccessory < RoomAccessory
            attr_reader :room
            
            def initialize(mqtt, key)
                @mqtt = mqtt;
                @base_topic = "/esp32/WuffGate/#{key}/";

                @indicator_brightness = 1;
                self.indicator_brightness = 255; 
            end

            def indicator_brightness=(b)
                b = [50, 255*b].max if(b > 0)

                new_brightness = [255, [b, 0].max].min
            
                return if new_brightness == @indicator_brightness
                @indicator_brightness = new_brightness

                @mqtt.publish_to @base_topic + "notificationBrightness", new_brightness, retain: true, qos: 1
            end

            def update_indicator_brightness()
                if(!@room.is_occupied?)
                    self.indicator_brightness = 0;
                else
                    self.indicator_brightness = @room.indicator_brightness
                end 
            end

            def room_update(type, *args)
                return if @room.nil?

                case type
                when :occupancy, :indicator_brightness
                    update_indicator_brightness
                end
            end

            def room=(new_room)
                @room = new_room

                update_indicator_brightness
            end
        end
    end
end