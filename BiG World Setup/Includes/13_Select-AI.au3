#include-once
; ---------------------------------------------------------------------------------------------
; NOTES: Some things may not seem to be efficient. I had to rewrite this part so I wanted to keep functions simple and only a single one exists for a task.
; Definition - Mods: 0=setup ; 1=tag                ; 2=-        ; 3=-         ; 4=short mod-desc; 5=handle; 6=Ext. mod-desc ; 7=Size ; 8=Translation; 9=selected    ; 10=possible sel. ; 11=compilation; 12=install y/n; 13=add. ids (splitted mod); 14=shift icon-number; 15=version-number
; Definition - Comp: 0=setup ; 1=current sel. handel; 2=comp-num ; 3=comp-desc ; 4=short mod-desc; 5=handle; 6=Ext. comp-desc; 7=fixed; 8=Translation; 9=is-selected ; 10=has a subtree ; 11=compilation; 12=install y/n;                           ; 14=shift icon-number; 15=Pause y/n
; Definition - Sele: 0=setup ; 1=current sel. handel; 2=+        ;             ; 4=short mod-desc; 5=handle;                 ;        ; 8=Translation; 9=is-selected ; 10=is part of sub; 11=compilation; 12=install y/n;                           ; 14=shift icon-number; 15=Pause y/n
; Debug-Sample: ConsoleWrite($g_CentralArray[$p_Num][0] & ' ' & $g_CentralArray[$p_Num][1] & ' ' & $g_CentralArray[$p_Num][2] & ' ' & $g_CentralArray[$p_Num][3] &@CRLF)
; important: MUC-Headlines and SUB-Selections are all counted as possible selections, so 3 possible SUBs add up +3
; If [0][9]=[0][10], the tree is counted as completely selected
; Not used items from g_CentralArray: 1 - 4 - 6 - 7 - 8 - 15
; ---------------------------------------------------------------------------------------------

; ---------------------------------------------------------------------------------------------
; Report the select/deselect-status of all mod-items
; ---------------------------------------------------------------------------------------------
Func _AI_Debug($p_Num, $p_Type='-')
	Local $FirstModItem, $Num
	$p_Num = _AI_GetStart($p_Num, $p_Type)
	ConsoleWrite('>>>>>>>>>' & @HOUR &':'&@MIN &':'& @SEC& ' ==> ' &$p_Num& '>>>>>>>>>>' & @CRLF)
	ConsoleWrite($g_CentralArray[$p_Num][0] &  ' - ' & $g_CentralArray[$p_Num][2] & ': ' & $g_CentralArray[$p_Num][9] & @CRLF)
	Local $FirstModItem = $p_Num
	$p_Num +=1
	While $g_CentralArray[$p_Num][2] <> $p_Type; walk the tree while it's still underneath p_Type
		If $g_CentralArray[$p_Num][2] = '!' Then ExitLoop
		ConsoleWrite($g_CentralArray[$p_Num][0] &  ' - ' & $g_CentralArray[$p_Num][2] & ': ' & $g_CentralArray[$p_Num][9] & @CRLF)
		If $g_CentralArray[$p_Num][9] =1 Then $Num+=1
		$p_Num+=1
		If $p_Num > $g_CentralArray[0][0] Then ExitLoop
	WEnd
	If $g_CentralArray[$FirstModItem][9] = $Num Then
		ConsoleWrite('+')
	Else
		ConsoleWrite('!')
	EndIf
	;If $g_CentralArray[$FirstModItem][9] <> $Num Then MsgBox(0, 'Debug', 'Error')
	;If $g_CentralArray[$FirstModItem][9] > $g_CentralArray[$FirstModItem][10] Then MsgBox(0, 'Debug', 'Error')
	ConsoleWrite('Sum:'& $g_CentralArray[$FirstModItem][9] & '/'&$g_CentralArray[$FirstModItem][10]& ' Items:' & $Num & @CRLF)
	ConsoleWrite('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>' & @CRLF)
EndFunc    ;==>_AI_Debug

; ---------------------------------------------------------------------------------------------
; Return if the mod gets (not)(partially) installed
; ---------------------------------------------------------------------------------------------
Func _AI_GetModState($p_Num); $a=ControlID of the treeviewitem
	If $g_CentralArray[$p_Num][9] = 0 Then; none selected
		Return 0
	Else; some or all selected
		Return 1
	EndIf
EndFunc   ;==>_AI_GetModState

; ---------------------------------------------------------------------------------------------
; Detect if component is shown or not in current selection
; ---------------------------------------------------------------------------------------------
Func _AI_GetSelect($p_Num, $p_Type=0)
	Local $Num=0
	If $g_CentralArray[$p_Num][12] = '' Then Return 0
	Local $String = StringSplit($g_CentralArray[$p_Num][12], '');pre-selection bits, 0000 to 1111 (RSTE)
	If StringInStr($g_CentralArray[$p_Num][11], 'F') Then
		$Num=1
	ElseIf $g_Compilation = 'R' Then
		$Num=1
	ElseIf $g_Compilation = 'S' Then
		$Num=2
	ElseIf $g_Compilation = 'T' Then
		$Num=3
	ElseIf $g_Compilation = 'E' Then
		$Num=4
	EndIf
	If $p_Type = 0 Then Return $String[$Num]
	If $String[$Num]=1 Then Return 1
	For $n=$Num+1 to 4
		If $String[$n]=1 Then Return -$n
	Next
	Return 0
