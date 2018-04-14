#include-once

; ---------------------------------------------------------------------------------------------
; Add a pause to the $g_CentralArray[$p_Num][15] or jump to the next component
; ---------------------------------------------------------------------------------------------
Func _Selection_ContextMenu()
	Local $State, $FirstModItem, $NextModItem, $MenuItem[7]
	Local $p_Num = GUICtrlRead($g_UI_Interact[4][1])
	If $p_Num >= $g_CentralArray[0][1] And $p_Num <= $g_CentralArray[0][0] Then; prevent crashes if $g_CentralArray is undefined
		GUISetState(@SW_DISABLE); disable the GUI itself while selection is pending to avoid unwanted treeview-changes
		Local $OldMode=AutoItSetOption('GUIOnEventMode')
		If $OldMode Then AutoItSetOption('GUIOnEventMode', 0)
		Local $Tree = GUICtrlRead($p_Num, 1)
		Local $MenuString = $Tree
		If $g_CentralArray[$p_Num][2] = '-' Then $MenuString = $g_CentralArray[$p_Num][4]
		Local $IsPaused =  StringRegExp($Tree, '\s\x5bP\x5d\z')
		$g_UI_Menu[0][4] = GUICtrlCreateContextMenu($p_Num); create a context-menu on the clicked item
		Local $MenuLabel = GUICtrlCreateMenuItem($MenuString, $g_UI_Menu[0][4])
		GUICtrlSetState(-1, $GUI_DISABLE)
		GUICtrlCreateMenuItem('', $g_UI_Menu[0][4]); separator
; ---------------------------------------------------------------------------------------------
; Create the pause-menu items
; ---------------------------------------------------------------------------------------------
		If $g_CentralArray[$p_Num][2] = '-' Then
			$MenuItem[1] = GUICtrlCreateMenuItem(_GetTR($g_UI_Message, '4-L8'), $g_UI_Menu[0][4]); => pause before mod
			$MenuItem[2] = GUICtrlCreateMenuItem(_GetTR($g_UI_Message, '4-L9'), $g_UI_Menu[0][4]); => don't pause before mod
			$FirstModItem = $p_Num+1
			While StringRegExp($g_CentralArray[$FirstModItem][2], '\A\D')
				If $FirstModItem <= $g_CentralArray[0][0] Then ExitLoop
				$FirstModItem+=1
			WEnd
		Else
			$MenuItem[1] = GUICtrlCreateMenuItem(_GetTR($g_UI_Message, '4-L10'), $g_UI_Menu[0][4]); => pause before component
			$MenuItem[2] = GUICtrlCreateMenuItem(_GetTR($g_UI_Message, '4-L11'), $g_UI_Menu[0][4]); => don't pause before component
		EndIf
; ---------------------------------------------------------------------------------------------
; See if the mod was splitted and enable to jump to the next chapter
; ---------------------------------------------------------------------------------------------
		Local $Splitted, $Headline=_AI_GetStart($p_Num, '-')
		If $g_CentralArray[$Headline][13] <> '' Then
			$Splitted=StringSplit($g_CentralArray[$Headline][13], ',')
			$NextModItem=$Splitted[1]
		EndIf
		GUICtrlCreateMenuItem('', $g_UI_Menu[0][4]); separator
		$MenuItem[0] = GUICtrlCreateMenuItem(_GetTR($g_UI_Message, '4-L6'), $g_UI_Menu[0][4]); => visit homepage
		$MenuItem[6] = GUICtrlCreateMenuItem(_GetTR($g_UI_Message, '4-L25'), $g_UI_Menu[0][4]); => Download Manually
		GUICtrlCreateMenuItem('', $g_UI_Menu[0][4]); separator
		If $g_CentralArray[$p_Num][2] <> '-' Then ; hide or expand the components
			$MenuItem[4] = GUICtrlCreateMenuItem(_GetTR($g_UI_Message, '4-M1'), $g_UI_Menu[0][4]); => hide components
		Else
			$State = _GUICtrlTreeView_GetExpanded($g_UI_Handle[0], $g_CentralArray[$p_Num][5])
			If $State = True Then
				$MenuItem[4] = GUICtrlCreateMenuItem(_GetTR($g_UI_Message, '4-M1'), $g_UI_Menu[0][4]); => hide components
			Else
				$MenuItem[4] = GUICtrlCreateMenuItem(_GetTR($g_UI_Message, '4-M2'), $g_UI_Menu[0][4]); => show components
			EndIf
		EndIf
		If $NextModItem <> '' Then; there is a next part of the mod >> create a menu-item
			GUICtrlCreateMenuItem('', $g_UI_Menu[0][4]); separator
			$MenuItem[3] = GUICtrlCreateMenuItem(_GetTR($g_UI_Message, '4-L12'), $g_UI_Menu[0][4]); => jump to next part of mod
		EndIf
		If StringInStr($g_CentralArray[$p_Num][2], '?') Then
			$Pos=StringInStr($g_CentralArray[$p_Num][2], '_', 0, -1)
			$Definition=IniRead($g_GConfDir&'\Game.ini', 'Edit', $g_CentralArray[$p_Num][0]&';'&StringLeft($g_CentralArray[$p_Num][2], $Pos-1), '')
			If $Definition <> '' Then
				GUICtrlCreateMenuItem('', $g_UI_Menu[0][4]); separator
				$MenuItem[5] = GUICtrlCreateMenuItem(_GetTR($g_UI_Message, '4-L24'), $g_UI_Menu[0][4]); => edit value
			EndIf
		EndIf
		__ShowContextMenu($g_UI[0], $p_Num, $g_UI_Menu[0][4])
