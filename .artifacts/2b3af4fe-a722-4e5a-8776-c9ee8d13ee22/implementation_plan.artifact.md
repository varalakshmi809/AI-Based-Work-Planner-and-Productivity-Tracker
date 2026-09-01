# Implementation Plan - Fix Android Emulator Build

The project is currently failing to build for Android due to a persistent Gradle error: `AndroidLocationsBuildService`. This is caused by the space in the Windows username (`veeresh gowda`). This plan aims to force Gradle to use a space-free path for all its internal operations.

## Proposed Changes

### [Android Configuration]

#### [MODIFY] [gradle.properties](file:///C:/Users/veeresh%20gowda/first_flutter_project/ai_work_planner/android/gradle.properties)
- Strengthen the redirection of home directories.
- Add `systemProp.gradle.user.home` to ensure Gradle cache is also away from the space-containing path.

#### [MODIFY] [build.gradle.kts](file:///C:/Users/veeresh%20gowda/first_flutter_project/ai_work_planner/android/app/build.gradle.kts)
- Explicitly set the `buildToolsVersion` to a known stable version if needed. (Optional, will check compatibility first).

### [Environment Variables]

- We will run the build using a "Clean Environment" script that sets `ANDROID_USER_HOME`, `GRADLE_USER_HOME`, and `ANDROID_SDK_HOME` to `C:\AndroidUserHome`.

## Verification Plan

### Automated Tests
- I will run a Gradle dry-run to verify the build services initialize correctly.

### Manual Verification
- Run `flutter run -d emulator-5554` and confirm the app launches on the emulator.
- Verify the AI functionality works (it should work on Android without CORS issues).
