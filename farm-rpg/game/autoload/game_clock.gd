extends Node
## Spielzeit. Ein Spieltag läuft von DAY_START_HOUR bis 24:00, danach beginnt der nächste Tag.
## Selbstständig (keine Abhängigkeit zu anderen Autoloads), daher ohne Szene testbar.

signal time_changed(hour: int, minute: int)
signal day_started(day: int)

const MINUTES_PER_HOUR: int = 60
const HOURS_PER_DAY: int = 24
const DAY_START_HOUR: int = 6

## Echtsekunden pro Spielminute.
@export var seconds_per_game_minute: float = 0.7

var day: int = 1
var hour: int = DAY_START_HOUR
var minute: int = 0
var paused: bool = true

var _accumulator: float = 0.0


func _process(delta: float) -> void:
	if paused:
		return
	_accumulator += delta
	while _accumulator >= seconds_per_game_minute:
		_accumulator -= seconds_per_game_minute
		advance_minutes(1)


func advance_minutes(amount: int) -> void:
	for _i in amount:
		minute += 1
		if minute >= MINUTES_PER_HOUR:
			minute = 0
			hour += 1
		if hour >= HOURS_PER_DAY:
			start_next_day()
		else:
			time_changed.emit(hour, minute)


func start_next_day() -> void:
	day += 1
	hour = DAY_START_HOUR
	minute = 0
	day_started.emit(day)
	time_changed.emit(hour, minute)
