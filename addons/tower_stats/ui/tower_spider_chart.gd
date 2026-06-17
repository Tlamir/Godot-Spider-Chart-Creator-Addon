@tool
class_name TowerSpiderChart
extends Control

## TowerSpiderChart — runs fully in the editor via @tool.
## Assign a TowerStats resource and the chart draws instantly.

# ── Resource ─────────────────────────────────────────────────────────────────

@export var tower_stats: TowerStats = null:
	set(v):
		if tower_stats and tower_stats.changed.is_connected(queue_redraw):
			tower_stats.changed.disconnect(queue_redraw)
		tower_stats = v
		if tower_stats:
			tower_stats.changed.connect(queue_redraw)
		queue_redraw()

# ── Appearance ────────────────────────────────────────────────────────────────

@export_group("Chart Style")

@export_range(2, 8) var grid_rings: int = 4:
	set(v): grid_rings = v; queue_redraw()

## How much of the control the chart occupies (leaves room for labels)
@export_range(0.2, 0.85) var radius_fraction: float = 0.55:
	set(v): radius_fraction = v; queue_redraw()

## Background is transparent by default — only the chart area gets a panel
@export var draw_background_panel: bool = false:
	set(v): draw_background_panel = v; queue_redraw()

@export var color_background: Color  = Color(0.07, 0.07, 0.10, 0.92):
	set(v): color_background = v; queue_redraw()

@export var color_grid: Color        = Color(1.0, 1.0, 1.0, 0.08):
	set(v): color_grid = v; queue_redraw()

@export var color_axis: Color        = Color(1.0, 1.0, 1.0, 0.20):
	set(v): color_axis = v; queue_redraw()

@export var color_fill: Color        = Color(0.28, 0.72, 1.0, 0.20):
	set(v): color_fill = v; queue_redraw()

@export var color_stroke: Color      = Color(0.28, 0.72, 1.0, 0.90):
	set(v): color_stroke = v; queue_redraw()

@export var color_label: Color       = Color(0.90, 0.90, 1.00, 1.0):
	set(v): color_label = v; queue_redraw()

@export var color_value: Color       = Color(0.55, 0.95, 0.65, 1.0):
	set(v): color_value = v; queue_redraw()

@export var color_empty_text: Color  = Color(0.5, 0.5, 0.6, 0.7):
	set(v): color_empty_text = v; queue_redraw()

@export var stroke_width: float = 2.0:
	set(v): stroke_width = v; queue_redraw()

@export var dot_radius: float = 4.0:
	set(v): dot_radius = v; queue_redraw()

## Pixels between the outermost ring and the label anchor point
@export var label_padding: float = 10.0:
	set(v): label_padding = v; queue_redraw()

@export_group("Font")
@export var font_size_label: int = 12:
	set(v): font_size_label = v; queue_redraw()
@export var font_size_value: int = 10:
	set(v): font_size_value = v; queue_redraw()
@export var font_size_title: int = 14:
	set(v): font_size_title = v; queue_redraw()
@export var font_size_empty: int = 15:
	set(v): font_size_empty = v; queue_redraw()

# ── Palette ───────────────────────────────────────────────────────────────────

const _PALETTE := [
	Color(0.28, 0.72, 1.00),
	Color(1.00, 0.60, 0.20),
	Color(0.40, 0.90, 0.55),
	Color(0.90, 0.35, 0.55),
	Color(0.75, 0.45, 1.00),
	Color(0.25, 0.90, 0.90),
	Color(1.00, 0.90, 0.25),
	Color(1.00, 0.45, 0.35),
]

# ── Draw ──────────────────────────────────────────────────────────────────────

