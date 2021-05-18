
require_relative '../cookie/ConversationCookie.rb'
require_relative 'Room'

module XNM
    module DragonHome
        class CookieRoom < Room
            attr_reader :cookie

            def initialize(room_id, home_core, cookie)
                super(room_id, home_core)
                
                raise ArgumentError, "Cookie is not of correct type!" unless cookie.is_a? ConversationCookie

                @cookie = cookie
                @cookie.on_convo_reply { |convo| home_core.send_conversation convo }

                setup_sensor_update
            end

            private def setup_sensor_update
                @cookie.on_sensor_update do |new_sensors|

                    old_sensors = @sensor_values
                    @sensor_values = @cookie.sensor_data.clone
                                        
                    if(new_sensors.include? 'occupancy')
                        update_accessories :occupancy, is_occupied?
                        @home_core.send_event :roomOccupancyChanged, self      
                    end
                    
                    @home_core.send_event :roomSensorsUpdated, self, new_sensors
                end

                @cookie.on_indicator_brightness_change do |new_b|
                    @indicator_brightness = new_b
                    update_accessories :indicator_brightness, new_b
                end
            end

            def queue_conversation(convo)
                @cookie.queue_conversation convo
            end
            def dequeue_conversation(convo)
                @cookie.dequeue_conversation convo
            end

            def rate_conversation(convo)
                if(is_occupied?)
                    return 10
                else
                    return nil
                end
            end

            def is_occupied?
                return @cookie.occupancy
            end
        end
    end
end