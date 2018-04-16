#include-once

; ---------------------------------------------------------------------------------------------
; Edit, remove, open or test items
; ---------------------------------------------------------------------------------------------
Func _Admin_ContextMenu($p_Lang, $p_Message)
	Local $MenuItem[6]=[5, 'a', 'b', 'c', 'd', 'e'], $Return
	$ID = GUICtrlRead($g_UI_Interact[11][4])
	$Text=StringSplit(GUICtrlRead($ID), '|')
	If $Text[0]=1 Then $ID=GUICtrlCreateDummy()
	$MenuLabel=$Text[1]
	$Text[1]=_Admin_ItemTranslate($Text[1], $p_Lang, 2); Link, Down, Save, Size, Test, NotFixed, REN, Wiki
	GUISetState(@SW_DISABLE); disable the GUI itself while selection is pending to avoid unwanted treeview-changes
	$g_UI_Menu[0][4] = GUICtrlCreateContextMenu($ID); create a context-menu on the clicked item
	If $Text[0]=1 Then
		$MenuItem[1] = GUICtrlCreateMenuItem(_GetTR($g_UI_Message, '4-L17'), $g_UI_Menu[0][4]); => new entry
	Else
		$MenuLabel = GUICtrlCreateMenuItem($MenuLabel, $g_UI_Menu[0][4])
		GUICtrlSetState(-1, $GUI_DISABLE)
		GUICtrlCreateMenuItem('', $g_UI_Menu[0][4]); separator
		$MenuItem[1] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[5][6], 1), $g_UI_Menu[0][4]); edit entry
		$MenuItem[2] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[5][7], 1), $g_UI_Menu[0][4]); delete entry
		If Not StringRegExp($Text[1], '(?i)Size|NotFixed|REN') Then $MenuItem[3] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[5][8], 1), $g_UI_Menu[0][4]); open entry
		If StringRegExp($Text[1], '(?i)Down|Save|Size|Test') Then $MenuItem[4] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[5][9], 1), $g_UI_Menu[0][4]); test enty
	EndIf
	GUICtrlCreateMenuItem('', $g_UI_Menu[0][4])
	$MenuItem[5] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[5][14], 1), $g_UI_Menu[0][4]); select all
	__ShowContextMenu($g_UI[0], $ID, $g_UI_Menu[0][4])
; ---------------------------------------------------------------------------------------------
; Create another Msg-loop, since the GUI is disabled and only the menuitems should be available
; ---------------------------------------------------------------------------------------------
		While 1
			$Msg = GUIGetMsg()
			Switch $Msg
			Case $MenuItem[1]; new/edit entry
				$Return=1
			Case $MenuItem[2]; delete entry
				$Return=2
			Case $MenuItem[3]; open entry
				$Return=3
			Case $MenuItem[4]; test entry
				$Return=4
			Case $MenuItem[5]; select all
				$Return=5
			Case Else
				If $Return Then ExitLoop
				If _IsPressed('01', $g_UDll) Then; react to a left mouseclick outside of the menu
					While  _IsPressed('01', $g_UDll)
						Sleep(10)
					WEnd
					ExitLoop
				ElseIf _IsPressed('02', $g_UDll) Then; react to a right mouseclick outside of the menu
					While  _IsPressed('02', $g_UDll)
						Sleep(10)
					WEnd
					ExitLoop
				EndIf
			EndSwitch
			Sleep(10)
		WEnd
		GUISetState(@SW_ENABLE); enable the GUI again
		GUICtrlDelete($g_UI_Menu[0][4])
		Switch $Return
			Case 1
				If $Text[0]=1 Then GUICtrlDelete($ID); delete the dummy-control
				_Admin_ItemEdit($Text[0])
			Case 2
				_Admin_ItemDelete()
			Case 3
				_Admin_ItemOpen($ID, $p_Lang)
			Case 4
				_Admin_ItemTest($ID, $p_Lang, $p_Message)
			Case 5
				ControlListView($g_UI[0], '', $g_UI_Interact[11][4], 'SelectAll')
		EndSwitch
EndFunc    ;==>_Admin_ContextMenu

; ---------------------------------------------------------------------------------------------
; Delete selected LVitems
; ---------------------------------------------------------------------------------------------
Func _Admin_ItemDelete()
	If $g_Flags[16]=0 Then
		$Act=ControlGetHandle($g_UI[0], '', ControlGetFocus($g_UI[0]))
		If _WinAPI_GetClassName($Act) = 'Edit' Then ControlSend($g_UI[0], '', $Act, '{BACKSPACE}'); mark text if markable
		Return; LV is not focused
	EndIf
	$List=StringSplit(ControlListView($g_UI[0], '', $g_UI_Interact[11][4], 'GetSelected', 1), '|')
	For $l=$List[0] to 1 Step -1
		GUICtrlDelete(_GUICtrlListView_GetItemParam($g_UI_Interact[11][4], $List[$l]))
	Next
EndFunc   ;==>_Admin_ItemDelete

