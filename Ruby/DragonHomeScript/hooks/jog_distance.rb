
$core.define_hook :jogging do
	on :userLocationChanged do |user, distance|
		next if user.hook_data[:active_jogging].nil?
		data = user.hook_data[:active_jogging]

		seg_time = Time.now() - data[:last_update]
		data[:last_update] = Time.now();

		segment_speed = (distance/1000) / (seg_time/(60*60));

		puts "You went #{distance}m in #{seg_time} seconds"

		threshold_speed = (data[:type] == :jog) ? 6 : 2;

		data[:temporary_time] += seg_time;
		data[:temporary_distance] += distance;

		if((data[:temporary_time] > (60*30)) && (data[:temporary_time] - seg_time) <= (60*30))
			user.send_message "Don't forget to log out of your #{data[:type]}!"
		end

		if(segment_speed > threshold_speed)
			temporary_speed = (data[:temporary_distance]/1000) / (data[:temporary_time]/(60*60));
			
			if((data[:temporary_time] < 1) || temporary_speed > threshold_speed)
				data[:distance]    += data[:temporary_distance]
				data[:active_time] += data[:temporary_time]
			else
				data[:idle_time] += data[:temporary_time]
			end

			data[:temporary_time] = 0
			data[:temporary_distance] = 0
		end
	end

	def end_walk(user, prefix = '', convo: nil)
		data = user.hook_data[:active_jogging]

		if(data.nil?)
			convo.reply("You aren't currently in an activity, sorry.")
			return;
		end

		dist = (data[:distance]/1000);
		dur = (data[:active_time]/60);

		speed = dist / ([dur/60, 0.1].max);

		out_str = "#{prefix}You did a total distance of #{dist.round(2)}km in #{dur.round(1)} minutes, that's an average of #{speed.round(1)} km/h."

		if(data[:idle_time] > 60)
			out_str += " You paused for #{(data[:idle_time]/60).round(2)} minutes."
		end

		out_str += " Keep it up!";

		if(!convo.nil?)
			convo.reply out_str
		else
			user.send_message out_str;
		end

		user.close_activity('jogging', extra_details: {
			distance: data[:distance],
			time: data[:active_time],
			paused: data[:idle_time]
		});

		user.hook_data[:active_jogging] = nil;
		user.save
	end

	on :userMovedRooms do |user, old_room|
		data = user.hook_data[:active_jogging]
		next if data.nil?

		if(old_room.nil?)
			end_walk(user)
		end
	end

	on :conversationReply do |convo|
		next if convo.user.nil?
		user = convo.user

		case convo.to_s
		when /(?:i am|i'm) going (for a walk|jogging)/i
			if(!user.hook_data[:active_jogging].nil?)
					convo.reply('You are already in an activity!')
					
					next
			end

			convo.reply("Alright, enjoy your #{$1 == 'jogging' ? 'jog' : 'walk'}!")

			user.hook_data[:active_jogging] = {
				distance: 0,
				active_time: 0,
				last_update: Time.now(),

				temporary_time: 0,
				temporary_distance: 0,

				idle_time: 0,

				type: $1 == 'jogging' ? :jog : :walk
			}
			user.save

			user.start_activity('jogging', color: 'green', category: 'sports');

		when /(?:i am|i'm) (?:done|back) (jogging|(?:with|from) the (?:walk|jog))/i
			end_walk(user, "Very nice! ", convo: convo)
		end
	end
end