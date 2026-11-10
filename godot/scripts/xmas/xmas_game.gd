class_name XmasGame
extends Screen
## Noel mini oyun ekranı tabanı: Noel sahnesi + kar + başlık + paylaş butonu + çalışma alanı.
## Alt sınıf: GAME (Xmas.GAMES içinden), TITLE_KEY ayarlar; setup_game(area: Rect2) içinde
## oyununu kurar. Kayıt: `state` (= Xmas.data(GAME)), değişince `Xmas.save()`.
## Kaybetme/zamanlayıcı yok; ilerleme `state.progress` (0..1) köy kartında görünür.

var GAME := ""
var TITLE_KEY := ""
var state: Dictionary
var area := Rect2()          ## mini oyunun serbest alanı (başlık altı → alt güvenli bölge)
var snow: XmasKit.Snow
var BG_SCENE := "christmas"   ## alt sınıf değiştirebilir (art/scene_winter/<ad>.jpg ya da art/scene)
var BG_WASH := Vector2(0.35, 0.55)

func build() -> void:
	state = Xmas.data(GAME)
	var bg := SceneBackdrop.new()
	bg.tex = PackArt.scene_by_name(BG_SCENE)
	bg.wash_top = BG_WASH.x
	bg.wash_bottom = BG_WASH.y
	bg.motes = 0
	bg.size = size
	add_child(bg)
	snow = XmasKit.add_snow(self, 28)
	var top := header(TITLE_KEY)
	var sh := Ui.icon_button("ic_share", 120)
	put(sh, Vector2(X0 + W - 150, TOP + 30.0), Vector2(120, 120))
	sh.tapped.connect(func() -> void: XmasKit.share_node(self, area, "xmas.shareText"))
	area = Rect2(Vector2(X0, top), Vector2(W, H - top - BOTTOM))
	setup_game(area)
	move_child(snow, get_child_count() - 1)

func setup_game(_r: Rect2) -> void:
	pass

func set_progress(v: float) -> void:
	state.progress = clampf(v, 0.0, 1.0)
	Xmas.save()
