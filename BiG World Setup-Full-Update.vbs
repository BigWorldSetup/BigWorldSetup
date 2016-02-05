If WScript.Arguments.Named.Exists("elevated") = False Then
  CreateObject("Shell.Application").ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """ /elevated", "", "runas", 1
  WScript.Quit
Else
  Set oShell = CreateObject("WScript.Shell")
  oShell.CurrentDirectory = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
  Set wshShell = WScript.CreateObject ("wscript.shell")
  'On Error Resume Next
  'wshShell.Run """BiG World Setup\Tools\Git\bin\git.exe""" & " version", 7, True
  'If Err.Number <> 0 Then
  '  WScript.Echo "To enable automatic updates each time you start BWS, please install Git for Windows (http://git-scm.com/download/win).  Choose the middle installer option labeled 'Use Git from the Windows Command prompt'.  This will add Git to the Windows PATH environment variable so BWS can find it.  All other install options can be left to the defaults."
  '  WScript.Quit
  'Else
    Set objFSO = CreateObject("Scripting.FileSystemObject")
    If objFSO.FolderExists(".git") Then
      'WScript.Echo "Folder exists."
        wshShell.Run """BiG World Setup\Tools\Git\bin\git.exe""" & " reset --hard", 1, True
        wshShell.Run """BiG World Setup\Tools\Git\bin\git.exe""" & " pull --rebase", 1, True
		wshShell.Run "pause & exit", 1, True
    Else
      'WScript.Echo "Folder does not exist."
		wshShell.Run """BiG World Setup\Tools\Git\bin\git.exe""" & " init .", 1, True
        wshShell.Run """BiG World Setup\Tools\Git\bin\git.exe""" & " remote add -f origin https://bitbucket.org/BigWorldSetup/BigWorldSetup", 1, True
        wshShell.Run """BiG World Setup\Tools\Git\bin\git.exe""" & " branch --track master origin/master", 1, True
        wshShell.Run """BiG World Setup\Tools\Git\bin\git.exe""" & " reset --hard origin/master", 1, True
        wshShell.Run "pause & exit", 1, True
    End If
    wshShell.Run """BiG World Setup\Tools\Git\bin\git.exe""" & " rev-parse HEAD > BWS-Version.txt", 7, True
  'End If
  'Err.Clear
  'On Error Goto 0
  wshShell.Run """BiG World Setup\Tools\AutoIt3.exe""" & " " & """BiG World Setup\BiG World Setup.au3""", 1, True
  Set wshShell = nothing
End If