EndFunc    ;==>_AI_GetSelect

; ---------------------------------------------------------------------------------------------
; Get the mod or MUC-selection of the selected component
; ---------------------------------------------------------------------------------------------
Func _AI_GetStart($p_Num, $p_Type, $p_Next='-'); treeview-number, type, previous/next hit
	If $p_Next = '-' Then
		While Not StringInStr($g_CentralArray[$p_Num][2], $p_Type)
			$p_Num -= 1
			If $p_Num < $g_CentralArray[0][1] Then Return 0
		WEnd
	Else
		While Not StringInStr($g_CentralArray[$p_Num][2], $p_Type)
			$p_Num += 1
			If $p_Num > $g_CentralArray[0][0] Then Return 0
		WEnd
	EndIf
	Return $p_Num
EndFunc   ;==>_AI_GetStart

; ---------------------------------------------------------------------------------------------
; Set the type of the current component. [14] contains the number the std. image is shifted
; ---------------------------------------------------------------------------------------------
Func _AI_GetType()
	Local $MUCoverride
	For $t=$g_CentralArray[0][1] to $g_CentralArray[0][0]
		If $g_CentralArray[$t][0] = '' Then ContinueLoop; this keeps the BWS from crashing if some items were build between the (re)builds of the selection-screen and still lock some controlIDs
		If StringInStr($g_CentralArray[$t][11], 'F') Then
			$g_CentralArray[$t][14]=0
		ElseIf $g_CentralArray[$t][12]='' Then; these components are not selected >> use mods defaults
			If StringInStr($g_CentralArray[$t][11], 'R') Then
				$g_CentralArray[$t][14]=3
			ElseIf StringInStr($g_CentralArray[$t][11], 'S') Then
				$g_CentralArray[$t][14]=6
			ElseIf StringInStr($g_CentralArray[$t][11], 'T') Then
				$g_CentralArray[$t][14]=9
			ElseIf StringInStr($g_CentralArray[$t][11], 'E') Then
				$g_CentralArray[$t][14]=12
			Else
				ConsoleWrite('!'&$g_CentralArray[$t][11] & ' ' & $g_CentralArray[$t][12] & @CRLF); >> this should never happen, if it does: Edit Select.txt
			EndIf
			If $g_CentralArray[$t][10] = 1 And $MUCoverride > $g_CentralArray[$t][14] Then $g_CentralArray[$t][14] = $MUCoverride; avoid MUC-tree to be "lower" than its root
		Else
			Local $String = StringSplit($g_CentralArray[$t][12], ''); RSTE
			If $String[1]=1 Then; recommended or standard
				$g_CentralArray[$t][14]=3
			ElseIf $String[2]=1 Then
				$g_CentralArray[$t][14]=6
			ElseIf $String[3]=1 Then; tactic
				$g_CentralArray[$t][14]=9
			ElseIf $String[4]=1 Then; expert
				$g_CentralArray[$t][14]=12
			EndIf
		EndIf
		If StringInStr($g_CentralArray[$t][2], '+') Then $MUCoverride = $g_CentralArray[$t][14]; save override for MUC-items that are never selected
	Next
EndFunc    ;==>_AI_GetType

; ---------------------------------------------------------------------------------------------
; Checks if a mod will be installed in any version
; ---------------------------------------------------------------------------------------------
Func _AI_Installs($p_Num)
	$p_Num += 1
	While $g_CentralArray[$p_Num][2] <> '-'
		If StringInStr($g_CentralArray[$p_Num][12], 1) Then Return 1
		$p_Num +=1
		If $p_Num > $g_CentralArray[0][0] Then ExitLoop
	WEnd
	Return 0
EndFunc    ;==>_AI_Installs

; ---------------------------------------------------------------------------------------------
; Detect whether the item is in a subtree
; ---------------------------------------------------------------------------------------------
Func _AI_IsInSubtree($p_Num)
	If StringRegExp($g_CentralArray[$p_Num][2], '\x21|-') Then Return 0; chapters and mods are not good
	If StringInStr($g_CentralArray[$p_Num][2], '?') Then Return 2; enable changes in SUB
	If $g_CentralArray[$p_Num][10] = 1 Then Return 1; enable changes in MUC
	Return 0
EndFunc    ;==>_AI_IsInSubtree

; ---------------------------------------------------------------------------------------------
; Sets the checkboxes of the selection-gui. $a=guictrlhandle; $b=force state
; ---------------------------------------------------------------------------------------------
Func _AI_SetClicked($p_Num, $p_Type = 0, $p_Key=0); $a=itemnumber; $p_Type=0(toggle)/True(force checked)/False(force unchecked)
	Local $SetState, $ForceAll, $OldCompilation, $Compilation[5]=[4, 'R', 'S', 'T', 'E']
	If $p_Num < $g_CentralArray[0][1]-1 Or $p_Num > $g_CentralArray[0][0] Then Return; prevent crashes if $g_CentralArray is undefined
	$g_Flags[24]=1
	;_AI_Debug($p_Num); Debugging: Show selected-states of a mods components
