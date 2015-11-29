If WScript.Arguments.Named.Exists("elevated") = False Then
CreateObject("Shell.Application").ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """ /elevated", "", "runas", 1
WScript.Quit
Else
Set oShell = CreateObject("WScript.Shell")
oShell.CurrentDirectory = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
Set wshshell = WScript.CreateObject ("wscript.shell")
wshshell.run """BiG World Setup\AutoIt3.exe""" &" " & """BiG World Setup\Debug.au3"""& " 1", 6, True
Set wshshell = nothing
End If