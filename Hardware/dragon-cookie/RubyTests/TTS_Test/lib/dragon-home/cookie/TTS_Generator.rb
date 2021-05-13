

module XNM
    module DragonHome
        module TTSGen
            def self.generate_espeak(data)
                system('espeak', "-w#{data[:ttsfile]}", "\"#{data[:text]}\"")

                return data[:ttsfile];
            end

            def self.generate_dtalk(data)
                system('./say_demo_uk', '-fo', "#{data[:ttsfile]}", '-a', "[:dv ap 120][:dv pr 1] #{data[:text]}");
            
                return data[:ttsfile]
            end
            
            def self.generate_arctic(data)
                tmpfile = "/tmp/tts_txt_#{SecureRandom.uuid}"
                
                File.write(tmpfile, data[:text]);
	            system('text2wave', '-o', data[:ttsfile], '-eval', '(voice_cmu_us_slt_arctic_hts)', tmpfile)
            
                return data[:ttsfile]
            ensure
                File.delete(tmpfile)
            end

            def self.generate_tts(data)
                data[:ttsfile] ||= "/tmp/dragoncookie-msg-#{SecureRandom.uuid}.wav"

                case data[:tts_engine]
                when :dtalk
                    return generate_dtalk(data);
                when :arctic
                    return generate_arctic(data);
                else 
                    return generate_espeak(data);
                end
            end
        end
    end
end