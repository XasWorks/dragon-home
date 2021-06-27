
require_relative '../conversation/ConversationOutput'

module XNM
    module DragonHome
        class RoomAccessory
            def room_update(tag, *args) end
        end

        class Room
            include Conversation::Output

            attr_reader :sensor_values

            attr_reader :indicator_brightness

            attr_reader :room_colour

            attr_reader :id

            def initialize(room_id, home_core)
                @id = room_id
                @home_core = home_core

                @sensor_values = {}
                @indicator_brightness = 0;

                @users = []
                @room_accessories = []
            end

            private def update_accessories(tag, *args)
                @room_accessories.each do |a|
                    a.room_update(tag, *args)
                end
            end

            def <<(new_thing)
                if(new_thing.is_a? RoomAccessory)
                    new_thing.room = self
                    @room_accessories << new_thing
                end
            end

            def is_occupied?
                return !@users.empty?
            end
        end
    end
end