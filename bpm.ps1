# this thing name
$myname = "BPM"

# webserver root, this must be the root directory where this script is located
$webroot = (Get-ItemProperty "REGISTRY::HKLM\SOFTWARE\$myname" -Name webroot).webroot

# default msiexec arguments
$msiexec_args = "/qn /norestart"

### functions used in script ###

function download_package {
  if (Get-Variable download_uri -ErrorAction SilentlyContinue)
  {
    Start-BitsTransfer $download_uri
    if (!($?)){
      $err = "Failed to download file from $download_uri !"
      Write-Host "$err" -ForegroundColor Red
      Write-EventLog -EventId 83 -Logname "Application" -Message "$err" -Source "$myname" -EntryType Error
      Remove-Variable download_uri -ErrorAction SilentlyContinue
      $global:eventid = "83"
    } else {
      $global:eventid = "84"
    }
  } else {
    # Set eventid like if download was successfull
    eventid = "84"
  }  
}

function install_package {

  Write-Host "$msg" -ForegroundColor Yellow
  Write-EventLog -EventId 31 -Logname "Application" -Message "$msg" -Source "$myname" -EntryType Information    

  # download package if download_uri is defined
  download_package

  # if download was successfull
  if ($eventid -eq 84){

    # do the install
    Invoke-Expression $install_cmd
  
    # register package in registry
    New-Item "REGISTRY::HKLM\SOFTWARE\$myname\$package" -Force *>$null
    New-ItemProperty "REGISTRY::HKLM\SOFTWARE\$myname\$package" -Name Version -PropertyType Qword -Value $version -Force *>$null
    New-ItemProperty "REGISTRY::HKLM\SOFTWARE\$myname\$package" -Name Uninstall_CMD -PropertyType String -Value $uninstall_cmd -Force *>$null  

  }

}

### START ###

Write-Host "Started $myname" -ForegroundColor Green
Write-EventLog -EventId 1 -Logname "Application" -Message "Started $myname" -Source "$myname" -EntryType Information

# Check if event log for $myname is defined
Get-Item "HKLM:\SYSTEM\CurrentControlSet\Services\EventLog\Application\$myname" *>$null
if (!($?)){
  Write-Host "Creating Event Log for $myname" -ForegroundColor Yellow
  New-EventLog -LogName "Application" -Source "$myname"
}

# Check if config is set
Get-ItemProperty "REGISTRY::HKLM\SOFTWARE\$myname" -Name config *>$null
if (!($?)){
  $err = "Specify configuration first ! (STRING saved in REGISTRY::HKLM\SOFTWARE\$myname\config)"
  Write-Host "$err" -ForegroundColor Red
  Write-EventLog -EventId 80 -Logname "Application" -Message "Configuration not set ! `n$err" -Source "$myname" -EntryType Error
  return 80
} else {
	# Set config variable from registry value
	$config = (Get-ItemProperty "REGISTRY::HKLM\SOFTWARE\$myname" -Name config).config
}

# Go to TEMPorary directory while operating
New-Item -ItemType Directory -Force $env:TEMP\$myname *>$null
Set-Location $env:TEMP\$myname

# import Background Intelligent Transfer Service module (BITS). This is used for file download.
Import-Module BitsTransfer

# load configuration from configuration file
Invoke-Expression (Invoke-RestMethod -Uri $webroot/config/$config.ps1)
if (!($?)){
  $err = "Failed to load configuration file from $webroot/$config.ps1 !"
  Write-Host "$err" -ForegroundColor Red  
  Write-EventLog -EventId 81 -Logname "Application" -Message "$err" -Source "$myname" -EntryType Error
  return 81
}
Write-EventLog -EventId 10 -Logname "Application" -Message "Loaded configuration from $webroot/$config.ps1" -Source "$myname" -EntryType Information

# Process packages
Foreach ($package in $packages){

  # load package
  Invoke-Expression (Invoke-RestMethod -Uri $webroot/config/packages/$package.ps1)
  if (!($?)){
    $err = "Failed to load package configuration file from $webroot/config/packages/$package.ps1 !"
    Write-Host "$err" -ForegroundColor Red
    Write-EventLog -EventId 82 -Logname "Application" -Message "$err" -Source "$myname" -EntryType Error
  }
  Write-EventLog -EventId 11 -Logname "Application" -Message "Loaded package configuration from $webroot/packages/$package.ps1." -Source "$myname" -EntryType Information

  # Is package installed ?
  if ((Get-ItemProperty  "REGISTRY::HKLM\SOFTWARE\$myname\$package" -ErrorAction SilentlyContinue).Version){

    # What version is currently installed ?
    $current_version = (Get-ItemProperty "REGISTRY::HKLM\SOFTWARE\$myname\$package").Version

    # Is newer version avaible ?
    if ($current_version -lt $version){

      # it is upgrade time
      $msg = "Upgrading $package version from $current_version to $version."
      install_package

    } else {

      # Yes it is
      $msg = "Package $package is already installed or your version is higher than avaible. `nYour version: $current_version `nAvaible version: $version"
      Write-Host "$msg" -ForegroundColor Yellow
      Write-EventLog -EventId 30 -Logname "Application" -Message "$msg" -Source "$myname" -EntryType Information
  
    }

  } else {
    # No it is not
    $msg = "Installing $package"
    install_package
  }

}

### Now remove the packages installed but not specified in package list ###
$installed_packages = Get-ChildItem "REGISTRY::HKLM\SOFTWARE\$myname"

Foreach ($installed_package in $installed_packages){

  $installed_package_name = $installed_package.PSChildName

  # If package is not in the package list
  if (!($packages -contains $installed_package_name)){

    $msg = "Uninstalling $installed_package_name because it is not defined in $webroot/$config.ps1"
    Write-Host "$msg" -ForegroundColor Red
    Write-EventLog -EventId 32 -Logname "Application" -Message "$msg" -Source "$myname" -EntryType Warning  
    Invoke-Expression (Get-ItemProperty "REGISTRY::HKLM\SOFTWARE\$myname\$installed_package_name").Uninstall_CMD
    Remove-Item "REGISTRY::HKLM\SOFTWARE\$myname\$installed_package_name" -Force *>$null

  }

}

Write-Host "Finished running $myname" -ForegroundColor Green
Write-EventLog -EventId 1 -Logname "Application" -Message "Finished running $myname" -Source "$myname" -EntryType Information
