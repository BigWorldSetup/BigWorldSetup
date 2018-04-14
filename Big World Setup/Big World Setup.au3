AutoItSetOption('WinTitleMatchMode', 2); set a more flexible way to search for windows
AutoItSetOption('GUIResizeMode', 1); resize and reposition GUI-elements according to new window size
AutoItSetOption('GUICloseOnESC', 0);  don't send the $GUI_EVENT_CLOSE message when ESC is pressed
AutoItSetOption('TrayIconDebug', 1); shows the current script line in the tray icon tip to help debugging
AutoItSetOption('GUIOnEventMode', 0); disable OnEvent functions notifications
AutoItSetOption('OnExitFunc', 'Au3Exit'); sets the name of the function called when AutoIt exits
;AutoItSetOption('MustDeclareVars', 1); require Local/Global/Dim pre-declaration of variables to help catch bugs

TraySetIcon(@ScriptDir & '\Pics\BWS.ico'); sets the tray-icon

#Region Global vars
; Global are named with a $g_ , parameters with a $p_ . Normal/Local variables don't have a prefix.
; files and folders
Global $g_BaseDir = StringLeft(@ScriptDir, StringInStr(@ScriptDir, '\', 1, -1) - 1), $g_GConfDir, $g_ConnectionsConfDir, $g_GameDir, $g_ProgName = 'Big World Setup'
Global $g_ProgDir = $g_BaseDir & '\Big World Setup', $g_LogDir = $g_ProgDir & '\Logs', $g_DownDir = $g_BaseDir & '\Big World Downloads'
Global $g_BG1Dir, $g_BG2Dir, $g_BG1EEDIR, $g_BG2EEDIR, $g_IWD1Dir, $g_IWD1EEDir, $g_PSTEEDir, $g_IWD2Dir, $g_PSTDir, $g_RemovedDir, $g_BackupDir, $g_LogFile = $g_LogDir & '\BWS-Debug.txt'
Global $g_BWSIni = $g_ProgDir & '\Config\Setup.ini', $g_MODIni, $g_UsrIni = $g_ProgDir & '\Config\User.ini'
; select-gui vars
Global $g_Compilation = 'R', $g_LimitedSelection = 0, $g_Tags, $g_ActiveConnections[1], $g_Groups, $g_GameList
Global $g_TreeviewItem[1][1], $g_CHTreeviewItem[1][1], $g_Connections, $g_CentralArray[1][16], $g_GUIFold
; Logging, Reading Streams / Process-Window
Global $g_ConsoleOutput = '', $g_STDStream, $g_ConsoleOutput, $g_pQuestion = 0
; program options and misc
Global $g_Order, $g_Setups, $g_Skip, $g_Clip; available setups, items to skip
Global $g_CurrentPackages, $g_fLock, $g_FItem = IniRead($g_BWSIni, 'Options', 'Start', '1'); selected packages, fixed mods and last processed item
Global $g_ATrans = StringSplit(IniRead($g_BWSIni, 'Options', 'AppLang', 'EN|GE'), '|'), $g_ATNum = 1, $g_MLang; available translations and mod translations
Global $g_UDll = DllOpen('user32.dll'); we have to use this for detecting the mouse or keboard-usage
Global $g_Down[6][2]; used for updating download-progressbar
; ---------------------------------------------------------------------------------------------
; New GUI-Builing
; ---------------------------------------------------------------------------------------------
Global $g_UI[5], $g_UI_Static[17][20], $g_UI_Button[17][20], $g_UI_Seperate[17][10], $g_UI_Interact[17][20], $g_UI_Menu[10][50]
Global $g_Search[5], $g_Flags[26] = [1], $g_UI_Handle[10]
Global $g_TRAIni = $g_ProgDir & '\Config\Translation-' & $g_ATrans[$g_ATNum] & '.ini', $g_UI_Message = IniReadSection($g_TRAIni, 'UI-Runtime')
; g_Flags =>
;			1=w: continue without link checking
;			2=w: update links
;			3=mod language-string
;			4=w: mc-disabled
;			5=admin-tokens short/Enable Pause-Resume
;			6=admin-tokens long/overwitten text by pause
;			7=current tip-handle
;			8=current tab is advsel
;			9=window is locked
;			10=Rebuild when leaving first screens/tab to go back from admin-tabs
;			11=back is pressed
;			12=forward is pressed
;			13=real exit
;			14=current selected install method
;			15=greet-picture is visible
;			16=admin-lv has focus/treeicon clicked
;			17=treelabel clicked
;			18=beep
;			19=cmd-started
;			20=w: selection-is-higher-than-your-preselection
;			21=use old sorting format/BG1-mods in EET-install
;			22=wscreen ID/BG2-mods in EET-install
;			23=download-button-number/unsolved dependencies
;			24=user clicked tv
;			25=available selection-items (as numbers)
; g_UI_Handle => 0=adv. TreeView, 1=dep. ListView, 2=mod ListView, 3= 4/5=dep admin ListViews, 6/7=comp Listviews, 8=select admin
; g_UI_Menu[0]=> 0=, 1=used themes in advmenu, 2=number of themes in adv-menus, 3=number of themes+groups in adv-menus, 4=mod, depend and select-contextmenu, 5=, 6-9=depend-context-menu
; $g_UI 0=main, 1=child-window with BWP-pic, 2=width, 3=height, 4=child-window with progress-bar

#EndRegion Global vars
#Region Includes
#include'Includes\01_UDF1.au3'
#include'Includes\02_UDF2.au3'
#include'Includes\03_Admin.au3'
#include'Includes\04_Backup.au3'
#include'Includes\05_Basics.au3'
#include'Includes\06_Depend.au3'
#include'Includes\07_Extract.au3'
#include'Includes\08_GUI.au3'
#include'Includes\09_Install.au3'
#include'Includes\10_Misc-GUI.au3'
#include'Includes\11_NET.au3'
#include'Includes\12_Process.au3'
#include'Includes\13_Select-AI.au3'
#include'Includes\14_Select-GUILoop.au3'
#include'Includes\15_Select-Helper.au3'
#include'Includes\16_Select-Tree.au3'
#include'Includes\17_Testing.au3'
#EndRegion Includes
;#NoTrayIcon

#Region Copy between games

$g_Order = IniReadSection($g_BWSIni, 'Order'); reload this to get the new selected functions

For $g_CurrentOrder = 1 To $g_Order[0][0]; Calling the functions. This is the main loop. Cute, isn't it? :)
	If $g_Order[$g_CurrentOrder][1] = '0' Then ContinueLoop
	Call($g_Order[$g_CurrentOrder][0], $g_Order[$g_CurrentOrder][1])
	__ReduceMemory()
Next

; ---------------------------------------------------------------------------------------------
; If you place Au3Exit=X in the Order-section, the setup will close at this point. If X=0, the setup will ask you to start with the next key of the "current-package"-section.
; Usefull if you want to do some things manually, test things until a certain point...
; ---------------------------------------------------------------------------------------------
Func Au3Exit($p_Num = 0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling Au3Exit')
	DllClose($g_UDll); close the dll for detecting "space"-keypresses
	If $g_STDStream <> '' Then; close the backend-cmd-instance
		StdinWrite($g_STDStream, 'exit' & @CRLF)
		StdinWrite($g_STDStream, @CRLF)
	EndIf
	Exit
EndFunc   ;==>Au3Exit

; ---------------------------------------------------------------------------------------------
; Get the core-settings for the current installation
; ---------------------------------------------------------------------------------------------
Func Au3GetVal($p_Num = 0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling Au3GetVal')
	$g_Order = IniReadSection($g_BWSIni, 'Order'); reload this to get the new selected functions
	Local $ReadSection = IniReadSection($g_UsrIni, 'Options')
	Local $Test = StringSplit(_IniRead($ReadSection, 'AppType', 'BWP:BWS'), ':'); need correct gametype
	If $Test[0] <> 2 Then; revert to default if AppType in User.ini is not in expected format
		$Test = [2, "BWP", "BWS"]
	EndIf
	_Misc_Set_GConfDir($Test[1]); first part before : is the conf folder
	$g_Flags[14] = StringUpper($Test[2]); second part after : determines the target game folder where mods will be installed
	If StringRegExp($g_Flags[14], 'BWS|BWP') Then
		_Test_GetGamePath('BG1')
		_Test_GetGamePath('BG2')
		$g_GameDir = $g_BG2Dir
	Else
		_Test_GetGamePath($g_Flags[14])
		$g_GameDir = Eval('g_' & $g_Flags[14] & 'Dir')
	EndIf
	If $g_Flags[14] = 'BG2EE' Then _Test_GetGamePath('BG1EE'); get path for possible EET-installs
	_Test_Get_EET_Mods(); get BG1EE / BG2EE-mods if currently installing EET
	$g_ModIni = $g_GConfDir & '\Mod.ini'
	$g_Setups = _CreateList('s')
	$g_DownDir = _IniRead($ReadSection, 'Download', '')
	$g_GUIFold = _IniRead($ReadSection, 'UnFold', '1')
	$g_Flags[18] = _IniRead($ReadSection, 'Beep', 0)
	$g_CurrentPackages = IniReadSection($g_UsrIni, 'Current'); used for possible next step: download
	AutoItSetOption('GUIOnEventMode', 1)
	If IniRead($g_BWSIni, 'Order', 'Au3Select', 1) = 0 And GUICtrlRead($g_UI_Button[0][1]) = '' Then; this is a restart > show the question-dialog
		_Misc_SetLang()
		GUICtrlSetState($g_UI_Seperate[8][0], $GUI_SHOW)
		Local $Nextstep
		For $o = 1 To $g_Order[0][0]
			If $g_Order[$o][1] = '0' Then ContinueLoop
			If StringRegExp('Au3BuildGui,Au3Detect,Au3GetVal,Au3ResetEdit', '(\A|\x2c)' & $g_Order[$o][0] & '(\z|\x2c)') Then ContinueLoop
			$Nextstep = $g_Order[$o][0]
			ExitLoop
		Next
		Local $Split, $Name, $Comp, $Answer
		If StringRegExp($g_FItem, '\A\d{1,}\z') Then
			$Array = StringSplit(StringStripCR(FileRead($g_GConfDir & '\Select.txt')), @LF)
			If _IniRead($ReadSection, 'GroupInstall', 0) = 1 Then $Array = _Install_ModifyForGroupInstall($Array); always install in groups
			Local $a = $g_FItem; TODO:  convert to For loop ?
			If $a = 0 Then ; crash prevention when restarting BWS before first mod is processed
				_PrintDebug('Unfortunately, BWS is unable to resume from where it left off - please start over', 1)
				IniWrite($g_BWSIni, 'Order', 'Au3Detect', 1)
				IniWrite($g_BWSIni, 'Order', 'Au3BuildGui', 1)
				IniWrite($g_BWSIni, 'Order', 'Au3Select', 1)
				IniWrite($g_BWSIni, 'Order', 'Au3GetVal', 1)
				IniWrite($g_BWSIni, 'Order', 'Au3CleanInst', 1)
				IniWrite($g_BWSIni, 'Order', 'Au3PrepInst', 1)
				IniWrite($g_BWSIni, 'Order', 'Au3Net', 1)
				IniWrite($g_BWSIni, 'Order', 'Au3NetTest', 1)
				IniWrite($g_BWSIni, 'Order', 'Au3NetFix', 1)
				IniWrite($g_BWSIni, 'Order', 'Au3Extract', 1)
				IniWrite($g_BWSIni, 'Order', 'Au3ExFix', 1)
				IniWrite($g_BWSIni, 'Order', 'Au3ExTest', 1)
				IniWrite($g_BWSIni, 'Order', 'Au3RunFix', 1)
				IniWrite($g_BWSIni, 'Order', 'Au3Install', 1)
				IniWrite($g_BWSIni, 'Order', 'Au3Exit', 1)
				Exit
			EndIf
			While StringRegExp($Array[$a], '(?i)\A(CMD|ANN|DWN|GRP)') And $a < $Array[0]
				$a += 1
			WEnd
			$Split = StringSplit($Array[$a], ';')
			$Name = $Split[2]
			$Name = IniRead($g_ModIni, $Name, 'Name', $Name); SetupName
			$Comp = $Split[3]; CompNumber
			$Answer = _Misc_MsgGUI(2, $g_ProgName, StringFormat(_GetTR($g_UI_Message, '0-L4'), $Nextstep, $Name & ', #' & $Comp), 2, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2')); => continue installation?
		Else
			$Name = IniRead($g_ModIni, $g_FItem, 'Name', $g_FItem); SetupName
			$Answer = _Misc_MsgGUI(2, $g_ProgName, StringFormat(_GetTR($g_UI_Message, '0-L4'), $Nextstep, $Name), 2, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2')); => continue installation?
		EndIf
		If $Answer = 2 Then ; Continue
			_Misc_SetLang()
			_Tree_Populate(0)
			Local $Ignores = IniReadSection($g_UsrIni, 'IgnoredConnections'); user-ignored conflict/dependency rules
			If IsArray($Ignores) Then
				For $i = 1 To $Ignores[0][0]
					For $c = 1 To $g_Connections[0][0]
						If $Ignores[$i][1] <> $g_Connections[$c][1] Then ContinueLoop
						$g_Connections[$c][3] = 'W' & $g_Connections[$c][3]; user ignored it before, so ignore it again
						ExitLoop
					Next
				Next
			EndIf
			_Tree_Reload(0)
			If $Nextstep <> 'Au3Net' Then _Process_Gui_Create(2)
			GUICtrlSetState($g_UI_Button[0][1], $GUI_DISABLE)
			GUICtrlSetState($g_UI_Button[0][2], $GUI_DISABLE)
		ElseIf $Answer = 1 Then ; No
			$g_FItem = 1
			IniDelete($g_BWSIni, 'Faults'); remove old errors
			_ResetInstall()
			$g_Order = IniReadSection($g_BWSIni, 'Order'); Reread to be aware of the changes
			$g_CurrentOrder = 2
			GUICtrlSetState($g_UI_Seperate[2][0], $GUI_SHOW); show the fileselection-dialog
			AutoItSetOption('GUIOnEventMode', 0)
		EndIf
	Else
		GUICtrlSetState($g_UI_Button[0][1], $GUI_DISABLE)
		GUICtrlSetState($g_UI_Button[0][2], $GUI_DISABLE)
	EndIf
EndFunc   ;==>Au3GetVal

; ---------------------------------------------------------------------------------------------
; Generate the current list of exe's in the section-list
;	$p_Num ('s' = setup, 'c' = chapters)
;	Setups[0][0] = number of mod-setup-names found
;	if p_Num = 's' then
;		Setups[N][0] = mod-setup-names found (ex. 1pp)
;		Setups[N][1] = long mod name (ex. One Pixel Productions)
;		Setups[N][2] is not set
;	if p_Num = 'c' then
;		Setups[N][0] is not set
;		Setups[N][1] = mod-setup-names found (ex. 1pp)
;		Setups[N][2] = long mod name (ex. One Pixel Productions)
; ---------------------------------------------------------------------------------------------
Func _CreateList($p_Num = 's')
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _CreateList')
	If $p_Num = 's' Then; build setups list
		; search for mods and their names (with a fallback-version)
		Local $SectionNames = IniReadSectionNames($g_ModIni)
		Local $Setups[$SectionNames[0] + 1][3]
		$Setups[0][0] = $SectionNames[0]
		Local $File = FileRead($g_ModIni)
		Local $Array = StringRegExp($File, '(?i)\nName=.*\n', 3)
		If UBound($Array) = $SectionNames[0] Then
			For $a = 0 To UBound($Array) - 1
				$Setups[$a + 1][0] = StringLower($SectionNames[$a + 1])
				$Setups[$a + 1][1] = StringStripWS(StringTrimRight(StringTrimLeft($Array[$a], 6), 2), 2)
			Next
		Else; less 'Name=' lines than [section name]s
			ConsoleWrite('!Missing Name-definition in Mod.ini' & @CRLF)
			$Array = StringSplit(StringStripCR($File), @LF)
			For $a = 1 To $Array[0]; scan each line of the file ...
				If StringLeft($Array[$a], 1) = '[' Then; when we find a line that starts with a '[' bracket ...
					For $a = $a + 1 To $Array[0]; scan lines after it looking for the next '[' or 'Name=' ...
						If StringLeft($Array[$a], 1) = '[' Then; found '[' before 'Name=' - badly formatted section
							_PrintDebug('Improperly formatted mod ini file (missing Name): '&$g_ModIni&' at line '&$a, 1)
							Exit
						ElseIf StringLeft($Array[$a], 5) = 'Name=' Then; found 'Name=' first - correct format, continue
							ExitLoop
						EndIf
					Next
				EndIf
			Next
; following code is legacy and doesn't work - replaced by working code above
;			For $a = 1 To $Array[0]
;				If StringLeft($Array[$a], 1) = '[' Then
;					$Setups[0][0] = $Setups[0][0] + 1
;					If $Setups[0][0] > UBound($Setups) Or $Setups[0][0] > UBound($SectionNames) Then
;						_PrintDebug('Improperly formatted mod ini file: '&$g_ModIni&' at line '&$a, 1)
;						Exit
;					EndIf
;					$Setups[$Setups[0][0]][0] = StringLower($SectionNames[$Setups[0][0]])
;					For $a = $a To $Array[0]
;						If StringLeft($Array[$a], 5) = 'Name=' Then
;							$Setups[$Setups[0][0]][1] = StringStripWS(StringTrimLeft($Array[$a], 5), 2)
;							ExitLoop
;						EndIf
;					Next
;				EndIf
;			Next
		EndIf
	Else;If $p_Num = 'c' Then; build chapters list
		If Not IsArray($g_Setups) Then $g_Setups = _CreateList(); we need setups list for chapters list
		; ---------------------------------------------------------------------------------------------
		; Create an index of first characters and assign the number to begin with
		; ---------------------------------------------------------------------------------------------
		; TODO: replace this with _IniCreateIndex
		Local $Char, $Index[100][2]
		For $s = 1 To $g_Setups[0][0]
			$Char = StringLeft($g_Setups[$s][0], 1)
			If $Index[0][1] <> $Char Then
				$Index[0][0] += 1
				$Index[0][1] = $Char
				$Index[$Index[0][0]][0] = Asc(StringLower($Char))
				$Index[$Index[0][0]][1] = $s
			EndIf
		Next
		; ---------------------------------------------------------------------------------------------
		; loop through select.txt-array and if new setup is used...
		; ---------------------------------------------------------------------------------------------
		Local $Setups[5000][3], $OldSetup
		Local $Array = StringSplit(StringStripCR(FileRead($g_GConfDir & '\Select.txt')), @LF)
		For $a = 1 To $Array[0]
			If StringRegExp($Array[$a], '(?i)\A(CMD|ANN|GRP)') Then ContinueLoop
			Local $Split = StringSplit($Array[$a], ';')
			Local $SetupName = $Split[2]; setup
			If $SetupName <> $OldSetup Then
				$Setups[0][0] += 1
				$Setups[$Setups[0][0]][1] = $SetupName
				; ---------------------------------------------------------------------------------------------
				; ...use the index to start at a smart index-number
				; ---------------------------------------------------------------------------------------------
				Local $Char = Asc(StringLower(StringLeft($SetupName, 1))); asc-number for the first character
				For $i = 1 To $Index[0][0]
					If $Char = $Index[$i][0] Then
						ExitLoop
					ElseIf $Char < $Index[$i][0] Then
						$i -= 1
						ExitLoop
					EndIf
				Next
				For $g = $Index[$i][1] To $g_Setups[0][0]; start searching from assigned index-number
					If $g_Setups[$g][0] = $SetupName Then
						$Setups[$Setups[0][0]][2] = $g_Setups[$g][1]
						ExitLoop
					EndIf
				Next
				If $Setups[$Setups[0][0]][2] = '' Then ConsoleWrite('!' & $SetupName & ': Missing Name in Mod.ini' & @CRLF)
				$OldSetup = $SetupName
			Else
				ContinueLoop
			EndIf
		Next	
	EndIf
	ReDim $Setups[$Setups[0][0] + 1][3]
	If $p_Num = 's' Then _ArraySort($Setups, 0, 1)
	Return $Setups
EndFunc   ;==>_CreateList

; ---------------------------------------------------------------------------------------------
; Generate the current list of exe's in the section-list
; ---------------------------------------------------------------------------------------------
Func _GetCurrent()
	Local $Current = IniReadSection($g_UsrIni, 'Current')
	If @error Then
		Local $Current[1][2]
		$Current[0][0] = 0
	EndIf
	If $g_Flags[21] = '' Then Return $Current; BWS will not install BG1EE-mods and EET
	Local $Num = StringRegExpReplace($g_Flags[14], '(?i)\ABG|EE\z', '')
	Local $Return[$Current[0][0] + 1][2]
	For $c = 1 To $Current[0][0]
		If StringRegExp($g_Flags[20 + $Num], '(?i)(\A|\x7c)' & $Current[$c][0] & '(\z|\x7c)') Then; trim selection to BG1EE/BG2EE mods only
			$Return[0][0] += 1
			$Return[$Return[0][0]][0] = $Current[$c][0]
			$Return[$Return[0][0]][1] = $Current[$c][1]
		EndIf
	Next
	ReDim $Return[$Return[0][0] + 1][2]
	Return $Return
EndFunc   ;==>_GetCurrent

; ---------------------------------------------------------------------------------------------
; Gather all the information from single small mod-files and write them into the bigger ini-files
; ---------------------------------------------------------------------------------------------
Func _GetGlobalData($p_Game='')
	If $p_Game <> '' Then; Enable testing of this function or use defaults...
		_Misc_Set_GConfDir($p_Game)
	Else
		$p_Game=StringRegExpReplace($g_GConfDir, '\A.*\\', '')
	EndIf
	Local $GameLen=StringLen($p_Game)
	If $p_Game <> '' Then; Enable testing of this function or use defaults...
		_Misc_Set_GConfDir($p_Game)
	Else
		$p_Game=$g_Flags[14]
	EndIf
	If FileExists($g_GConfDir&'\Mod.ini') Then
		If IniRead($g_UsrIni, 'Options', 'RecreateFromGlobal', 1) = 0 Then Return; Stick with the current config to optionally speed up local client development/testing
		FileDelete($g_GConfDir&'\Mod*.ini')
		FileDelete($g_GConfDir&'\WeiDU*.ini')
	EndIf
	Local $Current = GUICtrlRead($g_UI_Seperate[0][0])+1 ; current tab number
	_Misc_ProgressGUI(_GetTR($g_UI_Message, '0-T2'), _GetTR($g_UI_Message, '0-L2')); => building dependencies-table
	GUISwitch($g_UI[0])
	; Get tokens (first letter) of games, should be BCIP (BG/CA/IWD/PST-games)
	Local $Array=_FileSearch($g_ProgDir&'\Config', '*')
	Local $Token, $GameToken=''; 'BCIP'
	For $a=1 to $Array[0]
		If StringRegExp($Array[$a], '(?i)\x2e|Global') Then ContinueLoop; ignore '.', '..' and Global folder
		$Token=StringLeft($Array[$a], 1)
		If Not StringInStr($GameToken, $Token) Then $GameToken&=$Token
	Next
	; Get mods used in Select.txt
	Local $Text=FileRead($g_GConfDir&'\Select.txt')
	$Text=StringRegExpReplace($Text, '(?i)(\A|\n)(DWN|MUC|STD|SUB)', '--')
	Local $Array=StringRegExp($Text, '--\x3b[^\x3b]*\x3b' , 3)
	Local $Mod, $LastMod, $Mods='|'
	For $a=0 to UBound($Array)-1
		$Mod=StringRegExpReplace($Array[$a], '\A.{3}|.\z', '')
		If $Mod=$LastMod Then ContinueLoop
		$Mods&=$Mod&'|'
		$LastMod=$Mod
	Next
	Local $Array=StringSplit($Mods, '|')
	_ArraySort($Array, 0, 1)
	GUICtrlSetData($g_UI_Interact[9][1], 5); set the progress
	GUICtrlSetData($g_UI_Static[9][2], '5 %')
	; Open file-handles
	If Not FileExists($g_GConfDir) Then DirCreate($g_GConfDir)
	Local $h_Mod=FileOpen($g_GConfDir&'\Mod.ini', 2)
	Local $Lang=StringSplit('EN|GE|RU', '|'); BWS user interface languages
	For $l=1 to $Lang[0]
		Assign('h_Mod_'&$Lang[$l], FileOpen($g_GConfDir&'\Mod-'&$Lang[$l]&'.ini', 1)); don't overwrite file, contains [Preselection]
		FileWrite(Eval('h_Mod_'&$Lang[$l]), @CRLF&@CRLF&'[Description]'&@CRLF)
	Next
	Local $LCodes[13]=[12, 'GE','EN','FR','PO','RU','IT','SP','CZ','KO','CH','JP','PR']
	For $l=1 to $LCodes[0]
		Assign('h_WeiDU_'&$LCodes[$l], FileOpen($g_GConfDir&'\WeiDU-'&$LCodes[$l]&'.ini', 2))
	Next
	; Copy/write content of files to different file-handles
	Local $Edit='', $LineType, $File, $Split, $Desc, $Key, $Value
	For $a=2 to $Array[0]
		GUICtrlSetData($g_UI_Interact[9][1], 5+($a * 95 / $Array[0])); set the progress
		If _MathCheckDiv($a, 10) = 2 Then GUICtrlSetData($g_UI_Static[9][2], Round(5+($a * 95 / $Array[0]), 0) & ' %')
		If $Array[$a]=$Array[$a-1] Then ContinueLoop
		$Text=FileRead($g_ProgDir&'\Config\Global\'&$Array[$a]&'.ini')
		If @error Then ConsoleWrite($Array[$a]&' not found'&@CRLF)
		$Text=StringSplit(StringStripCR($Text), @LF)
		For $t=1 to $Text[0]
			$LineType=StringLeft($Text[$t], 1)
			If $LineType = '@' Then; translations don't need special attention
			ElseIf $LineType = '[' Then; that's a section -> adjust to different handle
				$File=StringReplace(StringRegExpReplace($Text[$t], '\A(\s|)\x5b|\x5d(|\s)\z', ''), '-', '_')
				If $File='Description' Then; special handling for mods descriptions
					While 1
						$t+=1
						If $t>$Text[0] Or StringLeft($Text[$t], 1) = '[' Then ExitLoop; end of file or beginning of a different section
						$Desc=StringRegExpReplace($Text[$t], '\A[^=]*=', ''); strip any prefix from the actual text
						If @extended Then
							If StringRegExp($Text[$t], '\A[^=]*_') Then; exception found (e.g. BG2EE_ prefix)
								If StringLeft($Text[$t], $GameLen+1) = $p_Game&'_' Then; fitting for this game
									$Split=StringInStr($Text[$t], '=')
									$Key=StringMid($Text[$t], $GameLen+2, $Split-$GameLen-2)
									If $Desc='' Then $Desc=' '
									$Edit&=$Key&'|Description|'&$Array[$a]&'|'&StringReplace($Desc, '|', '\x7c')&'||'; save for later (temporarily replace vertical bars with \x7c because they have overloaded meaning here -- in Description section they represent newlines, but we are also using vertical bars here to represent key/value associations)
								EndIf
							EndIf
							FileWrite(Eval('h_Mod_'&StringMid($Text[$t], 5, 2)), $Array[$a]&'='&$Desc&@CRLF)
						EndIf
					WEnd
					$t-=1
				Else
					FileWrite(Eval('h_'&$File), '['&$Array[$a]&']'&@CRLF)
				EndIf
				ContinueLoop
			ElseIf StringInStr($GameToken, $LineType) Then; this could be some line with a special adjustment for certain games (e.g., BG2EE_ prefix)
				If StringRegExp($Text[$t], '\A[^=]*_') Then; found
					If StringLeft($Text[$t], $GameLen) = $p_Game Then; fitting for this game
						$Split=StringInStr($Text[$t], '=')
						$Key=StringMid($Text[$t], $GameLen+2, $Split-$GameLen-2)
						$Value=StringRegExpReplace($Text[$t], '\A[^=]*=', '')
						If $Value='' Then $Value=' '
						$Edit&=StringReplace($File, '_', '-')&'|'&$Array[$a]&'|'&$Key&'|'&$Value&'||'; save for later
					EndIf
					ContinueLoop
				EndIf
			EndIf
			FileWrite(Eval('h_'&$File), $Text[$t]&@CRLF); write current line
		Next
	Next
	; Close file handles for Mod-lang.ini files and WeiDU-lang.ini files
	FileClose($h_Mod)
	For $l=1 to $Lang[0]
		FileClose(Eval('h_Mod_'&$Lang[$l]))
	Next
	For $l=1 to $LCodes[0]
		FileClose(Eval('h_WeiDU_'&$LCodes[$l]))
	Next
	; Handle exceptions (apply any prefix-overrides like BG2EE_Type=E or BWP_Mod-EN=... that match current game type)
	$Edit=StringSplit($Edit, '||', 1)
	For $e=1 to $Edit[0]-1
		$Split=StringSplit($Edit[$e], '|')
		If $Split[4]=' ' Then
			IniDelete($g_GConfDir&'\'&$Split[1]&'.ini', $Split[2], $Split[3])
		Else
			If $Split[2] = 'Description' Then $Split[4]=StringReplace($Split[4], '\x7c', '|'); restore vertical bars we replaced earlier with \x7c
			IniWrite($g_GConfDir&'\'&$Split[1]&'.ini', $Split[2], $Split[3], $Split[4])
		EndIf
	Next
	; Preselections
	Local $ReadSection, $Array[3]=[2, 'Global', $p_Game]
	For $a=1 to $Array[0]
		$ReadSection=IniReadSection($g_ProgDir&'\Config\Preselect.ini', $Array[$a])
		If @error Then ContinueLoop
		For $r=1 to $ReadSection[0][0]
			For $l=1 to $Lang[0]
				If StringRight($ReadSection[$r][0], 2) = $Lang[$l] Then IniWrite($g_GConfDir&'\Mod-'&$Lang[$l]&'.ini', 'Preselect', StringLeft($ReadSection[$r][0], 2), $ReadSection[$r][1])
			Next
		Next
	Next
	_Misc_SetTab($Current)
EndFunc    ;==>_GetGlobalData

; ---------------------------------------------------------------------------------------------
; Well, print a debug message. :D
; ---------------------------------------------------------------------------------------------
Func _PrintDebug($p_String, $p_Show = 0)
	ConsoleWrite($p_String & @CR)
	If $p_Show = 1 Then MsgBox(64, $g_ProgName, $p_String, 60) ; flags, title, text, timeout in seconds
EndFunc   ;==>_PrintDebug

; ---------------------------------------------------------------------------------------------
; Set all values to start a new install
; ---------------------------------------------------------------------------------------------
Func _ResetInstall($p_DeletePause = 1)
	Local $OldLogDir = $g_LogDir
	IniWrite($g_BWSIni, 'Order', 'Au3Select', '1'); Enable the start of the selection-gui
	IniWrite($g_BWSIni, 'Order', 'Au3PrepInst', '1'); remove cds
	IniWrite($g_BWSIni, 'Order', 'Au3CleanInst', '1'); backup
	IniWrite($g_BWSIni, 'Order', 'Au3Net', '1'); download
	IniWrite($g_BWSIni, 'Order', 'Au3NetFix', '1'); post-download-processess
	IniWrite($g_BWSIni, 'Order', 'Au3NetTest', '1'); download test
	IniWrite($g_BWSIni, 'Order', 'Au3Extract', '1'); extract
	IniWrite($g_BWSIni, 'Order', 'Au3ExFix', '1'); extract
	IniWrite($g_BWSIni, 'Order', 'Au3ExTest', '1'); extract test
	IniWrite($g_BWSIni, 'Order', 'Au3RunFix', '1'); fixes and patches
	IniWrite($g_BWSIni, 'Order', 'Au3Install', '1'); install
	IniWrite($g_BWSIni, 'Options', 'Start', '1')
	FileMove($g_LogDir & '\*.txt', $g_LogDir & '\Bak\', 9); save old logs
	If DirGetSize($g_LogDir & '\Bak') > 0 Then
		$OldLogDir = $g_LogDir & '\Bak-' & @YEAR & @MON & @MDAY & @HOUR & @MIN
		DirMove($g_LogDir & '\Bak', $OldLogDir)
	Else
		DirRemove($g_LogDir & '\Bak')
	EndIf
	IniDelete($g_UsrIni, 'RemovedFromCurrent'); delete old failures-mesages
	If $p_DeletePause = 1 Then IniDelete($g_UsrIni, 'Pause'); delete old pauses
	Return $OldLogDir
EndFunc   ;==>_ResetInstall
