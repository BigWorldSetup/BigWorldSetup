If WScript.Arguments.Named.Exists("elevated") = False Then
CreateObject("Shell.Application").ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """ /elevated", "", "runas", 1
WScript.Quit
Else
Set oShell = CreateObject("WScript.Shell")
oShell.CurrentDirectory = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
Set wshShell = WScript.CreateObject ("wscript.shell")
GitResetHard = "git reset --hard"
GitPullRebase = "git pull --rebase"
wshShell.Run GitResetHard,1,1
wshShell.Run GitPullRebase,1,1
wshShell.run """BiG World Setup\AutoIt3.exe""" &" " & """BiG World Setup\BiG World Setup.au3""", 6, True
Set wshShell = nothing
End If