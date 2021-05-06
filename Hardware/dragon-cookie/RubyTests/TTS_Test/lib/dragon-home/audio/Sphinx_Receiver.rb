

require 'opus-ruby'
require 'numo/narray'

module XNM
    module OpusStream
        class Pocketsphinx_Input
            def initialize(bitrate: 16000, bitdepth: 16)
                @sox_io = nil;
                @current_file = nil;

                @on_record_done = nil;

                @bitdepth = bitdepth;
                @bitrate  = bitrate;
            end
        
            def feed_packet(raw_packet)
                return if @sox_io.nil?
                @sox_io.write(raw_packet);
            end

            def start_recording(filename = nil)
                stop_recording if (@sox_io)

                filename ||= "/tmp/dragoncookie-record-#{SecureRandom.uuid}.wav"
                @current_file = filename;
                
                @sox_io = IO.popen(['sox', '-c1', "-b#{@bitdepth}", "-r#{@bitrate}", 
                    '-traw', '-esigned', '-', '-twav', '-r16000', '-c1', '-b16', @current_file,
                    'noisered', 'noise.prof', '0.21'],
                    'w',
                    :external_encoding => 'ASCII-8BIT');
                @sox_io.binmode

                return @current_file
            end

            def on_record_done(&block)
                @on_record_done = block;
            end

            def stop_recording()
                return if @sox_io.nil?

                @sox_io.close();
                @sox_io = nil;

                @on_record_done&.call(@current_file);
                
                @current_file = nil;
            end
        end
    end
end