; ---------------------------------------------------------------------------------------------
; Create another Msg-loop, since the GUI is disabled and only the menuitems should be available
; ---------------------------------------------------------------------------------------------
		Local $Msg, $Return
		While 1
			$Msg = GUIGetMsg()
			Switch $Msg
			Case $MenuItem[0]; homepage
				_Selection_OpenPage()
				ExitLoop
			Case $MenuItem[1]; pause
				If Not $IsPaused Then GUICtrlSetData($p_Num, $Tree & ' [P]')
				If $g_CentralArray[$p_Num][2] = '-' Then
					$g_CentralArray[$FirstModItem][15]=1
				Else
					$g_CentralArray[$p_Num][15]=1
				EndIf
				ExitLoop
			Case $MenuItem[2]; not pause
				If $IsPaused Then GUICtrlSetData($p_Num, StringRegExpReplace($Tree, '\s\x5bP\x5d\z', ''))
				If $g_CentralArray[$p_Num][2] = '-' Then
					$g_CentralArray[$FirstModItem][15]=0
				Else
					$g_CentralArray[$p_Num][15]=0
				EndIf
				ExitLoop
			Case $MenuItem[3]; jump to next item
				If $MenuItem[3] = '' Then ExitLoop
				If $NextModItem = '' Then ExitLoop; no next item to jump to
				_GUICtrlTreeView_SelectItem($g_UI_Handle[0], $g_CentralArray[$NextModItem][5], $TVGN_FIRSTVISIBLE); select and view the first item
				_GUICtrlTreeView_SelectItem($g_UI_Handle[0], $g_CentralArray[$NextModItem][5], $TVGN_CARET)
				_GUICtrlTreeView_SetSelected($g_UI_Handle[0], $g_CentralArray[$NextModItem][5])
				ExitLoop
			Case $MenuItem[4]; (do not) expand components
				If $g_CentralArray[$p_Num][2] <> '-' Then
					_GUICtrlTreeView_Expand($g_UI_Handle[0], _AI_GetStart($p_Num, '-'), False)
				Else
					If $State = True Then
						_GUICtrlTreeView_Expand($g_UI_Handle[0], $p_Num, False)
					Else
						_GUICtrlTreeView_Expand($g_UI_Handle[0], $p_Num, True)
					EndIf
				EndIf
				ExitLoop
			Case $MenuItem[5]; set value
				$Return=InputBox($g_ProgName, _GetTR($g_UI_Message, '4-L2'), StringMid($g_CentralArray[$p_Num][2], $Pos+1), '', -1, -1, Default, Default, 0, $g_UI[0])
				If $Return <> '' Then
					If StringRegExp($Return, '\A'&$Definition&'\z') = 1 Then
						IniWrite($g_UsrIni, 'Edit', $g_CentralArray[$p_Num][0]&';'&$g_CentralArray[$p_Num][2], $Return)
						;$g_CentralArray[$p_Num][2]=StringLeft($g_CentralArray[$p_Num][2], $Pos)&$Return
						GUICtrlSetData($p_Num, $g_CentralArray[$p_Num][3]&' => '&_GetTR($g_UI_Message, '4-L21')&' '&$Return)
					Else
						GUISetState(@SW_ENABLE); enable the GUI again
						_Misc_MsgGUI(4, _GetTR($g_UI_Message, '4-L2'), _GetTR($g_UI_Message, '4-L22')&@CRLF&@CRLF&$Definition)
					EndIf
				EndIf
				ExitLoop
			Case $MenuItem[6]; Download Manually
				_Selection_Download_Manually()
				ExitLoop
			Case Else
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
		If $OldMode Then AutoItSetOption('GUIOnEventMode', 0)
		GUISetState(@SW_ENABLE); enable the GUI again
		GUICtrlDelete($g_UI_Menu[0][4])
	EndIf
	$g_Flags[16] = 0