; ---------------------------------------------------------------------------------------------
; it's the headline of a chapter
; ---------------------------------------------------------------------------------------------
	If $g_CentralArray[$p_Num][2] = '!' Then
		If $g_CentralArray[$p_Num][9] = 0 Then
			_Tree_SetSelectedGroup($g_CentralArray[$p_Num][1], 1)
		Else
			_Tree_SetSelectedGroup($g_CentralArray[$p_Num][1], 0)
		EndIf
		_AI_SetModStateIcon($p_Num); reset icon in case the action was canceled or limited
		Return
	EndIf
; ---------------------------------------------------------------------------------------------
; it's a fixed item
; ---------------------------------------------------------------------------------------------
	If StringInStr($g_CentralArray[$p_Num][11], 'F') Then; fixed items behave differently
		If StringInStr($g_CentralArray[$p_Num][2], '-') Then; just reset mod-icon
			_AI_SetModStateIcon($p_Num)
		ElseIf $g_CentralArray[$p_Num][10] = 1 Then; enable change of subtree-items
			If $g_CentralArray[$p_Num][9] = 1 Then; just reset icon if already enabled
				__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 2+$g_CentralArray[$p_Num][14])
			Else
				If StringInStr($g_CentralArray[$p_Num][2], '?') Then
					_AI_SetInSUB_Enable($p_Num)
				Else
					_AI_SetInMUC_Enable($p_Num)
				EndIf
			EndIf
		ElseIf StringInStr($g_CentralArray[$p_Num][2], '?') Then; enable change of subtree-parent
			_AI_SetSUB_Enable($p_Num)
		ElseIf $g_CentralArray[$p_Num][5] <> '' Then; reset icon
			__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 2+$g_CentralArray[$p_Num][14])
		EndIf
		;_AI_Debug($p_Num); Debugging: Show selected-states of a mods components
		Return; fixed item handling ends here
; ---------------------------------------------------------------------------------------------
; determine what's to be done otherwise
; ---------------------------------------------------------------------------------------------
	ElseIf $p_Type = 1 Then; forced state to True
		$SetState = 1
	ElseIf $p_Type = 2 Then ; forced state to False
		$SetState = 0
	Else
		If $g_CentralArray[$p_Num][2] = '-' Then
			$ForceAll = _IsPressed(10, $g_UDll); shift is pressed >> select or deselect every component
		EndIf
		If $g_CentralArray[$p_Num][9] = 0 Then
			$SetState = 1
		Else
			$SetState = 0
		EndIf
		;If $p_Key = 1 Then $SetState = Not $SetState (entering from Select-GUILoop with spacebar [not mouse click] triggered this .. why?)
	EndIf
; ---------------------------------------------------------------------------------------------
;  don't allow mod-components to be changed if restrictions are on and comp or type are not matched
; ---------------------------------------------------------------------------------------------
	Local $Request, $Test
	If $g_LimitedSelection = 0 And $SetState = 1 Then $Test= _AI_GetSelect($p_Num, 1)
	If $Test < 0 Then
		If $g_Flags[20] = 0 Then $Request = _Misc_MsgGUI(3, _GetTR($g_UI_Message, '0-T1'), _GetTR($g_UI_Message, '4-L7'), 3, _GetTR($g_UI_Message, '8-B4'), _GetTR($g_UI_Message, '8-B1'), _GetTR($g_UI_Message, '8-B2')); => select mods from other versions?
		If $g_Flags[20] = 1 Then $Request = 2
		If $Request = 3 Then $g_Flags[20] = 1
		If $Request = 1 Then; user does not want to add this
			$g_LimitedSelection = 1
		Else
			$OldCompilation=$g_Compilation
			$g_Compilation = $Compilation[-$Test]
		EndIf
	EndIf
	If $g_LimitedSelection = 1 Then
		If Not StringInStr($g_CentralArray[$p_Num][11], $g_Compilation) Then $SetState = -1
		If _AI_GetSelect($p_Num) = 0 Then $SetState = -1; type-definitions: standard = 1, extended = 0
		If $SetState = -1 Then; no changes to apply > reset icons
			If $g_CentralArray[$p_Num][9] = 0 Then
				__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 1+$g_CentralArray[$p_Num][14])
			Else
				__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 2+$g_CentralArray[$p_Num][14])
			EndIf
			If $Test < 0 Then $g_LimitedSelection = 0; reset value since it was set temporary
			Return
		EndIf
	EndIf
