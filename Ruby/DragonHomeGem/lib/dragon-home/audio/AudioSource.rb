
require 'numo/narray'

module XNM
	module OpusStream
		class AudioSource
			def initialize()
			end

			def has_audio?
				false
			end
			def get_audio(samp_no = 48000 * 0.02)
				nil;
			end

			def is_done?()
				true
			end

			def stop()
			end

			def pause()
			end

			def resume()
			end
		end
	end
end