; ---------------------------------------------------------------------------------------------
; Message-loop to modify a mods listview-item
; ---------------------------------------------------------------------------------------------
Func _Admin_ItemEdit($p_New=0)
	Local $Width[4]=[3, 170, 470, 30]
	$Current = GUICtrlRead($g_UI_Seperate[0][0])+1
	If $Current = 11 Then
		$LV=$g_UI_Interact[11][4]
		$Key=$g_UI_Interact[11][5]
		$Value=$g_UI_Interact[11][6]
		$Save=$g_UI_Button[11][5]
		Local $Offset[5]=[4, 30, 220, 230, 705]; left top of lv, left value, left button
	Else
		$LV=$g_UI_Interact[12][2]
		$Key=$g_UI_Interact[12][5]
		$Value=$g_UI_Interact[12][6]
		$Save=$g_UI_Button[12][3]
		$State=BitAND(GUICtrlGetState($g_UI_Button[12][1]), $GUI_HIDE)
		If $State Then
			Local $Offset[5]=[4, 30, 90, 230, 705]
		Else
			$Pos=ControlGetPos($g_UI[0], '', $g_UI_Interact[12][2]); position of the LV
			Local $Offset[5]=[4, $Pos[0], 90, $Pos[0]+45, $Pos[0]+$Pos[2]-30]
			Local $Width[4]=[3, 40, 255, 30]; 400, 445, 705
		EndIf
	EndIf
	$Index=Number(ControlListView($g_UI[0], '', $LV, 'GetSelected'))
	$ID=GUICtrlRead($LV)
	$Text=StringSplit(GUICtrlRead($ID), '|')
	If $p_New = 1 Then
		Local $iPos[2]=[1, 40], $Text[3]
	Else
		If $Text[0] = 1 Then Return 0; nothing selected here -> get out to avoid crashes
		$iPos = _GUICtrlListView_GetSubItemRect($LV, $Index, 1)
	EndIf
	GUICtrlSetPos($Key, $Offset[1], $iPos[1]+$Offset[2], $Width[1])
	GUICtrlSetPos($Value, $Offset[3], $iPos[1]+$Offset[2], $Width[2])
	GUICtrlSetPos($Save, $Offset[4], $iPos[1]+$Offset[2], $Width[3])
	If $p_New = 1 Then; new
		GUICtrlSetData($Value, '')
		GUICtrlSetState($Key, $GUI_FOCUS)
	Else
		GUICtrlSetData($Key, $Text[1])
		GUICtrlSetData($Value, $Text[2])
		GUICtrlSetState($Value, $GUI_FOCUS)
	EndIf
	GUICtrlSetState($Key, $GUI_SHOW)
	GUICtrlSetState($Value, $GUI_SHOW)
	GUICtrlSetState($Save, $GUI_SHOW+$GUI_DEFBUTTON)
	GUICtrlSetState($LV, $GUI_HIDE)
	GUIGetMsg(); Get last message (in case enter was pressed, this would be the current default (e.g. $g_UI_Button[0][2])
	While 1
		$Msg=GUIGetMsg()
		Switch $Msg
			Case $Save
				Local $Error=0
				$Text[1]=GUICtrlRead($Key)
				$Text[2]=GUICtrlRead($Value)
				If StringRegExp($Text[1], '\A('&$g_Flags[6]&')\z')  And $Text[1] <> '' And $Text[2] <> '' Then
				Else
					_Misc_MsgGUI(3, _GetTR($g_UI_Message, '0-T1'), _GetTR($g_UI_Message, '11-L1')); => Save changes? Yes/No
					GUICtrlSetState($Key, $GUI_FOCUS)
					GUICtrlSetState($Save, $GUI_DEFBUTTON)
					ContinueLoop
				EndIf
				If $Current = 12 Then
					_Tra_ItemWriteEntry()
				Else
					If $p_New = 1 Then; new
						$Test=GUICtrlCreateListViewItem($Text[1]&'|'&$Text[2], $LV)
					Else
						GUICtrlSetData($ID, $Text[1]&'|'&$Text[2])
					EndIf
				EndIf
				ExitLoop
			Case Else
				If $Msg > 0 And Not StringRegExp($Msg, '\A('&$Key&'|'&$Value&')\z') Then ExitLoop
		EndSwitch
		Sleep(10)
	WEnd
	GUICtrlSetState($Key, $GUI_HIDE)
	GUICtrlSetState($Value, $GUI_HIDE)
	GUICtrlSetState($Save, $GUI_HIDE)
	GUICtrlSetState($LV, $GUI_SHOW+$GUI_FOCUS)
	GUICtrlSetState($g_UI_Button[0][2], $GUI_DEFBUTTON)
	While _IsPressed('0D', $g_UDll)
		Sleep(10)
	WEnd
	Return 1
EndFunc   ;==>_Admin_ItemEdit

; ---------------------------------------------------------------------------------------------
; Get current LVitems
; ---------------------------------------------------------------------------------------------
Func _Admin_ItemGet($p_Lang, $p_Selected='*')
	$Num = ControlListView($g_UI[0], '', $g_UI_Interact[11][4], 'GetItemCount')
	Local $Return[$Num+5][2], $Token[4][2]=[[3], [1, 'Name'], [2, 'Rev'], [8, 'Tra']]; 5 above = 3 tokens + type + 0-index in array
	$Return[0][0]=$Num+4
	For $n=1 to $Num
		$ID=_GUICtrlListView_GetItemParam($g_UI_Interact[11][4], $n-1)
		$Text=StringSplit(GUICtrlRead($ID), '|')
		$Return[$n][0]=_Admin_ItemTranslate($Text[1], $p_Lang, 2)
		$Return[$n][1]=$Text[2]
	Next
	For $t=1 to $Token[0][0]
		$Return[$Num+$t][0]=$Token[$t][1]
		$Return[$Num+$t][1]=GUICtrlRead($g_UI_Interact[11][$Token[$t][0]])
		If $Token[$t][0]=8 Then $Return[$Num+$t][1]=StringUpper($Return[$Num+$t][1]); make translation uppercase
	Next
	$Return[$Return[0][0]][0]='Type'
	$Return[$Return[0][0]][1]=_Admin_ModType(1, 1)
	If $p_Selected='*' Then
		Return $Return
	Else
		For $r=1 to $Return[0][0]
			If $Return[$r][0] = $p_Selected Then Return $Return[$r][1]
		Next
		Return ''
	EndIf
EndFunc   ;==>_Admin_ItemGet

; ---------------------------------------------------------------------------------------------
; Open url or file via ShellExecute
; ---------------------------------------------------------------------------------------------
Func _Admin_ItemOpen($p_ID, $p_Lang)
	$String=StringSplit(GUICtrlRead($p_ID), '|')
	$String[1]=_Admin_ItemTranslate($String[1], $p_Lang, 2); Link, Down, Save, Size, Test, NotFixed, REN, Wiki
	If StringRegExp($String[1], '(?i)Link|Down') Then; open in webbrowser
		ShellExecute($String[2])
	ElseIf StringInStr($String[1], 'Test') Then; open test-file
		ShellExecute($g_GameDir&'\'&StringLeft($String[2], StringInStr($String[2], ':')-1))
	ElseIf $String[1] = 'Wiki' Then; wiki-page
		ShellExecute('http://kerzenburg.baldurs-gate.eu/wiki/'&$String[2])
	ElseIf StringInStr($String[1], 'Save') Then
		ShellExecute($g_DownDir&'\'&$String[2]); file
	EndIf
EndFunc   ;==>_Admin_ItemOpen

; ---------------------------------------------------------------------------------------------
; Loop through the items of _Admin_ItemGet and set the value of the selected LVitem
; ---------------------------------------------------------------------------------------------
Func _Admin_ItemSet($p_List, $p_Selected, $p_String)
	For $l=1 to $p_List[0][0]
		If $p_List[$l][0]<>$p_Selected Then ContinueLoop
		$ID=_GUICtrlListView_GetItemParam($g_UI_Interact[11][4], $l-1)
		$Text=StringSplit(GUICtrlRead($ID), '|')
		GUICtrlSetData($ID, $Text[1]&'|'&$p_String)
		Return 1
	Next
	Return 0
EndFunc   ;==>_Admin_ItemSet

; ---------------------------------------------------------------------------------------------
; Test if the current setting is valid. Works with urls, filenames and sizes
; ---------------------------------------------------------------------------------------------
Func _Admin_ItemTest($p_ID, $p_Lang, $p_Message)
	$String=StringSplit(GUICtrlRead($p_ID), '|')
	$Text=$String[1]
	$String[1]=_Admin_ItemTranslate($String[1], $p_Lang, 2); Link, Down, Save, Size, Test, NotFixed, REN, Wiki
	$List=_Admin_ItemGet($p_Lang)
	If StringInStr($String[1], 'Down') Then; download-test
		$Save=_IniRead($List, StringReplace($String[1], 'Down', 'Save'), '')
		$Size=_IniRead($List, StringReplace($String[1], 'Down', 'Size'), '')
		$Return=$Text&'|'&$String[2]&'|'&$Save&'|'&$Size&'||'
		$Test=_Net_LinkGetInfo($String[2], 1)
		If $Test[0] = 0 Then
			_Misc_MsgGUI(3, _GetTR($p_Message, 'L12'), $Return&_GetTR($p_Message, 'L14')); => Test: file not found
			Return
		EndIf
		$Test[1]=StringReplace(StringReplace($Test[1], '%20', ' '), '\', ''); set correct space
		If StringLower($Test[1]) <> StringLower($Save) Then $Return&=_GetTR($p_Message, 'L15')&$Test[1]&'|'; => name has changed
		If $Test[2] <> 0 And $Test[2] <> $Size Then $Return&=_GetTR($p_Message, 'L16')&$Test[2]&'|'; => size has changed
		If $Return = $Text&'|'&$String[2]&'|'&$Save&'|'&$Size&'||' Then
			_Misc_MsgGUI(1, _GetTR($p_Message, 'L12'), $Return&_GetTR($p_Message, 'L13')); => is correct
		Else
			$Return=_Misc_MsgGUI(2, _GetTR($p_Message, 'L12'), $Return&'|'&_GetTR($p_Message, 'L17'), 2, _GetTR($g_UI_Message, '0-B2'), _GetTR($g_UI_Message, '0-B1')); => save change
			If $Return=2 Then Return
			_Admin_ItemSet($List, StringReplace($String[1], 'Down', 'Save'), $Test[1])
			_Admin_ItemSet($List, StringReplace($String[1], 'Down', 'Size'), $Test[2])
		EndIf
	ElseIf StringInStr($String[1], 'Save') Then; file-test
		$Size=_IniRead($List, StringReplace($String[1], 'Save', 'Size'), '')
		$Return=$Text&'|'&$String[2]&'|'&$Size&'||'
		If Not FileExists($g_DownDir&'\'&$String[2]) Then
			_Misc_MsgGUI(3, _GetTR($p_Message, 'L12'), $Return&_GetTR($p_Message, 'L14')); => Test: file not found
			Return
		EndIf
		$Test=FileGetSize($g_DownDir&'\'&$String[2])
		If $Test = $Size Then
			_Misc_MsgGUI(1, _GetTR($p_Message, 'L12'), $Return&_GetTR($p_Message, 'L13')); => is correct
		Else
			$Return=_Misc_MsgGUI(2, _GetTR($p_Message, 'L12'), $Return&_GetTR($p_Message, 'L16')&$Test&'||'&_GetTR($p_Message, 'L17'), 2, _GetTR($g_UI_Message, '0-B2'), _GetTR($g_UI_Message, '0-B1')); => size changed; save change
			If $Return=2 Then Return
			_Admin_ItemSet($List, StringReplace($String[1], 'Save', 'Size'), $Test)
		EndIf
	ElseIf StringInStr($String[1], 'Size') Then; size-test
		$Save=_IniRead($List, StringReplace($String[1], 'Size', 'Save'), '')
		$Return=$Text&'|'&$Save&'|'&$String[2]&'||'
		If $Save = '' Then Return
		If Not FileExists($g_DownDir&'\'&$Save) Then
			_Misc_MsgGUI(3, _GetTR($p_Message, 'L12'), $Return&_GetTR($p_Message, 'L14')); => Test: file not found
			Return
		EndIf
		$Test=FileGetSize($g_DownDir&'\'&$Save)
		If $Test=$String[2] Then
			_Misc_MsgGUI(1, _GetTR($p_Message, 'L12'), $Return&_GetTR($p_Message, 'L13')); => is correct
		Else
			$Return=_Misc_MsgGUI(2, _GetTR($p_Message, 'L12'), $Return&_GetTR($p_Message, 'L16')&$Test&'||'&_GetTR($p_Message, 'L17'), 2, _GetTR($g_UI_Message, '0-B2'), _GetTR($g_UI_Message, '0-B1')); => size changed; save change
			If $Return=2 Then Return
			_Admin_ItemSet($List, $String[1], $Test)
		EndIf
	ElseIf StringInStr($String[1], 'Test') Then; test-test
		$File=StringSplit($String[2], ':')
		If $File[0] = 1 Then
			_Misc_MsgGUI(3, _GetTR($p_Message, 'L12'), _GetTR($p_Message, 'L9')); => Test: file not found
			Return
		EndIf
		$Return=$Text&'|'&$File[1]&'|'&$File[2]&'||'
		If Not FileExists($g_GameDir&'\'&$File[1]) Then
			_Misc_MsgGUI(3, _GetTR($p_Message, 'L12'), $Return&_GetTR($p_Message, 'L14')); => Test: file not found
			Return
		Else
			$Found=1
			If $File[2] <> '-' Then
				$Test=FileGetSize($g_GameDir&'\'&$File[1])
				If $Test <> $File[2] Then
					$Return=_Misc_MsgGUI(2, _GetTR($p_Message, 'L12'), $Return&_GetTR($p_Message, 'L16')&$Test&'||'&_GetTR($p_Message, 'L17'), 2, _GetTR($g_UI_Message, '0-B2'), _GetTR($g_UI_Message, '0-B1')); => size changed; save change
					If $Return=2 Then Return
					_Admin_ItemSet($List, $String[1], $File[1]&':'&$Test)
					$Found=0
				EndIf
			EndIf
			If $Found Then _Misc_MsgGUI(1, _GetTR($p_Message, 'L12'), $Return&_GetTR($p_Message, 'L13')); => is correct
		EndIf
	EndIf
EndFunc   ;==>_Admin_ItemTest

; ---------------------------------------------------------------------------------------------
; Replaced the ini-keys with understandable words
; ---------------------------------------------------------------------------------------------
Func _Admin_ItemTranslate($p_String, $p_Lang, $p_Dir=1)
	If $p_Dir=1 Then; translate ini-entries to self-explaining text
		For $l=1 to $p_Lang[0][0]
			$p_String = StringReplace($p_String, $p_Lang[$l][0], $p_Lang[$l][1])
		Next
	EndIf
	If $p_Dir=2 Then; translate self-explaining text back to ini-entries
		For $l=$p_Lang[0][0] to 1 Step -1
			$p_String = StringReplace($p_String, $p_Lang[$l][1], $p_Lang[$l][0])
		Next
	EndIf
	Return $p_String
EndFunc   ;==>_Admin_ItemTranslate

; ---------------------------------------------------------------------------------------------
; Clean the GUI-entries and set up some useful (empty) defaults
; ---------------------------------------------------------------------------------------------
Func _Admin_ModCreate($p_Lang, ByRef $p_Desc)
	Local $Clean[5]=[1, 2, 3, 7, 8], $Token[6+$g_ATrans[0]][2]=[[5+$g_ATrans[0]], ['Link', ''], ['Down', ''], ['Save', ''], ['Size', ''], ['Setup', 'new_bws_mod']]
	For $a=1 to $g_ATrans[0]
		$p_Desc[$a][0]='Desc-'&$g_ATrans[$a]
		$p_Desc[$a][1]=''
		$Token[5+$a][0]='Desc-'&$g_ATrans[$a]
		$Token[5+$a][1]=Random(1, 1000)
	Next
	GUICtrlSetData($g_UI_Interact[11][1], ' ', ' '); setups
	GUICtrlSetData($g_UI_Interact[11][2], ''); rev
	GUICtrlSetData($g_UI_Interact[11][3], ''); description
	GUICtrlSetData($g_UI_Interact[11][7], ' ', ' '); setup
	GUICtrlSetData($g_UI_Interact[11][8], ''); translation
	For $l=ControlListView($g_UI[0], '', $g_UI_Interact[11][4], 'GetItemCount') to 1 Step -1
		GUICtrlDelete(_GUICtrlListView_GetItemParam($g_UI_Interact[11][4], $l-1))
	Next
	For $t=1 to 4
		GUICtrlCreateListViewItem(_Admin_ItemTranslate($Token[$t][0], $p_Lang)&'|', $g_UI_Interact[11][4])
	Next
	_Admin_ModType(1)
	Return $Token
EndFunc   ;==>_Admin_ModCreate

; ---------------------------------------------------------------------------------------------
; Delete the current mod from the mod.ini, mod-XX.ini, weidu-XX.ini
; ---------------------------------------------------------------------------------------------
Func _Admin_ModDelete($p_Message, $p_Setup='', $p_Tra='')
	Local $Setup, $Tra
	If $p_Setup = '' Then
		$Setup=GUICtrlRead($g_UI_Interact[11][7])
		$Test=_Misc_MsgGUI(2, _GetTR($g_UI_Message, '0-T1'), StringFormat(_GetTR($p_Message, 'L11'), $Setup), 2, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2')); => Save changes? Yes/No
		If $Test = 1 Then Return 0; user does not want to save
	Else
		$Setup=$p_Setup
	EndIf
	If $p_Tra='' Then
		$Tra=GUICtrlRead($g_UI_Interact[11][8])
	Else
		$Tra=$p_Tra
	EndIf
	IniDelete($g_MODIni, $Setup)
	For $a=1 to $g_ATrans[0]
		IniDelete($g_GConfDir&'\Mod-'&$g_ATrans[$a]&'.ini', 'Description', $Setup)
	Next
	If $Tra <> '-' Then
		$Token=StringSplit($Tra, ',')
		For $t=1 to $Token[0]
			IniDelete($g_GConfDir&'\WeiDU-'&StringLeft($Token[$t], 2)&'.ini', $Setup)
		Next
	EndIf
	_ArrayDelete($g_Setups, _Admin_ModGetIndex($Setup)); now delete the entry from the combo-boxes
	$g_Setups[0][0]-=1
	_Admin_Populate(11, $p_Message)
	Return 1
	; game.ini ????
EndFunc   ;==>_Admin_ModDelete

; ---------------------------------------------------------------------------------------------
; Display the current settings for a mod
; ---------------------------------------------------------------------------------------------
Func _Admin_ModDisplay($p_Num, $p_Lang, ByRef $p_Desc)
	Local $Num = '', $Type[5]=[4, 'R', 'S', 'T', 'E']
	$Setup = GUICtrlRead($g_UI_Interact[11][$p_Num])
	If $Setup = '' Then Return
	If $p_Num = 1 Then
		$Num=_Admin_ModGetIndex($Setup, 1)
		If $Num = '' Then Return
		$Setup = $g_Setups[$Num][0]
	EndIf
	$p_Desc[0][0] = 0
	$ReadSection = IniReadSection($g_MODIni, $Setup)
	If @error Then Return; avoid crashes if notice is selected => select the mod
	ReDim $ReadSection[$ReadSection[0][0]+$g_ATrans[0]+2][2]
	_IniWrite($ReadSection, 'Setup', $Setup)
	For $a=1 to $g_ATrans[0]
		_IniWrite($ReadSection, 'Desc-'&$g_ATrans[$a], IniRead($g_GConfDir&'\Mod-'&$g_ATrans[$a]&'.ini', 'Description', $Setup, ''))
		_IniWrite($p_Desc, 'Desc-'&$g_ATrans[$a], IniRead($g_GConfDir&'\Mod-'&$g_ATrans[$a]&'.ini', 'Description', $Setup, ''), 'O')
	Next
	GUICtrlSetData($g_UI_Interact[11][1], _IniRead($ReadSection, 'Name', '')); name
	GUICtrlSetData($g_UI_Interact[11][2], _IniRead($ReadSection, 'Rev', '')); version/revision
	GUICtrlSetData($g_UI_Interact[11][3], StringReplace(_IniRead($ReadSection, 'Desc-'&GUICtrlRead($g_UI_Static[11][4]), ''), '|', @CRLF)); ext. information
	GUICtrlSetData($g_UI_Interact[11][7], $Setup); setup-file
	GUICtrlSetData($g_UI_Interact[11][8], _IniRead($ReadSection, 'Tra', '')); translation
	$Test=_IniRead($ReadSection, 'Type', '')
	For $t=1 to $Type[0]
		If StringInStr($Test, $Type[$t]) Then
			_Admin_ModType($t)
			ExitLoop
		EndIf
	Next
	_GUICtrlListView_DeleteAllItems($g_UI_Interact[11][4])
	For $r=1 to $ReadSection[0][0]
		If StringRegExp($ReadSection[$r][0], '(?i)Desc|Name|Rev|Setup|Tra|Type') Then ContinueLoop
		$Test=GUICtrlCreateListViewItem(_Admin_ItemTranslate($ReadSection[$r][0], $p_Lang)&'|'&$ReadSection[$r][1], $g_UI_Interact[11][4])
	Next
	Return SetExtended($Num, $ReadSection)
EndFunc   ;==>_Admin_ModDisplay

; ---------------------------------------------------------------------------------------------
; Translate the mods name to setup and vice versa
; ---------------------------------------------------------------------------------------------
Func _Admin_ModGetIndex($p_String, $p_IsName=0)
	$Return = ''
	For $g=1 to $g_Setups[0][0]
		If $p_String = $g_Setups[$g][$p_IsName] Then
			$Return = $g
			ExitLoop
		EndIf
	Next
	Return $Return
EndFunc   ;==>_Admin_ModGetIndex

; ---------------------------------------------------------------------------------------------
; Message-loop to modify the mods setting - like URLs and files
; ---------------------------------------------------------------------------------------------
Func _Admin_ModGui($p_Mod = '')
	If Not IsDeclared('p_Mod') Then $p_Mod='-'
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Admin_ModGui')
	Local $Message = IniReadSection($g_TRAIni, 'Admin')
	Local $ATNum=$g_ATNum; enable local changes of the language without any global effects
	Local $ReadSection, $s, $Combo, $Switch=0, $Desc[$g_ATrans[0]+1][2]
	$Desc[0][0]=$g_ATrans[0]
	If $g_Flags[10]=0 Then $g_Flags[10]=GUICtrlRead($g_UI_Seperate[0][0])+1
; =================  define hotkeys   ======================
	Local $List[5] = [4, '!1', '!2', '!m', '!d'], $Accel[5]
	Local $AccelKeys[9][2] = [["!{Left}", $g_UI_Button[0][1]], ["!{Right}", $g_UI_Button[0][2]], ["!{Down}", $g_UI_Static[11][5]], ["!{Up}", $g_UI_Static[11][8]], _
		['^n', $g_UI_Menu[5][13]], ['^s', $g_UI_Menu[5][2]], ['^x', $g_UI_Menu[5][7]], ['{F2}', $g_UI_Menu[5][6]], ['^a', $g_UI_Menu[5][14]]]
	For $l=1 to $List[0]
		$Accel[$l]=GUICtrlCreateDummy(); create some dummys to "connect" accelerators
		ReDim $AccelKeys[UBound($AccelKeys)+1][2]
		$AccelKeys[UBound($AccelKeys)-1][0]=$List[$l]
		$AccelKeys[UBound($AccelKeys)-1][1]=$Accel[$l]
	Next
	GUISetAccelerators($AccelKeys)
; ==============  translation preparation  =================
	$Test=StringSplit(_GetTR($g_UI_Message, '15-L1'), '|'); => language as token
	$Text=StringSplit(_GetTR($g_UI_Message, '15-I1'), '|'); => language as word
	$Trans=StringSplit(_GetTR($Message, 'I1'), '|'); => token as word
	Local $Token[10][2]=[[9], ['Link', $Trans[1]], ['Down', $Trans[2]], ['Save', $Trans[3]], ['Size', $Trans[4]], _
		['Test', $Trans[5]], ['-Add', $Trans[6]], ['Add', $Trans[7]], ['NotFixed', $Trans[8]], ['REN', $Trans[9]]]
	Local $Lang[$Token[0][0]+$Test[0]+1][2]
	$Lang[0][0]=$Token[0][0]+$Test[0]
	For $t=1 to $Test[0]
		$Lang[$t][0]=$Test[$t]&'-'
		$Lang[$t][1]=$Text[$t]&': -'
	Next
	For $t=1 to $Token[0][0]
		For $d=0 to 1
			$Lang[$t+$Test[0]][$d]=$Token[$t][$d]
		Next
	Next
	$Prefix='|Add'
	For $t=1 to $Test[0]
		$Prefix&='|'&$Test[$t]&'-Add'
	Next
	$Prefix=StringSplit($Prefix, '|')
	For $p=1 to $Prefix[0]
		For $t=2 to 5
			$Combo&='|'&$Prefix[$p]&$Token[$t][0]
		Next
	Next
	$g_Flags[5]='Link|Wiki|REN|NotFixed|Name|Rev|Tra|Type'&$Combo
	$g_Flags[6]=_Admin_ItemTranslate('Link|Wiki|REN|NotFixed|Name|Rev|Tra|Type'&$Combo, $Lang)
	GUICtrlSetData($g_UI_Static[11][4], $g_ATrans[$g_ATNum]); reset language at startup
	GUICtrlSetData($g_UI_Interact[11][5], '|'&$g_Flags[6])
; =============  select first displayed mod  ===============
	_Admin_Populate(11, $Message)
	If $p_Mod = '' Or $p_Mod = '-' Then
	Else
		$s=_Admin_ModGetIndex($p_Mod, 0)
		If $s = '' Then $s = 1
		GUICtrlSetData($g_UI_Interact[11][1], $g_Setups[$s][1])
		$ReadSection=_Admin_ModDisplay(1, $Lang, $Desc)
	EndIf
	_Misc_SetTab(11)
	While 1
		If $g_Flags[16]=1 And _IsPressed('0D', $g_UDll) Then; enter was pressed
			While _IsPressed('0D', $g_UDll)
				Sleep(10)
			WEnd
			_Admin_ItemEdit()
		ElseIf $g_Flags[16]=2 Then
			_Admin_Contextmenu($Lang, $Message)
			$g_Flags[16]=1
		EndIf
		$aMsg = GUIGetMsg()
;~ 		If StringRegExp($aMsg, '\A0|-11\z') = 0 Then ConsoleWrite($aMsg & @CRLF)
		Switch $aMsg
			Case 0; nothing happend
				Sleep(10)
				ContinueLoop
			Case -11; mouse moved
				Sleep(10)
				ContinueLoop
			Case $Gui_Event_Close; close
				ExitLoop
			Case $g_UI_Button[0][1]; previous mod
				If $s>1 Then
					$s-=1
					GUICtrlSetData($g_UI_Interact[11][7], $g_Setups[$s][0])
					$ReadSection=_Admin_ModDisplay(7, $Lang, $Desc)
				EndIf
			Case $g_UI_Button[0][2]; next mod
				If $s<$g_Setups[0][0] Then
					$s+=1
					GUICtrlSetData($g_UI_Interact[11][7], $g_Setups[$s][0])
					$ReadSection=_Admin_ModDisplay(7, $Lang, $Desc)
				EndIf
			Case $g_UI_Button[0][3]; exit
				ExitLoop
			Case $g_UI_Button[11][6]; edit button
				$Switch=12
				ExitLoop
			Case $g_UI_Interact[11][1]
				$ReadSection=_Admin_ModDisplay(1, $Lang, $Desc)
				$s=@extended
			Case $g_UI_Interact[11][7]
				$ReadSection=_Admin_ModDisplay(7, $Lang, $Desc)
			Case $Accel[1]; !1 upper panel
				GUICtrlSetState($g_UI_Interact[11][3], $GUI_FOCUS)
			Case $Accel[2]; !2 lower panel
				GUICtrlSetState($g_UI_Interact[11][4], $GUI_FOCUS)
			Case $Accel[3]; !m focus mod input-control
				GUICtrlSetState($g_UI_Interact[11][7], $GUI_FOCUS)
			Case $Accel[4]; !d debug
				For $r=1 to $Desc[0][0]
					ConsoleWrite($Desc[$r][0]& ' ==> ' & $Desc[$r][1] & @CRLF)
				Next
				For $r=1 to $ReadSection[0][0]
					ConsoleWrite($ReadSection[$r][0]& ' ==> ' & $ReadSection[$r][1] & @CRLF)
				Next

			Case $g_UI_Static[11][1]
				__ShowContextMenu($g_UI[0], $g_UI_Static[11][1], $g_UI_Menu[5][0])
			Case $g_UI_Static[11][5]; change language backwards
				_IniWrite($Desc, 'Desc-'&$g_ATrans[$ATNum], StringReplace(GUICtrlRead($g_UI_Interact[11][3]), @CRLF, '|'), 'O')
				ConsoleWrite($g_ATrans[$ATNum] & ' == ' & StringReplace(GUICtrlRead($g_UI_Interact[11][3]), @CRLF, '|')  & @CRLF)
				$ATNum-=1
				If $ATNum < 1 Then $ATNum = $g_ATrans[0]
				GUICtrlSetData($g_UI_Static[11][4], $g_ATrans[$ATNum])
				GUICtrlSetData($g_UI_Interact[11][3], StringReplace(_IniRead($Desc, 'Desc-'&$g_ATrans[$ATNum], ''), '|', @CRLF)); ext. information
			Case $g_UI_Static[11][8]; change language forward
				_IniWrite($Desc, 'Desc-'&$g_ATrans[$ATNum], StringReplace(GUICtrlRead($g_UI_Interact[11][3]), @CRLF, '|'), 'O')
				ConsoleWrite($g_ATrans[$ATNum] & ' == ' & StringReplace(GUICtrlRead($g_UI_Interact[11][3]), @CRLF, '|')  & @CRLF)
				$ATNum+=1
				If $ATNum > $g_ATrans[0] Then $ATNum = 1
				GUICtrlSetData($g_UI_Static[11][4], $g_ATrans[$ATNum])
				GUICtrlSetData($g_UI_Interact[11][3], StringReplace(_IniRead($Desc, 'Desc-'&$g_ATrans[$ATNum], ''), '|', @CRLF)); ext. information
			Case $g_UI_Menu[5][1]; new mod
				$Success=_Admin_ModSave($ReadSection, $Desc, $Lang, $Message, 1); peek if there's something to save, ask if there is
				If $Success Then
					$ATNum = $g_ATNum
					GUICtrlSetData($g_UI_Static[11][4], $g_ATrans[$ATNum])
					$ReadSection=_Admin_ModCreate($Lang, $Desc)
				EndIf
			Case $g_UI_Menu[5][2]; save mods links etc
				$Success=_Admin_ModSave($ReadSection, $Desc, $Lang, $Message)
				ConsoleWrite('**'&$Success & @CRLF)
			Case $g_UI_Menu[5][3]; delete mod
				_Admin_ModDelete($Message)
			Case $g_UI_Menu[5][4]; discard changes
				_Admin_ModDisplay(7, $Lang, $Desc)
			Case $g_UI_Menu[5][6]; edit entry
				_Admin_ItemEdit()
			Case $g_UI_Menu[5][7]; delete entry
				_Admin_ItemDelete()
			Case $g_UI_Menu[5][8]; open entry
				_Admin_ItemOpen(GUICtrlRead($g_UI_Interact[11][4]), $Lang)
			Case $g_UI_Menu[5][9]; test emtry
				_Admin_ItemTest(GUICtrlRead($g_UI_Interact[11][4]), $Lang, $Message)
; =================  update single mod =====================
			Case $g_UI_Menu[5][11]
#cs
				$Input = StringSplit(GUICtrlRead($g_UI_Interact[11][1]), '.: ', 1)
				If @error Then ContinueLoop
				_Net_SingleLinkUpdate($Input[2])
				$ReadSection=_Admin_ModDisplay(1, $Lang, $Desc)
#ce
			Case $g_UI_Menu[5][12]; administrate components
				$Switch = 12
				ExitLoop
			Case $g_UI_Menu[5][15]; administrate selection
				$Switch=16
				ExitLoop
			Case $g_UI_Menu[5][16]; administrate dependencies
				$Switch=13
				ExitLoop
			Case $g_UI_Menu[5][13]; create new entry
				_Admin_ItemEdit(1)
			Case $g_UI_Menu[5][14]; ^a select all
				If $g_Flags[16]=1 Then; LV is focused
					ControlListView($g_UI[0], '', $g_UI_Interact[11][4], 'SelectAll')
				Else
					$Act=ControlGetHandle($g_UI[0], '', ControlGetFocus($g_UI[0]))
					If _WinAPI_GetClassName($Act) = 'Edit' Then _GUICtrlEdit_SetSel($Act, 0, _GUICtrlEdit_GetTextLen($Act)); mark text if markable
				EndIf
		EndSwitch
		Sleep(10)
	WEnd
	$g_Flags[16]=0
	If $Switch Then
		$Setup = GUICtrlRead($g_UI_Interact[11][7])
		If $Setup = _GetTR($Message, 'C1') Then $Setup=''; => select mod
		If $Switch = 12 Then
			_Tra_Gui($Setup)
		ElseIf $Switch = 13 Then
			_Dep_Gui()
		ElseIf $Switch = 16 Then
			_Select_Gui()
		EndIf
	Else
		_Misc_SetTab($g_Flags[10])
		$g_Flags[10]=0
	EndIf
EndFunc   ;==>_Admin_ModGui

; ---------------------------------------------------------------------------------------------
; Save the current mods settings
; ---------------------------------------------------------------------------------------------
Func _Admin_ModSave($p_ReadSection, $p_Desc, $p_Lang, $p_Message, $p_peek=0)
	Local $Change[2], $Skip='(?)Desc|Setup', $Error, $Other, $Output, $Token, $Test[5]
	If Not IsArray($p_ReadSection) Then
		If $p_Peek = 1 Then
			Return 1; there was no previous selected mod
		Else
			Dim $p_ReadSection[2][2]=[[1], ['setup', 'new_bws_mod']]
		EndIf
	EndIf
	$Test[1] =_IniRead($p_ReadSection, 'Setup', '')
	$Setup = GUICtrlRead($g_UI_Interact[11][7])
; =============== work on descriptions first ===============
	_IniWrite($p_Desc, 'Desc-'&GUICtrlRead($g_UI_Static[11][4]), StringReplace(GUICtrlRead($g_UI_Interact[11][3]), @CRLF, '|'), 'O')
	For $a=1 to $g_ATrans[0]
		$New=_IniRead($p_Desc, 'Desc-'&$g_ATrans[$a], '')
		$Old=_IniRead($p_ReadSection, 'Desc-'&$g_ATrans[$a], '')
		If $New == $Old Then; compare includes upper/lowercase
		Else
			$Change[1]&='|'&$a
		EndIf
	Next
; =============== get other changes ========================
	Local $ReadSection=_Admin_ItemGet($p_Lang)
	For $r=1 to $p_ReadSection[0][0]; go through old entries
		If StringRegExp($p_ReadSection[$r][0], '(?i)'&$Skip) Then ContinueLoop
		$Skip&='|'&$p_ReadSection[$r][0]
		$New=_IniRead($ReadSection, $p_ReadSection[$r][0], '')
		If $New == $p_ReadSection[$r][1] Then; compare includes upper/lowercase
		Else
			$Change[0]&='|'&$p_ReadSection[$r][0]
		EndIf
	Next
	For $r=1 to $ReadSection[0][0]; go through new entries (to catch new ones obviously)
		$Token&='|'&$ReadSection[$r][0]
		If StringRegExp($ReadSection[$r][0], '(?i)'&$Skip) Then ContinueLoop
		$Skip&='|'&$ReadSection[$r][0]
		$Old=_IniRead($p_ReadSection, $ReadSection[$r][0], '')
		If $Old == $ReadSection[$r][1] Then; compare includes upper/lowercase
		Else
			$Change[0]&='|'&$ReadSection[$r][0]
		EndIf
	Next
	If $Test[1] = $Setup And $Change[0] = '' And $Change[1] = '' Then Return 1; nothing changed
	If $p_Peek= 1 Then
		$Test[0]=_Misc_MsgGUI(2, _GetTR($g_UI_Message, '0-B3'), _GetTR($p_Message, 'L1'), 2, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2')); => Save changes? Yes/No
		If $Test[0] = 2 Then Return 1; user does not want to save
	EndIf
	$Token&='|'
; ================ check for errors ========================
	If $Setup = _GetTR($p_Message, 'C1') Or $Setup = '' Then $Error&='|2'; => select a setup
	If StringRegExp($Setup, '(?i)\ASetup\x2d|\x2eexe\z') Then $Error&='|2'; correct setup-names
	If _IniRead($ReadSection, 'Name', '') = '' Then $Error&='|3'; mods name
	For $d=1 to $p_Desc[0][0]
		$p_Desc[$d][1]=StringRegExpReplace($p_Desc[$d][1], '(\r\n|\r|\n)', '|')
		If $p_Desc[$d][1]='' Then $Error&='|4'; no description
	Next
	If Not StringRegExp(_IniRead($ReadSection, 'Tra', ''), '(?i)\A((([A-Z]|-){2}\x3a\d{1,})(|\x2c)){1,}\z') Then $Error&='|5'; translation-fault
	For $r=1 to $ReadSection[0][0]
		If StringInStr($ReadSection[$r][0], 'Down') Then
			$URL=$ReadSection[$r][1]
			If $URL<>'MANUAL' AND StringRegExp($URL, '\A(http:|https:|ftp:)')=0 Then $Error&='|6'; URL
			$Save=_IniRead($ReadSection, StringReplace($ReadSection[$r][0], 'Down', 'Save'), '')
			$Size=_IniRead($ReadSection, StringReplace($ReadSection[$r][0], 'Down', 'Size'), '')
			If $Save <> '' And $Size <> '' Then; filename and site are defined
				If $Save <>'MANUAL' AND StringRegExp($Size, '\A\d{1,}\z')=0 Then $Error&='|7'; size
			Else
				$Error&='|8'; missing size/save-entry
			EndIf
		ElseIf StringInStr($ReadSection[$r][0], 'Test') Then
			If StringRegExp($ReadSection[$r][1], '\x3a(\d{1,}|\x2d)\z') = 0 Then $Error&='|9'; test
		EndIf
		If StringRegExp($ReadSection[$r][0], '\A('&$g_Flags[5]&')\z') = 0 Then $Error&='|10'; false token
	Next
; ================ show the errors =========================
	If $Error <> '' Then
		$Error=StringSplit(StringTrimLeft($Error, 1), '|')
		For $e=1 to $Error[0]
			$Output &= '|||'&_GetTR($p_Message, 'L'&$Error[$e]); =>multiple failures...
		Next
		_Misc_MsgGUI(4, _GetTR($p_Message, 'T1'), StringTrimLeft($Output, 3)); =>invalid configuration
		Return 0; abort the saving process
	EndIf
; ================ see if setup is renamed ==================
	If $Setup <> $Test[1] And $Test[1] <> 'new_bws_mod' Then
		$Test[2]=_Misc_MsgGUI(2, _GetTR($g_UI_Message, '0-B3'), _GetTR($p_Message, 'L40')&@CRLF&@CRLF&_GetTR($p_Message, 'L41')&@CRLF&@CRLF&_GetTR($p_Message, 'L17'), 2, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2')); => Mod exists. Save changes? Not that it affects mods only. Yes/No
		If $Test[2] = 1 Then Return 0; user does not want to rename
	EndIf
; ================ see if setup is overwritten ==============
	If $Test[1] = 'new_bws_mod' Then; new mod
		$Found=0
		For $s=1 to $g_Setups[0][0]
			If $g_Setups[$s][0]=$Setup Then
				$Found = 1
				ExitLoop
			EndIf
		Next
		If $Found = 1 Then
			$Test[3]=_Misc_MsgGUI(2, _GetTR($g_UI_Message, '0-B3'), _GetTR($p_Message, 'L39')&@CRLF&@CRLF&_GetTR($p_Message, 'L41')&@CRLF&@CRLF&_GetTR($p_Message, 'L17'), 2, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2')); => Mod exists. Save changes? Not that it affects mods only. Yes/No
			If $Test[3] = 1 Then Return 0; user does not want to save
		EndIf
	EndIf
; =================== save values ===========================
	If $Test[2] <> '' Then
		_Admin_ModDelete($p_Message, $Test[1], '-'); renameing was verified
		$Token=StringSplit(_IniRead($p_ReadSection, 'Tra', ''), ',')
		For $t=1 to $Token[0]
			IniRenameSection($g_GConfDir&'\WeiDU-'&StringLeft($Token[$t], 2)&'.ini', $Test[1], $Setup, 1)
		Next
		$Change[0]='|Name'; force writing entries to new setup-name
		$Change[1]=''
		For $a=1 to $g_ATrans[0]
			$Change[1]&='|'&$a
		Next
	EndIf
	If $Change[0] <> '' Then
		$ToDo=StringSplit(StringTrimLeft($Change[0], 1), '|')
		For $t=1 to $ToDo[0]
			ConsoleWrite('>'&$ToDo[$t] & @CRLF)
		Next
		IniWriteSection($g_MODIni, $Setup, $ReadSection)
	EndIf
	If $Change[1] <> '' Then
		$ToDo=StringSplit(StringTrimLeft($Change[1], 1), '|')
		For $t=1 to $ToDo[0]
			ConsoleWrite($ToDo[$t] & ' ==> ' & $p_Desc[$ToDo[$t]][1] & @CRLF)
			IniWrite($g_GConfDir&'\Mod-'&$g_ATrans[$ToDo[$t]]&'.ini', 'Description', $Setup, $p_Desc[$ToDo[$t]][1])
		Next
	EndIf
	If $Test[1] <> 'new_bws_mod' And $Test[2] = '' Then Return 1; no new mod
; ============== make BWS recognize mod  ====================
	GUICtrlSetData($g_UI_Interact[11][1], _IniRead($ReadSection, 'Name', $Setup))
	GUICtrlSetData($g_UI_Interact[11][7], $Setup)
	If $Test[2] <> '' Then; if renaming was done, _Admin_ModDelete re-populated the entries and dropped the current settings
		GUICtrlSetData($g_UI_Interact[11][1], _IniRead($ReadSection, 'Name', $Setup))
		GUICtrlSetData($g_UI_Interact[11][7], $Setup)
	EndIf
	$g_Setups[0][0]+=1
	ReDim $g_Setups[$g_Setups[0][0]+1][3]
	$g_Setups[$g_Setups[0][0]][0]=$Setup
	$g_Setups[$g_Setups[0][0]][1]=_IniRead($ReadSection, 'Name', $Setup)
	GUICtrlSetState($g_UI_Static[11][7], $GUI_SHOW)
	Sleep(1000)
	GUICtrlSetState($g_UI_Static[11][7], $GUI_HIDE)
	Return 1
EndFunc   ;==>_Admin_ModSave

; ---------------------------------------------------------------------------------------------
; Set colors for type-buttons or test current selection
; ---------------------------------------------------------------------------------------------
Func _Admin_ModType($p_Num, $p_Test=0)
	Local $Return[5]=[4, 'R,S,T,E', 'S,T,E', 'T,E', 'E']
	If $p_Test=1 Then
		For $n=1 to 4
			If GUICtrlRead($g_UI_Button[11][$n]) = 1 Then Return $Return[$n]
		Next
		Return
	EndIf
	For $n=1 to 4
		If $n=$p_Num Then
			GUICtrlSetState($g_UI_Button[11][$n], $GUI_CHECKED)
		Else
			GUICtrlSetState($g_UI_Button[11][$n], $GUI_UNCHECKED)
		EndIf
	Next
EndFunc    ;==>_Admin_ModType

; ---------------------------------------------------------------------------------------------
; Get special events like double-clicks, focus and so on
; ---------------------------------------------------------------------------------------------
Func _Admin_Mod_WM_Notify($hWnd, $iMsg, $iwParam, $ilParam)
	#forceref $hWnd, $iMsg, $iwParam
	Local $hWndFrom, $iIDFrom, $iCode, $tNMHDR
	$tNMHDR = DllStructCreate($tagNMHDR, $ilParam)
	$hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
	$iIDFrom = DllStructGetData($tNMHDR, "IDFrom")
	$iCode = DllStructGetData($tNMHDR, "Code")

	Switch $hWndFrom
		Case $g_UI_Handle[2]
			Switch $iCode
				Case $NM_DBLCLK ; Sent by a list-view control when the user double-clicks an item with the left mouse button
					_Admin_ItemEdit()
				Case $NM_KILLFOCUS ; The control has lost the input focus
					$g_Flags[16]=0
				Case $NM_RCLICK ; Sent by a list-view control when the user clicks an item with the right mouse button
					$g_Flags[16]=2
				Case $NM_SETFOCUS ; The control has received the input focus
					$g_Flags[16]=1
			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>_Admin_Mod_WM_Notify

; ---------------------------------------------------------------------------------------------
; Populate comboboxes for mods setups and names
; ---------------------------------------------------------------------------------------------
Func _Admin_Populate($p_Tab, $p_Message)
	Local $Mods, $Setups = $g_Setups
	_ArraySort($Setups, 0, 1, 0, 1)
	For $s = 1 To $Setups[0][0]
		$Mods&='|' & $Setups[$s][1]
	Next
	$Setups = ''
	For $s = 1 To $g_Setups[0][0]
		$Setups&='|'&$g_Setups[$s][0]
	Next
	$Mods='|'&_GetTR($p_Message, 'C1')&$Mods; => select mod
	$Setups='|'&_GetTR($p_Message, 'C1')&$Setups; => select mod
	If $p_Tab = 11 Then
		GUICtrlSetData($g_UI_Interact[11][1], $Mods, _GetTR($p_Message, 'C1')); =>Select the mod
		GUICtrlSetData($g_UI_Interact[11][7], $Setups, _GetTR($p_Message, 'C1')); =>Select the mod
	ElseIf $p_Tab = 12 Then
		GUICtrlSetData($g_UI_Interact[12][7], $Mods, _GetTR($p_Message, 'C1')); =>Select the mod
		GUICtrlSetData($g_UI_Interact[12][3], $Setups, _GetTR($p_Message, 'C1')); =>Select the mod
	ElseIf $p_Tab = 13 Then
		GUICtrlSetData($g_UI_Interact[13][6], $Mods, _GetTR($p_Message, 'C1')); =>Select the mod
		GUICtrlSetData($g_UI_Interact[13][7], $Setups, _GetTR($p_Message, 'C1')); =>Select the mod
	ElseIf $p_Tab = 16 Then
		GUICtrlSetData($g_UI_Interact[16][1], $Mods, _GetTR($p_Message, 'C1')); =>Select the mod
		GUICtrlSetData($g_UI_Interact[16][4], $Setups, _GetTR($p_Message, 'C1')); =>Select the mod
	EndIf
	Return 0
EndFunc   ;==>_Admin_Populate

; ---------------------------------------------------------------------------------------------
; Put components of the same mod and type together
; ---------------------------------------------------------------------------------------------
Func _Dep_Compact($p_Array, $p_Type, $p_Delimiter, $p_Compact=1)
	Local $Return
	For $a=1 to $p_Array[0][0]
		If Not ($p_Array[$a][0]<>'' And $p_Array[$a][2]=$p_Type) Then ContinueLoop
		If $p_Compact Then
			For $b=1 to $p_Array[0][0]
				If $a <> $b And $p_Array[$a][0] = $p_Array[$b][0] And $p_Array[$a][2] = $p_Array[$b][2] Then
					$p_Array[$a][1]&=$p_Delimiter&$p_Array[$b][1]
					$p_Array[$b][0]=''
				EndIf
			Next
		EndIf
		$Return&=$p_Delimiter&$p_Array[$a][0]&'('&$p_Array[$a][1]&')'
	Next
	Return StringTrimLeft($Return, 1)
EndFunc    ;==>_Dep_Compact

; ---------------------------------------------------------------------------------------------
; Edit, remove, open or test items
; ---------------------------------------------------------------------------------------------
Func _Dep_ContextMenu($p_Message, $p_Num)
	Local $MenuItem[6]=[5, 'a', 'b', 'c', 'd', 'e'], $Return
	$ID = GUICtrlRead($g_UI_Interact[13][$p_Num])
	$Text=StringSplit(GUICtrlRead($ID), '|')
	If $Text[0]=1 Then
		If $p_Num=3 Then Return
		$ID=GUICtrlCreateDummy()
	EndIf
	$MenuLabel=$Text[1]
	GUISetState(@SW_DISABLE); disable the GUI itself while selection is pending to avoid unwanted treeview-changes
	$g_UI_Menu[0][4] = GUICtrlCreateContextMenu($ID); create a context-menu on the clicked item
	If $Text[0]=1 Then
		$MenuItem[1] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[8][4], 1), $g_UI_Menu[0][4]); new entry
	ElseIf $p_Num=3 Then
		$MenuItem[3] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[8][6], 1), $g_UI_Menu[0][4]); delete entry
		$MenuItem[4] = GUICtrlCreateMenuItem(_GetTR($g_UI_Message, '16-B1'), $g_UI_Menu[0][4]); => up
		$MenuItem[5] = GUICtrlCreateMenuItem(_GetTR($g_UI_Message, '16-B2'), $g_UI_Menu[0][4]); => down
	Else
		$MenuLabel = GUICtrlCreateMenuItem($MenuLabel, $g_UI_Menu[0][4])
		GUICtrlSetState(-1, $GUI_DISABLE)
		GUICtrlCreateMenuItem('', $g_UI_Menu[0][4]); separator
		$MenuItem[1] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[8][4], 1), $g_UI_Menu[0][4]); new entry
		$MenuItem[2] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[8][5], 1), $g_UI_Menu[0][4]); edit enty
		$MenuItem[3] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[8][6], 1), $g_UI_Menu[0][4]); delete entry
	EndIf
	__ShowContextMenu($g_UI[0], $ID, $g_UI_Menu[0][4])
; ---------------------------------------------------------------------------------------------
; Create another Msg-loop, since the GUI is disabled and only the menuitems should be available
; ---------------------------------------------------------------------------------------------
		While 1
			$Msg = GUIGetMsg()
			Switch $Msg
			Case $MenuItem[1]; new entry
				$Return=1
			Case $MenuItem[2]; edit entry
				$Return=2
			Case $MenuItem[3]; delete entry
				$Return=3
			Case $MenuItem[4]; up
				$Return=4
			Case $MenuItem[5]; down
				$Return=5
			Case Else
				If $Return Then ExitLoop
				If _IsPressed('01', $g_UDll) Then; react to a left mouseclick outside of the menu
					While  _IsPressed('01', $g_UDll)
						Sleep(10)
					WEnd
					ExitLoop
				ElseIf _IsPressed('02', $g_UDll) Then; react to a right mouseclick outside of the menu
					While  _IsPressed('02', $g_UDll)
						Sleep(10)
					WEnd
					ExitLoop
				EndIf
			EndSwitch
			Sleep(10)
		WEnd
		GUISetState(@SW_ENABLE); enable the GUI again
		GUICtrlDelete($g_UI_Menu[0][4])
		Switch $Return
			Case 1
				If $Text[0]=1 Then GUICtrlDelete($ID); delete the dummy-control
				_Dep_ItemEdit(1, $p_Message)
			Case 2
				_Dep_ItemEdit(0, $p_Message)
			Case 3
				_Dep_Delete($p_Num)
			Case 4
				_Select_ItemSwitch('up', $g_UI_Interact[13][3])
			Case 5
				_Select_ItemSwitch('down', $g_UI_Interact[13][3])
		EndSwitch
EndFunc    ;==>_Dep_ContextMenu

; ---------------------------------------------------------------------------------------------
; Manage dependencies
; ---------------------------------------------------------------------------------------------
Func _Dep_Gui($p_Mod='-')
	If Not IsDeclared('p_Mod') Then $p_Mod='-'
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Dep_Gui')
	Local $Message = IniReadSection($g_TRAIni, 'Admin')
	Local $Switch=0
	If $g_Flags[10]=0 Then $g_Flags[10]=GUICtrlRead($g_UI_Seperate[0][0])+1
; =================  define hotkeys   ======================
	Local $List[2] = [1, '^f'], $Accel[2]
	Local $AccelKeys[4][2] = [['^s', $g_UI_Menu[8][1]], ['{F2}', $g_UI_Menu[8][5]], ['^n', $g_UI_Menu[8][4]], ['^x', $g_UI_Menu[8][6]]]
	For $l=1 to $List[0]
		$Accel[$l]=GUICtrlCreateDummy(); create some dummys to "connect" accelerators
		ReDim $AccelKeys[UBound($AccelKeys)+1][2]
		$AccelKeys[UBound($AccelKeys)-1][0]=$List[$l]
		$AccelKeys[UBound($AccelKeys)-1][1]=$Accel[$l]
	Next
	GUISetAccelerators($AccelKeys)
	GUICtrlSetData($g_UI_Interact[13][4], _GetTR($Message, 'C2')); => trigger if...
	GUICtrlSetData($g_UI_Interact[13][5], _GetTR($Message, 'C3')); => because of...
	_Admin_Populate(13, $Message)
	_Dep_Populate()
	While 1
		If $g_Flags[16]=1 And _IsPressed('0D', $g_UDll) Then; enter was pressed
			While _IsPressed('0D', $g_UDll)
				Sleep(10)
			WEnd
			_Dep_ItemEdit(0, $Message)
			GUISetAccelerators($AccelKeys); edit-section has its own accels
		ElseIf $g_Flags[16]=2 Then
			_Dep_Contextmenu($Message, 1)
			GUISetAccelerators($AccelKeys)
			$g_Flags[16]=1
		ElseIf $g_Flags[16]=3 Then
			_Dep_ItemEdit(0, $Message)
			GUISetAccelerators($AccelKeys)
			$g_Flags[16]=1
		EndIf
		$Msg = GUIGetMsg()
		Switch $Msg
			Case 0; nothing happend
				Sleep(10)
				ContinueLoop
			Case -11; mouse moved
				Sleep(10)
				ContinueLoop
			Case $Gui_Event_Close; close
				ExitLoop
			Case $g_UI_Static[13][1]
				__ShowContextMenu($g_UI[0], $g_UI_Static[13][1], $g_UI_Menu[8][0])
			Case $g_UI_Button[0][3]; exit
				ExitLoop
			Case $g_UI_Button[13][1]; search
				_Select_Search(13)
			Case $g_UI_Menu[8][1]; Save
				_Dep_Save()
			Case $g_UI_Menu[8][2]; Revert
				_Dep_Populate()
			Case $g_UI_Menu[8][4]; new entry
				_Dep_ItemEdit(1, $Message)
				GUISetAccelerators($AccelKeys)
			Case $g_UI_Menu[8][5]; edit entry
				_Dep_ItemEdit(0, $Message)
				GUISetAccelerators($AccelKeys)
			Case $g_UI_Menu[8][6]; delete entry
				_Dep_Delete(1)
			Case $g_UI_Menu[8][8]; administrate mods
				$Switch = 11
				ExitLoop
			Case $g_UI_Menu[8][9]; administrate components
				$Switch = 12
				ExitLoop
			Case $g_UI_Menu[8][10]; administrate selection
				$Switch = 16
				ExitLoop
			Case $Accel[1]; search
				GUICtrlSetState($g_UI_Interact[13][2], $GUI_FOCUS)
				GUICtrlSetState($g_UI_Button[13][1], $GUI_DEFBUTTON)
		EndSwitch
		Sleep(10)
	WEnd
	$g_Flags[16]=0
	$g_MLang = StringSplit($g_Flags[3]&' --', ' '); Restore setting
	If $Switch Then
		If $Switch = 11 Then
			_Admin_ModGui()
		ElseIf $Switch = 12 Then
			_Tra_Gui()
		ElseIf $Switch = 16 Then
			_Select_Gui()
		EndIf
	Else
		_Misc_SetTab($g_Flags[10])
		$g_Flags[10]=0
	EndIf
EndFunc    ;==>_Dep_Gui

; ---------------------------------------------------------------------------------------------
; Delete selected (may be multiple) entries
; ---------------------------------------------------------------------------------------------
Func _Dep_Delete($p_Num)
	$Num=ControlListView($g_UI[0], '', $g_UI_Interact[13][$p_Num], 'GetSelected', 1)
	$Num=StringSplit($Num, '|')
	For $n=$Num[0] to 1 Step -1
		GUICtrlDelete(_GUICtrlListView_GetItemParam($g_UI_Interact[13][$p_Num], $Num[$n]))
	Next
EndFunc   ;==>_Select_ItemDelete

; ---------------------------------------------------------------------------------------------
; Edit one connection
; ---------------------------------------------------------------------------------------------
Func _Dep_ItemCopyDep($p_Message)
	Local $Num[3], $Color=0, $Error
	$String=GUICtrlRead($g_UI_Interact[13][7])&'|'&GUICtrlRead($g_UI_Interact[13][8])&'|'&GUICtrlRead($g_UI_Interact[13][9])
	If StringInStr($String, _GetTR($p_Message, 'C1')) Then $Error&='28X'; => select mod
	$End=ControlListView($g_UI[0], '', $g_UI_Interact[13][3], 'GetItemCount')
	For $i=0 to $End-1
		$ID=_GUICtrlListView_GetItemParam($g_UI_Interact[13][3], $i)
		$Text=GUICtrlRead($ID)
		If StringInStr($Text, $String) Then $Error&='30X'
		If StringRight($Text, 3) = '|D|' Then
			$Num[1]+=1
		ElseIf StringRight($Text, 3) = '|C|' Then
			$Num[2]+=1
		Else
			$Num[0]&='|'&$ID
		EndIf
	Next
	If GUICtrlRead($g_UI_Interact[13][11]) = 1 Then
		$Type=_Dep_ItemGetSel(2, $p_Message)
		If $Type='DA' Then
			$Color = 0xFFA500; dependency
			$String&='|D'
			If $Num[2]<>'' Then $Error&='27'
		ElseIf $Type = 'C>' Then
			$Color = 0xFF0000; conflict
			$String&='|C'
			If $Num[1]<>'' Then $Error&='27'
		Else
			$Type=_Dep_ItemGetSel(1, $p_Message)
			If $Type = '' Then $Error&='28'
			If $Type = 1 And $Num[0] <> '' Then $Error&='29'
		EndIf
	ElseIf GUICtrlRead($g_UI_Interact[13][12]) = 1 Then
		$Type=_Dep_ItemGetSel(2, $p_Message)
		If $Type = '' Then $Error&='28X'
		If StringInStr ($Type, 'D') Then
			$Color = 0xFFA500; dependency
			$String&='|D'
			If $Num[2]<>'' Then $Error&='27'
			If $Type = 'D:' And $Num[1]<>'' Then $Error&='29'
		Else
			$Color = 0xFF0000; conflict
			$String&='|C'
			If $Type = 'C:' And $Num[2]<>'' Then $Error&='29'
			If $Num[1]<>'' Then $Error&='27'
		EndIf
	EndIf
	If $Error Then
		GUICtrlSetData($g_UI_Static[13][4], StringRegExpReplace(_GetTR($p_Message, 'L'&StringLeft($Error, 2)), '\x3a\x7c.*\z', '')); => get translations
		If StringInStr($Error, 'X') Then Return
	Else
		GUICtrlSetData($g_UI_Static[13][4], '')
	EndIf
	GUICtrlCreateListViewItem($String, $g_UI_Interact[13][3])
	If $Color Then GUICtrlSetBkColor(-1, $Color)
EndFunc   ;==>_Dep_ItemCopyDep

; ---------------------------------------------------------------------------------------------
; Edit one dependeny
; ---------------------------------------------------------------------------------------------
Func _Dep_ItemEdit($p_New, $p_Message)
	Local $Old, $s, $ReadSection=''
	Local $List[2] = [1, '^x'], $Accel[2]
	Local $AccelKeys[2][2] = [['^s', $g_UI_Button[13][4]], ['^c', $g_UI_Button[13][3]]]
	For $l=1 to $List[0]
		$Accel[$l]=GUICtrlCreateDummy(); create some dummys to "connect" accelerators
		ReDim $AccelKeys[UBound($AccelKeys)+1][2]
		$AccelKeys[UBound($AccelKeys)-1][0]=$List[$l]
		$AccelKeys[UBound($AccelKeys)-1][1]=$Accel[$l]
	Next
	GUISetAccelerators($AccelKeys)
	$Index=Number(ControlListView($g_UI[0], '', $g_UI_Interact[13][1], 'GetSelected'))
	If $Index=0 Then ControlListView($g_UI[0], '', $g_UI_Interact[13][1], 'Select', 0)
	$ID=_GUICtrlListView_GetItemParam($g_UI_Interact[13][1], $Index)
	$Text=StringSplit(GUICtrlRead($ID), '|')
	If $p_New = 0 Then
		Local $Old[3]=[$Index, $ID, $Text[3]]
		_Dep_ItemSetDep($Text[3], $p_Message)
		$s=_Dep_ItemSetComp(0, $ReadSection, $p_Message)
	Else
		Local $Old[3]=['', '', '']
		GUICtrlSetData($g_UI_Interact[13][6], _GetTR($p_Message, 'C1')); =>Select the mod
		GUICtrlSetData($g_UI_Interact[13][7], _GetTR($p_Message, 'C1')); =>Select the mod
		GUICtrlSetData($g_UI_Interact[13][8], '|')
		GUICtrlSetData($g_UI_Interact[13][9], '|')
		GUICtrlSetData($g_UI_Static[13][4], ''); set new/reset other comments
		GUICtrlSetData($g_UI_Interact[13][10], ''); reset connection-string
		GUICtrlSetData($g_UI_Interact[13][13], ''); reset name
		_GUICtrlListView_BeginUpdate($g_UI_Handle[5])
		_GUICtrlListView_DeleteAllItems($g_UI_Handle[5]); delete previous entries
		_GUICtrlListView_EndUpdate($g_UI_Handle[5])
	EndIf
	_Dep_ItemSwitch()
	GUIGetMsg(); Get last message (in case enter was pressed, this would be the current default (e.g. $g_UI_Button[0][2])
	While 1
		If $g_Flags[16]=1 And _IsPressed('0D', $g_UDll) Then; enter was pressed
			While _IsPressed('0D', $g_UDll)
				Sleep(10)
			WEnd
			$s=_Dep_ItemSetComp('-', $ReadSection, $p_Message)
		ElseIf $g_Flags[16]=2 Then
			_Dep_Contextmenu($p_Message, 3)
			$g_Flags[16]=1
		ElseIf $g_Flags[16]=3 Then
			$s=_Dep_ItemSetComp('-', $ReadSection, $p_Message)
			$g_Flags[16]=1
		EndIf
		$Msg = GUIGetMsg()
		Switch $Msg
			Case $g_UI_Button[0][3]
				ExitLoop
			Case $g_UI_Button[13][3]; copy item
				_Dep_ItemCopyDep($p_Message)
			Case $g_UI_Button[13][4]; save item
				If _Dep_ItemSave($p_Message, $Old) = 1 Then ExitLoop
			Case $g_UI_Interact[13][5]; changed type
				$Type=_Dep_ItemGetSel(2, $p_Message)
				If $Type='C>' Then
					$String= _GetTR($p_Message, 'L31'); => topmost entry preferred
				ElseIf $Type='C|' Then
					$String = _GetTR($p_Message, 'L32'); => no conflict in group
				Else
					$String = ''
				EndIf
				GUICtrlSetData($g_UI_Static[13][4], $String)
			Case $g_UI_Interact[13][6]; another modname was selected
				$s=_Dep_ItemSetMod(6, $ReadSection, $p_Message)
			Case $g_UI_Interact[13][7]; another setup was selected
				$s=_Dep_ItemSetMod(7, $ReadSection, $p_Message)
			Case $g_UI_Interact[13][8]; comp-number
				$Num=GUICtrlRead($g_UI_Interact[13][8])
				GUICtrlSetData($g_UI_Interact[13][9], _IniRead($ReadSection, '@'&$Num, $Num))
			Case $g_UI_Interact[13][9]; comp-desc
				$Dsc=GUICtrlRead($g_UI_Interact[13][9])
				For $r=1 to $ReadSection[0][0]
					If $ReadSection[$r][1] = $Dsc Then
						GUICtrlSetData($g_UI_Interact[13][8], StringTrimLeft($ReadSection[$r][0], 1))
						ExitLoop
					EndIf
				Next
			Case $Accel[1]; ctrl-x
				_Dep_Delete(3)
		EndSwitch
		Sleep(10)
	WEnd
	While _IsPressed('0D', $g_UDll)
		Sleep(10)
	WEnd
	_Dep_ItemSwitch()
EndFunc   ;==>_Dep_ItemEdit

; ---------------------------------------------------------------------------------------------
; Get connection between basis and others
; ---------------------------------------------------------------------------------------------
Func _Dep_ItemGetSel($p_Num, $p_Message)
	$Select=GUICtrlRead($g_UI_Interact[13][3+$p_Num])
	$Array=StringSplit(_GetTR($p_Message, 'C'&Number($p_Num+1)), '|'); => get trigger if/because of-entries
	For $a=1 to $Array[0]
		If $Array[$a]=$Select Then ExitLoop
	Next
	If $p_Num = 1 Then
		Switch $a
			Case 1
				Return 1
			Case 2
				Return '|'
			Case 3
				Return '&'
		EndSwitch
	Else
		Switch $a
			Case 1
				Return 'DA'
			Case 2
				Return 'D:'
			Case 3
				Return 'D&'
			Case 4
				Return 'D|'
			Case 5
				Return 'C>'
			Case 6
				Return 'C:'
			Case 7
				Return 'C|'
		EndSwitch
	EndIf
EndFunc   ;==>_Dep_ItemGetSel

; ---------------------------------------------------------------------------------------------
; Save current entry
; ---------------------------------------------------------------------------------------------
Func _Dep_ItemSave($p_Message, $p_Num)
	Local $Rule='', $Error, $Output
	$End=ControlListView($g_UI[0], '', $g_UI_Interact[13][3], 'GetItemCount')
	Local $Array[$End+2][3]
	For $i=0 to $End-1
		$Text=StringSplit(GUICtrlRead(_GUICtrlListView_GetItemParam($g_UI_Interact[13][3], $i)), '|')
		$Array[0][0]+=1
		$Array[$Array[0][0]][0]=$Text[1]
		$Array[$Array[0][0]][1]=$Text[2]
		$Array[$Array[0][0]][2]=$Text[4]
		If $Text[4] = 'D' Then
			$Array[0][1]+=1
		ElseIf $Text[4] = 'C' Then
			$Array[0][2]+=1
		EndIf
	Next
	$Desc=GUICtrlRead($g_UI_Interact[13][13])
	$Num=_Dep_ItemGetSel(1, $p_Message)
	$Type=_Dep_ItemGetSel(2, $p_Message)
	If $Desc='' Then $Error&='|37'; no description
	If Not ($Num<>'' And $Type<>'') Then $Error&='|28'; no selection
	If $Array[0][1]<>'' And $Array[0][2]<>'' Then $Error&='|27'; no error/dependency
	If $Num = 1 Then
		If Number($Array[0][0]-$Array[0][1]-$Array[0][2])<>1 Then $Output &= '|||'&_GetTR($p_Message, 'L34')&_GetTR($p_Message, 'L29'); => base should be 1
	Else
		If ($Type<>'DA' And $Type <> 'C>') And Number($Array[0][0]-$Array[0][1]-$Array[0][2])<2 Then $Output &= '|||'&_GetTR($p_Message, 'L34')&_GetTR($p_Message, 'L33'); => base should be more than 1
	EndIf
	If $Type = 'D:' And $Array[0][1]<>1 Then $Output &= '|||'&_GetTR($p_Message, 'L35')&_GetTR($p_Message, 'L29'); => there should be a dependency
	If $Type = 'C:' And $Array[0][2]<>1 Then $Output &= '|||'&_GetTR($p_Message, 'L36')&_GetTR($p_Message, 'L29'); => there should be a conflict
	If ($Type='DA' OR $Type='D&' Or $Type='D|') And Number($Array[0][1])<2 Then $Output &= '|||'&_GetTR($p_Message, 'L35')&_GetTR($p_Message, 'L33'); => there should be more dependenies
	; ================ show the errors =========================
	If Not ($Error = '' And $Output = '') Then
		$Error=StringSplit(StringTrimLeft($Error, 1), '|')
		For $e=1 to $Error[0]
			$Output &= '|||'&_GetTR($p_Message, 'L'&$Error[$e]); =>multiple failures...
		Next
		_Misc_MsgGUI(4, _GetTR($p_Message, 'T1'), StringTrimLeft($Output, 3)); =>invalid configuration
		Return 0; abort the saving process
	EndIf
; ============== no errors if we got here   ================
	If $Type = 'DA' Then
		$Rule='D:'&_Dep_Compact($Array, 'D', '&')
		$Long='D:'&_Dep_Compact($Array, 'D', '&', 0)
	ElseIf $Type = 'C>' Then
		For $a=1 to $Array[0][0]
			$Rule&='>'&$Array[$a][0]&'('&$Array[$a][1]&')'
		Next
		$Rule='C:'&StringTrimLeft($Rule, 1)
		$Long=$Rule
	Else
		$Rule=StringLeft($Type, 1)&':'&_Dep_Compact($Array, '', $Num)&':'&_Dep_Compact($Array, StringLeft($Type, 1), StringRight($Type, 1))
		$Long=StringLeft($Type, 1)&':'&_Dep_Compact($Array, '', $Num, 0)&':'&_Dep_Compact($Array, StringLeft($Type, 1), StringRight($Type, 1), 0)
	EndIf
	Dim $Text[2][2]=[[1], [1, $Rule]]
	$Text=_Depend_PrepareBuildSentences($Text)
	If $p_Num[2] = '' Then; add new item
		$g_Connections[0][0]+=1
		ReDim $g_Connections[$g_Connections[0][0]+1][5]
		$p_Num[2]=$g_Connections[0][0]
		GUICtrlCreateListViewItem($Desc&'|'&$Text[1][2]&'|'&$p_Num[2], $g_UI_Interact[13][1])
	Else
		GUICtrlSetData($p_Num[1], $Desc&'|'&$Text[1][2]&'|'&$p_Num[2])
	EndIf
	$g_Connections[$p_Num[2]][0]=$Desc; text describing the rule
	$g_Connections[$p_Num[2]][1]=$Rule; the rule itself, e.g. D:a(-):b(-)|c(-)
	$g_Connections[$p_Num[2]][2]=$Text[1][2]; sentence summarizing the rule, e.g. A depends on B or C
	$g_Connections[$p_Num[2]][3]=$Long; long form of rule, with IDs instead of mod names and component numbers, e.g. D:123:456|789
	$g_Connections[$p_Num[2]][4]=0; not a user-ignorable rule
;~ 	$p_Num 0=Index, 1=ID, 2=Number of rules in $g_Connections now (also the index of this new entry)
	Return 1
EndFunc   ;==>_Dep_ItemSave

; ---------------------------------------------------------------------------------------------
; Set mod/component that you clicked on
; ---------------------------------------------------------------------------------------------
Func _Dep_ItemSetComp($p_Index, ByRef $p_ReadSection, $p_Message)
	If $p_Index='-' Then $p_Index=ControlListView($g_UI[0], '', $g_UI_Interact[13][3], 'GetSelected')
	$Text=StringSplit(GUICtrlRead(_GUICtrlListView_GetItemParam($g_UI_Interact[13][3], $p_Index)), '|')
	If GUICtrlRead($g_UI_Interact[13][7]) <> $Text[1] Then
		GUICtrlSetData($g_UI_Interact[13][7], $Text[1])
		_Dep_ItemSetMod(7, $p_ReadSection, $p_Message)
	EndIf
	GUICtrlSetData($g_UI_Interact[13][8], $Text[2])
	GUICtrlSetData($g_UI_Interact[13][9], $Text[3])
	If $Text[4]='' Then
		GUICtrlSetState($g_UI_Interact[13][11], $GUI_CHECKED)
	Else
		GUICtrlSetState($g_UI_Interact[13][12], $GUI_CHECKED)
	EndIf
EndFunc    ;==>_Dep_ItemSetComp

; ---------------------------------------------------------------------------------------------
; Get current dependency and display it
; ---------------------------------------------------------------------------------------------
Func _Dep_ItemSetDep($p_Num, $p_Message)
	Local $Num[3], $String, $Desc=_GetTR($p_Message, 'L26'); => all components
	GUICtrlSetData($g_UI_Interact[13][13], $g_Connections[$p_Num][0])
	$Text=StringTrimLeft($g_Connections[$p_Num][3], 2)
	_GUICtrlListView_BeginUpdate($g_UI_Handle[5])
	_GUICtrlListView_DeleteAllItems($g_UI_Handle[5]); delete previous entries
	If StringLeft($g_Connections[$p_Num][3], 1) = 'D' Then
		If StringInStr($Text, ':') Then
			$Text=StringSplit($Text, ':')
			If StringInStr($Text[1], '&') Then
				$Num[1]=3
			ElseIf StringInStr($Text[1], '|') Then
				$Num[1]=2
			Else
				$Num[1]=1
			EndIf
			If StringInStr($Text[2], '&') Then
				$Num[2]=3
			ElseIf StringInStr($Text[2], '|') Then
				$Num[2]=4
			Else
				$Num[2]=2
			EndIf
			_Dep_ItemSetDepItem($Text[1], $Text[2], 'D', $Desc)
		Else
			; All same
			Local $Num[3]=['', 2, 1]
			_Dep_ItemSetDepItem('', $Text, 'D', $Desc)
		EndIf
	Else
		If StringInStr($Text, ':') Then
			$Text=StringSplit($Text, ':')
			If StringInStr($Text[1], '|') Then
				$Num[1]=2
			Else
				$Num[1]=1
			EndIf
			If StringInStr($Text[2], '|') Then
				$Num[2]=7
			Else
				$Num[2]=6
			EndIf
			_Dep_ItemSetDepItem($Text[1], $Text[2], 'C', $Desc)
			$String=_GetTR($p_Message, 'L32'); => no conflict in group
		Else
			Local $Num[3]=['', 2, 5]
			_Dep_ItemSetDepItem('', $Text, 'C', $Desc)
			$String=_GetTR($p_Message, 'L31'); => first one's preferred
		EndIf
	EndIf
	_GUICtrlListView_EndUpdate($g_UI_Handle[5])
	For $s=1 to 2
		$Split=StringSplit(_GetTR($p_Message, 'C'&Number(1+$s)), '|'); => trigger if/because of
		GUICtrlSetData($g_UI_Interact[13][3+$s], $Split[$Num[$s]])
	Next
	GUICtrlSetData($g_UI_Static[13][4], $String); set new/reset other comments
	GUICtrlSetData($g_UI_Interact[13][10], $g_Connections[$p_Num][1])
EndFunc   ;==>_Dep_ItemSetDep

; ---------------------------------------------------------------------------------------------
; Edit one connection
; ---------------------------------------------------------------------------------------------
Func _Dep_ItemSetDepItem($p_Text1, $p_Text2, $p_Conn, $p_Desc)
	Local $Color
	For $i=1 to 2
		$Color=''
		$Text=Eval('p_Text'&$i)
		If $Text = '' Then ContinueLoop
		$Text=StringSplit($Text, '&|>')
		For $t=1 to $Text[0]
			$Bracket=StringInStr($Text[$t], '(')
			$Mod=StringLeft($Text[$t], $Bracket-1)
			$Comp=StringTrimRight(StringMid($Text[$t], $Bracket+1),1)
			$String=$Mod&'|'&$Comp&'|'&StringReplace(_GetTra($Mod, $Comp), '-', $p_Desc)&'|'
			If $i=2 And $p_Conn = 'D' Then
				$Color = 0xFFA500; dependency
				$String&=$p_Conn
			ElseIf $i=2 And $p_Conn = 'C' Then
				$Color = 0xFF0000; conflict
				$String&=$p_Conn
			EndIf
			GUICtrlCreateListViewItem($String, $g_UI_Interact[13][3])
			If $Color Then GUICtrlSetBkColor(-1, $Color)
		Next
	Next
EndFunc   ;==>_Dep_ItemSetDepItem

; ---------------------------------------------------------------------------------------------
; Load mods names/components in edit-screen
; ---------------------------------------------------------------------------------------------
Func _Dep_ItemSetMod($p_Num, ByRef $p_ReadSection, $p_Message)
	Local $Num='|-', $Comp='|'&_GetTR($p_Message, 'L26'); => all components
	$s=_Admin_ModGetIndex(GUICtrlRead($g_UI_Interact[13][$p_Num]), 7-$p_Num)
	If $s = '' Then Return
	GUICtrlSetData($g_UI_Interact[13][7-Not(7-$p_Num)], $g_Setups[$s][Not(7-$p_Num)])
	$p_ReadSection=_GetTra($g_Setups[$s][0], 'R')
	For $r=1 to $p_ReadSection[0][0]
		If $p_ReadSection[$r][0] = 'Tra' Then ContinueLoop
		$Num&='|'&StringTrimLeft($p_ReadSection[$r][0], 1)
		$Comp&='|'&$p_ReadSection[$r][1]
	Next
	$p_ReadSection[0][0]+=1
	ReDim $p_ReadSection[$p_ReadSection[0][0]+1][2]
	$p_ReadSection[$p_ReadSection[0][0]][0]='@-'
	$p_ReadSection[$p_ReadSection[0][0]][1]=_GetTR($p_Message, 'L26'); => all components
	GUICtrlSetData($g_UI_Interact[13][8], $Num, StringTrimLeft($p_ReadSection[1][0], 1))
	GUICtrlSetData($g_UI_Interact[13][9], $Comp, $p_ReadSection[1][1])
	Return $s
EndFunc   ;==>_Dep_ItemSetMod

; ---------------------------------------------------------------------------------------------
; Switch between normal and edit-screen
; ---------------------------------------------------------------------------------------------
Func _Dep_ItemSwitch()
	$State=BitAND(GUICtrlGetState($g_UI_Button[13][3]), $GUI_SHOW)
	If Not $State Then
		Local $State1=$GUI_HIDE, $State2=$GUI_SHOW
		GUICtrlSetState($g_UI_Interact[13][4], $GUI_FOCUS)
		GUICtrlSetState($g_UI_Button[13][4], $GUI_DEFBUTTON)
	Else
		Local $State1=$GUI_SHOW, $State2=$GUI_HIDE
		GUICtrlSetState($g_UI_Interact[13][1], $GUI_FOCUS)
		GUICtrlSetState($g_UI_Button[0][3], $GUI_DEFBUTTON)
	EndIf
	GUICtrlSetState($g_UI_Static[13][1], $State1)
	GUICtrlSetState($g_UI_Interact[13][2], $State1)
	GUICtrlSetState($g_UI_Button[13][1], $State1)
	For $i=3 to 13
		GUICtrlSetState($g_UI_Interact[13][$i], $State2)
	Next
	For $i=2 to 4
		GUICtrlSetState($g_UI_Static[13][$i], $State2)
	Next
	GUICtrlSetState($g_UI_Button[13][3], $State2)
	GUICtrlSetState($g_UI_Button[13][4], $State2)
	GUICtrlSetState($g_UI_Interact[13][1], $State1)
	GUICtrlSetState($g_UI_Interact[13][11], $GUI_CHECKED)
EndFunc   ;==>_Dep_ItemSwitch

; ---------------------------------------------------------------------------------------------
; Populate Dependency-Tree
; ---------------------------------------------------------------------------------------------
Func _Dep_Populate()
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Dep_Populate')
	$MLang=StringSplit(_GetTR($g_UI_Message, '15-L1'), '|'); => the name has changed
	$g_MLang = $g_Flags[3]&' --'
	For $l=1 to $MLang[0]
		If Not StringInStr($g_MLang, $MLang[$l]) Then $g_MLang&=' '&$MLang[$l]
	Next
	$g_MLang = StringSplit($g_MLang, ' '); reset the array with the selected languages. -- is added for mods with no text = suitable for all languages
	GUISetState(@SW_SHOW, $g_UI[4]); show progress-gui to prevent flickering
	WinActivate($g_UI[0])
	_GUICtrlListView_BeginUpdate($g_UI_Handle[4])
	_GUICtrlListView_DeleteAllItems($g_UI_Handle[4]); delete previous entries
	$g_Connections=_Depend_PrepareToUseID(_Depend_PrepareBuildSentences(_IniReadSection($g_ConnectionsConfDir&'\Game.ini', 'Connections')))
	For $c=1 to $g_Connections[0][0]
		GUICtrlSetData($g_UI_Interact[0][1], $c*100/$g_Connections[0][0]); set the progress
		If _MathCheckDiv($c, 10) = 2 Then
			GUICtrlSetData($g_UI_Static[0][4], Round($c *100 / $g_Connections[0][0], 0) & ' %')
		EndIf
		GUICtrlCreateListViewItem($g_Connections[$c][0]&'|'&$g_Connections[$c][2]&'|'&$c, $g_UI_Interact[13][1])
	Next
	_GUICtrlListView_EndUpdate($g_UI_Handle[4])
	_Misc_SetTab(13)
	GUISetState(@SW_HIDE, $g_UI[4])
	WinActivate($g_UI[0])
	GUISwitch($g_UI[0])
	Return $g_Connections
EndFunc    ;==>_Dep_Populate

; ---------------------------------------------------------------------------------------------
; Save current dependencies
; ---------------------------------------------------------------------------------------------
Func _Dep_Save()
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Dep_Save')
	$End=ControlListView($g_UI[0], '', $g_UI_Interact[13][1], 'GetItemCount')
	Local $Return[$End+1][2]
	For $r = 0 To $End-1; loop through the main-array
		$Text=StringSplit(GUICtrlRead(_GUICtrlListView_GetItemParam($g_UI_Interact[13][1], $r)), '|')
		$Return[0][0]+=1
		$Return[$Return[0][0]][0]=$g_Connections[$Text[3]][0]
		$Return[$Return[0][0]][1]=$g_Connections[$Text[3]][1]
	Next
	IniWriteSection($g_ConnectionsConfDir&'\Game.ini', 'Connections', $Return)
	GUICtrlSetState($g_UI_Static[13][5], $GUI_SHOW)
	Sleep(1000)
	GUICtrlSetState($g_UI_Static[13][5], $GUI_HIDE)
EndFunc    ;==>_Dep_Save

; ---------------------------------------------------------------------------------------------
; Get special events like double-clicks, focus and so on
; ---------------------------------------------------------------------------------------------
Func _Dep_WM_Notify($hWnd, $iMsg, $iwParam, $ilParam)
	#forceref $hWnd, $iMsg, $iwParam
	Local $hWndFrom, $iIDFrom, $iCode, $tNMHDR
	$tNMHDR = DllStructCreate($tagNMHDR, $ilParam)
	$hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
	$iIDFrom = DllStructGetData($tNMHDR, "IDFrom")
	$iCode = DllStructGetData($tNMHDR, "Code")
	Switch $hWndFrom
		Case $g_UI_Handle[4]
			Switch $iCode
				Case $NM_DBLCLK ; Sent by a list-view control when the user double-clicks an item with the left mouse button
					$g_Flags[16]=3
				Case $NM_KILLFOCUS ; The control has lost the input focus
					$g_Flags[16]=0
				Case $NM_RCLICK ; Sent by a list-view control when the user clicks an item with the right mouse button
					$g_Flags[16]=2
				Case $NM_SETFOCUS ; The control has received the input focus
					$g_Flags[16]=1
			EndSwitch
		Case $g_UI_Handle[5]
			Switch $iCode
				Case $NM_DBLCLK ; Sent by a list-view control when the user double-clicks an item with the left mouse button
					$g_Flags[16]=3
				Case $NM_KILLFOCUS ; The control has lost the input focus
					$g_Flags[16]=0
				Case $NM_RCLICK ; Sent by a list-view control when the user clicks an item with the right mouse button
					$g_Flags[16]=2
				Case $NM_SETFOCUS ; The control has received the input focus
					$g_Flags[16]=1
			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_NOTIFY

; ---------------------------------------------------------------------------------------------
; Edit, remove, open or test items
; ---------------------------------------------------------------------------------------------
Func _Select_ContextMenu($p_ReadSection, $p_Message, $p_Theme, $p_Lang)
	Local $MenuItem[7]=[6, 'a', 'b', 'c', 'd', 'e', 'f'], $Return
	$ID = GUICtrlRead($g_UI_Interact[16][3])
	$Text=StringSplit(GUICtrlRead($ID), '|')
	If $Text[0]=1 Then $ID=GUICtrlCreateDummy()
	$MenuLabel=$Text[2]
	GUISetState(@SW_DISABLE); disable the GUI itself while selection is pending to avoid unwanted treeview-changes
	$g_UI_Menu[0][4] = GUICtrlCreateContextMenu($ID); create a context-menu on the clicked item
	If $Text[0]=1 Then
		$MenuItem[1] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[7][4], 1), $g_UI_Menu[0][4]); new entry
	Else
		$MenuLabel = GUICtrlCreateMenuItem($MenuLabel, $g_UI_Menu[0][4])
		GUICtrlSetState(-1, $GUI_DISABLE)
		GUICtrlCreateMenuItem('', $g_UI_Menu[0][4]); separator
		$MenuItem[1] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[7][4], 1), $g_UI_Menu[0][4]); new entry
		$MenuItem[2] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[7][5], 1), $g_UI_Menu[0][4]); edit enty
		$MenuItem[3] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[7][6], 1), $g_UI_Menu[0][4]); cut entry
		$MenuItem[4] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[7][7], 1), $g_UI_Menu[0][4]); copy entry
		$MenuItem[5] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[7][8], 1), $g_UI_Menu[0][4]); pase entry
		$MenuItem[6] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[7][9], 1), $g_UI_Menu[0][4]); delete entry
	EndIf
	__ShowContextMenu($g_UI[0], $ID, $g_UI_Menu[0][4])
