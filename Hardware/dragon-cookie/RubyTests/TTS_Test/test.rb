

def generate_voicefile(str)
	#	File.write("/tmp/tts.txt", str);
	#	system('text2wave', '-o', '/tmp/tts.wav', '-eval', '(voice_cmu_us_slt_arctic_hts)', '/tmp/tts.txt')
	
	#   system('espeak', '-p50', '-w/tmp/tts.wav', str)
	
	system('./say_demo_uk', '-fo', '/tmp/tts.wav', '-a', "[:dv ap 120][:dv pr 1] #{str}");
end

generate_voicefile("This is a test of the voice generation. Hopefully it sounds cool.");

exit

require 'mqtt/sub_handler'
require_relative 'OpusStream.rb'

require_relative 'Dragon_Cookie.rb'

$mqtt = MQTT::SubHandler.new('mqtt://192.168.178.230');
$base_topic = "/esp32/dragon-cookie/E0.E2.E6.56.14.D0/"


$cookie = XNM::DragonHome::Cookie.new($mqtt, 'E0.E2.E6.56.14.D0');

$oStream = $cookie.speaker;

#generate_voicefile("Warning, Beat Saber will commence. Please stand clear of the dragon with at least 2 meters distance")
#generate_voicefile("Warning, core temperature is exceeding safe levels. Emergency decompression procedures will commence. Please evacuate nonessential areas.");
#generate_voicefile("Warning, unacceptable dragon horny detected. Horny safeguards will be exceeded in approximately one minute. Please commence emergency fellatio to reduce horny levels.")

#generate_voicefile("Hello Furry Art Chat. This is a smart home test from Xasin, Neira and Mesh. Looks pretty cool, does it not?");

#generate_voicefile("Warning, cuteness detected. Please initiate emergency cuddles.");


def speak(text)
	generate_voicefile(text);
	audio = XNM::OpusStream::FileSource.new("/tmp/tts.wav");
	audio.volume = 0.8;

	$cookie.speaker << audio;

	audio
end

$mqtt.subscribe_to $base_topic + "whistle_detect" do $has_whistle = true; end

loop do
	$has_whistle = false;
	sleep 0.5 until $has_whistle

	$recorded_name = nil;

	$cookie.on_record_done do |name| 
		$recorded_name = name; 
	end

	audio = XNM::OpusStream::FileSource.new('./computerbeep_55.mp3');
	audio.volume = 0.2;
	$oStream << audio;

	sleep 0.1 until audio.is_done?()
	sleep 0.5

	$cookie.recording = true;
	$cookie.warn_state = :WORKING;

	while $recorded_name.nil? do sleep 0.1; end

	$understood_text = `pocketsphinx_continuous -infile #{$recorded_name} -logfn /dev/null -jsgf Test.jsgf`;
	
	case $understood_text
	when /enable ambient lights/
		$cookie.ambient_lights = true;
	when /disable ambient lights/
		$cookie.ambient_lights = false;
	when /identify/
		$cookie.warn_state = :INFO;
		sleep 0.5;

		audio = speak("I am a D I Y smart home installation, codename dragon-home. Currently highly work in progress. Voice recognition is coming online.");
		sleep 0.1 until audio.is_done?
		sleep 0.5
	end

	`rm #{$recorded_name}`

	fAlert = XNM::OpusStream::FileSource.new('./tng_nemesis_intruder_alert.mp3');
	fAlert.volume = 0.04;
	fAlert.repeat = true
	# $oStream << fAlert;

	fAlert.repeat = false

	sleep 0.5

	fTemp = XNM::OpusStream::FileSource.new('./computerbeep_74.mp3');
	fTemp.volume = 0.2;
	$oStream << fTemp;
	sleep 1

	$cookie.warn_state = :IDLE

end

sleep 1
