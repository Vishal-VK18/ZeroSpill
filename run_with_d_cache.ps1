$env:PUB_CACHE="D:\pub_cache"
$env:GRADLE_USER_HOME="D:\.gradle"
$env:TMP="D:\tmp"
$env:TEMP="D:\tmp"

Write-Host "Running with D: drive cache to avoid C: drive space issues..."
Write-Host "PUB_CACHE: $env:PUB_CACHE"
Write-Host "GRADLE_USER_HOME: $env:GRADLE_USER_HOME"
Write-Host "TEMP: $env:TMP"

flutter pub get
flutter run
