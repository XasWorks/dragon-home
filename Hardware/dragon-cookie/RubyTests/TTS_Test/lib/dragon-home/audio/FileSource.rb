
require_relative 'AudioSource'

module XNM
	module OpusStream
		class FileSource < AudioSource
			attr_reader :state

			attr_accessor :repeat
			attr_accessor :volume

			def initialize(filename)
				@state = :playing

				@fname = filename;

				sox_io = IO.popen(
					['sox', filename, '-r48000', '-c1',
						'-b16', '-esigned', '-traw', '-'],
						:external_encoding => 'ASCII-8BIT');
				sox_io.binmode

				@raw_data = Numo::Int16.from_string(sox_io.read);

				sox_io.close();

				@offset = 0;
				@repeat = false

				@on_finish = nil;

				@volume = 0.4;
			end

			def on_finish(&block)
				@on_finish = block;
			end

			def get_audio(samp_no = 48000 * 0.02)
				return nil if @state != :playing

				# We're reaching the end of the buffer. Empty that
				# and switch to 'off'
				if((@offset + samp_no) >= @raw_data.size())
					remaining_samples = @raw_data.size() - @offset

					o_data = Numo::SFloat.zeros(samp_no);
					o_data[0...remaining_samples] = @raw_data[@offset...(@offset + remaining_samples)];

					if(@repeat)
						@offset = 0;
					else
						@state = :finished

						@on_finish.call() unless @on_finish.nil?
					end

					o_data *= @volume if @volume
					o_data
				else
					o_data = @raw_data[@offset...(@offset + samp_no)]
					@offset += samp_no;

					o_data *= @volume if @volume
					o_data
				end
			end

			def has_audio?
				return @state == :playing
			end

			def is_done?
				return @state == :finished
			end

			def stop
				return if @state == :finished
				@state = :finished

				@on_finish.call() unless @on_finish.nil?
			end

			def restart
				@offset = 0;
				@state = :playing if @state == :finished
			end

			def pause
				return if is_done?
				@state = :paused
			end
			def resume
				return if is_done?
				@state = :playing
			end

			def toggle_pause
				return if is_done?
				@state = (@state == :playing) ? :paused : :playing
			end
		end
	end
end