; ---------------------------------------------------------------------------------------------
; it's the headline of the mod
; ---------------------------------------------------------------------------------------------
	If $g_CentralArray[$p_Num][2] = '-' Then
		If $SetState = 0 Then
			_AI_SetMod_Disable($p_Num); No selection should have a name -, so all are deselected
		Else
			_AI_SetMod_Enable($p_Num, 2); Enable selections of mods that have no defaults
		EndIf
		If $ForceAll = 1 Then; force the state on all other instances of the mod
			If $g_CentralArray[$p_Num][13] <> '' Then
				$Splitted=StringSplit($g_CentralArray[$p_Num][13], ',')
				For $s=1 to $Splitted[0]
					If $SetState = 0 Then
						_AI_SetMod_Disable($Splitted[$s]); No selection should have a name -, so all are deselected
					Else
						_AI_SetMod_Enable($Splitted[$s]); Enable selections of mods that have no defaults
					EndIf
				Next
			EndIf
		EndIf
; ---------------------------------------------------------------------------------------------
; it's a subtree of a multiple choice-component
; ---------------------------------------------------------------------------------------------
	ElseIf $g_CentralArray[$p_Num][2] = '+' Then
		If $SetState = 0 Then
			_AI_SetMUC_Disable($p_Num)
		Else
			_AI_SetMUC_Enable($p_Num)
		EndIf
; ---------------------------------------------------------------------------------------------
; it's a component of a SUB subtree
; ---------------------------------------------------------------------------------------------
	ElseIf StringInStr($g_CentralArray[$p_Num][2], '?') Then
		If $SetState = 0 Then
			_AI_SetInSUB_Disable($p_Num)
		Else
			_AI_SetInSUB_Enable($p_Num)
		EndIf
; ---------------------------------------------------------------------------------------------
; it's a component of a MUC subtree
; ---------------------------------------------------------------------------------------------
	ElseIf $g_CentralArray[$p_Num][10] = 1 Then
		If $SetState = 0 Then
			_AI_SetInMUC_Disable($p_Num)
		Else
			_AI_SetInMUC_Enable($p_Num)
		EndIf
	ElseIf $g_CentralArray[$p_Num][10] = 2 Then
		If $SetState = 0 Then
			_AI_SetSUB_Disable($p_Num)
		Else
			_AI_SetSUB_Enable($p_Num)
		EndIf
; ---------------------------------------------------------------------------------------------
; it's a component (optional SUBs are handled)
; ---------------------------------------------------------------------------------------------
	ElseIf $g_CentralArray[$p_Num][5] <> '' Then
		If $SetState = 0 Then
			_AI_SetSTD_Disable($p_Num)
		Else
			_AI_SetSTD_Enable($p_Num)
		EndIf
	EndIf
	If $Test < 0 Then
		$g_Compilation = $OldCompilation
		If $g_Flags[20] = 1 Then; give visual feedback if mod did not fit and question was suppressed
			GUICtrlSetBkColor($g_UI_Interact[4][2], 0xff8800)
			GUICtrlSetFont($g_UI_Interact[4][2], 32, 800, 0, "MS Sans Serif")
			GUICtrlSetData($g_UI_Interact[4][2], _GetTR($g_UI_Message, '0-T1')); => warning
			Sleep(200)
			GUICtrlSetFont($g_UI_Interact[4][2], 8, 400, 0, "MS Sans Serif")
			GUICtrlSetBkColor($g_UI_Interact[4][2], 0xffffff)
		EndIf
	EndIf
	;_AI_Debug($p_Num); Debugging: Show selected-states of a mods components
EndFunc   ;==>_AI_SetClicked

; ---------------------------------------------------------------------------------------------
; If the number of selectable components are selected, set a different color for the mods headline [Got (to be) ALWAYS CALLED!!!] ..._AI_SetMod_Disable
; ---------------------------------------------------------------------------------------------
Func _AI_SetModStateIcon($p_Num, $p_First = '-'); $p_Num=TVitemID; $p_First=first state before
	Local $Now, $ChapterID=_AI_GetStart($p_Num, '!')
	If $g_CentralArray[$p_Num][10] = $g_CentralArray[$p_Num][9] Then; all selected
		__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 2+$g_CentralArray[$p_Num][14])
		$Now=1
	ElseIf $g_CentralArray[$p_Num][9] > 0 Then; some selected
		__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 3+$g_CentralArray[$p_Num][14])
		$Now=1
	Else; none selected
		__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 1+$g_CentralArray[$p_Num][14])
		$Now=0
	EndIf
	If $p_First == '-' Then Return; no intention to adjust chapter-icons
	If $p_First > 0 Then $p_First = 1
	If $p_First = $Now Then Return; no need to do chapter-updates
	; do chapter icon update
	Local $Num = $g_CHTreeviewItem[$g_CentralArray[$p_Num][1]]; this is the ControlID of the chapter
	If $p_First = 1 Then; old State was selected, now deselected
		$g_CentralArray[$Num][9]-=1; decrease counter
	Else
		$g_CentralArray[$Num][9]+=1; increase counter
	EndIf
	If $g_CentralArray[$Num][9] = 0 Then; none selected
		__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$Num][5], 1)
	ElseIf $g_CentralArray[$Num][10] = $g_CentralArray[$Num][9] Then; all selected
		__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$Num][5], 2)
	Else; some selected
		__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$Num][5], 3)
	EndIf
EndFunc   ;==>_AI_SetModStateIcon

