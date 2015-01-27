#include-once

; ---------------------------------------------------------------------------------------------
; Checks for the current Options and fills them if needed
; ---------------------------------------------------------------------------------------------
Func Au3Detect($p_Num = 0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling Au3Detect')
	Local $Lang = ''
	If IniRead($g_UsrIni, 'Options', 'AppLang', '') = '' Then; search only on first startup
		$g_ATNum = '1'
		If StringRegExp(@OSLang, '(?i)0407|0807|0c07|1007|1407') = '1' Then $g_ATNum = '2'; german OSLANG
		;If StringRegExp(@OSLang, '(?i)040a|080a|0c0a|100a|140a|180a|1c0a|200a|240a|280a|2c0a|300a|340a|380a|3c0a|400a|440a|480a|4c0a|500a') = '1' Then $g_ATNum = '3'; spanish OSLANG
		;If StringRegExp(@OSLang, '(?i)040c|080c|0c0c|100c|140c|180c') = '1' Then $g_ATNum = '4'; french OSLANG
		If StringRegExp(@OSLang, '(?i)0419') = '1' Then $g_ATNum = '3'; Russian OSLANG
		$Lang = IniRead($g_UsrIni, 'Options', 'AppLang', 'EN')
		IniWrite($g_UsrIni, 'Options', 'Download', $g_DownDir)
	Else
		$g_DownDir = IniRead($g_UsrIni, 'Options', 'Download', $g_DownDir)
		$Lang = IniRead($g_UsrIni, 'Options', 'AppLang', 'EN')
		For $a = 1 To $g_ATrans[0]
			If $g_ATrans[$a] = $Lang Then ExitLoop
		Next
		$g_ATNum = $a
	EndIf
	$g_TRAIni = $g_ProgDir & '\Config\Translation-'&$g_ATrans[$g_ATNum]&'.ini'
	$g_UI_Message = IniReadSection($g_TRAIni, 'UI-Runtime')
EndFunc   ;==>Au3Detect

; ---------------------------------------------------------------------------------------------
; Checks for the current Options and fills them if needed
; ---------------------------------------------------------------------------------------------
Func _Test_GetGamePath($p_Game, $p_Force=0)
	Local $Game[8][4]=[[7], ['BG1', 'BGMain', 'Baldur*', 'Config.exe'],['BG2', 'BG2Main', 'BGII*', 'BGConfig.exe'], ['IWD1', 'IDMain', 'Icewind Dale', 'IDMain.exe'], _
	['IWD2', 'IWD2', 'Icewind Dale II', 'IWD2.exe'], ['PST', 'Torment', 'Torment', 'Torment.exe'], ['BG1EE', 'BeamDog.BGEE', 'Baldur*', 'movies\mineflod.wbm'], _
	['BG2EE', 'BeamDog.BG2EE', 'Baldur*', 'movies\melissan.wbm']]
	For $g=1 to $Game[0][0]
		If $Game[$g][0] = $p_Game Then ExitLoop
	Next
	If $p_Force = 0 Then
		$Test=IniRead($g_UsrIni, 'Options', $p_Game, '')
		If ($p_Game = 'BG1' And $Test = '-') Or ($Test <> '' And FileExists($Test&'\'&$Game[$g][3])) Then
			Assign ('g_'&$p_Game&'Dir', $Test)
			Return $Test
		EndIf
	EndIf
	If StringInStr($p_Game, 'EE') Then
		$Test=''
		For $k= 1 to 1000
			$key = RegEnumKey("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall", $k)
			If @error <> 0 then ExitLoop
			$Name=RegRead('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\'&$Key, 'DisplayName')
			If $p_Game = 'BG1EE' And $Name <> "Baldur's Gate - Enhanced Edition" Then ContinueLoop
			If $p_Game = 'BG2EE' And $Name <> "Baldur's Gate II Enhanced Edition" Then ContinueLoop
			$Test=RegRead('HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\'&$Key, 'UninstallString')
			$Test=StringRegExpReplace($Test, '\A"|\\[^\\]*\z', '')
			If $p_Game = 'BG1EE' And FileExists($Test&'\Data\00766') Then $Test=$Test&'\Data\00766'; Maybe this works for Steam?
			If $p_Game = 'BG2EE' And FileExists($Test&'\Data\00783') Then $Test=$Test&'\Data\00783'; Maybe this works for Steam?
			ExitLoop
		Next
	Else
		$Test = RegRead('HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\'&$Game[$g][1]&'.exe', 'Path')
		$Test = StringRegExpReplace($Test, '(?i)\x5c{1,}\z', '')
	EndIf
	If $Test <> '' And FileExists($Test&'\'&$Game[$g][3]) Then
	ElseIf $p_Game = 'BG1EE' Then
		$Test=''
		$Files=_FileSearch(@ProgramFilesDir, "Baldur's Gate*Enhanced Edition")
		If $Files[0] <> 0 Then
			If FileExists(@ProgramFilesDir&'\'&$Files[1]&'\'&$Game[$g][3]) Then $Test = @ProgramFilesDir&'\'&$Files[1]; Steam-version
			If FileExists(@ProgramFilesDir&'\'&$Files[1]&'\Data\00766\'&$Game[$g][3]) Then $Test=@ProgramFilesDir&'\'&$Files[1]&'\Data\00766'; BeamDog-version
		EndIf
		If FileExists(@ProgramFilesDir&'\BeamDog\Data\00766\'&$Game[$g][3]) Then $Test=@ProgramFilesDir&'\BeamDog\Data\00766'; BeamDog-version (2. attempt)
	ElseIf $p_Game = 'BG2EE' Then
		$Test=''
		$Files=_FileSearch(@ProgramFilesDir, "Baldur's Gate II*Enhanced Edition")
		If $Files[0] <> 0 Then
			If FileExists(@ProgramFilesDir&'\'&$Files[1]&'\'&$Game[$g][3]) Then $Test = @ProgramFilesDir&'\'&$Files[1]; Steam-version
			If FileExists(@ProgramFilesDir&'\'&$Files[1]&'\Data\00783\'&$Game[$g][3]) Then $Test=@ProgramFilesDir&'\'&$Files[1]&'\Data\00783'; BeamDog-version
		EndIf
		If FileExists(@ProgramFilesDir&'\BeamDog\Data\00783\'&$Game[$g][3]) Then $Test=@ProgramFilesDir&'\BeamDog\Data\00783'; BeamDog-version (2. attempt)
	Else
		$Test=''
		$Files=_FileSearch(@ProgramFilesDir&'\Black Isle', $Game[$g][2])
		If $Files[0] <> 0 Then
			If FileExists(@ProgramFilesDir&'\Black Isle\'&$Files[1] &'\'&$Game[$g][3]) Then $Test = @ProgramFilesDir&'\Black Isle\'&$Files[1]
		EndIf
	EndIf
	If $Test <> '' Then
		IniWrite($g_UsrIni, 'Options', $p_Game, $Test)
		Assign ('g_'&$p_Game&'Dir', $Test)
		Return $Test
	Else
		$SearchDir = $g_BaseDir
		$Files=_FileSearch($SearchDir, '*')
		For $f=1 to $Files[0]
			If Not StringInStr(FileGetAttrib($SearchDir & '\' & $Files[$f]), 'D') Then ContinueLoop
			If StringInStr($Files[$f], 'BiG World Clean Install') Then ContinueLoop
			If FileExists($SearchDir & '\' & $Files[$f] & '\'&$Game[$g][3]) Then
				If FileExists($SearchDir & '\' & $Files[$f] &'\Data\00766') Then $Files[$f]=$Files[$f] &'\Data\00766'; BG1EE
				If FileExists($SearchDir & '\' & $Files[$f] &'\Data\00783') Then $Files[$f]=$Files[$f] &'\Data\00783'; BG2EE
				Assign ('g_'&$p_Game&'Dir', $SearchDir & '\' & $Files[$f])
				IniWrite($g_UsrIni, 'Options', $p_Game, $SearchDir & '\' & $Files[$f])
				Return $SearchDir & '\' & $Files[$f]
			EndIf
		Next
	EndIf
EndFunc   ;==>_Test_GetGamePath

; ---------------------------------------------------------------------------------------------
; Test current codepage <> modselection
; ---------------------------------------------------------------------------------------------
Func _Test_ACP()
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Test_ACP')
	If Not StringRegExp ($g_Flags[14], 'BWS|BWP') Then Return; mod was made for Baldurs Gate (ToB)
	$Test = RegRead('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Nls\CodePage', 'ACP')
	If $Test = '1252' Then Return; codepage fits
	If $g_MLang[1] = 'RU' And $Test = '1251' Then Return; IA is converted for Russian translation, so Cyrillic codepage also fits
	$Answer=_Misc_MsgGUI(1, _GetTR($g_UI_Message, '0-T1'), StringFormat(_GetTR($g_UI_Message, '2-L6'), $Test), 3, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2'), _GetTR($g_UI_Message, '0-B3')); => Hint / This may affect your programs
	If $Answer = 1 Then
		ShellExecute(IniRead($g_ModIni, 'infinityanimations', 'Link', 'http://www.spellholdstudios.net/ie/infinityanimations')); open the homepage if it is nursed
		_Test_ACP()
		Return 0
	ElseIf $Answer = 2 Then; remove the mod
		$g_Skip&='|infinityanimations|IAContent.*|Bear_Animations_D2|vecna|JA#BGT_AdvPack;1'
		Return 0
	ElseIf $Answer = 3 Then; install the mod
		IniWrite($g_UsrIni, 'Options', 'ACP', $Test)
		If $g_CentralArray[0][0] <> '' Then _Tree_GetCurrentSelection()
		$Test=RegWrite('HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Nls\CodePage', 'ACP', 'REG_SZ', '1252')
		If @error Then
			_Misc_MsgGUI(3, _GetTR($g_UI_Message, '0-T1'), _GetTR($g_UI_Message, '2-L7')); => Warning
		Else
			$Answer=_Misc_MsgGUI(1, _GetTR($g_UI_Message, '0-B3'), _GetTR($g_UI_Message, '2-L8'), 2, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2')); => Hint / Applied & need to reboot. Do it now? / yes/no
			If $Answer = 2 Then	Shutdown(2)
		EndIf
		Return 1
	EndIf
EndFunc    ;==>_Test_ACP

; ---------------------------------------------------------------------------------------------
; Checks if all needed files exists.
; ---------------------------------------------------------------------------------------------
Func _Test_ArchivesExist()
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Test_ArchivesExist')
	$g_LogFile = $g_LogDir & '\BiG World Checking Debug.txt'
	Local $Prefixes[3], $Fault = '', $Delete = 0
	Local $Message = IniReadSection($g_TRAIni, 'TE-ArchivesExist')
	GUICtrlSetData($g_UI_Interact[6][4], _GetSTR($Message, 'H1')); => help text
	AutoItSetOption('GUIOnEventMode', 1)
	FileClose(FileOpen($g_LogFile, 2))
	$g_Flags[0] = 1
	_Process_Gui_Create(1, 0)
	Local $List = _Tree_GetCurrentList()
	GUICtrlSetData($g_UI_Static[6][1], _GetTR($Message, 'L1')); => watch progress
	_Process_SetScrollLog(_GetTR($Message, 'L14'), 1, -1); => what to do with unused files
	_Process_Question('r|m|k|c', _GetTR($Message, 'L15'), _GetTR($Message, 'Q1'),  4); => remove/move/keep/close
	If $g_pQuestion = 'c' Then
		_Process_Gui_Delete(3, 3, 0)
		Return
	EndIf
	$Keep = $g_pQuestion
	$Prefixes[0] = ''
	$Prefixes[1] = 'Add'
	$Prefixes[2] = $g_ATrans[$g_ATNum] & '-Add'
	If Not FileExists($g_RemovedDir) Then DirCreate($g_RemovedDir); create the folders
	If Not FileExists($g_DownDir & '\Valid') Then DirCreate($g_DownDir & '\Valid')
	If Not FileExists($g_DownDir & '\Not Valid') Then DirCreate($g_DownDir & '\Not Valid')
	For $l = 1 To $List[0][0]; loop through
		GUICtrlSetData($g_UI_Interact[6][1], 100 * $l / $List[0][0])
		GUICtrlSetData($g_UI_Static[6][2], _GetTR($Message, 'L2') & ' ' & $List[$l][1] & ' ...'); => checking
		_Process_SetScrollLog(_GetTR($Message, 'L2') & ' ' & $List[$l][1]); => checking
		$ReadSection = IniReadSection($g_ModIni, $List[$l][0])
		$Prefixes[2] = _GetTra($ReadSection, 'T')&'-Add'; adjust the language-addon
		For $Prefix In $Prefixes; search for additional stuff, too
			If $g_Flags[0] = 0 Then
				_Process_Gui_Delete(3, 3, 1)
				Return
			EndIf
			$Save = _IniRead($ReadSection, $Prefix & 'Save', '')
			If $Save = '' And $Prefix = '' Then
				If _IniRead($ReadSection, $Prefixes[2] & 'Save', '') = '' Then; there's no language-stuff and we don't have a save? C'mon.
					$Fault = $Fault & '|' & $List[$l][1]
					_Process_SetScrollLog(_GetTR($Message, 'L11')); => faulty entry
					ContinueLoop
				Else
					ContinueLoop
				EndIf
			ElseIf $Save = '' And $Prefix <> '' Then; if no additonal stuff is found, skip forward
				ContinueLoop
			EndIf
			If $Save = 'Manual' Then
				_Process_SetScrollLog(_GetTR($Message, 'L5')); => mod is included in another one
				_Process_SetScrollLog('')
				ContinueLoop; that's addtional stuff like Nej2Gui, CTB_FF, it's included in other saves
			EndIf
			If $Prefix = '' Then
				$Tag = ''
			ElseIf $Prefix = 'Add' Then
				$Tag = ' ('&_GetTR($Message, 'L12')&')'; => additional
			Else
				$Tag = ' ('&_GetTR($Message, 'L13')&')'; => translation
			EndIf
			If FileExists($g_DownDir & '\' & $Save) Then
				$INetSize = _IniRead($ReadSection, $Prefix & 'Size', '')
				$FileSize = FileGetSize($g_DownDir & '\' & $Save)
				If $FileSize = $INetSize Then
					FileMove($g_DownDir & '\' & $Save, $g_DownDir & '\Valid\'); move the file to valid if size is as expected
					$RoundedINetSize = Round($INetSize / 1048576, 1)
					If $RoundedINetSize = '0' Then $RoundedINetSize = '0.1'
					_Process_SetScrollLog(StringFormat(_GetTR($Message, 'L4'), $RoundedINetSize)); => matching archive found
				Else
					$Fault = $Fault & '|' & $List[$l][1]&$Tag; collect wrong sizes
					_Process_SetScrollLog(_GetTR($Message, 'L6')&$Tag); => wrong filesize
				EndIf
			Else
				$Fault = $Fault & '|' & $List[$l][1]&$Tag; this one didn't exist
				_Process_SetScrollLog(StringFormat(_GetTR($Message, 'L3'), $Save)&$Tag); => missing archive
			EndIf
			_Process_SetScrollLog('')
		Next
	Next
	FileMove($g_DownDir & '\*.*', $g_DownDir & '\Not Valid\'); move the rest to not valid
	FileMove($g_DownDir & '\Valid\*.*', $g_DownDir & '\'); get the valid files back
	$Num=DirGetSize($g_DownDir & '\Valid', 1)
	If $Num[1] = 0 And $Num[2] = 0 Then DirRemove($g_DownDir & '\Valid', 1)
	$Num=DirGetSize($g_DownDir & '\Not Valid', 1)
	If $Num[1] <> 0 Then $Delete = 1; files are found
	If $Num[2] <> 0 Then $Delete = 1; dirs are found
	If $Delete = 1 Then
		If $Keep = 'r' Then; remove files
			; ask
			_Process_SetScrollLog(_GetTR($Message, 'L17'), 1, -1); => really delete files
			_Process_Question('y|n',_GetTR($Message, 'L18'), _GetTR($Message, 'Q2'), 2); => yes/no
			If $g_pQuestion = 'y' Then
				DirRemove($g_DownDir & '\Not Valid', 1)
			Else
				FileMove($g_DownDir & '\Not Valid\*.*', $g_DownDir & '\')
				DirRemove($g_DownDir & '\Not Valid', 1)
			EndIf
		ElseIf $Keep = 'm' Then; move files
			If Not FileExists($g_RemovedDir) Then DirCreate($g_RemovedDir)
			DirMove($g_DownDir & '\Not Valid', $g_RemovedDir & '\BiG World Downloads-'&@YEAR&@MON&@MDAY, 1)
			_Process_SetScrollLog(StringFormat(_GetTR($Message, 'L16'), $g_RemovedDir & '\BiG World Downloads-'&@YEAR&@MON&@MDAY)); => files can be found at X
		Else; restore files
			FileMove($g_DownDir & '\Not Valid\*.*', $g_DownDir & '\')
		EndIf
	Else
		DirRemove($g_DownDir & '\Not Valid')
	EndIf
	GUICtrlSetData($g_UI_Interact[6][1], 100)
	_Process_SetScrollLog(_GetTR($Message, 'L7')); => summary
	If $Fault = '' Then
		_Process_SetScrollLog(_GetTR($Message, 'L8')); => all mods found
	Else
		_Process_SetScrollLog(_GetTR($Message, 'L9')); => these are missing
		_Process_SetScrollLog('')
		$Fault = StringSplit(StringTrimLeft($Fault, 1), '|')
		For $f = 1 To $Fault[0]
			_Process_SetScrollLog($Fault[$f])
		Next
	EndIf
	GUICtrlSetData($g_UI_Static[6][2], _GetTR($Message, 'L10')); => finished
	_Process_SetScrollLog(_GetTR($Message, 'L10')); => finished
	_Process_Gui_Delete(3, 3, 1)
EndFunc   ;==>_Test_ArchivesExist

; ---------------------------------------------------------------------------------------------
; Search if the german textpatch is needed
; ---------------------------------------------------------------------------------------------
Func _Test_CheckBG1TP()
	Local $CurrentVersion, $InstalledVersion
	If Not StringRegExp($g_Flags[14], 'BWP|BWS') Then Return 1; no BWP/BWS-installation (BG1)
	If $g_MLang[1] <> 'GE' Then Return 1
	If $g_BG1Dir = '-' Then Return 1
	$CurrentVersion=IniRead($g_ModIni, 'BG1TP', 'Rev', '')
	If FileExists($g_BG1Dir&'\WeiDU.log') Then
		$Array = StringSplit(StringStripCR(FileRead($g_BG1Dir & '\Weidu.log')), @LF)
		For $a = $Array[0] To 1 Step -1
			If StringRegExp($Array[$a], '(?i)\A~.{0,}(setup\x2d|\x2f|)bg1tp.tp2~\s#0\s#0') Then
				$Component = StringRegExpReplace($Array[$a], '\A.*\s//\s', '')
				$InstalledVersion=StringRegExpReplace($Component, '(?i).*:\sv|\r|\n', '')
				ExitLoop
			EndIf
		Next
	EndIf
	If $CurrentVersion > $InstalledVersion And $InstalledVersion <> '' Then; Remove and Install
		Return -1
	ElseIf $CurrentVersion > $InstalledVersion And $InstalledVersion = '' Then; Install
		Return 0
	Else; Do nothing
		Return 1
	EndIf
EndFunc    ;==>_Test_CheckBG1TP

; ---------------------------------------------------------------------------------------------
; Searches for correct spanish bg1-sounds
; ---------------------------------------------------------------------------------------------
Func _Test_CheckTotSCFiles_BG1()
	If $g_MLang[1] <> 'SP' Then Return 1
	If FileGetSize($g_BG1Dir&'\Data\MPSounds.bif') <> 6730534 Then Return 0
	If FileGetSize($g_BG1Dir&'\Data\NPCSound.bif') <> 55387742 Then Return 0
	If FileGetSize($g_BG1Dir&'\Data\SFXSound.bif') <> 48575666 Then Return 0
	If FileGetSize($g_BG1Dir&'\Data\CHASound.bif') <> 39654993 Then Return 0
	If FileGetSize($g_BG1Dir&'\Data\CRESound.bif') <> 8913388 Then Return 0
	Return 1
EndFunc    ;==>_Test_CheckTotSCFiles_BG1

; ---------------------------------------------------------------------------------------------
; Searches for required files and dirs...
; ---------------------------------------------------------------------------------------------
Func _Test_CheckRequieredFiles()
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Test_CheckRequieredFiles')
	Local $Error=0
	If StringRegExp($g_Flags[14], 'BWS|BWP') Then; (BGT)
		$Return = _Test_CheckRequieredFiles_BG1()
		$Error += @error
		If $Return = 1 Then $Error += 1
		$Return = _Test_CheckRequieredFiles_BG2()
		$Error += @error
		If $Return = 1 Then $Error += 1
	ElseIf $g_Flags[14] = 'BG2EE' Then; (EET)
		$Return = _Test_CheckRequieredFiles_BG1EE()
		$Error += @error
		If $Return = 1 Then $Error += 1
		$Return = _Test_CheckRequieredFiles_BG2EE()
		$Error += @error
		If $Return = 1 Then $Error += 1
	Else
		$Return = Call ('_Test_CheckRequieredFiles_'&$g_Flags[14])
		$Error += @error
		If $Return = 1 Then $Error += 1
	EndIf
	$g_DownDir=GUICtrlRead($g_UI_Interact[2][3])
	If Not FileExists($g_DownDir) Then DirCreate($g_DownDir)
	IniWrite($g_UsrIni, 'Options', 'Download', $g_DownDir)
	If Not FileExists($g_LogDir) Then DirCreate($g_LogDir)
	If Not FileExists($g_ProgDir&'\Update') Then DirCreate($g_ProgDir&'\Update')
	Return $Error
EndFunc    ;==>_Test_CheckRequieredFiles

; ---------------------------------------------------------------------------------------------
; Searches for required bg1-files and dirs...
; ---------------------------------------------------------------------------------------------
Func _Test_CheckRequieredFiles_BG1()
	Local $Message = IniReadSection($g_TRAIni, 'TE-BG1')
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Test_CheckRequieredFiles_BG1')
	Local $Missing='', $Hint='', $Error='', $Return
	If IniRead($g_BWSIni, 'Order', 'Au3Select', 0) = 1 Then
		$g_BG1Dir=GUICtrlRead($g_UI_Interact[2][1])
		IniWrite($g_UsrIni, 'Options', 'BG1', $g_BG1Dir)
	EndIf
	If $g_BG1Dir = '-' Then
		_Test_SetButtonColor(1, 0, 0)
		Return SetError(0, 0, 2)
	EndIf
	If Not FileExists($g_BG1Dir) Or $g_BG1Dir = '' Then
		_Misc_MsgGUI(4, $g_ProgName, _GetTR($Message, 'L1'), 1); => folder does not exist
		_Test_SetButtonColor(1, 1, 1)
		Return SetError(1, 1, 1)
	EndIf
	Local $Array[129] = ["000A", "000B", "000C", "000D", "000E", "000F", "000G", "000H", "010A", "010B", "020A", "020B", "030A", _
	"030B", "040X", "050D", "060A", "070A", "080A", "080B", "090X", "0100", "110A", "110B", "110C", "120A", "120B", "130A", _
	"140A", "140B", "160X", "180A", "180B", "180C", "180D", "180E", "190X", "0200", "210X", "220X", "230A", "230B", "260A", _
	"260B", "260C", "0300", "320X", "330A", "330B", "330C", "330D", "340X", "360X", "380X", "390X", "0400", "400X", "410X", _
	"420X", "440X", "450X", "470X", "480X", "490X", "500X", "510X", "520X", "540A", "540B", "540C", "540D", "550X", "0600", _
	"0700", "0800", "0900", "1100", "1200", "1300", "1400", "1600", "1700", "1800", "1900", "2100", "2200", "2300", "2400", _
	"2600", "2700", "2800", "2900", "3000", "3100", "3200", "3300", "3400", "3500", "3600", "3700", "3800", "3900", "4000", _
	"4100", "4200", "4300", "4400", "4500", "4600", "4700", "4800", "4900", "5000", "5100", "5200", "5300", "5400", "5500", _
	"050A", "050B", "050C", "100A", "150A", "200A", "200B", "0500", "1000", "1500", "2000"]
	For $a in $Array; Checking for missing bg1-files (area-bif)
		If Not FileExists($g_BG1Dir&'\data\Area'&$a&'.bif') Then $Missing &= @CRLF&'data\Area'&$a&'.bif'
	Next
	Local $Array[23] = ["Areas", "ARMisc", "CHAAnim", "CHASound", "CREAnim", "Creature", "CRESound", "Default", "Dialog", "Effects", _
	"Gui", "Items", "MPCREANM", "MPGUI", "MPSounds", "NPCSound", "OBJAnim", "RndEncnt", "scripts", "SFXSound", "Spells", "ExArMaps", "ExPAreas"]
	For $a in $Array; Checking for missing bg1-files (misc-bif)
		If Not FileExists($g_BG1Dir&'\data\'&$a&'.bif') Then $Missing &= @CRLF&'data\'&$a&'.bif'
	Next
	For $a=1 to 6; Checking for missing bg1-files (movie-bif)
		If Not FileExists($g_BG1Dir&"\movies\MOVIECD"&$a&".bif") Then $Missing&=@CRLF&"movies\MOVIECD"&$a&".bif"
	Next
	If Not FileExists($g_BG1Dir&"\chitin.key") Then $Missing&=@CRLF&"chitin.key"
	If Not FileExists($g_BG1Dir&"\BGMain2.exe") Then $Missing&=@CRLF&"BGMain2.exe"
	If $Missing <> '' Then $Error &= StringFormat(_GetTR($Message, 'L2'), $Missing); => no full installation
	If FileGetVersion($g_BG1Dir&'\bgmain2.exe') <> '1.3.0.1' Then $Error&=_GetTR($Message, 'L3')&@CRLF; => no current installation
	If $Error <> '' Then
		_Misc_MsgGUI(4, $g_ProgName, $Hint&$Error, 1)
		Local $ret_Error=1, $ret_Extended=0, $Return = 1
	ElseIf $Hint<> '' Then
		$Return = _Misc_MsgGUI(3, $g_ProgName, $Hint, 2)
		Local $ret_Error=0, $ret_Extended=1
	Else
		Local $ret_Error=0, $ret_Extended=0, $Return = 2
	EndIf
	_Test_SetButtonColor(1, $ret_Error, $ret_Extended)
	Return SetError($ret_Error, $ret_Extended, $Return)
EndFunc    ;==>_Test_CheckRequieredFiles_BG1

; ---------------------------------------------------------------------------------------------
; Searches for required bg1-files and dirs...
; ---------------------------------------------------------------------------------------------
Func _Test_CheckRequieredFiles_BG2()
	Local $Message = IniReadSection($g_TRAIni, 'TE-BG2')
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Test_CheckRequieredFiles_BG2')
	Local $Hint='', $Error='', $Return
	If IniRead($g_BWSIni, 'Order', 'Au3Select', 0) = 1 Then
		$g_BG2Dir=GUICtrlRead($g_UI_Interact[2][2])
		IniWrite($g_UsrIni, 'Options', 'BG2', $g_BG2Dir)
	EndIf
	If Not FileExists($g_BG2Dir) Or $g_BG2Dir = '' Then
		_Misc_MsgGUI(4, $g_ProgName, _GetTR($Message, 'L1'), 1); => does not exist
		_Test_SetButtonColor(2, 1, 1)
		Return SetError(1, 1, 1)
	EndIf
	$BG2AliasDir=IniRead($g_BG2Dir & '\baldur.ini', 'Alias', 'CD5:', $g_BG2Dir&'\CD5\')
	If StringInStr($BG2AliasDir, ';') Then
		$BG2AliasDir=StringSplit($BG2AliasDir, ';')
		For $b=1 to $BG2AliasDir[0]
			If StringRegExp($BG2AliasDir[$b], '\x5c\z') = 0 Then $BG2AliasDir[$b]&='\'; add trailing backslash if it's missing in new compilations
			If ( FileExists($BG2AliasDir[$b] & 'Movies\25movies.bif') Or FileExists($g_BG2Dir & '\' & 'Movies\25movies.bif') ) Then
				$BG2AliasDir=$BG2AliasDir[$b]
				ExitLoop
			EndIf
		Next
	EndIf
	If StringRegExp($BG2AliasDir, '\x5c\z') = 0 Then $BG2AliasDir&='\'; add trailing backslash if missing
	If Not ( FileExists($BG2AliasDir & 'Movies\25movies.bif') Or FileExists($g_BG2Dir & '\' & 'Movies\25movies.bif') ) Then $Error&=_GetTR($Message, 'L2')&@CRLF; => movie-file is missing
	If FileGetVersion($g_BG2Dir&'\bgmain.exe') = '2.5.0.2' And FileGetVersion($g_BG2Dir&'\bgmain.exe', 'PrivateBuild') = '26498' Then
		; ok
	ElseIf IniRead($g_MODIni, 'Classics053', 'Name', '') = 'The Classic Adventures' And FileGetVersion($g_BG2Dir&'\bgmain.exe') = '2.5.0.2' Then
		; ok, CA patches EXE
	Else
		$Error&=_GetTR($Message, 'L3')&@CRLF; => patch is missing
	EndIf
	$Path=StringLeft($g_BG2Dir, StringInStr($g_BG2Dir, '\', 1, -1)-1)
	If $Error <> '' Then
		_Misc_MsgGUI(4, $g_ProgName, $Hint&$Error, 1)
		Local $ret_Error=1, $ret_Extended=0, $Return = 1
	ElseIf $Hint<> '' Then
		$Return = _Misc_MsgGUI(3, $g_ProgName, StringRegExpReplace($Hint, '\A\r\n|\r\n\z', ''), 2)
		Local $ret_Error=0, $ret_Extended=1
	Else
		Local $ret_Error=0, $ret_Extended=0, $Return = 2
	EndIf
	_Test_SetButtonColor(2, $ret_Error, $ret_Extended)
	Return SetError($ret_Error, $ret_Extended, $Return)
EndFunc    ;==>_Test_CheckRequieredFiles_BG2

; ---------------------------------------------------------------------------------------------
; Searches for required bg1ee-files and dirs...
; ---------------------------------------------------------------------------------------------
Func _Test_CheckRequieredFiles_BG1EE()
	Local $Message = IniReadSection($g_TRAIni, 'TE-BG1EE')
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Test_CheckRequieredFiles_BG1EE')
	Local $Missing='', $Hint='', $Error='', $Return, $Num=2
	If $g_Flags[14] = 'BG2EE' Then $Num=1
	If IniRead($g_BWSIni, 'Order', 'Au3Select', 0) = 1 Then
		$g_BG1EEDir=GUICtrlRead($g_UI_Interact[2][$Num])
		IniWrite($g_UsrIni, 'Options', 'BG1EE', $g_BG1EEDir)
	EndIf
	If $g_BG1EEDir = '-' And $g_Flags[14] = 'BG2EE' Then
		_Test_SetButtonColor(1, 0, 0)
		Return SetError(0, 0, 2)
	EndIf
	If Not FileExists($g_BG1EEDir) Or $g_BG1EEDir = '' Then
		_Misc_MsgGUI(4, $g_ProgName, _GetTR($Message, 'L1'), 1); => folder does not exist
		_Test_SetButtonColor($Num, 1, 1)
		Return SetError(1, 1, 1)
	EndIf
	If FileExists($g_BG1EEDir&'\lang\en_US') And FileExists($g_BG1EEDir&'\movies\mineflod.wbm') And FileExists($g_BG1EEDir&'\Baldur.exe') Then; BG1EE-directory structure
	Else
		$Error&=_GetTR($Message, 'L2')&@CRLF; => structure not valid
	EndIf
	If $Error <> '' Then
		_Misc_MsgGUI(4, $g_ProgName, $Hint&$Error, 1)
		Local $ret_Error=1, $ret_Extended=0, $Return = 1
	ElseIf $Hint<> '' Then
		$Return = _Misc_MsgGUI(3, $g_ProgName, $Hint, 2)
		Local $ret_Error=0, $ret_Extended=1
	Else
		Local $ret_Error=0, $ret_Extended=0, $Return = 2
	EndIf
	_Test_SetButtonColor($Num, $ret_Error, $ret_Extended)
	Return SetError($ret_Error, $ret_Extended, $Return)
EndFunc    ;==>_Test_CheckRequieredFiles_BG1EE

; ---------------------------------------------------------------------------------------------
; Searches for required bg2ee-files and dirs...
; ---------------------------------------------------------------------------------------------
Func _Test_CheckRequieredFiles_BG2EE()
	Local $Message = IniReadSection($g_TRAIni, 'TE-BG2EE')
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Test_CheckRequieredFiles_BG2EE')
	Local $Missing='', $Hint='', $Error='', $Return
	If IniRead($g_BWSIni, 'Order', 'Au3Select', 0) = 1 Then
		$g_BG2EEDir=GUICtrlRead($g_UI_Interact[2][2])
		IniWrite($g_UsrIni, 'Options', 'BG2EE', $g_BG2EEDir)
	EndIf
	If Not FileExists($g_BG2EEDir) Or $g_BG2EEDir = '' Then
		_Misc_MsgGUI(4, $g_ProgName, _GetTR($Message, 'L1'), 1); => folder does not exist
		_Test_SetButtonColor(2, 1, 1)
		Return SetError(1, 1, 1)
	EndIf
	If FileExists($g_BG2EEDir&'\lang\en_US') And FileExists($g_BG2EEDir&'\movies\melissan.wbm') And FileExists($g_BG2EEDir&'\Baldur.exe') Then; BG2EE-directory structure
	Else
		$Error&=_GetTR($Message, 'L2')&@CRLF; => structure not valid
	EndIf
	If $Error <> '' Then
		_Misc_MsgGUI(4, $g_ProgName, $Hint&$Error, 1)
		Local $ret_Error=1, $ret_Extended=0, $Return = 1
	ElseIf $Hint<> '' Then
		$Return = _Misc_MsgGUI(3, $g_ProgName, $Hint, 2)
		Local $ret_Error=0, $ret_Extended=1
	Else
		Local $ret_Error=0, $ret_Extended=0, $Return = 2
	EndIf
	_Test_SetButtonColor(2, $ret_Error, $ret_Extended)
	Return SetError($ret_Error, $ret_Extended, $Return)
EndFunc    ;==>_Test_CheckRequieredFiles_BG2EE

; ---------------------------------------------------------------------------------------------
; Searches for required iwd1-files and dirs...
; ---------------------------------------------------------------------------------------------
Func _Test_CheckRequieredFiles_IWD1()
	Local $Message = IniReadSection($g_TRAIni, 'TE-IWD1')
	_PrintDebug('+' & @ScriptLineNumber & ' Calling IWD1-FileCheck')
	Local $Missing='', $Hint='', $Error='', $Return
	If IniRead($g_BWSIni, 'Order', 'Au3Select', 0) = 1 Then
		$g_IWD1Dir=GUICtrlRead($g_UI_Interact[2][2])
		IniWrite($g_UsrIni, 'Options', 'IWD1', $g_IWD1Dir)
	EndIf
	If Not FileExists($g_IWD1Dir) Or $g_IWD1Dir = '' Then
		_Misc_MsgGUI(4, $g_ProgName, _GetTR($Message, 'L1'), 1); => folder does not exist
		_Test_SetButtonColor(2, 1, 1)
		Return SetError(1, 1, 1)
	EndIf
	$Version=FileGetVersion($g_IWD1Dir&'\idmain.exe')
	If $Version = '0.0.0.0' Then; unpatched IWD
		$Error&=_GetTR($Message, 'L2')&@CRLF; => at least patch
	ElseIf $Version = '1.3.0.1' Then; patched IWD1 1.06
		$Hint&=_GetTR($Message, 'L3')&@CRLF; => you'll miss content
	ElseIf $Version = '1.4.0.1' Then; unpatched IWD1 HoW
		$Error&=_GetTR($Message, 'L4')&@CRLF; => at least patch
	ElseIf $Version = '1.4.1.0' Then; patched IWD1 HoW 1.41
		$Hint&=_GetTR($Message, 'L5')&@CRLF; => no current installation
	ElseIf $Version = '1.4.2.0' Then; How with TotL

	EndIf
	If $Error <> '' Then
		_Misc_MsgGUI(4, $g_ProgName, $Hint&$Error, 1)
		Local $ret_Error=1, $ret_Extended=0, $Return = 1
	ElseIf $Hint<> '' Then
		$Return = _Misc_MsgGUI(3, $g_ProgName, $Hint, 2)
		Local $ret_Error=0, $ret_Extended=1
	Else
		Local $ret_Error=0, $ret_Extended=0, $Return = 2
	EndIf
	_Test_SetButtonColor(2, $ret_Error, $ret_Extended)
	Return SetError($ret_Error, $ret_Extended, $Return)
EndFunc    ;==>_Test_CheckRequieredFiles_IWD1

; ---------------------------------------------------------------------------------------------
; Searches for required iwd2-files and dirs...
; ---------------------------------------------------------------------------------------------
Func _Test_CheckRequieredFiles_IWD2()
	Local $Message = IniReadSection($g_TRAIni, 'TE-IWD2')
	_PrintDebug('+' & @ScriptLineNumber & ' Calling IWD2-FileCheck')
	Local $Missing='', $Hint='', $Error='', $Return
	If IniRead($g_BWSIni, 'Order', 'Au3Select', 0) = 1 Then
		$g_IWD2Dir=GUICtrlRead($g_UI_Interact[2][2])
		IniWrite($g_UsrIni, 'Options', 'IWD2', $g_IWD2Dir)
	EndIf
	If Not FileExists($g_IWD2Dir) Or $g_IWD2Dir = '' Then
		_Misc_MsgGUI(4, $g_ProgName, _GetTR($Message, 'L1'), 1); => folder does not exist
		_Test_SetButtonColor(2, 1, 1)
		Return SetError(1, 1, 1)
	EndIf
	If FileGetVersion($g_IWD2Dir&'\iwd2.exe') = '2.0.1.0' Then; IWD patched
	Else
		$Error&=_GetTR($Message, 'L2')&@CRLF; => no current installation
	EndIf
	If $Error <> '' Then
		_Misc_MsgGUI(4, $g_ProgName, $Hint&$Error, 1)
		Local $ret_Error=1, $ret_Extended=0, $Return = 1
	ElseIf $Hint<> '' Then
		$Return = _Misc_MsgGUI(3, $g_ProgName, $Hint, 2)
		Local $ret_Error=0, $ret_Extended=1
	Else
		Local $ret_Error=0, $ret_Extended=0, $Return = 2
	EndIf
	_Test_SetButtonColor(2, $ret_Error, $ret_Extended)
	Return SetError($ret_Error, $ret_Extended, $Return)
EndFunc    ;==>_Test_CheckRequieredFiles_IWD2

; ---------------------------------------------------------------------------------------------
; Searches for required pst-files and dirs...
; ---------------------------------------------------------------------------------------------
Func _Test_CheckRequieredFiles_PST()
	Local $Message = IniReadSection($g_TRAIni, 'TE-PST')
	_PrintDebug('+' & @ScriptLineNumber & ' Calling PST-FileCheck')
	Local $Missing='', $Hint='', $Error='', $Return
	If IniRead($g_BWSIni, 'Order', 'Au3Select', 0) = 1 Then
		$g_PSTDir=GUICtrlRead($g_UI_Interact[2][2])
		IniWrite($g_UsrIni, 'Options', 'PST', $g_PSTDir)
	EndIf
	If Not FileExists($g_PSTDir) Or $g_PSTDir = '' Then
		_Misc_MsgGUI(4, $g_ProgName, _GetTR($Message, 'L1'), 1); => folder does not exist
		_Test_SetButtonColor(2, 1, 1)
		Return SetError(1, 1, 1)
	EndIf
		If FileGetVersion($g_PSTDir&'\torment.exe') = '1.0.0.1' Then; PST may be patched or unpatched
		If Not FileExists($g_PSTDir&'\Override\ar0700.ini') Then $Error&=_GetTR($Message, 'L3')&@CRLF; => no current installation
	Else
		$Error&=_GetTR($Message, 'L3')&@CRLF; => no current installation
	EndIf
	$ReadSection=IniReadSection($g_PSTDir&'\torment.ini', 'Alias')
	$Test=1
	For $r=1 to $ReadSection[0][0]
		If StringLeft($ReadSection[$r][0], 2) = 'CD' Then
			$Drive=StringLeft($ReadSection[$r][1], 2)
			If StringRegExp(DriveGetFileSystem($Drive), '(?i)\A\z|CDFS|UDF') Then $Test=0
		EndIf
	Next
	If $Test = 0 Then
		$Test=_Misc_MsgGUI(2, $g_ProgName, _GetTR($Message, 'L2'), 2); => files on hdd
		If $Test=1 Then
			$Error&=_GetTR($Message, 'L8')&@CRLF; => need to copy files
		Else
			DirCreate($g_PSTDir&'\CDs')
			For $r=1 to $ReadSection[0][0]
				If StringLeft($ReadSection[$r][0], 2) = 'CD' Then
					$Drive=StringLeft($ReadSection[$r][1], 2)
					If StringRegExp(DriveGetFileSystem($Drive), '(?i)\A\z|CDFS|UDF') Then; not not attached virtual drives, cds, dvds
						If StringRegExp($ReadSection[$r][0], 'CD(1|5)') Then; CD1 does not contain a CD1-folder, CD5 does not exist
							IniWrite($g_PSTDir&'\torment.ini', 'Alias', $ReadSection[$r][0], $g_PSTDir&'\CDs')
							ContinueLoop
						EndIf
						If Not FileExists($ReadSection[$r][1]&'\*.bif') Then
							While 1
								CDTray($Drive, 'open')
								_Misc_MsgGUI(1, $g_ProgName, StringFormat(_GetTR($Message, 'L4'), StringLeft($ReadSection[$r][0], 3), $ReadSection[$r][1]) , 1); => please gimme CD X
								If FileExists($ReadSection[$r][1]&'\*.bif') Then ExitLoop; don't do funny things when using virtual drives
								CDTray($Drive, 'close')
								If FileExists($ReadSection[$r][1]&'\*.bif') Then ExitLoop
							WEnd
						EndIf
						$Size=DirGetSize($ReadSection[$r][1])
						$List=_FileSearch($ReadSection[$r][1], '*')
						$cSize=0
						_Misc_ProgressGUI(_GetTR($Message, 'L5'), _GetTR($Message, 'L6')); => copy files
						For $l=1 to $List[0]
							GUICtrlSetData ($g_UI_Interact[9][1] , ($cSize*100)/$Size)
							GUICtrlSetData ($g_UI_Static[9][2], $List[$l])
							$FileSize=FileGetSize($ReadSection[$r][1]&'\'&$List[$l])
							If FileExists($g_PSTDir&'\CDs\'&$List[$l]) And FileGetSize($g_PSTDir&'\CDs\'&$List[$l]) = $FileSize Then
								$cSize +=$FileSize
								ContinueLoop
							EndIf
							$Success=FileCopy($ReadSection[$r][1]&'\'&$List[$l], $g_PSTDir&'\CDs\'&$List[$l], 9)
							If $Success = 0 Then
								$Error&=StringFormat(_GetTR($Message, 'L7'), $List[$l])&@CRLF; => no current installation
								ExitLoop 2
							EndIf
							FileSetAttrib($g_PSTDir&'\CDs\'&$List[$l], '-R'); remove read-only-bit
							$cSize+=$FileSize
						Next
					EndIf
					IniWrite($g_PSTDir&'\torment.ini', 'Alias', $ReadSection[$r][0], $g_PSTDir&'\CDs')
				EndIf
			Next
			_Misc_SetTab(2)
		EndIf
	EndIf
	If $Error <> '' Then
		_Misc_MsgGUI(4, $g_ProgName, $Hint&$Error, 1)
		Local $ret_Error=1, $ret_Extended=0, $Return = 1
	ElseIf $Hint<> '' Then
		$Return = _Misc_MsgGUI(3, $g_ProgName, $Hint, 2)
		Local $ret_Error=0, $ret_Extended=1
	Else
		Local $ret_Error=0, $ret_Extended=0, $Return = 2
	EndIf
	_Test_SetButtonColor(2, $ret_Error, $ret_Extended)
	Return SetError($ret_Error, $ret_Extended, $Return)
EndFunc    ;==>_Test_CheckRequieredFiles_PST

; ---------------------------------------------------------------------------------------------
; Same as _Test_GetTP2, but always returns a hit for bgt-music and bgt-gui and considers wrong filenames
; ---------------------------------------------------------------------------------------------
Func _Test_GetCustomTP2($p_Setup, $p_Dir='\')
	$TP2 = _Test_GetTP2($p_Setup, $p_Dir)
	If $TP2 = '0' Then
		$Rename = IniRead($g_MODIni, $p_Setup, 'REN', ''); look for some non-standard-filenames that will be renamed later
		If $Rename <> '' Then $TP2 = _Test_GetTP2($Rename, $p_Dir)
	EndIf
	If $TP2 = '0' Then
		Return SetError(1, 0, $TP2)
	Else
		$Return = _Test_GetModFolder($TP2)
		If $Return = '0' Then
			Return SetError(2, 0, $TP2)
		Else
			Return SetError(0, 0, $TP2)
		EndIf
	EndIf
EndFunc   ;==>_Test_GetCustomTP2

; ---------------------------------------------------------------------------------------------
; test if the folder that contains the mods data is present
; ---------------------------------------------------------------------------------------------
Func _Test_GetModFolder($p_TP2)
	If Not StringInStr($p_TP2, '.tp2') Then Return '0'
	$Array = StringSplit(StringStripCR(FileRead($p_TP2)), @LF)
	For $a=1 to $Array[0]
		If StringLeft($Array[$a], 6) = 'Backup' Then
			$Return = StringSplit($Array[$a], '"\/~')
			$Dir = $g_GameDir & '\' & StringStripWS($Return[2], 3)
			$IsDir = FileGetAttrib($Dir); get the attrib of this file or directory
			If StringInStr($IsDir, 'D') Then
				Return $Return[2]
			Else
				Return '0'
			EndIf
		EndIf
	Next
	Return '0'
EndFunc    ;==>_Test_GetModFolder

; ---------------------------------------------------------------------------------------------
; Find out if the TP2-file from a given setup exists
; ---------------------------------------------------------------------------------------------
Func _Test_GetTP2($p_Setup, $p_Dir='\')
	If FileExists($g_GameDir & $p_Dir & 'Setup-' & $p_Setup & '.TP2') Then
		Return $g_GameDir & $p_Dir & 'Setup-' & $p_Setup & '.TP2'
	ElseIf FileExists($g_GameDir & $p_Dir & $p_Setup & '.TP2') Then
		Return $g_GameDir & $p_Dir & $p_Setup & '.TP2'
	ElseIf FileExists($g_GameDir & $p_Dir & $p_Setup & '\' & $p_Setup & '.TP2') Then
		Return $g_GameDir & $p_Dir & $p_Setup & '\' & $p_Setup & '.TP2'
	ElseIf FileExists($g_GameDir & $p_Dir & $p_Setup & '\Setup-' & $p_Setup & '.TP2') Then
		Return $g_GameDir & $p_Dir & $p_Setup & '\Setup-' & $p_Setup & '.TP2'
	Else
		Return '0'
	EndIf
EndFunc   ;==>_Test_GetTP2

; ---------------------------------------------------------------------------------------------
; check if required folders are set
; ---------------------------------------------------------------------------------------------
Func _Test_RejectPath($p_Num)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Test_RejectPath')
	$Path = GUICtrlRead($g_UI_Interact[2][$p_Num])
	If $Path = '' Then
		_Test_SetButtonColor($p_Num, 1, 1)
		GUICtrlSetBkColor($g_UI_Interact[2][$p_Num], 0xff0000)
		GUICtrlSetData($g_UI_Interact[2][$p_Num], _GetTR($g_UI_Message, '2-L2')); => something's missing
		Sleep(2000)
		GUICtrlSetBkColor($g_UI_Interact[2][$p_Num], 0xffffff)
		GUICtrlSetData($g_UI_Interact[2][$p_Num], '')
		Return 1
	EndIf
EndFunc   ;==>_Test_RejectPath

; ---------------------------------------------------------------------------------------------
; Set the color of the files/folders test-button
; ---------------------------------------------------------------------------------------------
Func _Test_SetButtonColor($p_Num, $p_Error, $p_Extended)
	GUICtrlSetColor($g_UI_Button[2][$p_Num], 0xFFFFFF); white
	If $p_Error = 1 Then
		GUICtrlSetBkColor($g_UI_Button[2][$p_Num], 0xb0151c); red
	ElseIf $p_Extended = 1 Then
		GUICtrlSetBkColor($g_UI_Button[2][$p_Num], 0xed7515); orange
	Else
		GUICtrlSetBkColor($g_UI_Button[2][$p_Num], 0x0b630b); green
	EndIf
EndFunc    ;==>_Test_SetButtonColor