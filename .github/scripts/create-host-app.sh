#!/usr/bin/env bash
# Generates a throwaway Flutter app that depends on this plugin by path, so CI can prove the
# plugin's native Android/iOS code still compiles for a consumer. Needs no credentials.
# Usage: create-host-app.sh <dest-dir>
set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEST="${1:?usage: create-host-app.sh <dest-dir>}"

flutter create --platforms=android,ios --org com.flex.ci --project-name plugin_host "$DEST"
cd "$DEST"
flutter pub add flex_checkout_flutter --path "$PLUGIN_DIR"

# Each patch must match exactly once; a Flutter template change then fails loudly instead of
# silently producing an app that no longer reflects what a real consumer sets up.
python3 - <<'PY'
import re

def patch(path, pattern, repl, flags=0):
    src = open(path).read()
    out, n = re.subn(pattern, repl, src, count=1, flags=flags)
    if n != 1:
        raise SystemExit(f"host-app patch did not apply: {path}: {pattern}")
    open(path, "w").write(out)

# Android: the native SDK is published on JitPack, and requires minSdk 26.
patch("android/build.gradle.kts", r"mavenCentral\(\)",
      'mavenCentral()\n        maven { url = uri("https://jitpack.io") }')
patch("android/app/build.gradle.kts", r"minSdk = flutter\.minSdkVersion", "minSdk = 26")

# iOS: the native SDK requires iOS 15.
patch("ios/Podfile", r"^# platform :ios, '[0-9.]+'", "platform :ios, '15.0'", re.M)
patch("ios/Podfile", r"(flutter_additional_ios_build_settings\(target\)\n)",
      r"\1    target.build_configurations.each { |c| c.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0' }\n")
src = open("ios/Runner.xcodeproj/project.pbxproj").read()
src = re.sub(r"IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;", "IPHONEOS_DEPLOYMENT_TARGET = 15.0;", src)
open("ios/Runner.xcodeproj/project.pbxproj", "w").write(src)
PY
