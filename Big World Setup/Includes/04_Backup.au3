#include-once

; ---------------------------------------------------------------------------------------------
; Depending on the current selection or state of the installation, create a backup or restore it
; ---------------------------------------------------------------------------------------------
Func Au3CleanInst($p_Num = 0, $p_Tab = 6) ;1=first timer, 2=backup, 3=restore
	Local $Message = IniReadSection($g_TRAIni, 'BA-Au3CleanInst')
	_PrintDebug('+' & @ScriptLineNumber & ' Calling Au3CleanInst')
	Global $g_LogFile = $g_LogDir & '\BWS-Debug-Backup.txt'
	$g_Flags[0]=1
	If StringRegExp($g_Flags[14], 'BWS|BWP') Then
		Local $Type = 'BG2'
	Else
		Local $Type = $g_Flags[14]
	EndIf
	Global $g_BackupDir = $g_BaseDir & '\Big World Backup\'&$Type; prevent backups inside the BG2-folder
	Global $g_RemovedDir = $g_BaseDir & '\Big World Backup\Saved_'&$Type; don't move files accross partitions if BWS and BG2-dirs lay on different ones
	Local $Action = 0
	GUICtrlSetData($g_UI_Interact[6][4], StringFormat(_GetSTR($Message, 'H1'), $Type)); => help
	Call('_Test_CheckRequiredFiles_'&$Type)
	If @error > 0 Then
		If $p_Num = 1 Then ; Exit if it's from withing a process
			;_ResetInstall(); Enable a clean restart -- useful?
			Exit
		EndIf
		Return; files missing & started within $g_SGui-loop >> set Mode
	EndIf
	If $p_Num = 1 Then; first time check
		GUICtrlSetData($g_UI_Static[6][1], _GetTR($Message, 'L10')); => watch process
		GUICtrlSetData($g_UI_Static[6][2], StringFormat(_GetTR($Message, 'L12'), $g_BackupDir)); => create backup at
		_Process_SwitchEdit(1, 0)
		$Test=_Backup_Test($Type); 0=done / 1=done & mods already installed / 2 = not done / 3=not done & mods already installed
		If $Test = 0 Then; backup was done before
			IniWrite($g_BWSIni, 'Order', 'Au3CleanInst', 0)
		ElseIf $Test = 1 Then; backup was done, but mods were installed
			$Error=_Backup_Restore(6)
			$Action=2; set restore-mode
		ElseIf $Test = 2 Then; backup was not done before
			GUICtrlSetState($g_UI_Interact[6][2], $GUI_SHOW)
			GUICtrlSetState($g_UI_Interact[6][3], $GUI_HIDE)
			_Process_SetScrollLog(StringFormat(_GetTR($Message, 'L1'), $Type), 1, -1); => first time backup notification
			_Process_Question('y|n',_GetTR($Message, 'L11'), _GetTR($Message, 'Q1'), 2); => enter yes/no
			If $g_pQuestion = 'y' Then
				$Action=1; set backup-mode
			Else; no backup
				IniWrite($g_BWSIni, 'Order', 'Au3CleanInst', 0)
			EndIf
		Elseif $Test = 3 Then; 3=backup was not done & mods are already installed
			_Process_SetScrollLog(StringFormat(_GetTR($Message, 'L21'), _GetGameName()), 1, -1); => no backup, install from scratch
			_Process_Gui_Delete(6, 6, 1); Delete the window
			Exit
		EndIf
	ElseIf $p_Num = 2 Then; backup check
		_Process_Gui_Create(1, 0)
		$Test=_Backup_Test($Type); 0=done / 1=done & mods already installed / 2 = not done / 3=not done & mods already installed
		GUICtrlSetData($g_UI_Static[6][1], _GetTR($Message, 'L10')); => watch progress
		GUICtrlSetData($g_UI_Static[6][2], StringFormat(_GetTR($Message, 'L12'), $g_BackupDir)); => create backup at
		If $Test = 0 Or $Test = 2 Then; no mods are installed
			_Process_SetScrollLog(StringFormat(_GetTR($Message, 'L2'), $Type), 1, -1); => you want a backup
			_Process_Question('y|n',_GetTR($Message, 'L11'), _GetTR($Message, 'Q1'), 2); => enter yes/no
			If $g_pQuestion = 'y' Then
				$Action=1; set backup-mode
			Else
				_Process_Gui_Delete(3, 3, 0); Return to the previous tab
			EndIf
		ElseIf $Test = 1 Then; backup was done and mods are installed
			_Process_SetScrollLog(_GetTR($Message, 'L22'), 1, -1); => backup + installed mods does not make sense
			_Process_Gui_Delete(3, 3, 1); Return to the previous tab
		Else
			_Process_SetScrollLog(StringFormat(_GetTR($Message, 'L21'), _GetGameName()), 1, -1); => no backup, install from scratch
			_Process_Gui_Delete(3, 3, 1); Return to the previous tab
		EndIf
	ElseIf $p_Num = 3 Then; restore check
		_Process_Gui_Create(1, 0)
		$Error = _Backup_Restore(3)
		$Action = 2
	EndIf