; ---------------------------------------------------------------------------------------------
; Select the components included in the pre-selection that matches the current 'click-setting'
; ---------------------------------------------------------------------------------------------
Func _AI_SetDefaults()
	;_PrintDebug('+' & @ScriptLineNumber & ' Calling _AI_SetDefaults')
	For $a=1 to $g_CentralArray[0][0]
		If $g_CentralArray[$a][2] = '!' Then; theme/chapter heading
			$g_CentralArray[$a][9] = 0; reset theme counter
			__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$a][5], 1)
			ContinueLoop
		ElseIf $g_CentralArray[$a][2] <> '-' Then; if it is a component
			ContinueLoop
		EndIf
		$g_CentralArray[$a][9] = 0; reset the component counter
		_AI_SetMod_Enable($a, 1)
	Next
EndFunc   ;==>_AI_SetDefaults

; ---------------------------------------------------------------------------------------------
; Disable a MUC-component. The MUCtree, too. Start wit a MUC-component.
; ---------------------------------------------------------------------------------------------
Func _AI_SetInMUC_Disable($p_Num, $p_First=0)
	;_PrintDebug('+' & @ScriptLineNumber & ' Calling _AI_SetInMUC_Disable')
	If $p_First = 0 Then $p_First = _AI_GetStart($p_Num, '-')
	While $g_CentralArray[$p_Num][2] <> '+'; get the item with the MUCtree
		$p_Num -= 1
		If $p_Num < $g_CentralArray[0][1] Then ExitLoop
	WEnd
	_AI_SetMUC_Disable($p_Num, $p_First)
EndFunc    ;==>_AI_SetInMUC_Disable

; ---------------------------------------------------------------------------------------------
; Enable a MUC-component. Disable others. Enable MUCtree if needed. Start with a MUC-component.
; ---------------------------------------------------------------------------------------------
Func _AI_SetInMUC_Enable($p_Num, $p_First = 0)
	;_PrintDebug('+' & @ScriptLineNumber & ' Calling _AI_SetInMUC_Enable')
	Local $ChapterID=_AI_GetStart($p_Num, '!')
	If $p_First = 0 Then $p_First = _AI_GetStart($p_Num, '-')
	Local $FirstIconState=_AI_GetModState($p_First)
	Local $Current=$p_Num
	While $g_CentralArray[$p_Num][2] <> '+'; get the item with the MUCtree
		$p_Num -= 1
		If $p_Num < $g_CentralArray[0][1] Then ExitLoop
	WEnd
	If $g_CentralArray[$p_Num][9] = 1 Then _AI_SetMUC_Disable($p_Num, $p_First); disable complete MUC-tree if active
	$FirstIconState=_AI_GetModState($p_First)
	__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 2+$g_CentralArray[$Current][14]); set MUC-rootitem to MUC-treeitem-color
	$g_CentralArray[$p_First][9] +=2; MUC _always_ have two selections: MUCtree and MUCcomponent
	$g_CentralArray[$p_Num][9] = 1
	__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$Current][5], 2+$g_CentralArray[$Current][14])
	$g_CentralArray[$Current][9] = 1
	_AI_SetModStateIcon($p_First, $FirstIconState); update mod state after it was possibly altered by
EndFunc    ;==>_AI_SetInMUC_Enable

; ---------------------------------------------------------------------------------------------
; Disabling a SUB-Component results in diabled component and SUBs. Start with a SUB.
; ---------------------------------------------------------------------------------------------
Func _AI_SetInSUB_Disable($p_Num, $p_First=0)
	;_PrintDebug('+' & @ScriptLineNumber & ' Calling _AI_SetInSUB_Disable')
	If $p_First = 0 Then $p_First = _AI_GetStart($p_Num, '-')
	If $g_Flags[4] = 0 Then; tell them that this won't work
		_Misc_MsgGUI(3, _GetTR($g_UI_Message, '0-T1'), $g_CentralArray[$p_Num][4]&' ('&$g_CentralArray[$p_Num][3]&')'&@CRLF&@CRLF&_GetTR($g_UI_Message, '4-L5'), 1); => cannot remove SUBs, will remove component
		$g_Flags[4] = 1
	EndIf
	While $g_CentralArray[$p_Num][10] <> 2; get the item with the SUBs
		$p_Num -= 1
	WEnd
	_AI_SetSUB_Disable($p_Num, $p_First)
EndFunc    ;==>_AI_SetInSUB_Disable