; ---------------------------------------------------------------------------------------------
; Create another Msg-loop, since the GUI is disabled and only the menuitems should be available
; ---------------------------------------------------------------------------------------------
		While 1
			$Msg = GUIGetMsg()
			Switch $Msg
			Case $MenuItem[1]; new entry
				$Return=1
			Case $MenuItem[2]; edit entry
				$Return=2
			Case $MenuItem[3]; cut entry
				$Return=3
			Case $MenuItem[4]; copy entry
				$Return=4
			Case $MenuItem[5]; paste entry
				$Return=5
			Case $MenuItem[6]; delete entry
				$Return=6
			Case Else
				If $Return Then ExitLoop
				If _IsPressed('01', $g_UDll) Then; react to a left mouseclick outside of the menu
					While  _IsPressed('01', $g_UDll)
						Sleep(10)
					WEnd
					ExitLoop
				ElseIf _IsPressed('02', $g_UDll) Then; react to a right mouseclick outside of the menu
					While  _IsPressed('02', $g_UDll)
						Sleep(10)
					WEnd
					ExitLoop
				EndIf
			EndSwitch
			Sleep(10)
		WEnd
		GUISetState(@SW_ENABLE); enable the GUI again
		GUICtrlDelete($g_UI_Menu[0][4])
		Switch $Return
			Case 1
				If $Text[0]=1 Then GUICtrlDelete($ID); delete the dummy-control
				_Select_ItemEdit(1, $p_ReadSection, $p_Theme, $p_Message)
			Case 2
				_Select_ItemEdit(0, $p_ReadSection, $p_Theme, $p_Message)
			Case 3
				_Select_ItemCut()
			Case 4
				_Select_ItemCopy()
			Case 5
				_Select_ItemPaste()
			Case 6
				_Select_ItemDelete()
		EndSwitch
