If WScript.Arguments.Named.Exists("elevated") = False Then
CreateObject("Shell.Application").ShellExecute "wscript.exe", """" & WScript.ScriptFullName & """ /elevated", "", "runas", 1
WScript.Quit
Else
Set objShell = CreateObject("WScript.Shell") 
objStartFolder = objShell.CurrentDirectory & "\" & "BiG World Setup\Config"
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objFolder = objFSO.GetFolder(objStartFolder)
'Wscript.Echo objFolder.Path
Set colFiles = objFolder.Files
ShowSubfolders objFSO.GetFolder(objStartFolder)
Sub ShowSubFolders(Folder)
    For Each Subfolder in Folder.SubFolders
        'Wscript.Echo Subfolder.Path
        Set objFolder = objFSO.GetFolder(Subfolder.Path)
        Set colFiles = objFolder.Files
        ShowSubFolders Subfolder
		Set objRE1 = New RegExp
		objRE1.Global     = True
		objRE1.IgnoreCase = True
		objRE1.Pattern    = "^mod.*"
		Set objRE2 = New RegExp
		objRE2.Global     = True
		objRE2.IgnoreCase = True
		objRE2.Pattern    = "^weidu-.*"
		For Each objFile In colFiles
		   bMatch = objRE1.Test(objFile.Name)
		   If bMatch Then
			  'WScript.Echo objFSO.GetAbsolutePathName(objFile)
			  objFSO.DeleteFile objFSO.GetAbsolutePathName(objFile)
		   End If
		Next
		For Each objFile In colFiles
		   bMatch = objRE2.Test(objFile.Name)
		   If bMatch Then
			  'WScript.Echo objFSO.GetAbsolutePathName(objFile)
			  objFSO.DeleteFile objFSO.GetAbsolutePathName(objFile)
		   End If
		Next
    Next
End Sub
Set oShell = CreateObject("WScript.Shell")
oShell.CurrentDirectory = CreateObject("Scripting.FileSystemObject").GetParentFolderName(WScript.ScriptFullName)
Set wshshell = WScript.CreateObject ("wscript.shell")
wshshell.run """BiG World Setup\AutoIt3.exe""" &" " & """BiG World Setup\BiG World Setup.au3""", 6, True
End If
Set wshshell = Nothing
set objFSO = Nothing
set objShell = Nothing
set oShell = Nothing
Wscript.Quit