func _draw() -> void:
	var font   : Font   = ThemeDB.fallback_font
	var size   : Vector2 = get_size()
	var center : Vector2 = size / 2.0

	# Leave a margin so labels have room — radius is based on the smaller axis
	var radius : float = minf(center.x, center.y) * radius_fraction

	# Optional full background
	if draw_background_panel:
		draw_rect(Rect2(Vector2.ZERO, size), color_background)

	# ── Empty / no-resource state ─────────────────────────────────────────────
	if tower_stats == null or tower_stats.stats.is_empty():
		_draw_empty_state(size, center, radius, font)
		return

	var valid_stats: Array = tower_stats.stats.filter(func(s): return s != null)
	if valid_stats.is_empty():
		_draw_empty_state(size, center, radius, font)
		return

	var n            := valid_stats.size()
	var angle_offset := -PI / 2.0
	var step         := TAU / float(n)

	# Axis tip positions (on the outer ring)
	var tips: Array[Vector2] = []
	for i in n:
		tips.append(center + Vector2(cos(angle_offset + step * i), sin(angle_offset + step * i)) * radius)

	# ── Background panel clipped to the chart polygon ─────────────────────────
	if not draw_background_panel:
		# Draw a slightly enlarged solid polygon as the chart background
		var bg_pts: PackedVector2Array = []
		for i in n:
			var a := angle_offset + step * i
			bg_pts.append(center + Vector2(cos(a), sin(a)) * (radius + 2.0))
		draw_colored_polygon(bg_pts, Color(0.07, 0.07, 0.10, 0.88))

	# ── Grid rings ────────────────────────────────────────────────────────────
	for r in range(1, grid_rings + 1):
		var t := float(r) / float(grid_rings)
		var ring: PackedVector2Array = []
		for i in n:
			ring.append(center + Vector2(cos(angle_offset + step * i), sin(angle_offset + step * i)) * radius * t)
		ring.append(ring[0])
		draw_polyline(ring, color_grid, 1.0, true)

	# ── Axis lines ────────────────────────────────────────────────────────────
	for i in n:
		draw_line(center, tips[i], color_axis, 1.0, true)

	# ── Data polygon ──────────────────────────────────────────────────────────
	var is_all_zero := tower_stats.is_empty()
	var data_pts: PackedVector2Array = []
	for i in n:
		var stat: TowerStat = valid_stats[i]
		var a := angle_offset + step * i
		data_pts.append(center + Vector2(cos(a), sin(a)) * radius * stat.normalized())

	if not is_all_zero:
		var fill_pts := PackedVector2Array([center])
		fill_pts.append_array(data_pts)
		fill_pts.append(data_pts[0])
		draw_colored_polygon(fill_pts, color_fill)

		var stroke_pts := data_pts.duplicate()
		stroke_pts.append(data_pts[0])
		draw_polyline(stroke_pts, color_stroke, stroke_width, true)

		for i in n:
			var stat: TowerStat = valid_stats[i]
			draw_circle(data_pts[i], dot_radius, _stat_color(stat, i))

	# ── Labels ────────────────────────────────────────────────────────────────
	for i in n:
		var stat : TowerStat = valid_stats[i]
		var a    := angle_offset + step * i
		var cos_a := cos(a)
		var sin_a := sin(a)
		var tip  := tips[i]

		# Anchor point just outside the outer ring
		var anchor := tip + Vector2(cos_a, sin_a) * label_padding

		# Determine horizontal alignment & x nudge so text doesn't overlap axis
		var h_align := HORIZONTAL_ALIGNMENT_CENTER
		var x_nudge := 0.0
		if cos_a > 0.15:
			h_align = HORIZONTAL_ALIGNMENT_LEFT
			x_nudge = 0.0
		elif cos_a < -0.15:
			h_align = HORIZONTAL_ALIGNMENT_RIGHT
			x_nudge = 0.0

		# Vertical nudge: push down if axis points downward
		var line_h := float(font_size_label)
		var y_nudge := 0.0
		if sin_a > 0.15:
			y_nudge = 0.0        # axis goes down  → anchor is below ring, text starts here
		elif sin_a < -0.15:
			y_nudge = -line_h    # axis goes up    → shift text up so it sits above ring

		var lbl_pos := anchor + Vector2(x_nudge, y_nudge)

		# Stat name
		draw_string(font, lbl_pos, stat.label,
			h_align, -1, font_size_label, color_label)

		# Value line below name
		var val_str := "%.1f / %.0f" % [stat.value, stat.max_value]
		draw_string(font, lbl_pos + Vector2(0, font_size_label + 2), val_str,
			h_align, -1, font_size_value, color_value)

	# ── Title ─────────────────────────────────────────────────────────────────
	if tower_stats.tower_name != "":
		draw_string(font,
			Vector2(size.x * 0.5, float(font_size_title) + 4.0),
			tower_stats.tower_name,
			HORIZONTAL_ALIGNMENT_CENTER, -1, font_size_title,
			Color(1.0, 1.0, 1.0, 0.55))

	# ── All-zero overlay ──────────────────────────────────────────────────────
	if is_all_zero:
		draw_string(font, Vector2(size.x * 0.5, center.y + 8.0),
			"All stats are 0",
			HORIZONTAL_ALIGNMENT_CENTER, -1, font_size_label,
			Color(color_empty_text.r, color_empty_text.g, color_empty_text.b, 0.55))


func _draw_empty_state(size: Vector2, center: Vector2, radius: float, font: Font) -> void:
	# Ghost placeholder pentagon
	var n    := 5
	var step := TAU / float(n)
	var ao   := -PI / 2.0
	var r_scale := radius * 0.55

	# Dark background panel in the shape of the placeholder
	var bg: PackedVector2Array = []
	for i in n:
		bg.append(center + Vector2(cos(ao + step * i), sin(ao + step * i)) * (r_scale + 2.0))
	draw_colored_polygon(bg, Color(0.07, 0.07, 0.10, 0.88))

	for ring_t in [0.33, 0.66, 1.0]:
		var ring: PackedVector2Array = []
		for i in n:
			ring.append(center + Vector2(cos(ao + step * i), sin(ao + step * i)) * r_scale * ring_t)
		ring.append(ring[0])
		draw_polyline(ring, Color(1, 1, 1, 0.07), 1.0, true)

	for i in n:
		draw_line(center,
			center + Vector2(cos(ao + step * i), sin(ao + step * i)) * r_scale,
			Color(1, 1, 1, 0.10), 1.0)

	# Text
	draw_string(font, Vector2(size.x * 0.5, center.y - 10.0),
		"No TowerStats resource",
		HORIZONTAL_ALIGNMENT_CENTER, -1, font_size_empty, color_empty_text)
	draw_string(font, Vector2(size.x * 0.5, center.y + 9.0),
		"Assign one in the Inspector",
		HORIZONTAL_ALIGNMENT_CENTER, -1, font_size_label,
		Color(color_empty_text.r, color_empty_text.g, color_empty_text.b, 0.40))


func _stat_color(stat: TowerStat, index: int) -> Color:
	if stat.color_override.a > 0.01:
		return stat.color_override
	return _PALETTE[index % _PALETTE.size()]
