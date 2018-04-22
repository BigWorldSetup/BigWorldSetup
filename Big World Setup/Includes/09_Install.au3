#include-once

Global $g_WeiDUQuickLog = ''; '--quick-log'

; ---------------------------------------------------------------------------------------------
; Set some options, start test-run, exit if not successfull, make WeiDU-backups
; ---------------------------------------------------------------------------------------------
Func Au3PrepInst($p_Num = 0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling Au3PrepInst')
	Local $Message = IniReadSection($g_TRAIni, 'IN-Au3PrepInst')
	GUICtrlSetData($g_UI_Static[6][1], _GetTR($Message, 'L1')); => preparation
	GUICtrlSetData($g_UI_Static[6][2], _GetTR($Message, 'L2')); => watch progress
	If $g_Flags[14] = 'BWP' Then; create dummy-patch-files
		If Not FileExists($g_BG1Dir&'\readme_patch.txt') Then FileClose(FileOpen($g_BG1Dir&'\readme_patch.txt',2))
		If Not FileExists($g_BG2Dir&'\BG2-ToBPatchReadMe.txt') Then FileClose(FileOpen($g_BG2Dir&'\BG2-ToBPatchReadMe.txt',2))
		If Not ( FileExists($g_BG2Dir&'\CD5\movies\25Movies.bif') Or FileExists($g_BG2Dir & '\' & 'Movies\25movies.bif') ) Then FileClose(FileOpen($g_BG2Dir&'\CD5\movies\25Movies.bif',2+8))
	EndIf
	If StringRegExp($g_Flags[14], 'BWP|BWS') Then; BG2-options
; entries from Ini_Cheats.bat
		IniWrite($g_BG2Dir & '\baldur.ini', 'Program Options', 'Logging On', 1); enable crash-logs
		IniWrite($g_BG2Dir & '\baldur.ini', 'Program Options', 'Debug Mode', 1); enable cheats
		IniWrite($g_BG2Dir & '\baldur.ini', 'Game Options', 'Memory Access', 100); enable blood
		IniWrite($g_BG2Dir & '\baldur.ini', 'Game Options', 'Use 3d Animations', 1); enable 3D animations
; entries from Ini_Settings.bat
#cs
		IniWrite($g_BG2Dir & '\baldur.ini', 'Program Options', 'Path Search Nodes', 400000)
		IniWrite($g_BG2Dir & '\baldur.ini', 'Program Options', 'Volume Movie', 150)
		IniWrite($g_BG2Dir & '\baldur.ini', 'Program Options', 'Volume Music', 150)
		IniWrite($g_BG2Dir & '\baldur.ini', 'Program Options', 'Volume Voice', 150)
		IniWrite($g_BG2Dir & '\baldur.ini', 'Program Options', 'Volume Ambients', 150)
		IniWrite($g_BG2Dir & '\baldur.ini', 'Program Options', 'Volume SFX', 150)
		IniWrite($g_BG2Dir & '\baldur.ini', 'Program Options', 'Display Subtitles', 1)

		IniWrite($g_BG2Dir & '\baldur.ini', 'Game Options', 'Mid Level Brighten', 1)
		IniWrite($g_BG2Dir & '\baldur.ini', 'Game Options', 'High Level Brighten', 1)
		IniWrite($g_BG2Dir & '\baldur.ini', 'Game Options', 'Tiles Precache Percent', 100)
		IniWrite($g_BG2Dir & '\baldur.ini', 'Game Options', 'Use 3d Animations', 1)
		IniWrite($g_BG2Dir & '\baldur.ini', 'Game Options', 'Footsteps', 1)
		IniWrite($g_BG2Dir & '\baldur.ini', 'Game Options', 'Pausing Map', 1)
		IniWrite($g_BG2Dir & '\baldur.ini', 'Game Options', 'Low End Machine', 1)

		IniWrite($g_BG2Dir & '\baldur.ini', 'Config', 'General', 1)
		IniWrite($g_BG2Dir & '\baldur.ini', 'Config', 'Graphics', 1)
		IniWrite($g_BG2Dir & '\baldur.ini', 'Config', 'Sound', 1)
		IniWrite($g_BG2Dir & '\baldur.ini', 'Config', 'CacheSize', 1000)
#ce
; entries from Ini_movies.bat
		If StringRegExp($g_Compilation, '(?i)S|T|E') Then; enable skipping of movies for experienced players
			$Movies = StringSplit('BISLOGO,BWDRAGON,BEREGOST,BGENTER,BGINTRO,BGSUNRIS,BGSUNSET,BHALL,CAMP,CBCTMOVE,CBSOUBAR,CNDLKEEP,' & _
			'DAYNITE,DEATHAND,DUNGEON,DURLAG,ELDRCITY,END15FPS,ENDCRDIT,ENDMOVIE,FLYTHR01,FLYTHR02,FLYTHR03,FLYTHR04,FRARMINN,GNOLL,' & _
			'INTRO,INTRO15F,IRONTHRN,JZINTRO,MANAFORG,MELISSAN,MINEFLOD,NASHKELL,NITEDAY,OUTRO,PALACE,POCKETZZ,RESTCAMP,RESTDUNG,' & _
			'RESTINN,SARADUSH,SEWER,SOAINTRO,VA#MOV01,WOTC,WOTH,WRECK,WYVERN', ',')
			For $m=1 to $Movies[0]
				IniWrite($g_BG2Dir & '\baldur.ini', 'Movies', $Movies[$m], 1); enable exiting of movies
			Next
		EndIf
	ElseIf $g_Flags[14] = 'PST' Then
		IniWrite($g_PSTDir & '\Torment.ini', 'Config', 'CacheSize', 1); disable caching
	ElseIf $g_Flags[14] = 'IWD1' Then
		IniWrite($g_IWD1Dir & '\icewind.ini', 'Game Options', 'Cheats', '1')
	ElseIf StringInStr($g_Flags[14], 'EE') Then
		If $g_Flags[14]='BG1EE' Then
			$MyBGEE=@MyDocumentsDir&"\Baldur's Gate - Enhanced Edition"

		ElseIf $g_Flags[14]='BG2EE' Then
			$MyBGEE=@MyDocumentsDir&"\Baldur's Gate II - Enhanced Edition"
		ElseIf $g_Flags[14]='IWD1EE' Then
			$MyBGEE=@MyDocumentsDir&"\Icewind Dale - Enhanced Edition"
		ElseIf $g_Flags[14]='PSTEE' Then
			$MyBGEE=@MyDocumentsDir&"\Planescape Torment - Enhanced Edition"
		EndIf
		If Not FileExists($MyBGEE&'\save') Then DirCreate($MyBGEE&'\save')
		If Not FileExists($MyBGEE&'\characters') Then DirCreate($MyBGEE&'\characters')
		If Not FileExists($MyBGEE&'\portraits') Then DirCreate($MyBGEE&'\portraits')
		If Not FileExists($g_GameDir&'\override') Then DirCreate($g_GameDir&'\override')

			If $g_Flags[14]='BG1EE' Then
				$Lang=_Install_GetEELang(_GetTR($Message, 'L4'), 1); => choose a language BG1EE

			ElseIf $g_Flags[14] = 'BG2EE' Then
				$Lang=_Install_GetEELang(_GetTR($Message, 'L4'), 2); => choose a language BG2EE
			ElseIf $g_Flags[14] = 'IWD1EE' Then
				$Lang=_Install_GetEELang(_GetTR($Message, 'L4'), 3); => choose a language IWD1EE
			ElseIf $g_Flags[14] = 'PSTEE' Then
				$Lang=_Install_GetEELang(_GetTR($Message, 'L4'), 4); => choose a language PSTEE
			EndIf

			; _PrintDebug('Debug '&$Lang, 1)
			; Make sure that $lang for $g_GameDir&'\WeiDu.conf' is not set to non existing $g_GameDir\lang\ directory before first weidu mod will be installed
			; otherwise, weidu will fail with "None of the dialog paths were a match against $lang"
			
			$Lang = _Install_GetEELangDir($Lang)
			FileDelete($g_GameDir&'\WeiDu.conf')
			FileWrite($g_GameDir&'\WeiDu.conf', 'lang_dir = '&$Lang)
	EndIf
	FileMove($g_GameDir & '\*.DEBUG', $g_GameDir & '\DEBUG-Bak\', 9)
	FileMove($g_GameDir & '\WeiDU.log', $g_GameDir & '\WeiDU-' & @YEAR & @MON & @MDAY & @HOUR & @MIN & '.log', 1)
	$Success=_CDTray('Open')
	If $Success = 1 Then
		_Misc_MsgGUI(1, $g_ProgName, _GetTR($Message, 'L3')); => remove cds
		_CDTray('Closed')
	EndIf
	;If FileExists($g_DownDir&'\WeiDU.exe') Then FileDelete($g_DownDir&'\WeiDU.exe'); => delete the old WeiDU, so the program can download it again
	IniWrite($g_BWSIni, 'Order', 'Au3PrepInst', 0); Skip this one if the Setup is rerun
EndFunc   ;==>Au3PrepInst

; ---------------------------------------------------------------------------------------------
; Installs fixes and patches
; ---------------------------------------------------------------------------------------------
Func Au3RunFix($p_Num = 0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling Au3RunFix')
	Local $Message = IniReadSection($g_TRAIni, 'IN-Au3RunFix')
	$Type=StringRegExpReplace($g_Flags[14], '(?i)BWS|BWP', 'BG2')
	_Process_SwitchEdit(0, 0)
	_Process_ChangeDir($g_GameDir, 1)
	GUICtrlSetData($g_UI_Interact[6][4], StringFormat(_GetSTR($Message, 'H1'), $Type)); => help text
	GUICtrlSetData($g_UI_Static[6][1], _GetTR($Message, 'L2')); => watch progress
	$g_LogFile = $g_LogDir & '\BWS-Debug-Installation.log'
	; No longer used
	; Special case, EET-patches-for-BG2EE-mods-master must be extracted after all other mods are extracted, before files are copied in from
	; OverwriteFiles (_Extract_OverwriteFiles()) and before Big World Fixpack is run
	; Use Experimental function which fix DirMove "ub\ub" problem. Used only with EET Patches for Mods to minimalize new bugs
	;If FileExists($g_GameDir&'\EET-patches-for-BG2EE-mods-master') Then
	;	FileWrite($g_LogFile, '>EET-patches-for-BG2EE-mods-master\* .' & @CRLF)
	;	_Extract_MoveModEx('EET-patches-for-BG2EE-mods-master')
	;EndIf
	_Extract_OverwriteFiles()
; ---------------------------------------------------------------------------------------------
; make sure the WeiDU-setups are really replaced by a new one
; ---------------------------------------------------------------------------------------------
	If FileExists($g_GameDir&'\WeiDU\WeiDU.exe') Then
		GUICtrlSetData($g_UI_Static[6][2], _GetTR($Message, 'L3')); => copy WeiDU
		$Setup=_FileSearch($g_GameDir, '*.exe')
		ReDim $Setup[$Setup[0]+2]; => make sure to add WeiDU itself so it exists
		$Setup[0]+=1
		$Setup[$Setup[0]]='WeiDU.exe'
		$Size=FileGetSize($g_GameDir&'\WeiDU\WeiDU.exe')
		For $s=1 to $Setup[0]
			If StringRegExp($Setup[$s], '(?i)-{0,1}(setup)-{0,1}.*exe\z|WeiDU.exe') Then
				ProcessClose($Setup[$s])
				While 1
					If $Size = FileGetSize($g_GameDir&'\'&$Setup[$s]) Then ExitLoop
					$Test=FileCopy($g_GameDir&'\WeiDU\WeiDU.exe', $g_GameDir&'\'&$Setup[$s], 1)
					If $Test = 1 Then ExitLoop
					$Test=_Misc_MsgGUI(3, _GetTR($g_UI_Message, '0-T1'), _GetTR($Message, 'L9')&'||'& StringFormat(_GetTR($Message, 'L10'), $Setup[$s], $Type), 2); => cannot continue without current WeiDU
					If $Test = 1 Then Exit
				WEnd
			EndIf
		Next
		If Not StringInStr(FileRead($g_GameDir&'\WeiDU.log'), 'WeiDU.tp2') Then
			$PID=Run('"'&$g_GameDir&'\WeiDU\WeiDU.exe" --exit', $g_GameDir, @SW_HIDE, 8); read the version-number directly from weidu
			ProcessWaitClose($PID)
			$Version=StringRegExp(StdoutRead($PID), '\d{5}\r\n', 3)
			If IsArray($Version) Then _Install_CreateTP2Entry('WeiDU', StringTrimRight($Version[0],2))
		EndIf
	Else
		$Site=IniRead($g_MODIni, 'WeiDU', 'Link', '')
		_Misc_MsgGUI(4, _GetTR($g_UI_Message, '0-T1'), _GetTR($Message, 'L9')&'||'& StringFormat(_GetTR($Message, 'L11'), $Type, $Site, $g_GameDir&'\WeiDU\WeiDU.exe')); => need extracted WeiDU-archive
		Exit
	EndIf
	If Not StringInStr(FileRead($g_GameDir&'\WeiDU.log'), 'BWS.tp2') Then
		$Array=StringSplit(StringStripCR(FileRead($g_BaseDir & '\Documentation\Changelog-Mods.txt')), @LF); read the version-number from the changelog
		For $a=$Array[0] to 1 Step -1
			If StringRegExp($Array[$a], '\A\d') Then
				If $g_Flags[14]='BWP' Then $Array[$a]&=' setting up BWP-install'
				_Install_CreateTP2Entry('BWS', $Array[$a])
				ExitLoop
			EndIf
		Next
	EndIf
	If Not StringInStr(FileRead($g_GameDir&'\WeiDU.log'), 'BWS-URL.tp2') And FileExists($g_DownDir&'\Mod.ini.gz') Then _Install_CreateTP2Entry('BWS-URL', FileGetTime($g_DownDir&'\Mod.ini.gz', 1, 1))
	If FileExists($g_GameDir&'\shs#soundsets\install_win.bat') And not FileExists($g_GameDir&'\sounds\m_sassy1.wav')Then
		GUICtrlSetData($g_UI_Static[6][2], _GetTR($Message, 'L5')); => install pcsoundset
		ShellExecuteWait($g_GameDir&'\shs#soundsets\install_win.bat', '', $g_GameDir&'\shs#soundsets', '', @SW_HIDE)
	EndIf
	If Not FileExists($g_GameDir&'\Portraits') Then DirCreate($g_GameDir&'\Portraits')
	If StringRegExp($g_Flags[14], 'BWP|BWS') Then
		_Install_BG1Textpatch($Message)
		;If Not StringInStr(FileRead($g_BG2Dir&'\WeiDU.log'), 'BWFixpack.TP2') Then _Install_CreateTP2Entry('BWFixpack', IniRead($g_MODIni, 'BWFixpack', 'Save', ''))
		If IniRead($g_UsrIni, 'Save', 'BWTextpack', '') <> '' Then
			$Tra = _GetTra('BWTextpack', 'T')
			If $Tra = 'GE' Then
				$File=IniRead($g_MODIni, 'BWTextpack', 'GE-AddSave', 'Unknown')
				If FileExists($g_DownDir&'\'&$File) And Not StringInStr(FileRead($g_BG2Dir&'\WeiDU.log'), 'BWTextpack.TP2') Then _Install_CreateTP2Entry('BWTextpack', $File)
			ElseIf $Tra = 'SP' Then
				$File=IniRead($g_MODIni, 'BWTextpack', 'SP-AddSave', 'Unknown')
				If FileExists($g_DownDir&'\'&$File) And Not StringInStr(FileRead($g_BG2Dir&'\WeiDU.log'), 'BWTextpack.TP2') Then _Install_CreateTP2Entry('BWTextpack', $File)
			ElseIf $Tra = 'RU' Then
				$File=IniRead($g_MODIni, 'BWTextpack', 'RU-AddSave', 'Unknown')
				If FileExists($g_DownDir&'\'&$File) And Not StringInStr(FileRead($g_BG2Dir&'\WeiDU.log'), 'BWTextpack.TP2') Then _Install_CreateTP2Entry('BWTextpack', $File)
			EndIf
		EndIf
; ---------------------------------------------------------------------------------------------
; run textharmonisation if wanted
; ---------------------------------------------------------------------------------------------
		If $g_MLang[1] = 'GE' And IniRead($g_UsrIni, 'Options', 'TAPatch', 1) = 1 Then
			_Process_Run('xcopy /Y /S /E ".\Big World Textpack GERMAN\_Textharmonisation" ".\Big World Textpack GERMAN"', 'xcopy.exe')
			If Not StringInStr(FileRead($g_BG2Dir&'\WeiDU.log'), 'Textharmonisation.TP2') Then _Install_CreateTP2Entry('Textharmonisation', IniRead($g_MODIni, 'BWTextpack', 'GE-AddSave', ''))
		EndIf
		;If Not StringInStr(FileRead($g_BG2Dir&'\WeiDU.log'), 'BWTrimpack.TP2') Then _Install_CreateTP2Entry('BWTrimpack', IniRead($g_MODIni, 'BWTrimpack', 'Save', 'Unknown'))
		If Not StringInStr(FileRead($g_BG2Dir&'\WeiDU.log'), 'BWInstallpack.TP2') Then _Install_CreateTP2Entry('BWInstallpack', IniRead($g_MODIni, 'BWInstallpack', 'Save', 'Unknown'))
		If _Install_PatchTest() = 0 Then
			_Misc_MsgGUI(4, _GetTR($g_UI_Message, '0-T1'), _GetTR($Message, 'L13')&'|'& StringFormat(StringRegExpReplace(_GetTR($g_UI_Message, '8-L2'), '\A[^\x7c]*\x7c', ''), @AutoItExe), 1, _GetTR($g_UI_Message, '8-B3')); => cannot read log -> exit
			Exit
		EndIf
	EndIf
; ---------------------------------------------------------------------------------------------
; Install Russian textpack from arcanecoast.ru
; ---------------------------------------------------------------------------------------------
	If $g_MLang[1] = 'RU' And StringRegExp($g_Flags[14], 'IWD1|IWD2|PST') Then
		$Type = StringLeft($g_Flags[14], 3)
		$Counter=0
		$Mods=_FileSearch($g_GameDir&'\Russian_'&$Type&'_update', '*')
		For $m=1 to $Mods[0]
			$TP2 = _Test_GetTP2($Mods[$m])
			If $TP2 = '0' Then ContinueLoop
			$Counter+=1
			$File=_FileSearch($g_GameDir&'\Russian_'&$Type&'_update\'&$Mods[$m], '*')
			For $f=1 to $File[0]
				If StringInStr(FileGetAttrib($g_GameDir&'\Russian_'&$Type&'_update\'&$Mods[$m]&'\'&$File[$f]), 'D') Then
					DirCopy($g_GameDir&'\Russian_'&$Type&'_update\'&$Mods[$m]&'\'&$File[$f], $g_GameDir&'\'&$File[$f], 1)
				Else
					FileCopy($g_GameDir&'\Russian_'&$Type&'_update\'&$Mods[$m]&'\'&$File[$f], $g_GameDir&'\'&$File[$f], 1)
				EndIf
			Next
		Next
		If $Counter > 0 Then
			$Rev=IniRead($g_MODIni, 'Textpack', 'Rev', 'Unknown')
			If Not StringInStr(FileRead($g_GameDir&'\WeiDU.log'), 'Textpack.TP2') Then
				_Install_CreateTP2Entry('Textpack', $Rev)
			EndIf
		EndIf
	EndIf
; ---------------------------------------------------------------------------------------------
; Replace variables defined in other batches to make them usable for BWS.
; ---------------------------------------------------------------------------------------------
	If $g_Flags[14]='BWS' Then
		Local $ID[3]=[2, 'trim', 'fix_Kit']
		For $i=1 to $ID[0]
			$File=$g_BG2Dir&'\Big World Installpack\'&$ID[$i]&'_IDS.bat'
			$Text=FileRead($File)
			If StringInStr($Text, '%BWFP%') Then
				$Handle=FileOpen($File, 2)
				FileWrite($Handle, StringReplace($Text, '%BWFP%', 'Big World Fixpack'))
				FileClose($Handle)
			EndIf
		Next
	EndIf
	IniWrite($g_BWSIni, 'Order', 'Au3RunFix', 0); Skip this one if the Setup is rerun
	GUICtrlSetData($g_UI_Static[6][1], _GetTR($Message, 'L7')); => all steps are done
	GUICtrlSetData($g_UI_Static[6][2], '')
	$g_ConsoleOutput=''
	If $g_Flags[14] = 'BWP' Then; do a batch-installation
		_Process_SwitchEdit(1)
		GUICtrlSetState($g_UI_Button[0][3], $Gui_DISABLE)
		_Process_SetScrollLog(_GetTR($Message, 'L12'), 1, -1); => you may need to close security-software
		GUICtrlSetImage($g_UI_Static[0][3], @ScriptDir & "\Pics\FinalLogo.jpg")
		For $i=1 to 100
			Sleep(100)
			GUICtrlSetData($g_UI_Interact[6][1], $i)
		Next
		GUICtrlSetState($g_UI_Button[0][3], $Gui_ENABLE)
		AutoItSetOption('OnExitFunc','_Install_BatchRun'); execute batch on close
		_ResetInstall()
		_Process_Gui_Delete(7, 7, 1)
		Exit
	ElseIf IniRead($g_UsrIni, 'Options', 'Logic3', 1) = '3' Then; hide message if needed
		_Misc_MsgGUI(2, _GetTR($Message, 'L7'), _GetTR($Message, 'L8'), 1, '', '', '', 30); => pre-install-info
	Else
		_Misc_MsgGUI(2, _GetTR($Message, 'L7'), _GetTR($Message, 'L8')); => pre-install-info
	EndIf
EndFunc    ;==>Au3RunFix

; ---------------------------------------------------------------------------------------------
; Just run the customized install-batch if it exists
; ---------------------------------------------------------------------------------------------
Func Au3Install($p_Num = 0, $p_Debug = 0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling Au3Install')
	Local $RMessage = IniReadSection($g_TRAIni, 'IN-Check')
	Local $TMessage = IniReadSection($g_TRAIni, 'IN-Test')
	Local $Message = IniReadSection($g_TRAIni, 'IN-Au3Install')
	$g_LogFile = $g_LogDir & '\BWS-Debug-Installation.log'
	Local $Group = '-1', $CurrentMod, $Setup[10], $Type=StringRegExpReplace($g_Flags[14], '(?i)BWS|BWP', 'BG2')
	Local $Logic = IniRead($g_UsrIni, 'Options', 'Logic3', 1), $Ref=FileGetSize($g_GameDir&'\WeiDU\WeiDU.exe')
	Local $EET_Mods
	If $g_Flags[21] <> '' Then $EET_Mods=$g_Flags[20+StringRegExpReplace($g_Flags[14],  '(?i)\ABG|EE\z', '')]
	GUICtrlSetData($g_UI_Interact[6][4], StringFormat(_GetSTR($Message, 'H1'), $Type)); => help text
	_Process_ChangeDir($g_GameDir, 1)
	FileClose(FileOpen($g_GameDir&'\BWS_Dummy.nul', 2))
	_Process_SwitchEdit(0, 1)
	If Not FileExists($g_GameDir & '\WeiDU\WeiDU.exe') Then
		_Misc_MsgGUI(4, _GetTR($g_UI_Message, '0-T1'), StringFormat(_GetTR($Message, 'L6'), $Type)); => need a current WeiDU
		Exit
	EndIf
	$g_LogFile = $g_LogDir & '\BWS-Debug-Installation.log'
	FileWriteLine($g_LogFile, 'Big World Install')
	GUICtrlSetData($g_UI_Static[6][1], _GetTR($Message, 'L1')); => watch progress
	$Array = StringSplit(StringRegExpReplace(StringStripCR(FileRead($g_GConfDir&'\InstallOrder.ini')), '\x0a((|\s{1,})\x0a){1,}', @LF), @LF)
	If IniRead($g_UsrIni, 'Options', 'GroupInstall', 0) = 1 Then $Array = _Install_ModifyForGroupInstall($Array); always install in groups
	If $p_Debug = 1 Then
		For $a = 1 To $Array[0]
			_Process_SetConsoleLog($Array[$a])
		Next
		_PrintDebug('Installation array printed to log Big World Setup\Logs\BWS-Debug.log',1)
		Exit
	EndIf
	For $a = $g_FItem To $Array[0]
		If $g_Flags[0] = 0 Then; the exit button was pressed
			Exit
		EndIf
		GUICtrlSetData($g_UI_Interact[6][1], ($a * 100) / $Array[0])
		If StringInStr($Array[$a], ';EET;') And StringInStr($g_GConfDir, 'BG2EE') And $g_Flags[14] = 'BG1EE' Then; this is the end of the BG1EE install, now install BG2EE and import BG1EE with EET
			ExitLoop; additional code for EET transition follows end of loop below
		ElseIf StringRegExp($Array[$a], '(?i)\A(DWN|ANN)') Then; skip comments and download-only mods
			ContinueLoop
		ElseIf StringRegExp($Array[$a], '(?i)\ACMD') Then
			$Split=StringReplace($Array[$a], "\;", "&SEMI&") ; allow backslash to escape a semicolon in CMD statements
			$Split=StringSplit($Split, ';')
			$Split[2]=StringReplace($Split[2], "&SEMI&", ";") ; replace placeholders with semicolons after splitting string
			IniWrite($g_BWSIni, 'Options', 'Start', $a); create entry to enable resume
			If UBound($Split)>6 Then; only look for requirement if line has enough semicolons
				If $Split[6] <> '' Then; skip if requirements are not met. No feedback - it's just a cmd like copy/del.
					If _Install_CheckCondition($Split[6]) = 0 Then ContinueLoop
				EndIf
			EndIf
			FileDelete($g_GameDir&'\BWS_Finished.nul')
			GUICtrlSetData($g_UI_Static[6][2], _GetTR($Message, 'L7')); => run batch
			$Handle = FileOpen($g_GameDir & '\Tmp.bat', 2); yeah, this looks stupid, but how else would I know that the action is done?
			;FileWriteLine($Handle, '@echo off'); be quiet
			FileWriteLine($Handle, $Split[2]); >> Do not comment if not debugging!!!
			FileWriteLine($Handle, 'copy "BWS_Dummy.nul" "BWS_Finished.nul" 2>nul 1>nul'); be a little more quiet
			FileClose($Handle)
			If Not StringRegExp($Array[$a], '(?i)\s(Call|For|xcopy)\s|_IDS') Then; just avoid some annoying and useless linefeeds
				_Process_SetConsoleLog($Split[2])
				ShellExecuteWait('Tmp.bat', '', $g_GameDir, '', @SW_HIDE)
			Else
				_Process_Run('Tmp.bat', 'BWS_Finished.nul')
			EndIf
		ElseIf StringRegExp($Array[$a], '(?i)\AGRP;Start') Then
			IniWrite($g_BWSIni, 'Options', 'Start', $a); create entry to enable resume (start of a group)
			$Group=''
			ContinueLoop
		ElseIf StringRegExp($Array[$a], '(?i)\AGRP;Stop') Then
			If $Group = '-1' Or $Group = '' Then ; Stop without preceding Start or empty group (possibly due to purging)
				$Group = -1
				ContinueLoop
			EndIf
			$Group = StringTrimLeft($Group, 1)
			$Setup[0]='Setup-'&$Setup[2]&'.exe'
			$InstallString=$Setup[0]&' --no-exit-pause --noautoupdate --language '&StringTrimLeft($Setup[5], 3) &' --skip-at-view '&$g_WeiDUQuickLog&' --force-install-list '&$Group&' --logapp'
			_Install_ManageDebug($Setup[2], 1); clean old debug log
			_Install_UpdateWeiDU($Setup[0], $Ref); if needed, create or update WeiDU executable for this mod
			_Install_SetPrompt($Setup[9], StringTrimLeft($Setup[5], 3)); adjust keywords for debugging-output
			GUICtrlSetData($g_UI_Static[6][2], _GetTR($Message, 'L14') & ' (' & $Setup[7]&')'); => installing a list of components
			_Process_Run($InstallString, $Setup[0])
			$Test = StringSplit($Group, ' ')
			$DebugTest=_Install_ReadDebug($Setup[2])
			For $t=1 to $Test[0]
				$Setup[3]=$Test[$t]
				$Setup[8]=IniRead($g_GConfDir&'\WeiDU-'&StringLeft($Setup[5],2)&'.ini', $Setup[2], '@' & $Setup[3], ''); component-description
				If _Install_TestInstalled($Setup, $DebugTest, $Logic, $t, $TMessage) = 1 Then; user selected to try again
					$InstallString = $Setup[0]&' --no-exit-pause --noautoupdate --language '&StringTrimLeft($Setup[5], 3) &' --skip-at-view '&$g_WeiDUQuickLog&' --force-uninstall-list '&$Group&' --logapp'; uninstall group
					_Process_Run($InstallString, $Setup[0])
					While 1; search for first installed component
						$Split=StringSplit($Array[$a], ';')
						If UBound($Split) > 3 Then; avoid crashes on group- or ann-lines
							If $Split[3] = $Test[1] And $Split[2] = $Setup[2] And StringRegExp($Split[1], '(?i)STD|MUC|SUB') Then; get a valid line
								$a-=1
								$Group=''
								ContinueLoop 3; redo from that position
							EndIf
						EndIf
						$a-=1
					WEnd
				EndIf
			Next
			$Group = -1
			_Install_ManageDebug($Setup[2], 2); merge debug-files
			If $Type = 'BG2' Then _Install_RepairIDS()
			ContinueLoop
		Else
			If $Group = '-1' Then IniWrite($g_BWSIni, 'Options', 'Start', $a); create entry to enable resume (we're not currently in a group install + we're at a specific component)
			GUICtrlSetData($g_UI_Static[6][2], _GetTR($Message, 'L2')); => test conditions for install
; ---------------------------------------------------------------------------------------------
; get the lines of WeiDU-data into an array
; ---------------------------------------------------------------------------------------------
			$Split=StringSplit($Array[$a], ';')
			If $Split[0] < 6 Then
				_Process_SetConsoleLog('WARNING:  BWS is skipping an incorrectly formatted line '&$a&' in '&$g_GConfDir&'\InstallOrder.ini'&': '&$Array[$a])
				ContinueLoop
			EndIf
			$Setup[0]=$Split[1]; LineType
			$Setup[2]=$Split[2]; SetupName
			$Setup[3]=$Split[3]; CompNumber
			; $Split[4] => theme (not needed here)
			; $Split[5] => defaults (not needed here)
			$Setup[6]=$Split[6]; $CompReq
			If $CurrentMod <> $Setup[2] Then; same mod > no update
				$Setup[5]=_GetTra($Setup[2], 'S')
				$Setup[7]=IniRead($g_MODIni, $Setup[2], 'Name', $Setup[2]); Modname
				If $EET_Mods <> '' And StringRegExp($EET_Mods, '(?i)(\A|\x7c)'&$Setup[2]&'(\z|\x7c)') = 0 Then ContinueLoop; this mod should not be installed now
				If IniRead($g_UsrIni, 'Current', $Setup[2], '') = '' Then ContinueLoop; the user did not select the mod at all
				$Setup[9]=_Test_GetCustomTP2($Setup[2])
				$Error=@error
				_Process_SetConsoleLog(@CRLF&@CRLF&'##### ' & $Setup[7] & ' #####')
				If $Error = 0 And FileExists($Setup[9]) Then
					;mod found
				Else
					If StringRegExp(IniRead($g_UsrIni, 'Pause', $Setup[2], ''), '(\A|\s)'&$Setup[3]&'(\z|\s)') Then _Process_Pause($Setup[7]); pause due to preselection
; ---------------------------------------------------------------------------------------------
; ask what to do if the mod is missing
; ---------------------------------------------------------------------------------------------
					_Process_SetConsoleLog(_GetTR($Message, 'L3')); => mod not found
					$Dependent=_Depend_GetUnsolved($Setup[2], '-'); $Dependent[0][unsolved, output, missing + unsolved]
					If $Dependent[0][0] <> 0 Then
						_Process_SetConsoleLog(_GetTR($g_UI_Message, '6-L6'), -1); => mods cannot be installed due to dependencies
						_Process_SetConsoleLog($Dependent[0][1])
					EndIf
					If $Logic = 5 Then; always continue-logic
						If $Dependent[0][0] <> 0 Then
							$Dependent[0][0]+=1
							ReDim $Dependent[$Dependent[0][0]+1][4]
							$Dependent[$Dependent[0][0]][0]=$Setup[2]
							_Depend_RemoveFromCurrent($Dependent)
						EndIf
						ContinueLoop
					EndIf
					_Process_SetConsoleLog(_GetTR($Message, 'L17'), -1); => make sure mod exists
					_Process_Question('r|c|e', _GetTR($TMessage, 'L6'), _GetTR($TMessage, 'Q1'), 3, $g_Flags[18]); => install anyway/skip/exit?
					If $g_pQuestion = 'e' Then; exit
						Exit
					ElseIf $g_pQuestion = 'c' Then; continue
						If $Dependent[0][0] <> 0 Then
							$Dependent[0][0]+=1
							ReDim $Dependent[$Dependent[0][0]+1][4]
							$Dependent[$Dependent[0][0]][0]=$Setup[2]
							_Depend_RemoveFromCurrent($Dependent)
						EndIf
						ContinueLoop
					Else; retry
						$a-=1
						ContinueLoop
					EndIf
				EndIf
				$CurrentMod = $Setup[2]
			EndIf
			$Setup[8] = IniRead($g_GConfDir&'\WeiDU-'&StringLeft($Setup[5],2)&'.ini', $Setup[2], '@' & $Setup[3], ''); component-description
; ---------------------------------------------------------------------------------------------
; skip for various reasons
; ---------------------------------------------------------------------------------------------
			If StringRegExp(IniRead($g_UsrIni, 'Pause', $Setup[2], ''), '(\A|\s)'&$Setup[3]&'(\z|\s)') Or $g_Flags[11] = 1 Then _Process_Pause($Setup[7]); pause due to preselection or current decision
			If _Install_Check($Setup, $Logic, $RMessage) = 0 Then ContinueLoop; check for dependencies and conflicts
; ---------------------------------------------------------------------------------------------
; Prepare for installation
; ---------------------------------------------------------------------------------------------
			If $Setup[2] = 'GUI' Then
				$Test = _Install_GetGUICompNumber($Setup[3]); check if the installation is possible and what number it has
				If $Test = -1 Then
					Local $Dependent[2][2] = [[1, ''], [$Setup[2], $Setup[3]]]
					_Depend_RemoveFromCurrent($Dependent); remove component from installed items
					ContinueLoop
				EndIf
				$Setup[3] = $Test
			EndIf
			If $Group <> '-1' Then; started a group for batch-installation. Component will be appended
				$Group&=' '&$Setup[3]
				ContinueLoop
			EndIf
			_Install_ManageDebug($Setup[2], 1); clean old debug
			$Sub=_Install_BuildSubcmd($Setup[2], $Setup[3])
			$Setup[0]='Setup-'&$Setup[2]&'.exe'
			If $Sub = 0 Then
				If $Setup[2] = 'BGT' Then; add bg1-param
					$InstallString=$Setup[0]&' --no-exit-pause --noautoupdate --language '&StringTrimLeft($Setup[5], 3) &' --skip-at-view '&$g_WeiDUQuickLog&' --args-list ops "'&$g_BG1Dir&'" --force-install-list '&$Setup[3]&' --logapp'
				ElseIf $Setup[2] = 'BGT-NPCSound' Then; hide the output
					$InstallString=$Setup[0]&' --no-exit-pause --noautoupdate --language '&StringTrimLeft($Setup[5], 3) &' --skip-at-view '&$g_WeiDUQuickLog&' --force-install-list '&$Setup[3]&' --logapp 2>nul 1>nul'
				ElseIf $Setup[2] = 'EET' Then; add bg1ee-param
					$InstallString=$Setup[0]&' --no-exit-pause --noautoupdate --language '&StringTrimLeft($Setup[5], 3) &' --skip-at-view '&$g_WeiDUQuickLog&' --args-list p "'&$g_BG1EEDir&'" --force-install-list '&$Setup[3]&' --logapp'
				Else
					$InstallString=$Setup[0]&' --no-exit-pause --noautoupdate --language '&StringTrimLeft($Setup[5], 3) &' --skip-at-view '&$g_WeiDUQuickLog&' --force-install-list '&$Setup[3]&' --logapp'
				EndIf
			Else
				$InstallString='type BWS_SUB.nul | '&$Setup[0]&' --no-exit-pause --noautoupdate --language '&StringTrimLeft($Setup[5], 3) &' --skip-at-view '&$g_WeiDUQuickLog&' --force-install-list '&$Setup[3]&' --logapp'
			EndIf
			_Install_ManageDebug($Setup[2], 1); clean old debug log
			_Install_UpdateWeiDU($Setup[0], $Ref); if needed, create or update WeiDU executable for this mod
			_Install_SetPrompt($Setup[9], StringTrimLeft($Setup[5], 3)); adjust keywords for debugging-output
			GUICtrlSetData($g_UI_Static[6][2], _GetTR($Message, 'L5') & ' ' & $Setup[8] & ' (' & $Setup[7]&')'); => installing
			$Success=_Process_Run($InstallString, $Setup[0])
			If $Success = 0 Then
				If StringRegExp($Logic, '5') = 0 Then; errors should be displayed
					_Process_SetConsoleLog(_GetTR($Message, 'L15'), -1); => try to start cmd again?
					_Process_Question('r|c|e', _GetTR($TMessage, 'L6'), _GetTR($TMessage, 'Q1'), 3, $g_Flags[18]); => retry/continue (skip)/exit?
				Else
					$g_pQuestion = 'r'; set answer to retry if user chose not to be prompted
				EndIf
				If $g_pQuestion = 'e' Then; exit
					Exit
				ElseIf $g_pQuestion = 'c' Then; continue
					ContinueLoop
				ElseIf $g_pQuestion = 'r' Then; retry
					$Success=_Process_Run($InstallString, $Setup[0])
					If $Success = 0 Then
						_Misc_MsgGUI(4, _GetTR($g_UI_Message, '0-T1'), _GetTR($Message, 'L16')); => Got an error again. User action needed. Exit BWS.
						Exit
					EndIf
				EndIf
			EndIf
			$DebugTest=_Install_ReadDebug($Setup[2])
			$a-=_Install_TestInstalled($Setup, $DebugTest, $Logic, 1, $TMessage)
			_Install_ManageDebug($Setup[2], 2); merge debug-files
			If $Type = 'BG2' Then _Install_RepairIDS()
			Sleep(1000)
		EndIf
	Next
	_Install_CreateTP2Entry('BWS_Final', 'Make quick-logged WeiDU-entries visible'); use a dummy install/uninstall without '&$g_WeiDUQuickLog&' to add details from previous WeiDU setups that used '&$g_WeiDUQuickLog&'
	_Process_Run('WeiDU.exe "Setup-BWS_Final.tp2" --no-exit-pause --game "." --language 0 --force-uninstall-list 0 --log "Setup-BWS_Final.Debug"', 'WeiDU.exe')
	FileClose(FileOpen($g_GameDir&'\WeiDU\BWP_Backup\0\MAPPINGS.0', 9))
	If StringInStr($g_GConfDir, 'BG2EE') And $g_Flags[14] = 'BG1EE' Then; this is the end of the BG1EE install, now install BG2EE and import BG1EE with EET
		IniWrite($g_UsrIni,  'Options', 'AppType', 'BG2EE:BG2EE'); change $g_Flags[14] (and so the games type) to BG2EE
		$Order=StringSplit('Au3CleanInst|Au3PrepInst|Au3NetFix|Au3Extract|Au3ExFix|Au3ExTest|Au3RunFix|Au3Install', '|'); things to do during BG2EE
		For $o=1 to $Order[0]
			IniWrite($g_BWSIni, 'Order', $Order[$o], 1); re-enable BG2EE-install
		Next
		IniWrite($g_BWSIni, 'Options', 'Start', '1')
		$g_CurrentOrder=3; install will resume at Au3GetVal
		Return
	EndIf
; ---------------------------------------------------------------------------------------------
; show not installed mods and say goodbye
; ---------------------------------------------------------------------------------------------
	GUICtrlSetImage($g_UI_Static[0][3], @ScriptDir & "\Pics\FinalLogo.jpg")
	_Process_SwitchEdit(1, 0)
	GUICtrlSetState($g_UI_Button[0][3], $Gui_DISABLE)
	$ReadSection=IniReadSection($g_UsrIni, 'RemovedFromCurrent')
	If Not @error Then
		$Text=StringSplit(_GetTR($Message, 'L10'), '|'); => mod/component
		_Process_SetScrollLog(_GetTR($Message, 'L9')&'|', 1, -1); => following could not be installed
		For $r=1 to $ReadSection[0][0]
			_Process_SetScrollLog($Text[1] & ': '&IniRead($g_MODIni, $ReadSection[$r][0], 'Name', $ReadSection[$r][0]))
			$Tra=_GetTra($ReadSection[$r][0], 'W')
			$Components=_SplitComp($ReadSection[$r][1])
			For $c=1 To $Components[0]
				_Process_SetScrollLog($Text[2] & ': '&IniRead($Tra, $ReadSection[$r][0], '@'&$Components[$c], $Components[$c]))
			Next
			_Process_SetScrollLog('')
		Next
	EndIf
	$Counter=_FileSearch($g_GameDir&'\Override', '*')
	If _Install_ReadWeiDU('generalized_biffing') = 0 And $Counter[0] > 5000 Then
		_Process_SetScrollLog('|'&StringFormat(_GetTR($Message, 'L18'), $Counter[0], IniRead($g_ModIni, 'generalized_biffing', 'Down', '')), 0, -1); => sees like you have many files
		If _Install_ReadWeiDU('widescreen') Then _Process_SetScrollLog('|'&_GetTR($Message, 'L19'), 0, -1); => sees like you have many files
	EndIf
	$ACP=IniRead($g_UsrIni, 'Options', 'ACP', '')
	If $ACP <> '' Then
		_Process_SetScrollLog('||'&StringFormat(_GetTR($Message, 'L20'), $ACP), -1); => ACP was set. Reset?
		Local $TMessage = IniReadSection($g_TRAIni, 'BA-MultiInstall')
		_Process_Question('y|n', _GetTR($TMessage, 'L5'), _GetTR($TMessage, 'Q1')); => enter yes/no
		If $g_pQuestion = 'y' Then
			$Test=RegWrite('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Nls\CodePage', 'ACP', 'REG_SZ', $ACP)
			If @error Then
				_Process_SetScrollLog(StringReplace(_GetTR($g_UI_Message, '2-L7'), '1252', $ACP)); => Warning
			Else
				_Process_SetScrollLog(StringRegExpReplace(_GetTR($g_UI_Message, '2-L8'), '\x7c{2}[^\x7c]*\z', '')); => Hint / Applied & need to reboot.
			EndIf
		EndIf
		IniDelete($g_UsrIni, 'Options', 'ACP')
	EndIf
	If StringRegExp($g_Flags[14], 'BWS|BWP') Then
		_Process_SetScrollLog('||'&_GetTR($Message, 'L8'), 0, -1); => finish + how to start
	Else
		_Process_SetScrollLog('||'&StringRegExpReplace(_GetTR($Message, 'L8'), '\x7c.*\x7c{3}', '|||'), 0, -1); => finish + thank you (stripped BG2-stuff)
	EndIf
	GUICtrlSetData($g_UI_Static[6][2], _GetTR($Message, 'L11')); => create bug-report-archive
	_Install_CompressLog()
	GUICtrlSetState($g_UI_Button[0][3], $Gui_ENABLE)
	$g_LogFile = _ResetInstall() & '\BWS-Debug-Installation.log'
	If StringRegExp($g_Flags[14], 'BWP|BWS') Then
		If $g_MLang[1] = 'GE' Then; prepare Cleanup-tool to delete stuff
			FileCopy($g_BG2Dir&'\Big World Installpack\German\*', $g_BG2Dir&'\Big World Installpack\temp\', 1)
		ElseIf $g_MLang[1] = 'SP' Then
			FileCopy($g_BG2Dir&'\Big World Installpack\Spanish\*', $g_BG2Dir&'\Big World Installpack\temp\', 1)
		ElseIf $g_MLang[1] = 'RU' Then
			FileCopy($g_BG2Dir&'\Big World Installpack\Russian\*', $g_BG2Dir&'\Big World Installpack\temp\', 1)
		Else
			FileCopy($g_BG2Dir&'\Big World Installpack\English\*', $g_BG2Dir&'\Big World Installpack\temp\', 1)
		EndIf
		FileClose(FileOpen($g_BG2Dir&'\Big World Project.installed', 1))
	EndIf
	GUICtrlSetData($g_UI_Static[6][2], _GetTR($Message, 'L13')); => complete
	_Process_Gui_Delete(7, 7, 1)
EndFunc   ;==>Au3Install

; ---------------------------------------------------------------------------------------------
; show not installed mods and say goodbye
; ---------------------------------------------------------------------------------------------
Func _Install_BatchRun()
	$File=$g_BG2Dir&'\Big World Install.bat'
	If Not FileExists($File) Then Exit
	$Text=FileRead($File)
	If Not StringInStr($Text, 'cd /D "'&$g_BG2Dir&'"') Then; enable run as admin
		$Success=FileMove($File, $g_BG2Dir&'\Big World Install_with_UAC_problem.bat', 1)
		If $Success = 1 Then
			$Text='cd /D "'&$g_BG2Dir&'"'&@CRLF&$Text
			$Handle=FileOpen($File, 2)
			FileWrite($Handle, $Text)
			FileClose($Handle)
		EndIf
	EndIf
	If StringRegExp(@OSVersion, 'WIN_2016|WIN_2012R2|WIN_2012|WIN_2008R2|WIN_VISTA|WIN_7|WIN_8|WIN_81|WIN_10') = 1 And IsAdmin() = 0 Then
		ShellExecute($File, '', $g_BG2Dir, 'runas')
	Else
		ShellExecute($File, '', $g_BG2Dir)
	EndIf
;~ 	Au3Exit()
EndFunc   ;==>_Install_BatchRun

; ---------------------------------------------------------------------------------------------
; install the textpatches if needed
; ---------------------------------------------------------------------------------------------
Func _Install_BG1Textpatch($p_Message)
	$Success = _Test_CheckBG1TP(); German textpack
	If $Success <> 1 Then
		GUICtrlSetData($g_UI_Static[6][2], _GetTR($p_Message, 'L4')); => install TP
		_Process_ChangeDir($g_BG1Dir, 1)
		FileCopy($g_BG2Dir&'\WeiDU\WeiDU.exe', $g_BG1Dir&'\Setup-bg1tp.exe', 1)
		If $Success = -1 Then
			_Process_Run('Setup-BG1TP.exe --force-uninstall-list 0', 'Setup-bg1tp.exe')
			If StringInStr(FileRead($g_BG1Dir&'\WeiDU.log'), @LF&'~bg1tp') Then
				_Misc_MsgGUI(4, _GetTR($p_Message, 'T1'), _GetTR($p_Message, 'L6'), 1, _GetTR($p_Message, 'B1')); => cannot remove old TP
				Exit
			EndIf
			If FileExists($g_BG1Dir&'\Setup-bg1tp.tp2') And FileDelete($g_BG1Dir&'\Setup-bg1tp.tp2') = 0 Then; remove old tp2, else the old version is installed again
				_Misc_MsgGUI(4, _GetTR($p_Message, 'T1'), _GetTR($p_Message, 'L6'), 1, _GetTR($p_Message, 'B1')); => cannot remove old TP
				Exit
			EndIf
		EndIf
		_Process_Run('Setup-BG1TP.exe --no-exit-pause --noautoupdate --language 0 --skip-at-view --force-install-list 0', 'Setup-bg1tp.exe')
		If Not StringInStr(FileRead($g_BG1Dir&'\WeiDU.log'), @LF&'~bg1tp') Then
			_Misc_MsgGUI(4, _GetTR($p_Message, 'T1'), _GetTR($p_Message, 'L1'), 1, _GetTR($p_Message, 'B1')); => cannot install new TP
			Exit
		EndIf
		_Process_ChangeDir($g_BG2Dir, 1)
	EndIf
; ---------------------------------------------------------------------------------------------
; install the Spanish textpatch if needed
; ---------------------------------------------------------------------------------------------
	If $g_MLang[1] = 'SP' And Not StringInStr(FileRead($g_BG1Dir&'\WeiDU.log'), @LF&'~setup-Abra.tp2') And $g_BG1Dir <> '-' Then; first installation
		GUICtrlSetData($g_UI_Static[6][2], _GetTR($p_Message, 'L4')); => install abra
		_FileReplace($g_BG1Dir & '\Setup-Abra.tp2', 'AT_INTERACTIVE_EXIT ~VIEW Abra\Readme.htm~', '//AT_INTERACTIVE_EXIT ~VIEW Abra\Readme.htm~'); don't show the readme
		_Process_ChangeDir($g_BG1Dir, 1)
		FileCopy($g_BG2Dir&'\WeiDU\WeiDU.exe', $g_BG1Dir&'\Setup-Abra.exe', 1)
		_Process_Run('Setup-Abra.exe --no-exit-pause --noautoupdate --language 0 --skip-at-view --force-install-list 0 1', 'Setup-Abra.exe')
		If Not StringInStr(FileRead($g_BG1Dir&'\WeiDU.log'), @LF&'~setup-Abra.tp2') Then
			_Misc_MsgGUI(4, _GetTR($p_Message, 'T1'), _GetTR($p_Message, 'L1'), 1, _GetTR($p_Message, 'B1')); => cannot install abra
			Exit
		EndIf
		_Process_ChangeDir($g_BG2Dir, 1)
	EndIf
; ---------------------------------------------------------------------------------------------
; install the French textpatch if needed
; ---------------------------------------------------------------------------------------------
	If $g_MLang[1] = 'FR' And Not StringInStr(FileRead($g_BG1Dir&'\WeiDU.log'), @LF&'~correcfrbg1/correcfrbg1.tp2') And $g_BG1Dir <> '-' Then; first installation
		GUICtrlSetData($g_UI_Static[6][2], _GetTR($p_Message, 'L4')); => install textpatch
		_Process_ChangeDir($g_BG1Dir, 1)
		FileCopy($g_BG2Dir&'\WeiDU\WeiDU.exe', $g_BG1Dir&'\Setup-correcfrbg1.exe', 1)
		_Process_Run('Setup-correcfrbg1.exe --no-exit-pause --noautoupdate --language 0 --skip-at-view --force-install-list 0 1', 'Setup-correcfrbg1.exe')
		If Not StringInStr(FileRead($g_BG1Dir&'\WeiDU.log'), @LF&'~correcfrbg1/correcfrbg1.tp2') Then
			_Misc_MsgGUI(4, _GetTR($p_Message, 'T1'), _GetTR($p_Message, 'L1'), 1, _GetTR($p_Message, 'B1')); => cannot install correcfrbg
			Exit
		EndIf
		_Process_ChangeDir($g_BG2Dir, 1)
	EndIf
; ---------------------------------------------------------------------------------------------
; install the Polish BG1 characters conversion if needed
; ---------------------------------------------------------------------------------------------
	If $g_MLang[1] = 'PO' And FileGetSize($g_BG1Dir&'\DialogF.tlk') = '3430385' And Not FileExists($g_BG1Dir&'\Dialog.bak') And $g_BG1Dir <> '-' Then; first installation
		GUICtrlSetData($g_UI_Static[6][2], _GetTR($p_Message, 'L4')); => install textpatch
		_Process_ChangeDir($g_BG1Dir, 1)
		FileCopy($g_BG2Dir&'\BGT\kpzbg1.exe', $g_BG1Dir&'\kpzbg1.exe', 1)
		$Handle=FileOpen($g_BG1Dir&'\kpzbg1.txt', 2)
		FileWrite($Handle, 3&@CRLF&1&@CRLF)
		FileClose($Handle)
		_Process_Run('type kpzbg1.txt|kpzbg1.exe', 'kpzbg1.exe')
		If Not StringInStr($g_ConsoleOutput, 'Operacja sie powiodla.') Then
			_Misc_MsgGUI(4, _GetTR($p_Message, 'T1'), _GetTR($p_Message, 'L1'), 1, _GetTR($p_Message, 'B1')); => cannot install textpatch
			Exit
		EndIf
		_Process_ChangeDir($g_BG2Dir, 1)
	EndIf
; ---------------------------------------------------------------------------------------------
; install the Russian textpatch if needed
; ---------------------------------------------------------------------------------------------
	If $g_MLang[1] = 'RU' And Not StringInStr(FileRead($g_BG1Dir&'\WeiDU.log'), @LF&'~bg1textpack/setup-bg1textpack.tp2') And $g_BG1Dir <> '-' Then; first installation
		GUICtrlSetData($g_UI_Static[6][2], _GetTR($p_Message, 'L4')); => install textpatch
		_Process_ChangeDir($g_BG1Dir, 1)
		FileCopy($g_BG1Dir&'\dialog.tlk', $g_BG1Dir&'\dialogf.tlk', 1)
		_Process_Run('setup-bg1textpack.exe --no-exit-pause --noautoupdate --language 0 --skip-at-view --force-install-list 1', 'setup-bg1textpack.exe')
		If Not StringInStr(FileRead($g_BG1Dir&'\WeiDU.log'), @LF&'~bg1textpack/setup-bg1textpack.tp2') Then
			_Misc_MsgGUI(4, _GetTR($p_Message, 'T1'), _GetTR($p_Message, 'L1'), 1, _GetTR($p_Message, 'B1')); => cannot install bg1textpack
			Exit
		EndIf
		_Process_ChangeDir($g_BG2Dir, 1)
	EndIf
EndFunc   ;==>_Install_BG1Textpatch

; ---------------------------------------------------------------------------------------------
; Get the answers to questions of a mod by its setup-name
; ---------------------------------------------------------------------------------------------
Func _Install_BuildSubcmd($p_Setup, $p_Comp)
	$Components=IniRead($g_UsrIni, 'Current', $p_Setup, $p_Comp)
	If Not StringRegExp($Components, '(\A|\s)'&$p_Comp&'\x3f') Then Return 0 ; expect p_Comp without ?#_ans part
	If $p_Setup = 'BG2_Tweaks' Or $p_Setup = 'cdtweaks' Then
		If StringInStr($Components, '3183?') And StringInStr($Components, '3183?3_b') Then ; RomanceCheats: Remove Nothing kills romances? - selection if "Allow multiple romances" was not selected before.
			$Components=StringRegExpReplace($Components, '3183\x3f4_\D\s', '')
		EndIf
	EndIf
	If $p_Setup = 'level1npcs' Then
		$Test=IniRead($g_UsrIni, 'Current', 'Divine_Remix', '200')
		If StringInStr($Components, '1?') And StringInStr($Test, '200') Then ; Remove "Restrict fighter/druids from armors single class druids cannot wear?" if Druid Remix will be installed.
			$Components=StringRegExpReplace($Components, '1\x3f3_\d\s', '')
		EndIf
	EndIf
	If $p_Setup = '1pp' Then
		If StringInStr($Components, '400?') And Not StringInStr($Components, '206') Then ; Remove Shields Appearance if Additional Shield Animations was not selected before.
			$Components=StringRegExpReplace($Components, '400\x3f3_\d\s', '')
			$Components=StringRegExpReplace($Components, '400\x3f4_\d\s', '')
		EndIf
		If StringInStr($Components, '400?') And Not StringInStr($Components, '208') Then ; Remove Helmets Appearance if Additional Helmet Animations was not selected before.
			$Components=StringRegExpReplace($Components, '400\x3f5_\d\s', '')
			$Components=StringRegExpReplace($Components, '400\x3f6_\d\s', '')
			$Components=StringRegExpReplace($Components, '400\x3f7_\d\s', '')
		EndIf
	EndIf
	If $p_Setup = 'klatu' Then
		If StringInStr($Components, '2090?') And Not StringInStr($Components, '2090?1_2') Then ; Remove Enter a number if Allow divine casting was not selected before.
			$Components=StringRegExpReplace($Components, '2090\x3f2_\d\s', '')
		EndIf
		If StringInStr($Components, '2090?') And Not StringInStr($Components, '2090?3_2') Then ; Remove Enter a number if Allow arcane casting was not selected before.
			$Components=StringRegExpReplace($Components, '2090\x3f4_\d\s', '')
		EndIf
	EndIf
	$Components=_SplitComp($Components)
	$Handle=FileOpen($g_GameDir&'\BWS_Sub.nul', 2)
	For $c=1 to $Components[0]
		If StringInStr($Components[$c], $p_Comp&'?') Then
			$UserEditedValue = IniRead($g_UsrIni, 'Edit', $p_Setup&';'&$Components[$c], '')
			If $UserEditedValue <> '' Then
				FileWriteLine($Handle, $UserEditedValue)
			Else
				FileWriteLine($Handle, StringRegExpReplace($Components[$c], '\A.*_', ''))
			EndIf
		EndIf
	Next
	FileClose($Handle)
	Return 1
EndFunc   ;==>_Install_BuildSubcmd

; ---------------------------------------------------------------------------------------------
; Check if the mod is installed, was selected and if it matches with the current dependencies and conflicts
; ---------------------------------------------------------------------------------------------
Func _Install_Check($p_Setup, $p_Logic, $p_Message='')
	If Not IsArray($p_Message) Then
		Local $Message = IniReadSection($g_TRAIni, 'In-Check')
	Else
		Local $Message = $p_Message
	EndIf

	If StringInStr($p_Setup[3], '?') Then Return 0; SUB-selections are applied while installing the component itself
	If Not StringRegExp(IniRead($g_UsrIni, 'Current', $p_Setup[2], ''), '(?i)(\A|\s)' & $p_Setup[3] & '(\s|\z)') Then; the user did not select the mods component. Note: Not checking for SUBs here.
		;_Process_SetConsoleLog('@@@ Skipping ' & _Tree_SetLength($p_Setup[3]) &': '& $p_Setup[8] & ' because it was not selected for this installation @@@')
		Return 0
	EndIf
	_Process_SetConsoleLog('### ' & _Tree_SetLength($p_Setup[3]) &': '& $p_Setup[8] & ' ###')
	If _Install_ReadWeiDU($p_Setup[2], $p_Setup[3]) = 1 Then
		_Process_SetConsoleLog(_GetTR($Message, 'L10')); => already installed
		Return 0
	EndIf

	_Depend_GetActiveConnections(0); fetch active connections
	$Dependent=_Depend_ListInstallUnsolved($p_Setup[2], $p_Setup[3]); get unsolved dependencies
	$Conflicts=_Depend_ListInstallConflicts($p_Setup[2], $p_Setup[3]); get conflicts
	If $Dependent = '' And $Conflicts = '' Then

	Else
		_Process_SetConsoleLog(_GetTR($Message, 'L2')); => something's hindering
		If $Dependent <> '' Then _Process_SetConsoleLog($Dependent)
		If $Conflicts <> '' Then _Process_SetConsoleLog($Conflicts)
		If $Dependent <> '' Then _Process_SetConsoleLog(_GetTR($Message, 'L3')); => required mod was removed
		If $Conflicts <> '' Then _Process_SetConsoleLog(_GetTR($Message, 'L4')); => mod has a conflict
		_Process_SetConsoleLog(_GetTR($Message, 'L5')); => this is an error
		If $p_Logic = '5' Then
			_Process_SetConsoleLog(_GetTR($Message, 'L1')); => skipping with autopilot
			Local $Dependent[2][2] = [[1, ''], [$p_Setup[2], $p_Setup[3]]]
			_Depend_RemoveFromCurrent($Dependent); remove component from installed items
			Return 0
		EndIf
		_Process_SetConsoleLog(_GetTR($Message, 'L6'), -1); => try to install it?
		_Process_Question('i|s|e', _GetTR($Message, 'L7'), _GetTR($Message, 'Q1'), 3, $g_Flags[18]); => install anyway/skip/exit?
		If $g_pQuestion = 'e' Then; exit
			Exit
		ElseIf $g_pQuestion = 's' Then; continue
			Local $Dependent[2][2] = [[1, ''], [$p_Setup[2], $p_Setup[3]]]
			_Depend_RemoveFromCurrent($Dependent); remove component from installed items
			Return 0
		EndIf
	EndIf
	If $p_Setup[6] <> '' Then; skip if requirements are not met
		If _Install_CheckCondition($p_Setup[6]) = 0 Then
			_Process_SetConsoleLog(_GetTR($Message, 'L8')); => request not met
			Return 0
		EndIf
	EndIf
	_Process_SetConsoleLog(_GetTR($Message, 'L9')); => ready for installation
	Return 1
EndFunc   ;==>_Install_Check

; ---------------------------------------------------------------------------------------------
; Check if the mod/cmd passes the install-condition. Syntax C/D:A(X)[&B(Y)]
; ---------------------------------------------------------------------------------------------
Func _Install_CheckCondition($p_String)
	$Array=StringSplit(StringTrimLeft($p_String, 2), '&')
	$Result=0
	For $a=1 to $Array[0]
		$Mod=StringRegExpReplace($Array[$a], '\x28.*\z', '')
		$Comp=StringRegExpReplace($Array[$a], '\A[^\x28]*\x28|\x29', '')
		$Test=_Install_ReadWeiDU($Mod, $Comp)
		If $Test<>0 Then $Result+=1
	Next
	If $Result = $Array[0] Then; all checks were passed
		$Result = 1
	Else
		$Result = 0
	EndIf
	If StringLeft($p_String, 1) = 'C' Then; invert the result because it's a conflict
		If $Result=0 Then
			Return 1
		Else
			Return 0
		EndIf
	EndIf
	Return $Result
EndFunc   ;==>_Install_CheckCondition

; ---------------------------------------------------------------------------------------------
; This will create a compressed log
; ---------------------------------------------------------------------------------------------
Func _Install_CompressLog()
	Dim $LastLine
	$File = $g_LogDir & '\BWS-Debug-Installation.log'
	$Handle = FileOpen($g_LogDir & '\BWS-Debug.log', 2)
	$Array=StringSplit(StringStripCR(FileRead($File)), @LF)
	For $a=1 to $Array[0]
		If _MathCheckDiv($a, 10000) Then GUICtrlSetData($g_UI_Interact[6][1], ($a/$Array[0])*80)
		If StringRegExp($Array[$a], '(?i)Tiles processed|% decoded|%]|\A(Tile|Pos:|\s?Oggdec|\sEncoder|\sSerial|\sBitstream|\sScale|\sDecoded|\sEncoded)\s') Then ContinueLoop; cmd itself
		If $LastLine = '' And $Array[$a] = '' Then ContinueLoop
		FileWriteLine($Handle, $Array[$a])
		$LastLine=$Array[$a]
	Next
	FileClose($Handle)
	$7za = $g_ProgDir & '\Tools\7z.exe'
	$Handle = Run('"' & $7za & '" a "' & $g_GameDir & '\BWS-Debug.7z" "' & $g_LogDir & '\BWS-Debug.log"', $g_ProgDir, @SW_HIDE, 8)
	Local $Return
	While 1
		$Return &= StdoutRead($Handle)
		If @error Then ExitLoop
	Wend
	If StringInStr($Return, 'Everything is Ok') Then
		GUICtrlSetData($g_UI_Interact[6][1], 100)
		GUICtrlSetData($g_UI_Static[6][2], '7z file created.')
	Else
		GUICtrlSetData($g_UI_Interact[6][1], 100)
		GUICtrlSetBkColor($g_UI_Static[6][2], 0xFF0000)
		GUICtrlSetData($g_UI_Static[6][2], 'Error while creating 7z file.')
	EndIf
EndFunc   ;==>_Install_CompressLog

; ---------------------------------------------------------------------------------------------
; This will create a dummy WeiDU-entry
; ---------------------------------------------------------------------------------------------
Func _Install_CreateTP2Entry($p_Setup, $p_Text, $p_Process=1, $p_File=''); $a=tp2-name; $b=component-name; $c=execute, $d=at_now-cmd
	Local $Handle=FileOpen($g_GameDir&'\Setup-'&$p_Setup&'.tp2', 2) ;overwrite
	Local $c=0
	If $Handle=-1 Then
		$Type=StringRegExpReplace($g_Flags[14], '(?i)BWS|BWP', 'BG2')
		_Misc_MsgGUI(4, _GetTR($g_UI_Message, '0-T1'), StringFormat(_GetTR($g_UI_Message, '8-L2'), $Type, @AutoItExe), 1, _GetTR($g_UI_Message, '8-B3')); => don't have write-permission -> exit
		Exit
	EndIf
	If Not FileExists($g_GameDir&'\WeiDU') Then DirCreate($g_GameDir&'\WeiDU')
	If Not FileExists($g_GameDir&'\WeiDU\BWP_Backup') Then DirCreate($g_GameDir&'\WeiDU\BWP_Backup')
	FileWriteLine($Handle, 'BACKUP ~WeiDU/bwp_backup~')
	FileWriteLine($Handle, 'AUTHOR ~dummy@mail.de~')
	If $p_Setup = 'BWS' Then
		; remove ANYONE from EA.IDS to work around script compilation errors with WeiDU 238 and earlier
		FileWriteLine($Handle, 'ALWAYS')
		FileWriteLine($Handle, '  COPY_EXISTING ~EA.IDS~ ~override~')
		FileWriteLine($Handle, '    REPLACE_TEXTUALLY ~0[ %TAB%]+ANYONE~ ~~')
		FileWriteLine($Handle, '  BUT_ONLY')
		FileWriteLine($Handle, 'END')
		If $g_Compilation = 'E' Then
			FileWriteLine($Handle, 'BEGIN "Expert Click-Properties Selected"')
			$c += 1
		EndIf
		$c += _Depend_LogToWeiDU($Handle)
		Local $LoggedMods = ''
		For $w = $g_CentralArray[0][1] To $g_CentralArray[0][0]
			If GUICtrlRead($w) = 0 Then ContinueLoop; not sure why we need this
			If $g_CentralArray[$w][9] = 0 Then ContinueLoop; skip not selected
			If $g_CentralArray[$w][2] = '-' Then; this is a mod headline
				If StringInStr($g_CentralArray[$w][11], 'E') And Not StringRegExp($g_CentralArray[$w][11], '[FRST]') Then
					; Only add mod once even if it appears in multiple theme sections
					If Not StringInStr($LoggedMods, '|'&$g_CentralArray[$w][0]&'|') Then
						$LoggedMods &= '|'&$g_CentralArray[$w][0]&'|'; remember this line
						FileWriteLine($Handle, 'BEGIN ~Expert Mod In Selection: '&$g_CentralArray[$w][0]&'~')
						$c += 1
					EndIf
				EndIf
			ElseIf StringInStr($LoggedMods, '|'&$g_CentralArray[$w][0]&'|') Then
				ContinueLoop; we already logged the mod headline, so skip its components
			ElseIf $g_CentralArray[$w][12] = '0001' Then; this is an Expert pre-selection-only component
				FileWriteLine($Handle, 'BEGIN ~Expert Component In Selection: '&$g_CentralArray[$w][0]&'('&$g_CentralArray[$w][2]&')~')
				$c += 1
			EndIf
		Next
		FileClose($Handle)
		Local $BWS_ver = 'BWS-Version.txt not found, '
		$Handle = FileOpen($g_BaseDir & '\BWS-Version.txt', 1); read-only
		If Not @error Then
			$BWS_ver = StringStripWS(StringLeft(FileReadLine($Handle),7),8)
			If UBound($BWS_ver) Then $BWS_ver = 'BWS version ' & $BWS_ver & ', '
			FileClose($Handle)
		EndIf
		RunWait(@ComSpec&' /c echo BEGIN ~'&$p_Text&' ('&$BWS_ver&'installation started %DATE%)~ >> Setup-BWS.tp2', $g_gameDir, @SW_HIDE)
	Else ;important assumption -- Setup-BWS.tp2 will never have $p_File <> '' -- if it does, this function needs rewrite
		FileWriteLine($Handle, 'BEGIN "'&$p_Text&'"')
		If $p_File <> '' Then FileWriteLine($Handle, 'AT_NOW ~'&$p_File&'~'); execute this windows-command
		FileClose($Handle)
	EndIf
	If Not FileExists($g_GameDir&'\WeiDU.log') Then FileClose(FileOpen($g_GameDir&'\WeiDU.log', 2))
	Local $Components = '0'
	For $x = 1 To $c
		$Components &= ' '&$x
	Next
	If $p_Process = 1 Then _Process_Run('WeiDU.exe "Setup-'&$p_Setup&'.tp2" --game "." --language 0 --force-install-list '&$Components&' '&$g_WeiDUQuickLog&' --log "Setup-'&$p_Setup&'.Debug"', 'WeiDU.exe')
EndFunc   ;==>_Install_CreateTP2Entry

; ---------------------------------------------------------------------------------------------
; Get BG1EE/BG2EE-translation-setting
; ---------------------------------------------------------------------------------------------
Func _Install_GetEELang($p_String='', $p_Version=1)
	If $p_String='' Then IniRead($g_TRAIni, 'IN-Au3PrepInst', 'L4', '')
	Local $Lang='en_US', $MyIni=@MyDocumentsDir&"\Baldur's Gate - Enhanced Edition\Baldur.lua"
	If $p_Version=2 Then $MyIni=@MyDocumentsDir&"\Baldur's Gate II - Enhanced Edition\Baldur.lua"
	If $p_Version=3 Then $MyIni=@MyDocumentsDir&"\IceWind Dale - Enhanced Edition\Baldur.ini"
	If $p_Version=4 Then $MyIni=@MyDocumentsDir&"\Planescape Torment - Enhanced Edition\Baldur.lua"
	If FileExists($MyIni) Then
		$Array=StringSplit(StringStripCR(FileRead($MyIni)), @LF)
		For $a=1 to $Array[0]
			If StringInStr($Array[$a], 'Language') Then; search for language-definition
				$Test=StringRegExp($Array[$a], '\D\D_\D\D', 3); should be xx_XX
				If IsArray($Test) Then $Lang=$Test[0]
				ExitLoop
			EndIf
		Next
	Else; no lua found -> game not started
		_Misc_MsgGUI(4, $g_ProgName, $p_String); => start the game and choose a language
		Exit
	EndIf
	Return $Lang
EndFunc   ;==>_Install_GetBGEELang

; ---------------------------------------------------------------------------------------------
; Get existing BG1EE/BG2EE-language-directory
; ---------------------------------------------------------------------------------------------
Func _Install_GetEELangDir($Lang)
		;_PrintDebug('$g_GameDir '& $g_GameDir, 1)
		;_PrintDebug('Inistial $Lang passed value '&$Lang, 1)
		If FileExists($g_GameDir&'\WeiDu.conf') Then
			Local $weiduConfLangArray = StringSplit(StringStripCR(FileRead($g_gameDir & '\WeiDu.conf')), " = ",3)
			Local $weiduConfLang = $weiduConfLangArray[1]
			;_PrintDebug('weiduConfLang '&$weiduConfLang, 1)
		EndIf
		;Local $langDirArray = _FileListToArrayRec($g_GameDir&'\lang', "*");, $FLTAR_FOLDERS, $FLTAR_NORECUR, $FLTAR_SORT, $FLTAR_NOPATH)
		Local $langDirArray = _FileListToArrayEx($g_GameDir&'\lang', '*') ; function flag (2) is bugged when using with BWS autoit.exe :(
		;_ArrayDisplay($langDirArray, "$langDirArray")
		;_PrintDebug('$langDirArray[0] '& $langDirArray[0], 1)
		Local $bFound = False
		For $i = 0 To UBound($langDirArray) -1
			If StringInStr($Lang, $langDirArray[$i]) Then
				$bFound = True
				;ConsoleWrite ( $langDirArray[$i] )
				;_PrintDebug('langDirArray[$i] '& $langDirArray[$i], 1)
				ExitLoop
			EndIf
		Next
		If $bFound = True  Then
			$langDirName = $Lang
		;_PrintDebug('langDirName found '&$langDirName, 1)
		else
			;_PrintDebug('$Lang not found '&$Lang, 1)
			$langDirName = 'en_US'
			;_PrintDebug('langDirName switched to en_US '&$langDirName, 1)
		endif
		Return $langDirName
EndFunc   ;==>_Install_GetEELangDir

; ---------------------------------------------------------------------------------------------
; Returns the number of the selected GUI-theme
; ---------------------------------------------------------------------------------------------
Func _Install_GetGUICompNumber($p_Num)
	Local $Ini
	$Language=StringTrimLeft(_GetTra('GUI', 'S'), 3)
	$Translation=_GetTra('GUI', $p_Num)
	$Translation=StringRegExpReplace($Translation, '\A.*\s?->\s?', '')
	$Array=StringSplit(StringStripCR(FileRead($g_BG2Dir&'\Setup-GUI.tp2')), @LF)
	$Num = -1
	For $a=1 to $Array[0]
		If StringRegExp($Array[$a], '\ALANGUAGE') Then $Num+=1
		If $Num = $Language Then
			$Ini=StringReplace(StringRegExpReplace($Array[$a+2], '\A[^~]*~|~[^~]*\z', ''), '/', '\')
			$Ini=StringSplit(StringStripCR(FileRead($g_BG2Dir&'\'&$Ini)), @LF)
			$Num+=1
		EndIf
		If $Ini <> '' And StringInStr ($Array[$a], '@') Then
			$String=''
			$Pos=StringInStr($Array[$a], '@')
			$Line=StringSplit($Array[$a], '')
			For $l=$Pos+1 To $Line[0]
				If StringRegExp($Line[$l], '\D') Then ExitLoop
				$String&=$Line[$l]
			Next
			For $i=1 to $Ini[0]
				If StringRegExp($Ini[$i], '\A@'&$String) Then
					$Array[$a]=StringReplace($Array[$a], '@'&$String, StringRegExpReplace($Ini[$i], '\A[^~]*~|~[^~]*\z', ''))
					ExitLoop
				EndIf
			Next
		EndIf
	Next
	$Num = -1
	For $a=1 to $Array[0]
		If StringRegExp($Array[$a], '\ABEGIN') Then $Num+=1
		If StringInStr($Array[$a], $Translation) Then Return $Num
		If $a = $Array[0] Then Return -1
	Next
EndFunc   ;==>_Install_GetGUICompNumber

; ---------------------------------------------------------------------------------------------
; Move current debug so it does not bother the current install or merge after a successful one
; ---------------------------------------------------------------------------------------------
Func _Install_ManageDebug($p_Setup, $p_Num)
	If $p_Num = 1 And FileExists($g_GameDir&'\Setup-'&$p_Setup&'.debug') Then; move the old log so no unused data is parsed
		$Text=FileRead($g_GameDir&'\Setup-'&$p_Setup&'.debug')
		$Handle=FileOpen($g_GameDir&'\Setup-'&$p_Setup&'.debug_old', 1)
		FileWrite($Handle, @CRLF& $Text)
		FileClose($Handle)
		FileDelete($g_GameDir&'\Setup-'&$p_Setup&'.debug')
	EndIf
	If $p_Num = 2 And FileExists($g_GameDir&'\Setup-'&$p_Setup&'.debug_old') Then; append the new data to an old log so data is merged again
		$Text=FileRead($g_GameDir&'\Setup-'&$p_Setup&'.debug')
		$Handle=FileOpen($g_GameDir&'\Setup-'&$p_Setup&'.debug_old', 1)
		FileWrite($Handle, @CRLF& $Text)
		FileClose($Handle)
		FileMove($g_GameDir&'\Setup-'&$p_Setup&'.debug_old', $g_GameDir&'\Setup-'&$p_Setup&'.debug', 1)
	EndIf
EndFunc   ;==>_Install_ManageDebug

; ---------------------------------------------------------------------------------------------
; Modifies the list of installation-commands so that it installs components as groups and not one by one
; ---------------------------------------------------------------------------------------------
Func _Install_ModifyForGroupInstall($p_Array, $p_Debug=0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Install_ModifyForGroupInstall')
	Local $NArray[$p_Array[0]*2] ; allow for the maximum case possibility that every 2 lines in InstallOrder.ini will become 4 lines (GRP;Start before and GRP;Stop after every 2 components of a unique mod-setup)
	Local $n=0, $Open=0, $OldMod
	Local $EndGroupInstall=StringRegExpReplace(IniRead($g_GConfDir&'\Game.ini', 'Options', 'EndGroupInstall', ''), ',|&', '|')
	For $a = 1 To $p_Array[0]
		If StringRegExp($p_Array[$a], '\A(\s.*\z|\z)') Then ContinueLoop; skip empty lines
		If StringRegExp($p_Array[$a], '(?i)\A(DWN|ANN|GRP)') Then ContinueLoop
		$Split=StringSplit($p_Array[$a], ';')
		$Mod=$Split[2]; SetupName
		$Comp=''
		$n+=1
		If StringRegExp($p_Array[$a], '(?i)\ACMD') Then
			If $Open Then
				$NArray[$n]='GRP;Stop'
				$Open=0
				$n+=1
			EndIf
			$NArray[$n]=$p_Array[$a]
			ContinueLoop
		ElseIf $Open And $Mod <> $OldMod Then
			$NArray[$n]='GRP;Stop'
			$Open=0
			$n+=1
			; and fall through to continue processing this line
		ElseIf $Open And StringRegExp($EndGroupInstall, '(?i)(\A|\x7c)'&$Mod&'\x28') Then; if we are in the middle of a group and this mod is in the "end group install" section of Game.ini
			$Comp=StringRegExpReplace($Split[3], '\x3f.*\z', ''); CompNumber, without sub-component _??? if any
			If StringRegExp($EndGroupInstall, '(?i)'&$Mod&'\x28[^\x29]*'&$Comp&'(\x29|\x26|x7c)') Then; if the current component is also in the "end group install" section, end current group
				$NArray[$n]='GRP;Stop'
				$Open=0
				$n+=1
			EndIf
			; and fall through to continue processing this line
		EndIf
		If StringRegExp($p_Array[$a], '(?i)\ASUB') Then; look if subs are going to be installed because using pipes will break stuff
			$Comp=StringRegExpReplace($Split[3], '\x3f.*\z', ''); CompNumber, without sub-component _??? if any
			If _Install_BuildSubcmd($Mod, $Comp) = 1 Then; if SUB is installed, stop and continue
				If $Open Then
					$NArray[$n]='GRP;Stop'
					$Open=0
					$n+=1
				EndIf
			EndIf
			$NArray[$n]=$p_Array[$a]
			While StringRegExp($p_Array[$a+1], ';'&$Comp&'\x3f')
				$a+=1
				$n+=1
				$NArray[$n]=$p_Array[$a]
			WEnd
		Else
			$Split=StringSplit($p_Array[$a+1], ';')
			If $Open = 0 And $Mod=$Split[2] Then ; Only open a group if setup lasts longer then 2 components
				$NArray[$n]='GRP;Start'
				$Open=1
				$n+=1
			EndIf
			$NArray[$n]=$p_Array[$a]
		EndIf
		$OldMod=$Mod
	Next
	If $Open Then ; we reached the end of the InstallOrder.ini and still have an open GRP;Start ... so add a final GRP;Stop
		$NArray[$n]='GRP;Stop'
		$Open=0
		; don't increment n here: this is the final line
	EndIf
	$NArray[0] = $n
	ReDim $NArray[$n+1]
	If $p_Debug = 1 Then
		For $a = 1 To $NArray[0]
			If StringRegExp($NArray[$a], '\AGRP;Start') Then
				_Process_SetConsoleLog('+')
				$Open=1
			ElseIf StringRegExp($NArray[$a], '\AGRP;Stop') Then
				_Process_SetConsoleLog('!')
				$Open=0
			ElseIf $Open = 1 Then
				_Process_SetConsoleLog('<')
			Else
				_Process_SetConsoleLog(' ')
			EndIf
			_Process_SetConsoleLog($NArray[$a])
		Next
		_PrintDebug('_Install_ModifyForGroupInstall finished - check Big World Setup\Logs\BWS-Debug.log',1)
		Exit
	EndIf
	Return $NArray
EndFunc   ;==>_Install_ModifyForGroupInstall

; ---------------------------------------------------------------------------------------------
; Check if patching would be working
; ---------------------------------------------------------------------------------------------
Func _Install_PatchTest()
	Local $Return = 0
	_Install_CreateTP2Entry('Patchtest', 'This is a failure.', 0)
	$Handle=FileOpen($g_GameDir&'\Setup-Patchtest.patch', 2)
	FileWriteLine($Handle, '--- Setup-Patchtest.tp2	Sun Mar 03 22:27:46 2013')
	FileWriteLine($Handle, '+++ Setup-Patchtest.tp2	Sun Mar 03 22:27:09 2013')
	FileWriteLine($Handle, '@@ -1,3 +1,3 @@')
	FileWriteLine($Handle, ' BACKUP ~WeiDU/bwp_backup~')
	FileWriteLine($Handle, ' AUTHOR ~dummy@mail.de~')
	FileWriteLine($Handle, '-BEGIN "This is a failure."')
	FileWriteLine($Handle, '+BEGIN "This is a success."')
	FileClose($Handle)
	$PID=Run('"'&$g_GameDir&'\Big World Fixpack\_utils\patch.exe" -p0 --no-backup-if-mismatch --ignore-whitespace  "'&$g_GameDir&'\Setup-Patchtest.tp2'&'" "'&$g_GameDir&'\Setup-Patchtest.patch"', $g_GameDir, @SW_HIDE)
	$Test=ProcessWaitClose($PID, 10)
	If $Test=1 And StringInStr(FileRead($g_GameDir&'\Setup-Patchtest.patch'), 'success') Then $Return=1
	FileDelete($g_GameDir&'\Setup-Patchtest.tp2')
	FileDelete($g_GameDir&'\Setup-Patchtest.patch')
	Return $Return
EndFunc   ;==>_Install_PatchTest

; ---------------------------------------------------------------------------------------------
; Adds default IDS-entries to your override-IDS-files if they are missing
; ---------------------------------------------------------------------------------------------
Func _Install_RepairIDS()
	Local $ID[5]=[4, 'Action', 'Animate', 'Stats', 'Kit'], $Ref
	For $i=1 to $ID[0]
		If FileExists ($g_BG2Dir&'\override\'&$ID[$i]&'.ids') Then
			$Override=StringSplit(StringStripCR(FileRead($g_BG2Dir&'\override\'&$ID[$i]&'.ids')), @LF)
			$Ref=StringSplit(StringStripCR(FileRead($g_BG2Dir&'\Big World Fixpack\_IDS_ref\'&$ID[$i]&'.ids')), @LF)
			$Append=''
			For $o=1 to $Override[0]
				$Override[$o]=StringStripWS($Override[$o], 3)
			Next
			For $r=1 to $Ref[0]
				$Ref[$r]=StringStripWS($Ref[$r], 3)
			Next
			For $r=1 to $Ref[0]
				$Found=0
				For $o=1 to $Override[0]
					If $Override[$o]=$Ref[$r] Then
						$Found=1
						ExitLoop
					EndIf
				Next
				If $Found = 0 Then $Append&=$Ref[$r]&@CRLF
			Next
			If $Append Then
				$Handle=FileOpen($g_BG2Dir&'\override\'&$ID[$i]&'.ids', 1)
				If $Override[$Override[0]] <> '' Then FileWrite($Handle, @CRLF)
				FileWrite($Handle, $Append)
				FileClose($Handle)
			EndIf
		EndIf
	Next
EndFunc    ;==>_Install_RepairIDS

; ---------------------------------------------------------------------------------------------
; Slightly adjust the translation for important installation-keywords located in prompt.tra
; Affected mods: BGT, BGTTweaks, dsotsc, impasylum, refinements, rttkit
; 'Installing', 'SKIPPING:', 'WARNING:', 'ERROR:', 'Saving This Log:', 'WeiDU Timings', 'SUCCESSFULLY INSTALLED', 'INSTALLED WITH WARNINGS', 'INSTALLED DUE TO ERRORS'
; @-1016         @-1020       --          --        --                  --              1019                       1033                       1032
; ---------------------------------------------------------------------------------------------
Func _Install_SetPrompt($p_TP2, $p_Num)
	Local $Num=-1, $Prompt=''
	$Array = StringSplit(StringStripCR(FileRead($p_TP2)), @LF)
	For $a=1 to $Array[0]
		If StringRegExp($Array[$a], '(?i)\A\s{0,}LANGUAGE') Then
			$Num+=1
			If $Num<>$p_Num Then ContinueLoop
			$Language=StringSplit($Array[$a], '~')
			If $Language[0] > 3 Then
				For $l=1 to $Language[0]
					If StringRegExp($Language[$l], '\x2f|\x5c') Then
						$Folder=$g_GameDir&'\'&StringReplace(StringRegExpReplace($Language[$l], '\A\s{0,}~|/[^/]*\z', ''), '/', '\')
						If StringInStr($Array[$a], 'prompt') Then; also look for items that contain the word prompt
							$Prompt=$g_GameDir&'\'&StringReplace(StringRegExpReplace(StringReplace($Language[$l], '%WEIDU_OS%', 'win32'), '\A\s{0,}~|~\z', ''), '/', '\')
							If FileExists($Prompt) Then ExitLoop 2
						EndIf
						$Prompt=$Folder&'\Prompts.tra'
						If FileExists($Prompt) Then ExitLoop 2
						$Prompt = ''
					EndIf
				Next
			Else
				If $a = $Array[0] Then
					_PrintDebug('Error 1: _Install_SetPrompt unexpectedly reached end of file '&$p_TP2, 1)
					Exit
				EndIf
				While StringRegExp($Array[$a+1], '(?i)\A\s{0,}LANGUAGE') = 0
					$a+=1
					If $a > $Array[0] Then
						_PrintDebug('Error 2: _Install_SetPrompt unexpectedly reached the end of file '&$p_TP2&' without finding a line starting with the BEGIN keyword', 1)
						Exit
					EndIf
					If StringRegExp($Array[$a], '(?i)\A\s{0,}BEGIN') Then Return 1
					If StringRegExp($Array[$a], '\x2f|\x5c') Then
						$Folder=$g_GameDir&'\'&StringReplace(StringRegExpReplace($Array[$a], '\A\s{0,}~|/[^/]*\z', ''), '/', '\')
						If StringInStr($Array[$a], 'prompt') Then; also look for items that contain the word prompt
							$Prompt=$g_GameDir&'\'&StringReplace(StringRegExpReplace(StringReplace($Array[$a], '%WEIDU_OS%', 'win32'), '\A\s{0,}~|~\z', ''), '/', '\')
							If FileExists($Prompt) Then ExitLoop 2
						EndIf
						$Prompt=$Folder&'\Prompts.tra'
						If FileExists($Prompt) Then ExitLoop 2
						$Prompt = ''
					EndIf
				WEnd
			EndIf
		EndIf
		If StringRegExp($Array[$a], '(?i)\A\s{0,}BEGIN') Then ExitLoop
	Next
	If $Prompt = '' Then Return 1
	$Array = StringSplit(StringStripCR(FileRead($Prompt)), @LF)
	$Handle=FileOpen($Prompt&'_new', 2)
	For $a=1 to $Array[0]
		If StringRegExp($Array[$a], '@-10(16|19|20|32|33)') And Not StringRegExp($Array[$a], '\A\s{0,}\x2f{2}\s') Then $Array[$a]='// ' & $Array[$a]
		FileWriteLine($Handle, $Array[$a])
	Next
	FileClose($Handle)
	If FileGetSize($Prompt&'_new') > 0 Then
		FileMove($Prompt&'_new', $Prompt, 1)
		Return 1
	Else
		Return 0
	EndIf
EndFunc   ;==>_Install_SetPrompt

; ---------------------------------------------------------------------------------------------
; Test the results & work on errors & warnings
; ---------------------------------------------------------------------------------------------
Func _Install_TestInstalled($p_Setup, $p_DebugTest, $p_Logic, $p_Num, $p_Message='')
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Install_TestInstalled')
	If Not IsArray($p_Message) Then
		Local $Message = IniReadSection($g_TRAIni, 'In-Test')
	Else
		Local $Message = $p_Message
	EndIf
	$WeiDUTest=_Install_ReadWeiDU($p_Setup[2], $p_Setup[3]); do the testing, warnings and stuff there
	If $p_Num > $p_DebugTest[0][0] Then
		ReDim $p_DebugTest[$p_Num+1][3]
		$p_DebugTest[$p_Num][0] = 0
	EndIf
	If $p_DebugTest[$p_Num][0] = 3 Then
		$DebugLines=$p_DebugTest[$p_Num][2]
	Else
		$DebugLines=$p_DebugTest[$p_Num][1]
	EndIf
	ConsoleWrite('WeiDUTest:  ' & $WeiDUTest & @CRLF); Debug
	ConsoleWrite('DebugTest:  ' &$p_DebugTest[$p_Num][0] & @CRLF); Debug
	ConsoleWrite('DebugLines: ' & $DebugLines & @CRLF); Debug
	If $p_DebugTest[0][1] = 'Log not found' Then
		_Misc_MsgGUI(4, _GetTR($g_UI_Message, '0-T1'), _GetTR($g_UI_Message, '6-L7')&'|'& StringFormat(StringRegExpReplace(_GetTR($g_UI_Message, '8-L2'), '\A[^\x7c]*\x7c', ''), @AutoItExe), 1, _GetTR($g_UI_Message, '8-B3')); => cannot read log -> exit
		Exit
	EndIf
	If ($WeiDUTest = 1 And $p_DebugTest[$p_Num][0] = 1) Or ($WeiDUTest = 0 And ($p_DebugTest[$p_Num][0] = 2 OR  $p_DebugTest[$p_Num][0] = 3)) Then; show output
		$DebugLines=StringSplit($DebugLines, '|')
		For $t=1 To $DebugLines[0]
			_Process_SetConsoleLog($DebugLines[$t])
		Next
	EndIf
	If $WeiDUTest = 1 And $p_DebugTest[$p_Num][0] = 0 Then; success
		_Process_SetConsoleLog($p_Setup[8] & ' (' & $p_Setup[7]&') ' & _GetTR($Message, 'L1')); => installed
	ElseIf $WeiDUTest = 1 And $p_DebugTest[$p_Num][0] = 1 Then; warnings
		_Process_SetConsoleLog($p_Setup[8] & ' (' & $p_Setup[7]&') ' & _GetTR($Message, 'L2')); => installed with warnings
		If $p_Logic = 4 Then
			_Process_SetConsoleLog('|'&_GetTR($Message, 'L7'), -1); => you may want to analyse if the warning is severe...
			_Process_Question('c|e', _GetTR($Message, 'L8'), _GetTR($Message, 'Q2'), 2, $g_Flags[18]); => continue/exit
			If $g_pQuestion = 'e' Then Exit
		EndIf
	ElseIf $WeiDUTest = 0 And $p_DebugTest[$p_Num][0] = 2 Then; skipping
		_Process_SetConsoleLog($p_Setup[8] & ' (' & $p_Setup[7]&') ' & _GetTR($Message, 'L3')); => was skipped
		If StringRegExp($p_Logic, '1|3|4') Then
			_Process_SetConsoleLog('|'&_GetTR($Message, 'L12'), -1); => normally this is harmless...
			_Process_Question('c|e', _GetTR($Message, 'L8'), _GetTR($Message, 'Q2'), 2, $g_Flags[18]); => continue/exit
			If $g_pQuestion = 'e' Then Exit
		EndIf
		Local $Dependent[2][2] = [[1, ''], [$p_Setup[2], $p_Setup[3]]]
		_Depend_RemoveFromCurrent($Dependent); remove component from installed items
	ElseIf $WeiDUTest = 0 And $p_DebugTest[$p_Num][0] = 3 Then; error
		_Process_SetConsoleLog($p_Setup[8] & ' (' & $p_Setup[7]&') ' & _GetTR($Message, 'L4')); => not installed due to errors
		If StringRegExp($g_fLock, '(?i)(\A|\x2c)'&$p_Setup[2]&'(\z|\x2c)') Then; error of fixed mod >> be cautious
			_Process_SetConsoleLog('|'&_GetTR($Message, 'L9'), -1); => you _HAVE_ to fix it!
			_Process_Question('r|e', _GetTR($Message, 'L10'), _GetTR($Message, 'Q3'), 2, $g_Flags[18]); => retry/exit
			If $g_pQuestion = 'e' Then
				Exit
			Else
				Return 1; decrease number for retry
			EndIf
		Else
			$Dependent=_Depend_GetUnsolved('', '')
			If $Dependent[0][1] <> '' Then; don't show empty messages
				_Process_SetConsoleLog(_GetTR($Message, 'L11')); => show dependent mods
				_Process_SetConsoleLog($Dependent[0][1])
			EndIf
			If StringRegExp($p_Logic, '1|2|4') Then; errors should be displayed
				_Process_SetConsoleLog('|'&_GetTR($Message, 'L5'), -1); => want to fix it?
				_Process_Question('r|c|e', _GetTR($Message, 'L6'), _GetTR($Message, 'Q1'), 3, $g_Flags[18]); => retry/continue/exit
				If $g_pQuestion = 'e' Then
					Exit
				ElseIf $g_pQuestion = 'r' Then
					Return 1; decrease number for retry
				EndIf
			Else; user wants to remove all and continue
				$g_pQuestion = 'c'
			EndIf
			If $g_pQuestion = 'c' Then
				_Depend_RemoveFromCurrent($Dependent); remove depends
				Local $Dependent[2][2] = [[1, ''], [$p_Setup[2], $p_Setup[3]]]
				_Depend_RemoveFromCurrent($Dependent); remove component itself
			EndIf
		EndIf
	ElseIf $WeiDUTest = 0 And $p_DebugTest[$p_Num][0] = 2 Then
		ConsoleWrite('-Unknown' & @CRLF)
	EndIf
	If $p_DebugTest[$p_Num][0] = $p_DebugTest[0][0] Then _Process_SetConsoleLog(''); last line
	Return 0
EndFunc   ;==>_Install_TestInstalled

; ---------------------------------------------------------------------------------------------
; Returns the status of the requested components and the corresponding lines
; 0		= Number of components = current array dim	=
; 1-N	= Val for component 1  = possible warning	= possible error
; ---------------------------------------------------------------------------------------------
Func _Install_ReadDebug($p_Setup)
	Local $Return[100][3]
	$Return[0][1]=95
	If Not FileExists($g_GameDir&'\Setup-'&$p_Setup&'.debug') Then
		If Not FileExists($g_GameDir&'\debugs\Setup-'&$p_Setup&'.debug') Then
			Local $Return[2][3]=[[1, 'Log not found'],[0]]
			Return SetError(1, '', $Return)
		EndIf
	EndIf
	$Array = StringSplit(StringStripCR(FileRead($g_GameDir & '\Setup-'&$p_Setup&'.debug')), @LF)
	For $a = 1 To $Array[0]; collect messages to fetch skipping & warnings/errors
		If StringRegExp($Array[$a], '\A(E|I|S|W)') = 0 Then ContinueLoop
		If StringRegExp($Array[$a], '\AInstalling \x5b') Then
			$Return[0][0]+=1
		ElseIf StringRegExp($Array[$a], '\ASKIPPING: \x5b') Then
			$Return[0][0]+=1
			$Return[$Return[0][0]][0]=2
			$a+=1
			While StringRegExp($Array[$a], '\A\t\D')
				$Return[$Return[0][0]][1]&='|'&StringStripWS($Array[$a], 1)
				$a+=1
			WEnd
		ElseIf StringRegExp($Array[$a], '\AWARNING:\s') Then
			$Return[$Return[0][0]][1]&='|'&$Array[$a]
		ElseIf StringRegExp($Array[$a], '\AERROR:\s') Then
			$Return[$Return[0][0]][2 ]&='|'&$Array[$a]
		EndIf
		If $Return[0][0] = $Return[0][1] Then; expand array if it's nearly filled
			ReDim $Return[$Return[0][0]+50][3]
			$Return[0][1]+=50
		EndIf
	Next
; ---------------------------------------------------------------------------------------------
; Search for WeiDU's return value and assign the selected messages for that type of value
; ---------------------------------------------------------------------------------------------
	$Num=-1
	For $a = $Array[0] To 1 Step -1
		If $Num = 0 Or StringInStr($Array[$a], 'Saving This Log:') Then ExitLoop; exit after getting all $NUM-messages or when hitting the top of the summary
		If StringInStr($Array[$a], 'WeiDU Timings') Then $Num=$Return[0][0]; the timings are listed after component-summary. So now search for $NUM-messages
		If $Num <> -1 Then; searching the summary
			While $Return[$Num][0]=2; decrease the counter if the component was skipped
				$Num-=1
				If $Num = 0 Then ExitLoop; exit after getting all $NUM-messages
			WEnd
		EndIf
		If StringInStr($Array[$a], 'SUCCESSFULLY INSTALLED') Then
			$Return[$Num][0]=0
			$Num-=1
		ElseIf StringInStr($Array[$a], 'INSTALLED WITH WARNINGS') Then
			$Return[$Num][0]=1
			$Num-=1
		ElseIf StringInStr($Array[$a], 'NOT INSTALLED DUE TO ERRORS') Then
			$Return[$Num][0]=3
			$Num-=1
		EndIf
	Next
	ReDim $Return[$Return[0][0]+1][3]
	Return $Return
EndFunc   ;==>_Install_ReadDebug

; ---------------------------------------------------------------------------------------------
; Test if the component was installed
; ---------------------------------------------------------------------------------------------
Func _Install_ReadWeiDU($p_Setup, $p_Comp='*', $p_Lang='*')
	If $p_Lang = '*' Then $p_Lang = '.*'
	If $p_Comp = '*' Then $p_Comp = '.*'
	$Array = StringSplit(StringStripCR(FileRead($g_GameDir & '\WeiDU.log')), @LF)
	For $a = $Array[0] To 1 Step -1
		If StringRegExp($Array[$a], '(?i)\A~([^\x2f]{1,}\x2f|)(setup\x2d|)'&$p_Setup&'.tp2~\s#'&$p_Lang&'\s#'&$p_Comp) Then
			$Component = StringRegExpReplace($Array[$a], '\A.*\s//\s', '')
			Return SetError(0, '', 1)
			ExitLoop
		EndIf
	Next
	Return SetError(1, '', 0)
EndFunc   ;==>_Install_ReadWeiDU

; ---------------------------------------------------------------------------------------------
; Overwrite WeiDU-setup with a current one; prevent beta releases to be overwritten by stable releases
; ---------------------------------------------------------------------------------------------
Func _Install_UpdateWeiDU($p_File, $p_Size=0)
	If $p_Size = 0 Then $p_Size=FileGetSize($g_GameDir&'\WeiDU\WeiDU.exe')
	If $p_Size = 0 Then Return; do nothing if WeiDU.exe does not exist
	$Size=FileGetSize($g_GameDir&'\'&$p_File); get size of target WeiDU-setup exe for comparison
	If $Size <> $p_Size Then; create or replace the WeiDU-setup exe if it doesn't match reference size
		FileCopy($g_GameDir&'\WeiDU\WeiDU.exe', $g_GameDir&'\'&$p_File, 1)
	EndIf
EndFunc   ;==>_Install_UpdateWeiDU