; ---------------------------------------------------------------------------------------------
; Enabling a SUB-Component results in enabled component and disabling other SUBs. Start with a SUB.
; ---------------------------------------------------------------------------------------------
Func _AI_SetInSUB_Enable($p_Num, $p_First=0)
	;_PrintDebug('+' & @ScriptLineNumber & ' Calling _AI_SetInSUB_Enable')
	If $p_First = 0 Then $p_First = _AI_GetStart($p_Num, '-')
	Local $FirstIconState=_AI_GetModState($p_First)
	Local $Current=$p_Num
	Local $Component=StringRegExpReplace($g_CentralArray[$Current][2], '\x5f.*', ''); x5f = '_' (unicode low line); strip answer, keep 'comp-num?sub-comp-num' part
	While $g_CentralArray[$p_Num][10] <> 2; get the item with the SUBs
		$p_Num -= 1
	WEnd
	If $g_CentralArray[$p_Num][9] = 0 Then _AI_SetSUB_Enable($p_Num, $p_First); enable other SUB-root-item if needed
	$p_Num+=1
	While $g_CentralArray[$p_Num][10] = 1; disable the other SUB items
		If StringInStr($g_CentralArray[$p_Num][2], $Component) And $g_CentralArray[$p_Num][9] = 1 Then
			__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 1+$g_CentralArray[$p_Num][14])
			$g_CentralArray[$p_Num][9] = 0
		EndIf
		$p_Num+=1
		If $p_Num > $g_CentralArray[0][0] Then ExitLoop
	WEnd
	__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$Current][5], 2+$g_CentralArray[$Current][14]); enable clicked SUB-item
	$g_CentralArray[$Current][9] = 1
	_AI_SetModStateIcon($p_First, $FirstIconState)
EndFunc    ;==>_AI_SetInSUB_Enable

; ---------------------------------------------------------------------------------------------
; Disable a whole mod
; ---------------------------------------------------------------------------------------------
Func _AI_SetMod_Disable($p_Num)
	;_PrintDebug('+' & @ScriptLineNumber & ' Calling _AI_SetMod_Disable')
	Local $FirstModItem=$p_Num
	Local $FirstIconState=_AI_GetModState($FirstModItem)
	$g_CentralArray[$p_Num][9] = 0
	$p_Num +=1
	While StringRegExp($g_CentralArray[$p_Num][2], '-|!') = 0
		If $g_CentralArray[$p_Num][9] = 1 Then __TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 1+$g_CentralArray[$p_Num][14])
		$g_CentralArray[$p_Num][9] = 0
		$p_Num +=1
		If $p_Num > $g_CentralArray[0][0] Then ExitLoop
	WEnd
	_AI_SetModStateIcon($FirstModItem, $FirstIconState)
EndFunc    ;==>_AI_SetMod_Disable

; ---------------------------------------------------------------------------------------------
; Enable a whole mod
; ---------------------------------------------------------------------------------------------
Func _AI_SetMod_Enable($p_Num, $p_Force=0)
	If Not $p_Force = 1 Then _PrintDebug('+' & @ScriptLineNumber & ' Calling _AI_SetMod_Enable')
	Local $FirstModItem=$p_Num, $Selected=0, $ForcedInstall=0
	Local $FirstIconState=_AI_GetModState($FirstModItem)
	$p_Num +=1
	If $p_Force = 2 Then
		If _AI_Installs($FirstModItem) = 0 Then $ForcedInstall = 1
	EndIf
	If $ForcedInstall Then
		If $FirstIconState = 0 Then ConsoleWrite($FirstIconState & @CRLF)
		While StringRegExp($g_CentralArray[$p_Num][2], '-|!') = 0
			If $g_CentralArray[$p_Num][2] = '+' Then; MUC
				_AI_SetMUC_Enable($p_Num, $FirstModItem, 1)
				$p_Num +=1
				While $g_CentralArray[$p_Num][10] = 1; skip MUC lines below root
					$p_Num +=1
					If $p_Num > $g_CentralArray[0][0] Then ExitLoop
				WEnd
			ElseIf $g_CentralArray[$p_Num][10] = 2 Then; SUB
				_AI_SetSUB_Enable($p_Num, $FirstModItem, 1)
				Local $Component = StringRegExpReplace($g_CentralArray[$p_Num][2], '\x3f.*\z', ''); save component number to match SUB lines below
				$p_Num +=1
				While StringRegExp($g_CentralArray[$p_Num][2], '(?i)\A'&$Component&'\x3f'); skip SUB lines for component
					$p_Num +=1
					If $p_Num > $g_CentralArray[0][0] Then ExitLoop
				WEnd
			Else; STD
				_AI_SetSTD_Enable($p_Num, $FirstModItem)
				$p_Num +=1
			EndIf
			If $p_Num > $g_CentralArray[0][0] Then ExitLoop
		WEnd
		; disable the annoying pop-up when activating a mod with no pre-selected components
		;_Misc_MsgGUI(1, _GetTR($g_UI_Message, '0-B3'), _GetTR($g_UI_Message, '4-L14')); => no versions found, so mod was installed completely
	Else
		While StringRegExp($g_CentralArray[$p_Num][2], '-|!') = 0
			If _AI_GetSelect($p_Num) = 1 Then
				If $g_CentralArray[$p_Num][9] = 0 Then __TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 2+$g_CentralArray[$p_Num][14])
				$g_CentralArray[$p_Num][9] = 1
				$Selected+=1
			Else
				If $g_CentralArray[$p_Num][9] = 1 Then __TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 1+$g_CentralArray[$p_Num][14])
				If $p_Force=1 And $g_CentralArray[$p_Num][9] = 0 Then __TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 1+$g_CentralArray[$p_Num][14])
				$g_CentralArray[$p_Num][9] = 0
			EndIf
			$p_Num +=1
			If $p_Num > $g_CentralArray[0][0] Then ExitLoop
		WEnd
		$g_CentralArray[$FirstModItem][9] = $Selected
		_AI_SetModStateIcon($FirstModItem, $FirstIconState)
	EndIf
