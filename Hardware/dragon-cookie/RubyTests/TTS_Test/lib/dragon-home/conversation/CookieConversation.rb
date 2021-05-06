
require_relative 'BaseConversation'
require_relative '../cookie/DragonCookie'

module XNM
    module DragonHome
        class CookieConversation < BaseConversation
            NOTIFICATION_SOUNDS = {
                INFO: 'info_start.mp3',
                WORKING: 'working.mp3',
                WARN: 'warn_start.mp3'
            }

            def initialize(config, cookie)
                super(config);

                @cookie = cookie;
            end

            def recording_done(filename)
                @cookie_record_fname = filename;
                @conversation_thread.run();
            end

            private def setup_warnmode()
                @config[:level] ||= :INFO
                
                @cookie.warn_state = @config
                
                case @config[:level]
                when :INFO, :WORKING, :WARN
                    precursor = OpusStream::FileSource.new(File.join(File.dirname(__FILE__), '..', 'sound_samples', NOTIFICATION_SOUNDS[@config[:level]]));
                    
                    precursor.on_finish do
                        @conversation_thread.run
                    end
                    
                    @cookie.speaker << precursor

                    Thread.stop() until precursor.is_done?
                end
            end

            def reply(text)
                raise ConversationClosedError if @closed

                tts_cfg = {
                    ttsfile: "/tmp/dragoncookie-msg-#{SecureRandom.uuid}.wav",
                    text: text
                }
                TTSGen::generate_tts(tts_cfg);
            
                @current_audio_source = OpusStream::FileSource.new(tts_cfg[:ttsfile]);
                File.delete(tts_cfg[:ttsfile]);

                @current_audio_source.on_finish { @conversation_thread.run() };
                @cookie.speaker << @current_audio_source

                Thread.stop() until @current_audio_source.is_done?
            end

            def get_user_input()
                @cookie_record_fname = nil;

                sleep 0.5
                
                @cookie.recording = true
                Thread.stop while @cookie_record_fname.nil?

                text = `pocketsphinx_continuous -infile #{@cookie_record_fname} -logfn /dev/null -jsgf Test.jsgf`
            
                File.delete(@cookie_record_fname)
                @cookie_record_fname = nil;

                return text;
            end

            private def run_conversation_thread()
                begin
                    setup_warnmode();

                    text = @config[:text]
                    reply(text) if(text.is_a? String)

                    @config[:conversation_block]&.call(self);
                rescue ConversationClosedError
                ensure
                    @current_audio_source&.stop
                end

                @closed = true

                @cookie.next_conversation
            end

            private def run_conversation()
                @cookie.warn_mode 
            end

            def close!()
                @current_audio_source&.stop()

                super();
            end
        end
    end
end