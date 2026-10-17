extends Node
## Yerel bildirimler: iOS'ta SnugloBridge (UNUserNotificationCenter, ios/plugins/snuglo_bridge);
## masaüstünde/testte no-op, is_supported() false → UI bildirim seçeneklerini gizler.
## Swift kuralları (DailyReminderService / NotificationService):
## - Günlük hatırlatma: "snuglo.daily.reminder", her gün yerel hour:minute (varsayılan 19:00),
##   tekrar eden takvim tetikleyicisi; açarken izin iste, reddedilirse ayarı geri kapat.
##   Metin: notif.daily.title / notif.daily.body.
## - Geri dönüş: uygulama arka plana geçince (ayar açıksa) +2 gün ve +7 gün tek seferlik
##   ("snuglo.comeback.2d"/".7d"); her ön plana dönüşte iptal edilir. notif.comeback.*.
## - Açılışta izin kaldırıldıysa daily_reminder ayarını kapat.

const DAILY_ID := "snuglo.daily.reminder"
const COMEBACK := [["snuglo.comeback.2d", 2 * 86400], ["snuglo.comeback.7d", 7 * 86400]]
const AUTHORIZED := [2, 3, 4]   # UNAuthorizationStatus: authorized, provisional, ephemeral

var _b: Object = null
var _pending: Array[Callable] = []

func _ready() -> void:
	if OS.get_name() == "iOS" and Engine.has_singleton("SnugloBridge"):
		_b = Engine.get_singleton("SnugloBridge")
		_b.permission_result.connect(_on_permission)
		_b.authorization_status.connect(_on_auth_status)
		_b.refresh_authorization()
	Events.settings_changed.connect(_on_setting)

func _exit_tree() -> void:
	if _b == null:
		return
	if _b.permission_result.is_connected(_on_permission):
		_b.permission_result.disconnect(_on_permission)
	if _b.authorization_status.is_connected(_on_auth_status):
		_b.authorization_status.disconnect(_on_auth_status)
	_b = null

func is_supported() -> bool:
	return _b != null

## İzin iste; sonuç callback(bool). Desteklenmiyorsa false.
func request_permission(callback: Callable) -> void:
	if _b == null:
		callback.call(false)
		return
	_pending.append(callback)
	if _pending.size() == 1:
		_b.request_permission()

func _on_permission(granted: bool) -> void:
	var cbs := _pending.duplicate()
	_pending.clear()
	for cb in cbs:
		if cb.is_valid():
			cb.call(granted)

## Açılış denetimi: kullanıcı iOS Ayarlar'dan izni kaldırdıysa hatırlatma ayarını kapat.
func _on_auth_status(status: int) -> void:
	if status in AUTHORIZED:
		if Settings.daily_reminder:
			schedule_daily(Settings.reminder_hour, Settings.reminder_minute)
	elif Settings.daily_reminder:
		Settings.daily_reminder = false

func schedule_daily(hour: int, minute: int) -> void:
	if _b:
		_b.schedule_daily(hour, minute, tr("notif.daily.title"), tr("notif.daily.body"))

func cancel_daily() -> void:
	if _b:
		_b.cancel(DAILY_ID)

## Arka plana geçişte çağır (Settings.comeback_reminders açıksa).
func schedule_comeback() -> void:
	if _b == null:
		return
	for c in COMEBACK:
		_b.schedule_in(float(c[1]), c[0], tr("notif.comeback.title"), tr("notif.comeback.body"))

## Ön plana dönüşte çağır.
func cancel_comeback() -> void:
	if _b == null:
		return
	for c in COMEBACK:
		_b.cancel(c[0])

func _on_setting(key: String) -> void:
	if not is_supported():
		return
	if key in ["daily_reminder", "reminder_hour", "reminder_minute"]:
		if Settings.daily_reminder:
			if key == "daily_reminder":
				# Açılırken izin iste; reddedilirse ayarı geri kapat (Swift setEnabled).
				request_permission(func(ok: bool) -> void:
					if ok:
						schedule_daily(Settings.reminder_hour, Settings.reminder_minute)
					else:
						Settings.daily_reminder = false)
			else:
				schedule_daily(Settings.reminder_hour, Settings.reminder_minute)
		else:
			cancel_daily()
	elif key == "comeback_reminders" and Settings.comeback_reminders:
		request_permission(func(ok: bool) -> void:
			if not ok:
				Settings.comeback_reminders = false)
	elif key == "language" and Settings.daily_reminder:
		schedule_daily(Settings.reminder_hour, Settings.reminder_minute)   # metni yeni dilde yeniden kur

func _notification(what: int) -> void:
	if not is_supported():
		return
	if what == NOTIFICATION_APPLICATION_PAUSED and Settings.comeback_reminders:
		schedule_comeback()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		cancel_comeback()
