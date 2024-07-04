

$core.define_hook :job_time do 
	on :conversationReply do |message|
		user = message.user
		return if user.nil?

		case message.to_s
		when /going to the (hiwi job|lab)/i
			user.start_activity($1.downcase, color: 'orange', category: 'work');
			message.reply("Alright, enjoy the #{$1} work!");
		when /done with the (hiwi job|lab)(?: on (.*))?/i
			
			w = user.close_activity($1.downcase, description: $2);

			if w.nil?
				message.reply('Sorry, no running activity was found for that!');
				
				next
			end

			message.reply("Very nice! You did #{((w.tend - w.tstart) / (60*60)).round(1)}h of work.");
		end
	end
end