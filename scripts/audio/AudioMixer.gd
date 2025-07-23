class_name AudioMixer
extends Node

# Audio mixing and playback system
# Manages audio player pools and handles mixing/limiting

# Audio players pool for each bus
var drum_players = []
var melodic_players = []
var sfx_players = []
var ambient_players = []

# Constants
const PLAYER_POOL_SIZE = 4  # Increased for better concurrency
const SAMPLE_RATE = 44100

func _ready():
	print("[AudioMixer] Initializing mixer and player pools")
	
	# Ensure audio buses exist
	setup_audio_buses()
	
	# Create player pools
	create_player_pools()
	
	print("[AudioMixer] Mixer ready with ", PLAYER_POOL_SIZE, " players per bus")

func setup_audio_buses():
	# Set up proper audio bus configuration if not already done
	if not AudioServer.get_bus_index("Drums") >= 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Drums")
		AudioServer.set_bus_send(AudioServer.get_bus_index("Drums"), "Master")
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Drums"), -3.0)
	
	if not AudioServer.get_bus_index("Melodic") >= 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Melodic")
		AudioServer.set_bus_send(AudioServer.get_bus_index("Melodic"), "Master")
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Melodic"), -6.0)
	
	if not AudioServer.get_bus_index("SFX") >= 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
		AudioServer.set_bus_send(AudioServer.get_bus_index("SFX"), "Master")
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), -4.0)
	
	if not AudioServer.get_bus_index("Ambient") >= 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "Ambient")
		AudioServer.set_bus_send(AudioServer.get_bus_index("Ambient"), "Master")
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambient"), -12.0)
	
	# Add limiter to master bus
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -6.0)

func create_player_pools():
	# Drum bus players
	for i in PLAYER_POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.bus = "Drums"
		add_child(player)
		drum_players.append(player)
	
	# Melodic bus players
	for i in PLAYER_POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.bus = "Melodic"
		add_child(player)
		melodic_players.append(player)
	
	# SFX bus players
	for i in PLAYER_POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)
	
	# Ambient bus players
	for i in 2:  # Less needed for ambient
		var player = AudioStreamPlayer.new()
		player.bus = "Ambient"
		add_child(player)
		ambient_players.append(player)

func get_available_player(player_pool: Array) -> AudioStreamPlayer:
	# Find first available player in pool
	for player in player_pool:
		if not player.playing:
			return player
	
	# If all playing, use the oldest one
	return player_pool[0]

func play_sound(audio_data: PackedFloat32Array, bus_type: String = "SFX", volume_adjustment: float = 0.0):
	var player_pool = []
	match bus_type:
		"Drums":
			player_pool = drum_players
		"Melodic":
			player_pool = melodic_players
		"SFX":
			player_pool = sfx_players
		"Ambient":
			player_pool = ambient_players
		_:
			player_pool = sfx_players
	
	var player = get_available_player(player_pool)
	if not player:
		return player
	
	# Create stream and setup
	var stream = AudioStreamGenerator.new()
	stream.mix_rate = SAMPLE_RATE
	stream.buffer_length = 0.5
	
	player.stream = stream
	player.volume_db = volume_adjustment
	player.play()
	
	var playback = player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback:
		# Convert to stereo frames (no soft limiting - sounds are pre-normalized)
		var stereo_frames = PackedVector2Array()
		for sample in audio_data:
			# Simple hard clip as failsafe only
			var clamped = clamp(sample, -1.0, 1.0)
			stereo_frames.append(Vector2(clamped, clamped))
		
		# Push all at once for better performance
		playback.push_buffer(stereo_frames)
	
	return player

# Get a specific player for continuous playback
func get_ambient_player() -> AudioStreamPlayer:
	return get_available_player(ambient_players)