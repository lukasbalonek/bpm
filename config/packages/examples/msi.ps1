# Package version. If you increase this number, package will be upgraded with install_cmd
$version = 1

# If download_uri is defined, package is downloaded before install or upgrade
$download_uri = "http://<some repository webserver>/<somefile>.msi"

# Command that will install package and remove installer after
$install_cmd = "`
Start-Process -Wait .\<somefile>.msi -ArgumentList `"$msiexec_args`" ;
Remove-Item -ErrorAction SilentlyContinue -Force <somefile>.msi ;
"

# Command that will uninstall (remove) package
$uninstall_cmd = "Start-Process `"$env:ProgramFiles\<someprogram>\uninstall.exe`" /S"