EndFunc    ;==>_AI_SetMod_Enable

; ---------------------------------------------------------------------------------------------
; Disable a MUC-Headline. Start with the subtree-headline.
; ---------------------------------------------------------------------------------------------
Func _AI_SetMUC_Disable($p_Num, $p_First=0)
	;_PrintDebug('+' & @ScriptLineNumber & ' Calling _AI_SetMUC_Disable')
	Local $ChapterID=_AI_GetStart($p_Num, '!')
	If $p_First = 0 Then $p_First = _AI_GetStart($p_Num, '-')
	Local $FirstIconState=_AI_GetModState($p_First)
	If $g_CentralArray[$p_Num][9] = 1 Then; this is the first MUC-selection -- increase counters
		__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 1+$g_CentralArray[$p_Num][14])
		$g_CentralArray[$p_Num][9] = 0
		$g_CentralArray[$p_First][9] -= 2; one selected MUC-tree _always_ has the subtree-headline and one selected comp
	EndIf
	$p_Num +=1
	While $g_CentralArray[$p_Num][10] = 1 And StringRegExp($g_CentralArray[$p_Num][2], '-|!') = 0 ; remove all items from the tree
		__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 1+$g_CentralArray[$p_Num][14])
		$g_CentralArray[$p_Num][9] = 0
		$p_Num +=1
		If $p_Num > $g_CentralArray[0][0] Then ExitLoop
	WEnd
	_AI_SetModStateIcon($p_First, $FirstIconState)
EndFunc    ;==>_AI_SetMUC_Disable

; ---------------------------------------------------------------------------------------------
; Enable a MUC-Headline. Start with the subtree-headline.
; ---------------------------------------------------------------------------------------------
Func _AI_SetMUC_Enable($p_Num, $p_First=0, $p_Silent=1)
	;_PrintDebug('+' & @ScriptLineNumber & ' Calling _AI_SetMUC_Enable')
	Local $ChapterID=_AI_GetStart($p_Num, '!')
	If $p_First = 0 Then $p_First = _AI_GetStart($p_Num, '-')
	Local $FirstIconState=_AI_GetModState($p_First)
	__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 2+$g_CentralArray[$p_Num][14]); enable the subtree itself
	$g_CentralArray[$p_Num][9] = 1
	$g_CentralArray[$p_First][9] += 2; one selected MUC-tree _always_ has the subtree-headline and one selected comp
	If _AI_GetSelect($p_Num) = 0 Then; just select the first item is no defaults are found
		__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num+1][5], 2+$g_CentralArray[$p_Num][14])
		$g_CentralArray[$p_Num+1][9] = 1
		If $p_Silent = 0 Then _Misc_MsgGUI(1, _GetTR($g_UI_Message, '0-B3'), _GetTR($g_UI_Message, '4-L15')); => no versions found, so MUC was installed completely
	Else
		$p_Num +=1
		While $g_CentralArray[$p_Num][10] = 1 And StringRegExp($g_CentralArray[$p_Num][2], '-|!') = 0; get defaults for the tree
			If _AI_GetSelect($p_Num) = 1 Then
				__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 2+$g_CentralArray[$p_Num][14])
				$g_CentralArray[$p_Num][9] = 1
			EndIf
			$p_Num +=1
			If $p_Num > $g_CentralArray[0][0] Then ExitLoop
		WEnd
	EndIf
	_AI_SetModStateIcon($p_First, $FirstIconState)
EndFunc    ;==>_AI_SetMUC_Enable

; ---------------------------------------------------------------------------------------------
; Disable a STD-Component. Do SUBs if needed.
; ---------------------------------------------------------------------------------------------
Func _AI_SetSTD_Disable($p_Num, $p_First=0)
	;_PrintDebug('+' & @ScriptLineNumber & ' Calling _AI_SetSTD_Disable')
	If $p_First = 0 Then $p_First=_AI_GetStart($p_Num, '-')
	Local $FirstIconState=_AI_GetModState($p_First)
	$g_CentralArray[$p_Num][9] = 0
	__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 1 +$g_CentralArray[$p_Num][14])
	$g_CentralArray[$p_First][9] -= 1
	_AI_SetModStateIcon($p_First, $FirstIconState)
EndFunc    ;==>_AI_SetSTD_Disable

; ---------------------------------------------------------------------------------------------
; Enable a Std-Component. Do SUBs if needed.
; ---------------------------------------------------------------------------------------------
Func _AI_SetSTD_Enable($p_Num, $p_First=0)
	;_PrintDebug('+' & @ScriptLineNumber & ' Calling _AI_SetSTD_Enable')
	If $p_First = 0 Then $p_First=_AI_GetStart($p_Num, '-')
	Local $FirstIconState=_AI_GetModState($p_First)
	$g_CentralArray[$p_Num][9] = 1
	__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 2 +$g_CentralArray[$p_Num][14])
	$g_CentralArray[$p_First][9] += 1
	_AI_SetModStateIcon($p_First, $FirstIconState)
