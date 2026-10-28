extends Node
## Tracks the four required Grail fragments independently from excavation sites.

signal fragment_collected(fragment_id: int, collected_count: int)
signal fragment_damaged(fragment_id: int)

enum FragmentState { UNCOLLECTED, INTACT, DAMAGED }

const REQUIRED_FRAGMENT_IDS := [1, 2, 3, 4]
const REQUIRED_COUNT := 4

var _states: Dictionary = {}


func _ready() -> void:
	for fragment_id in REQUIRED_FRAGMENT_IDS:
		_states[fragment_id] = FragmentState.UNCOLLECTED


func collect_fragment(fragment_id: int) -> bool:
	if not _states.has(fragment_id) or _states[fragment_id] != FragmentState.UNCOLLECTED:
		return false
	_states[fragment_id] = FragmentState.INTACT
	fragment_collected.emit(fragment_id, collected_count())
	return true


func damage_fragment(fragment_id: int) -> bool:
	if not _states.has(fragment_id) or _states[fragment_id] == FragmentState.DAMAGED:
		return false
	_states[fragment_id] = FragmentState.DAMAGED
	fragment_damaged.emit(fragment_id)
	return true


func collected_count() -> int:
	var count := 0
	for fragment_id in REQUIRED_FRAGMENT_IDS:
		if _states.get(fragment_id, FragmentState.UNCOLLECTED) == FragmentState.INTACT:
			count += 1
	return count


func has_all_intact() -> bool:
	if _states.size() != REQUIRED_COUNT:
		return false
	for fragment_id in REQUIRED_FRAGMENT_IDS:
		if _states.get(fragment_id, FragmentState.UNCOLLECTED) != FragmentState.INTACT:
			return false
	return true
