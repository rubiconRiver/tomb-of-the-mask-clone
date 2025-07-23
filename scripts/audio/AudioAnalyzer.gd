extends Node
class_name AudioAnalyzer

# Real-time audio analysis for enhanced beat detection and visual reactivity
signal beat_detected(strength: float, frequency_band: String)
signal tempo_detected(bpm: float)
signal audio_spectrum_updated(spectrum_data: Array)

var spectrum: AudioEffectSpectrumAnalyzerInstance
var beat_detection_enabled: bool = true
var spectrum_analysis_enabled: bool = true

# Beat detection parameters
var beat_threshold: float = 0.3
var beat_cooldown: float = 0.1
var last_beat_time: float = 0.0
var energy_history: Array[float] = []
var energy_history_size: int = 43  # ~1 second at 43.07 FPS

# Frequency band analysis
var frequency_bands = {
	"sub_bass": {"min": 20, "max": 60, "energy": 0.0},
	"bass": {"min": 60, "max": 250, "energy": 0.0},
	"low_mid": {"min": 250, "max": 500, "energy": 0.0},
	"mid": {"min": 500, "max": 2000, "energy": 0.0},
	"upper_mid": {"min": 2000, "max": 4000, "energy": 0.0},
	"presence": {"min": 4000, "max": 6000, "energy": 0.0},
	"brilliance": {"min": 6000, "max": 20000, "energy": 0.0}
}

# BPM detection
var bpm_detection_enabled: bool = true
var beat_intervals: Array[float] = []
var beat_interval_history_size: int = 16
var current_bpm: float = 120.0
var bpm_confidence: float = 0.0

func _ready():
	# Get spectrum analyzer from AudioServer
	setup_spectrum_analyzer()
	set_process(true)

func setup_spectrum_analyzer():
	# Add spectrum analyzer effect to master bus
	var spectrum_effect = AudioEffectSpectrumAnalyzer.new()
	spectrum_effect.buffer_length = 2048
	spectrum_effect.tap_back_pos = 0
	spectrum_effect.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_2048
	
	# Add to master bus
	AudioServer.add_bus_effect(0, spectrum_effect)
	
	# Get the instance
	spectrum = AudioServer.get_bus_effect_instance(0, AudioServer.get_bus_effect_count(0) - 1)

func _process(delta):
	if not spectrum:
		return
	
	# Update frequency band analysis
	if spectrum_analysis_enabled:
		update_frequency_analysis()
	
	# Detect beats
	if beat_detection_enabled:
		detect_beats(delta)

func update_frequency_analysis():
	var magnitude_sum = 0.0
	var spectrum_data = []
	
	# Analyze each frequency band
	for band_name in frequency_bands:
		var band = frequency_bands[band_name]
		var energy = get_frequency_band_energy(band.min, band.max)
		band.energy = energy
		magnitude_sum += energy
		
		spectrum_data.append({
			"band": band_name,
			"energy": energy,
			"normalized": energy / 1.0  # Will be properly normalized below
		})
	
	# Normalize spectrum data
	if magnitude_sum > 0:
		for data in spectrum_data:
			data.normalized = data.energy / magnitude_sum
	
	emit_signal("audio_spectrum_updated", spectrum_data)

func get_frequency_band_energy(freq_min: float, freq_max: float) -> float:
	var sample_rate = AudioServer.get_mix_rate()
	var nyquist = sample_rate / 2.0
	var buffer_size = 2048
	
	# Convert frequencies to bin indices
	var min_bin = int((freq_min / nyquist) * buffer_size / 2)
	var max_bin = int((freq_max / nyquist) * buffer_size / 2)
	
	min_bin = max(0, min_bin)
	max_bin = min(buffer_size / 2 - 1, max_bin)
	
	var energy = 0.0
	for i in range(min_bin, max_bin + 1):
		var magnitude = spectrum.get_magnitude_for_frequency_range(
			i * nyquist / (buffer_size / 2),
			(i + 1) * nyquist / (buffer_size / 2)
		).length()
		energy += magnitude * magnitude
	
	return sqrt(energy / (max_bin - min_bin + 1))

