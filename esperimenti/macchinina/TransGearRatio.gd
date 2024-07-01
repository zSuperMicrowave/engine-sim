extends Resource
class_name GearRatio

@export_range(1,9) var n := 1
@export_range(1,9) var over_d := 2
@export_range(1,40) var teeth_multiplier := 3
var enabled := false

func get_ratio() -> float:
	return float(n) / float(over_d)
