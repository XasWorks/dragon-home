

$core.define_hook :comfy do
	@messages = [
		"Remember: Productivity is not the goal. It's enjoying what you do!",
		"Hey, how about you take a small break and reflect what you're doing?",
		"Are you stuck on a task? Maybe you should give yourself a breather, and then do something else!",
		"I hope you're feeling good, because ... Well, you should!",
		"If your plans aren't working out ... That's ok. You have all the time you need - you can work on them later :)",
		"I hope you're enjoying what you are doing - you deserve to :)",
		"You're awesome and you should relax!",
		"Remember that the passion to do something does not come from willpower alone. Breed it, let it go by feeling confident, feeling good about yourself - then your passions will soon after follow.",
		"When you feel like you *need* to do something ... Remember, you have time.
		 The most important thing is you, first and foremost, and ... Let projects come naturally, when you enjoy them.",
		"Do you want to switch to something different, try something out? If you feel like it, maybe now's a good time to do so!
		 But remember, there is no need to rush or feel obligated :)",
		"Don't forget to balance out your productivity with some lighthearted relaxing!",
		"Don't be afraid to say no to things. It's a good way to make sure that when you do say yes, it's true!",
		"Be proud of who you are, even if you aren't doing much. Every little bit counts, ok?",
		"Admire and be grateful for the little things, not just the big goals.",
		"Any good thing deserves to take its time. Especially with your art and projects, no single day has to finish everything :)",
		"Direction is more important than speed. Keep going with passion and enjoyment!"
	]

	every '7m' do
		$core.users.each do |u_key, user|
			next_comf = (user.hook_data[:next_comfy_message] || Time.at(0))
			next if Time.now() < next_comf

			if(user.awake?)
				user.send_message @messages.sample
			end
			
			user.hook_data[:next_comfy_message] = Time.now() + rand(60..120) * 60;
		end
	end
end