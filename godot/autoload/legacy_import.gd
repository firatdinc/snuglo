class_name LegacyImport
extends RefCounted
## Eski SwiftUI sürümünün (v1.2.0, com.snuglo.app) UserDefaults kaydını yeni bölümlere çevirir.
## Girdi: native köprünün okuduğu {anahtar: değer}. Codable anahtarları JSON Data'dır: String,
## PackedByteArray (UTF-8) ya da önceden ayrıştırılmış Dictionary/Array kabul edilir.
## Swift Date (JSONEncoder varsayılanı) = 2001-01-01'den beri saniye.
## Kullanım: Save.import_legacy(defaults). Dönüş: işlenen anahtar sayısı.

const APPLE_EPOCH := 978307200.0

## Codable blob → Variant (çözülemezse null).
static func blob(v: Variant) -> Variant:
	if v is Dictionary or v is Array:
		return v
	if v is PackedByteArray:
		v = (v as PackedByteArray).get_string_from_utf8()
	if v is String:
		return JSON.parse_string(v)
	return null

## Swift Date (referans saniyesi) → yerel "yyyy-MM-dd".
static func apple_date_key(t: float) -> String:
	var unix := t + APPLE_EPOCH
	var bias := float(Time.get_time_zone_from_system().get("bias", 0)) * 60.0
	return Time.get_date_string_from_unix_time(int(unix + bias))

static func _sec(data: Dictionary, name: String) -> Dictionary:
	if not (data.get(name) is Dictionary):
		data[name] = {}
	return data[name]

