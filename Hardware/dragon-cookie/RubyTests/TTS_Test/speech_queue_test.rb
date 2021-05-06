

require 'mqtt/sub_handler'
require_relative 'lib/dragon-home/conversation/CookieConversation.rb'

$mqtt = MQTT::SubHandler.new('192.168.178.230');

$cookie = XNM::DragonHome::Cookie.new($mqtt, 'E0.E2.E6.56.14.D0');
$base_topic = "/esp32/dragon-cookie/E0.E2.E6.56.14.D0/"

$whistle_lockout = Time.now();
$mqtt.subscribe_to $base_topic + "whistle_detect" do
    next if $cookie.is_speaking?
    next if (Time.now() - $whistle_lockout) < 3

    $cookie.send_message({
        conversation_block: Proc.new do |conv|
            conv.reply("Speak now:");

            txt = conv.get_user_input

            case txt
            when /i am making some (.*)tea/
                tea_type = $1;
                if(tea_type == "")
                    conv.reply("What kind of tea?");
                    
                    `play tea_earl_grey.mp3`

                    $cookie.send_message({
                        level: :WARN,
                        conversation_block: Proc.new do |conv|

                            $cookie.play_file("./systems_offline.mp3");

                            $whistle_lockout = Time.now();
                        end
                    });

                end
            else
                conv.reply "Did you say: #{txt}?"
                reply = conv.get_user_input
        
                puts "Reply was: #{reply}"
        
                if(reply =~ /yes/)
                    conv.reply "Ah, very good";
                else
                    conv.reply "Oh well."
                end
            end

            $whistle_lockout = Time.now();
        end,
        level: :INFO
    });
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