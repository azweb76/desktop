param([switch]$sshkey)

if($sshkey){
  mkdir -force "$Env:USERPROFILE\.ssh"
  ssh-keygen -f "$Env:USERPROFILE\.ssh\id_rsa" -t rsa -q -N "''" -b 2048

  Write-Host "SSH key generated. Your public key will be opened in notepad. Add the key to your account in github.secureserver.net. Press any key to launch notepad and github."
  $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

  Start-Process "https://github.secureserver.net/settings/ssh"
  Start-Process "notepad.exe" -ArgumentList "$Env:USERPROFILE\.ssh\id_rsa.pub"

  Write-Host "Press any key to continue ..."
  $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

mkdir -f "$Env:USERPROFILE\Documents\WindowsPowerShell\"
cp Microsoft.PowerShell_profile.ps1 "$Env:USERPROFILE\Documents\WindowsPowerShell\"