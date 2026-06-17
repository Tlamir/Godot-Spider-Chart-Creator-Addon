@tool
class_name TowerStat
extends Resource

## A single stat entry for a tower. Add as many as you want to TowerStats.
## Each stat has a label, a current value, and a max value (used for chart scaling).

@export var label: String = "Stat":
	set(v):
		label = v
		emit_changed()

@export var value: float = 0.0:
	set(v):
		value = clampf(v, 0.0, max_value)
		emit_changed()

@export var max_value: float = 100.0:
	set(v):
		max_value = maxf(v, 0.001)
		# Re-clamp value
		value = clampf(value, 0.0, max_value)
		emit_changed()

## Returns value normalized 0..1 relative to max_value
func normalized() -> float:
	if max_value <= 0.0:
		return 0.0
	return value / max_value
