# Package version. If you increase this number, package will be upgraded with install_cmd
$version = 1

# If download_uri is defined, package is downloaded before install or upgrade
$download_uri = "https://statics.teams.cdn.office.net/production-windows-x64/enterprise/webview2/lkg/MSTeams-x64.msix"

# Command that will install package and remove installer after
$install_cmd = "`
Add-AppxPackage .\MSTeams-x64.msix ;
Remove-Item -ErrorAction SilentlyContinue -Force MSTeams-x64.msix ;
"

# Command that will uninstall (remove) package
$uninstall_cmd = "Get-AppxPackage -Name MSTeams | Remove-AppxPackage -AllUsers"
