extends Node
## Señales globales entre sistemas que no se conocen entre sí.
## Regla: los sistemas emiten aquí y escuchan aquí; nunca leen el estado interno de otro.

signal stamina_changed(value: float, max_value: float, exhausted: bool)
signal player_state_changed(state_name: StringName)
signal pause_changed(paused: bool)
signal mouse_capture_changed(captured: bool)
