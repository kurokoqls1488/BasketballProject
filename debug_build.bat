    ===========================================================
  Flutter / Android Debug Script
  Checks everything, fixes what it can, runs the build
    ===========================================================

  [1/8] JDK Check
echo --- JDK ---
if exist "C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot\bin\java.exe" (
  set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.19.10-hotspot"
  echo [OK] JDK 17 found at %JAVA_HOME%
) else (
  echo [FATAL] JDK 17 not found. Install Adoptium JDK 17.
  exit /b 1
)

  [2/8] Android SDK Check
echo --- Android SDK ---
if not exist "C:\Users\Dan\AppData\Local\Android\sdk\platform-tools\adb.exe" (
  echo [FATAL] ADB not found. Check android\local.properties sdk.dir
  exit /b 1
)
echo [OK] ADB found

  [3/8] Device Check
echo --- Device ---
adb.exe get-state 2>nul
if errorlevel 1 (
  echo [FATAL] No device connected or ADB server not running
  echo        Connect phone with USB debugging enabled
  exit /b 1
)
echo [OK] Device connected

  [4/8] Gradle config check
echo --- Gradle Config ---
set "GP=android\gradle.properties"
set "SW=android\gradle\wrapper\gradle-wrapper.properties"
set "SG=android\settings.gradle.kts"
set "BK=android\app\build.gradle.kts"

echo Checking %GP% ...
findstr /c:"jvmHome=" "%GP%" >nul 2>&1
if errorlevel 1 (
  echo jvmHome not set in gradle.properties
)

echo Checking %SW% ...
findstr /c:"distributionUrl=" "%SW%" >nul
if errorlevel 1 echo [ERROR] distributionUrl missing in gradle-wrapper.properties

echo Checking %BK% ...
findstr /c:"source = " "%BK%" >nul
if errorlevel 1 echo [ERROR] flutter source missing in build.gradle.kts
findstr /c:"target = " "%BK%" >nul
if errorlevel 1 (
  echo [WARN] target path not set in build.gradle.kts - lib\main.dart will be used
)

echo Checking %SG% ...
findstr /c:"defaultPluginManagementRepositories" "%SG%" >nul
if not errorlevel 1 (
  echo [FIX] Removing broken defaultPluginManagementRepositories from settings.gradle.kts
  powershell -Command "(Get-Content android\settings.gradle.kts) -replace '    defaultPluginManagementRepositories \{\r?\n        google\(\)\r?\n    \}\r?\n', '' | Set-Content android\settings.gradle.kts"
)

  [5/8] Gradle cache health
echo --- Gradle Cache ---
if exist "%USERPROFILE%\.gradle\caches\8.14" (
  echo [OK] Gradle cache exists
  dir "%USERPROFILE%\.gradle\caches\8.14" /b | find /c "transforms" >nul
  if errorlevel 0 echo       (transforms present)
) else (
  echo [WARN] No Gradle cache - will be recreated on first build
)

  [6/8] Flutter license check
echo --- Flutter License ---
flutter doctor --android-licenses >nul 2>&1
echo [OK] Licenses checked

  [7/8] Pub packages
echo --- Pub Packages ---
flutter pub get >nul 2>&1
if errorlevel 1 (
  echo [FATAL] flutter pub get failed
  exit /b 1
)
echo [OK] Packages resolved

  [8/8] Build
echo --- Building ---
echo Using JDK: %JAVA_HOME%
flutter run -d 23117RA68G 2>&1
exit /b %errorlevel%