EndFunc    ;==>_Select_ContextMenu

; ---------------------------------------------------------------------------------------------
; A GUI to set up the installation order
; ---------------------------------------------------------------------------------------------
Func _Select_Gui()
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Admin_SelectGui')
	Local $Message = IniReadSection($g_TRAIni, 'Admin')
	Local $OldMod, $ReadSection, $Switch
	If $g_Flags[14] = 'BWS' Then; read different themes for BWS. BWP uses another method, so it can't be set here.
		$Text='Menu[2][2]'
	Else; any other mod beside the Big World Project
		$Text='Menu[2][5]'
	EndIf
	$Text = IniRead($g_TRAIni, 'UI-Buildtime', $Text, '')
	$Theme = StringSplit($Text, '|'); => themes
	GUICtrlSetData($g_UI_Interact[16][2], $Text, $Theme[1])
	If $g_Flags[10]=0 Then $g_Flags[10]=GUICtrlRead($g_UI_Seperate[0][0])+1
	$Trans=StringSplit(_GetTR($Message, 'I2'), '|'); => token as word
	Local $Lang[9][2]=[[8], ['ANN', $Trans[1]], ['CMD', $Trans[2]], ['DWN', $Trans[3]], ['STD', $Trans[4]], ['MUC', $Trans[5]], ['SUB', $Trans[6]], ['GRP', $Trans[7]], ['Init', $Trans[8]]]
