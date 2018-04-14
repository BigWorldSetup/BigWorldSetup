#include-once

Func _Misc_Search($p_ID, $p_String, $p_Occurrence = 1)
	Local $Handle = GUICtrlGetHandle($p_ID)
	GUICtrlSetState($p_ID, $GUI_FOCUS)
	Local $iPos = StringInStr(GUICtrlRead($p_ID), $p_String, 0, $p_Occurrence)
	_GUICtrlEdit_SetSel($Handle, $iPos - 1, ($iPos + StringLen($p_String)) - 1)
	_GUICtrlEdit_Scroll($Handle, $__EDITCONSTANT_SB_SCROLLCARET)
EndFunc   ;==>_Misc_Search

Func _Misc_Set_GConfDir($p_GameType)
	$g_GConfDir = $g_ProgDir & '\Config\'&$p_GameType
	If StringRegExp($p_GameType, 'BG[1-2]EE') Then
		$g_ConnectionsConfDir = $g_ProgDir&'\Config\BWP'; make BG1EE and BG2EE use BWP Game.ini for Connections rules
	Else
		$g_ConnectionsConfDir = $g_GConfDir
	EndIf
EndFunc   ;==>_Misc_SetGConfDir

; ---------------------------------------------------------------------------------------------
; Displays the about-screen
; ---------------------------------------------------------------------------------------------
Func _Misc_AboutGUI()
	Local $String = 'Big World Setup', $Version
	Local $Current = GUICtrlRead($g_UI_Seperate[0][0]) + 1
	; ---------------------------------------------------------------------------------------------
	; Fetch the version number
	; ---------------------------------------------------------------------------------------------
	Local $Array = StringSplit(StringStripCR(FileRead($g_BaseDir & '\Documentation\Changelog.txt')), @LF)
	For $a = $Array[0] To 1 Step -1
		If StringRegExp($Array[$a], '\A\d{8,}') Then
			$Version = StringRegExp($Array[$a], '\A\d{8,}', 3)
			$Version = $Version[0]
			ExitLoop
		EndIf
	Next
	If $Version <> '' Then $String &= ' (' & $Version & ')'
	; ---------------------------------------------------------------------------------------------
	; And action
	; ---------------------------------------------------------------------------------------------
	GUICtrlSetData($g_UI_Static[7][1], $String)
	_Misc_SetTab(7)
	Local $OldMode = AutoItSetOption('GUIOnEventMode')
	If $OldMode Then AutoItSetOption('GUIOnEventMode', 0)
	Local $msg, $Answer = 0
	While $Answer = 0
		$msg = GUIGetMsg()
		If $msg = $g_UI_Button[0][1] Then $Answer = 1
		If $msg = $g_UI_Button[0][2] Then $Answer = 1
		If $msg = $g_UI_Button[0][3] Then $Answer = 1
		If $msg = $g_UI_Static[0][3] Then $Answer = 1
		Sleep(10)
	WEnd
	If $OldMode Then AutoItSetOption('GUIOnEventMode', $OldMode)
	_Misc_SetTab($Current)
EndFunc   ;==>_Misc_AboutGUI

; ---------------------------------------------------------------------------------------------
; Calculate button positions
; ---------------------------------------------------------------------------------------------
Func _Misc_CalcButtonPos($p_Num, $p_Button)
	Local $Return[4]
	Local $Pos = ControlGetPos($g_UI[0], '', $g_UI_Seperate[8][1])
	If $p_Button = 1 Then
		$Return[2] = $Pos[2] - 40
	ElseIf $p_Button = 2 Then
		$Return[2] = Round(($Pos[2] - 60) / 2, 0)
	ElseIf $p_Button = 3 Then
		$Return[2] = Round(($Pos[2] - 70) / 3, 0)
	EndIf
	If $p_Num = 1 Then
		$Return[0] = $Pos[0] + 20
	ElseIf $p_Num = 2 And $p_Button = 2 Then
		$Return[0] = $Pos[0] + 40 + $Return[2]
	ElseIf $p_Num = 2 And $p_Button = 3 Then
		$Return[0] = $Pos[0] + 35 + $Return[2]
	ElseIf $p_Num = 3 Then
		$Return[0] = $Pos[0] + 50 + (2 * $Return[2])
	EndIf
	$Return[1] = $Pos[1] + $Pos[3] - Round(20 * $Pos[1] / 240, 0) - 25
	$Return[3] = Round(20 * $Pos[3] / 240, 0)
	Return $Return
EndFunc   ;==>_Misc_CalcButtonPos

; ---------------------------------------------------------------------------------------------
; Delete the old menu-entries and create new ones
; ---------------------------------------------------------------------------------------------
Func _Misc_CreateMenu()
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Misc_CreateMenu')
	For $m = 2 To 4
		For $g = 3 To $g_Tags[0][0]
			If Not StringInStr($g_UI_Menu[0][1], '|' & $g_Tags[$g][0] & '|') Then ContinueLoop
			$g_UI_Menu[$m][$g] = GUICtrlCreateMenuItem($g_Tags[$g][1], $g_UI_Menu[$m][0])
		Next
		For $g = 2 + $g_UI_Menu[0][2] To $g_Tags[0][0]
			$g_UI_Menu[$m][$g] = GUICtrlCreateMenuItem($g_Tags[$g][1], $g_UI_Menu[$m][1])
		Next
	Next
EndFunc   ;==>_Misc_CreateMenu

; ---------------------------------------------------------------------------------------------
; Add or remove a LS-item to/from the selection
; ---------------------------------------------------------------------------------------------
Func _Misc_LS_EditItem($p_Num, $p_LV = 1)
	Local $Selected = StringSplit(ControlListView($g_Ui[0], '', $g_UI_Interact[15][$p_LV], 'GetSelected', 1), '|')
	Local $Total = ControlListView($g_Ui[0], '', $g_UI_Interact[15][2], 'GetItemCount')
	Local $ID1, $Text1, $Found, $ID2, $Text2
	For $s = 1 To $Selected[0]
		$ID1 = _GUICtrlListView_GetItemParam($g_UI_Interact[15][$p_LV], $Selected[$s])
		$Text1 = GUICtrlRead($ID1)
		$Found = 0
		For $t = 1 To $Total
			$ID2 = _GUICtrlListView_GetItemParam($g_UI_Interact[15][2], $t - 1)
			$Text2 = GUICtrlRead($ID2)
			If $Text1 = $Text2 Then
				If $p_Num = 1 Then
					$Found = 1
				ElseIf $p_Num = 2 Then
					GUICtrlDelete($ID2)
				EndIf
				ExitLoop
			EndIf
		Next
		If $p_Num = 1 And $Found = 0 Then GUICtrlCreateListViewItem($Text1, $g_UI_Interact[15][2])
	Next
	GUICtrlSetState($g_UI_Interact[15][$p_LV], $GUI_FOCUS)
EndFunc   ;==>_Misc_LS_EditItem

