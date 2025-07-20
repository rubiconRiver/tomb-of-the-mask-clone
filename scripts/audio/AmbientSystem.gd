class_name AmbientSystem
extends Node

# Ambient sound system for continuous background audio
# Handles guitar chord ambience

var mixer: AudioMixer
var guitar_player: AudioStreamPlayer
var guitar_loop: PackedFloat32Array
var guitar_position = 0
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
		return
		
	# Pre-create the guitar player and stream once
	_setup_guitar_player()
	
	# Load the pre-generated guitar loop
	guitar_loop = SoundBank.get_guitar_loop()
	if guitar_loop.size() == 0:
		push_error("[AmbientSystem] Failed to load guitar loop")

func _process(delta):
	if is_playing and guitar_playback and guitar_loop.size() > 0:
		# Keep the buffer filled with pre-generated audio
		while guitar_playback.can_push_buffer(CHUNK_SIZE):
			# Get next chunk from pre-generated loop
			var stereo_frames = PackedVector2Array()
			
			for i in CHUNK_SIZE:
				# Loop the audio if we reach the end
				var sample = guitar_loop[guitar_position % guitar_loop.size()]
				var clamped = clamp(sample * 0.8, -1.0, 1.0)
				stereo_frames.append(Vector2(clamped, clamped))
				guitar_position += 1
			
			guitar_playback.push_buffer(stereo_frames)

func _setup_guitar_player():
	guitar_player = mixer.get_ambient_player()
	if not guitar_player:
		push_error("[AmbientSystem] Could not get ambient player")
		return
	
	# Create stream once
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = 1.0
	
	guitar_player.stream = stream
	guitar_player.volume_db = 0.0

func start_guitar():
	if is_playing or not guitar_player or guitar_loop.size() == 0:
		return
	
	# Reset position for clean start
	guitar_position = 0
	
	# Just start playing the existing stream
	guitar_player.play()
	guitar_playback = guitar_player.get_stream_playback() as AudioStreamGeneratorPlayback
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