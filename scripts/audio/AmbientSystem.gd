class_name AmbientSystem
extends Node

# Ambient sound system for continuous background audio
# Handles guitar chord ambience

var mixer: AudioMixer
var guitar_player: AudioStreamPlayer
var guitar_playback: AudioStreamGeneratorPlayback
var guitar_time_position = 0.0
var is_playing = false

const CHUNK_SIZE = 1024
const SAMPLE_RATE = 44100

func _ready():
	# Wait a frame for all nodes to be ready
	await get_tree().process_frame
	# Get mixer from parent AudioManager
	var audio_manager = get_parent()
	if audio_manager and "mixer" in audio_manager:
		mixer = audio_manager.mixer
	if not mixer:
		push_error("[AmbientSystem] Could not find AudioMixer")

func _process(delta):
	if is_playing and guitar_playback:
		# Keep the buffer filled
		while guitar_playback.can_push_buffer(CHUNK_SIZE):
			var chunk = SoundBank.generate_ambient_guitar_chunk(guitar_time_position, CHUNK_SIZE)
			
			# Convert to stereo with limiting
			var stereo_frames = PackedVector2Array()
			for sample in chunk:
				var limited = SoundBank.soft_clip(sample * 0.8)
				stereo_frames.append(Vector2(limited, limited))
			
			guitar_playback.push_buffer(stereo_frames)
			guitar_time_position += float(CHUNK_SIZE) / SAMPLE_RATE

func start_guitar():
	if is_playing:
		return
	
	guitar_player = mixer.get_ambient_player()
	if not guitar_player:
		return
	
	# Setup stream
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = 1.0
	
	guitar_player.stream = stream
	guitar_player.volume_db = 0.0
	guitar_player.play()
	
	guitar_playback = guitar_player.get_stream_playback() as AudioStreamGeneratorPlayback
	guitar_time_position = 0.0
	is_playing = true

func stop_guitar():
	if not is_playing:
		return
	
	is_playing = false
	if guitar_player and guitar_player.playing:
		guitar_player.stop()
	guitar_playback = null

func stop_all():
	stop_guitar()