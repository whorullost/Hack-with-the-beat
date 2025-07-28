extends RefCounted
class_name ColorBleedEvent

# --- EVENT DATA ---
var position: Vector2          # World position where effect appears
var current_radius: float = 0.0  # Current size (animated by tweens)
var max_radius: float          # Maximum size when fully grown
#var timer: float = 0.0         # Generic timer (currently unused)
var state: int = 0             # 0: growing, 1: staying, 2: shrinking
var event_finished: bool = false  # Marks event for cleanup

# This class is a data container that gets animated by the ColorManager
# The shader reads position and current_radius to determine where to show color