## data: Save'in ham sözlüğü (yerinde doldurulur).
static func apply(data: Dictionary, d: Dictionary) -> int:
	var n := 0
	var prog := _sec(data, "progress")
	var wallet := _sec(data, "wallet")
	var settings := _sec(data, "settings")
	var cos := _sec(data, "cosmetics")
	var dr := _sec(data, "daily_reward")
	var pur := _sec(data, "purchases")

	# --- snuglo.progress.v1 (ProgressStore.Snapshot) ---
	var p = blob(d.get("snuglo.progress.v1"))
	if p is Dictionary:
		n += 1
		var levels := {}
		var lp: Dictionary = p.get("levelProgress", {})
		for id in lp:
			# Kule katları Swift'te yanlışlıkla kampanyaya yazılıyordu → alma.
			if String(id).begins_with("tower") or String(id).begins_with("endless"):
				continue
			var e: Dictionary = lp[id]
			var l := {"completed": bool(e.get("isCompleted", false)), "stars": int(e.get("stars", 0))}
			if e.get("bestTime") != null:
				l["best_time"] = float(e.bestTime)
			if e.get("bestHintsUsed") != null:
				l["hints_used"] = int(e.bestHintsUsed)
			if e.get("completedAt") != null:
				l["completed_at"] = apple_date_key(float(e.completedAt))
			levels[id] = l
		prog["levels"] = levels
		var dc = p.get("dailyChallenge")
		var ddate := ""
		var dcount := 0
		if dc is Dictionary:
			ddate = String(dc.get("date", ""))
			dcount = mini(int(dc.get("solvedCount", 0)), Progress.DAILY_LEVELS)
			prog["daily"] = {"date": ddate, "count": dcount}
		var results := {}
		for r in p.get("dailyResults", []):
			if not bool(r.get("solved", false)):
				continue
			var k := String(r.get("date", ""))
			results[k] = {"count": dcount if k == ddate and dcount > 0 else 1,
				"time": float(r.time) if r.get("time") != null else -1.0}
		prog["daily_results"] = results
		prog["daily_longest"] = int(p.get("longestStreak", 0))
		prog["played_days"] = p.get("playedDays", [])
		prog["longest_play_streak"] = int(p.get("longestPlayStreak", 0))
		prog["last_rewarded_streak"] = int(p.get("lastRewardedStreak", 0))
		prog["streak_freezes"] = int(p.get("streakFreezes", 0))
		wallet["hint"] = int(p.get("hintCount", 0))
		if p.get("lastClaimedDate") != null:
			dr["week_last"] = apple_date_key(float(p.lastClaimedDate))
			dr["week_day"] = int(p.get("lastClaimedDay", 0))

	# --- snuglo.wallet.v1 {coin, gem, ticket, cup} ---
	var w = blob(d.get("snuglo.wallet.v1"))
	if w is Dictionary:
		n += 1
		for c in ["coin", "gem", "ticket", "cup"]:
			wallet[c] = int(w.get(c, 0))

	var x = blob(d.get("snuglo.xp.v1"))
	if x is Dictionary:
		n += 1
		_sec(data, "xp")["total"] = maxi(0, int(x.get("totalXP", 0)))

	var a = blob(d.get("snuglo.achievements.v1"))
	if a is Dictionary:
		n += 1
		var known := []
		for e in Achievements.LIST:
			known.append(e.id)
		var un := []
		for id in a.get("unlocked", []):
			if id in known:
				un.append(id)
		_sec(data, "achievements")["unlocked"] = un

	var ch = blob(d.get("snuglo.chests.v1"))
	if ch is Dictionary:
		n += 1
		var cs := _sec(data, "chest")
		cs["progress"] = clampi(int(ch.get("progress", 0)), 0, Chest.SOLVES_PER_CHEST)
		cs["pending"] = maxi(0, int(ch.get("pending", 0)))
		wallet["key"] = maxi(0, int(ch.get("keys", 0) if ch.get("keys") != null else 0))

	var sp = blob(d.get("snuglo.spin.v1"))
	if sp is Dictionary:
		n += 1
		_sec(data, "spin")["last_day"] = int(sp.get("lastSpinDay", -1))

	var q = blob(d.get("snuglo.dailyquests.v1"))
	var wk = blob(d.get("snuglo.weekly.v1"))
	if q is Dictionary or wk is Dictionary:
		var qs := _sec(data, "quests")
		if q is Dictionary:
			n += 1
			qs["day"] = int(q.get("day", -1))
			qs["progress"] = q.get("progress", [0, 0, 0])
			qs["claimed"] = q.get("claimed", [false, false, false])
		if wk is Dictionary:
			n += 1
			qs["week"] = int(wk.get("week", -1))
			qs["weekly_progress"] = int(wk.get("progress", 0))
			qs["weekly_claimed"] = bool(wk.get("claimed", false))

	if d.has("snuglo.cosmetics.v1"):
		n += 1
		var bought := []
		for s in _list(d["snuglo.cosmetics.v1"]):
			if Cosmetics.SWIFT_SKIN.has(s):
				bought.append(Cosmetics.SWIFT_SKIN[s])
		cos["bought"] = bought
	if d.has("snuglo.cosmetics.boards.v1"):
		n += 1
		cos["boards_bought"] = _list(d["snuglo.cosmetics.boards.v1"])
	if d.has("blockSkin"):
		n += 1
		cos["fabric"] = Cosmetics.SWIFT_SKIN.get(String(d.blockSkin), "classic")
	if d.has("boardBackground"):
		n += 1
		cos["board"] = String(d.boardBackground)

	var cal = blob(d.get("snuglo.dailycal.v1"))
	if cal is Dictionary:
		n += 1
		dr["cal_day"] = int(cal.get("claimedCycleDay", 0))
		dr["cal_last"] = int(cal.get("lastClaimedDayNumber", -1))

	if d.has("snuglo.endless.v1"):
		n += 1
		prog["endless_best"] = int(d["snuglo.endless.v1"])
	if d.has("snuglo.packrewards.v1"):
		n += 1
		prog["pack_rewarded"] = _list(d["snuglo.packrewards.v1"])
	if d.has("snuglo.packrewards.pending"):
		n += 1
		prog["pack_pending"] = String(d["snuglo.packrewards.pending"]) if d["snuglo.packrewards.pending"] != null else ""

	var rr = blob(d.get("snuglo.relaxedReward.v1"))
	if rr is Dictionary:
		n += 1
		prog["relaxed"] = {"day": String(rr.get("day", "")), "xp": int(rr.get("xp", 0)), "coin": int(rr.get("coin", 0))}

	var gs = blob(d.get("snuglo.gamesessions.v1"))
	if gs is Dictionary:
		n += 1
		var sessions := {}
		for id in gs:
			var g: Dictionary = gs[id]
			var pl := []
			for e in g.get("placements", []):
				pl.append({"piece": String(e.pieceId), "x": int(e.origin.x), "y": int(e.origin.y)})
			sessions[id] = {"fingerprint": String(g.get("fingerprint", "")), "placements": pl,
				"elapsed": int(g.get("elapsedSeconds", 0)), "moves": int(g.get("moveCount", 0)),
				"hints": int(g.get("hintsUsed", 0)), "history": g.get("moveHistory", [])}
		prog["sessions"] = sessions

	# --- Enerji (düz değerler) ---
	if d.has("snuglo.energy.value.v1"):
		n += 1
		var en := _sec(data, "energy")
		en["value"] = clampi(int(d["snuglo.energy.value.v1"]), 0, Energy.MAX)
		var t := float(d.get("snuglo.energy.anchor.v1", 0.0))
		en["anchor"] = t if t > 0.0 else Time.get_unix_time_from_system()
		en["open_levels"] = _list(d.get("snuglo.energy.openlevels.v1", []))

	var nk = blob(d.get("snuglo.nook.v2"))
	if nk is Dictionary:
		n += 1
		var placed := {}
		var src: Dictionary = nk.get("placed", {})
		for k in src:
			placed[k] = int(src[k])
		_sec(data, "nook")["placed"] = placed

	if d.has("snuglo.tower.bestFloor.v1") or d.has("snuglo.tower.currentFloor.v1"):
		n += 1
		var tw := _sec(data, "tower")
		tw["best"] = int(d.get("snuglo.tower.bestFloor.v1", 0))
		tw["current"] = int(d.get("snuglo.tower.currentFloor.v1", 0))

	# --- Satın almalar (önbellek; gerçek hak RevenueCat'ten tazelenir) ---
	if d.has("snuglo.purchased.v1"):
		n += 1
		var owned := []
		for id in _list(d["snuglo.purchased.v1"]):
			if id in Purchases.NON_CONSUMABLE:
				owned.append(id)
		pur["owned"] = owned
	if d.has("snuglo.premium.active"):
		n += 1
		pur["premium"] = bool(d["snuglo.premium.active"])
	if d.has("snuglo.ads.removed"):
		n += 1
		pur["ads_removed"] = bool(d["snuglo.ads.removed"])

	if d.has("snuglo.ads.rewarded.count"):
		n += 1
		var ads := _sec(data, "ads")
		ads["count"] = int(d["snuglo.ads.rewarded.count"])
		ads["day"] = Progress.key_from_number(int(d.get("snuglo.ads.rewarded.day", 0)))
		ads["last"] = float(d.get("snuglo.ads.rewarded.last", 0.0))
	if d.has("snuglo.ads.consent"):
		n += 1
		_sec(data, "ads")["consent"] = bool(d["snuglo.ads.consent"])
	if d.has("snuglo.version.dismissedSoft"):
		n += 1
		_sec(data, "version")["dismissed_soft"] = String(d["snuglo.version.dismissedSoft"])

	# --- Tercihler ---
	var prefs := {
		"musicEnabled": "music_enabled", "musicVolume": "music_volume", "musicTrack": "music_track",
		"sfxEnabled": "sfx_enabled", "sfxVolume": "sfx_volume", "hapticsEnabled": "haptics",
		"hapticLevel": "haptic_level", "soundPack": "sound_pack", "zenMode": "zen_mode",
		"colorblindMode": "colorblind", "appTheme": "theme", "comebackRemindersEnabled": "comeback_reminders",
		"coachShown": "coach_shown", "hasOnboarded": "onboarded", "hasRequestedReview": "review_requested",
	}
	for k in prefs:
		if d.has(k):
			n += 1
			settings[prefs[k]] = d[k]
	if d.has("dailyReminderEnabled") or d.has("snuglo.dailyReminder.enabled"):
		n += 1
		settings["daily_reminder"] = bool(d.get("dailyReminderEnabled", false)) \
			or bool(d.get("snuglo.dailyReminder.enabled", false))
	if d.has("dailyReminderTime"):
		# Swift: Date(timeIntervalSinceReferenceDate:) → yerel saat:dakika.
		n += 1
		var bias := float(Time.get_time_zone_from_system().get("bias", 0)) * 60.0
		var t := Time.get_datetime_dict_from_unix_time(int(float(d.dailyReminderTime) + APPLE_EPOCH + bias))
		settings["reminder_hour"] = int(t.hour)
		settings["reminder_minute"] = int(t.minute)
	if d.has("snuglo.language.override"):
		n += 1
		var lang := String(d["snuglo.language.override"])
		settings["language"] = lang if lang in ["en", "tr", "es"] else ""
	if d.has("snuglo.cloud.rev"):
		data["cloud_rev"] = int(d["snuglo.cloud.rev"])
	return n

static func _list(v: Variant) -> Array:
	if v is Array:
		return v
	var parsed = blob(v)
	return parsed if parsed is Array else []
