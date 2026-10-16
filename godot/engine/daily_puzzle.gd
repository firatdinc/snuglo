class_name DailyPuzzle
extends RefCounted
## Tarih tabanlı günlük bulmaca (UTC). Swift DailyPuzzle ile aynı seed ve grid rotasyonu.

static func for_date(year: int, month: int, day: int, index: int = 0) -> LevelData:
	var unix := Time.get_unix_time_from_datetime_dict({"year": year, "month": month, "day": day, "hour": 12})
	var wd: int = Time.get_datetime_dict_from_unix_time(unix).weekday  # 0=Pazar
	return LevelGenerator.generate("daily", index, grid_size(wd), year * 10000 + month * 100 + day)

static func today(index: int = 0) -> LevelData:
	var d := Time.get_datetime_dict_from_system(true)
	return for_date(d.year, d.month, d.day, index)

## Godot weekday 0=Pazar … 6=Cumartesi.
static func grid_size(weekday: int) -> int:
	match weekday:
		1, 5: return 5
		2, 6: return 6
		3, 0: return 7
		4: return 8
	return 5