; =================  define hotkeys   ======================
	Local $List[2] = [1, '^f'], $Accel[2]
	Local $AccelKeys[6][2] = [['^s', $g_UI_Menu[7][1]], ['{F2}', $g_UI_Menu[7][5]], ['^n', $g_UI_Menu[7][4]], ['^x', $g_UI_Menu[7][6]], _
	['^c', $g_UI_Menu[7][7]], ['^v', $g_UI_Menu[7][8]]]
	For $l=1 to $List[0]
		$Accel[$l]=GUICtrlCreateDummy(); create some dummys to "connect" accelerators
		ReDim $AccelKeys[UBound($AccelKeys)+1][2]
		$AccelKeys[UBound($AccelKeys)-1][0]=$List[$l]
		$AccelKeys[UBound($AccelKeys)-1][1]=$Accel[$l]
	Next
	GUISetAccelerators($AccelKeys)
	_Admin_Populate(16, $Message)
	GUICtrlSetData($g_UI_Interact[16][7], _GetTR($Message, 'I2')); => token as word
	$TestArray=_Select_Populate($Lang); Populate the LV
	While 1
		If $g_Flags[16]=1 And _IsPressed('0D', $g_UDll) Then; enter was pressed
			While _IsPressed('0D', $g_UDll)
				Sleep(10)
			WEnd
			_Select_ItemEdit(0, $ReadSection, $Theme, $Message)
		ElseIf $g_Flags[16]=2 Then
			_Select_ContextMenu($ReadSection, $Message, $Theme, $Lang)
			$g_Flags[16]=1
		ElseIf $g_Flags[16]=3 Then; item clicked
			_Select_ItemSetMod($Lang, $Theme, $OldMod, $ReadSection)
			$g_Flags[16]=1
		ElseIf $g_Flags[16]=4 Then
			_Select_ItemEdit(0, $ReadSection, $Theme, $Message)
			$g_Flags[16]=1
		EndIf
		$aMsg = GUIGetMsg()
		Switch $aMsg
			Case 0; nothing happend
				Sleep(10)
				ContinueLoop
			Case -11; mouse moved
				Sleep(10)
				ContinueLoop
			Case $Gui_Event_Close; close
				ExitLoop
			Case $g_UI_Static[16][1]
				__ShowContextMenu($g_UI[0], $g_UI_Static[16][1], $g_UI_Menu[7][0])
			Case $g_UI_Button[0][1]; move item up
				_Select_ItemSwitch('up', $g_UI_Interact[16][3])
			Case $g_UI_Button[0][2]; move item down
				_Select_ItemSwitch('down', $g_UI_Interact[16][3])
			Case $g_UI_Button[0][3]; exit
				ExitLoop
			Case $g_UI_Button[16][6]
				_Select_Search(16)
			; Creating select-options-menu
			Case $g_UI_Menu[7][1]; Save
				_Select_Save($Lang)
			Case $g_UI_Menu[7][2]; Revert
				_Select_Populate($Lang)
			Case $g_UI_Menu[7][4]; new entry
				_Select_ItemEdit(1, $ReadSection, $Theme, $Message)
			Case $g_UI_Menu[7][5]; edit entry
				_Select_ItemEdit(0, $ReadSection, $Theme, $Message)
			Case $g_UI_Menu[7][6]; cut entry
				_Select_ItemCut()
			Case $g_UI_Menu[7][7]; copy entry
				_Select_ItemCopy()
			Case $g_UI_Menu[7][8]; paste entry
				_Select_ItemPaste()
			Case $g_UI_Menu[7][9]; delete entry
				_Select_ItemDelete()
			Case $g_UI_Menu[7][11]; administrate mods
				$Switch = 11
				ExitLoop
			Case $g_UI_Menu[7][12]; administrate components
				$Switch = 12
				ExitLoop
			Case $g_UI_Menu[7][13]; administrate dependencies
				$Switch = 13
				ExitLoop
			Case $Accel[1]; move to find item
				_Select_SearchSwitch()
		EndSwitch
	WEnd
	$g_MLang = StringSplit($g_Flags[3]&' --', ' '); Restore setting
	$g_Flags[16]=0
	If $Switch Then
		$Setup = GUICtrlRead($g_UI_Interact[16][4])
		If $Setup = _GetTR($Message, 'C1') Then $Setup=''; => select mod
		If $Switch = 11 Then
			_Admin_ModGui()
		ElseIf $Switch = 12 Then
			_Tra_Gui()
		ElseIf $Switch = 13 Then
			_Dep_Gui()
		EndIf
	Else
		_Misc_SetTab($g_Flags[10])
		$g_Flags[10]=0
	EndIf
EndFunc   ;==>_Select_Gui

; ---------------------------------------------------------------------------------------------
; Copy entries to some kind of clipboard
; ---------------------------------------------------------------------------------------------
Func _Select_ItemCopy()
	$Num=StringSplit(ControlListView($g_UI[0], '', $g_UI_Interact[16][3], 'GetSelected', 1), '|')
	$g_Clip = ''
	For $n=1 to $Num[0]
		$g_Clip&=@LF&GUICtrlRead(_GUICtrlListView_GetItemParam($g_UI_Interact[16][3], $Num[$n]))
	Next
	$g_Clip=StringTrimLeft($g_Clip, 1)
EndFunc   ;==>_Select_ItemCopy

; ---------------------------------------------------------------------------------------------
; Copy entries from some kind of clipboard and delete them in one go
; ---------------------------------------------------------------------------------------------
Func _Select_ItemCut()
	_Select_ItemCopy()
	_Select_ItemDelete()
EndFunc   ;==>_Select_ItemCut

; ---------------------------------------------------------------------------------------------
; Delete selected (may be multiple) entries
; ---------------------------------------------------------------------------------------------
Func _Select_ItemDelete()
	$Num=ControlListView($g_UI[0], '', $g_UI_Interact[16][3], 'GetSelected', 1)
	$Num=StringSplit($Num, '|')
	For $n=$Num[0] to 1 Step -1
		GUICtrlDelete(_GUICtrlListView_GetItemParam($g_UI_Interact[16][3], $Num[$n]))
	Next
EndFunc   ;==>_Select_ItemDelete

