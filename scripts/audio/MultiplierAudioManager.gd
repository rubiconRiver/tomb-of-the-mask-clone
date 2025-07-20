class_name MultiplierAudioManager
extends Node

# Note frequencies for each multiplier level (in Hz)
# C4, G4, C5, E5, G5 - ascending with satisfying resolution
const MULTIPLIER_FREQUENCIES = {
	1: 261.63,  # C4 (starting note)
	2: 392.00,  # G4 (perfect fifth jump)
	3: 523.25,  # C5 (octave of start)
	4: 659.25,  # E5 (major third above C5)
	5: 783.99   # G5 (perfect fifth, completes the chord)
}

# Volume and duration settings
const NOTE_DURATION = 0.3  # seconds
const NOTE_VOLUME = -10.0  # dB

var audio_player: AudioStreamPlayer
var current_multiplier = 1
var previous_multiplier = 1

func _ready():
	print("[MultiplierAudio] Initializing multiplier audio system")
	
	# Create audio player
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Master"
	add_child(audio_player)
	
	print("[MultiplierAudio] Audio player created and ready")

func play_multiplier_note(new_multiplier: int, old_multiplier: int = -1):
	print("[MultiplierAudio] === MULTIPLIER SOUND TRIGGERED ===")
	print("[MultiplierAudio] New multiplier: ", new_multiplier, " | Previous multiplier: ", current_multiplier)
	
	# Only play sound when multiplier increases
	if new_multiplier <= current_multiplier:
		print("[MultiplierAudio] Multiplier did not increase, skipping sound")
		previous_multiplier = current_multiplier
		current_multiplier = new_multiplier
		return
	
	# Get frequency for this multiplier level
	var frequency = MULTIPLIER_FREQUENCIES.get(new_multiplier, 261.63)
	print("[MultiplierAudio] Playing note at frequency: ", frequency, " Hz")
	
	# Create a simple sine wave tone
	var sample_rate = 44100
	var samples = int(sample_rate * NOTE_DURATION)
	var audio_data = PackedFloat32Array()
	
	# Generate sine wave with envelope
	for i in range(samples):
		var t = float(i) / float(sample_rate)
		
		# Apply ADSR envelope for cleaner sound
		var envelope = 1.0
		var attack_time = 0.01
		var decay_time = 0.05
		var sustain_level = 0.8
		var release_time = 0.1
		
		if t < attack_time:
			# Attack
			envelope = t / attack_time
		elif t < attack_time + decay_time:
			# Decay
			var decay_progress = (t - attack_time) / decay_time
			envelope = 1.0 - (1.0 - sustain_level) * decay_progress
		elif t < NOTE_DURATION - release_time:
			# Sustain
			envelope = sustain_level
		else:
			# Release
			var release_progress = (t - (NOTE_DURATION - release_time)) / release_time
			envelope = sustain_level * (1.0 - release_progress)
		
		# Generate sample with envelope
		var sample = sin(2.0 * PI * frequency * t) * envelope * 0.5
		audio_data.append(sample)
	
	# Create audio stream from generated data
	var audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = sample_rate
	audio_stream.buffer_length = 0.5
	
	audio_player.stream = audio_stream
	audio_player.volume_db = NOTE_VOLUME
	audio_player.play()
	
	# Use generator playback to push our audio data
	var playback = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback:
		# Convert to stereo
		var stereo_frames = PackedVector2Array()
		for sample in audio_data:
			stereo_frames.append(Vector2(sample, sample))
		
		# Push frames in chunks to avoid buffer overflow
		var chunk_size = 1024
		for i in range(0, stereo_frames.size(), chunk_size):
			var end_idx = min(i + chunk_size, stereo_frames.size())
			var chunk = stereo_frames.slice(i, end_idx)
			playback.push_buffer(chunk)
	
	print("[MultiplierAudio] Note playing for ", NOTE_DURATION, " seconds")
	print("[MultiplierAudio] Volume: ", NOTE_VOLUME, " dB")
	
	# Update state
	previous_multiplier = new_multiplier
	current_multiplier = new_multiplier

func on_multiplier_changed(new_multiplier: int):
	print("[MultiplierAudio] Received multiplier change signal: ", new_multiplier)
	play_multiplier_note(new_multiplier)

func play_combo_note(combo: int, multiplier_increased: bool):
	print("[MultiplierAudio] === COMBO SOUND TRIGGERED ===")
	print("[MultiplierAudio] Combo: ", combo, " | Multiplier increased: ", multiplier_increased)
	
	# Get frequency based on combo (1-5)
	var clamped_combo = min(combo, 5)
	var frequency = MULTIPLIER_FREQUENCIES.get(clamped_combo, 261.63)
	
	# Adjust volume based on whether multiplier increased
	var volume = NOTE_VOLUME if multiplier_increased else NOTE_VOLUME - 6.0  # Quieter when not progressing
	
	print("[MultiplierAudio] Playing note at frequency: ", frequency, " Hz")
	print("[MultiplierAudio] Volume: ", volume, " dB (", "loud" if multiplier_increased else "quiet", ")")
	
	# Create a simple sine wave tone
	var sample_rate = 44100
	var samples = int(sample_rate * NOTE_DURATION)
	var audio_data = PackedFloat32Array()
	
	# Generate sine wave with envelope
	for i in range(samples):
		var t = float(i) / float(sample_rate)
		
		# Apply ADSR envelope for cleaner sound
		var envelope = 1.0
		var attack_time = 0.01
		var decay_time = 0.05
		var sustain_level = 0.8
		var release_time = 0.1
		
		if t < attack_time:
			# Attack
			envelope = t / attack_time
		elif t < attack_time + decay_time:
			# Decay
			var decay_progress = (t - attack_time) / decay_time
			envelope = 1.0 - (1.0 - sustain_level) * decay_progress
		elif t < NOTE_DURATION - release_time:
			# Sustain
			envelope = sustain_level
		else:
			# Release
			var release_progress = (t - (NOTE_DURATION - release_time)) / release_time
			envelope = sustain_level * (1.0 - release_progress)
		
		# Generate sample with envelope
		var sample = sin(2.0 * PI * frequency * t) * envelope * 0.5
		audio_data.append(sample)
	
	# Create audio stream from generated data
	var audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = sample_rate
	audio_stream.buffer_length = 0.5
	
	audio_player.stream = audio_stream
	audio_player.volume_db = volume
	audio_player.play()
	
	# Use generator playback to push our audio data
	var playback = audio_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback:
		# Convert to stereo
		var stereo_frames = PackedVector2Array()
		for sample in audio_data:
			stereo_frames.append(Vector2(sample, sample))
		
		# Push frames in chunks to avoid buffer overflow
		var chunk_size = 1024
		for i in range(0, stereo_frames.size(), chunk_size):
			var end_idx = min(i + chunk_size, stereo_frames.size())
			var chunk = stereo_frames.slice(i, end_idx)
			playback.push_buffer(chunk)

func on_combo_changed(combo: int, multiplier_increased: bool = true):
	print("[MultiplierAudio] Combo changed to: ", combo, " | Multiplier increased: ", multiplier_increased)
	# Only play sound for combos 1-5 to avoid repetitive high notes
	if combo > 0 and combo <= 5:
		play_combo_note(combo, multiplier_increased)

func reset():
	print("[MultiplierAudio] Resetting audio manager")
	current_multiplier = 1
	previous_multiplier = 1
	if audio_player.playing:
		audio_player.stop()