; ---------------------------------------------------------------------------------------------
; create a backup
; ---------------------------------------------------------------------------------------------
	If $Action = 1 Then
		If _Backup_Create($Type, $Message) = 0 Then; all ok
			_Process_SetScrollLog(@CRLF&StringFormat(_GetTR($Message, 'L4'), $g_BackupDir), 1, -1); => backup: success. found: there
			GUICtrlSetData($g_UI_Static[6][2], StringRegExpReplace(_GetTR($Message, 'L4'), '\x7c.*', '')); => backup: success
			IniWrite($g_BWSIni, 'Order', 'Au3CleanInst', 0)
			If $p_Num=1 Then ; this window will be used later. Just wait a sec to have a look
				_Process_SetScrollLog(_GetTR($Message, 'L13'), 1, -1); => continue in 5s
				Sleep(5000)
			Else; switch back to the default tab
				_Process_Gui_Delete(3, 3, 1)
			EndIf
		Else; fault
			_Process_SetScrollLog(_GetTR($Message, 'L6'), 1, -1); => backup: fail. Look at log
			GUICtrlSetData($g_UI_Static[6][2], StringRegExpReplace(_GetTR($Message, 'L6'), '\x7c.*', '')); => backup: fail
			_Process_Gui_Delete(3, 3, 1)
			If $p_Num = 1 Then Exit
		EndIf
; ---------------------------------------------------------------------------------------------
; Restore from a backup
; ---------------------------------------------------------------------------------------------
	ElseIf $Action = 2 Then
		If $Error = 0 Then; everthings ok
			_Process_SetScrollLog(_GetTR($Message, 'L5'), 1, -1); => restore: success
			GUICtrlSetData($g_UI_Static[6][2], _GetTR($Message, 'L5')); => restore: success
			If $p_Num=1 Then ; this window will be used later. Just wait a sec to have a look
				_Process_SetScrollLog(_GetTR($Message, 'L13'), 1, -1); => continue in 5s
				IniWrite($g_BWSIni, 'Order', 'Au3CleanInst', 0)
				Sleep(5000)
			Else; this window will be deleted
				_Process_Gui_Delete(3, 3, 1)
			EndIf
		ElseIf $Error = -1 Then; aborted before the restore
			If $p_Num = 1 Then _Process_SetScrollLog('|'&StringFormat(_GetTR($Message, 'L21'), _GetGameName()) , 1, -1); => no backup, install from scratch
			Sleep(5000)
			_Process_Gui_Delete(3, 3, 0)
			If $p_Num = 1 Then Exit
		Else; error during restore
			_Process_SetScrollLog(_GetTR($Message, 'L7'), 1, -1); => restore: fail. Look at log
			GUICtrlSetData($g_UI_Static[6][2], StringRegExpReplace(_GetTR($Message, 'L7'), '\x7c.*', '')); => restore: fail
			_Process_Gui_Delete(3, 3, 1)
			If $p_Num = 1 Then Exit
		EndIf
	EndIf
