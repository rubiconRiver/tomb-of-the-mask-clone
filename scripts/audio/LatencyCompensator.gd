extends Node
class_name LatencyCompensator

# Latency compensation system for better rhythm timing
signal latency_measured(latency_ms: float)
signal calibration_complete(offset_ms: float)

var current_offset: float = 0.0  # Current latency offset in seconds
var measurement_samples: Array[float] = []
var is_measuring: bool = false
var measurement_count: int = 0
var target_measurements: int = 10

# Platform-specific base latencies (in milliseconds)
var PLATFORM_LATENCIES = {
	"Windows": 40.0,
	"macOS": 20.0,
	"Linux": 35.0,
	"Android": 60.0,
	"iOS": 25.0,
	"Web": 80.0
}

# Device-specific adjustments
var audio_driver_latencies = {
	"ASIO": 10.0,
	"DirectSound": 40.0,
	"WASAPI": 25.0,
	"PulseAudio": 30.0,
	"ALSA": 35.0,
	"CoreAudio": 20.0
}

func _ready():
	# Auto-detect and set initial offset
	auto_detect_latency()

func auto_detect_latency():
	var platform = OS.get_name()
	var base_latency = PLATFORM_LATENCIES.get(platform, 40.0)
	
	# Additional adjustments based on audio driver
	var driver_adjustment = detect_audio_driver_latency()
	
	# Set initial offset (convert ms to seconds)
	current_offset = (base_latency + driver_adjustment) / 1000.0
	
	print("[LatencyCompensator] Auto-detected latency: ", current_offset * 1000.0, "ms")
	emit_signal("latency_measured", current_offset * 1000.0)

func detect_audio_driver_latency() -> float:
	# Try to detect audio driver for more accurate latency estimation
	var audio_driver = AudioServer.get_driver_name()
	return audio_driver_latencies.get(audio_driver, 0.0)

func start_calibration():
	print("[LatencyCompensator] Starting manual calibration")
	measurement_samples.clear()
	measurement_count = 0
	is_measuring = true

func add_timing_measurement(expected_time: float, actual_time: float):
	if not is_measuring:
		return
	
	var latency = actual_time - expected_time
	measurement_samples.append(latency)
	measurement_count += 1
	
	print("[LatencyCompensator] Measurement ", measurement_count, ": ", latency * 1000.0, "ms")
	
	if measurement_count >= target_measurements:
		finish_calibration()

func finish_calibration():
	if measurement_samples.size() == 0:
		print("[LatencyCompensator] No measurements collected")
		return
	
	# Calculate average latency, removing outliers
	var sorted_samples = measurement_samples.duplicate()
	sorted_samples.sort()
	
	# Remove top and bottom 20% as outliers
	var start_idx = int(sorted_samples.size() * 0.2)
	var end_idx = int(sorted_samples.size() * 0.8)
	
	var sum = 0.0
	var count = 0
	for i in range(start_idx, end_idx):
		sum += sorted_samples[i]
		count += 1
	
	if count > 0:
		current_offset = sum / count
		print("[LatencyCompensator] Calibration complete: ", current_offset * 1000.0, "ms")
		emit_signal("calibration_complete", current_offset * 1000.0)
	
	is_measuring = false

func get_compensated_time() -> float:
	# Return current time with latency compensation applied
	return Time.get_ticks_msec() * 0.001 - current_offset

func compensate_beat_time(beat_time: float) -> float:
	# Compensate a beat timing with current offset
	return beat_time - current_offset

func set_manual_offset(offset_ms: float):
	# Allow manual override of latency offset
	current_offset = offset_ms / 1000.0
	print("[LatencyCompensator] Manual offset set: ", offset_ms, "ms")

func get_current_offset_ms() -> float:
	return current_offset * 1000.0

# Adaptive adjustment based on user performance
func adapt_offset_from_performance(timing_errors: Array[float]):
	if timing_errors.size() < 5:
		return  # Need at least 5 samples
	
	# Calculate average timing error
	var sum = 0.0
	for error in timing_errors:
		sum += error
	
	var avg_error = sum / timing_errors.size()
	
	# If there's a consistent bias, adjust offset slightly
	if abs(avg_error) > 0.02:  # 20ms threshold
		var adjustment = avg_error * 0.1  # Small adjustment factor
		current_offset += adjustment
		
		print("[LatencyCompensator] Adaptive adjustment: ", adjustment * 1000.0, "ms")
		print("[LatencyCompensator] New offset: ", current_offset * 1000.0, "ms")

# Save/load calibration
func save_calibration():
	var save_data = {
		"offset_ms": current_offset * 1000.0,
		"platform": OS.get_name(),
		"audio_driver": AudioServer.get_driver_name(),
		"timestamp": Time.get_unix_time_from_system()
	}
	
	var file = FileAccess.open("user://audio_calibration.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("[LatencyCompensator] Calibration saved")

func load_calibration() -> bool:
	var file = FileAccess.open("user://audio_calibration.json", FileAccess.READ)
	if not file:
		return false
	
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()
	
	if parse_result != OK:
		print("[LatencyCompensator] Failed to parse calibration file")
		return false
	
	var data = json.data
	
	# Verify platform matches (calibration might not be valid on different platform)
	if data.get("platform", "") == OS.get_name():
		current_offset = data.get("offset_ms", 0.0) / 1000.0
		print("[LatencyCompensator] Calibration loaded: ", current_offset * 1000.0, "ms")
		return true
	
	return false