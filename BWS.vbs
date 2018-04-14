If WScript.Arguments.Named.Exists("elevated") = False Then
  CreateObject("Shell.Application").ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """ /elevated", "", "runas", 1
  WScript.Quit
Else

  Set oShell = CreateObject("WScript.Shell")
  oShell.CurrentDirectory = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
  Set objFSO = CreateObject("Scripting.FileSystemObject")
  If objFSO.FolderExists(".git") Then
    Const ForReading = 1
    InstallationInProgress = False
    Dim strSearchFor
    strSearchFor = "Au3CleanInst=1"
    Set objFSO = CreateObject("Scripting.FileSystemObject")
    setupFilePath = "Big World Setup\Config\Setup.ini"
    Set objTextFile = objFSO.OpenTextFile(setupFilePath, ForReading)
    do until objTextFile.AtEndOfStream
        strLine = objTextFile.ReadLine()
        If InStr(strLine, strSearchFor) <> 0 then
            InstallationInProgress = False
        Else
            InstallationInProgress = True
        End If
    loop
    objTextFile.Close
    If InstallationInProgress = False Then
	  Set wshShell = WScript.CreateObject ("wscript.shell")
      wshShell.Run "%comspec% /k "".\Git\bin\git.exe"" fetch & .\Git\bin\git.exe reset --hard origin/master & exit", 1, True
    End If
  Else
	Set wshShell = WScript.CreateObject ("wscript.shell")
    wshShell.Run "%comspec% /k XCOPY /S /Q /Y /I ""Big World Setup\Tools\Git"" "".\Git"" & exit", 7, True
    WScript.Echo "BWS has an autoupdate feature that will synchronize your local copy of BWS with the latest online version each time you run this script." & _
                 "Applicaion will not update any files when when installation is in progress. This message will only be displayed once."
    wshShell.Run """.\Git\bin\git.exe"" init .", 1, True
    wshShell.Run """.\Git\bin\git.exe"" remote add -f origin https://bitbucket.org/BigWorldSetup/BigWorldSetup", 1, True
    wshShell.Run """.\Git\bin\git.exe"" branch --track master origin/master", 1, True
    wshShell.Run """.\Git\bin\git.exe"" reset --hard origin/master", 1, True
	Set wshShell = nothing
  End If
  
  Set wshShell = WScript.CreateObject ("wscript.shell")
  commandDefinition = "%comspec% /c ""Big World Setup\Tools\Git\bin\git.exe""" & " " & "rev-parse HEAD" & " > " & "BWS-Version.txt"
  wshShell.Run commandDefinition, 7, True
  wshShell.Run """Big World Setup\Tools\AutoIt3.exe"" ""Big World Setup\Big World Setup.au3""", 1, True
  Set wshShell = nothing
End If