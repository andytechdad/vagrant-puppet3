
write-output "Running User Data Script"
write-host "(host) Running User Data Script"

Set-ExecutionPolicy -ExecutionPolicy bypass -Force

# RDP
cmd.exe /c netsh advfirewall firewall add rule name="Open Port 3389" dir=in action=allow protocol=TCP localport=3389
cmd.exe /c reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f

# Turn of Windows Firewall - AWS Security Groups will manage this.
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False

tzutil /s "GMT Standard Time"
Set-Culture en-GB
Set-WinSystemLocale en-GB
Set-WinHomeLocation -GeoId 242
Set-WinUserLanguageList en-GB -force

write-output "Running Puppet Install"

Write-Host "Attempting to install puppet."

$PuppetVersion = "3.8.7-x64"
$MsiLocation   = "C:\vagrant\files\puppet-3.8.7-x64.msi"

$MsiLocation   = "C:\vagrant\files\puppet-3.8.7-x64.msi"

try {

  Write-Host "Checking for existing installation of puppet"

  $ErrorActionPreference = "Stop";
  Get-Command puppet | Out-Null
  $InstalledPuppetVersion=&puppet "--version"

  $InstalledVersionNumber = $InstalledPuppetVersion.replace('.', '')
  $VersionNumber = $PuppetVersion.replace('.', '')

  if ($InstalledVersionNumber -eq $VersionNumber) {
      Write-Host "Puppet $InstalledPuppetVersion is already installed."
      Exit 0
  }

  if ($InstalledVersionNumber -gt $VersionNumber) {
      Write-Host "Puppet $InstalledPuppetVersion is already installed which is newer than $PuppetVersion."
      Exit 0
  }

  if ($InstalledVersionNumber -lt $VersionNumber) {
      Write-Host "Puppet $InstalledPuppetVersion is already installed. Upgrading to $PuppetVersion."
  }

} catch {
  Write-Host "Puppet is not installed, continuing..."
}

###########################################################
## Check that we have a sane environment to run in
###########################################################

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (! ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
  Write-Host -ForegroundColor Red "You must run this script as an administrator."
  Exit 1
}

cmd.exe /c mkdir c:\temp\qe-bins

###########################################################
## Download the installer
###########################################################

if (Test-Path "C:\vagrant\files\puppet-3.8.7-x64.msi") {
   Write-Host "Puppet Binary puppet-$($PuppetVersion).msi found"
} else {
  Exit 1
}
###########################################################
## Install Puppet
###########################################################

$install_args = ("/qn", "/norestart","/i", "C:\vagrant\files\puppet-3.8.7-x64.msi")
Write-Host "Installing Puppet. Running msiexec.exe $install_args"

$process = Start-Process -FilePath msiexec.exe -ArgumentList $install_args -Wait -PassThru
$process.WaitForExit()

if ($process.ExitCode -ne 0) {
  Write-Host "Installer failed."
  Exit 1
}

# Stop the service that it autostarts
Write-Host "Stopping Puppet service"
Start-Sleep -s 5
Get-Service puppet | Stop-Service -PassThru | Set-Service -StartupType disabled

Write-Host "Puppet successfully installed."

write-output "FINISHED"
Write-Host "FINISHED"