EndFunc   ;==>Au3CleanInst

; ---------------------------------------------------------------------------------------------
; Creates the backup and returns the number of errors
; ---------------------------------------------------------------------------------------------
Func _Backup_Create($p_Game, $p_Message)
	Local $FMessage = IniReadSection($g_TRAIni, 'BA-FileAction')
	Local $Size, $CSize, $Error=0, $FileList
	_Process_SetScrollLog('')
	FileClose(FileOpen($g_LogFile,2))
	$Files=_FileSearch($g_GameDir, '*'); save the files that exist now and calculate the size of the backup
	Local $Section[$Files[0]+8][2]; files + fixed files that are possibly missing
	For $f=1 to $Files[0]
		$IsDir=StringRegExp(FileGetAttrib($g_GameDir&'\'&$Files[$f]), 'D')
		_IniWrite($Section, $Files[$f], $IsDir, 'N')
		If StringRegExp($Files[$f], '(?i)\A(\x2e?|mplay.*|nwn_1.mpg|(GS)?Arcade.*|glsetup.exe)\z') Then ContinueLoop; don't copy useless files
		If StringRight($Files[$f], 4) = '.bif' And $p_Game = 'PST' Then ContinueLoop; PST has no data-folder but installs all files into the root-folder
		If StringRegExp($Files[$f], '(?i)\A(Big World Backup|Big World Downloads|Big World Setup|cache|cd\d|data|ereg|mplayer|script compiler|debugs)\z') Then ContinueLoop; don't copy useless or untouched folders
		If $IsDir Then
			$Size+=DirGetSize($g_GameDir&'\'&$Files[$f])
		Else
			$Size+=FileGetSize($g_GameDir&'\'&$Files[$f])
		EndIf
		$FileList&='|'&$f&'|'&$IsDir; log indexnumber and directory
	Next
	_Process_SetScrollLog(_GetTR($p_Message, 'L8')&@CRLF, 1, -1); => wait a bit
	If FileExists($g_BackupDir) Then; remove old backup
		GUICtrlSetData($g_UI_Static[6][2], _GetTR($p_Message, 'L9')); => removing old backup
		$Error+=_Backup_FileAction($g_BackupDir, '', '', 3, $CSize, $Size, $FMessage)
	EndIf
	DirCreate($g_BackupDir)
	; Add some files/folders that might not exist yet but should not be removed
	Local $Fix[6] = ['portraits', 'save', 'mpsave', 'Big World Setup', 'Big World Backup', 'Big World Downloads']
	For $f in $Fix
		_IniWrite($Section, $f, 1)
	Next
	_IniWrite($Section, 'Big World Setup.vbs', 0)
	IniWriteSection($g_BackupDir&'\BWS_Backup.ini', 'Root', $Section)
	$FileList=StringSplit(StringTrimLeft($FileList, 1), '|')
	For $f=1 to $FileList[0]-1 Step 2; copy the files that were found and shout be copied
		$Error+=_Backup_FileAction($Files[$FileList[$f]], $g_GameDir, $g_BackupDir, $FileList[$f+1], $CSize, $Size, $FMessage)
	Next
	GUICtrlSetData($g_UI_Interact[6][1], 100)
	Return $Error
EndFunc   ;==>_Backup_Create

; ---------------------------------------------------------------------------------------------
; Do the copy/deletion and logging stuff for Au3CleanInst.
; ---------------------------------------------------------------------------------------------
Func _Backup_FileAction($p_File, $p_Parent, $p_Dir, $p_Num, ByRef $p_Progress, $p_CompSize, $p_Message)
	If $p_Parent='' Then
		$p_Parent=$p_File
	Else
		$p_Parent=$p_Parent&'\'&$p_File
	EndIf
	$p_Dir=$p_Dir&'\'&$p_File
	If $p_Num=0 Then
		$Size=FileGetSize($p_Parent)
		$p_Progress+=$Size
 		GUICtrlSetData($g_UI_Static[6][2], _GetTR($p_Message, 'L5') &' ' & $p_File &' ('&Round ($Size/1048576, 1)&' MB)'); =>copy: file
		$Success=FileCopy($p_Parent, $p_Dir, 1)
		GUICtrlSetData($g_UI_Interact[6][1], ($p_Progress*100)/$p_CompSize)
	ElseIf $p_Num=1 Then
		GUICtrlSetData($g_UI_Static[6][2], _GetTR($p_Message, 'L5') &' ' & $p_File&' ('&Round (DirGetSize($p_Parent)/1048576, 1)&' MB)'); =>copy: folder
		$Files=_FileSearch($p_Parent, '*')
		$Success = 0
		For $f=1 to $Files[0]
			If StringInStr(FileGetAttrib($p_Parent&'\'&$Files[$f]), 'D') Then
				$Size=DirGetSize($p_Parent&'\'&$Files[$f])
				$p_Progress+=$Size
				$Success+=DirCopy($p_Parent&'\'&$Files[$f], $p_Dir&'\'&$Files[$f], 1)
			Else
				$Size=FileGetSize($p_Parent&'\'&$Files[$f])
				$p_Progress+=$Size
				$Success+=FileCopy($p_Parent&'\'&$Files[$f], $p_Dir&'\'&$Files[$f], 9)
			EndIf
			GUICtrlSetData($g_UI_Interact[6][1], ($p_Progress*100)/$p_CompSize)
		Next
		If $Success = $Files[0] Then $Success = 1
	ElseIf $p_Num=2 Then
 		GUICtrlSetData($g_UI_Static[6][2], _GetTR($p_Message, 'L6') &' ' & $p_File); =>deleting: file
		$Success=FileDelete($p_Parent)
		$p_Progress+=1
		GUICtrlSetData($g_UI_Interact[6][1], 100-(($p_Progress*100)/$p_CompSize))
	ElseIf $p_Num=3 Then
 		GUICtrlSetData($g_UI_Static[6][2], _GetTR($p_Message, 'L6') &' ' & $p_File); =>deleting: folder
		$Success=DirRemove($p_Parent, 1)
		$p_Progress+=5
		GUICtrlSetData($g_UI_Interact[6][1], 100-(($p_Progress*100)/$p_CompSize))
	ElseIf $p_Num=4 Then
 		GUICtrlSetData($g_UI_Static[6][2], _GetTR($p_Message, 'L7') &' ' & $p_File); =>moving: file
		$Success=FileMove($p_Parent, $p_Dir&'\', 1)
		$p_Progress+=1
		GUICtrlSetData($g_UI_Interact[6][1], 100-(($p_Progress*100)/$p_CompSize))
	ElseIf $p_Num=5 Then
 		GUICtrlSetData($g_UI_Static[6][2], _GetTR($p_Message, 'L7') &' ' & $p_File); =>moving: folder
		$Success=DirMove($p_Parent, $p_Dir&'\', 1)
		$p_Progress+=5
		GUICtrlSetData($g_UI_Interact[6][1], 100-(($p_Progress*100)/$p_CompSize))
	EndIf
	If $Success = 1 Then ; success
		If $p_Num=0 or $p_Num=1 Then _Process_SetScrollLog($p_File&' '&_GetTR($p_Message, 'L1')); =>copy: success
		If $p_Num=2 or $p_Num=3 Then _Process_SetScrollLog($p_File&' '&_GetTR($p_Message, 'L3')); =>delete: success
		If $p_Num=4 or $p_Num=5 Then _Process_SetScrollLog($p_File&' '&_GetTR($p_Message, 'L8')); =>move: success
		Return 0
	Else
		If $p_Num=0 or $p_Num=1 Then _Process_SetScrollLog($p_File&' '&_GetTR($p_Message, 'L2')); =>copy: fail
		If $p_Num=2 or $p_Num=3 Then _Process_SetScrollLog($p_File&' '&_GetTR($p_Message, 'L4')); =>delete: fail
		If $p_Num=4 or $p_Num=5 Then _Process_SetScrollLog($p_File&' '&_GetTR($p_Message, 'L9')); =>move: fail
		Return 1
	EndIf
EndFunc   ;==>_Backup_FileAction

; ---------------------------------------------------------------------------------------------
; Moves unneeded files and restores the backup
; ---------------------------------------------------------------------------------------------
Func _Backup_Restore($p_Tab)
	Local $Message = IniReadSection($g_TRAIni, 'BA-Au3CleanInst')
	Local $FMessage = IniReadSection($g_TRAIni, 'BA-FileAction')
	Local $Size, $CSize, $Error=0, $Save = 0
	Local $BSize = DirGetSize($g_BackupDir)
	Local $BifList= '25AmbSnd|25Areas|25ArMisc|25CreAni|25Creatures|25CreSou|25Deflt|25Dialog|25Effect|25GuiBam|' & _
	'25GuiDes|25GuiMos|25Items|25IWAnim|25MiscAn|25NpcSo|25Portrt|25Projct|25Scripts|25SndFX|25SpelAn|25Spells|25Store|' & _
	'AMBSound|Areas|ARMisc|CDCreAni|CD3CreA2|CD3CreAn|CD4CreA2|CD4CreA3|CD4CreAn|CHAAnim|CHASound|CREAnim|CREAnim1|Creature|' & _
	'CRESound|CRIWAnim|Default|DESound|Dialog|Effects|GUIBam|GUICHUI|GUIDesc|GUIFont|GUIIcon|GUIMosc|Hd0CrAn|Hd0GMosc|Items|' & _
	'MISCAnim|MISSound|MovHD0|NPCAnim|NPCHd0So|NPCSoCD2|NPCSoCD3|NPCSoCD4|NPCSound|OBJAnim|PaperDol|Portrait|Project|Scripts|' & _
	'SFXSound|SPELAnim|Spells|Stores'
	GUICtrlSetData($g_UI_Static[6][1], _GetTR($Message, 'L14')); =>watch progress
	GUICtrlSetData($g_UI_Static[6][2], StringFormat(_GetTR($Message, 'L15'), $g_BackupDir)); =>backup location
	If Not FileExists($g_BackupDir) Then
		_Process_SetScrollLog(_GetTR($Message, 'L17'), 1, -1); =>no backup
		Return -1
	EndIf
	If $p_Tab = 3 Then _Process_SetScrollLog(_GetTR($Message, 'L3'), 1, -1); =>you want to restore
	If $p_Tab = 6 Then _Process_SetScrollLog(_GetTR($Message, 'L19'), 1, -1); =>you did install something and should restore
	_Process_SetScrollLog($g_BackupDir & ' => '&$g_GameDir, 1, -1)
	_Process_SetScrollLog(_GetTR($Message, 'L20'), 1, -1); =>shall files be removed or moved?
	_Process_Question('r|m|c',_GetTR($Message, 'L16'), _GetTR($Message, 'Q2'), 3); =>enter remove, move or cancel
	If $g_pQuestion = 'm' Then; move
		$Save =  2
		If Not FileExists($g_RemovedDir) Then DirCreate($g_RemovedDir)
		If Not FileExists($g_RemovedDir&'\Data') Then DirCreate($g_RemovedDir&'\Data')
	ElseIf $g_pQuestion = 'c' Then
		Return -1
	EndIf
	_Process_SetScrollLog('')
	FileClose(FileOpen($g_LogFile,2))
	_Process_SetScrollLog(_GetTR($Message, 'L8')&@CRLF, 1, -1); =>please wait
; ---------------------------------------------------------------------------------------------
; Delete mod-content (unpacked installation files or installed/in-game files)
; ---------------------------------------------------------------------------------------------
	If FileExists($g_GameDir&'\*save') Then
		$UniqueDir=$g_RemovedDir&'\'&@YEAR&@MON&@MDAY&'_'
		$UniqueNum=1
		While 1
			If FileExists($UniqueDir&$UniqueNum) Then
				$UniqueNum+=1
			Else
				DirCreate($UniqueDir&$UniqueNum)
				ExitLoop
			EndIf
		WEnd
		If FileExists($g_GameDir&'\save') Then $Error+=_Backup_FileAction('save', $g_GameDir, $UniqueDir&$UniqueNum, 5, $CSize, $Size, $FMessage); force saves to be moved
		If FileExists($g_GameDir&'\mpsave') Then $Error+=_Backup_FileAction('mpsave', $g_GameDir, $UniqueDir&$UniqueNum, 5, $CSize, $Size, $FMessage)
	EndIf
	If StringRegExp($g_Flags[14], 'BWS|BWP') Then
		$IsGoG=FileExists($g_BG2Dir&'\goggame.dll')
		FileSetAttrib($g_BG2Dir&'\Clean-Up.bat', '-RAS'); remove read-only-bit
		$DataFiles=_FileSearch($g_BG2Dir&'\Data', '*'); delete bif-files created by mods
		For $d=1 to $DataFiles[0]
			If Not StringRegExp($DataFiles[$d], '(?i)\A('&$BifList&').bif') Then
				$IsDir=StringRegExp(FileGetAttrib($g_BG2Dir&'\Data\'&$DataFiles[$d]), 'D')
				If $IsGoG And $IsDir And StringRegExp($DataFiles[$d], '(?i)\A(data|movies)\z') Then ContinueLoop
				$Error+=_Backup_FileAction($DataFiles[$d], $g_BG2Dir&'\Data', $g_RemovedDir&'\Data', 2+$IsDir+$Save, $CSize, $Size, $FMessage)
			EndIf
		Next
	ElseIf $g_Flags[14]='IWD2' Then
		FileSetAttrib($g_IWD2Dir&'\Readme.htm', '-RAS'); remove read-only-bit
	EndIf
	FileDelete($g_GameDir&'\Data\tb#gen*.bif'); remove generic biffed files
	$BakFiles=_FileSearch($g_BackupDir, '*'); delete files from bg2-folder which exist in the backup-folder
	For $b=1 to $BakFiles[0]
		If StringRegExp($BakFiles[$b], '(?i)\A(CD\d|Big World Downloads|Big World Backup|Big World Setup|Portraits)\z') Then ContinueLoop; do >>not<< remove useful or essential folders
		If FileExists($g_GameDir&'\'&$BakFiles[$b]) Then
			$IsDir=StringRegExp(FileGetAttrib($g_GameDir&'\'&$BakFiles[$b]), 'D')
			$Error+=_Backup_FileAction($BakFiles[$b], $g_GameDir, $g_RemovedDir, 2+$IsDir+$Save, $CSize, $Size, $FMessage)
		EndIf
	Next
	$ReadSection=IniReadSection($g_BackupDir&'\BWS_Backup.ini', 'Root')
	If Not @error Then; do not remove any additional files if this is missing!!!
; ---------------------------------------------------------------------------------------------
; collect/list/detect mods content
; ---------------------------------------------------------------------------------------------
		GUICtrlSetData($g_UI_Static[6][2], _GetTR($Message, 'L18')); =>searching unneeded
		$Files=_FileSearch($g_GameDir, '*')
		Local $FileList[$Files[0]+1][2]
		For $f=1 to $Files[0]
			If _IniRead($ReadSection, $Files[$f], -1) <> -1 Then ContinueLoop; includes portraits, save, mpsave, Big World Setup + its vbs, Big World Backup, Big World Downloads
			$FileList[0][0] +=1
			$FileList[$FileList[0][0]][0]=$Files[$f]
			If StringRegExp(FileGetAttrib($g_GameDir&'\'&$Files[$f]), 'D') Then
				$FileList[$FileList[0][0]][1]=1
				$FileList[0][1]+=10; pseudo-value to speed up the process
			Else
				$FileList[$FileList[0][0]][1]=0
				$FileList[0][1]+=1; another pseudo-value
			EndIf
		Next
; ---------------------------------------------------------------------------------------------
; delete or move mods content
; ---------------------------------------------------------------------------------------------
		ReDim $FileList[$FileList[0][0]+1][2]
		$Size = $FileList[0][1]
		For $f = 1 to $FileList[0][0]
			$Error+=_Backup_FileAction($FileList[$f][0], $g_GameDir, $g_RemovedDir, 2+$FileList[$f][1]+$Save, $CSize, $Size, $FMessage)
		Next
	EndIf
; ---------------------------------------------------------------------------------------------
; Copy backup-data
; ---------------------------------------------------------------------------------------------
	Local $CSize=0, $Size=$BSize
	For $b=1 to $BakFiles[0]
		If StringRegExp($BakFiles[$b], '(?i)\A(Big World Downloads|Big World Backup|Big World Setup|mpsave|Portraits|save|BWS_Backup.ini)\z') Then ContinueLoop; do >>not<< copy old content
		$IsDir=StringRegExp(FileGetAttrib($g_BackupDir&'\'&$BakFiles[$b]), 'D')
		$Error+=_Backup_FileAction($BakFiles[$b], $g_BackupDir, $g_GameDir, $IsDir, $CSize, $Size, $FMessage)
	Next
; ---------------------------------------------------------------------------------------------
; Tiny verification for data/bif-files
; ---------------------------------------------------------------------------------------------
	If StringRegExp($g_Flags[14], 'BWS|BWP') Then
		$Files=StringSplit($BifList, '|')
		For $f=1 to $Files[0]
			If Not FileExists($g_BG2Dir&'\Data\' & $Files[$f]&'.bif') Then
				If StringRegExp($Files[$f], 'CDCreAni|DESound') Then ContinueLoop; don't display this as an error fo potential additional files
				_Process_SetScrollLog($Files[$f]&' '&_GetTR($Message, 'L24')); =>does not exist
				$Error+=1
			EndIf
		Next
	EndIf
	GUICtrlSetData($g_UI_Interact[6][1], 100)
	_Process_SetScrollLog('')
	If $Save=2 Then
		_Process_SetScrollLog(StringFormat(_GetTR($Message, 'L23'), $g_RemovedDir)&'|'); =>old files were moved to
	EndIf
	Return $Error
EndFunc   ;==>_Backup_Restore

; ---------------------------------------------------------------------------------------------
; Checks conditions of a backup. Return codes: 0=done / 1=done & mods already installed / 2 = not done / 3=not done & mods already installed
; ---------------------------------------------------------------------------------------------
Func _Backup_Test($p_Game)
	Local $IsInstalled=0
	Local $Game[10][2]=[[9], ['BG1', 'BGMain2'],['BG2', 'BGMain'], ['IWD1', 'IDMain'],['IWD2', 'IWD2'], ['PST', 'Torment'], ['BG1EE', 'Baldur'], ['BG2EE', 'Baldur'], ['IWD1EE', 'Icewind'], ['PSTEE', 'Torment']]
	For $g=1 to $Game[0][0]
		If $Game[$g][0] = $p_Game Then ExitLoop
	Next
	$Test= StringRegExp(FileRead(Eval('g_'&$p_Game&'Dir') & '\WeiDU.log'), @LF&'~.*#.\s#', 3)
	If IsArray($Test) Then
		For $t=0 to UBound($Test)-1
			If Not StringInStr($Test[$t], 'DDRAW') Then $IsInstalled = 1
		Next
	EndIf
	If FileExists($g_BackupDir&'\'&$Game[$g][1]&'.exe') And $IsInstalled = 0 Then
		Return 0
	ElseIf FileExists($g_BackupDir&'\'&$Game[$g][1]&'.exe') And $IsInstalled = 1 Then
		Return 1
	ElseIf Not FileExists($g_BackupDir) And $IsInstalled = 0 Then
		Return 2
	ElseIf Not FileExists($g_BackupDir) And $IsInstalled = 1 Then
		Return 3
	EndIf
EndFunc   ;==>_Backup_Test