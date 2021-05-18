

require_relative 'lib/dragon-home/hooks/HookHandler'
require_relative 'lib/dragon-home/conversation/TelegramConvoEndpoint'

require 'mqtt/sub_handler'
require_relative 'lib/dragon-home/interface/CookieRoom.rb'
require_relative 'lib/dragon-home/interface/DragonHomeCore.rb'

require_relative 'lib/dragon-home/misc/StargateAccessory.rb'

require 'xnm/telegram/Handler.rb'

require 'yaml'

$config = YAML.load(File.read('TestCFG.yaml'));

$mqtt = MQTT::SubHandler.new($config['MQTT_URI']);
$telegram = XNM::Telegram::Handler.new($config['TelegramToken']);

$home_core = XNM::DragonHome::Core.new($mqtt);

$cookie = XNM::DragonHome::ConversationCookie.new($mqtt, 'E0.E2.E6.56.14.D0');
$cookie_room = XNM::DragonHome::CookieRoom.new(:fstr_office, $home_core, $cookie)
$home_core << $cookie_room

$stargate = XNM::DragonHome::StargateAccessory.new($mqtt, '3C.71.BF.0A.88.80');
$cookie_room << $stargate

$test_user = XNM::DragonHome::User.new('xaseiresh', $home_core);

$tg_user = $telegram[$config['users']['xaseiresh']['tg_id']];
$tg_convo = XNM::Conversation::TelegramConversationEndpoint.new($tg_user, $home_core)

$test_user.conversation_outputs << $tg_convo
$test_user.room = $cookie_room

Thread.new do
sleep 15
$test_user.send_message("How are you doing?");
end

$home_core.define_hook :gate do |h|
    h.on :conversationReply do |c|
        if(c.to_s =~ /(stop|start) dialing sequence/)
            $mqtt.publish_to "/esp32/WuffGate/3C.71.BF.0A.88.80/SetTarget", $1 == "stop" ? 0 : 7, retain: true

            c.reply "#{$1}ing dialing sequence!"
        end
    end
end

$home_core.define_hook :tea_hook do |h|
    h.on :conversationReplyTea do |convo|
        convo.reply "Good, we're making some #{convo.to_s} tea";
    end

    h.on :conversationReply do |convo|
        if(convo.to_s =~ /i am making some (.*)tea/)
            convo.tag = :tea

            if($1 == '')
                convo.inquire("What kind of tea?", jsgf: 'TeaType.jsgf') { |c| $home_core.send_conversation(c) };
            else
                convo.reply "Good, we're making some #{$1} tea";
            end
        end
    end

    h.on :roomOccupancyChanged do
        if $cookie_room.is_occupied?
            $test_user.send_message("Welcome back!") 
        else
            $test_user.send_message("Goodbye :>");
        end
    end
end

$home_core.define_hook :random_hello do |h|
    h.on :conversationReply do |convo|
        case convo.to_s
        when /(disable|enable) ambient lights/
            $cookie.ambient_lights = ($1 == 'enable');

            convo.reply $1 + 'ing lights';
        else
            convo.reply("Right, you said #{convo.user_text}, correct?")
        end
    end
end

$base_topic = "/esp32/dragon-cookie/E0.E2.E6.56.14.D0/"

$whistle_lockout = Time.now();
$mqtt.subscribe_to $base_topic + "whistle_detect" do
    next if $cookie.is_speaking?
    next if (Time.now() - $cookie.conversation_end_time) < 1

    puts "got a whistle"

    convo = XNM::Conversation::BaseConversation.new()
    convo.inquire(nil, jsgf: 'Test.jsgf') { |c| $home_core.send_conversation(c) }
    
    $cookie.whistle_detected = true
    $cookie.send_message(convo);
end

require 'sinatra'

set :bind, '192.168.178.108'

post '/api/grafana/notifications' do
    data = request.body.read

    puts "Got request: #{data}"

    parsed = JSON.parse(data);

    msg = {};
    if(parsed['state'] == 'alerting')
        msg = {
            text: "Rule #{parsed['ruleName']} reports: " + parsed['message'],
            level: :WARN
        };
    elsif(parsed['state'] == 'ok')
        msg = {
            text: "Rule #{parsed['ruleName']} is back to normal.",
            level: :INFO
        }
    end

    $test_user.send_message(msg);

    return 'OK';
end