AutoItSetOption('WinTitleMatchMode', 2); set a more flexible way to search for windows
AutoItSetOption('GUIResizeMode', 1); resize and reposition GUI-elements according to new window size
AutoItSetOption('GUICloseOnESC', 0);  don't send the $GUI_EVENT_CLOSE message when ESC is pressed
AutoItSetOption('TrayIconDebug', 1); shows the current script line in the tray icon tip to help debugging
AutoItSetOption('GUIOnEventMode', 1); disable OnEvent functions notifications
AutoItSetOption('OnExitFunc','Au3Exit'); sets the name of the function called when AutoIt exits

TraySetIcon (@ScriptDir&'\Pics\BWS.ico'); sets the tray-icon

Global $g_BaseDir = StringLeft(@ScriptDir, StringInStr(@ScriptDir, '\', 1, -1)-1), $g_GConfDir, $g_GameDir, $g_ProgName = 'BiG World Setup'
Global $g_ProgDir = $g_BaseDir & '\BiG World Setup', $g_LogDir=$g_ProgDir&'\Logs', $g_DownDir = $g_BaseDir & '\BiG World Downloads'
Global $g_BWSIni = $g_ProgDir & '\Config\Setup.ini', $g_MODIni, $g_UsrIni = $g_ProgDir & '\Config\User.ini'
Global $g_ATrans = StringSplit(IniRead($g_BWSIni, 'Options', 'AppLang', 'EN|GE'), '|'), $g_ATNum = 1, $g_MLang; available translations and mod translations
Global $g_UI[5], $g_UI_Static[17][20], $g_UI_Button[17][20], $g_UI_Seperate[17][10], $g_UI_Interact[17][20], $g_UI_Menu[10][50]
Global $g_Search[5], $g_Flags[24] = [1], $g_UI_Handle[10], $g_Setups

#include'Includes\01_UDF1.au3'
#include'Includes\05_Basics.au3'

$g_UI[0] = GuiCreate($g_ProgName, 500, 290, -1, -1, $WS_MINIMIZEBOX + $WS_MAXIMIZEBOX + $WS_CAPTION + $WS_POPUP + $WS_SYSMENU + $WS_SIZEBOX)

GUISetFont(8, 400, 0, 'MS Sans Serif')
GUISetOnEvent($GUI_EVENT_CLOSE, "_Check_OnEvent")
GUISetIcon (@ScriptDir&'\Pics\BWS.ico', 0); sets the GUIs icon

$g_UI_Static[1][1] = GuiCtrlCreateLabel("Mod", 10, 10, 480, 20, $SS_CENTER+$SS_CENTERIMAGE)
GUICtrlSetFont(-1, 10, 800, 0, 'MS Sans Serif')
GUICtrlSetResizing(-1, 512+32); => top, no height-change
$g_UI_Interact[1][6] = GUICtrlCreateInput('', 10, 40, 480, 20)
GUICtrlSetResizing(-1, 512+32); => top, no height-change
$g_UI_Interact[1][1] = GuiCtrlCreateProgress(10, 65, 480, 10)
GUICtrlSetResizing(-1, 512+32); => top, no height-change
GUICtrlSetState(-1, $GUI_HIDE)
$g_UI_Interact[1][2] = GuiCtrlCreateEdit("", 10, 80, 480, 140)
_GUICtrlEdit_SetLimitText($g_UI_Interact[1][2], 64000)
GUICtrlSetResizing(-1, 2+4+32+64); => left,right, top, bottom
$g_UI_Interact[1][3] = GUICtrlCreateCombo("", 10, 230, 150, 20)
GUICtrlSetResizing(-1, 512+64); => bottom, no height-change
GUICtrlSetOnEvent(-1, '_Check_OnEvent')
$g_UI_Interact[1][4] = GUICtrlCreateCombo("", 175, 230, 150, 20)
GUICtrlSetResizing(-1, 512+64); => bottom, no height-change
GUICtrlSetOnEvent(-1, '_Check_OnEvent')
$g_UI_Interact[1][5] = GuiCtrlCreateCheckbox("Only update existing entries", 340, 230, 150, 20)
GUICtrlSetResizing(-1, 512+64); => bottom, no height-change
GUICtrlSetOnEvent(-1, '_Check_OnEvent')
$g_UI_Button[1][1] = GuiCtrlCreateButton("Start", 10, 255, 150, 20)
GUICtrlSetResizing(-1, 512+64); => bottom, no height-change
GUICtrlSetOnEvent(-1, '_Check_OnEvent')
$g_UI_Button[1][2] = GuiCtrlCreateButton("Export", 175, 255, 150, 20)
GUICtrlSetResizing(-1, 512+64); => bottom, no height-change
GUICtrlSetOnEvent(-1, '_Check_OnEvent')
$g_UI_Button[1][3] = GuiCtrlCreateButton("Exit", 340, 255, 150, 20)
GUICtrlSetResizing(-1, 512+64); => bottom, no height-change
GUICtrlSetOnEvent(-1, '_Check_OnEvent')

$g_GameList=_GetGameList()
GUICtrlSetData($g_UI_Interact[1][3], $g_GameList[0][1], $g_GameList[1][1]); => installation method
GUICtrlSetData($g_UI_Interact[1][4], $g_GameList[0][1], $g_GameList[1][1]); => installation method
$g_Flags[1]=$g_GameList[1][1]
$g_Flags[2]=$g_GameList[1][1]

GuiSetState()

Local $Start = TimerInit()

GUICtrlSetState($g_UI_Interact[1][6], $GUI_SHOW)


While 1
	While $g_Flags[4] = 0
		Sleep(10)
	WEnd
	GUICtrlSetState($g_UI_Interact[1][3], $GUI_DISABLE)
	GUICtrlSetState($g_UI_Interact[1][4], $GUI_DISABLE)
	$g_Setups=GUICtrlRead($g_UI_Interact[1][6])
	If $g_Setups='*' Then
		If $g_Flags[3] Then
			$g_Setups=IniReadSectionNames('Config\'&$g_Flags[2]&'\Mod.ini')
		Else
			$g_Setups=IniReadSectionNames('Config\'&$g_Flags[1]&'\Mod.ini')
		EndIf		
	Else
		$g_Setups=StringSplit($g_Setups, '|')
	EndIf	
	For $s=1 to $g_Setups[0]
		While $g_Flags[4] = 0
			Sleep(10)
		WEnd
		If _CopyMod($g_Setups[$s]) Then _CheckScroll($g_Setups[$s])
	Next
	_CheckScroll('========================================')
	$g_Flags[4]=0
	GUICtrlSetState($g_UI_Interact[1][3], $GUI_ENABLE)
	GUICtrlSetState($g_UI_Interact[1][4], $GUI_ENABLE)
	GUICtrlSetData($g_UI_Button[1][1], 'Start')
WEnd	
Exit

Func _CopyMod($p_Mod)
	Local $CopyFrom=$g_Flags[1]
	Local $CopyTo[1]=[$g_Flags[2]]
	$Def=IniReadSection('Config\'&$CopyFrom&'\Mod.ini', $p_Mod)
	If @error Then Return 0
	For $Game in $CopyTo
		IniWriteSection('Config\'&$Game&'\Mod.ini', $p_Mod, $Def)
	Next
	Local $Tra[4]=[3, 'EN', 'GE', 'RU']
	For $t=0 To $Tra[0]
		$Desc=IniRead('Config\'&$CopyFrom&'\Mod-'&$Tra[$t]&'.ini', 'Description', $p_Mod, '')
		If $Desc <> '' Then
			For $Game in $CopyTo
				IniWrite('Config\'&$Game&'\Mod-'&$Tra[$t]&'.ini', 'Description', $p_Mod, $Desc)
			Next
		EndIf
	Next
	$Lang=_IniRead($Def, 'Tra', '')
	$Tra=StringRegExp($Lang, '[[:upper:]]{2}', 3)
	For $t=0 To UBound($Tra)-1
		If $Tra[$t] = '--' Then ContinueLoop
		$Desc=IniReadSection('Config\'&$CopyFrom&'\WEiDU-'&$Tra[$t]&'.ini', $p_Mod)
		If Not @error Then
			For $Game in $CopyTo
				IniWriteSection('Config\'&$Game&'\WeiDU-'&$Tra[$t]&'.ini', $p_Mod, $Desc)
			Next
		EndIf
	Next
	Return 1
EndFunc

Func _ListSelect()
	Local $Return=''
	$Array=StringSplit(StringStripCR(FileRead('Config\'&$g_Flags[1]&'\Select.txt')), @LF)
	For $a=1 to $Array[0]
		For $g=1 to $g_Setups[0]
			If StringInStr($Array[$a], ';'&$g_Setups[$g]&';') Then 
				$Return&=@CRLF&$Array[$a]
				ExitLoop
			EndIf
		Next
	Next
	ClipPut($Return)
	_CheckScroll('Matching Select-lines was exported to clipboard.')
EndFunc

	

; ---------------------------------------------------------------------------------------------
; OnEvent actions for the gui
; ---------------------------------------------------------------------------------------------
Func _Check_OnEvent()
	Switch @GUI_CtrlId
		Case $GUI_EVENT_CLOSE
			Exit
		Case $g_UI_Interact[1][3]
			$g_Flags[1]=GUICtrlRead($g_UI_Interact[1][3]); Copyfrom
		Case $g_UI_Interact[1][4]
			$g_Flags[2]=GUICtrlRead($g_UI_Interact[1][4]); Copyto
		Case $g_UI_Interact[1][5]
			$g_Flags[3]=GUICtrlRead($g_UI_Interact[1][5]); Updateonly
		Case $g_UI_Button[1][1]
			If $g_Flags[1]=$g_Flags[2] Then
				_CheckScroll("Source and Target can't be the same.")
				Return
			ElseIf GUICtrlRead($g_UI_Interact[1][6]) = '' Then
				_CheckScroll("Specify some mods first.")
				_CheckScroll("Use a vertical line to separate mods (1pp|rr).")
				_CheckScroll("An asterix (*) will copy all.")
				Return
			EndIf
;~ 			_WorkMods()
			If $g_Flags[4]=0 Then; Start/Stop
				GUICtrlSetData($g_UI_Button[1][1], 'Pause')
				$g_Flags[4]=1
			Else
				GUICtrlSetData($g_UI_Button[1][1], 'Start')
				$g_Flags[4]=0
			EndIf
		Case $g_UI_Button[1][2]; Export
			If $g_Flags[4] = 0 Then 
				If IsArray($g_Setups) Then 
					_ListSelect()
				Else
					_CheckScroll('To export matching select-lines to your clipboard,')
					_CheckScroll('select your options and start the script once.')
				EndIf
			EndIf	
		Case $g_UI_Button[1][3]; Exit
			Exit
	EndSwitch
EndFunc   ;==>__Check_OnEvent

Func _CheckScroll($p_Text)
	Local $Num=0
	_GUICtrlEdit_AppendText($g_UI_Interact[1][2], $p_Text & @CRLF)
	_GUICtrlEdit_LineScroll($g_UI_Interact[1][2], 0, 1+$Num)
EndFunc				

; ---------------------------------------------------------------------------------------------
; Well, print a debug message. :D
; ---------------------------------------------------------------------------------------------
Func _PrintDebug($p_String, $p_Show = 0)
	ConsoleWrite($p_String & @CR)
	If $p_Show = 1 Then MsgBox(64, $g_ProgName, $p_String)
EndFunc   ;==>_PrintDebug

Exit