EndFunc    ;==>_Selection_ContextMenu

; ---------------------------------------------------------------------------------------------
; Warn if expert mods or mods with warnings are going to be installed
; ---------------------------------------------------------------------------------------------
Func _Selection_ExpertWarning($p_Buttons = 2)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Selection_ExpertWarning')
	Local $Expert, $Warning
	For $w = $g_CentralArray[0][1] To $g_CentralArray[0][0]
		If GUICtrlRead($w) = 0 Then ContinueLoop; not sure why we need this
		If $g_CentralArray[$w][9] = 0 Then ContinueLoop; skip not selected
		If $g_CentralArray[$w][2] = '-' Then; this is a mod headline
			If StringInStr($g_CentralArray[$w][11], 'E') And Not StringRegExp($g_CentralArray[$w][11], '[FRST]') Then
				; Only add mod once even if it appears in multiple theme sections
				If Not StringInStr($Expert, $g_CentralArray[$w][4]&'|') Then
					$Expert &= $g_CentralArray[$w][4]&'|'
				EndIf
			ElseIf StringInStr($g_CentralArray[$w][11], 'W') Then
				; Only add mod once even if it appears in multiple theme sections
				If Not StringInStr($Warning, '|** '&$g_CentralArray[$w][4]) Then
					$Warning &= '|** '&$g_CentralArray[$w][4]
				EndIf
			EndIf
		ElseIf StringInStr($Expert, $g_CentralArray[$w][4]&'|') Then
			ContinueLoop; we already logged the mod headline, so skip its components
		ElseIf $g_CentralArray[$w][12] = '0001' Then; this is an Expert pre-selection-only component
			$Expert &= $g_CentralArray[$w][4]&'('&$g_CentralArray[$w][2]&'): '&$g_CentralArray[$w][3]&'|'
		EndIf
	Next
	If $Expert = '' And $Warning = '' Then Return 2
	Local $Test=_Misc_MsgGUI(3, _GetTR($g_UI_Message, '0-T1'), _GetTR($g_UI_Message, '8-L1')&$Expert&$Warning, $p_Buttons); => expert-warning
	Return $Test
EndFunc    ;==>_Selection_ExpertWarning

; ---------------------------------------------------------------------------------------------
; Get the current install-version
; ---------------------------------------------------------------------------------------------
Func _Selection_GetCurrentInstallType()
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Selection_GetCurrentInstallType')
	Local $Array = StringSplit(_GetTR($g_UI_Message, '2-I1'), '|'); => versions
	Local $Num = StringSplit($g_Flags[25], '|') 	; indices of available selections (00|01|02|03|04|05 ... |1|2|3|4|5)
													; default pre-selections at the end are represented by single digits
	Local $String = GUICtrlRead($g_UI_Interact[2][4]) ; current compilation/selection (from drop-down menu)
	Local $Found=0
	For $a = 1 To $Array[0]
		If $Array[$a] = $String Then
			$Found=1
			ExitLoop; the result is the number of the compilation type
		EndIf
	Next
	If $Found = 0 Then; prevent crash if language has changed
;		If $g_Flags[14] = 'BWS' Then
;			$a=1; total happiness
;		Else
			$a=2; recommended
