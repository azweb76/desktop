Import-Module PSReadLine
[System.Reflection.Assembly]::LoadWithPartialName("System.Web") | out-null
[System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions") | out-null

$global:cred = $null

function expand-servername($s){
  $computers = @()

  $gd = $s.Replace("]", "") -split "\["
  $prefix = $gd[0]
  if($gd[1]){
    $nums = $gd[1] -split "-"
    $pad=("0"*$nums[1].length)
    $fmt="{0:$pad}"

    $nums[0]..$nums[1] |
    foreach {
      $computers += "$prefix$fmt" -f $_
    }
  }
  else {
    $computers += $s
  }

  $computers
}

function which($app){
  (Get-Command $app).Definition
}

function login(){
  if(-not $global:cred){
    $global:cred = Get-Credential
  }
}

function rservice($servers, $service, [switch]$async, $action='restart'){
  login
  psexec $servers {
    param($service,$action)
    function restartservice($s){ net stop $s; net start $s }
    $service | %{ if($action -eq 'restart') { restartservice $_ } else { sc.exe $action "${_}" } }
  } $service,$action -async:$async
}

function serverips($servers){
  expand-servername $servers | %{
    $s = $_
    [System.Net.Dns]::GetHostAddresses($s)[0].IPAddressToString
  }
}

function wsh($server){
  if(-not $global:cred){
    $global:cred = Get-Credential
  }
  Enter-PSSession $server -Credential $global:cred
}

$hist = join-path ([Environment]::GetFolderPath('UserProfile')) .ps_history

register-engineevent PowerShell.Exiting -Action { get-history | export-clixml $hist } | out-null
if (test-path $hist){ import-clixml $hist | add-history }

Set-PSReadlineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadlineKeyHandler -Key Tab -Function Complete

function hg($arg) {
    Get-History -c $MaximumHistoryCount | out-string -stream |
    select-string $arg
}

function psexec($server,$code,$argumentlist,[switch]$async){
	login
  $servers = expand-servername $server
  if($async){
    $jobs = @()
    $servers | foreach {
      $jobs += invoke-command -computername $_ -credential $global:cred -scriptblock $code -ArgumentList $argumentlist -AsJob
    }
    $jobs | %{ receive-job -wait $_ }
  }
  else {
    $servers | foreach {
      invoke-command -computername $_ -credential $global:cred -scriptblock $code -ArgumentList $argumentlist
    }
  }
}

new-alias exec psexec
new-alias ex psexec
new-alias xs expand-servername
new-alias subl "C:\Program Files\Sublime Text 3\sublime_text.exe"

function co($m){
	$t = @{ requestor= "dclayton"; changeCategory='Automated Deployment.Site Builders.Designer Go Live'; changeType='Normal'; changeStatus='Open'; group='DEV-WebsiteBuilder'; template='WSBV7_GOLIVE'; summary=$m; startDate=(get-date).AddMinutes(10).ToString("yyyy-MM-dd HH:mm:ss"); description="description here" }
	$data=''
	foreach($k in $t.Keys){
        $v=[System.Web.HttpUtility]::UrlEncode($t.Item($k))
        if($data){ $data += '&' }
        $data += "$k=$v"
    }
	iex "curl.exe -d `"$data`" -H `"Content-Type: application/x-www-form-urlencoded`" -X POST `"http://10.8.12.188/servicedesk/changeorder/`""
}