; ---------------------------------------------------------------------------------------------
; Edit or create new entries (uses same controls)
; ---------------------------------------------------------------------------------------------
Func _Select_ItemEdit($p_New, $p_ReadSection, $p_Theme, $p_Message)
	Local $Save=0
	Local $Message = IniReadSection($g_TRAIni, 'Admin')
	$Trans=StringSplit(_GetTR($Message, 'I2'), '|'); => token as word
	Local $Lang[9][2]=[[8], ['ANN', $Trans[1]], ['CMD', $Trans[2]], ['DWN', $Trans[3]], ['STD', $Trans[4]], ['MUC', $Trans[5]], ['SUB', $Trans[6]], ['GRP', $Trans[7]], ['Init', $Trans[8]]]
	If Not IsArray($p_ReadSection) Then Dim $p_ReadSection[1][2]=[[0]]
	$Index=Number(ControlListView($g_UI[0], '', $g_UI_Interact[16][3], 'GetSelected'))
	If $Index=0 Then ControlListView($g_UI[0], '', $g_UI_Interact[16][3], 'Select', 0)
	$ID=GUICtrlRead($g_UI_Interact[16][3])
	$Text=StringSplit(GUICtrlRead($ID), '|')
	Local $Out[5]=[4, $Text[1], 0, $ID, $p_New]
	_Select_ItemEditSetMod($Text, 0, $p_ReadSection, $p_Theme, $Lang)
	_Select_ItemEditSwitch($p_New, $Text, $Index)
	_Select_ItemEditSetState(_Select_ItemTranslate(GUICtrlRead($g_UI_Interact[16][7]), $Lang, 2), $p_New)
	GUICtrlSetState($g_UI_Interact[16][3], $GUI_HIDE); show GUI after it's build up
	GUIGetMsg(); Get last message (in case enter was pressed, this would be the current default (e.g. $g_UI_Button[0][2])
	While 1
		If _IsPressed('1B', $g_UDll) Then; esc was pressed
			While _IsPressed('1B', $g_UDll)
				Sleep(10)
			WEnd
			ExitLoop
		EndIf
		$Msg=GUIGetMsg()
		Switch $Msg
			Case $g_UI_Button[0][3]
				ExitLoop
			Case $g_UI_Button[16][5]
				If _Select_ItemEditSave($p_Message, $p_ReadSection, $p_Theme, $Out) = 0 Then ContinueLoop
				$Save=1
				ExitLoop
			Case $g_UI_Interact[16][1]; modname
				$p_ReadSection=_Select_ItemEditSetMod(GUICtrlRead($g_UI_Interact[16][1]), 1, $p_ReadSection, $p_Theme, $Lang)
				If @error Then
					GUICtrlSetData($g_UI_Interact[16][1], $g_Setups[_Admin_ModGetIndex(GUICtrlRead($g_UI_Interact[16][4]))][1])
					_Misc_MsgGUI(3, _GetTR($g_UI_Message, '0-T1'), _GetTR($p_Message, 'L38')); => No components added yet
				EndIf
			Case $g_UI_Interact[16][4]; setup
				$p_ReadSection=_Select_ItemEditSetMod(GUICtrlRead($g_UI_Interact[16][4]), 0, $p_ReadSection, $p_Theme, $Lang)
				If @error Then
					GUICtrlSetData($g_UI_Interact[16][4], $g_Setups[_Admin_ModGetIndex(GUICtrlRead($g_UI_Interact[16][1]), 1)][0])
					_Misc_MsgGUI(3, _GetTR($g_UI_Message, '0-T1'), _GetTR($p_Message, 'L38')); => No components added yet
				EndIf
			Case $g_UI_Interact[16][5]; compnumber
				$Num=GUICtrlRead($g_UI_Interact[16][5])
				GUICtrlSetData($g_UI_Interact[16][6], _IniRead($p_ReadSection, '@'&$Num, $Num))
			Case $g_UI_Interact[16][6]; comp-desc
				$Dsc=GUICtrlRead($g_UI_Interact[16][6])
				For $r=1 to $p_ReadSection[0][0]
					If $p_ReadSection[$r][1] = $Dsc Then
						GUICtrlSetData($g_UI_Interact[16][5], StringTrimLeft($p_ReadSection[$r][0], 1))
						ExitLoop
					EndIf
				Next
			Case $g_UI_Interact[16][7]; linetype
				_Select_ItemEditSetState(_Select_ItemTranslate(GUICtrlRead($g_UI_Interact[16][7]), $Lang, 2), $p_New)
			Case $g_UI_Interact[16][8]; to comp checkbox
				If GUICtrlRead($g_UI_Interact[16][8])=1 Then
					GUICtrlSetState($g_UI_Interact[16][9], $GUI_ENABLE)
				Else
					GUICtrlSetState($g_UI_Interact[16][9], $GUI_DISABLE)
				EndIf
		EndSwitch
		Sleep(10)
	WEnd
	If $Save = 0 Then _Select_ItemEditSetMod($Text, 0, $p_ReadSection, $p_Theme, $Lang)
	_Select_ItemEditSwitch($p_New, $Text, $Index)
	GUICtrlSetState($g_UI_Interact[16][3], $GUI_SHOW)
	While _IsPressed('0D', $g_UDll)
		Sleep(10)
	WEnd
EndFunc   ;==>_Select_ItemEdit

; ---------------------------------------------------------------------------------------------
; Test and save the current selection of mods
; ---------------------------------------------------------------------------------------------
Func _Select_ItemEditSave($p_Message, $p_ReadSection, $p_Theme, $p_Array)
	Local $Return[12]=[11], $Error, $Out, $Output, $Test[10]
;~ 	$Return=> 1=modname, 2=theme/group, 4=setup, 5=comp number, 6=comp desc/ann/cmd, 7=linetype, 8=to checkbox, 9=to comp, 10=install dependencies
	For $r=1 to $Return[0]
		$Return[$r]=GUICtrlRead($g_UI_Interact[16][$r])
	Next
	$Return[3]=''; put theme here
	For $b=1 to 4
		$Return[3]&=StringReplace(GUICtrlRead($g_UI_Button[16][$b]), '4', '0')
	Next
; ================  now do checks  =========================
	$Trans=StringSplit(_GetTR($p_Message, 'I2'), '|'); => token as word
	Local $Lang[9][2]=[[8], ['ANN', $Trans[1]], ['CMD', $Trans[2]], ['DWN', $Trans[3]], ['STD', $Trans[4]], ['MUC', $Trans[5]], ['SUB', $Trans[6]], ['GRP', $Trans[7]], ['Init', $Trans[8]]]
	$Return[5]=_Select_ItemTranslate($Return[5], $Lang, 2)
	$Return[7]=_Select_ItemTranslate($Return[7], $Lang, 2)
	$Return[11]=GUICtrlRead($g_UI_Static[16][4])
	If Not StringRegExp($Return[7], '\A(?i)(ANN|CMD|DWN|STD|MUC|SUB|GRP)\z') Then $Error&='|10'; check keyword
	If $Return[7] = 'MUC' Then; check MUC-logic
		If Not ($Return[5] = 'Init' Or StringInStr(_IniRead($p_ReadSection, '@'&$Return[5], ''), '->')) Then $Error&='|24'
	ElseIf $Return[7] = 'SUB' Then; check SUB logic
		If Not StringInStr($Return[5], '?') Then
			For $r=1 to $p_ReadSection[0][0]
				If StringRegExp($p_ReadSection[$r][0], $Return[5]&'\x3f') Then
					$Test[3]=1
					ExitLoop
				EndIf
			Next
			If $Test[3]=0 Then $Error&='|25'
		EndIf
	EndIf
	If $Return[7] = 'ANN' Then
		$String='|'&$Return[7]&'||'&$Return[6]&'||||'; no check, just some words
	ElseIf $Return[7] = 'CMD' Then
		$String='|'&$Return[7]&'||'&$Return[6]
		If StringRegExp($Return[10], '\A(\s|)\z') = 0 Then
			$String&='|||'&$Return[10]
			$Test[1]=1; check dependencies later
		Else
			$String&='||||'
		EndIf
	ElseIf $Return[7] = 'GRP' Then
		$String='|'&$Return[7]&'||'&$Return[6]&'||||'
		If StringRegExp($Return[10], '\A(start|stop)\z') Then $Error&='|19'
	ElseIf StringRegExp($Return[7], 'DWN|MUC|STD|SUB') Then; don't run when keywords were changed
		$Index=_Admin_ModGetIndex($Return[4]); check mod
		If $Index <> '' Then; mod was found
			If $g_Setups[$Index][1] <> $Return[1] Then $Error&='|20'
		Else
			$Error&='|20'
		EndIf
		For $t=1 to $p_Theme[0]; check theme
			If $p_Theme[$t] = $Return[2] Then
				$Return[2]=$t-1
				If StringLen($Return[2])=1 Then $Return[2]='0'&$Return[2]
				$Test[2]=1
				ExitLoop
			EndIf
		Next
		If $Test[2] <> 1 Then $Error&='|21'
		If Not ($Return[7]='MUC' And $Return[5]='Init') Then; selection is ok for multiple choice
			$Desc=_IniRead($p_ReadSection, '@'&$Return[5], ''); check component
			If $Desc <> '' Then
				If $Desc <> $Return[6] Then $Error&='|22'
			Else
				$Error&='|22'
			EndIf
		EndIf
		If GUICtrlRead($g_UI_Interact[16][8])=1 Then; check additional components
			$Desc=_IniRead($p_ReadSection, '@'&$Return[9], ''); check component
			If $Desc = '' Then  $Error&='|23'
		EndIf
		If StringRegExp($Return[10], '\A(\s|)\z') = 0 Then $Test[1]=1; check dependencies later
		If GUICtrlRead($g_UI_Interact[16][8])=1 Then; check additional components
			Local $String='', $Out=0, $Num=0
			For $r=1 to $p_ReadSection[0][0]
				If $p_ReadSection[$r][0]='@'&$Return[5] Then $Out=1
				If $Out Then $String&=@LF&$Return[4]&'|'&_Select_ItemTranslate($Return[7], $Lang)&'|'&StringTrimLeft($p_ReadSection[$r][0], 1) & _
					'|'&$p_ReadSection[$r][1]&'|'&$Return[3]&'|'&$Return[2]&'|'&$Return[11]&'|'&$Return[10]
				If $p_ReadSection[$r][0]='@'&$Return[9] Then $Out=0
			Next
			$String=StringTrimLeft($String, 1)
		Else
			$String=$Return[4]&'|'&_Select_ItemTranslate($Return[7], $Lang)&'|'&_Select_ItemTranslate($Return[5], $Lang)&'|'&$Return[6]&'|'&$Return[3]&'|'&$Return[2]&'|'&$Return[11]&'|'&$Return[10]
		EndIf
	EndIf
	If $Test[1]=1 Then; dependency-checking
		If StringRegExp($Return[10], '\A(?i)(D|C)\x3a') = 0 Then $Error&='|18'
		$Array=StringSplit(StringTrimLeft($Return[10], 2), '&')
		$Result=0
		For $a=1 to $Array[0]
			$Mod=StringRegExpReplace($Array[$a], '\x28.*\z', '')
			$Comp=StringRegExpReplace($Array[$a], '\A[^\x28]*\x28|\x29', '')
			If _Admin_ModGetIndex($Mod) <> '' Then; mod was found
				If $Comp <> '-' Then
					$Desc=_GetTra($Mod, $Comp)
					If $Desc=$Comp And Not StringInStr($Error, '|18') Then $Error&='|18'
				EndIf
			Else
				If Not StringInStr($Error, '|18') Then $Error&='|18'
			EndIf
		Next
	EndIf
; ================ show the errors =========================
	If $Error <> '' Then
		$Error=StringSplit(StringTrimLeft($Error, 1), '|')
		For $e=1 to $Error[0]
			$Output &= '|||'&_GetTR($p_Message, 'L'&$Error[$e]); =>multiple failures...
		Next
		_Misc_MsgGUI(4, _GetTR($p_Message, 'T1'), StringTrimLeft($Output, 3)); =>invalid configuration
		Return 0; abort the saving process
	EndIf
; ============== no errors if we got here   ================
	$String=StringRegExpReplace(StringRegExpReplace(StringReplace($String, '||', '| |'), '\A\x7c', ' |'), '\x7c\z', '| ')
	$String=StringRegExpReplace(StringRegExpReplace(StringReplace($String, '||', '| |'), '\n\x7c', @LF&' |'), '\x7c\n', '| '&@LF)
	If $p_Array[4] Then; new item
		$Text=$g_Clip
		$g_Clip=$String
		_Select_ItemPaste(1)
		$g_Clip=$Text
	Else; edit item
		GUICtrlSetData($p_Array[3], $String)
	EndIf
	Return 1
EndFunc   ;==>_Select_ItemEditSave

; ---------------------------------------------------------------------------------------------
; Updates _Select_ItemEdit if mod is changed
; ---------------------------------------------------------------------------------------------
Func _Select_ItemEditSetMod($p_String, $p_IsName, $p_ReadSection, $p_Theme, $p_Lang)
	Local $Comp, $Num, $Type=''
	If IsArray($p_String) Then
		$Mod=$p_String[1]
		$Name=$g_Setups[_Admin_ModGetIndex($Mod)][1]
		If $p_String[5]=' ' Then $p_String[5]='0000'
		$Test=StringSplit($p_String[5], ''); def installtype
		For $t=1 to $Test[0]
			If $Test[$t]=1 Then
				GUICtrlSetState($g_UI_Button[16][$t], $GUI_CHECKED)
			Else
				GUICtrlSetState($g_UI_Button[16][$t], $GUI_UNCHECKED)
			EndIf
		Next
		GUICtrlSetData($g_UI_Static[16][4], $p_String[7])
		GUICtrlSetData($g_UI_Interact[16][2], $p_Theme[$p_String[6]+1]); set theme
		GUICtrlSetData($g_UI_Interact[16][4], $Mod)
		GUICtrlSetData($g_UI_Interact[16][7], $p_String[2]); linetype
		GUICtrlSetData($g_UI_Interact[16][9], ''); to compnumber
		GUICtrlSetData($g_UI_Interact[16][10], $p_String[8]); install dependency
		Local $c=$p_String[3], $d=$p_String[4]
	Else
		If $p_IsName = 0 Then
			$Mod=$p_String
			$Name=$g_Setups[_Admin_ModGetIndex($p_String)][1]
		Else
			$Name=$p_String
			$Mod=$g_Setups[_Admin_ModGetIndex($p_String, 1)][0]
		EndIf
		$Trans = _GetTra($Mod, 'T')
		$Bkp=$p_ReadSection
		$p_ReadSection = IniReadSection($g_GConfDir & '\Weidu-'&$Trans&'.ini', $Mod)
		If @error Then Return SetError(1, 1, $Bkp)
		GUICtrlSetData($g_UI_Static[16][4], $Trans)
		Local $c=StringTrimLeft($p_ReadSection[1][0], 1), $d=$p_ReadSection[1][1]
	EndIf
	$Type=_Select_ItemTranslate(GUICtrlRead($g_UI_Interact[16][7]), $p_Lang, 2)
	For $r=1 to $p_ReadSection[0][0]
		If $p_ReadSection[$r][0] = 'Tra' Then ContinueLoop
		$Num&='|'&StringTrimLeft($p_ReadSection[$r][0], 1)
		$Comp&='|'&$p_ReadSection[$r][1]
	Next
	If StringRegExp($Name, '\A(| )\z') = 0 Then GUICtrlSetData($g_UI_Interact[16][1], $Name); modname
	If StringRegExp($Mod, '\A(| )\z') = 0 Then GUICtrlSetData($g_UI_Interact[16][4], $Mod); setup
	If IsArray($p_String) Then; only act on a creation
		If StringRegExp($Type, '(?i)ANN|CMD|GRP') Then; this is no component...
			Local $Num='|'&$p_String[3], $Comp='|'&$p_String[4];... so we need to fill the comboboxes
		Else
			$Num='|'&$p_Lang[8][1]&$Num; make select available
		EndIf
	Else
		If Not StringRegExp($Type, '(?i)ANN|CMD|GRP') Then $Num='|'&$p_Lang[8][1]&$Num
	EndIf
	GUICtrlSetData($g_UI_Interact[16][5], $Num, $c); compnumber
	GUICtrlSetData($g_UI_Interact[16][6], $Comp, $d); comp-desc
	GUICtrlSetData($g_UI_Interact[16][9], $Num); compnumber
	Return $p_ReadSection
EndFunc   ;==>_Select_ItemEditSetMod

; ---------------------------------------------------------------------------------------------
; Dis/Enables comoboxes and input for editing
; ---------------------------------------------------------------------------------------------
Func _Select_ItemEditSetState($p_Type, $p_New)
	If $p_Type='ANN' Then
		Local $State[11]=[10, 0, 0, 0, 0, 0, 1, 1, $p_New, 0, 0]; 6/7=linetype + comp desc
	ElseIf $p_Type = 'CMD' Then
		Local $State[11]=[10, 0, 0, 0, 0, 0, 1, 1, $p_New, 0, 1]; 6/7+10=install dependencies
	ElseIf StringRegExp($p_Type, '(?i)DWN|MUC|STD|SUB') Then
		Local $State[11]=[10, 1, 1, 1, 1, 1, 1, 1, $p_New, 0, 1]; all except to comp
	ElseIf $p_Type = 'GRP' Then
		Local $State[11]=[10, 0, 0, 0, 0, 1, 1, 1, $p_New, 0, 0]; 6/7=linetype + comp desc
	EndIf
	For $s=1 to $State[0]
		If $State[$s]=1 Then
			$State[$s]=$GUI_ENABLE
		Else
			$State[$s]=$GUI_DISABLE
		EndIf
		If $s=3 Then
			For $b=1 to 4
				GUICtrlSetState($g_UI_Button[16][$b], $State[$s])
			Next
		Else
			GUICtrlSetState($g_UI_Interact[16][$s], $State[$s])
		EndIf
	Next
EndFunc   ;==>_Select_ItemEditSetState

; ---------------------------------------------------------------------------------------------
; Switch between normal and edit-mode
; ---------------------------------------------------------------------------------------------
Func _Select_ItemEditSwitch($p_New, $p_String, $p_Index)
	$State=BitAND(GUICtrlGetState($g_UI_Button[16][5]), $GUI_SHOW)
	If Not $State Then
		If $p_New = 1 Then
			If $p_String[0] = 1 Then
				Local $iPos[2]=[1, 40]
			Else
				$iPos = _GUICtrlListView_GetSubItemRect($g_UI_Interact[16][3], $p_Index, 1)
			EndIf
		Else
			If $p_String[0] = 1 Then Return 0; nothing selected here -> get out to avoid crashes
			$iPos = _GUICtrlListView_GetSubItemRect($g_UI_Interact[16][3], $p_Index, 1)
		EndIf
		If $iPos[1] < 30 Then $iPos[1]=30
		If $iPos[1] > 230 Then $iPos[1]=230
		Local $State1=$GUI_HIDE, $State2=$GUI_DISABLE, $State3=$GUI_SHOW
		GUICtrlSetPos($g_UI_Interact[16][1], 30, 60+$iPos[1], 370, 20); mod
		GUICtrlSetPos($g_UI_Interact[16][2], 420, 60+$iPos[1], 180, 20); theme
		GUICtrlSetState($g_UI_Interact[16][4], $GUI_FOCUS); setup
		GUICtrlSetState($g_UI_Button[16][5], $GUI_DEFBUTTON); save
	Else
		Local $iPos[2]=[1, 0], $State1=$GUI_SHOW, $State2=$GUI_ENABLE, $State3=$GUI_HIDE
		GUICtrlSetPos($g_UI_Interact[16][1], 115, 60, 285, 20); mod
		GUICtrlSetPos($g_UI_Interact[16][2], 460, 60, 140, 20); theme
		GUICtrlSetState($g_UI_Interact[16][3], $GUI_FOCUS); LV
		GUICtrlSetState($g_UI_Button[0][2], $GUI_DEFBUTTON); down
		GUICtrlSetState($g_UI_Interact[16][1], $GUI_DISABLE); mod -> ensure that visible controls are usable
		GUICtrlSetState($g_UI_Interact[16][2], $GUI_DISABLE); theme
		For $b=1 to 4
			GUICtrlSetState($g_UI_Button[16][$b], $GUI_DISABLE)
		Next
	EndIf
; =================  move ctrls around =====================
	GUICtrlSetPos($g_UI_Static[16][4], 30, 30+$iPos[1]); R
	GUICtrlSetPos($g_UI_Button[16][1], 620, 60+$iPos[1]); R
	GUICtrlSetPos($g_UI_Button[16][2], 640, 60+$iPos[1]); S
	GUICtrlSetPos($g_UI_Button[16][3], 660, 60+$iPos[1]); T
	GUICtrlSetPos($g_UI_Button[16][4], 680, 60+$iPos[1]); E
	GUICtrlSetPos($g_UI_Button[16][5], 705, 90+$iPos[1]); save-button
	GUICtrlSetPos($g_UI_Interact[16][4], 30, 90+$iPos[1]); setup
	GUICtrlSetPos($g_UI_Interact[16][5], 230, 90+$iPos[1]); compnumber
	GUICtrlSetPos($g_UI_Interact[16][6], 420, 90+$iPos[1]); comp-desc
	GUICtrlSetPos($g_UI_Interact[16][7], 30, 120+$iPos[1]); linetype
	GUICtrlSetPos($g_UI_Interact[16][8], 230, 120+$iPos[1]); activate to compnumber
	GUICtrlSetPos($g_UI_Interact[16][9], 300, 120+$iPos[1]); to compnumber
	GUICtrlSetPos($g_UI_Interact[16][10], 420, 120+$iPos[1]); install dependency
; =================  dis/enable ctrls  =====================
	GUICtrlSetState($g_UI_Interact[16][8], $GUI_UNCHECKED)
	For $i=1 to 3
		GUICtrlSetState($g_UI_Static[16][$i], $State1)
	Next
	For $i=4 to 10
		GUICtrlSetState($g_UI_Interact[16][$i], $State3)
	Next
	GUICtrlSetState($g_UI_Static[16][4], $State3); translation
	GUICtrlSetState($g_UI_Button[16][5], $State3); save
	GUICtrlSetState($g_UI_Button[0][1], $State2); up
	GUICtrlSetState($g_UI_Button[0][2], $State2); down
EndFunc   ;==>_Select_ItemEditSwitch

; ---------------------------------------------------------------------------------------------
; Copy entries from some kind of clipboard
; ---------------------------------------------------------------------------------------------
Func _Select_ItemPaste($p_New=0)
	Local $Append=0
	$Start=ControlListView($g_UI[0], '', $g_UI_Interact[16][3], 'GetSelected')
	$Num=StringSplit($g_Clip, @LF)
	For $n=1 to $Num[0]
		GUICtrlCreateListViewItem('', $g_UI_Interact[16][3]); add new item
	Next
	$End=ControlListView($g_UI[0], '', $g_UI_Interact[16][3], 'GetItemCount')-1
	If $p_New = 1 And $End = $Start + $Num[0] Then; this is a new created item, no copy and paste
		$Append=1; append the items rather then putting them in between
		$Start+=1; choose new item
	EndIf
	If Not $Append Then
		For $i=$End to $Start Step -1; replace items
			GUICtrlSetData(_GUICtrlListView_GetItemParam($g_UI_Interact[16][3], $i), GUICtrlRead(_GUICtrlListView_GetItemParam($g_UI_Interact[16][3], $i-$Num[0])))
		Next
	EndIf
	For $n=1 To $Num[0]
		GUICtrlSetData(_GUICtrlListView_GetItemParam($g_UI_Interact[16][3], $Start+$n-1), $Num[$n])
	Next
	If $Append Then
		_GUICtrlListView_EnsureVisible($g_UI_Interact[16][3], $End)
		ControlListView($g_UI[0], '', $g_UI_Interact[16][3], 'SelectClear')
		ControlListView($g_UI[0], '', $g_UI_Interact[16][3], 'Select', $End)
	EndIf
EndFunc   ;==>_Select_ItemPaste

; ---------------------------------------------------------------------------------------------
; Set main gui to for current item (theme, install-type, modname & component-entries)
; ---------------------------------------------------------------------------------------------
Func _Select_ItemSetMod($p_Lang, $p_Theme, ByRef $p_OldMod, ByRef $p_ReadSection)
	$Index=ControlListView($g_UI[0], '', $g_UI_Interact[16][3], 'GetSelected')
	$Text=StringSplit(GUICtrlRead(_GUICtrlListView_GetItemParam($g_UI_Interact[16][3], $Index)), '|')
	If $Text[5]=' ' Then $Text[5]='0000'
	$Test=StringSplit($Text[5], ''); det installtype
	For $t=1 to $Test[0]
		If $Test[$t]=1 Then
			GUICtrlSetState($g_UI_Button[16][$t], $GUI_CHECKED)
		Else
			GUICtrlSetState($g_UI_Button[16][$t], $GUI_UNCHECKED)
		EndIf
	Next
	GUICtrlSetData($g_UI_Interact[16][2], $p_Theme[$Text[6]+1]); set theme
	If StringRegExp($Text[2], $p_Lang[1][1]&'|'&$p_Lang[2][1]&'|'&$p_Lang[7][1]) Then Return; ANN,CMD,GRP
	If $Text[1] = ' ' Or $p_OldMod = $Text[1] Then Return
	GUICtrlSetData($g_UI_Interact[16][1], $g_Setups[_Admin_ModGetIndex($Text[1])][1])
	$p_ReadSection=IniReadSection($g_GConfDir & '\Weidu-'&$Text[7]&'.ini', $Text[1])
	$p_OldMod=$Text[1]
EndFunc   ;==>_Select_ItemSetMod

; ---------------------------------------------------------------------------------------------
; Move one item up or down
; ---------------------------------------------------------------------------------------------
Func _Select_ItemSwitch($p_String, $p_ID)
	$Index=ControlListView($g_UI[0], '', $p_ID, 'GetSelected')
	If $p_String = 'up' Then
		If $Index=0 Then Return; stop if item is on top
		Local $ID1=$Index-1, $ID2=$Index, $ID=$ID1
	Else
		$End=ControlListView($g_UI[0], '', $p_ID, 'GetItemCount')
		If $Index=$End Then Return; stop if item is bottom
		Local $ID1=$Index, $ID2=$Index+1, $ID=$ID2
	EndIf
	$Start=_GUICtrlListView_GetItemParam($p_ID, $ID1); get upper ID
	$End=_GUICtrlListView_GetItemParam($p_ID, $ID2); get lower ID
	$Text1=GUICtrlRead($Start)
	$Text2=GUICtrlRead($End)
	GUICtrlSetData($Start, $Text2); switch
	GUICtrlSetData($End, $Text1)
	GUICtrlSetState($p_ID, $GUI_FOCUS); remove focus from buttons
	ControlListView($g_UI[0], '', $p_ID, 'SelectClear')
	ControlListView($g_UI[0], '', $p_ID, 'Select', $ID); select "moved" item
EndFunc   ;==>_Select_ItemSwitch

; ---------------------------------------------------------------------------------------------
; Replaced the ini-keys with understandable words
; ---------------------------------------------------------------------------------------------
Func _Select_ItemTranslate($p_String, $p_Lang, $p_Dir=1)
	If $p_Dir=1 Then; translate ini-entries to self-explaining text
		For $l=1 to $p_Lang[0][0]
			$p_String = StringReplace($p_String, $p_Lang[$l][0], $p_Lang[$l][1])
		Next
	EndIf
	If $p_Dir=2 Then; translate self-explaining text back to ini-entries
		For $l=$p_Lang[0][0] to 1 Step -1
			$p_String = StringReplace($p_String, $p_Lang[$l][1], $p_Lang[$l][0])
		Next
	EndIf
	Return $p_String
EndFunc   ;==>_Select_ItemTranslate

; ---------------------------------------------------------------------------------------------
; Populate the selection admin GUI
; ---------------------------------------------------------------------------------------------
Func _Select_Populate($p_Lang)
	Local $cs
	$Setup=_Tree_SelectRead(1); read the InstallOrder.ini-file
	$MLang=StringSplit(_GetTR($g_UI_Message, '15-L1'), '|'); => lang token
	$g_MLang = $g_Flags[3]&' --'
	For $l=1 to $MLang[0]
		If Not StringInStr($g_MLang, $MLang[$l]) Then $g_MLang&=' '&$MLang[$l]
	Next
	$g_MLang = StringSplit($g_MLang, ' '); reset the array with the selected languages. -- is added for mods with no text = suitable for all languages
	; 0=linetype, 1=unused, 2=setup, 3=component, 4=defaults, 5=translation, 6=component requirements, 7=componentname, 8=theme
	$Compnote = _GetTR($g_UI_Message, '4-L1'); => in the future you will be able to select components
	GUISetState(@SW_SHOW, $g_UI[4]); show progress-gui to prevent flickering
	WinActivate($g_UI[0])
	_GUICtrlListView_BeginUpdate($g_UI_Handle[8])
	_GUICtrlListView_DeleteAllItems($g_UI_Handle[8]); delete previous entries
	For $s=1 to $Setup[0][0]
		If StringRegExp($Setup[$s][0], '(?i)\A(ANN|CMD|GRP)\z') =0  And $Setup[$s][2] <> $Setup[$s-1][2] Then
			$cs+=1
			GUICtrlSetData($g_UI_Interact[0][1], $cs*100/$Setup[0][1]); set the progress
			If _MathCheckDiv($cs, 10) = 2 Then
				GUICtrlSetData($g_UI_Static[0][4], Round($cs *100 / $Setup[0][1], 0) & ' %')
			EndIf
			$ReadSection = IniReadSection($g_ModIni, $Setup[$s][2])
			$NotFixedItems = _IniRead($ReadSection, 'NotFixed', '') ; see if there are not fixed items (among the fixed)
			$Setup[$s][5] = _GetTra($ReadSection, 'T')
			If $Setup[$s][5] = '--' Then
				$ReadSection=IniReadSection($g_GConfDir&'\WeiDU-'&_GetTra($ReadSection, 'T')&'.ini', $Setup[$s][2])
			Else
				$ReadSection=IniReadSection($g_GConfDir&'\WeiDU-'&$Setup[$s][5]&'.ini', $Setup[$s][2])
			EndIf
		EndIf
		If $Setup[$s][4] <> '' Then; type is defined, so it's a download or a component
			If $Setup[$s][5] = '' Then $Setup[$s][5]=$Setup[$s-1][5]
			If $Setup[$s][3] = 'Init' Then
				$Setup[$s][7]=StringRegExpReplace(_IniRead($ReadSection, '@'&$Setup[$s+1][3], ''), '\s?->.*\z', '')
			Else
				$Setup[$s][7]=_IniRead($ReadSection, '@' & $Setup[$s][3], $Compnote)
			EndIf
		EndIf
		$String=$Setup[$s][2]&'|'&_Select_ItemTranslate($Setup[$s][0], $p_Lang)&'|'&StringReplace($Setup[$s][3], $p_Lang[8][0], $p_Lang[8][1])&'|'&$Setup[$s][7]&'|'&$Setup[$s][4]&'|'&$Setup[$s][8]&'|'&$Setup[$s][5]&'|'&$Setup[$s][6]
		GUICtrlCreateListViewItem(StringRegExpReplace(StringRegExpReplace(StringReplace(StringReplace($String, '||', '| |'), '||', '| |'), '\A\x7c', ' |'), '\x7c\z', '| '), $g_UI_Interact[16][3])
	Next
	_GUICtrlListView_EndUpdate($g_UI_Handle[8])
	_Misc_SetTab(16)
	GUISetState(@SW_HIDE, $g_UI[4])
EndFunc   ;==>_Select_Populate

; ---------------------------------------------------------------------------------------------
; Save current setting into file
; ---------------------------------------------------------------------------------------------
Func _Select_Save($p_Lang)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Select_Save')
	$End=ControlListView($g_UI[0], '', $g_UI_Interact[16][3], 'GetItemCount')-1
	$Handle=FileOpen($g_GConfDir&'\InstallOrder.ini', 2)
	For $i=0 to $End
		$Return=StringSplit(GUICtrlRead(_GUICtrlListView_GetItemParam($g_UI_Interact[16][3], $i)), '|')
		$Return[2]=_Select_ItemTranslate($Return[2], $p_Lang, 2)
		If StringRegExp($Return[2], 'ANN|GRP') Then
			$String=$Return[2]&';'&$Return[4]
		ElseIf $Return[2]='CMD' Then
			$String=$Return[2]&';'&$Return[4]
			If StringRegExp($Return[8], '\A(\s|)\z')=0 Then $String&=';;;;'&$Return[8]
		Else
			$String=$Return[2]&';'&$Return[1]&';'&StringRegExpReplace($Return[3], '\A(?i)'&$p_Lang[8][1]&'\z', $p_Lang[8][0])&';'&$Return[6]&';'&$Return[5]&';'&StringRegExpReplace($Return[8], '\A\s\z', '')
		EndIf
		If $i<> $End Then
			FileWriteLine($Handle, $String)
		Else
			FileWrite($Handle, $String)
		EndIf
	Next
	FileClose($Handle)
	GUICtrlSetState($g_UI_Static[16][5], $GUI_SHOW)
	Sleep(1000)
	GUICtrlSetState($g_UI_Static[16][5], $GUI_HIDE)
EndFunc   ;==>_Select_Save

; ---------------------------------------------------------------------------------------------
; Search through listviews
; ---------------------------------------------------------------------------------------------
Func _Select_Search($p_Tab)
	Local $Run
	If $p_Tab = '13' Then
		Local $ID1=$g_UI_Interact[13][1], $ID2=$g_UI_Interact[13][2]
	ElseIf $p_Tab = '16' Then
		Local $ID1=$g_UI_Interact[16][3], $ID2=$g_UI_Interact[16][11]
	EndIf
	$String=GUICtrlRead($ID2)
	$Index=Number(ControlListView($g_UI[0], '', $ID1, 'GetSelected'))
	$End=ControlListView($g_UI[0], '', $ID1, 'GetItemCount')
	For $s = $Index+1 To $End; loop through the main-array
		If StringInStr(GUICtrlRead(_GUICtrlListView_GetItemParam($ID1, $s)), $String) Then
			_GUICtrlListView_EnsureVisible($ID1, $s)
			ControlListView($g_UI[0], '', $ID1, 'SelectClear')
			ControlListView($g_UI[0], '', $ID1, 'Select', $s)
			Return
		EndIf
		If $s=$End Then
			If $Run = 2 Then ExitLoop
			If $Index <> 0 Then; search from top to the current item if search hit the bottom and the current element is not the first one.
				$s=-1
				$End=$Index
				$Run=2
			EndIf
		EndIf
	Next
EndFunc   ;==>_Select_Search

; ---------------------------------------------------------------------------------------------
; Show/hide searchbar
; ---------------------------------------------------------------------------------------------
Func _Select_SearchSwitch()
	$State=BitAND(GUICtrlGetState($g_UI_Button[16][6]), $GUI_SHOW)
	If Not $State Then
		Local $State1=$GUI_SHOW, $State2=$GUI_HIDE
		GUICtrlSetState($g_UI_Interact[16][11], $GUI_FOCUS); setup
		GUICtrlSetState($g_UI_Button[16][6], $GUI_DEFBUTTON); save
	Else
		Local $State1=$GUI_HIDE, $State2=$GUI_SHOW
	EndIf
	GUICtrlSetState($g_UI_Interact[16][11], $State1)
	GUICtrlSetState($g_UI_Button[16][6], $State1)
	GUICtrlSetState($g_UI_Static[16][3], $State2)
	GUICtrlSetState($g_UI_Interact[16][2], $State2)
	For $b=1 to 4
		GUICtrlSetState($g_UI_Button[16][$b], $State2)
	Next
EndFunc   ;==>_Select_SearchSwitch

; ---------------------------------------------------------------------------------------------
; Get special events like double-clicks, focus and so on
; ---------------------------------------------------------------------------------------------
Func _Select_WM_Notify($hWnd, $iMsg, $iwParam, $ilParam)
	#forceref $hWnd, $iMsg, $iwParam
	Local $hWndFrom, $iIDFrom, $iCode, $tNMHDR
	$tNMHDR = DllStructCreate($tagNMHDR, $ilParam)
	$hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
	$iIDFrom = DllStructGetData($tNMHDR, "IDFrom")
	$iCode = DllStructGetData($tNMHDR, "Code")
	Switch $hWndFrom
		Case $g_UI_Handle[8]
			Switch $iCode
				 Case $LVN_KEYDOWN ; A key has been pressed
                    $tInfo = DllStructCreate($tagNMLVKEYDOWN, $ilParam)
					$Key=DllStructGetData($tInfo, "VKey")
					If $Key='22020136' Or $Key='21495846' Then $g_Flags[16]=3; down or up key
				Case $NM_CLICK
					$g_Flags[16]=3
				Case $NM_DBLCLK ; Sent by a list-view control when the user double-clicks an item with the left mouse button
					$g_Flags[16]=4
				Case $NM_KILLFOCUS ; The control has lost the input focus
					$g_Flags[16]=0
				Case $NM_RCLICK ; Sent by a list-view control when the user clicks an item with the right mouse button
					$g_Flags[16]=2
				Case $NM_SETFOCUS ; The control has received the input focus
					$g_Flags[16]=1
			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>_Select_WM_Notify

; ---------------------------------------------------------------------------------------------
; Edit, remove, open or test items
; ---------------------------------------------------------------------------------------------
Func _Tra_ContextMenu($p_Message)
	Local $MenuItem[4]=[3, 'a', 'b', 'c'], $Return
	If $g_Flags[16]=4 Then
		$ID = GUICtrlRead($g_UI_Interact[12][2])
	Else
		$ID = GUICtrlRead($g_UI_Interact[12][1])
	EndIf
	$Text=StringSplit(GUICtrlRead($ID), '|')
	If $Text[0]=1 Then
		$ID=GUICtrlCreateDummy()
	EndIf
	$MenuLabel=$Text[1]
	GUISetState(@SW_DISABLE); disable the GUI itself while selection is pending to avoid unwanted treeview-changes
	$g_UI_Menu[0][4] = GUICtrlCreateContextMenu($ID); create a context-menu on the clicked item
	If $Text[0]=1 Then
		If $g_Flags[16]=4 Then $MenuItem[1] = GUICtrlCreateMenuItem(_GetTR($g_UI_Message, '4-L17'), $g_UI_Menu[0][4]); => new entry
	Else
		$MenuLabel = GUICtrlCreateMenuItem($MenuLabel, $g_UI_Menu[0][4])
		GUICtrlSetState(-1, $GUI_DISABLE)
		GUICtrlCreateMenuItem('', $g_UI_Menu[0][4]); separator
		If $g_Flags[16]=3 Then
			$MenuItem[1] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[6][5], 1), $g_UI_Menu[0][4]); copy entry
		Else
			$MenuItem[1] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[6][6], 1), $g_UI_Menu[0][4]); edit entry
			If $Text[1] <> 'Tra' Then $MenuItem[2] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[6][7], 1), $g_UI_Menu[0][4]); delete entry
		EndIf
	EndIf
	GUICtrlCreateMenuItem('', $g_UI_Menu[0][4])
	$MenuItem[3] = GUICtrlCreateMenuItem(GUICtrlRead($g_UI_Menu[6][8], 1), $g_UI_Menu[0][4]); edit entry
	__ShowContextMenu($g_UI[0], $ID, $g_UI_Menu[0][4])