EndFunc    ;==>_AI_SetSTD_Enable

; ---------------------------------------------------------------------------------------------
; Disable SUB-Components. Start with a component.
; ---------------------------------------------------------------------------------------------
Func _AI_SetSUB_Disable($p_Num, $p_First=0)
	;_PrintDebug('+' & @ScriptLineNumber & ' Calling _AI_SetSUB_Disable')
	If $p_First = 0 Then $p_First=_AI_GetStart($p_Num, '-')
	Local $FirstIconState=_AI_GetModState($p_First)
	$g_CentralArray[$p_Num][9] = 0
	__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 1 +$g_CentralArray[$p_Num][14])
	$g_CentralArray[$p_First][9] -= 1
	Local $Component = StringRegExpReplace($g_CentralArray[$p_Num][2], '\x3f.*\z', ''); save component number to match SUB lines below
	$p_Num +=1
	While StringRegExp($g_CentralArray[$p_Num][2], '(?i)\A'&$Component&'\x3f')
		__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 1+$g_CentralArray[$p_Num][14])
		If $g_CentralArray[$p_Num][9] = 1 Then $g_CentralArray[$p_First][9]-=1
		$g_CentralArray[$p_Num][9] = 0
		$p_Num +=1
		If $p_Num > $g_CentralArray[0][0] Then ExitLoop
	WEnd
	_AI_SetModStateIcon($p_First, $FirstIconState)
EndFunc    ;==>_AI_SetSUB_Disable

; ---------------------------------------------------------------------------------------------
; Enable a SUB-Component. Start with a component.
; ---------------------------------------------------------------------------------------------
Func _AI_SetSUB_Enable($p_Num, $p_First=0, $p_Silent=1)
	;_PrintDebug('+' & @ScriptLineNumber & ' Calling _AI_SetSUB_Enable')
	Local $CurrentSub=''
	If $p_First = 0 Then $p_First=_AI_GetStart($p_Num, '-')
	Local $FirstIconState=_AI_GetModState($p_First)
	If $g_CentralArray[$p_Num][9] = 0 Then ; enable the component if not already enabled
		__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 2+$g_CentralArray[$p_Num][14])
		$g_CentralArray[$p_Num][9] = 1
		$g_CentralArray[$p_First][9] += 1
	EndIf
	Local $Component=StringRegExpReplace($g_CentralArray[$p_Num][2], '\x3f.*\z', '') ; x3f = '?' (question mark); strip '?...' keep 'comp-num' only
	If _AI_GetSelect($p_Num) = 0 Then ; nothing can be selected
		$p_Num += 1
		While StringRegExp($g_CentralArray[$p_Num][2], '(?i)\A'&$Component&'\x3f')
			Local $Test=StringRegExpReplace($g_CentralArray[$p_Num][2], '\A.*\x3f|\x5f.*\z', '') ; x3f = '?' (question mark), x5f = '_' (unicode low line)
			If $CurrentSub <> $Test Then
				If $g_CentralArray[$p_Num][9] = 0 Then; enable sub-component if not already enabled
					__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 2+$g_CentralArray[$p_Num][14])
					$g_CentralArray[$p_Num][9] = 1
					$g_CentralArray[$p_First][9] += 1
				EndIf
				$CurrentSub=$Test
			EndIf
			$p_Num += 1
			If $p_Num > $g_CentralArray[0][0] Then ExitLoop
		WEnd
		If $p_Silent = 0 Then _Misc_MsgGUI(1, _GetTR($g_UI_Message, '0-B3'), _GetTR($g_UI_Message, '4-L15')); => no versions found, so SUB was installed completely
	Else
		$p_Num += 1
		While StringRegExp($g_CentralArray[$p_Num][2], '(?i)\A'&$Component&'\x3f')
			If _AI_GetSelect($p_Num) = 1 Then
				If $g_CentralArray[$p_Num][9] = 0 Then ; enable sub-component if not already enabled
					__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$p_Num][5], 2+$g_CentralArray[$p_Num][14])
					$g_CentralArray[$p_Num][9] = 1
					$g_CentralArray[$p_First][9] += 1
				EndIf
			EndIf
			$p_Num += 1
			If $p_Num > $g_CentralArray[0][0] Then ExitLoop
		WEnd
	EndIf
	_AI_SetModStateIcon($p_First, $FirstIconState)
EndFunc    ;==>_AI_SetSUB_Enable

Func _AI_SwitchComp($p_Num, $p_Force=0)
	Local $Compilation[6]=[5, 'R', 'S', 'T', 'E', 'F']
	For $m=1 to 5
		If $m = $p_Num Then
			GUICtrlSetState($g_UI_Menu[1][$m+6], $GUI_CHECKED)
			If $p_Force = 1 Then $g_Compilation = $Compilation[$m]
		Else
			GUICtrlSetState($g_UI_Menu[1][$m+6], $GUI_UNCHECKED)
		EndIf
	Next
EndFunc    ;==>_AI_SwitchComp