;		EndIf
	EndIf
	Local $ClickModes = StringSplit(IniRead($g_BWSIni, 'Options', 'ClickModes', 'F,R,S,T,E'), ',') ; 'F,R,S,T,E' is default if ClickModes is missing from Setup.ini
	If StringLen($Num[$a]) > 1 Then; if custom selection (including saved user selection), reset "click mode" to recommended
		$g_Compilation='R'
	Else
		$g_Compilation=$ClickModes[$Num[$a]]
	EndIf
	IniWrite($g_UsrIni, 'Options', 'InstallType', $Num[$a])
	Return $Num[$a]
EndFunc    ;==>_Selection_GetCurrentInstallType

; ---------------------------------------------------------------------------------------------
; Open the homepage of the currently selected mod
; ---------------------------------------------------------------------------------------------
Func _Selection_OpenPage($p_String='Link')
	Local $i = GUICtrlRead($g_UI_Interact[4][1]); get the current selection
	Local $HP=IniRead($g_ModIni, $g_CentralArray[$i][0], $p_String, '')
	If $HP <> '' And $HP <> '-' Then
		If $p_String = 'Wiki' Then $HP='http://kerzenburg.baldurs-gate.eu/wiki/'&$HP
		ShellExecute($HP); open the homepage if it is nursed
	EndIf
EndFunc    ;==>_Selection_OpenHomePage

; ---------------------------------------------------------------------------------------------
; Visit the download link of the currently selected mod
; ---------------------------------------------------------------------------------------------
Func _Selection_Download_Manually($p_String='Down')
	Local $i = GUICtrlRead($g_UI_Interact[4][1]); get the current selection
	Local $Down=IniRead($g_ModIni, $g_CentralArray[$i][0], $p_String, '')
	If $Down <> '' Then		
		ShellExecute($Down); Open download link in default browser.
	EndIf
EndFunc    ;==>_Selection_Download_Manually

; ---------------------------------------------------------------------------------------------
; Convert the WeiDU.log into a two-dimensional array
; Sample: ~BG2FIXPACK/SETUP-BG2FIXPACK.TP2~ #3 #0 // BG2 Fixpack - Hauptteil reparieren
;     or: ~TP2_File~ #language_number #component_number
; ---------------------------------------------------------------------------------------------
Func _Selection_ReadWeidu($p_File)
	If StringRegExp($p_File, '\A\D:') Then
		If Not FileExists($p_File) Then Return -1
		$p_File=FileRead($p_File)
	Else
		If $p_File = '' Then $p_File = ClipGet()
		If Not StringRegExp($p_File, '\A(//|~)') Then Return -1
	EndIf
	Local $Section[5000][2]
	Local $Name, $Num, $Array=StringSplit(StringStripCR($p_File), @LF)
	If $Array[0] = 0 Then Return -1
	For $a=1 to $Array[0]
		If Not StringRegExp($Array[$a], '\A~') Then ContinueLoop
		$Name = StringRegExpReplace(StringRegExpReplace($Array[$a], '\A~|~.*\z', ''), '(?i)-{0,1}(setup)-{0,1}|\x2etp2.*\z|\A.*/', '')
		$Num = StringRegExp($Array[$a], '(?:\A~.+~ #[^#]+#)(\d+)', 1)
		If IsArray($Num) Then _IniWrite($Section, $Name, $Num[0])
	Next
	ReDim $Section[$Section[0][0]+1][2]
	Return $Section
EndFunc    ;==>_Selection_ReadWeidu

