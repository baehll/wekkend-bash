extends GutTest
## Beispieltest (GUT 9.x). Voraussetzung: addons/gut installiert und aktiviert.

const GameClockScript = preload("res://autoload/game_clock.gd")

var clock: Node


func before_each() -> void:
	clock = GameClockScript.new()
	add_child_autofree(clock)


func test_starts_at_day_one_morning() -> void:
	assert_eq(clock.day, 1)
	assert_eq(clock.hour, GameClockScript.DAY_START_HOUR)
	assert_eq(clock.minute, 0)


func test_sixty_minutes_advance_one_hour() -> void:
	clock.advance_minutes(60)
	assert_eq(clock.hour, GameClockScript.DAY_START_HOUR + 1)
	assert_eq(clock.minute, 0)


func test_day_rolls_over_at_midnight() -> void:
	watch_signals(clock)
	var minutes_until_midnight: int = (GameClockScript.HOURS_PER_DAY - GameClockScript.DAY_START_HOUR) * 60
	clock.advance_minutes(minutes_until_midnight)
	assert_eq(clock.day, 2)
	assert_eq(clock.hour, GameClockScript.DAY_START_HOUR)
	assert_signal_emitted(clock, "day_started")


func test_paused_clock_does_not_advance() -> void:
	clock.paused = true
	clock._process(100.0)
	assert_eq(clock.minute, 0)
