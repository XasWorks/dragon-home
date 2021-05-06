
require 'securerandom'

require_relative '../audio/OpusStream.rb'
require_relative '../audio/Sphinx_Receiver.rb'

require_relative 'TTS_Generator.rb'

require_relative '../conversation/CookieConversation.rb'

module XNM
    module DragonHome
        class Cookie
            attr_reader :speaker
            attr_reader :microphone

            attr_reader :warn_state

            attr_reader :sensor_data

            attr_reader :recording

            attr_reader :ambient_lights

            WARN_STATES = {
                OFF: 0,
                IDLE: 1,
                INFO: 2,
                WORKING: 3,
                WARN: 4,
                ERROR: 5,
                ALERT: 5
            };

            NOTIFICATION_SOUNDS = {
                INFO: 'info_start.mp3',
                WORKING: 'working.mp3',
                WARN: 'warn_start.mp3'
            }

            def initialize(mqtt, key)
                @mqtt = mqtt;
                @key = key;

                @base_topic = "/esp32/dragon-cookie/#{key}/";

                @warn_state = :IDLE;
                @sensor_data = {};

                @message_queue   = Queue.new();
                @message_current = nil;

                @ambient_lights = false

                @speaker = XNM::OpusStream::Output.new() do |data|
                    unless(data.nil?)
                        @mqtt.publish_to @base_topic + "audio/play", data, qos: 0, retain: false
                    end
                end

                @microphone = XNM::OpusStream::Pocketsphinx_Input.new();
                
                setup_mqtt();

                setup_record_cb();
            end

            private def setup_record_cb()
                @microphone.on_record_done do |filename|
                    @message_current&.recording_done(filename);
                end
            end

            private def setup_mqtt()
                @mqtt.subscribe_to @base_topic + "audio/record" do |data|
                    @microphone.feed_packet data
                end

                @mqtt.subscribe_to @base_topic + "sensors" do |data|
                    begin
                        data = JSON.parse(data);
                        
                        @sensor_data.merge!(data);
                    rescue
                    end        
                end

                @mqtt.subscribe_to @base_topic + "audio/recording_silence" do 
                    self.recording = false;
                end

                @mqtt.subscribe_to @base_topic + 'AmbientOn' do |data|
                    @ambient_lights = (data == '1');
                end
            end

            def warn_state=(new_state)
                out_hash = {}

                if(new_state.is_a?(Hash))
                    out_hash = new_state
                    new_state = out_hash[:state] || out_hash[:level]
                end

                raise ArgumentError, "Next state is invalid!" unless WARN_STATES.include? new_state

                @warn_state = new_state;
                out_hash[:state] = WARN_STATES[@warn_state];

                @mqtt.publish_to @base_topic + 'notification/set', out_hash.to_json, 
                    qos: 1, 
                    retain: true
            end

            def ambient_lights=(new_lights)
                new_lights = new_lights ? true : false;

                return if new_lights == @ambient_lights;

                @ambient_lights = new_lights;
                
                @mqtt.publish_to @base_topic + 'AmbientOn', @ambient_lights ? '1' : '0', retain: true, qos: 1
            end

            def on_record_done(&block)
                @microphone.on_record_done(&block);
            end

            def start_recording(filename)
                self.recording = false if(@is_recording)

                @is_recording = true;

                @microphone.start_recording(filename)

                @mqtt.publish_to @base_topic + 'audio/set_recording', 'Y', qos: 1, retain: true;
            end

            def recording=(new_state)
                new_state = new_state ? true : false;

                return if(new_state == @is_recording)

                @is_recording = new_state; 

                if(@is_recording)
                    @microphone.start_recording
                else
                    @microphone.stop_recording
                end

                @mqtt.publish_to @base_topic + 'audio/set_recording', @is_recording ? 'Y' : 'N', qos: 1, retain: true;
            end

            def play_file(file)
                source = OpusStream::FileSource.new(file);
                
                th = Thread.current
                source.on_finish do
                    th.run 
                end

                @speaker << source

                Thread.stop until source.is_done?
            end

            def next_conversation()
                return if @message_current&.running?

                if(!@message_queue.empty?)
                    @message_current = CookieConversation.new(@message_queue.pop, self);
                elsif(!(@on_speech_done&.call()))
                    wrapup    = OpusStream::FileSource.new(File.join(File.dirname(__FILE__), '..', 'sound_samples', 'info_end.mp3'));
                    wrapup.on_finish do
                        self.warn_state = :IDLE
                    end

                    speaker << wrapup
                    @message_current = nil;
                end
            end

            def is_speaking?
                return !@message_current.nil?
            end
            def send_message(message)
                @message_queue << message
                next_conversation();
            end
        end
    end
end