; ---------------------------------------------------------------------------------------------
; (Re)Color an item
; 0x1a8c14 lime = recommended / 0x000070 dark = standard / 0xe8901a = tactics / 0xad1414 light = expert, 0xad1414
; ---------------------------------------------------------------------------------------------
Func _Selection_SearchColorItem($p_Num, $p_Color)
	If $p_Color Then
		GUICtrlSetColor($p_Num, 0xff0000); paint the hit red
	Else
		If $g_CentralArray[$p_Num][6] <> '' Then
			If $g_CentralArray[$p_Num][2] = '-' And StringInStr($g_CentralArray[$p_Num][11], 'R') Then
				GUICtrlSetColor($p_Num, 0x1a8c14); repaint the item lime, since it's recommended
			ElseIf $g_CentralArray[$p_Num][2] = '-' And StringInStr($g_CentralArray[$p_Num][11], 'S') Then
				GUICtrlSetColor($p_Num, 0x000070); repaint the item darkblue, since it's standard
			ElseIf $g_CentralArray[$p_Num][2] = '-' And StringInStr($g_CentralArray[$p_Num][11], 'T') Then
				GUICtrlSetColor($p_Num, 0xe8901a); repaint the item rust, since it's tactics
			Else
				GUICtrlSetColor($p_Num, 0xad1414); repaint the item blue, since it's expert mod or a description
			EndIf
			If $g_CentralArray[$p_Num][2] = '-' And StringInStr($g_CentralArray[$p_Num][11], 'W') Then
				GUICtrlSetBkColor($p_Num, 0xffff99); highlight the item background in yellow, since it has a warning
			EndIf
		Else
			GUICtrlSetColor($p_Num, 0x000000); repaint the item black if it has no description
		EndIf
	EndIf
EndFunc   ;==>_Selection_SearchColorItem

; ---------------------------------------------------------------------------------------------
; Set the treeviews mod-selection (from contextmenu)
; ---------------------------------------------------------------------------------------------
Func _Selection_SearchMulti($p_Type, $p_Last)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Selection_Multi')
	_GUICtrlTreeView_BeginUpdate($g_UI_Handle[0])
	_Tree_ShowComponents('0')
	_Selection_SearchColorItem($g_Search[2], 0); reset the color of the last found single-search-item
	If $p_Last > $g_UI_Menu[0][2]-2 Then; reset the last found mass-search-items
		_Selection_SearchMultiSpecial($p_Last, 0)
	Else
		If IsNumber($p_Last) Then _Selection_SearchMultiGroup($p_Last, 0)
	EndIf
	If $p_Type > $g_UI_Menu[0][2]-2 Then
		_Selection_SearchMultiSpecial($p_Type, 1)
	Else
		If IsNumber($p_Type) Then _Selection_SearchMultiGroup($p_Type, 1)
	EndIf
	_GUICtrlTreeView_EndUpdate($g_UI_Handle[0])
EndFunc   ;==>_Selection_SearchMulti

; ---------------------------------------------------------------------------------------------
; Search for mods that belong to one chapter
; ---------------------------------------------------------------------------------------------
Func _Selection_SearchMultiGroup($p_Type, $p_Color)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Selection_SearchMultiGroup')
	Local $FirstModItem
	For $m = $g_CentralArray[0][1] To $g_CentralArray[0][0]
		If $g_CentralArray[$m][2] <> '-' Then ContinueLoop; no interrest in components
		If StringRegExp($g_CentralArray[$m][1], '(\A|,)'&$p_Type&'(\z|,)') Then
			If $FirstModItem = '' Then $FirstModItem = $g_CentralArray[$m][5]
			If $p_Color Then _GUICtrlTreeView_SetState($g_UI_Handle[0], $g_CentralArray[$m][5], $TVIS_EXPANDED); expand the theme-tree
			_Selection_SearchColorItem($m, $p_Color)
		EndIf
	Next
	If $p_Color Then _GUICtrlTreeView_SelectItem($g_UI_Handle[0], $FirstModItem, $TVGN_FIRSTVISIBLE)
EndFunc   ;==>_Selection_SearchMultiGroup

