
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'DragonHomeGem', 'lib'));

require 'yaml'

require 'mqtt/sub_handler'
require 'xnm/telegram/Handler.rb'

require 'dragon-home'

$config = YAML.load(File.read('config.yaml'));

$mqtt = MQTT::SubHandler.new($config['mqtt']);
$telegram = XNM::Telegram::Handler.new($config['telegram']);

$telegram.on_command 'start' do |msg|
    msg.send_message "Hi! Your chat id is: #{msg.user.chat_id}. Please pass this on to your local dragon technitian!"
end

$core = XNM::DragonHome::Core.new($mqtt);

sleep 0.5
puts "Loading rooms..."

$config['rooms'].each do |room_id, data|
    room = nil

    if(data.include? 'cookie_mac')
        cookie = XNM::DragonHome::ConversationCookie.new($mqtt, data['cookie_mac']);

        $mqtt.subscribe_to "/esp32/dragon-cookie/#{data['cookie_mac']}/whistle_detect" do
            convo = XNM::Conversation::BaseConversation.new()
            convo.inquire(nil, jsgf: 'voice.jsgf') { |c| $home_core.send_conversation(c) }
            
            cookie.whistle_detected = true
            cookie.send_message(convo);
        end

        room   = XNM::DragonHome::CookieRoom.new(room_id, $core, cookie);
    end

    next if room.nil?

    if(data.include? 'stargate_mac')
        $gate = XNM::DragonHome::StargateAccessory.new($mqtt, data['stargate_mac']);
        room << $gate
    end

    $core << room
end

sleep 0.5
puts "Loading users..."

$config['users'].each do |user_id, data|
    user = XNM::DragonHome::User.new(user_id, $core);

    user.apikey = data['apikey']

    if(data.include? 'tg_id')
        tg_user = $telegram[data['tg_id']];
        puts "TG User for #{user_id} is #{tg_user}"

        tg_convo = XNM::Conversation::TelegramConversationEndpoint.new(tg_user, $core, user);

        user.conversation_outputs << tg_convo
    end
    if(data.include? 'owntracks')
        $mqtt.subscribe_to data['owntracks'] do |data|
            begin
                data = JSON.parse(data)
            
                user.location = data if(data['_type'] == 'location')
            rescue
            end
        end
    end
end

$core.users['xaseiresh'].send_message('Script restarted');

at_exit {
    $core.users['xaseiresh'].send_message('DragonHome script exiting!');

    sleep 10
}

sleep 3

puts "Loading hooks..."

load 'hooks/bs_room_hook.rb'
load 'hooks/tea_hook.rb'
load 'hooks/comfy_messages.rb'
load 'hooks/jog_distance.rb'