Set-Location "$PSScriptRoot\BiG World Setup\Config"
Get-ChildItem -Include 'Mod*.ini','WeiDU-*' -Recurse | Remove-Item
exit