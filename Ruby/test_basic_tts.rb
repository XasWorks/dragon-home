
$grapheme_list = {}
$grapheme_types = {}

File.readlines('cmudict-0.7b.txt').each do |line|
    begin
        next if line =~ /^;;;/

        m = /(\S+)  (.*)/.match line

        word = m[1];
        graphemes = m[2].split(' ');

        $grapheme_list[word] = graphemes;
        graphemes.each do |type|
            $grapheme_types[type] = true
        end
    rescue
    end
end

def play_word(word)
    graphemes = $grapheme_list[word.upcase]

    return if graphemes.nil?

    `sox #{File.exist?('/tmp/tts_lol.wav') ? '/tmp/tts_lol.wav' : ''} #{graphemes.map {|g| "test_graphemes/#{g}.wav" }.join(' ')} /tmp/tts_lol_tmp.wav`
    `mv /tmp/tts_lol_tmp.wav /tmp/tts_lol.wav`
end
def add_gap(duration = 0.1)
    `sox -n -r 44100 -c 1 /tmp/silence.wav trim 0.0 #{duration}`
    `sox /tmp/tts_lol.wav /tmp/silence.wav /tmp/tts_lol_tmp.wav`
    `mv /tmp/tts_lol_tmp.wav /tmp/tts_lol.wav`
end

def play_sentence(s)
    words = s.gsub(/\s+/, ' ').split(' ');

    words.each do |w|
        if(w =~ /^([^\.,]+)([\.,])$/)
            play_word($1);
            add_gap 0.3
        else
            play_word(w)
            add_gap
        end
    end    
end

puts "Hello would be #{$grapheme_list['DICTIONARY']}, graphemes are #{$grapheme_types.keys}"

`rm /tmp/tts_lol.wav`
play_sentence("Hello there, I hope you are doing alright ");

#play_sentence("This is a really, really stupid test. Like, so stupid. I recorded the different phonemes of the english language and used a phoneme dictionary.");
#play_sentence("I basically turned myself into a text to speech system.");

`sox /tmp/tts_lol.wav /tmp/tts.wav tempo 1.6`
`play /tmp/tts.wav`