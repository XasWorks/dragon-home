

require 'mqtt/sub_handler'

require 'tef/animation.rb'

$mqtt       = MQTT::SubHandler.new('mqtt://192.168.178.230');
$anim_core  = TEF::Sequencing::Player.new();

$base_device_topic = "/esp32/dragon-cookie/E0.E2.E6.56.14.D0/"

$colourmap = {
    'idle' => '#58462F',
    'warm' => '#CFB67E',
    'neutral' => '#A7ABAB',
    'golden' => '#FFC530',
    'cold' => '#B1C0CC'
}

def c_remap(c)
    if($colourmap.include? c)
        return $colourmap[c];
    end

    return c;
end

def set_speed(speed = 5)
    $mqtt.publish_to $base_device_topic + "AmbientSpeed", speed;
end

def set_colour(colour)
    $mqtt.publish_to $base_device_topic + "AmbientOverride", c_remap(colour)
end

def flash_colour(colour)
    $mqtt.publish_to $base_device_topic + "AmbientJump", c_remap(colour)
end

$music_sheet = TEF::Sequencing::Sheet.new() do |s|
    s.notes do
        play './Locus Iste Cut.mp3'

        notes_reader = TEF::Sequencing::AudacityReader.new('LocusIstePoints.txt');

        notes_reader['default'].each do |element|
            at element[:start] do
                if(/S(\S*)/ =~ element[:text]) 
                    set_speed($1); 
                end
                if(/J(\S*)/ =~ element[:text]) 
                    flash_colour($1); 
                end
                if(/C(\S*)/ =~ element[:text]) 
                    set_colour($1); 
                end
            end
        end
    end
end

$anim_core['default'] = $music_sheet;

at_exit do
    set_colour("#000000")
    sleep 0.1;
end

Thread.stop();