; ---------------------------------------------------------------------------------------------
; Search for special groups defined in the Game.ini
; ---------------------------------------------------------------------------------------------
Func _Selection_SearchMultiSpecial($p_Type, $p_Color)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Selection_SearchMultiSpecial')
	Local $FirstModItem
	Local $Num=$p_Type - ($g_UI_Menu[0][2]-2)
	For $c = $g_CentralArray[0][1] To $g_CentralArray[0][0]; loop through all mod-headlines and components
		If $g_CentralArray[$c][2] = '' Then ContinueLoop
		If $g_CentralArray[$c][2] <> '-' Then ContinueLoop
		If StringRegExp($g_Groups[$Num][1], '(?i)(\A|,)'&$g_CentralArray[$c][0]&'\x28') Then; is element selected?
			Local $Mod=StringRegExp($g_Groups[$Num][1], '(?i)'&$g_CentralArray[$c][0]&'[^\x29]*\x29', 3)
			If Not IsArray($Mod) Then ContinueLoop
			Local $Comp=StringRegExpReplace($Mod[0], '\A[^\x28]*', '')
			If $Comp = '(-)' Then
				If $FirstModItem = '' Then $FirstModItem = $g_CentralArray[$c][5]
				If $p_Color Then _GUICtrlTreeView_SetState($g_UI_Handle[0], $g_CentralArray[$g_CHTreeviewItem[$g_CentralArray[$c][1]]][5], $TVIS_EXPANDED); expand the theme-tree
				_Selection_SearchColorItem($c, $p_Color)
			Else
				Local $Current=$c
				$c+=1
				While $g_CentralArray[$c][2] <> '-'
					If StringRegExp($g_CentralArray[$c][2], '(?i)\A' & $Comp & '\z') Then
						If $FirstModItem = '' Then $FirstModItem = $g_CentralArray[$c][5]
						If $p_Color Then _GUICtrlTreeView_Expand($g_UI_Handle[0], $Current, True)
						_Selection_SearchColorItem($c, $p_Color)
					EndIf
					$c+=1
					If $c > $g_CentralArray[0][0] Then ExitLoop
				WEnd
				$c-=1
			EndIf
		EndIf
	Next
	If $p_Color Then _GUICtrlTreeView_SelectItem($g_UI_Handle[0], $FirstModItem, $TVGN_FIRSTVISIBLE)
EndFunc   ;==>_Selection_SearchMultiSpecial

; ---------------------------------------------------------------------------------------------
; Searches through the items in the treeview from Au3Select
; ---------------------------------------------------------------------------------------------
Func _Selection_SearchSingle($p_String, $p_Text)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Selection_SearchSingle')
	If $p_String = $p_Text Then Return; don't do anything on the search-hint
	If $g_Search[0] = 'T' Then
		_Selection_SearchMulti('', $g_Search[3])
		$g_Search[0] = 'S'
	EndIf
	Local $Mod
	If $g_Search[1] <> $p_String Then; if the last search is different from the new one
		$Mod = 1; search from first entry
	Else
		$Mod = $g_Search[2] + 1; search from the next entry
	EndIf
	If $g_Search[2] <> '' Then; if an item was found before
		If $g_CentralArray[$g_Search[2]][2] = '-' Then; if it's a headline skip to next mod (saves user some clicks, since both the >>mod name<< and the components are searched)
			While $g_CentralArray[$Mod][2] <> '-'
				$Mod = $Mod + 1
			WEnd
		EndIf
		_Selection_SearchColorItem($g_Search[2], 0); reset the color of the last search
	EndIf
	Local $Last = $g_CentralArray[0][0]
	Local $Run = 1
; ---------------------------------------------------------------------------------------------
; loop through the elements of the main-array. We make heavy usage of the main-array here. Now you know why it's that important. :)
; ---------------------------------------------------------------------------------------------
	For $m = $Mod To $Last; loop through the main-array
		If StringInStr($g_CentralArray[$m][3], $p_String) Or (StringInStr($g_CentralArray[$m][4], $p_String) And $g_CentralArray[$m][2] = '-') Or ($g_CentralArray[$m][0] = $p_String And $g_CentralArray[$m][2] = '-') Then
			If GUICtrlRead($m) = 0 Then ContinueLoop
			_GUICtrlTreeView_SelectItem($g_UI_Handle[0], $g_CentralArray[$m][5], $TVGN_FIRSTVISIBLE); focus the item
			_Selection_TipSetData($m)
			GUICtrlSetColor($m, 0xff0000); paint the item red
			$g_Search[2] = $m; remember the number of the element
			$g_Search[1] = $p_String; remember string searched for
			ExitLoop
		EndIf
		If $m = $g_CentralArray[0][0] And $Mod <> 1 Then; search from top to the current item if search hit the bottom and the current element is not the first one.
			$m = 1
			$Last = $Mod
			$Run = 2
		EndIf
		If $Run = 2 And $m = $Last Then ExitLoop
	Next
EndFunc   ;==>_Selection_SearchSingle

