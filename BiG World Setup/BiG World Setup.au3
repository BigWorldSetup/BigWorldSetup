AutoItSetOption('WinTitleMatchMode', 2); set a more flexible way to search for windows
AutoItSetOption('GUIResizeMode', 1); resize and reposition GUI-elements according to new window size
AutoItSetOption('GUICloseOnESC', 0);  don't send the $GUI_EVENT_CLOSE message when ESC is pressed
AutoItSetOption('TrayIconDebug', 1); shows the current script line in the tray icon tip to help debugging
AutoItSetOption('GUIOnEventMode', 0); disable OnEvent functions notifications
AutoItSetOption('OnExitFunc','Au3Exit'); sets the name of the function called when AutoIt exits

TraySetIcon (@ScriptDir&'\Pics\BWS.ico'); sets the tray-icon

#Region Global vars
; Global are named with a $g_ , parameters with a $p_ . Normal/Local variables don't have a prefix.
; files and folders
Global $g_BaseDir = StringLeft(@ScriptDir, StringInStr(@ScriptDir, '\', 1, -1)-1), $g_GConfDir, $g_GameDir, $g_ProgName = 'BiG World Setup'
Global $g_ProgDir = $g_BaseDir & '\BiG World Setup', $g_LogDir=$g_ProgDir&'\Logs', $g_DownDir = $g_BaseDir & '\BiG World Downloads'
Global $g_BG1Dir, $g_BG2Dir, $g_BGEEDIR, $g_IWD1Dir, $g_IWD2Dir, $g_PSTDir, $g_RemovedDir, $g_BackupDir, $g_LogFile = $g_LogDir & '\BiG World Debug.txt'
Global $g_BWSIni = $g_ProgDir & '\Config\Setup.ini', $g_MODIni, $g_UsrIni = $g_ProgDir & '\Config\User.ini'
; select-gui vars
Global $g_Compilation='R', $g_LimitedSelection = 0, $g_Tags, $g_ActiveConnections[1], $g_Groups
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
Global $g_Search[5], $g_Flags[24] = [1], $g_UI_Handle[10]
Global $g_TRAIni = $g_ProgDir & '\Config\Translation-'&$g_ATrans[$g_ATNum]&'.ini', $g_UI_Message = IniReadSection($g_TRAIni, 'UI-Runtime')
; g_Flags => 1=w: continue without link checking; 2=w: update links; 3=mod language-string; 4=w: mc-disabled 5=admin-tokens short/Enable Pause-Resume
; 6=admin-tokens long/overwitten text by pause, 7=current tip-handle, 8=current tab is advsel, 9=window is locked, 10=Rebuild when leaving first screens/tab to go back from admin-tabs
; 11=back is pressed, 12=forward is pressed, 13=real exit, 14=current selected install method, 15=greet-picture is visible
; 16=admin-lv has focus/treeicon clicked, 17=treelabel clicked, 18=beep, 19=cmd-started, 20=w: selection-is-higer-than-your-preselection
; 21=use old sorting format, 22=wscreen ID, 23=download-button-number/unsolved dependencies
; g_UI_Handle => 0=adv. TreeView, 1=dep. ListView, 2=mod ListView, 3= 4/5=dep admin ListViews, 6/7=comp Listviews, 8=select admin
; g_UI_Menu[0] => 0=, 1=used themes in advmenu, 2=number of themes in adv-menus, 3=number of themes+groups in adv-menus, 4=mod, depend and select-contextmenu, 5=, 6-9=depend-context-menu
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
EndFunc    ;==>Au3Exit

; ---------------------------------------------------------------------------------------------
; Get the core-settings for the current installation
; ---------------------------------------------------------------------------------------------
Func Au3GetVal($p_Num = 0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling Au3GetVal')
	$g_Order = IniReadSection($g_BWSIni, 'Order'); reload this to get the new selected functions
	$ReadSection = IniReadSection($g_UsrIni, 'Options')
	$g_Flags[14]=_IniRead($ReadSection, 'AppType', ''); need correct gametype
	If StringRegExp($g_Flags[14], 'BWS|BWP') Then
		$g_GConfDir = $g_ProgDir & '\Config\BWP'
		_Test_GetGamePath('BG1')
		_Test_GetGamePath('BG2')
		$g_GameDir = $g_BG2Dir
	Else
		$g_GConfDir = $g_ProgDir & '\Config\'&$g_Flags[14]
		_Test_GetGamePath($g_Flags[14])
		$g_GameDir = Eval('g_'&$g_Flags[14]&'Dir')
	EndIf
	$g_ModIni = $g_GConfDir & '\Mod.ini'
	$g_Setups=_CreateList('s')
	$g_DownDir = _IniRead($ReadSection, 'Download', '')
	$g_GUIFold = _IniRead($ReadSection, 'UnFold', '1')
	$g_Flags[18] = _IniRead($ReadSection, 'Beep', 0)
	$g_CurrentPackages = IniReadSection($g_UsrIni, 'Current')
	AutoItSetOption('GUIOnEventMode', 1)
	If IniRead($g_BWSIni, 'Order', 'Au3Select', 1) = 0 And GUICtrlRead($g_UI_Button[0][1]) = '' Then; this is a restart > show the question-dialog
		_Misc_SetLang()
		GUICtrlSetState($g_UI_Seperate[8][0], $GUI_SHOW)
		For $o = 1 To $g_Order[0][0]
			If $g_Order[$o][1] = '0' Then ContinueLoop
			If StringRegExp('Au3BuildGui,Au3Detect,Au3GetVal,Au3ResetEdit', '(\A|\x2c)'&$g_Order[$o][0]&'(\z|\x2c)') Then ContinueLoop
			$Nextstep=$g_Order[$o][0]
			ExitLoop
		Next
		If StringRegExp($g_FItem, '\A\d{1,}\z') Then
			$Array = StringSplit(StringStripCR(FileRead($g_GConfDir&'\Select.txt')), @LF)
			If _IniRead($ReadSection, 'GroupInstall', 0) =  1 Then $Array = _Install_ModifyForGroupInstall($Array); always install in groups
			$a=$g_FItem
			While StringRegExp($Array[$a], '(?i)\A(CMD|ANN|DWN|GRP)') And $a<$Array[0]
				$a+=1
			WEnd
			$Split=StringSplit($Array[$a], ';')
			$Name=$Split[2]
			$Name=IniRead($g_MODIni, $Name, 'Name', $Name); SetupName
			$Comp=$Split[3]; CompNumber
			$Answer = _Misc_MsgGUI(2, $g_ProgName, StringFormat(_GetTR($g_UI_Message, '0-L4'), $Nextstep, $Name&', #'&$Comp), 2, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2')); => continue installation?
		Else
			$Name=IniRead($g_MODIni, $g_FItem, 'Name', $g_FItem); SetupName
			$Answer = _Misc_MsgGUI(2, $g_ProgName, StringFormat(_GetTR($g_UI_Message, '0-L4'), $Nextstep, $Name), 2, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2')); => continue installation?
		EndIf
		If $Answer = 2 Then;Continue
			_Misc_SetLang()
			_Tree_Populate(0)
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
; ---------------------------------------------------------------------------------------------
Func _CreateList($p_Num='s'); $a=Type ('s' = setup, 'c' = chapters)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _CreateList')
	If $p_Num='c' Then; chapters
; ---------------------------------------------------------------------------------------------
; Create an index of first characters and assign the number to begin with
; ---------------------------------------------------------------------------------------------
		If Not IsArray($g_Setups) Then $g_Setups=_CreateList()
		Local $Index[100][2]
		For $s = 1 To $g_Setups[0][0]
			$Test=StringLeft($g_Setups[$s][0], 1)
			If $Index[0][1] <> $Test Then
				$Index[0][0]+=1
				$Index[0][1]=$Test
				$Index[$Index[0][0]][0] = Asc(StringLower($Test))
				$Index[$Index[0][0]][1] = $s
			EndIf
		Next
; ---------------------------------------------------------------------------------------------
; loop through select.txt-array and if new setup is used...
; ---------------------------------------------------------------------------------------------
		Local $Setups[1000][3], $OldSetup
		Local $Array=StringSplit(StringStripCR(FileRead($g_GConfDir&'\Select.txt')), @LF)
		For $a=1 to $Array[0]
			If StringRegExp($Array[$a], '(?i)\A(CMD|ANN|GRP)') Then ContinueLoop
			$Split=StringSplit($Array[$a], ';')
			$Test=$Split[2]; setup
			If $Test <> $OldSetup Then
				$Setups[0][0]+=1
				$Setups[$Setups[0][0]][1]=$Test; setup
; ---------------------------------------------------------------------------------------------
; ...use the index to start at a smart index-number
; ---------------------------------------------------------------------------------------------
				$Num=Asc(StringLower(StringLeft($Test, 1))); asc-number for the character
				For $i=1 to $Index[0][0]
					If $Num = $Index[$i][0] Then
						ExitLoop
					ElseIf $Num < $Index[$i][0]Then
						$i-=1
						ExitLoop
					EndIf
				Next
				For $g = $Index[$i][1] To $g_Setups[0][0]; start searching from assigned index-number
					If $g_Setups[$g][0] = $Test Then
						$Setups[$Setups[0][0]][2]=$g_Setups[$g][1]
						ExitLoop
					EndIf
				Next
				If $Setups[$Setups[0][0]][2] = '' Then ConsoleWrite('!'&$Test&': Missing Name in Mod.ini' & @CRLF)
				$OldSetup = $Test
			Else
				ContinueLoop
			EndIf
		Next
	Else; Search for mods and their names (with a fallback-version)
		$SectionNames=IniReadSectionNames($g_ModIni)
		Local $Setups[$SectionNames[0]+1][3]
		$Setups[0][0] = $SectionNames[0]
		$File=FileRead($g_ModIni)
		$Array=StringRegExp($File, '(?i)\nName=.*\n', 3)
		If UBound($Array) = $SectionNames[0] Then
			for $a=0 to UBound($Array)-1
				$Setups[$a+1][0] = $SectionNames[$a+1]
				$Setups[$a+1][1] = StringStripWS(StringTrimRight(StringTrimLeft($Array[$a], 6), 2), 2)
			Next
		Else
			ConsoleWrite('!Missing Name-definition in Mod.ini'  & @CRLF)
			$Array=StringSplit(StringStripCR($File), @LF)
			For $a=1 to $Array[0]
				If StringLeft($Array[$a], 1) = '[' Then
					$Setups[0][0] = $Setups[0][0] + 1
					$Setups[$Setups[0][0]][0] = $SectionNames[$Setups[0][0]]
					For $a=$a to $Array[0]
						If StringLeft($Array[$a], 5) = 'Name=' Then
							$Setups[$Setups[0][0]][1] = StringStripWS(StringTrimLeft($Array[$a], 5), 2)
							ExitLoop
						EndIf
					Next
				EndIf
			Next
		EndIf
	EndIf
	ReDim $Setups[$Setups[0][0] + 1][3]
	If $p_Num = 's' Then _ArraySort($Setups, 0, 1)
	Return $Setups
EndFunc   ;==>_CreateList

; ---------------------------------------------------------------------------------------------
; Well, print a debug message. :D
; ---------------------------------------------------------------------------------------------
Func _PrintDebug($p_String, $p_Show = 0)
	ConsoleWrite($p_String & @CR)
	If $p_Show = 1 Then MsgBox(64, $g_ProgName, $p_String)
EndFunc   ;==>_PrintDebug

; ---------------------------------------------------------------------------------------------
; Set all values to start a new install
; ---------------------------------------------------------------------------------------------
Func _ResetInstall($p_DeletePause=1)
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
		DirMove($g_LogDir & '\Bak', $g_LogDir & '\Bak-'& @YEAR & @MON & @MDAY & @HOUR & @MIN)
	Else
		DirRemove($g_LogDir & '\Bak')
	EndIf
	IniDelete($g_UsrIni, 'RemovedFromCurrent'); delete old failures-mesages
	If $p_DeletePause = 1 Then IniDelete($g_UsrIni, 'Pause'); delete old pauses
EndFunc   ;==>_ResetInstall