extends RefCounted
class_name AudioTimingDiagnostics

# Helper class for tracking audio timing, drift, and performance metrics
# Provides utilities to ensure beats never skip or slow down

# Frame timing tracking
var frame_times: Array = []
var max_frame_history: int = 60
var last_frame_time: float = 0.0

# Beat timing tracking
var start_time: float = 0.0
var expected_beat_time: float = 0.0
var actual_beat_time: float = 0.0
var drift_accumulator: float = 0.0
var beat_interval: float = 0.5

# Performance thresholds
const FRAME_DROP_THRESHOLD = 0.033  # 33ms = below 30fps
const DRIFT_WARNING_THRESHOLD = 0.010  # 10ms drift warning
const DRIFT_CRITICAL_THRESHOLD = 0.050  # 50ms drift critical

# Statistics
var total_beats: int = 0
var dropped_frames: int = 0
var drift_warnings: int = 0
var drift_criticals: int = 0

func _init(initial_beat_interval: float = 0.5):
	beat_interval = initial_beat_interval
	print("[AudioTimingDiagnostics] _init() called with interval: ", beat_interval)
	reset()

func reset():
	frame_times.clear()
	last_frame_time = 0.0
	start_time = Time.get_ticks_msec() / 1000.0
	expected_beat_time = start_time + beat_interval
	print("[AudioTimingDiagnostics] reset() - start_time: ", start_time)
	print("[AudioTimingDiagnostics] reset() - first expected_beat_time: ", expected_beat_time)
	actual_beat_time = start_time
	drift_accumulator = 0.0
	total_beats = 0
	dropped_frames = 0
	drift_warnings = 0
	drift_criticals = 0

# Call this every frame to track frame timing
func update_frame_timing() -> Dictionary:
	var current_time = Time.get_ticks_msec() / 1000.0
	var result = {
		"frame_time": 0.0,
		"is_frame_drop": false,
		"current_fps": 0.0,
		"average_fps": 0.0
	}
	
	if last_frame_time > 0:
		var frame_time = current_time - last_frame_time
		frame_times.append(frame_time)
		
		if frame_times.size() > max_frame_history:
			frame_times.pop_front()
		
		result.frame_time = frame_time
		result.current_fps = 1.0 / frame_time if frame_time > 0 else 0.0
		
		# Check for frame drop
		if frame_time > FRAME_DROP_THRESHOLD:
			result.is_frame_drop = true
			dropped_frames += 1
		
		# Calculate average FPS
		if frame_times.size() > 0:
			var avg_frame_time = 0.0
			for ft in frame_times:
				avg_frame_time += ft
			avg_frame_time /= frame_times.size()
			result.average_fps = 1.0 / avg_frame_time if avg_frame_time > 0 else 0.0
	
	last_frame_time = current_time
	return result

# Call this when a beat occurs to track timing drift
func record_beat(beat_count: int) -> Dictionary:
	var current_time = Time.get_ticks_msec() / 1000.0
	actual_beat_time = current_time
	
	var drift = actual_beat_time - expected_beat_time
	drift_accumulator += drift
	total_beats += 1
	
	# Categorize drift severity
	var drift_severity = "OK"
	if abs(drift) > DRIFT_CRITICAL_THRESHOLD:
		drift_severity = "CRITICAL"
		drift_criticals += 1
	elif abs(drift) > DRIFT_WARNING_THRESHOLD:
		drift_severity = "WARNING"
		drift_warnings += 1
	
	var result = {
		"beat_number": beat_count,
		"actual_time": actual_beat_time,
		"expected_time": expected_beat_time,
		"drift_ms": drift * 1000.0,
		"total_drift_ms": drift_accumulator * 1000.0,
		"drift_severity": drift_severity,
		"time_since_start": current_time - start_time
	}
	
	# Update expected time for next beat
	expected_beat_time += beat_interval
	
	return result

# Get current performance summary
func get_performance_summary() -> Dictionary:
	var avg_fps = 0.0
	if frame_times.size() > 0:
		var avg_frame_time = 0.0
		for ft in frame_times:
			avg_frame_time += ft
		avg_frame_time /= frame_times.size()
		avg_fps = 1.0 / avg_frame_time if avg_frame_time > 0 else 0.0
	
	return {
		"average_fps": avg_fps,
		"total_beats": total_beats,
		"dropped_frames": dropped_frames,
		"drift_warnings": drift_warnings,
		"drift_criticals": drift_criticals,
		"total_drift_ms": drift_accumulator * 1000.0,
		"drift_per_beat_ms": (drift_accumulator / max(1, total_beats)) * 1000.0
	}

# Format timing data for logging
func format_beat_log(beat_data: Dictionary) -> String:
	var lines = []
	lines.append("[AudioTiming] Beat %d at %.3f" % [beat_data.beat_number, beat_data.actual_time])
	lines.append("  Expected: %.3f | Drift: %.1fms | Total: %.1fms | %s" % [
		beat_data.expected_time,
		beat_data.drift_ms,
		beat_data.total_drift_ms,
		beat_data.drift_severity
	])
	return "\n".join(lines)

func format_frame_drop_log(frame_data: Dictionary) -> String:
	return "[AudioTiming] FRAME DROP! %.1fms (%.1f FPS)" % [
		frame_data.frame_time * 1000.0,
		frame_data.current_fps
	]

func format_performance_log() -> String:
	var summary = get_performance_summary()
	var lines = []
	lines.append("[AudioTiming] === PERFORMANCE SUMMARY ===")
	lines.append("  Average FPS: %.1f" % summary.average_fps)
	lines.append("  Total beats: %d" % summary.total_beats)
	lines.append("  Dropped frames: %d" % summary.dropped_frames)
	lines.append("  Drift warnings: %d" % summary.drift_warnings)
	lines.append("  Drift criticals: %d" % summary.drift_criticals)
	lines.append("  Total drift: %.1fms" % summary.total_drift_ms)
	lines.append("  Drift per beat: %.2fms" % summary.drift_per_beat_ms)
	return "\n".join(lines)

# Utility to check if we're maintaining good sync
func is_sync_healthy() -> bool:
	var summary = get_performance_summary()
	return summary.drift_criticals == 0 and abs(summary.drift_per_beat_ms) < 5.0