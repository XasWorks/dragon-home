
puts "Loading!"

$core.define_hook :bs_room do |h|
    on :setup do
        $core.rooms.each do |_id, r|
            if(r.is_occupied?)
                $core.users['xaseiresh'].room = r;
                break;
            end
        end
    end

    on :conversationReply do |msg|
        next unless msg.user

        if(msg.to_s =~ /good\s?night/i)
            msg.user.name = nil
        elsif(msg.to_s =~ /(\w+) switched in/i)
            msg.user.name = $1
        end
    end
    on :userAwakeChanged do |user|
        user.send_message(user.awake?() ? "Good morning, #{user.name}" : "Good night, #{user.name}")
    end
    on :userSwitched do |user|
        next unless user.awake?
        user.send_message "Hello #{user.name}!"
    end

    def recheck_user_pos()
        user = $core.users['xaseiresh']

        if(user.location['inregions']&.include?('Home :>'))
            if($core.rooms['main_room'].is_occupied?)
                user.room = $core.rooms['main_room']

                user.send_message("Welcome back home, #{user.name}") if user.hook_data[:was_away]
                user.hook_data[:was_away] = false
            else
                user.room = nil;
            end
        else
            user.room = nil;
            
            user.send_message("See you around, #{user.name}") if(!user.hook_data[:was_away])
            user.hook_data[:was_away] = true
        end
    end

    on :roomOccupancyChanged do |room|
        recheck_user_pos()
    end

    on :userLocationChanged do |user, oldRegions|
        recheck_user_pos()
    end

    on :conversationReply do |c|
        if(c.to_s =~ /(stop|start) dialing sequence/)
            $mqtt.publish_to "/esp32/WuffGate/3C.71.BF.0A.88.80/SetTarget", $1 == "stop" ? 0 : 7, retain: true

            c.reply "#{$1}ing dialing sequence!"
        end
    end
end