; ---------------------------------------------------------------------------------------------
; The Language Selector GUI
; ---------------------------------------------------------------------------------------------
Func _Misc_LS_GUI()
	Local $LV
	Local $LV1 = GUICtrlGetHandle($g_UI_Interact[15][1])
	Local $LV2 = GUICtrlGetHandle($g_UI_Interact[15][2])
	Local $SArray = StringSplit(_GetTR($g_UI_Message, '15-L1'), '|'); => short available translations for the mods
	Local $LArray = StringSplit(_GetTR($g_UI_Message, '15-I1'), '|'); => long available translations for the mods
	For $l = 1 To $LArray[0]
		If Not FileExists($g_GConfDir & '\WeiDU-' & $SArray[$l] & '.ini') Then ContinueLoop
		GUICtrlCreateListViewItem($LArray[$l], $g_UI_Interact[15][1])
	Next
	Local $MArray = StringSplit(GUICtrlRead($g_UI_Interact[2][5]), ' ')
	For $m = 1 To $MArray[0]
		For $s = 1 To $SArray[0]
			If $MArray[$m] = $SArray[$s] Then
				GUICtrlCreateListViewItem($LArray[$s], $g_UI_Interact[15][2])
				ExitLoop
			EndIf
		Next
	Next
	_GUICtrlListView_SetColumnWidth($g_UI_Interact[15][1], 0, 165)
	_GUICtrlListView_SetColumnWidth($g_UI_Interact[15][2], 0, 185)
	_Misc_SetTab(15)
	Local $msg, $t, $OldLV, $Test, $Name, $Tra
	While 1
		$msg = GUIGetMsg()
		$t += 1; rather ugly check to get the listview that has focus to avoid problems after _Misc_ReBuildTreeView was called
		If $t = 40 Then
			$OldLV = $LV
			$Test = ControlGetHandle($g_UI[0], '', ControlGetFocus($g_UI[0]))
			If $Test = $LV1 Then $LV = 1
			If $Test = $LV2 Then $LV = 2
			$t = 0
		EndIf
		Switch $msg
			Case $GUI_EVENT_CLOSE
				$Test = _Misc_LS_Verify(); do not exit without at least one selection
				If $Test = 1 Then ExitLoop
			Case $g_UI_Button[0][3]; go back to the folder-selection-screen
				$Test = _Misc_LS_Verify(); do not exit without at least one selection
				If $Test = 1 Then ExitLoop
			Case $g_UI_Button[15][1]; delete
				_Misc_LS_EditItem(2, $LV)
			Case $g_UI_Button[15][2]; add
				_Misc_LS_EditItem(1)
			Case $g_UI_Button[15][3]; decrease item
				_Misc_LS_MoveItem('-1')
			Case $g_UI_Button[15][4]; increase item
				_Misc_LS_MoveItem('+1')
			Case $g_UI_Button[15][5]; show mods that fit the currently selected language
				Local $Return = '', $Counter = 0
				$Name = StringTrimRight(GUICtrlRead(GUICtrlRead($g_UI_Interact[15][$LV])), 1)
				For $l = 1 To $LArray[0]
					If $Name = $LArray[$l] Then
						For $s = 1 To $g_Setups[0][0]
							$Tra = IniRead($g_MODIni, $g_Setups[$s][0], 'Tra', '')
							If StringRegExp($Tra, $SArray[$l]) Then
								$Return &= $g_Setups[$s][1] & @CRLF
								$Counter += 1
							EndIf
						Next
						GUICtrlSetData($g_UI_Interact[15][3], StringRegExpReplace($Return, '\A\r\n|\r\n\z', ''))
						GUICtrlSetData($g_UI_Button[15][5], IniRead($g_TRAIni, 'UI-Buildtime ', 'Button[15][5]', '') & ' ' & $Counter)
						ExitLoop
					EndIf
				Next
		EndSwitch
		Sleep(10)
	WEnd
	_Misc_SetTab(2)
EndFunc   ;==>_Misc_LS_GUI

; ---------------------------------------------------------------------------------------------
; Move the item in the listview up or down
; ---------------------------------------------------------------------------------------------
Func _Misc_LS_MoveItem($p_String)
	Local $Selected = ControlListView($g_Ui[0], '', $g_UI_Interact[15][2], 'GetSelected', 1)
	Local $Total = ControlListView($g_Ui[0], '', $g_UI_Interact[15][2], 'GetItemCount')
	If ($p_String = '+1' And $Selected = 0) Or ($p_String = '-1' And $Selected = $Total - 1) Then
		GUICtrlSetState($g_UI_Interact[15][2], $GUI_FOCUS)
		Return
	EndIf
	Local $ID1 = _GUICtrlListView_GetItemParam($g_UI_Interact[15][2], $Selected)
	Local $ID2, $Text1 = GUICtrlRead($ID1)
	If $p_String = '+1' Then
		$ID2 = _GUICtrlListView_GetItemParam($g_UI_Interact[15][2], $Selected - 1)
	Else
		$ID2 = _GUICtrlListView_GetItemParam($g_UI_Interact[15][2], $Selected + 1)
	EndIf
	Local $Text2 = GUICtrlRead($ID2)
	GUICtrlSetData($ID2, $Text1)
	GUICtrlSetData($ID1, $Text2)
	GUICtrlSetState($ID1, $GUI_NOFOCUS)
	GUICtrlSetState($ID2, $GUI_FOCUS)
	GUICtrlSetState($g_UI_Interact[15][2], $GUI_FOCUS)
EndFunc   ;==>_Misc_LS_MoveItem

; ---------------------------------------------------------------------------------------------
; Verify the string that has been put in the inputbox in the folder-selection-screen
; ---------------------------------------------------------------------------------------------
Func _Misc_LS_Verify()
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Misc_LS_Verify')
	Local $BGTInstallable = 0, $Error = '', $Reset = 0, $Tra, $Valid = 0
	Local $Current = GUICtrlRead($g_UI_Seperate[0][0]) + 1; avoid loops for updates during info-screen later
	Local $LArray = StringSplit(_GetTR($g_UI_Message, '15-I1'), '|'); => long available translations for the mods
	Local $MArray = StringSplit(GUICtrlRead($g_UI_Interact[2][5]), ' ')
	Local $SArray = StringSplit(_GetTR($g_UI_Message, '15-L1'), '|'); => short available translations for the mods
	If StringRegExp($g_Flags[14], 'BWS|BWP') Then $Tra = IniRead($g_ModIni, 'BGT', 'Tra', '')
	If $g_Flags[14] = 'BG2EE' Then $Tra = IniRead($g_ModIni, 'EET', 'Tra', ''); BG2EE uses EET for merging games
	If $Current = 15 Then; lang-tab
		Local $Selected = ControlListView($g_Ui[0], '', $g_UI_Interact[15][2], 'GetItemCount')
		If $Selected = 0 Then $Error = '|' & _GetTR($g_UI_Message, '2-L1'); => select a translation
		Local $ID, $Text, $Return = ''
		For $s = 0 To $Selected - 1
			$ID = _GUICtrlListView_GetItemParam($g_UI_Interact[15][2], $s)
			$Text = StringTrimRight(GUICtrlRead($ID), 1)
			For $l = 1 To $LArray[0]
				If $Text = $LArray[$l] Then
					If StringInStr($Tra, $SArray[$l]) Then $BGTInstallable = 1
					$Return &= ' ' & $SArray[$l]
					ExitLoop
				EndIf
			Next
		Next
		If $g_Flags[3] <> StringTrimLeft($Return, 1) Then $Reset = 1; token is not found in current setting
		$g_Flags[3] = StringTrimLeft($Return, 1)
		Local $Last = _GUICtrlListView_GetItemParam($g_UI_Interact[15][2], $Selected - 1)
		Local $First = _GUICtrlListView_GetItemParam($g_UI_Interact[15][1], 0)
		If $BGTInstallable = 1 Then
			For $ID = $Last To $First Step -1
				GUICtrlDelete($ID); delete all GuiListViewItems so _Tree_Reload works as expected
			Next
		EndIf
	Else; folder-tab
		Local $Selected = GUICtrlRead($g_UI_Interact[2][5])
		If $g_Flags[3] <> $Selected Then $Reset = 1; changes have been made
		If $Selected = '' Then $Error = _GetTR($g_UI_Message, '2-L1'); => select a translation
		For $m = 1 To $MArray[0]
			For $s = 1 To $SArray[0]
				If $MArray[$m] = $SArray[$s] Then
					If Not FileExists($g_GConfDir & '\WeiDU-' & $SArray[$s] & '.ini') Then ContinueLoop
					If StringInStr($Tra, $MArray[$m]) Then $BGTInstallable = 1
					$Valid += 1
					ExitLoop
				EndIf
			Next
		Next
		If $Valid <> $MArray[0] Then $Error = '|' & _GetTR($g_UI_Message, '2-L1'); => select a translation
		$g_Flags[3] = $Selected
	EndIf
	If $BGTInstallable = 0 And GUICtrlRead($g_UI_Interact[2][1]) <> '-' Then $Error &= '||' & IniRead($g_GConfDir & '\Translation-' & $g_ATrans[$g_ATNum] & '.ini', 'UI-RunTime', '2-L4', ''); => BGT/EET not installable
	If $Error <> '' Then
		If $Current = 2 Then $Error &= '||' & _GetTR($g_UI_Message, '2-L5'); => start assistant
		_Misc_MsgGUI(4, _GetTR($g_UI_Message, '0-T1'), $Error); => warning
		If $Current = 2 Then _Misc_LS_GUI()
		Return 0
	EndIf
	IniWrite($g_UsrIni, 'Options', 'ModLang', $g_Flags[3]); Fetch the selected items and write them into the users preference(s)-file
	GUICtrlSetData($g_UI_Interact[2][5], $g_Flags[3])
	$g_MLang = StringSplit($g_Flags[3] & ' --', ' '); reset the array with the selected languages. -- is added for mods with no text = suitable for all languages
	If $Reset = 1 And $g_Skip <> '' Then _Misc_ReBuildTreeView(); another language-token was added that was not used before and Treeview exists
	Return 1
