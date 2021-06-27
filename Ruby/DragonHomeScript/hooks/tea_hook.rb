
TEA_DURATIONS = {
    'black' => 6,
    'peppermint' => 4,
    'quick' => 0.1
}

$core.define_hook :teatime do
    def start_tea(convo, tea_type)
        tea_type.gsub!(/\s/, '');

        dur = TEA_DURATIONS[tea_type] || 5;
        convo.user.hook_data[:tea_done_time] = Time.now() + dur*60;

        convo.reply("Your tea will be ready in #{dur} minutes");

        user = convo.user

        self.in "#{dur}m" do 
            user.send_message("Your #{tea_type} tea is now ready!");
            user.hook_data[:tea_done_time] = nil;
        end
    end

    on :conversationReplyTea do |convo|
        next if convo.user.nil?

        if(convo.to_s =~ /(black|pepper mint|peppermint)(?: tea)?/i)
            start_tea convo, $1
        else
            convo.reply 'Sorry, I didn\'t get what tea you want.'
        end
    end

    on :conversationReply do |convo|
        next if convo.user.nil?

        if(convo.to_s =~ /(?:I am|I'm) making some (.*)tea/i)
            convo.tag = :tea

            tea_type = $1;

            if(tea_type == '')
                convo.inquire('What kind of tea?', jsgf: 'teatype.jsgf');
            else
                start_tea convo, tea_type
            end
        elsif(convo.to_s =~ /how long for the tea/i)
            tea_done_time = convo.user.hook_data[:tea_done_time];

            if(tea_done_time.nil?)
                convo.reply("The tea is a lie");
            else
                convo.reply("Your tea will be done in #{(tea_done_time - Time.now()) / 60} minutes!");
            end
        end
    end
end