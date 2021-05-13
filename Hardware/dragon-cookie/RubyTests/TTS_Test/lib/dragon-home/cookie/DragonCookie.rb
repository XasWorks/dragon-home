
require 'securerandom'

require_relative '../audio/OpusStream.rb'
require_relative '../audio/Sphinx_Receiver.rb'

require_relative 'TTS_Generator.rb'

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

                self.ambient_lights = "#000000";
                @mqtt.publish_to @base_topic + 'audio/set_recording', 'N', retain: true, qos: 1
                @mqtt.publish_to @base_topic + 'notification/set', '', retain: true, qos: 1
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
                    out_hash = new_state.clone
                    new_state = out_hash[:level] || out_hash[:state]
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

            def speak_text(text, blocking: true)
                if(text.is_a? String)
                    tts_cfg = { text: text } 
                else
                    tts_cfg = text.clone
                end

                TTSGen::generate_tts(tts_cfg);
            
                @current_audio_source = OpusStream::FileSource.new(tts_cfg[:ttsfile]);
                File.delete(tts_cfg[:ttsfile]);
                
                @speaker << @current_audio_source

                return unless blocking

                th = Thread.current
                @current_audio_source.on_finish { th.run };

                Thread.stop() until @current_audio_source.is_done?
            end

            def play_file(file, blocking: true)
                @current_audio_source = OpusStream::FileSource.new(file);
                @speaker << @current_audio_source
                
                return @current_audio_file unless blocking

                th = Thread.current
                @current_audio_source.on_finish do
                    th.run 
                end

                Thread.stop until @current_audio_source.is_done?
            end

            def get_recording(filename = nil)
                filename ||= "/tmp/dragoncookie-recording-#{SecureRandom.uuid}.wav"

                recorded_name = nil;
                th = Thread.current
                
                @microphone.on_record_done do |fName|
                    puts "Done recording from inside sys!"
                    
                    recorded_name = fName;
                    th.run
                end
                
                start_recording(filename)

                Thread.stop() while recorded_name.nil?

                return recorded_name
            end
        end
    end
end