; ---------------------------------------------------------------------------------------------
; Create another Msg-loop, since the GUI is disabled and only the menuitems should be available
; ---------------------------------------------------------------------------------------------
		While 1
			$Msg = GUIGetMsg()
			Switch $Msg
			Case $MenuItem[1]; new/edit entry
				$Return=1
			Case $MenuItem[2]; delete entry
				$Return=2
			Case $MenuItem[3]; select all
				$Return=3
			Case Else
				If $Return Then ExitLoop
				If _IsPressed('01', $g_UDll) Then; react to a left mouseclick outside of the menu
					While  _IsPressed('01', $g_UDll)
						Sleep(10)
					WEnd
					ExitLoop
				ElseIf _IsPressed('02', $g_UDll) Then; react to a right mouseclick outside of the menu
					While  _IsPressed('02', $g_UDll)
						Sleep(10)
					WEnd
					ExitLoop
				EndIf
			EndSwitch
			Sleep(10)
		WEnd
		GUISetState(@SW_ENABLE); enable the GUI again
		GUICtrlDelete($g_UI_Menu[0][4])
		Switch $Return
			Case 1
				If $Text[0]=1 Then GUICtrlDelete($ID); delete the dummy-control
				If $g_Flags[16]=3 Then; left LV is focused
					_Tra_ItemCopy()
				Else
					_Admin_ItemEdit($Text[0])
				EndIf
			Case 2
				_Tra_ItemDelete()
			Case 3
				If $g_Flags[16]=3 Then; left LV is focused
					ControlListView($g_UI[0], '', $g_UI_Interact[12][1], 'SelectAll')
				Else
					ControlListView($g_UI[0], '', $g_UI_Interact[12][2], 'SelectAll')
				EndIf
		EndSwitch
EndFunc    ;==>_Tra_ContextMenu

; ---------------------------------------------------------------------------------------------
; Get the mods version (if defined)
; ---------------------------------------------------------------------------------------------
Func _Tra_GetVersion($p_TP2)
	$Text=StringSplit(StringStripCR(FileRead($p_TP2)), @LF)
	For $t=1 to $Text[0]
		If StringRegExp($Text[$t], '(?i)\A\s{0,}Version\s{1,}("|~)') Then
			$Version=StringRegExpReplace($Text[$t], '(?i)\A\s{0,}Version\s{1,}("|~)|("|~)\s{0,}\z', '')
			$Version=StringReplace($Version, '(', '\x28')
			$Version=StringReplace($Version, ')', '\x29')
			Return $Version
		EndIf
	Next
EndFunc   ;==>_Tra_GetVersion

; ---------------------------------------------------------------------------------------------
; Display the current settings for the translation
; ---------------------------------------------------------------------------------------------
Func _Tra_Gui($p_Mod='')
	If Not IsDeclared('p_Mod') Then $p_Mod='-'
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Tra_Gui')
	$g_Flags[6]='\d{1,}|(?i)Tra'
	Local $Message = IniReadSection($g_TRAIni, 'Admin')
	If $g_Flags[10]=0 Then $g_Flags[10]=GUICtrlRead($g_UI_Seperate[0][0])+1
	Local $Available = '', $s=1, $Mods, $Tra, $Switch=0
	Local $List[8] = [7, '!{Down}', '!{Up}', '!1', '!2', '!m', '!l', '^d'], $Accel[8]
	Local $AccelKeys[9][2] = [["!{Left}", $g_UI_Button[0][1]], ["!{Right}", $g_UI_Button[0][2]], ["^c", $g_UI_Button[12][1]], ["^f", $g_UI_Button[12][2]], _
	['^s', $g_UI_Menu[6][1]], ['^e', $g_UI_Menu[6][3]], ['{F2}', $g_UI_Menu[6][6]], ['^x', $g_UI_Menu[6][7]], ['^a', $g_UI_Menu[6][8]]]
	For $l=1 to $List[0]
		$Accel[$l]=GUICtrlCreateDummy(); create some dummys to "connect" accelerators
		ReDim $AccelKeys[UBound($AccelKeys)+1][2]
		$AccelKeys[UBound($AccelKeys)-1][0]=$List[$l]
		$AccelKeys[UBound($AccelKeys)-1][1]=$Accel[$l]
	Next
	GUISetAccelerators($AccelKeys)
	_Admin_Populate(12, $Message)
	If $p_Mod = '' Or $p_Mod = '-' Then
	Else
		$s=_Admin_ModGetIndex($p_Mod, 0)
		If $s = '' Then $s = 1
		$Tra=_Tra_ModShowDefaultTra($s)
	EndIf
	_Misc_SetTab(12)
	While 1
		If ($g_Flags[16]=1 Or $g_Flags[16]=2) And _IsPressed('0D', $g_UDll) Then; enter was pressed
			While _IsPressed('0D', $g_UDll)
				Sleep(10)
			WEnd
			_Admin_ItemEdit(0)
		ElseIf $g_Flags[16]=3 Or $g_Flags[16]=4 Then
			_Tra_Contextmenu($Message)
			$g_Flags[16]-=2
		EndIf
		$Msg=GUIGetMsg()
		Switch $Msg
			Case $GUI_EVENT_CLOSE; exit [X]
				ExitLoop
			Case $g_UI_Static[12][4]
				__ShowContextMenu($g_UI[0], $g_UI_Static[12][4], $g_UI_Menu[6][0])
			Case $g_UI_Interact[12][3]; another setup was selected
				$s=_Admin_ModGetIndex(GUICtrlRead($g_UI_Interact[12][3]), 0)
				$Tra=_Tra_ModShowDefaultTra($s)
			Case $g_UI_Interact[12][4]; another language was selected
				_Tra_ModPopulateLists($g_Setups[$s][0])
			Case $g_UI_Interact[12][7]; another modname was selected
				$s=_Admin_ModGetIndex(GUICtrlRead($g_UI_Interact[12][7]), 1)
				$Tra=_Tra_ModShowDefaultTra($s)
			Case $g_UI_Button[12][1]; copy item
				_Tra_ItemCopy()
			Case $g_UI_Button[12][2]; auto-scan /update
				$s=_Tra_ModScan()
			Case $g_UI_Button[12][3]; write component entry into right listview
				_Tra_ItemWriteEntry()
			Case $g_UI_Button[12][4]; exit to mod-editing
				$Switch = 11
				ExitLoop
			Case $g_UI_Button[0][1]; previous mod
				If $s = 1 Then
					$s=$g_Setups[0][0]
				Else
					$s-=1
				EndIf
				$Tra=_Tra_ModShowDefaultTra($s)
			Case $g_UI_Button[0][2]; next mod
				If $s = $g_Setups[0][0] Then
					$s=1
				Else
					$s+=1
				EndIf
				$Tra=_Tra_ModShowDefaultTra($s)
			Case $g_UI_Button[0][3]; cancel
				ExitLoop
			Case $g_UI_Menu[6][1]; Save
				_Tra_ModSave($g_Setups[$s][0])
			Case $g_UI_Menu[6][2]; Scan
				$s=_Tra_ModScan()
			Case $g_UI_Menu[6][3]; switch to English
				$ReadSection = IniReadSection($g_GConfDir & '\Weidu-EN.ini', $g_Setups[$s][0])
				If @error Then ContinueLoop
				_IniWrite($ReadSection, 'Tra', StringTrimLeft(GUICtrlRead($g_UI_Interact[12][4]), 3), 'O')
				_Tra_ModListComponents($g_UI_Interact[12][1], $ReadSection)
				_Tra_ModColorDiff($p_Mod)
				ControlListView($g_UI[0], '', $g_UI_Interact[12][1], 'Select', 0)
				ControlListView($g_UI[0], '', $g_UI_Interact[12][2], 'Select', 0)
				GUICtrlSetState($g_UI_Interact[12][1], $GUI_FOCUS)
			Case $g_UI_Menu[6][5]; copy entry
				_Tra_ItemCopy()
			Case $g_UI_Menu[6][6]; edit entry
				_Admin_ItemEdit(0)
			Case $g_UI_Menu[6][7]; delete entry
				_Tra_ItemDelete()
			Case $g_UI_Menu[6][8]; select all
				ControlListView($g_UI[0], '', $g_UI_Interact[12][1], 'SelectAll')
			Case $g_UI_Menu[6][9]; new entry
				_Admin_ItemEdit(1)
			Case $g_UI_Menu[6][10]; revert
				_Tra_ModPopulateLists($g_Setups[$s][0])
			Case $g_UI_Menu[6][11]; Switch to copy/edit-mode
				_Tra_SetSize()
			Case $g_UI_Menu[6][13]; administrate mods
				$Switch=11
				ExitLoop
			Case $g_UI_Menu[6][14]; administrate selection
				$Switch=16
				ExitLoop
			Case $g_UI_Menu[6][15]; administrate dependencies
				$Switch=13
				ExitLoop
			Case $Accel[1]; !{Down} next translation
				_Tra_ModShowNextTra($g_Setups[$s][0], $Tra, +1)
			Case $Accel[2]; !{Up} previous translation
				_Tra_ModShowNextTra($g_Setups[$s][0], $Tra, -1)
			Case $Accel[3]; !1 left panel
				GUICtrlSetState($g_UI_Interact[12][1], $GUI_FOCUS)
			Case $Accel[4]; !2 right panel
				GUICtrlSetState($g_UI_Interact[12][2], $GUI_FOCUS)
			Case $Accel[5]; !m focus mod input-control
				GUICtrlSetState($g_UI_Interact[12][3], $GUI_FOCUS)
			Case $Accel[6]; !l focus component input-control
				GUICtrlSetState($g_UI_Interact[12][4], $GUI_FOCUS)
			Case $Accel[7]; ^d debug entry
				$ID2=GUICtrlRead($g_UI_Interact[12][2])
				$Text2=GUICtrlRead($ID2)
				ConsoleWrite($Text2 & @CRLF)
				$Text2=StringSplit($Text2, '')
				For $t=1 to $Text2[0]
					ConsoleWrite($t&': '&$Text2[$t]&': '& Asc($Text2[$t]) & @CRLF)
				Next
		EndSwitch
		Sleep(10)
	WEnd
	$Mod = GUICtrlRead($g_UI_Interact[12][3])
	If $Mod = _GetTR($Message, 'C1') Then $Mod = '-'; => choose a mod
	If $Switch Then
		If $Switch = 11 Then
			_Admin_ModGui($Mod)
		ElseIf $Switch = 13 Then
			_Dep_Gui()
		ElseIf $Switch = 16 Then
			_Select_Gui()
		EndIf
	Else
		_Misc_SetTab($g_Flags[10])
		$g_Flags[10]=0
	EndIf
EndFunc    ;==>_Tra_Gui

; ---------------------------------------------------------------------------------------------
; Copy one or multiple selected entries form the left to the right panel
; ---------------------------------------------------------------------------------------------
Func _Tra_ItemCopy($p_Selected='-')
	If $p_Selected='-' Then $p_Selected=ControlListView($g_UI[0], '', $g_UI_Interact[12][1], 'GetSelected', 1)
	$p_Selected = StringSplit($p_Selected, '|')
	$Total = ControlListView($g_UI[0], '', $g_UI_Interact[12][2], 'GetItemCount')
	For $s=1 to $p_Selected[0]
		$ID1=_GUICtrlListView_GetItemParam($g_UI_Interact[12][1], $p_Selected[$s])
		$Text1=StringSplit(GUICtrlRead($ID1), '|')
		$Found=0
		For $t=1 to $Total
			$ID2=_GUICtrlListView_GetItemParam($g_UI_Interact[12][2], $t-1)
			$Text2=StringSplit(GUICtrlRead($ID2), '|')
			If $Text1[1] = $Text2[1] Then
				If $Text1[2] <> $Text2[2] Then
					_Tra_ItemSetColor($ID1, $ID2, 0x1a8c14, '+1')
				Else
					_Tra_ItemSetColor($ID1, $ID2, 0x1a8c14)
				EndIf
				$Found=1
				GUICtrlSetData($ID2, $Text1[1]&'|'&$Text1[2])
				ExitLoop
			EndIf
		Next
		If $Found = 0 Then
			$ID2=GUICtrlCreateListViewItem($Text1[1]&'|'&$Text1[2], $g_UI_Interact[12][2])
			_Tra_ItemSetColor($ID1, $ID2, 0x1a8c14, '+1')
		EndIf
	Next
EndFunc    ;==>_Tra_ItemCopy

; ---------------------------------------------------------------------------------------------
; Delete a litviewitem in one of the listviews
; ---------------------------------------------------------------------------------------------
Func _Tra_ItemDelete()
	$Test=ControlGetHandle($g_UI[0], '', ControlGetFocus($g_UI[0]))
	If GUICtrlGetHandle($g_UI_Interact[12][1]) = $Test Then
		$Test = $g_UI_Interact[12][1]
		$Other = $g_UI_Interact[12][2]
	Else
		$Test = $g_UI_Interact[12][2]
		$Other = $g_UI_Interact[12][1]
	EndIf
	$List=StringSplit(ControlListView($g_UI[0], '', $Test, 'GetSelected', 1), '|')
	For $l=$List[0] to 1 Step -1
		$ID2=_GUICtrlListView_GetItemParam($Test, $List[$l])
		$Text2=StringSplit(GUICtrlRead($ID2), '|')
		$ID1 = _Tra_ItemGetID($Other, $Text2[1])
		GUICtrlDelete($ID2)
		If $ID1 <> '' Then
			$Text1=StringSplit(GUICtrlRead($ID1), '|')
			If $Text1[2] = $Text2[2] Then; remove one item from counter
				_Tra_ItemSetColor($ID1, '', 0xe8901a, '-1')
			Else
				_Tra_ItemSetColor($ID1, '', 0xe8901a)
			EndIf
		Else; delete something that exists only once
			If StringInStr(GUICtrlRead($g_UI_Static[12][2]), '~') Then
				$Num1 = ControlListView($g_UI[0], '', $Test, 'GetItemCount')
				$Num2 = ControlListView($g_UI[0], '', $Other, 'GetItemCount')
				If $Num1 = $Num2 Then
					GUICtrlSetData($g_UI_Static[12][2], $Num2)
					_Tra_ItemSetColor($g_UI_Static[12][1], $g_UI_Static[12][2], 0x1a8c14)
				ElseIf $Num1 > $Num2 Then; deleted an item of the larger array
					GUICtrlSetData($g_UI_Static[12][2], '~ '&$Num1)
				EndIf
			EndIf
		EndIf
	Next
EndFunc    ;==>_Tra_ItemDelete

; ---------------------------------------------------------------------------------------------
; Returns the item-id of an item which has a matching component-number
; ---------------------------------------------------------------------------------------------
Func _Tra_ItemGetID($p_List, $p_String)
	$Num1 = ControlListView($g_UI[0], '', $p_List, 'GetItemCount')
	For $n=1 to $Num1
		$ID1=_GUICtrlListView_GetItemParam($p_List, $n-1)
		$Text1=StringSplit(GUICtrlRead($ID1), '|')
		If $Text1[1] = $p_String Then Return $ID1
	Next
	Return ''
EndFunc    ;==>_Tra_ItemGetID

; ---------------------------------------------------------------------------------------------
; Color the listviewitems or labels depending on the circumstances
; ---------------------------------------------------------------------------------------------
Func _Tra_ItemSetColor($p_ID1, $p_ID2, $p_Color, $p_Num=0)
	If $p_ID1 <> '' Then GUICtrlSetColor($p_ID1, $p_Color)
	If $p_ID2 <> '' Then GUICtrlSetColor($p_ID2, $p_Color)
	;If $p_Num = 0 Then Return
	$Num1 = ControlListView($g_UI[0], '', $g_UI_Interact[12][1], 'GetItemCount')
	$Num2 = ControlListView($g_UI[0], '', $g_UI_Interact[12][2], 'GetItemCount')
	If StringInStr(GUICtrlRead($g_UI_Static[12][2]), '~') Then
		If $Num1 = $Num2 Then
			GUICtrlSetData($g_UI_Static[12][2], $Num2)
		Else
			$Num = StringTrimLeft(GUICtrlRead($g_UI_Static[12][2], $Num2), 2)
			If $Num1 > $Num2 And $Num1 > $Num Then GUICtrlSetData($g_UI_Static[12][2], '~ '&$Num1)
			If $Num2 > $Num1 And $Num2 > $Num Then GUICtrlSetData($g_UI_Static[12][2], '~ '&$Num2)
		EndIf
	Else
		If $Num2 > $Num1 Then GUICtrlSetData($g_UI_Static[12][2], '~ ' & $Num2)
	EndIf
	If $p_Num = '+1' Then
		GUICtrlSetData($g_UI_Static[12][1], GUICtrlRead($g_UI_Static[12][1])+1)
		If GUICtrlRead($g_UI_Static[12][1]) = GUICtrlRead($g_UI_Static[12][2]) Then _Tra_ItemSetColor($g_UI_Static[12][1], $g_UI_Static[12][2], 0x1a8c14)
	ElseIf $p_Num = '-1' Then
		GUICtrlSetData($g_UI_Static[12][1], GUICtrlRead($g_UI_Static[12][1])-1)
		_Tra_ItemSetColor($g_UI_Static[12][1], $g_UI_Static[12][2], 0xe8901a)
	EndIf
EndFunc    ;==>_Tra_ItemSetColor

; ---------------------------------------------------------------------------------------------
; Change or add a listviewitem
; ---------------------------------------------------------------------------------------------
Func _Tra_ItemWriteEntry()
	$Num=_Tra_StringCreate(GUICtrlRead($g_UI_Interact[12][5]))
	$Comp=GUICtrlRead($g_UI_Interact[12][6])
	$ID1=_Tra_ItemGetID($g_UI_Interact[12][1], $Num)
	$ID2=_Tra_ItemGetID($g_UI_Interact[12][2], $Num)
	$Text1=StringSplit(GUICtrlRead($ID1), '|')
	$Text2=StringSplit(GUICtrlRead($ID2), '|')
	If $ID1 <> '' And $ID2 <> '' Then; IDs both exist (and number is the same)
		If $Text2[2] = $Comp Then; no change
			Return
		ElseIf $Text1[2] = $Text2[2] Then; components were identical
			_Tra_ItemSetColor($ID1, $ID2, 0x0000ff, '-1'); remove one item from itentical because of the change
		ElseIf $Text1[2] <> $Text2[2] Then; components were not identical
			If $Text1[2] = $Comp Then
				_Tra_ItemSetColor($ID1, $ID2, 0x1a8c14, '+1')
			EndIf
		EndIf
	ElseIf $ID1 <> '' Then; Left exists, right is created
		$ID2=GUICtrlCreateListViewItem($Num&'|'&$Comp, $g_UI_Interact[12][2])
		If $Text1[2] = $Comp Then
			_Tra_ItemSetColor($ID1, $ID2, 0x1a8c14, '+1')
		Else
			_Tra_ItemSetColor($ID1, $ID2, 0x0000ff)
		EndIf
	ElseIf $ID2 <> '' Then; Left does not exist, right one is edited
		; just update the item later
	Else; Left does not exist, right is a new creation
		$ID2=GUICtrlCreateListViewItem($Num&'|'&$Comp, $g_UI_Interact[12][2])
		_Tra_ItemSetColor('', $ID2, 0xe8901a)
		_Tra_ItemSetColor($g_UI_Static[12][1], $g_UI_Static[12][2], 0xe8901a)
	EndIf
	GUICtrlSetData($ID2, $Num&'|'&$Comp)
EndFunc    ;==>_Tra_ItemWriteEntry

; ---------------------------------------------------------------------------------------------
; Color the items that match or differ
; ---------------------------------------------------------------------------------------------
Func _Tra_ModColorDiff($p_Mod, $p_Debug=0)
	Local $AutoSave, $Searched, $Same
	$Num1 = ControlListView($g_UI[0], '', $g_UI_Interact[12][1], 'GetItemCount')
	$Num2 = ControlListView($g_UI[0], '', $g_UI_Interact[12][2], 'GetItemCount')
	If $Num1 = $Num2 Then
		GUICtrlSetData($g_UI_Static[12][2], $Num1)
	ElseIf $Num1 > $Num2 Then
		GUICtrlSetData($g_UI_Static[12][2], '~ '&$Num1)
	Else
		GUICtrlSetData($g_UI_Static[12][2], '~ '&$Num2)
	EndIf
	For $n=1 to $Num1
		$ID1=_GUICtrlListView_GetItemParam($g_UI_Interact[12][1], $n-1)
		$Text1=StringSplit(GUICtrlRead($ID1), '|')
		$Found=0
		For $t=1 to $Num2
			$ID2=_GUICtrlListView_GetItemParam($g_UI_Interact[12][2], $t-1)
			$Text2=StringSplit(GUICtrlRead($ID2), '|')
			If $Text1[1] = $Text2[1] Then
				$Found=1
				$Searched&='|'&$t
				If $Text1[2] = $Text2[2] Then
					$Same +=1
					_Tra_ItemSetColor($ID1, $ID2, 0x1a8c14)
				ElseIf _Tra_StringStripVersion($Text1[2]) = _Tra_StringStripVersion($Text2[2]) Then
					GUICtrlSetData($ID2, $Text1[1]&'|'&$Text1[2])
					$Same +=1
					$AutoSave = 1
					_Tra_ItemSetColor($ID1, $ID2, 0x1a8c14)
				Else
					If $p_Debug = 1 Then
						ConsoleWrite('-"'& $Text1[2] & '"'& @CRLF)
						ConsoleWrite('!"'& $Text2[2] & '"'&  @CRLF)
					EndIf
					_Tra_ItemSetColor($ID1, $ID2, 0x0000ff)
				EndIf
				ExitLoop
			EndIf
		Next
		If $Found = 0 Then _Tra_ItemSetColor($ID1, '', 0xe8901a)
	Next
	GUICtrlSetData($g_UI_Static[12][1], $Same)
	If $Same = $Num1 And $Num1 = $Num2 Then
		_Tra_ItemSetColor($g_UI_Static[12][1], $g_UI_Static[12][2], 0x1a8c14)
	Else
		_Tra_ItemSetColor($g_UI_Static[12][1], $g_UI_Static[12][2], 0xe8901a)
	EndIf
	$Searched&='|'
	For $t=1 to $Num2
		If StringInStr($Searched, '|'&$t&'|') Then ContinueLoop
		$ID2=_GUICtrlListView_GetItemParam($g_UI_Interact[12][2], $t-1)
		_Tra_ItemSetColor('', $ID2, 0xe8901a)
	Next
	If $AutoSave = 1 Then _Tra_ModSave($p_Mod, 0)
	If $Same = $Num1 And $Num1 = $Num2 Then Return 0
	Return 1
