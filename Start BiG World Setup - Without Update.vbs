If WScript.Arguments.Named.Exists("elevated") = False Then
  CreateObject("Shell.Application").ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """ /elevated", "", "runas", 1
  WScript.Quit
Else
  Set oShell = CreateObject("WScript.Shell")
  oShell.CurrentDirectory = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
  Set wshShell = WScript.CreateObject ("wscript.shell")
  Set objFSO = CreateObject("Scripting.FileSystemObject")
  wshShell.Run """BiG World Setup\Tools\AutoIt3.exe"" ""BiG World Setup\BiG World Setup.au3""", 1, True
  Set wshShell = nothing
End If