EndFunc   ;==>_Misc_LS_Verify

; ---------------------------------------------------------------------------------------------
; Creates the custom message-box
; ---------------------------------------------------------------------------------------------
Func _Misc_MsgGUI($p_Icon, $p_Title, $p_Text, $p_Button = 1, $p_Text1 = '', $p_Text2 = '', $p_Text3 = '', $p_Time = -1)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Misc_MsgGUI'); >>> 1=continue, 2=cancel, 3=exit
	Local $Feed, $State[4]
	If $p_Text1 = '' Then $p_Text1 = _GetTR($g_UI_Message, '8-B1'); => continue
	If $p_Text2 = '' Then $p_Text2 = _GetTR($g_UI_Message, '8-B2'); => cancel
	If $p_Text3 = '' Then $p_Text3 = _GetTR($g_UI_Message, '8-B3'); => exit
	Local $String = __StringSplit_ByLength($p_Text, 310, $g_UI_Interact[8][1])
	$p_Text = StringReplace(_StringStripCRLF($p_Text), '|', @CRLF)
	; ---------------------------------------------------------------------------------------------
	; Display different icons
	; ---------------------------------------------------------------------------------------------
	If $p_Icon = 1 Then
		GUICtrlSetImage($g_UI_Static[8][1], @ScriptDir & "\Pics\Info.ico")
	ElseIf $p_Icon = 2 Then
		GUICtrlSetImage($g_UI_Static[8][1], @ScriptDir & "\Pics\Question.ico")
	ElseIf $p_Icon = 3 Then
		GUICtrlSetImage($g_UI_Static[8][1], @ScriptDir & "\Pics\Warning.ico")
	ElseIf $p_Icon = 4 Then
		GUICtrlSetImage($g_UI_Static[8][1], @ScriptDir & "\Pics\Error.ico")
	EndIf
	; ---------------------------------------------------------------------------------------------
	; Position the icon and buttons
	; ---------------------------------------------------------------------------------------------
	Local $Pos = ControlGetPos($g_UI[0], '', $g_UI_Seperate[8][1])
	GUICtrlSetPos($g_UI_Static[8][1], $Pos[0] + 15, $Pos[1] + Round(($Pos[3] - 90) / 2, 2), 48, 48)
	If $p_Button = 1 Then
		$Pos = _Misc_CalcButtonPos(1, 1)
		GUICtrlSetPos($g_UI_Button[8][1], $Pos[0], $Pos[1], $Pos[2], $Pos[3])
		GUICtrlSetData($g_UI_Button[8][1], $p_Text1)
		GUICtrlSetState($g_UI_Button[8][1], $GUI_SHOW)
		GUICtrlSetState($g_UI_Button[8][2], $GUI_HIDE)
		GUICtrlSetState($g_UI_Button[8][3], $GUI_HIDE)
	ElseIf $p_Button = 2 Then
		$Pos = _Misc_CalcButtonPos(1, 2)
		GUICtrlSetPos($g_UI_Button[8][1], $Pos[0], $Pos[1], $Pos[2], $Pos[3])
		$Pos = _Misc_CalcButtonPos(2, 2)
		GUICtrlSetPos($g_UI_Button[8][2], $Pos[0], $Pos[1], $Pos[2], $Pos[3])
		GUICtrlSetData($g_UI_Button[8][1], $p_Text2)
		GUICtrlSetData($g_UI_Button[8][2], $p_Text1)
		GUICtrlSetState($g_UI_Button[8][1], $GUI_SHOW)
		GUICtrlSetState($g_UI_Button[8][2], $GUI_SHOW)
		GUICtrlSetState($g_UI_Button[8][3], $GUI_HIDE)
	Else
		$Pos = _Misc_CalcButtonPos(1, 3)
		GUICtrlSetPos($g_UI_Button[8][1], $Pos[0], $Pos[1], $Pos[2], $Pos[3])
		$Pos = _Misc_CalcButtonPos(2, 3)
		GUICtrlSetPos($g_UI_Button[8][2], $Pos[0], $Pos[1], $Pos[2], $Pos[3])
		$Pos = _Misc_CalcButtonPos(3, 3)
		GUICtrlSetPos($g_UI_Button[8][3], $Pos[0], $Pos[1], $Pos[2], $Pos[3])
		GUICtrlSetData($g_UI_Button[8][1], $p_Text3)
		GUICtrlSetData($g_UI_Button[8][2], $p_Text2)
		GUICtrlSetData($g_UI_Button[8][3], $p_Text1)
		GUICtrlSetState($g_UI_Button[8][1], $GUI_SHOW)
		GUICtrlSetState($g_UI_Button[8][2], $GUI_SHOW)
		GUICtrlSetState($g_UI_Button[8][3], $GUI_SHOW)
	EndIf
	; ---------------------------------------------------------------------------------------------
	; Display the message
	; ---------------------------------------------------------------------------------------------
	GUICtrlSetData($g_UI_Seperate[8][1], $p_Title); hint
	If $String[1] >= 10 Then
		GUICtrlSetState($g_UI_Static[8][2], $GUI_HIDE)
		GUICtrlSetState($g_UI_Interact[8][1], $GUI_SHOW)
		GUICtrlSetData($g_UI_Interact[8][1], $p_Text); message
	Else
		For $n = 1 To Ceiling((11 - $String[1]) / 2)
			$Feed &= @CRLF
		Next
		GUICtrlSetState($g_UI_Interact[8][1], $GUI_HIDE)
		GUICtrlSetState($g_UI_Static[8][2], $GUI_SHOW)
		GUICtrlSetData($g_UI_Static[8][2], $Feed & $p_Text); message
	EndIf
	Local $OldTab = GUICtrlRead($g_UI_Seperate[0][0])
	For $i = 1 To 3
		$State[$i] = GUICtrlGetState($g_UI_Button[0][$i])
	Next
	If $g_Flags[9] = 1 Then WinSetState($g_UI[0], '', @SW_ENABLE)
	_Misc_SetTab(8)
	; ---------------------------------------------------------------------------------------------
	; Be sure to be able to fetch button-clicks
	; ---------------------------------------------------------------------------------------------
	Local $OldMode = AutoItSetOption('GUIOnEventMode')
	If $OldMode Then AutoItSetOption('GUIOnEventMode', 0)
	Local $msg, $Answer = 0, $Num = 0
	While $Answer = 0
		If $Num = 100 * $p_Time Then $Answer = 1
		$msg = GUIGetMsg()
		If $msg = $g_UI_Button[8][1] Then $Answer = 1
		If $msg = $g_UI_Button[8][2] Then $Answer = 2
		If $msg = $g_UI_Button[8][3] Then $Answer = 3
		Sleep(10)
		$Num += 1
	WEnd
	; ---------------------------------------------------------------------------------------------
	; Switch back to old state
	; ---------------------------------------------------------------------------------------------
	If $OldMode Then AutoItSetOption('GUIOnEventMode', $OldMode)
	For $i = 1 To 3
		If BitAND($State[$i], $GUI_ENABLE) Then GUICtrlSetState($g_UI_Button[0][$i], $GUI_ENABLE)
	Next
	If $OldTab <> 8 Then _Misc_SetTab($OldTab + 1); remove the icons from the screen
	If $g_Flags[9] = 1 Then WinSetState($g_UI[0], '', @SW_DISABLE)
	Return $Answer
EndFunc   ;==>_Misc_MsgGUI

