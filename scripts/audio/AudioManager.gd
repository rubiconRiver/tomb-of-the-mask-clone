extends Node

# Main audio system manager - handles all audio playback in the game
# This is a singleton that coordinates between different audio subsystems

signal beat_occurred(beat_count: int)
signal eighth_note_occurred()

# Subsystems
var drum_bank: DrumBank
var melodic_bank: MelodicBank
var sfx_bank: SFXBank
var ambient_system: AmbientSystem
var mixer: AudioMixer

# Timing
var beat_timer = 0.0
var beat_interval = 0.5
var eighth_note_timer = 0.0
var eighth_note_interval = 0.25
var beat_count = 0
var audio_latency_offset = 0.0

# State
var is_started = false
var start_time = 0.0

# Diagnostics
var timing_diagnostics: AudioTimingDiagnostics
var enable_timing_logs = true
var log_every_n_beats = 4  # Log summary every 4 beats

func _init():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready():
	print("[AudioManager] Initializing audio system")
	print("[AudioManager] _ready() called at: ", Time.get_ticks_msec() / 1000.0)
	
	# Initialize subsystems
	mixer = AudioMixer.new()
	add_child(mixer)
	
	drum_bank = DrumBank.new()
	add_child(drum_bank)
	
	melodic_bank = MelodicBank.new()
	add_child(melodic_bank)
	
	sfx_bank = SFXBank.new()
	add_child(sfx_bank)
	
	ambient_system = AmbientSystem.new()
	add_child(ambient_system)
	
	print("[AudioManager] Audio system ready (beat tracking not started yet)")
	print("[AudioManager] Beat interval configured as: %.3f seconds" % beat_interval)

func _process(delta):
	# Don't process beats until we've started
	if not is_started:
		return
	
	# Track frame timing
	if timing_diagnostics and enable_timing_logs:
		var frame_data = timing_diagnostics.update_frame_timing()
		if frame_data.is_frame_drop:
			print(timing_diagnostics.format_frame_drop_log(frame_data))
	
	# Log the very first frame after starting
	if beat_count == 0 and beat_timer == 0.0:
		print("[AudioManager] First _process() after start at: ", Time.get_ticks_msec() / 1000.0)
		print("[AudioManager] First delta after start: ", delta)
		print("[AudioManager] Beat interval: ", beat_interval)
	
	# Update beat timing
	beat_timer += delta
	eighth_note_timer += delta
	
	# Check for eighth notes
	if eighth_note_timer >= eighth_note_interval:
		eighth_note_timer -= eighth_note_interval
		eighth_note_occurred.emit()
	
	# Check for quarter note beats
	if beat_timer >= beat_interval:
		beat_timer -= beat_interval
		beat_count += 1
		
		# Special logging for first beat
		if beat_count == 1:
			print("[AudioManager] FIRST BEAT FIRED!")
			print("  beat_timer was: ", beat_timer + beat_interval)
			print("  beat_timer now: ", beat_timer)
			print("  Current time: ", Time.get_ticks_msec() / 1000.0)
		
		# Track beat timing
		if timing_diagnostics and enable_timing_logs:
			var beat_data = timing_diagnostics.record_beat(beat_count)
			print(timing_diagnostics.format_beat_log(beat_data))
			
			# Log performance summary periodically
			if beat_count % log_every_n_beats == 0:
				print(timing_diagnostics.format_performance_log())
		
		beat_occurred.emit(beat_count)

# === DRUM INTERFACE ===
func play_beat_sound(beat_number: int):
	# Kick on 1 and 3, snare on 2 and 4
	if beat_number % 4 == 0 or beat_number % 4 == 2:
		if enable_timing_logs:
			print("[AudioManager] Playing KICK on beat %d" % beat_number)
		drum_bank.play_kick()
	else:
		if enable_timing_logs:
			print("[AudioManager] Playing SNARE on beat %d" % beat_number)
		drum_bank.play_snare()

func play_hihat():
	drum_bank.play_hihat()

# === MELODIC INTERFACE ===
func play_combo_sound(combo: int, multiplier_increased: bool):
	melodic_bank.play_combo_sound(combo, multiplier_increased)

func play_multiplier_note(multiplier: int):
	melodic_bank.play_multiplier_note(multiplier)

# === SFX INTERFACE ===
func play_coin_collected():
	sfx_bank.play_coin_chime()

func play_wall_hit():
	sfx_bank.play_wall_hit()

func play_whoosh():
	sfx_bank.play_whoosh()

func play_game_over():
	sfx_bank.play_game_over()

# === AMBIENT INTERFACE ===
# Guitar removed for performance - these are now no-ops
func start_ambient_guitar():
	pass

func stop_ambient_guitar():
	pass

# === UTILITY FUNCTIONS ===
func set_master_volume(volume_db: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)

func set_latency_offset(offset: float):
	audio_latency_offset = offset

func start_beat_tracking():
	if is_started:
		print("[AudioManager] WARNING: Beat tracking already started!")
		return
	
	print("[AudioManager] === STARTING BEAT TRACKING ===")
	start_time = Time.get_ticks_msec() / 1000.0
	print("[AudioManager] Start time: ", start_time)
	
	# Initialize timing diagnostics NOW
	timing_diagnostics = AudioTimingDiagnostics.new(beat_interval)
	print("[AudioManager] Timing diagnostics initialized")
	
	# Reset all timers
	beat_timer = 0.0
	eighth_note_timer = 0.0
	beat_count = 0
	
	is_started = true
	print("[AudioManager] Beat tracking started! First beat expected at: ", start_time + beat_interval)

func reset():
	print("[AudioManager] Resetting audio system")
	is_started = false
	beat_count = 0
	beat_timer = 0.0
	eighth_note_timer = 0.0
	melodic_bank.reset()
	ambient_system.stop_all()
	
	# Reset diagnostics
	if timing_diagnostics:
		timing_diagnostics.reset()
		print("[AudioManager] Timing diagnostics reset")

# Get timing info for other systems
func get_beat_progress() -> float:
	if not is_started:
		return 0.0
	return beat_timer / beat_interval

func get_current_beat() -> int:
	return beat_count

func is_on_beat(tolerance: float = 0.1) -> bool:
	if not is_started:
		return false
	var progress = get_beat_progress()
	return progress < tolerance or progress > (1.0 - tolerance)

# Get diagnostic info
func get_timing_health() -> Dictionary:
	if timing_diagnostics:
		return timing_diagnostics.get_performance_summary()
	return {}

func is_timing_healthy() -> bool:
	if timing_diagnostics:
		return timing_diagnostics.is_sync_healthy()
	return true
