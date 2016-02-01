If WScript.Arguments.Named.Exists("elevated") = False Then
  CreateObject("Shell.Application").ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """ /elevated", "", "runas", 1
  WScript.Quit
Else
  Set oShell = CreateObject("WScript.Shell")
  oShell.CurrentDirectory = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
  Set wshShell = WScript.CreateObject ("wscript.shell")
  
  Set objFSO = CreateObject("Scripting.FileSystemObject")
  If objFSO.FolderExists(".git") Then
    'Wscript.Echo "Folder exists."
    wshShell.Run "AutoUpdate\git reset --hard",1,1
    wshShell.Run "AutoUpdate\git pull --rebase",1,1
  Else
    'Wscript.Echo "Folder does not exist."
    wshShell.Run "AutoUpdate\git init .",1,1
    wshShell.Run "AutoUpdate\git remote add -f origin https://bitbucket.org/BigWorldSetup/BigWorldSetup",1,1
    wshShell.Run "AutoUpdate\git branch --track master origin/master",1,1
    wshShell.Run "AutoUpdate\git reset --hard origin/master",1,1
  End If
  wshShell.run """BiG World Setup\Tools\AutoIt3.exe""" &" " & """BiG World Setup\BiG World Setup.au3""", 6, True
  Set wshShell = nothing
End If