func detect_beats(delta: float):
	# Get current energy (focus on bass and low-mid frequencies for beat detection)
	var current_energy = frequency_bands.bass.energy + frequency_bands.low_mid.energy * 0.5
	
	# Add to energy history
	energy_history.append(current_energy)
	if energy_history.size() > energy_history_size:
		energy_history.pop_front()
	
	# Need sufficient history for beat detection
	if energy_history.size() < energy_history_size:
		return
	
	# Calculate average energy
	var avg_energy = 0.0
	for energy in energy_history:
		avg_energy += energy
	avg_energy /= energy_history.size()
	
	# Beat detection: current energy significantly above average
	var beat_factor = 1.5  # Energy must be 1.5x average
	var current_time = Time.get_ticks_msec() * 0.001
	var time_since_last_beat = current_time - last_beat_time
	
	if current_energy > avg_energy * beat_factor and time_since_last_beat > beat_cooldown:
		var beat_strength = (current_energy - avg_energy) / avg_energy
		last_beat_time = current_time
		
		# Determine dominant frequency band for this beat
		var dominant_band = get_dominant_frequency_band()
		
		emit_signal("beat_detected", beat_strength, dominant_band)
		
		# Update BPM detection
		if bpm_detection_enabled:
			update_bpm_detection(time_since_last_beat)

func get_dominant_frequency_band() -> String:
	var max_energy = 0.0
	var dominant_band = "bass"
	
	for band_name in frequency_bands:
		var energy = frequency_bands[band_name].energy
		if energy > max_energy:
			max_energy = energy
			dominant_band = band_name
	
	return dominant_band

func update_bpm_detection(interval: float):
	if interval < 0.2 or interval > 2.0:  # Ignore unrealistic intervals
		return
	
	beat_intervals.append(interval)
	if beat_intervals.size() > beat_interval_history_size:
		beat_intervals.pop_front()
	
	# Calculate BPM from intervals
	if beat_intervals.size() >= 4:
		var avg_interval = 0.0
		for beat_interval in beat_intervals:
			avg_interval += beat_interval
		avg_interval /= beat_intervals.size()
		
		var detected_bpm = 60.0 / avg_interval
		
		# Smooth BPM changes
		var bpm_change = abs(detected_bpm - current_bpm)
		var max_change = 10.0  # Max BPM change per detection
		
		if bpm_change < max_change:
			current_bpm = lerp(current_bpm, detected_bpm, 0.1)  # Smooth interpolation
			bpm_confidence = min(bpm_confidence + 0.1, 1.0)
		else:
			bpm_confidence = max(bpm_confidence - 0.2, 0.0)
		
		if bpm_confidence > 0.7:  # Only emit when confident
			emit_signal("tempo_detected", current_bpm)

# Configuration functions
func set_beat_sensitivity(sensitivity: float):
	# sensitivity: 0.0 (least sensitive) to 1.0 (most sensitive)
	beat_threshold = lerp(0.5, 0.1, sensitivity)

func set_spectrum_resolution(resolution: int):
	# Change FFT size for different frequency resolution
	match resolution:
		1: setup_spectrum_analyzer()  # 2048 - default
		2: pass  # Could implement 4096 for higher resolution
		0: pass  # Could implement 1024 for lower CPU usage

func get_current_bpm() -> float:
	return current_bpm

func get_bpm_confidence() -> float:
	return bpm_confidence

func get_frequency_energy(band_name: String) -> float:
	if frequency_bands.has(band_name):
		return frequency_bands[band_name].energy
	return 0.0

func is_beat_detected_recently(time_window: float = 0.1) -> bool:
	var current_time = Time.get_ticks_msec() * 0.001
	return current_time - last_beat_time < time_window

# Visual reactivity helpers
func get_bass_intensity() -> float:
	return frequency_bands.bass.energy

func get_treble_intensity() -> float:
	return (frequency_bands.presence.energy + frequency_bands.brilliance.energy) / 2.0

func get_overall_intensity() -> float:
	var total_energy = 0.0
	for band_name in frequency_bands:
		total_energy += frequency_bands[band_name].energy
	return total_energy / frequency_bands.size()