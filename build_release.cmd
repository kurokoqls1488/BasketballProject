@echo off
cd /d C:\Users\Dan\Desktop\basketball_training
set PATH=C:\Users\Dan\AppData\Local\Programs\Eclipse Adoptium\jdk-17.0.19.10-hotspot\bin;C:\flutter\bin;C:\Users\Dan\AppData\Local\Android\Sdk\platform-tools;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0
flutter run --android-skip-build-dependency-validation --no-version-check -d qsbqd6qgbaem4day
echo BUILD EXIT CODE: %ERRORLEVEL%
pause
