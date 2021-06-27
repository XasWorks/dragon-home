

require_relative 'DragonCookie.rb'
require_relative '../conversation/ConversationOutput'


module XNM
    module DragonHome
        class ConversationCookie < Cookie
            include Conversation::Output

            NOTIFICATION_SOUNDS = {
                INFO: 'info_start.mp3',
                WORKING: 'working.mp3',
                WARN: 'warn_start.mp3'
            }

            attr_accessor :conversation_end_time
            attr_accessor :whistle_detected

            def initialize(mqtt, key)
                super(mqtt, key);

                init_conversation_output()

                @conversation_thread = Thread.new do
                    convo_thread
                end

                @conversation_thread.abort_on_exception = true

                @conversation_end_time = Time.at(0)
            end

            private def setup_warnmode()
                oHash = {
                    level: @current_conversation.level,
                    colour: @current_conversation.colour
                }
                
                self.warn_state = oHash
                
                case oHash[:level]
                when :INFO, :WORKING, :WARN
                    play_file File.join(File.dirname(__FILE__), "../sound_samples/#{NOTIFICATION_SOUNDS[oHash[:level]]}"), volume: 0.4
                end
            end

            private def handle_conversation(c_convo)
                setup_warnmode()

                loop do
                    speak_text c_convo.reply_data if c_convo.reply_data.is_a? Hash
                    c_convo.reply_data = nil

                    if c_convo.has_inquiry?
                        begin
                            record_file = get_recording();

                            jsgf = c_convo.inquiry_options[:jsgf];
                            parsed_text = `pocketsphinx_continuous -infile #{record_file} -logfn /dev/null #{(!jsgf.nil?) ? '-jsgf ' + jsgf : ''}`

                            c_convo.set_user_answer(parsed_text)

                            @conversation_callback&.call(c_convo)
                        ensure
                            File.delete record_file
                        end
                    else
                        break
                    end
                end
            end

            private def convo_thread()
                @conversation_thread_waiting = Thread.current

                loop do
                    Thread.stop() until (@whistle_detected || (!@conversation_queue.empty?() && (@sensor_data['pir_motion'] == 1)))

                    @current_conversation = next_conversation()

                    handle_conversation @current_conversation

                    if(@conversation_queue.empty?)
                        play_file File.join(File.dirname(__FILE__), '..', 'sound_samples', 'info_end.mp3'), volume: 0.4
                        self.warn_state = :IDLE

                        @current_conversation = nil;
                        @whistle_detected = false

                        @conversation_end_time = Time.now();
                    end
                end
            end
            
            private def update_sensor_data(data)
                super(data)
                
                @conversation_thread.run()
            end

            def on_convo_reply(&block)
                @conversation_callback = block;
            end

            def queue_conversation(convo)
                @current_conversation ||= convo
                super(convo)
            end

            def send_message(message, **opts)
                message = Conversation.to_convo(message, **opts)   
                queue_conversation(message);
            end
            def is_speaking?
                return !@current_conversation.nil?
            end
        end
    end
end