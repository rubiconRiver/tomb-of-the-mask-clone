class_name StyleScoreManager
extends Node

enum TimingQuality {
	PERFECT,
	GREAT,
	GOOD,      # Treated as OFF_BEAT for combo/multiplier purposes
	OFF_BEAT
}

# Base timing windows at 120 BPM (0.5s beat interval)
const BASE_BEAT_INTERVAL = 0.5
const BASE_TIMING_WINDOWS = {
	TimingQuality.PERFECT: 0.05,   # ±50ms at 120 BPM
	TimingQuality.GREAT: 0.12,     # ±120ms at 120 BPM
	TimingQuality.GOOD: 0.2        # ±200ms at 120 BPM
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
var great_moves = 0
var good_moves = 0
var on_beat_moves = 0

# Multiplier system
var current_multiplier = 1
const MAX_MULTIPLIER = 8
const MIN_MULTIPLIER = 1

signal timing_calculated(quality: TimingQuality, multiplier: float)
signal combo_changed(new_combo: int, multiplier_increased: bool)
signal multiplier_changed(new_multiplier: int)

func calculate_timing(beat_timer: float, beat_interval: float) -> Dictionary:
	# Calculate time to nearest beat
	var time_since_beat = beat_timer
	var time_to_next_beat = beat_interval - beat_timer
	var distance_to_beat = min(time_since_beat, time_to_next_beat)
	
	# Determine if early or late
	var is_early = time_to_next_beat < time_since_beat
	
	# Scale timing windows based on BPM
	# Faster BPM = smaller windows, slower BPM = larger windows
	var window_scale = beat_interval / BASE_BEAT_INTERVAL
	
	# Check timing windows with scaling
	var quality = TimingQuality.OFF_BEAT
	if distance_to_beat <= BASE_TIMING_WINDOWS[TimingQuality.PERFECT] * window_scale:
		quality = TimingQuality.PERFECT
	elif distance_to_beat <= BASE_TIMING_WINDOWS[TimingQuality.GREAT] * window_scale:
		quality = TimingQuality.GREAT
	elif distance_to_beat <= BASE_TIMING_WINDOWS[TimingQuality.GOOD] * window_scale:
		quality = TimingQuality.GOOD
	
	return {
		"quality": quality,
		"is_early": is_early,
		"distance": distance_to_beat,
		"window_scale": window_scale
	}

func register_move(beat_timer: float, beat_interval: float) -> Dictionary:
	total_moves += 1
	var timing_result = calculate_timing(beat_timer, beat_interval)
	var quality = timing_result.quality
	var multiplier = SCORE_MULTIPLIERS[quality]
	
	# Update combo and counts based on timing quality
	if quality == TimingQuality.PERFECT or quality == TimingQuality.GREAT:
		# PERFECT/GREAT: Increase combo
		combo_count += 1
		on_beat_moves += 1
		
		match quality:
			TimingQuality.PERFECT:
				perfect_moves += 1
			TimingQuality.GREAT:
				great_moves += 1
		
		# Multiplier only increases when combo catches up, never decreases on hit
		# This allows rebuilding combo without losing multiplier progress
		var multiplier_increased = false
		if combo_count > current_multiplier and current_multiplier < MAX_MULTIPLIER:
			current_multiplier = min(combo_count, MAX_MULTIPLIER)
			multiplier_increased = true
			emit_signal("multiplier_changed", current_multiplier)
		
		# Emit combo changed with multiplier increase info
		emit_signal("combo_changed", combo_count, multiplier_increased)
			
	else:  # GOOD or OFF_BEAT - treat all as off-beat
		# Reset combo and decrease multiplier by 1
		combo_count = 0
		
		# Track the move type
		if quality == TimingQuality.GOOD:
			good_moves += 1
			on_beat_moves += 1  # Still counts for accuracy
		
		# Decrease multiplier by 1 (minimum 1)
		if current_multiplier > MIN_MULTIPLIER:
			current_multiplier -= 1
			emit_signal("multiplier_changed", current_multiplier)
		
		# Combo reset doesn't increase multiplier
		emit_signal("combo_changed", combo_count, false)
	
	emit_signal("timing_calculated", quality, multiplier)
	
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

func get_current_multiplier() -> int:
	return current_multiplier

func reset_combo():
	combo_count = 0
	emit_signal("combo_changed", 0)

func reset_all():
	combo_count = 0
	total_moves = 0
	perfect_moves = 0
	great_moves = 0
	good_moves = 0
	on_beat_moves = 0
	current_multiplier = 1
	emit_signal("multiplier_changed", current_multiplier)

func get_timing_counts() -> Dictionary:
	return {
		"perfect": perfect_moves,
		"great": great_moves,
		"good": good_moves,
		"miss": total_moves - on_beat_moves
	}

func reset_score():
	reset_all()