; ---------------------------------------------------------------------------------------------
; Switch help on / off on advanced tab
; ---------------------------------------------------------------------------------------------
Func _Selection_SetSize()
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Selection_SetSize')
	Local $Pos=ControlGetPos($g_UI[0], '', $g_UI_Interact[4][1])
	Local $State=GUICtrlGetState($g_UI_Interact[4][4])
	If BitAND($State, $GUI_HIDE) Then
		GUICtrlSetPos($g_UI_Interact[4][1], 15, 85, $Pos[2]-305, $Pos[3])
		GUICtrlSetPos($g_UI_Button[4][2], $Pos[2]-290, 85, 15, $Pos[3])
		GUICtrlSetState($g_UI_Interact[4][4], $GUI_SHOW)
		GUICtrlSetData($g_UI_Button[4][2], '>')
	Else
		GUICtrlSetPos($g_UI_Interact[4][1], 15, 85, $Pos[2]+305, $Pos[3])
		GUICtrlSetPos($g_UI_Button[4][2], $Pos[2]+320, 85, 15, $Pos[3])
		GUICtrlSetState($g_UI_Interact[4][4], $GUI_HIDE)
		GUICtrlSetData($g_UI_Button[4][2], '<')
	EndIf
EndFunc   ;==>_Selection_SetSize

; ---------------------------------------------------------------------------------------------
; Set the custom tooltip
; ---------------------------------------------------------------------------------------------
Func _Selection_TipSetData($p_Num)
	If $p_Num < $g_CentralArray[0][1] Then Return; make sure this does not crash the script after some tree-rebuilding
	If $p_Num > $g_CentralArray[0][0] Then Return
	Local $Dsc, $Num=StringSplit($g_CentralArray[$p_Num][1], ','); Translate numbers into something readable
	For $n=1 to $Num[0]
		If $Num[$n]+3 > $g_Tags[0][0] Then ContinueLoop; prevent crashes if tag/theme number exceeds valid range
		$Dsc &= ','&$g_Tags[$Num[$n]+3][1]
	Next
	$Dsc=StringTrimLeft($Dsc, 1)
	Local $Headline
	If $g_CentralArray[$p_Num][2] = '-' Then
		Local $SetupName=$g_CentralArray[$p_Num][0]
		Local $Rev=$g_CentralArray[$p_Num][15]
		Local $Size=$g_CentralArray[$p_Num][8]		
		Local $Lang=$g_CentralArray[$p_Num][8]
		$Headline = $Dsc&': '&$SetupName&' ('
		If StringRegExp($Rev, '\A\d') Then
			$Headline &= 'v'&$Rev&', '; revision/version starts with digit
		ElseIf $Rev Then;
			$Headline &= $Rev&', '; non-digit revision/version
		EndIf
		If $Size <> 0 Then
			$Headline &= Round($Size/(1024 * 1024), 1)&' MB, '
		EndIf
		$Headline &= $Lang&')'
	Else
		$Headline = $Dsc
	EndIf
	GUICtrlSetData($g_UI_Static[4][1], $Headline)
	GUICtrlSetData($g_UI_Interact[4][2], $g_CentralArray[$p_Num][6])
EndFunc   ;==>_Selection_TipSetData

; ---------------------------------------------------------------------------------------------
; Sets the tip-data for Au3Select
; ---------------------------------------------------------------------------------------------
Func _Selection_TipUpdate()
	Local $hItem = __TreeItemFromPoint($g_UI_Handle[0])
	If Not WinActive($g_UI[0]) Then; the mouse is not over the treeview
		$g_Flags[7] = ''; reset the old item to spawn again
		Return
	EndIf
	Local $i
	If $g_Flags[17] = 1 Then; label of a treeitem has been clicked
		$i=GUICtrlRead($g_UI_Interact[4][1])
		_Selection_TipSetData($i)
		$g_Flags[17] = 0
		$g_Flags[7] = $g_CentralArray[$i][5]
	Else; check for keyboard movement
		$i = GUICtrlRead($g_UI_Interact[4][1]); get the current selection
		If $g_CentralArray[$i][5] <> $g_Flags[7] Then; the itemhandle has changed
			_GUICtrlTreeView_DisplayRect($g_UI_Handle[0], $g_CentralArray[$i][5], True)
			_Selection_TipSetData($i)
			$g_Flags[7] = $g_CentralArray[$i][5]
		EndIf
	EndIf
EndFunc   ;==>_Selection_TipUpdate