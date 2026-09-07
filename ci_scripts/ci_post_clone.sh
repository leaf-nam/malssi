#!/bin/sh
# Xcode Cloud post-clone: Flutter 산출물(`ios/Flutter/ephemeral/` 등)은
# git에 없으므로 클론 직후 여기서 생성한다.
set -e

# 이 스크립트의 실행 디렉토리는 ci_scripts이며, 저장소 루트로 이동한다.
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Flutter SDK 설치.
if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
fi
export PATH="$HOME/flutter/bin:$PATH"

# iOS 아티팩트 + 의존성 설치. `flutter pub get`이
# `FlutterGeneratedPluginSwiftPackage`를 포함한 ephemeral 파일을 만든다.
flutter precache --ios
flutter pub get

# CocoaPods 의존성 설치 (`ios/Pods/`도 git에 없다).
cd ios && pod install
