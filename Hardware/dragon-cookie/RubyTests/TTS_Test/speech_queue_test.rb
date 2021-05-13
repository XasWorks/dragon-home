

require_relative 'lib/dragon-home/hooks/HookHandler'
require_relative 'lib/dragon-home/conversation/TelegramConvoEndpoint'

require 'xnm/telegram/Handler.rb'

$telegram = XNM::Telegram::Handler.new("453888137:AAHV4-Z5egfGKanRaOqHLIQSkw_se2Q5JWQ");
$hook_core = XNM::DragonHome::HookHandler.new()


$tg_user = $telegram[87816854];
$tg_convo = XNM::Conversation::TelegramConversationEndpoint.new($tg_user)

$tg_convo.on_convo_reply do |convo| 
    $hook_core.send_conversation convo
end

$tg_user.send_message("How are you doing?", inline_keyboard: {"Good" => 'g', "Not good" => 'n'});

$hook_core.define_hook :gate do |h|
    h.on :conversationReply do |c|
        if(c.to_s =~ /(stop|start) dialing sequence/)
            $mqtt.publish_to "/esp32/WuffGate/3C.71.BF.0A.88.80/SetTarget", $1 == "stop" ? 0 : 7, retain: true

            c.reply "#{$1}ing dialing sequence!"
        end
    end
end

$hook_core.define_hook :tea_hook do |h|
    h.on :conversationReplyTea do |convo|
        convo.reply "Good, we're making some #{convo.to_s} tea";
    end

    h.on :conversationReply do |convo|
        if(convo.to_s =~ /i am making some (.*)tea/)
            convo.tag = :tea

            if($1 == '')
                convo.inquire("What kind of tea?", jsgf: 'TeaType.jsgf') { |c| $hook_core.send_conversation(c) };
            else
                convo.reply "Good, we're making some #{$1} tea";
            end
        end
    end
end

$hook_core.define_hook :random_hello do |h|
    h.on :conversationReply do |convo|
        case convo.to_s
        when /(disable|enable) ambient lights/
            $cookie.ambient_lights = ($1 == 'enable');

            convo.reply $1 + 'ing lights';
        else
            convo.inquire("Right, you said #{convo.user_text}, correct?") do |c|
                c.reply(c.user_text =~ /yes/ ? "Very good!" : "Sorry, nevermind then", tts_engine: :arctic);
            end
        end
        
    end
end

require 'mqtt/sub_handler'
require_relative 'lib/dragon-home/cookie/ConversationCookie.rb'

$mqtt = MQTT::SubHandler.new('192.168.178.230');

$cookie = XNM::DragonHome::ConversationCookie.new($mqtt, 'E0.E2.E6.56.14.D0');
$base_topic = "/esp32/dragon-cookie/E0.E2.E6.56.14.D0/"

$whistle_lockout = Time.now();
$mqtt.subscribe_to $base_topic + "whistle_detect" do
    next if $cookie.is_speaking?
    next if (Time.now() - $cookie.conversation_end_time) < 1

    puts "got a whistle"

    convo = XNM::Conversation::BaseConversation.new()
    convo.inquire(nil, jsgf: 'Test.jsgf') { |c| $hook_core.send_conversation(c) }

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

    $cookie.send_message(msg);

    return 'OK';
end