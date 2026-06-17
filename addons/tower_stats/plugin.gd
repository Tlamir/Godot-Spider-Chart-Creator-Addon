@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type(
		"TowerSpiderChart",
		"Control",
		preload("res://addons/tower_stats/ui/tower_spider_chart.gd"),
		null
	)
	add_custom_type(
		"TowerStats",
		"Resource",
		preload("res://addons/tower_stats/resources/tower_stats.gd"),
		null
	)
	add_custom_type(
		"TowerStat",
		"Resource",
		preload("res://addons/tower_stats/resources/tower_stat.gd"),
		null
	)

func _exit_tree() -> void:
	remove_custom_type("TowerSpiderChart")
	remove_custom_type("TowerStats")
	remove_custom_type("TowerStat")
