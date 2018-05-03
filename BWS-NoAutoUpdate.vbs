If WScript.Arguments.Named.Exists("elevated") = False Then
  CreateObject("Shell.Application").ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """ /elevated", "", "runas", 1
  WScript.Quit
Else
  Set oShell = CreateObject("WScript.Shell")
  oShell.CurrentDirectory = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
  Set wshShell = WScript.CreateObject ("wscript.shell")
  Set objFSO = CreateObject("Scripting.FileSystemObject")
  commandDefinition = "%comspec% /c ""App\Tools\Git\cmd\git.exe""" & " " & "log --pretty=oneline --abbrev-commit --abbrev=7 -n 1" & " > " & "BWS-Version.txt"
  wshShell.Run commandDefinition, 7, True
  wshShell.Run """App\Tools\AutoIt3.exe"" ""App\App.au3""", 1, True
  Set wshShell = nothing
End If