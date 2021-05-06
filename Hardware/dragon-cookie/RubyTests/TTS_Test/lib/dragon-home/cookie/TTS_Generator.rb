

module XNM
    module DragonHome
        module TTSGen
            def self.generate_espeak(data)
                system('espeak', "-w#{data[:ttsfile]}", "\"#{data[:text]}\"")
            end

            def self.generate_tts(data)
                return generate_espeak(data);
            end
        end
    end
end