; ---------------------------------------------------------------------------------------------
; Creates the custom progress-screen
; ---------------------------------------------------------------------------------------------
Func _Misc_ProgressGUI($p_Title, $p_Text)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Misc_ProgressGUI')
	GUICtrlSetData($g_UI_Seperate[9][1], $p_Title)
	GUICtrlSetData($g_UI_Static[9][1], $p_Text)
	GUICtrlSetData($g_UI_Interact[9][1], 0)
	_Misc_SetTab(9)
EndFunc   ;==>_Misc_ProgressGUI

; ---------------------------------------------------------------------------------------------
; Prepares a rebuild of the treeview
; ---------------------------------------------------------------------------------------------
Func _Misc_ReBuildTreeView($p_Save = 0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Misc_ReBuildTreeView')
	If $p_Save Then _Tree_GetCurrentSelection(0, @TempDir & '\BWS_Reload.ini')
	For $t = 2 To 4; remove all defined menu-items
		For $c = 3 To $g_UI_Menu[0][3]
			If $g_UI_Menu[$t][$c] <> '' Then GUICtrlDelete($g_UI_Menu[$t][$c])
		Next
	Next
	For $c = $g_CentralArray[0][1] To $g_CentralArray[0][0]; remove treeview-items
		GUICtrlDelete($c)
	Next
	Global $g_TreeviewItem[1][1], $g_CHTreeviewItem[1][1], $g_Connections[1000][3], $g_CentralArray[1][16], $g_Test = ''; This cleans all the old settings (has to be removed, since its content depends on the language)
	Local $Pos = ControlGetPos($g_UI[0], '', $g_UI_Interact[4][1])
	_GUICtrlListView_DeleteAllItems($g_UI_Handle[1]); delete dependencies
	_Selection_GetCurrentInstallType()
	_Misc_SetAvailableSelection()
	_Tree_Populate(1 + $p_Save); rebuild Arrays, GUI and so on (_Tree_Populate will call _Tree_SetPreSelected UNLESS $p_Save = 1)
	;_Depend_AutoSolve('DS', 2, 1); disable mods/components with unsatisfied dependencies, skip warning rules
	;_Depend_AutoSolve('C', 2, 1); disable conflict losers, skip warning rules
	;_Depend_AutoSolve('DS', 2, 1); disable mods/components with unsatisfied dependencies, skip warning rules
	;$g_Flags[23]=''; reset progress bar
	If $p_Save Then _Tree_Reload(1, 1, @TempDir & '\BWS_Reload.ini')
	;GUICtrlSetData($g_UI_Static[9][2], '100 %')
	GUICtrlSetData($g_UI_Interact[1][1], StringReplace(IniRead($g_TRAIni, 'UI-Buildtime', 'Interact[1][1]', ''), '|', @CRLF))
EndFunc   ;==>_Misc_ReBuildTreeView

; ---------------------------------------------------------------------------------------------
; Select another folder
; ---------------------------------------------------------------------------------------------
Func _Misc_SelectFolder($p_Type, $p_Text)
	Local $Folder = Eval('g_' & $p_Type & 'Dir')
	If Not FileExists($Folder) Then $Folder = $g_BaseDir
	$Folder = FileSelectFolder($p_Text, '', 2, $Folder & '\', $g_UI[0]); => select folder
	If $Folder = '' Then Return
	If $p_Type = 'BG1EE' And FileExists($Folder & '\Data\00766') Then $Folder = $Folder & '\Data\00766'; get BG1EE Beamdog-subfolder
	If $p_Type = 'BG1EE' And FileExists($Folder & '\Data\00806') Then $Folder = $Folder & '\Data\00806'; get BG1EE Beamdog-subfolder
	If $p_Type = 'BG2EE' And FileExists($Folder & '\Data\00783') Then $Folder = $Folder & '\Data\00783'; get BG2EE Beamdog-subfolder
	If $p_Type = 'IWD1EE' And FileExists($Folder & '\Data\00798') Then $Folder = $Folder & '\Data\00798'; get IWD1EE Beamdog-subfolder
	If $p_Type = 'PSTEE' And FileExists($Folder & '\Data\00827') Then $Folder = $Folder & '\Data\00827'; get PSTEE Beamdog-subfolder
	Assign('g_' & $p_Type & 'Dir', $Folder)
	If $p_Type = 'Down' Then
		Local $Test = 1
		Local $File = _FileSearch($g_DownDir, '*')
		For $f = 1 To $File[0]
			If StringRegExp($File[$f], '(?i)\ABWS') = 0 Then
				$Test = 0
				ExitLoop
			Else
				FileMove($g_DownDir & '\' & $File[$f], $Folder & '\' & $File[$f]); move BWS-files
			EndIf
		Next
		If $Test = 1 Then DirRemove($g_DownDir, 1); remove folder if nothing is left
		IniWrite($g_UsrIni, 'Options', 'Download', $Folder)
		GUICtrlSetData($g_UI_Interact[2][3], $Folder)
	Else
		IniWrite($g_UsrIni, 'Options', $p_Type, $Folder)
		If $p_Type = 'BG1' Or ($p_Type = 'BG1EE' And $g_Flags[14] = 'BG2EE') Then; BGT/EET
			GUICtrlSetData($g_UI_Interact[2][1], $Folder)
		Else
			GUICtrlSetData($g_UI_Interact[2][2], $Folder)
			$g_GameDir = $Folder
		EndIf
		Call('_Test_CheckRequiredFiles_' & $p_Type)
	EndIf
EndFunc   ;==>_Misc_SelectFolder

; ---------------------------------------------------------------------------------------------
; adapts the available selections depending on BWS/BWP-installs
; ---------------------------------------------------------------------------------------------
Func _Misc_SetAvailableSelection()
	Local $Message = IniRead($g_GConfDir & '\Translation-' & $g_ATrans[$g_ATNum] & '.ini', 'UI-Buildtime', 'Interact[2][6]', '')
	Local $UI = IniRead($g_TRAIni, 'UI-Runtime', '2-I1', '')
	Local $PreSelect = '', $Description = '', $Text = ''
	$g_Flags[25] = ''
	For $n = 0 To 99
		If StringLen($n) = 1 Then $n = '0' & $n
		If Not FileExists($g_GConfDir & '\Preselection' & $n & '.ini') Then
			If $n = '00' Then
				ContinueLoop
			Else
				ExitLoop
			EndIf
		EndIf
		$Text = IniRead($g_GConfDir & '\Mod-' & $g_ATrans[$g_ATNum] & '.ini', 'Preselect', $n, '')
		If $Text = '' Then ContinueLoop
		$Description &= '||' & $Text
		$PreSelect &= '|' & StringLeft($Text, StringInStr($Text, ' - ') - 1)
		$g_Flags[25] &= $n & '|'
	Next
	$Description = _GetTR($g_UI_Message, '2-L9') & '|' & StringTrimLeft($Description, 2) & '||'; => you can select gamers compilations
	If $PreSelect <> '' Then $PreSelect = StringTrimLeft($PreSelect, 1) & '|'
	$g_Flags[25] &= '1|2|3|4|5'
	_IniWrite($g_UI_Message, '2-I1', $PreSelect & $UI, 'O'); => preselections - adjust available preselections for later
	Local $Split = StringSplit($PreSelect & $UI, '|'); => preselections
	Local $SplitD = StringSplit($UI, '|'); => defaults
	GUICtrlSetData($g_UI_Interact[2][4], '')
	Local $InstallType = IniRead($g_UsrIni, 'Options', 'InstallType', '')
	If $InstallType = '' Then ; revert to a default pre-selection if no record of most recent user selection
;		If $g_Flags[14] = 'BWS' Then
;			$InstallType = $Split[1]; => first custom pre-selection as default
;		Else
			$InstallType = $SplitD[2]; => 'recommended' pre-selection as default (#1 is minimal, #2 is recommended)
;		EndIf
	ElseIf StringLen($InstallType) = 1 Then; last user selection was one of the default pre-selections
		If $InstallType > UBound($SplitD) - 1 Then $InstallType = 1
		$InstallType = $SplitD[$InstallType]
	Else ; a custom compilation was the most recent user selection
		If $InstallType > UBound($Split) - 1 Then
			$InstallType = 1
		ElseIf $InstallType = '00' And FileExists($g_GConfDir & '\Preselection00.ini') Then
			$InstallType = 1 ; if available, reload auto-export (user-customized selection)
		EndIf
		$InstallType = $Split[$InstallType]
	EndIf
	GUICtrlSetData($g_UI_Interact[2][4], _GetTR($g_UI_Message, '2-I1'), $InstallType); => preselections with total happyness as default
	GUICtrlSetData($g_UI_Interact[2][6], StringReplace(StringFormat($Message, $Description), '|', @CRLF)); => folder/preselection-help
EndFunc   ;==>_Misc_SetAvailableSelection

; ---------------------------------------------------------------------------------------------
; sets the language of the gui-components to the selected one
; ---------------------------------------------------------------------------------------------
Func _Misc_SetLang()
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Misc_SetLang')
	Local $String, $Var, $Message = IniReadSection($g_TRAIni, 'UI-Buildtime')
	For $m = 1 To $Message[0][0]
		If $Message[$m][1] = '' Then ContinueLoop
		$String = StringSplit($Message[$m][0], '[]')
		$Var = Eval('g_UI_' & $String[1])
		If $Var <> '' Then GUICtrlSetData($Var[$String[2]][$String[4]], StringReplace($Message[$m][1], '|', @CRLF))
	Next
	GUICtrlSetData($g_UI_Static[2][2], _GetGameName())
	GUICtrlSetData($g_UI_Static[3][1], StringFormat(_GetSTR($Message, 'Static[3][1]'), $g_Flags[14])); => backup important files
	GUICtrlSetData($g_UI_Interact[3][4], StringFormat(_GetSTR($Message, 'Interact[3][4]'), _GetGameName(), $g_Flags[14], $g_Flags[14])); => backup help text
	; Items that need special treatment
	Local $Split = StringSplit(_GetTR($Message, 'Interact[1][2]'), '|'); => BWS translations
	GUICtrlSetData($g_UI_Interact[1][2], '')
	GUICtrlSetData($g_UI_Interact[1][2], _GetTR($Message, 'Interact[1][2]'), $Split[$g_ATNum]); => BWS translations
	GUICtrlSetData($g_UI_Interact[1][3], '')
	$g_GameList = _GetGameList()
	GUICtrlSetData($g_UI_Interact[1][3], $g_GameList[0][2], $g_GameList[1][2]); => installation method
	$g_Flags[3] = IniRead($g_UsrIni, 'Options', 'ModLang', '')
	If $g_Flags[3] = '' Then
		If $g_ATrans[$g_ATNum] <> 'EN' Then
			$g_Flags[3] = $g_ATrans[$g_ATNum] & ' EN'
		Else
			$g_Flags[3] &= 'EN'
		EndIf
	EndIf
	GUICtrlSetData($g_UI_Interact[2][5], $g_Flags[3])
	$g_MLang = StringSplit($g_Flags[3] & ' --', ' '); reset the array with the selected languages. -- is added for mods with no text = suitable for all languages
	Local $Split = StringSplit(_GetTR($Message, 'Menu[2][1]'), '|'); => Special|All
	For $n = 1 To 2
		For $m = 2 To 4
			GUICtrlSetData($g_UI_Menu[$m][$n], $Split[$n])
		Next
	Next
	If $g_ATrans[$g_ATNum] = 'GE' Then; show or hide kerzenburgs wiki-page button
		GUICtrlSetState($g_UI_Button[4][4], $GUI_SHOW)
	Else
		GUICtrlSetState($g_UI_Button[4][4], $GUI_HIDE)
	EndIf
	GUICtrlSetData($g_UI_Interact[10][1], _GetTR($Message, 'Interact[10][1]')); => mod/component
	GUICtrlSetData($g_UI_Interact[11][4], _GetTR($Message, 'Interact[11][4]')); => key/variable
	GUICtrlSetData($g_UI_Static[11][4], $g_ATrans[$g_ATNum])
	GUICtrlSetData($g_UI_Interact[12][1], _GetTR($Message, 'Interact[12][1]')); => No.|Read description
	GUICtrlSetData($g_UI_Interact[12][2], _GetTR($Message, 'Interact[12][2]')); => No.|Saved description
	GUICtrlSetData($g_UI_Interact[13][1], _GetTR($Message, 'Interact[13][1]')); => Mod|Component
	GUICtrlSetData($g_UI_Interact[13][3], _GetTR($Message, 'Interact[13][3]')); => Mod|Component|ID
	$Split = StringSplit(_GetTR($Message, 'Interact[14][1]'), '|'); => report/remove missing mods + pause after download
	GUICtrlSetData($g_UI_Interact[14][1], '')
	GUICtrlSetData($g_UI_Interact[14][1], _GetTR($Message, 'Interact[14][1]'), $Split[1]); => dito
	$Split = StringSplit(_GetTR($Message, 'Interact[14][2]'), '|'); => report/remove missing mods + pause after extraction
	GUICtrlSetData($g_UI_Interact[14][2], '')
	GUICtrlSetData($g_UI_Interact[14][2], _GetTR($Message, 'Interact[14][2]'), $Split[1]); => dito
	$Split = StringSplit(_GetTR($Message, 'Interact[14][3]'), '|'); => report or remove errors/warnings
	GUICtrlSetData($g_UI_Interact[14][3], '')
	GUICtrlSetData($g_UI_Interact[14][3], _GetTR($Message, 'Interact[14][3]'), $Split[1]); => dito
	GUICtrlSetData($g_UI_Interact[16][3], _GetTR($Message, 'Interact[16][3]')); => Mod|Component|ID
EndFunc   ;==>_Misc_SetLang

; ---------------------------------------------------------------------------------------------
; Switch to the desired tab. Do several tasks while doing it
; ---------------------------------------------------------------------------------------------
Func _Misc_SetTab($p_Tab)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Misc_SetTab')
	; ============ enable toolswitch ==================
	If $p_Tab = 2 Then; folder
		HotKeySet('^!c', '_Tra_Gui')
		HotKeySet('^!m', '_Admin_ModGui')
		HotKeySet('^!s', '_Select_Gui')
		HotKeySet('^!d', '_Dep_Gui')
	Else
		HotKeySet('^!c')
		HotKeySet('^!m')
		HotKeySet('^!s')
		HotKeySet('^!d')
	EndIf
	; ============ get default size ===================
	If $g_UI[2] = '' Then
		Local $WPos0 = WinGetPos($g_UI[0])
		Local $WPos1 = WinGetPos($g_UI[1])
		$g_UI[2] = $WPos1[0] - $WPos0[0]
		$g_UI[3] = $WPos1[1] - $WPos0[1]
	EndIf
	; ============ disable std. button ================
	If StringRegExp(String($p_Tab), '\A(8|9)\z') Then; msgbox & progressbar
		GUICtrlSetState($g_UI_Button[0][1], $GUI_DISABLE)
		GUICtrlSetState($g_UI_Button[0][2], $GUI_DISABLE)
		GUICtrlSetState($g_UI_Button[0][3], $GUI_DISABLE)
	ElseIf StringRegExp($p_Tab, '\A(4|7|13|15)\z') Then; about, modadmin, conflicts/depends
		GUICtrlSetState($g_UI_Button[0][1], $GUI_DISABLE)
		GUICtrlSetState($g_UI_Button[0][2], $GUI_DISABLE)
		GUICtrlSetState($g_UI_Button[0][3], $GUI_ENABLE)
	Else
		GUICtrlSetState($g_UI_Button[0][1], $GUI_ENABLE)
		GUICtrlSetState($g_UI_Button[0][2], $GUI_ENABLE)
		GUICtrlSetState($g_UI_Button[0][3], $GUI_ENABLE)
	EndIf
	; ========== edit names of std. button ============
	If StringRegExp(String($p_Tab), '\A(11|12)\z') Then; modadmin, componentadmin
		GUICtrlSetData($g_UI_Button[0][1], _GetTR($g_UI_Message, '12-B1')); => previous mod
		GUICtrlSetData($g_UI_Button[0][2], _GetTR($g_UI_Message, '12-B2')); => next mod
		GUICtrlSetData($g_UI_Button[0][3], IniRead($g_TRAIni, 'UI-Buildtime', 'Button[0][1]', 'Back'))
	ElseIf StringRegExp(String($p_Tab), '\A(4|7|13|15)\z') Then; about
		GUICtrlSetData($g_UI_Button[0][3], IniRead($g_TRAIni, 'UI-Buildtime', 'Button[0][1]', 'Back'))
	ElseIf String($p_Tab) = 16 Then; selectadmin
		GUICtrlSetData($g_UI_Button[0][1], _GetTR($g_UI_Message, '16-B1')); => upwards
		GUICtrlSetData($g_UI_Button[0][2], _GetTR($g_UI_Message, '16-B2')); => downwards
		GUICtrlSetData($g_UI_Button[0][3], IniRead($g_TRAIni, 'UI-Buildtime', 'Button[0][1]', 'Back'))
	Else
		GUICtrlSetData($g_UI_Button[0][1], IniRead($g_TRAIni, 'UI-Buildtime', 'Button[0][1]', 'Back'))
		GUICtrlSetData($g_UI_Button[0][2], IniRead($g_TRAIni, 'UI-Buildtime', 'Button[0][2]', 'Continue'))
		GUICtrlSetData($g_UI_Button[0][3], IniRead($g_TRAIni, 'UI-Buildtime', 'Button[0][3]', 'Exit'))
	EndIf
	; ============ set default button =================
	If $p_Tab = 4 Then; advanced
		GUICtrlSetState($g_UI_Button[4][1], $GUI_DEFBUTTON)
		GUICtrlSetState($g_UI_Interact[4][1], $GUI_FOCUS)
	ElseIf $p_Tab = 6 Then; process
		GUICtrlSetState($g_UI_Button[6][1], $GUI_DEFBUTTON)
		GUICtrlSetState($g_UI_Interact[6][5], $GUI_FOCUS)
	ElseIf $p_Tab = 8 Then; msgbox
		GUICtrlSetState($g_UI_Button[8][1], $GUI_DEFBUTTON)
		GUICtrlSetState($g_UI_Button[8][1], $GUI_FOCUS)
	ElseIf $p_Tab = 11 Then; modadmin
		GUICtrlSetState($g_UI_Interact[11][5], $GUI_FOCUS)
	ElseIf $p_Tab = 12 Then; componentadmin
		GUICtrlSetState($g_UI_Button[12][3], $GUI_DEFBUTTON)
		GUICtrlSetState($g_UI_Interact[12][1], $GUI_FOCUS)
	ElseIf $p_Tab = 13 Then; conflicts/depends
		GUICtrlSetState($g_UI_Button[13][2], $GUI_DEFBUTTON)
		GUICtrlSetState($g_UI_Interact[13][1], $GUI_FOCUS)
	Else
		GUICtrlSetState($g_UI_Button[0][2], $GUI_DEFBUTTON)
	EndIf
	; ========== hide/show msgbox icon  ===============
	If $p_Tab = 8 Then; msgbox
		GUICtrlSetState($g_UI_Static[8][1], $GUI_SHOW); used to avoid overlay-effects
	Else
		GUICtrlSetState($g_UI_Static[8][1], $GUI_HIDE)
	EndIf
	; ============ switch to tab  =====================
	Local $Current = GUICtrlRead($g_UI_Seperate[0][0]) + 1; avoid loops for updates during info-screen later
	If GUICtrlRead($g_UI_Seperate[0][0]) + 1 <> $p_Tab Then GUICtrlSetState($g_UI_Seperate[$p_Tab][0], $GUI_SHOW); don't switch if $p_tab is current one to avoid flickering
	; ============ show/hide picture ==================
	If StringRegExp(String($p_Tab), '\A(1|7)\z') Then; greetings, about
		$g_Flags[15] = 1
		Local $WPos0 = WinGetPos($g_UI[0])
		Local $CPos = ControlGetPos($g_UI[0], '', $g_UI_Static[1][4])
		Local $XControlOffSet = ($CPos[2] - 400) / 2
		Local $YControlOffSet = ($CPos[3] - 260)
		WinMove($g_UI[1], '', $WPos0[0] + $g_UI[2] + $XControlOffSet, $WPos0[1] + $g_UI[3] + $YControlOffSet)
		GUISetState(@SW_SHOW, $g_UI[1])
		WinActivate($g_UI[0])
	Else
		$g_Flags[15] = 0
		GUISetState(@SW_HIDE, $g_UI[1])
		WinActivate($g_UI[0])
	EndIf
	; ============ register custom msgs ===============
	GUIRegisterMsg($WM_NOTIFY, '')
	If $p_Tab = 4 Then; advanced
		$g_Flags[8] = 1
		GUIRegisterMsg($WM_NOTIFY, '__TristateTreeView_WM_Notify')
	Else
		$g_Flags[8] = 0
		If $p_Tab = 10 Then GUIRegisterMsg($WM_NOTIFY, '_Depend_WM_Notify'); solve dependencies
		If $p_Tab = 11 Then GUIRegisterMsg($WM_NOTIFY, '_Admin_Mod_WM_Notify'); admin mods
		If $p_Tab = 12 Then GUIRegisterMsg($WM_NOTIFY, '_Tra_WM_Notify'); admin component-translations
		If $p_Tab = 13 Then GUIRegisterMsg($WM_NOTIFY, '_Dep_WM_Notify'); admin dependencies
		If $p_Tab = 16 Then GUIRegisterMsg($WM_NOTIFY, '_Select_WM_Notify'); admin order
	EndIf
	GUISetState(@SW_SHOW, $g_UI[0])
EndFunc   ;==>_Misc_SetTab

; ---------------------------------------------------------------------------------------------
; Change the entries on the tip-screen. Stage 0 = Initial / 1 = Question screen
; ---------------------------------------------------------------------------------------------
Func _Misc_SetTip($p_Stage = 1)
	Local $Value = GUICtrlRead($g_UI_Interact[1][3]); get current value so function works if game-type is changed
	For $g = 1 To $g_GameList[0][0]
		If $Value = $g_GameList[$g][2] Then ExitLoop
	Next
	If $p_Stage <> 0 Then GUICtrlSetData($g_UI_Interact[1][1], StringReplace(IniRead($g_ProgDir & '\Config\' & $g_GameList[$g][0] & '\Translation-' & $g_ATrans[$g_ATNum] & '.ini', 'UI-RunTime', '1-L2', ''), '|', @CRLF)); => questionary (did you have installed...)
	GUICtrlSetData($g_UI_Static[2][2], _GetGameName()); game-folder
	GUICtrlSetData($g_UI_Static[3][1], StringFormat(StringReplace(IniRead($g_TRAIni, 'UI-Buildtime', 'Static[3][1]', ''), '|', @CRLF), $g_GameList[$g][1])); => backup hint
	GUICtrlSetData($g_UI_Interact[3][4], StringFormat(StringReplace(IniRead($g_TRAIni, 'UI-Buildtime', 'Interact[3][4]', ''), '|', @CRLF), _GetGameName(), $g_GameList[$g][1], $g_GameList[$g][1])); => backup help
EndFunc   ;==>_Misc_SetTip

; ---------------------------------------------------------------------------------------------
; Select the language in the first tab
;  $p_String = '+' if we're going forward (user clicked 'continue'), else we're going 'back'
; ---------------------------------------------------------------------------------------------
Func _Misc_SetWelcomeScreen($p_String)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Misc_SetWelcomeScreen')
	Local $Current = GUICtrlRead($g_UI_Seperate[0][0]) + 1
	Local $State = BitAND(GUICtrlGetState($g_UI_Interact[1][2]), $GUI_HIDE)
	If $p_String = '+' Then; we're going forwards
		If $State Then; jump from install selection to folder selection
			Local $Method = GUICtrlRead($g_UI_Interact[1][3]); look if install-method changed
			For $g = 1 To $g_GameList[0][0]
				If $Method = $g_GameList[$g][2] Then
					If $g_Flags[14] <> $g_GameList[$g][1] Then
						$g_Flags[14] = $g_GameList[$g][1]
						_Misc_SwitchGUIToInstallMethod()
						_Misc_SetAvailableSelection()
						IniWrite($g_UsrIni, 'Options', 'AppType', $g_GameList[$g][0] & ':' & $g_Flags[14])
						$g_Flags[10] = 1
					Else; make sure the correct config-dir is used (rare case if you use something, go back, change game, go back, go forth, revert game, continue)
						_Misc_Set_GConfDir($g_GameList[$g][0])
					EndIf
				EndIf
			Next
			;			If IniRead($g_UsrIni, 'Options', 'SuppressUpdate', 0) = 0 Then
			;				$State=BitAND(GUICtrlGetState($g_UI_Button[3][6]), $GUI_ENABLE)
			;				If $State Then _Net_StartupUpdate(); update was not done... ask again
			;			EndIf
			If $g_Flags[10] > 0 Then
				If $g_Skip <> '' Then _Misc_ReBuildTreeView()
				$g_Flags[10] = 0
			EndIf
			_Misc_SetTab(2)
		Else; jump from welcome to install selection
			If $g_Flags[10] = 2 Then IniWrite($g_UsrIni, 'Options', 'AppLang', $g_ATrans[$g_ATNum])
			GUICtrlSetData($g_UI_Static[1][1], _GetTR($g_UI_Message, '1-L1')); => important notes
			GUICtrlSetData($g_UI_Interact[1][1], StringReplace(IniRead($g_GConfDir & '\Translation-' & $g_ATrans[$g_ATNum] & '.ini', 'UI-RunTime', '1-L2', ''), '|', @CRLF)); => questionary (did you have installed...)
			GUICtrlSetState($g_UI_Interact[1][2], $GUI_HIDE); combobox
			GUICtrlSetState($g_UI_Static[1][2], $GUI_HIDE); language label
			GUICtrlSetState($g_UI_Interact[1][3], $GUI_SHOW); combobox
			GUICtrlSetState($g_UI_Static[1][3], $GUI_SHOW); install label
			GUICtrlSetState($g_UI_Button[0][1], $GUI_ENABLE)
			Return 0
		EndIf
	Else; not '+' => we're going back, not forward
		If $Current = 2 Then; jump back from folder selection to install selection
			GUICtrlSetData($g_UI_Static[1][1], _GetTR($g_UI_Message, '1-L1')); => important notes
			GUICtrlSetData($g_UI_Interact[1][1], StringReplace(IniRead($g_GConfDir & '\Translation-' & $g_ATrans[$g_ATNum] & '.ini', 'UI-RunTime', '1-L2', ''), '|', @CRLF)); => questionary (did you have installed...)
			_Misc_SetTab(1)
		ElseIf $State Then; jump back from install selection to welcome
			Local $Method = GUICtrlRead($g_UI_Interact[1][3]); look if install-method changed
			For $g = 1 To $g_GameList[0][0]
				If $Method = $g_GameList[$g][2] Then
					If $g_Flags[14] <> $g_GameList[$g][1] Then _Misc_Set_GConfDir($g_GameList[$g][0])
				EndIf
			Next
			GUICtrlSetData($g_UI_Static[1][1], StringReplace(IniRead($g_TRAIni, 'UI-Buildtime', 'Static[1][1]', ''), '|', @CRLF)); => important notes
			GUICtrlSetData($g_UI_Interact[1][1], StringReplace(IniRead($g_TRAIni, 'UI-Buildtime', 'Interact[1][1]', ''), '|', @CRLF)); => questionary (did you have installed...)
			GUICtrlSetState($g_UI_Interact[1][2], $GUI_SHOW); combobox
			GUICtrlSetState($g_UI_Static[1][2], $GUI_SHOW); language label
			GUICtrlSetState($g_UI_Interact[1][3], $GUI_HIDE); combobox
			GUICtrlSetState($g_UI_Static[1][3], $GUI_HIDE); install label
			GUICtrlSetState($g_UI_Button[0][1], $GUI_DISABLE)
		Else; the language-selection is already shown, can't go any further 
		EndIf
	EndIf
EndFunc   ;==>_Misc_SetWelcomeScreen

; ---------------------------------------------------------------------------------------------
; (De)activate the GUI-controls to fit the install-method
; ---------------------------------------------------------------------------------------------
Func _Misc_SwitchGUIToInstallMethod()
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Misc_SwitchGUIToInstallMethod')
	Local $Message = IniReadSection($g_TRAIni, 'UI-Buildtime')
	Local $State = $GUI_ENABLE
	Local $HideEET = 0; set this to 0 to enable EET
	Local $found = 0
	For $g = 1 To $g_GameList[0][0]
		If $g_Flags[14] = $g_GameList[$g][1] Then
			$found = 1
			ExitLoop
		EndIf
	Next
	If $found = 0 Then
		_PrintDebug('There is a problem with the internal configuration files. The BWS\Config\User.ini indicates that your current game type is "'&$g_Flags[14]&'" but no matching configuration was found. Please try restarting BWS using "with updates" to get the latest files; if that fails, please report this problem on one of the Big World Setup support forums.', 1)
		Exit
	EndIf
	_Misc_Set_GConfDir($g_GameList[$g][0])
	GUICtrlSetData($g_UI_Interact[1][3], $g_GameList[$g][2])
	GUICtrlSetState($g_UI_Static[2][1], $GUI_HIDE)
	GUICtrlSetState($g_UI_Interact[2][1], $GUI_HIDE); hide BG1/BG1EE-for-BGT/EET-folder by default
	GUICtrlSetState($g_UI_Button[2][1], $GUI_HIDE)
	GUICtrlSetState($g_UI_Static[2][2], $GUI_SHOW)
	GUICtrlSetState($g_UI_Interact[2][2], $GUI_SHOW); show BG1EE/BG2/BG2EE/IWD1/IWD2/PST folder by default
	GUICtrlSetState($g_UI_Button[2][2], $GUI_SHOW)
	GUICtrlSetPos($g_UI_Static[2][1], 30, 85, 370, 15)
	GUICtrlSetPos($g_UI_Interact[2][1], 30, 100, 300, 20); BG1/BG1EE-for-BGT/EET-folder default position
	GUICtrlSetPos($g_UI_Button[2][1], 350, 100, 50, 20)
	GUICtrlSetPos($g_UI_Static[2][2], 30, 135, 370, 15)
	GUICtrlSetPos($g_UI_Interact[2][2], 30, 150, 300, 20); BG2/BG2EE/IWD1/IWD2/PST folder default position
	GUICtrlSetPos($g_UI_Button[2][2], 350, 150, 50, 20)
	GUICtrlSetPos($g_UI_Static[2][3], 30, 190, 370, 15)
	GUICtrlSetPos($g_UI_Interact[2][3], 30, 205, 300, 20); download folder position same for all game types
	GUICtrlSetPos($g_UI_Button[2][3], 350, 205, 50, 20)
	If StringRegExp($g_Flags[14], 'BWS|BWP|BG2EE') Then; includes BGT/EET
		If $g_Flags[14] = 'BG2EE' Then; BG2EE or EET
			If $HideEET Then
				GUICtrlSetState($g_UI_Static[2][1], $GUI_HIDE)
				GUICtrlSetState($g_UI_Interact[2][1], $GUI_HIDE); hide BG1EE folder
				GUICtrlSetState($g_UI_Button[2][1], $GUI_HIDE)
				GUICtrlSetData($g_UI_Interact[2][1], '-'); disable BG1EE-folder tests
			Else; EET is enabled
				GUICtrlSetData($g_UI_Static[2][1], "Baldur's Gate I: Enhanced Edition, put '-' if you want only BG2:EE")
				GUICtrlSetState($g_UI_Static[2][1], $GUI_SHOW)
				GUICtrlSetState($g_UI_Interact[2][1], $GUI_SHOW); show BG1EE-for-EET folder
				GUICtrlSetState($g_UI_Button[2][1], $GUI_SHOW)
				_Test_GetGamePath('BG1EE')
				GUICtrlSetData($g_UI_Interact[2][1], $g_BG1EEDir)
			EndIf
			_Test_GetGamePath('BG2EE')
			$g_GameDir = $g_BG2EEDir; use BG2EEDir for now even if EET is enabled
			GUICtrlSetData($g_UI_Interact[2][2], $g_BG2EEDir)
		Else; BWS/BWP - includes BGT
			GUICtrlSetData($g_UI_Static[2][1], "Baldur's Gate I, put '-' if you want only BG2")
			GUICtrlSetState($g_UI_Static[2][1], $GUI_SHOW)
			GUICtrlSetState($g_UI_Interact[2][1], $GUI_SHOW); show BG1-for-BGT folder
			GUICtrlSetState($g_UI_Button[2][1], $GUI_SHOW)
			_Test_GetGamePath('BG1')
			_Test_GetGamePath('BG2')
			$g_GameDir = $g_BG2Dir
			GUICtrlSetData($g_UI_Interact[2][1], $g_BG1Dir)
			GUICtrlSetData($g_UI_Interact[2][2], $g_BG2Dir)
		EndIf
		If $g_Flags[14] = 'BWP' Then
			$g_Flags[21] = 1; sort components according to PDF
			$State = $GUI_DISABLE
			GUICtrlSetState($g_UI_Menu[1][16], $GUI_CHECKED)
			GUICtrlSetState($g_UI_Interact[14][8], $GUI_UNCHECKED); will be asked by batch
		Else;If StringRegExp($g_Flags[14], 'BWS|BG2EE)' Then
			$g_Flags[21] = 0; sort components by theme
			GUICtrlSetState($g_UI_Menu[1][16], $GUI_UNCHECKED)
		EndIf
;	ElseIf $g_Flags[14] = 'BG1EE' Then; hide BG2EE folder and reposition GUI-controls
;		GUICtrlSetState($g_UI_Static[2][2], $GUI_HIDE)
;		GUICtrlSetState($g_UI_Interact[2][2], $GUI_HIDE); hide BG2EE folder
;		GUICtrlSetState($g_UI_Button[2][2], $GUI_HIDE)
;		GUICtrlSetData($g_UI_Interact[2][2], '-'); disable BG2EE-folder tests
;		GUICtrlSetPos($g_UI_Static[2][1], 30, 135, 370, 15)
;		GUICtrlSetPos($g_UI_Interact[2][1], 30, 150, 300, 20); move BG1EE folder down
;		GUICtrlSetPos($g_UI_Button[2][1], 350, 150, 50, 20)
;		GUICtrlSetData($g_UI_Static[2][1], "Baldur's Gate I: Enhanced Edition")
;		GUICtrlSetState($g_UI_Static[2][1], $GUI_SHOW)
;		GUICtrlSetState($g_UI_Interact[2][1], $GUI_SHOW); show BG1EE folder
;		GUICtrlSetState($g_UI_Button[2][1], $GUI_SHOW)
;		_Test_GetGamePath('BG1EE')
;		$g_GameDir = $g_BG1EEDir
;		GUICtrlSetData($g_UI_Interact[2][1], $g_BG1EEDir)
	Else; for other game types, just disable BG1/BG1EE-for-BGT/EET-folder tests
		GUICtrlSetData($g_UI_Interact[2][1], '-'); disable BG1/BG1EE-for-BGT/EET-folder tests
		_Test_GetGamePath($g_Flags[14])
		$g_GameDir = Eval('g_' & $g_Flags[14] & 'Dir')
		GUICtrlSetData($g_UI_Interact[2][2], $g_GameDir)
	EndIf
	GUICtrlSetBkColor($g_UI_Button[2][1], Default)
	GUICtrlSetColor($g_UI_Button[2][1], Default)
	GUICtrlSetBkColor($g_UI_Button[2][2], Default)
	GUICtrlSetColor($g_UI_Button[2][2], Default)
	GUICtrlSetData($g_UI_Static[2][2], _GetGameName()); game-folder
	GUICtrlSetData($g_UI_Static[3][1], StringFormat(_GetSTR($Message, 'Static[3][1]'), $g_Flags[14])); => backup hint
	GUICtrlSetData($g_UI_Interact[3][4], StringFormat(_GetSTR($Message, 'Interact[3][4]'), _GetGameName(), $g_Flags[14], $g_Flags[14])); => backup help
	$g_ModIni = $g_GConfDir & '\Mod.ini'
	_GetGlobalData()
	$g_Setups = _CreateList('s')
	If Not StringRegExp($g_Flags[14], 'BWS|BWP') Then GUICtrlSetState($g_UI_Interact[14][8], $GUI_HIDE); hide additional textpatch-option
	GUICtrlSetState($g_UI_Interact[14][3], $State); install options
	GUICtrlSetState($g_UI_Interact[14][4], $State); install in groups
	GUICtrlSetState($g_UI_Interact[14][6], $State); desktop width
	GUICtrlSetState($g_UI_Interact[14][7], $State); desktop height
	GUICtrlSetState($g_UI_Interact[14][8], $State); install additional textpatch
	If StringInStr($g_Flags[14], 'EE') Then
		$State = $GUI_HIDE; BG1EE/BG2EE doesn't need widescreen mod for bigger resolutions
	Else
		$State = $GUI_SHOW
	EndIf
	For $i = 5 To 7
		GUICtrlSetState($g_UI_Interact[14][$i], $State)
	Next
EndFunc   ;==>_Misc_SwitchGUIToInstallMethod

; ---------------------------------------------------------------------------------------------
; Get the current language and switch if needed
; ---------------------------------------------------------------------------------------------
Func _Misc_SwitchLang()
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Misc_SwitchLang')
	Local $OldNum = $g_ATNum
	Local $Lang = GUICtrlRead($g_UI_Interact[1][2])
	Local $Split = StringSplit(_GetTR($g_UI_Message, '1-I1'), '|'); => available translations for the BWS
	For $s = 1 To $Split[0]
		If $Lang = $Split[$s] Then $g_ATNum = $s
	Next
	If $OldNum <> $g_ATNum Then
		IniWrite($g_UsrIni, 'Options', 'AppLang', $g_ATrans[$g_ATNum])
		$g_TRAIni = $g_ProgDir & '\Config\Translation-' & $g_ATrans[$g_ATNum] & '.ini'
		$g_UI_Message = IniReadSection($g_TRAIni, 'UI-Runtime')
		$g_Flags[10] = 1
		_Misc_SetLang()
		_Misc_SetAvailableSelection(); show preselection-descriptions
	EndIf
EndFunc   ;==>_Misc_SwitchLang

; ---------------------------------------------------------------------------------------------
; Enable or disable Widescreen checkbox if mod is deselected and vice versa
; ---------------------------------------------------------------------------------------------
Func _Misc_SwitchWideScreen($p_UserClicked = 0)
	If StringInStr($g_Flags[14], 'EE') Then Return; Widescreen already built into BG1EE/BG2EE
	Local $p_ID = $g_Flags[22]
	Local $p_State = $g_CentralArray[$p_ID][9]
	;FileWrite($g_LogFile, '_Misc_SwitchWideScreen '&$p_UserClicked&' $p_State = '&$p_State&@CRLF)
	If $p_UserClicked = 1 Then; read checkbox state and update the mod and UI appropriately
		If GUICtrlRead($g_UI_Interact[14][5]) = $GUI_CHECKED Then
			If $p_State = 0 Then _AI_SetSTD_Enable($p_ID)
			$p_State = 1
		Else;If GUICtrlRead($g_UI_Interact[14][5]) = $GUI_UNCHECKED Then
			If $p_State = 1 Then _AI_SetSTD_Disable($p_ID)
			$p_State = 0
		EndIf
	ElseIf $p_State = 0 Then; update checkbox state to match the mod state
		GUICtrlSetState($g_UI_Interact[14][5], $GUI_UNCHECKED)
	Else
		GUICtrlSetState($g_UI_Interact[14][5], $GUI_CHECKED)
	EndIf
	If $p_State = 1 Then
		If $g_Flags[14] <> 'BWP' Then; this is not a batch install
			GUICtrlSetState($g_UI_Interact[14][6], $GUI_Enable)
			GUICtrlSetState($g_UI_Interact[14][7], $GUI_Enable)
			If GUICtrlRead($g_UI_Interact[14][6]) = '' Then GUICtrlSetData($g_UI_Interact[14][6], @DesktopWidth)
			If GUICtrlRead($g_UI_Interact[14][7]) = '' Then GUICtrlSetData($g_UI_Interact[14][7], @DesktopHeight)
		EndIf
	Else;If $p_State = 0 Then
		GUICtrlSetState($g_UI_Interact[14][6], $GUI_DISABLE)
		GUICtrlSetState($g_UI_Interact[14][7], $GUI_DISABLE)
	EndIf
EndFunc   ;==>_Misc_SwitchWideScreen
