class_name StyleScoreManager
extends Node

enum TimingQuality {
	PERFECT,
	GREAT,
	GOOD,
	OFF_BEAT
}

const TIMING_WINDOWS = {
	TimingQuality.PERFECT: 0.08,  # ±80ms (increased from 50ms)
	TimingQuality.GREAT: 0.2,     # ±200ms (increased from 150ms)
	TimingQuality.GOOD: 0.4       # ±400ms (increased from 300ms)
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

func calculate_timing(beat_timer: float, beat_interval: float) -> Dictionary:
	# Calculate time to nearest beat
	var time_since_beat = beat_timer
	var time_to_next_beat = beat_interval - beat_timer
	var distance_to_beat = min(time_since_beat, time_to_next_beat)
	
	# Determine if early or late
	var is_early = time_to_next_beat < time_since_beat
	
	# Check timing windows
	var quality = TimingQuality.OFF_BEAT
	if distance_to_beat <= TIMING_WINDOWS[TimingQuality.PERFECT]:
		quality = TimingQuality.PERFECT
	elif distance_to_beat <= TIMING_WINDOWS[TimingQuality.GREAT]:
		quality = TimingQuality.GREAT
	elif distance_to_beat <= TIMING_WINDOWS[TimingQuality.GOOD]:
		quality = TimingQuality.GOOD
	
	return {
		"quality": quality,
		"is_early": is_early,
		"distance": distance_to_beat
	}

func register_move(beat_timer: float, beat_interval: float) -> Dictionary:
	total_moves += 1
	var timing_result = calculate_timing(beat_timer, beat_interval)
	var quality = timing_result.quality
	var multiplier = SCORE_MULTIPLIERS[quality]
	
	# Update combo
	if quality != TimingQuality.OFF_BEAT:
		combo_count += 1
		on_beat_moves += 1
		if quality == TimingQuality.PERFECT:
			perfect_moves += 1
	else:
		combo_count = 0
	
	emit_signal("timing_calculated", quality, multiplier)
	emit_signal("combo_changed", combo_count)
	
	return {
		"timing": quality,
		"multiplier": multiplier,
		"name": TIMING_NAMES[quality],
		"combo": combo_count,
		"is_early": timing_result.is_early,
		"distance": timing_result.distance
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