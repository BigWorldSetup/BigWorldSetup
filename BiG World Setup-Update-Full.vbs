If WScript.Arguments.Named.Exists("elevated") = False Then
CreateObject("Shell.Application").ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """ /elevated", "", "runas", 1
WScript.Quit
Else
Set oShell = CreateObject("WScript.Shell")
oShell.CurrentDirectory = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
Set wshshell = WScript.CreateObject ("wscript.shell")
GitResetHard = "git reset --hard"
GitPullRebase = "git pull --rebase"
wshShell.Run GitResetHard,1,1
wshShell.Run GitPullRebase,1,1
'wshshell.Exec ("git reset --hard")
'wshshell.Exec ("git pull --rebase")
Set wshshell = nothing
End If