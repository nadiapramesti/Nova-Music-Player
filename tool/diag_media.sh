#!/usr/bin/env bash
# Jalan di dalam emulator runner: putar lagu, lalu cek apakah Android ngenalin sesi media Nova.
set -x
mkdir -p diag
adb shell pm grant com.nadia.nova android.permission.POST_NOTIFICATIONS || true
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/media_session_test.dart \
  --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk > diag/drive.txt 2>&1 &
DRIVE=$!
sleep 50
adb shell dumpsys media_session > diag/media_session.txt
adb shell dumpsys notification --noredact > diag/notification.txt
adb logcat -d > diag/logcat.txt
adb shell cmd statusbar expand-notifications; sleep 4
adb exec-out screencap -p > diag/1-shade.png
adb shell uiautomator dump /sdcard/shade.xml >/dev/null; adb shell cat /sdcard/shade.xml > diag/shade.xml
adb shell cmd statusbar expand-settings; sleep 4
adb exec-out screencap -p > diag/2-quick-settings.png
adb shell cmd statusbar collapse; sleep 1
adb shell input keyevent 26; sleep 3
adb shell input keyevent 224; sleep 4
adb exec-out screencap -p > diag/3-lock-screen.png
adb shell uiautomator dump /sdcard/lock.xml >/dev/null; adb shell cat /sdcard/lock.xml > diag/lock.xml
wait $DRIVE
echo "===== drive"; grep -E "NOVA_PLAYING|All tests passed|Some tests failed|Exception" diag/drive.txt | head
echo "===== media_session"; sed -n '1,200p' diag/media_session.txt
echo "===== notification (nova)"; grep -c "com.nadia.nova" diag/notification.txt; grep -n "com.nadia.nova" diag/notification.txt | head -20
grep -n -B2 -A30 "NotificationRecord.*com.nadia.nova" diag/notification.txt | head -80
echo "===== logcat"; grep -iE "audioservice|AudioService|startForeground|ForegroundService|notif|nova" diag/logcat.txt | grep -viE "bluetooth|gms" | tail -60
echo "===== shade text"; grep -oE 'text="[^"]+"|content-desc="[^"]+"' diag/shade.xml | head -60
echo "===== lock text"; grep -oE 'text="[^"]+"|content-desc="[^"]+"' diag/lock.xml | head -40
exit 0
