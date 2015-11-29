If WScript.Arguments.Named.Exists("elevated") = False Then
CreateObject("Shell.Application").ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """ /elevated", "", "runas", 1
WScript.Quit
Else
Set oShell = CreateObject("WScript.Shell")
oShell.CurrentDirectory = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
Set wshshell = WScript.CreateObject ("wscript.shell")
GitPullRebase = "git pull --rebase"
GitStash = "git stash"
GitStashPop = "git stash pop"
wshShell.Run GitStash,1,1
wshShell.Run GitPullRebase,1,1
wshShell.Run GitStashPop,1,1
wshShell.Run """BiG World Setup\AutoIt3.exe""" &" " & """BiG World Setup\BiG World Setup.au3""", 6, True
Set wshshell = nothing
End If