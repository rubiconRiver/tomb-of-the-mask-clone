class_name StyleScoreManager
extends Node

enum TimingQuality {
	PERFECT,
	GREAT,
	GOOD,
	OFF_BEAT
}

const TIMING_WINDOWS = {
	TimingQuality.PERFECT: 0.05,  # ±50ms
	TimingQuality.GREAT: 0.15,    # ±150ms
	TimingQuality.GOOD: 0.3        # ±300ms
}

const SCORE_MULTIPLIERS = {
	TimingQuality.PERFECT: 3.0,
	TimingQuality.GREAT: 2.0,
	TimingQuality.GOOD: 1.5,
	TimingQuality.OFF_BEAT: 1.0
}

const TIMING_NAMES = {
	TimingQuality.PERFECT: "Perfect!",
	TimingQuality.GREAT: "Great!",
	TimingQuality.GOOD: "Good!",
	TimingQuality.OFF_BEAT: ""
}

var combo_count = 0
var total_moves = 0
var perfect_moves = 0
var on_beat_moves = 0

signal timing_calculated(quality: TimingQuality, multiplier: float)
signal combo_changed(new_combo: int)

func calculate_timing(beat_timer: float, beat_interval: float) -> TimingQuality:
	# Calculate time to nearest beat
	var time_since_beat = beat_timer
	var time_to_next_beat = beat_interval - beat_timer
	var distance_to_beat = min(time_since_beat, time_to_next_beat)
	
	# Check timing windows
	if distance_to_beat <= TIMING_WINDOWS[TimingQuality.PERFECT]:
		return TimingQuality.PERFECT
	elif distance_to_beat <= TIMING_WINDOWS[TimingQuality.GREAT]:
		return TimingQuality.GREAT
	elif distance_to_beat <= TIMING_WINDOWS[TimingQuality.GOOD]:
		return TimingQuality.GOOD
	else:
		return TimingQuality.OFF_BEAT

func register_move(beat_timer: float, beat_interval: float) -> Dictionary:
	total_moves += 1
	var timing = calculate_timing(beat_timer, beat_interval)
	var multiplier = SCORE_MULTIPLIERS[timing]
	
	# Update combo
	if timing != TimingQuality.OFF_BEAT:
		combo_count += 1
		on_beat_moves += 1
		if timing == TimingQuality.PERFECT:
			perfect_moves += 1
	else:
		combo_count = 0
	
	emit_signal("timing_calculated", timing, multiplier)
	emit_signal("combo_changed", combo_count)
	
	return {
		"timing": timing,
		"multiplier": multiplier,
		"name": TIMING_NAMES[timing],
		"combo": combo_count
	}

func get_accuracy() -> float:
	if total_moves == 0:
		return 0.0
	return float(on_beat_moves) / float(total_moves) * 100.0

func get_perfect_percentage() -> float:
	if total_moves == 0:
		return 0.0
	return float(perfect_moves) / float(total_moves) * 100.0

func reset_combo():
	combo_count = 0
	emit_signal("combo_changed", 0)

func reset_all():
	combo_count = 0
	total_moves = 0
	perfect_moves = 0
	on_beat_moves = 0