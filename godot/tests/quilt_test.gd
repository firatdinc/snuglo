extends SceneTree
## Yorganım testleri: encode/decode determinizmi, 64'te tamamlanma, kayıt.
## godot --headless --path godot -s tests/quilt_test.gd

var fails := 0
var passes := 0
var _tmp := ""

func _init() -> void:
	_tmp = OS.get_user_data_dir().path_join("snuglo_quilt_test.json")
	OS.set_environment("SNUG_SAVE", _tmp)
	OS.set_environment("SNUG_MUTE", "1")

func _initialize() -> void:
	_run.call_deferred()

func _check(name: String, ok: bool, detail := "") -> void:
	if ok:
		passes += 1
		print("PASS ", name)
	else:
		fails += 1
		print("FAIL ", name, "  ", detail)

func _run() -> void:
	create_timer(60.0).timeout.connect(func() -> void:
		print("FAIL zaman aşımı")
		quit(1))
	await process_frame
	var save := root.get_node("/root/Save")
	save.path = _tmp
	save.reset_all()
	var quilt := root.get_node("/root/Quilt")
	quilt.reset()
	# Gerçek bir bölüm: referans çözümden occ kur.
	var lvl: LevelData = LevelGenerator.generate("cozy_beginnings", 1, 5)
	if lvl == null:
		_check("level üret", false, "LevelGenerator.generate yok")
	else:
		var occ := {}
		for p in lvl.pieces:
			var o: Vector2i = lvl.solution[p.id]
			for c in p.cells:
				occ[c + o] = p.id
		var a: Dictionary = quilt.encode("cozy_beginnings-1", lvl.width, occ, lvl.pieces, 3, 12.34, "classic", 1000)
		var b: Dictionary = quilt.encode("cozy_beginnings-1", lvl.width, occ, lvl.pieces, 3, 12.34, "classic", 1000)
		_check("encode deterministik", a == b)
		_check("g uzunluğu w*w", String(a.g).length() == lvl.width * lvl.width)
		_check("boş hücre yok", not String(a.g).contains("."))
		var dec: Array = quilt.decode(a)
		_check("parça sayısı", dec.size() == lvl.pieces.size(), "%d vs %d" % [dec.size(), lvl.pieces.size()])
		var cells := 0
		for d in dec:
			cells += (d.cells as Array).size()
		_check("hücre toplamı", cells == lvl.width * lvl.width)
		_check("renk korunur", int(dec[0].color) == int(lvl.pieces[0].color_index))
		_check("trim gold", quilt.trim_of(a) == "gold")
		_check("trim daily", quilt.trim_of({"id": "daily-2", "s": 3}) == "daily")
		for i in 63:
			quilt.add_patch(a.duplicate())
		_check("63 yama", quilt.current().size() == 63 and quilt.completed_count() == 0)
		var got := [false]
		quilt.quilt_completed.connect(func(_n: int) -> void: got[0] = true)
		quilt.add_patch(a.duplicate())
		_check("64'te tamamlandı", got[0] and quilt.completed_count() == 1 and quilt.current().is_empty())
		_check("toplam 64", quilt.total() == 64)
		# Dikilmemiş yama + oyuncu seçimi
		quilt.reset()
		_check("başta bekleyen yok", quilt.pending_count() == 0)
		quilt.add_pending(a.duplicate())
		quilt.add_pending(b.duplicate())
		_check("bekleyen 2", quilt.pending_count() == 2 and quilt.current().is_empty())
		var r0: int = quilt.sew_next(20, "denim", 4)
		_check("dikildi slot 20", r0 == 20 and quilt.pending_count() == 1 and quilt.current().size() == 1)
		var sp: Dictionary = quilt.current()[0]
		_check("seçim kayıtta", sp.pt == "plain" and sp.cs == "denim" and int(sp.ci) == 4 and int(sp.slot) == 20)
		_check("tahta verisi korunur", sp.g == a.g and sp.c == a.c)
		_check("dolu yuva reddedilir", quilt.sew_next(20, "classic", 1) == -1 and quilt.pending_count() == 1)
		_check("aralık dışı reddedilir", quilt.sew_next(64, "classic", 1) == -1 and quilt.sew_next(-1, "classic", 1) == -1)
		_check("seyrek yerleşim", quilt.free_slots().size() == 63 and not 20 in quilt.free_slots())
		var bs: Array = quilt.by_slot(quilt.current())
		_check("by_slot", bs.size() == 64 and not (bs[20] as Dictionary).is_empty() and (bs[0] as Dictionary).is_empty())
		save.flush()
		quilt._load()
		_check("kalıcı: bekleyen + seçim", quilt.pending_count() == 1 and quilt.current()[0].cs == "denim")
		# Eski kayıt göçü: pending yok, desensiz yama olduğu gibi kalır
		var sec: Dictionary = save.get_section("quilt")
		sec.erase("pending")
		quilt._load()
		_check("göç: pending boş", quilt.pending_count() == 0)
		_check("göç: eski yama durur", quilt.current().size() == 1)
		# Eski kayıt: slot alanı olmayan yamalar index'lerine göç eder
		var legacy: Array = [a.duplicate(), a.duplicate(), a.duplicate()]
		save.get_section("quilt")["cur"] = legacy
		quilt._load()
		_check("göç: slot atandı", int(quilt.current()[2].slot) == 2 and not quilt.current()[0].has("pt"))
		quilt.add_pending(a.duplicate())
		quilt.reset()
		quilt.add_pending(a.duplicate())
		for i in 63:
			quilt.add_patch(a.duplicate())
		var got2 := [false]
		quilt.quilt_completed.connect(func(_n: int) -> void: got2[0] = true)
		var r: int = quilt.sew_next(quilt.free_slots()[0], "classic", 0)
		_check("64. dikişte yorgan tamamlanır", got2[0] and r >= 0 and quilt.current().is_empty())
		save.flush()
	print("\nquilt: %d geçti, %d kaldı" % [passes, fails])
	DirAccess.remove_absolute(_tmp)
	quit(1 if fails > 0 else 0)
