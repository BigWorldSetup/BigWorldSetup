If WScript.Arguments.Named.Exists("elevated") = False Then
  CreateObject("Shell.Application").ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """ /elevated", "", "runas", 1
  WScript.Quit
Else
  Set oShell = CreateObject("WScript.Shell")
  oShell.CurrentDirectory = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
  Set wshShell = WScript.CreateObject ("wscript.shell")
  Set objFSO = CreateObject("Scripting.FileSystemObject")
  wshShell.Run "%comspec% /k XCOPY /S /Q /Y /I ""BiG World Setup\Tools\Git"" "".\Git"" & exit", 7, True
  If objFSO.FolderExists(".git") Then
    'WScript.Echo "Folder exists."
    wshShell.Run """.\Git\bin\git.exe"" reset --hard origin/master", 1, True
  Else
    'WScript.Echo "Folder does not exist."
    wshShell.Run """.\Git\bin\git.exe"" init .", 1, True
    wshShell.Run """.\Git\bin\git.exe"" remote add -f origin https://bitbucket.org/BigWorldSetup/BigWorldSetup", 1, True
    wshShell.Run """.\Git\bin\git.exe"" branch --track master origin/master", 1, True
    wshShell.Run """.\Git\bin\git.exe"" reset --hard origin/master", 1, True
  End If
  wshShell.Run """BiG World Setup\Tools\Git\bin\git.exe"" rev-parse HEAD > BWS-Version.txt", 7, True
  wshShell.Run """BiG World Setup\Tools\AutoIt3.exe"" ""BiG World Setup\BiG World Setup.au3""", 1, True
  Set wshShell = nothing
End If