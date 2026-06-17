@tool
class_name TowerStats
extends Resource

## TowerStats — attach this resource to any tower node.
## Add/remove/reorder stats freely; the spider chart updates automatically.

@export var tower_name: String = "New Tower":
	set(v):
		tower_name = v
		emit_changed()

## The list of stats. Add TowerStat resources here.
## Stats are fully dynamic — add, remove, or reorder at any time.
@export var stats: Array[TowerStat] = []:
	set(v):
		# Disconnect old signals
		for s in stats:
			if s and s.changed.is_connected(_on_stat_changed):
				s.changed.disconnect(_on_stat_changed)
		stats = v
		# Connect new signals
		for s in stats:
			if s and not s.changed.is_connected(_on_stat_changed):
				s.changed.connect(_on_stat_changed)
		emit_changed()

func _init() -> void:
	# Wire up existing stats when loaded from disk
	for s in stats:
		if s and not s.changed.is_connected(_on_stat_changed):
			s.changed.connect(_on_stat_changed)

func _on_stat_changed() -> void:
	emit_changed()

## Returns true if there are no stats, or all values are zero
func is_empty() -> bool:
	if stats.is_empty():
		return true
	for s in stats:
		if s and s.value > 0.0:
			return false
	return true

## Helper — get a stat by label (case-insensitive). Returns null if not found.
func get_stat(stat_label: String) -> TowerStat:
	for s in stats:
		if s and s.label.to_lower() == stat_label.to_lower():
			return s
	return null

## Helper — set a stat value by label. Does nothing if label not found.
func set_stat(stat_label: String, val: float) -> void:
	var s := get_stat(stat_label)
	if s:
		s.value = val

## Shorthand factory — creates a preset tower stat array
## Usage: TowerStats.make_default_stats()
static func make_default_stats() -> Array[TowerStat]:
	var presets := [
		["Damage",         50.0,  200.0],
		["Speed",          60.0,  100.0],
		["Range",          40.0,  100.0],
		["Crit Chance",    20.0,  100.0],
		["Crit Damage",    150.0, 300.0],
		["Damage/Second",  30.0,  100.0],
		["Area Damage",    25.0,  100.0],
	]
	var result: Array[TowerStat] = []
	for p in presets:
		var stat := TowerStat.new()
		stat.label     = p[0]
		stat.value     = p[1]
		stat.max_value = p[2]
		result.append(stat)
	return result