EndFunc    ;==>_Tra_ModColorDiff

; ---------------------------------------------------------------------------------------------
; Delete old entries and add new to panels
; ---------------------------------------------------------------------------------------------
Func _Tra_ModListComponents($p_List, $p_Array)
	$Test=_GUICtrlListView_DeleteAllItems($p_List)
	If $Test = False Then
		GUISwitch($g_UI[0], $g_UI_Seperate[12][0]); create the new controls on the current tab
		$Old=$p_List
		$Num=ControlListView($g_UI[0], '', $p_List, 'GetSelected')
		If $p_List = $g_UI_Interact[12][1] Then
			$g_UI_Interact[12][1] = GUICtrlCreateListView(IniRead($g_TRAIni, 'UI-Buildtime', 'Interact[12][1]', ''), 15, 90, 335, 290, $LVS_REPORT+$LVS_SORTASCENDING+$LVS_NOSORTHEADER, $LVS_EX_GRIDLINES + $LVS_EX_FULLROWSELECT + $LVS_EX_INFOTIP + $WS_Ex_Clientedge)
			GUICtrlSetResizing(-1, 98)
			$g_UI_Handle[6] = GUICtrlGetHandle($g_UI_Interact[12][1])
			_GUICtrlListView_SetColumnWidth($g_UI_Interact[12][1], 1, 265)
			GUICtrlSetState($g_UI_Interact[12][1], $GUI_SHOW)
			$p_List = $g_UI_Interact[12][1]
		Else

			$g_UI_Interact[12][2] = GUICtrlCreateListView(IniRead($g_TRAIni, 'UI-Buildtime', 'Interact[12][2]', ''), 400, 90, 335, 290, $LVS_REPORT+$LVS_SORTASCENDING+$LVS_NOSORTHEADER, $LVS_EX_GRIDLINES + $LVS_EX_FULLROWSELECT + $LVS_EX_INFOTIP + $WS_Ex_Clientedge)
			GUICtrlSetResizing(-1, 100)
			$g_UI_Handle[7] = GUICtrlGetHandle($g_UI_Interact[12][2])
			_GUICtrlListView_SetColumnWidth($g_UI_Interact[12][2], 1, 265)
			GUICtrlSetState($g_UI_Interact[12][2], $GUI_SHOW)
			$p_List = $g_UI_Interact[12][2]
		EndIf
		GUICtrlDelete($Old)
		ControlListView($g_UI[0], '', $p_List, 'Select', $Num)
	EndIf
	If Not IsArray($p_Array) Then Return
	For $p=1 to $p_Array[0][0]
		GUICtrlCreateListViewItem(_Tra_StringCreate($p_Array[$p][0])&'|'&StringStripWS($p_Array[$p][1], 3), $p_List)
	Next
EndFunc    ;==>_Tra_ModListComponents

; ---------------------------------------------------------------------------------------------
; Populate both the actual weidu and the stored info of a certain mod
; ---------------------------------------------------------------------------------------------
Func _Tra_ModPopulateLists($p_Mod)
	_Tra_ModListComponents($g_UI_Interact[12][1], _Tra_WeiDUGetComponents($p_Mod, StringTrimLeft(GUICtrlRead($g_UI_Interact[12][4]), 3)))
	_Tra_ModListComponents($g_UI_Interact[12][2], IniReadSection($g_GConfDir & '\Weidu-'&StringLeft(GUICtrlRead($g_UI_Interact[12][4]), 2)&'.ini', $p_Mod))
	_Tra_ModColorDiff($p_Mod)
	ControlListView($g_UI[0], '', $g_UI_Interact[12][1], 'Select', 0)
	ControlListView($g_UI[0], '', $g_UI_Interact[12][2], 'Select', 0)
	GUICtrlSetState($g_UI_Interact[12][1], $GUI_FOCUS)
EndFunc    ;==>_Tra_ModPopulateLists

; ---------------------------------------------------------------------------------------------
; Save the configuration of the current right panel
; ---------------------------------------------------------------------------------------------
Func _Tra_ModSave($p_Mod, $p_Num=1000)
	Local $Return[500][2]
	$Tra=IniRead($g_MODIni, $p_Mod, 'Tra', '')
	$Lang=GUICtrlRead($g_UI_Interact[12][4])
	If $p_Mod = '' Then Return
	If $Lang = '' Then Return
	GUICtrlSetState($g_UI_Static[12][3], $GUI_SHOW)
	$Num2 = ControlListView($g_UI[0], '', $g_UI_Interact[12][2], 'GetItemCount')
	If $Num2 = 0 Then
		;$Question=_Misc_MsgGUI(3, 'Warning', 'Do you really want to delete the translation?', 2)
		$Question = MsgBox(48+4, 'Warning', 'Do you really want to delete the translation?')
		If $Question = 6 Then ConsoleWrite('dooh' & @CRLF)
		Return
	EndIf
	For $n=1 to $Num2
		$ID2=_GUICtrlListView_GetItemParam($g_UI_Interact[12][2], $n-1)
		$Text2=StringSplit(GUICtrlRead($ID2), '|')
		If StringRegExp($Text2[1], '\A\d') Then $Text2[1]='@'&_Tra_StringStripNul($Text2[1])
		$Return[0][0]+=1
		$Return[$Return[0][0]][0]=$Text2[1]
		$Return[$Return[0][0]][1]=_Tra_StringStripVersion($Text2[2])
	Next
	ReDim $Return[$Return[0][0]+1][2]
	IniWriteSection($g_GConfDir & '\Weidu-'&StringLeft(GUICtrlRead($g_UI_Interact[12][4]), 2)&'.ini', $p_Mod, $Return)
	If StringInStr($Tra, $Lang) Then
		$Return = $Tra
	Else
		$LangNum=StringTrimLeft($Lang, 3)
		If StringInStr($Tra, ':'&$LangNum) Then
			$Return = InputBox($g_ProgName, 'The LangNum is used twice.'&@CRLF&'Please verify the Tra-String.', $Tra&','&$Lang)
		ElseIf StringInStr($Tra, StringLeft($Lang, 2) &':') Then
			$Return = InputBox($g_ProgName, 'The LangName is used twice.'&@CRLF&'Please verify the Tra-String.', $Tra&','&$Lang)
		Else
			$Return = $Tra&','&$Lang
		EndIf
	EndIf
	IniWrite($g_MODIni, $p_Mod, 'Tra', StringRegExpReplace($Return, '\A\x2c,', ''))
	Sleep($p_Num)
	GUICtrlSetState($g_UI_Static[12][3], $GUI_HIDE)
EndFunc    ;==>_Tra_ModSave

; ---------------------------------------------------------------------------------------------
; Scan for mods in the current folder that have new translations
; ---------------------------------------------------------------------------------------------
Func _Tra_ModScan()
	$Lang = GUICtrlRead($g_UI_Interact[12][4])
	$Mod=GUICtrlRead($g_UI_Interact[12][3])
	$s=_Admin_ModGetIndex($Mod, 0)
	While $s <= $g_Setups[0][0]
		GUICtrlSetData($g_UI_Interact[12][3], $g_Setups[$s][0])
		GUICtrlSetData($g_UI_Interact[12][7], $g_Setups[$s][1])
		$lTra=_Tra_WeiDUGetTra($g_Setups[$s][0])
		$Tra=StringSplit($lTra, ',')
		GUICtrlSetData($g_UI_Interact[12][4], '')
		GUICtrlSetData($g_UI_Interact[12][4], StringReplace($lTra, ',', '|'))
		ConsoleWrite('>'&$Tra[0] & @CRLF)
		For $t=1 to $Tra[0]
			ConsoleWrite('+'&$g_Setups[$s][0] & ' ' & $Tra[$t] & @CRLF)
			GUICtrlSetData($g_UI_Interact[12][4], $Tra[$t])
			_Tra_ModListComponents($g_UI_Interact[12][1], _Tra_WeiDUGetComponents($g_Setups[$s][0], StringTrimLeft($Tra[$t], 3)))
			_Tra_ModListComponents($g_UI_Interact[12][2], IniReadSection($g_GConfDir & '\Weidu-'&StringLeft($Tra[$t], 2)&'.ini', $g_Setups[$s][0]))
			If _Tra_ModColorDiff($g_Setups[$s][0], 1) = 1 Then ExitLoop(2)
			If $t=$Tra[0] Then $s+=1
		Next
	WEnd
	ControlListView($g_UI[0], '', $g_UI_Interact[12][1], 'Select', 0)
	ControlListView($g_UI[0], '', $g_UI_Interact[12][2], 'Select', 0)
	GUICtrlSetState($g_UI_Interact[12][1], $GUI_FOCUS)
	Return $s
EndFunc    ;==>_Tra_ModScan

; ---------------------------------------------------------------------------------------------
; Switch the info to default-translation of a certain mod
; ---------------------------------------------------------------------------------------------
Func _Tra_ModShowDefaultTra($p_Num)
	$lTra=_Tra_WeiDUGetTra($g_Setups[$p_Num][0])
	$iTra=IniRead($g_MODIni, $g_Setups[$p_Num][0], 'Tra', 'EN:0')
	If $lTra = -1 Then
		$lTra=$iTra; enable editing of existing translation if mod was not found
	Else
		$Add = StringRegExp($iTra, '(?i)--:\d{1,}', 3); Add strings for Not-Text-mods
		If IsArray($Add) Then
			$Add = StringRegExp($iTra, '(?i)[^--]{2}'&StringTrimLeft($Add[0], 2), 3); return the correct token if NT-dummy was found
			$lTra&=','&$Add
		EndIf
	EndIf
	Local $Default[1]=[$lTra]
	$Default = _GetTra($Default, 'S')
	If $Default = '' Then $Default = StringLeft($lTra, 4)
	GUICtrlSetData($g_UI_Interact[12][3], $g_Setups[$p_Num][0])
	GUICtrlSetData($g_UI_Interact[12][4], '|'&StringReplace($lTra, ',', '|'), $Default); destroy and reset the translation-list
	GUICtrlSetData($g_UI_Interact[12][7], $g_Setups[$p_Num][1])
	_Tra_ModPopulateLists($g_Setups[$p_Num][0])
	Return $lTra
EndFunc    ;==>_Tra_ModShowDefaultTra

; ---------------------------------------------------------------------------------------------
; Jump to the next or previous translation
; ---------------------------------------------------------------------------------------------
Func _Tra_ModShowNextTra($p_Mod, $p_Tra, $p_Num)
	$Tra=StringSplit($p_Tra, ',')
	If $Tra[0]=1 Then Return; there's nothing to change to
	$Num=StringTrimLeft(GUICtrlRead($g_UI_Interact[12][4]), 3)+1+$p_Num; weidu is 0-based, stringsplit 1-based index, so increase by one
	If $Num>$Tra[0] Then
		$Num=1
	ElseIf $Num=0 Then
		$Num=$Tra[0]
	EndIf
	GUICtrlSetData($g_UI_Interact[12][4], $Tra[$Num])
	_Tra_ModPopulateLists($p_Mod)
EndFunc    ;==>_Tra_ModShowNextTra

; ---------------------------------------------------------------------------------------------
; Switch between copy/edit-mode translation tab
; ---------------------------------------------------------------------------------------------
Func _Tra_SetSize()
	$wPos=ControlGetPos($g_UI[0], '', $g_UI_Static[0][1]); with of group ctrl around always visible buttons matches with
	$Pos=ControlGetPos($g_UI[0], '', $g_UI_Interact[12][1]); position of the LV
	$State=BitAND(GUICtrlGetState($g_UI_Button[12][1]), $GUI_HIDE)
	If $State Then
		GUICtrlSetPos($g_UI_Interact[12][2], $wPos[0]+$wPos[2]-$Pos[2], 90, $Pos[2], $Pos[3])
		GUICtrlSetState($g_UI_Interact[12][1], $GUI_SHOW)
		GUICtrlSetState($g_UI_Button[12][1], $GUI_SHOW)
		GUICtrlSetState($g_UI_Button[12][2], $GUI_SHOW)
		GUICtrlSetState($g_UI_Static[12][1], $GUI_SHOW)
		GUICtrlSetState($g_UI_Static[12][2], $GUI_SHOW)
;~ 		GUICtrlSetData($g_UI_Button[4][2], '>')
	Else
		GUICtrlSetPos($g_UI_Interact[12][2], 15, 90, $wPos[2], $Pos[3])
		GUICtrlSetState($g_UI_Interact[12][1], $GUI_HIDE)
		GUICtrlSetState($g_UI_Button[12][1], $GUI_HIDE)
		GUICtrlSetState($g_UI_Button[12][2], $GUI_HIDE)
		GUICtrlSetState($g_UI_Static[12][1], $GUI_HIDE)
		GUICtrlSetState($g_UI_Static[12][2], $GUI_HIDE)
;~ 		GUICtrlSetData($g_UI_Button[4][2], '<')
	EndIf
EndFunc    ;==>_Tra_SetSize

; ---------------------------------------------------------------------------------------------
; Add nulls in front of the component number so the length of the base is always 4
; ---------------------------------------------------------------------------------------------
Func _Tra_StringCreate($p_String)
	$Text = StringReplace($p_String, '@', '')
	If $Text <> 'Tra' Then
		$Pos=StringInStr($Text, '?')
		If $Pos = 0 Then
			$Text = _Tree_SetLength($Text)
		ElseIf $Pos < 4 Then
			$Text1 = _Tree_SetLength(StringLeft($Text, $Pos-1))
			$Text2 = StringTrimLeft($Text, $Pos)
			$Text = $Text1&'?'&$Text2
		EndIf
	EndIf
	Return $Text
EndFunc    ;==>_Tra_StringCreate

; ---------------------------------------------------------------------------------------------
; Remove the artificially added nulls in front of the component number
; ---------------------------------------------------------------------------------------------
Func _Tra_StringStripNul($p_String)
	$p_String=StringRegExpReplace($p_String, '\A0{1,3}', '')
	Return $p_String
EndFunc    ;==>_Tra_StringStripNul

; ---------------------------------------------------------------------------------------------
; Strip version histrory from WeiDU-component-description
; ---------------------------------------------------------------------------------------------
Func _Tra_StringStripVersion($p_String)
	$p_String=StringRegExpReplace($p_String, '(?i)(,|:)[,:v\s\x2e\d]*\z', ''); strip everything that should be a VERSION-string (in translation-strings)
	$p_String=StringRegExpReplace($p_String, '(?i)\sv[\s\x2e\d]*\z', ''); yeah, look nearly the same. But could not be included above since simple numbers would be stripped, too.
	Return $p_String
EndFunc    ;==>_Tra_StringStripVersion

; ---------------------------------------------------------------------------------------------
; Fetches the available component-numbers and translations for a certain language
; ---------------------------------------------------------------------------------------------
Func _Tra_WeiDUGetComponents($p_TP2, $p_Num)
	Local $Return[500][2]
	If StringRegExp($p_TP2, '(?i).tp2') = 0 Then $p_TP2=_Test_GetTP2($p_TP2)
	If Not FileExists($p_TP2) Then Return
	$Version=StringReplace(_Tra_GetVersion($p_TP2), '(', '\x28')
	$Version=StringReplace($Version, ')', '\x29')
	$Run=_RunSTD('"'&$g_GameDir&'\WeiDU.exe" --nogame --list-components "'&$p_TP2&'" '&$p_Num, $g_GameDir)
	$Run=StringSplit(StringStripCR($Run), @LF); it's a @CRLF, but oddly things mess up if I use it...
	For $r=1 to $Run[0]-1
		If Not StringInStr($Run[$r], '~ #') Then ContinueLoop
		$Return[0][0]+=1
		$Line=StringRegExpReplace($Run[$r], '\A.*\x7e\s\x23.', '')
		$Line=_StringVerifyExtAscII($Line) ; @CR|(...|[...
		$Line=StringSplit(StringRegExpReplace($Line, '\A\s\x23', ''), ' // ', 1)
		$Return[$Return[0][0]][0]=$Line[1]
		$Return[$Return[0][0]][1]=_Tra_StringStripVersion(StringRegExpReplace($Line[2], ':\s'&$Version&'\z', '')); for translations that use VERSION-strings in TP2-files
	Next
	$Return[0][0]+=1
	$Return[$Return[0][0]][0]='Tra'
	$Return[$Return[0][0]][1]=$p_Num
	ReDim $Return[$Return[0][0]+1][2]
	Return $Return
EndFunc    ;==>_Tra_WeiDUGetComponents

; ---------------------------------------------------------------------------------------------
; Fetches the currently available translations for a mod
; ---------------------------------------------------------------------------------------------
Func _Tra_WeiDUGetTra($p_Setup, $p_TP2='')
	Local $Return
	Local $LCodes[13]=[12, 'GE','EN','FR','PO','RU','IT','SP','CZ','KO','CH','JP','PR']
	If $p_TP2 = '' Then
		$TP2=_Test_GetTP2($p_Setup)
	Else
		$TP2=$p_TP2
	EndIf
	If Not FileExists($TP2) Then Return -1
	If Not FileExists($g_GameDir&'\WeiDU.exe') Then
		$Found = FileFindNextFile(FileFindFirstFile($g_GameDir&'\Setup-*.exe'))
		If StringRegExp($Found, '(?i)\ASetup-.*\x2eexe\z') Then
			FileCopy($g_GameDir&'\'&$Found, $g_GameDir&'\WeiDU.exe')
		Else
			ConsoleWrite('Put a WeiDU.exe into '&$g_GameDir&@CRLF)
		EndIf
	EndIf
	$Out=_RunSTD('"'&$g_GameDir&'\WeiDU.exe" --nogame --list-languages "'&$TP2&'"', $g_GameDir)
	If StringInStr($Out, 'ERROR') Then
		If StringInStr($Out, 'unknown option') Then
			Local $Message = IniReadSection($g_TRAIni, 'IN-Au3RunFix')
			_Misc_MsgGUI(4, _GetTR($Message, 'T1'), _GetTR($Message, 'L9')); => error / need current weidu
		EndIf
		Local $Out[1]=[3]
	EndIf
	Local $Found=0, $Comp = ''
	$Out=StringSplit($Out, @LF); it's a @CRLF, but oddly things mess up if I use it...
	For $o=1 to $Out[0]
		If StringRegExp($Out[$o], '\A\d') Then
			$Found=1
			ExitLoop
		EndIf
	Next
	If $Found = 0 Then
		$Lang=IniRead($g_MODIni, $p_Setup, 'TRA', '')
		If $Lang = '' Then
			$Lang = 'EN:0'
			$VerfyLang=1
		Else
			If StringInStr($Lang, ',') Then $Lang=StringLeft($Lang, 4)
			$VerfyLang=0
		EndIf
		$Lang =StringTrimRight(StringReplace($Lang, '-', 'EN'), 2)
		If $VerfyLang =1 Then $Lang=InputBox('Please verify by typing in the correct token (XX)', $p_Setup, $Lang, '', 500, 150)
		For $l=1 to $LCodes[0]
			If $Lang = $LCodes[$l] Then
				Return $Lang&':0'
			EndIf
		Next
		Return -1
	Else
		For $o=1 to $Out[0]-1
			If Not StringRegExp($Out[$o], '\A\d{1,}\x3a') Then ContinueLoop
			$Line=_StringVerifyExtAscII($Out[$o]) ; @CR|(...|[...
			If StringRegExp($Line, '(?i)German|Deutsch|Deutch') Then
				$LNum = 1
			ElseIf StringRegExp($Line, '(?i)English|American') Then
				$LNum = 2
			ElseIf StringRegExp($Line, '(?i)French|Fran') Then
				$LNum = 3
			ElseIf StringRegExp($Line, '(?i)Polish|Polski') Then
				$LNum = 4
			ElseIf StringRegExp($Line, '(?i)Russian|aerie.ru|'&Chr(227)&Chr(223)&Chr(223)) Then
				$LNum = 5
			ElseIf StringRegExp($Line, '(?i)Italia')  Then
				$LNum = 6
			ElseIf StringRegExp($Line, '(?i)Spanish|Espa|Castellano|Castilian') Then
				$LNum = 7
			ElseIf StringRegExp($Line, '(?i)Czech|Cesky|cz') Then
				$LNum = 8
			ElseIf StringRegExp($Line, '(?i)Korean')  Then
				$LNum = 9
			ElseIf StringRegExp($Line, '(?i)Chinese')  Then
				$LNum = 10
			ElseIf StringRegExp($Line, '(?i)Japanese')  Then
				$LNum = 11
			ElseIf StringRegExp($Line, '(?i)Portuguese')  Then
				$LNum = 12
			Else
				While 1
					$Found=0
					$Lang=InputBox('Please verify by typing in the correct token (XX)', $p_Setup, $Line, '', 500, 150)
					For $LNum = 1 to $LCodes[0]
						If $Lang = $LCodes[$LNum] Then
							$Found=1
							ExitLoop
						EndIf
					Next
					If $Found = 1 Then ExitLoop
				WEnd
			EndIf
			$Return&=','&$LCodes[$LNum]&':'&StringLeft($Line, StringInStr($Line, ':', 1, 1)-1)
		Next
	EndIf
	Return StringRegExpReplace($Return, '\A(\s|,)*', '')
EndFunc    ;==>_Tra_WeiDUGetTra

; ---------------------------------------------------------------------------------------------
; Get special events like double-clicks, focus and so on
; ---------------------------------------------------------------------------------------------
Func _Tra_WM_Notify($hWnd, $iMsg, $iwParam, $ilParam)
	#forceref $hWnd, $iMsg, $iwParam
	Local $hWndFrom, $iIDFrom, $iCode, $tNMHDR
	$tNMHDR = DllStructCreate($tagNMHDR, $ilParam)
	$hWndFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
	$iIDFrom = DllStructGetData($tNMHDR, "IDFrom")
	$iCode = DllStructGetData($tNMHDR, "Code")
	Switch $hWndFrom
		Case $g_UI_Handle[6]
			Switch $iCode
				Case $NM_KILLFOCUS ; The control has lost the input focus
					$g_Flags[16]=0
				Case $NM_RCLICK ; Sent by a list-view control when the user clicks an item with the right mouse button
					$g_Flags[16]=3
				Case $NM_SETFOCUS ; The control has received the input focus
					$g_Flags[16]=1
			EndSwitch
		Case $g_UI_Handle[7]
			Switch $iCode
				Case $NM_DBLCLK ; Sent by a list-view control when the user double-clicks an item with the left mouse button
					_Admin_ItemEdit()
				Case $NM_KILLFOCUS ; The control has lost the input focus
					$g_Flags[16]=0
				Case $NM_RCLICK ; Sent by a list-view control when the user clicks an item with the right mouse button
					$g_Flags[16]=4
				Case $NM_SETFOCUS ; The control has received the input focus
					$g_Flags[16]=2
			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_NOTIFY