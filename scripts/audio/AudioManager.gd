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

func _init():
	process_mode = Node.PROCESS_MODE_ALWAYS

func _ready():
	print("[AudioManager] Initializing audio system")
	
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
	
	print("[AudioManager] Audio system ready")

func _process(delta):
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
		beat_occurred.emit(beat_count)

# === DRUM INTERFACE ===
func play_beat_sound(beat_number: int):
	# Kick on 1 and 3, snare on 2 and 4
	if beat_number % 4 == 0 or beat_number % 4 == 2:
		drum_bank.play_kick()
	else:
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

func play_game_over():
	sfx_bank.play_game_over()

# === AMBIENT INTERFACE ===
func start_ambient_guitar():
	ambient_system.start_guitar()

func stop_ambient_guitar():
	ambient_system.stop_guitar()

# === UTILITY FUNCTIONS ===
func set_master_volume(volume_db: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), volume_db)

func set_latency_offset(offset: float):
	audio_latency_offset = offset

func reset():
	beat_count = 0
	beat_timer = 0.0
	eighth_note_timer = 0.0
	melodic_bank.reset()
	ambient_system.stop_all()

# Get timing info for other systems
func get_beat_progress() -> float:
	return beat_timer / beat_interval

func get_current_beat() -> int:
	return beat_count

func is_on_beat(tolerance: float = 0.1) -> bool:
	var progress = get_beat_progress()
	return progress < tolerance or progress > (1.0 - tolerance)
