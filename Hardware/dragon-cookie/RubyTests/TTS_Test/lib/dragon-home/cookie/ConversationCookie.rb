

require_relative 'DragonCookie.rb'
require_relative '../conversation/Conversation.rb'


module XNM
    module DragonHome
        class ConversationCookie < Cookie
            NOTIFICATION_SOUNDS = {
                INFO: 'info_start.mp3',
                WORKING: 'working.mp3',
                WARN: 'warn_start.mp3'
            }

            attr_accessor :conversation_end_time

            def initialize(mqtt, key)
                super(mqtt, key);

                @conversation_queue = Queue.new();

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
                    play_file File.join(File.dirname(__FILE__), '..', 'sound_samples', NOTIFICATION_SOUNDS[oHash[:level]])
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

                            # TODO replace with a call to logging?
                            puts "Parsed text was: #{parsed_text}"

                            c_convo.set_user_answer(parsed_text)
                        ensure
                            File.delete record_file
                        end
                    else
                        break
                    end
                end
            end

            private def convo_thread()
                loop do
                    @current_conversation = @conversation_queue.pop()

                    handle_conversation @current_conversation
                    
                    if(@conversation_queue.empty?)
                        play_file File.join(File.dirname(__FILE__), '..', 'sound_samples', 'info_end.mp3')
                        self.warn_state = :IDLE

                        @current_conversation = nil;

                        @conversation_end_time = Time.now();
                    end
                end
            end
            
            def on_convo_reply(&block)
                @conversation_callback = block;
            end
            def send_message(message)
                if(message.is_a? String)
                    text = message;
                    message = Conversation::BaseConversation.new();
                    message.respond text
                elsif(message.is_a? Hash)
                    h = message
                    message = Conversation::BaseConversation.new();
                    message.level = h[:level] if h.include? :level
                    message.respond h[:text], **h
                end

                @conversation_queue << message;
            end
            def is_speaking?
                return !@current_conversation.nil?
            end
        end
    end
end