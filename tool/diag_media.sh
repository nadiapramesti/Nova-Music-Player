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
adb shell cmd statusbar expand-notifications; sleep 4
adb exec-out screencap -p > diag/1-shade.png
adb shell cmd statusbar expand-settings; sleep 4
adb exec-out screencap -p > diag/2-quick-settings.png
adb shell cmd statusbar collapse; sleep 1
adb shell input keyevent 26; sleep 3
adb shell input keyevent 224; sleep 4
adb exec-out screencap -p > diag/3-lock-screen.png
wait $DRIVE
echo "===== drive"; grep -E "NOVA_PLAYING|All tests passed|Some tests failed|Exception" diag/drive.txt | head
echo "===== media_session"; sed -n '1,200p' diag/media_session.txt
echo "===== notification (nova)"; grep -n -A40 "pkg=com.nadia.nova" diag/notification.txt | head -120
exit 0
