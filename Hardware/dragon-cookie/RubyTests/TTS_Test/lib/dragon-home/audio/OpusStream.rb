
require 'opus-ruby'
require 'numo/narray'

INT16_MAX = (2**15) - 1;
INT16_MIN = -(2**15);

require_relative 'FileSource.rb'

module XNM
	module OpusStream
		class Output
			def initialize(bitrate: 24000, &block)
				raise ArgumentError, "A output block needs to be given!" unless block_given?

				@output_block = block;

				@config_mutex = Mutex.new();

				@source_list = [];
				@notify_threads = [];

				@output_encoder = Opus::Encoder.new(48000, 0.02 * 48000, 1);
				@output_encoder.vbr_rate = 0;
				@output_encoder.bitrate = bitrate;

				@per_tick_packet_num = 1;

				@data_thread_instance = Thread.new do
					data_thread
				end
				@data_thread_instance.abort_on_exception = true
			end

			private def data_thread()
				last_data_time = Time.now();

				loop do
					last_data_time += 0.02 * @per_tick_packet_num;
					sleep_time = last_data_time - Time.now();

					sleep sleep_time if sleep_time > 0

					output_tick();
				end
			end

			private def encode_audio_data(data)
				@last_rms = data.rms / INT16_MAX.to_f;

				data[(data > INT16_MAX).where] = INT16_MAX;
				data[(data < INT16_MIN).where] = INT16_MIN;

				cast_data = data.cast_to(Numo::Int16);

				@output_encoder.encode(cast_data.to_string, cast_data.size);
			end

			private def output_tick()
				per_packet_samples = 48000 * 0.02;
				byterate = @output_encoder.bitrate / 8;
				per_tick_encoded_bytes = byterate * 0.02 * @per_tick_packet_num;

				audio_data = Numo::DFloat.zeros(per_packet_samples);

				out_str = String.new('', encoding: 'ASCII-8BIT', capacity: per_tick_encoded_bytes + 1);
				out_str += [@per_tick_packet_num].pack('c');

				has_data = false;


				@per_tick_packet_num.times do

					audio_data.fill 0;

					source_copy = nil;
					@config_mutex.synchronize do
						source_copy = @source_list.dup
					end

					source_copy.each do |source|
						data = source.get_audio()
						next if data.nil?

						has_data = true;

						audio_data += data;
					end

					break unless has_data

					@source_list.delete_if(&:is_done?)

					out_str += encode_audio_data(audio_data);
				end

				@output_block.call(has_data ? out_str : nil);
			end

			def <<(source)
				raise ArgumentError, "Source could not be converted to AudioSource" unless source.is_a? AudioSource

				@config_mutex.synchronize do
					@source_list << source
				end
			end

			def play(audio_data)

			end
		end
	end
end
