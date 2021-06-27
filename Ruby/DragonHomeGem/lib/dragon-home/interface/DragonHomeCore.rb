
require 'mqtt/sub_handler.rb'

require_relative '../hooks/HookHandler.rb'

require_relative 'Room.rb'
require_relative 'User.rb'

module XNM
    module DragonHome
        class Core < HookHandler
            attr_reader :users
            attr_reader :rooms

            def initialize(mqtt)
                super()

                @mqtt = mqtt;

                @users = {}
                @rooms = {}
            end

            def <<(new_obj)
                if(new_obj.is_a? User)
                    @users[new_obj.id] = new_obj

                    send_event :newUser, new_obj
                elsif(new_obj.is_a? Room)
                    @rooms[new_obj.id] = new_obj

                    send_event :newRoom, new_obj
                else
                    raise ArgumentError, "New object's type not recongized!"
                end
            end
        end
    end
end