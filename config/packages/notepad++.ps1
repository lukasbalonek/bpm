# Package version. If you increase this number, package will be upgraded with install_cmd
$version = 1

# If download_uri is defined, package is downloaded before install or upgrade
$download_uri = "https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.6.4/npp.8.6.4.Installer.x64.exe"

# Command that will install package and remove installer after
$install_cmd = "`
Start-Process -Wait .\npp.8.6.4.Installer.x64.exe /S ;
Remove-Item -ErrorAction SilentlyContinue -Force npp.8.6.4.Installer.x64.exe ;
"

# Command that will uninstall (remove) package
$uninstall_cmd = "Start-Process `"$env:ProgramFiles\Notepad++\uninstall.exe`" /S"
