#include-once

; Note that you have to edit the functions when doing changes:
; _Depend_AutoSolve => solve problems right from start or in the dependency/connections-screen
; _Depend_Contextmenu => start solving the problems in the dependency/connections-screen
; _Depend_GetActiveConnections => build the list for the dependency/connections-screen after the selection

; _Depend_GetUnsolved => list mods that cannot be installed due to missing mods during download, extraction and installation
; _Depend_ListInstallConflicts => list mods that have conflicts during download, extraction and installation
; _Depend_ListInstallUnsolved => list mods that have open dependencies during download, extraction and installation

; Not used items from g_CentralArray: 5 - 6 - 7 - 8 - 11 - 12 - 14 - 15

;~ $g_CentralArray is an array of all mods/components from Select.txt, with the following fields:
;     0: setup-name
;     2: '-' for the root (top level) of a mod branch, '+' for the root of a multiple choice menu
;     3: component description (if 2 is '-' then this also will be '-')
;     4: name of the mod (from modname.ini)
;     9: number of active components (0 or 1 for a component; can be > 1 for a mod branch)
;      : theme/category number (ex. NPCs, items, tweaks)
;    13: blank '' or comma separated list of sections if mod is installed in different places

;~ $g_Connections is an array of rules entries (from Game.ini), with the following fields:
;    0: inikey (rule text from before the = )
;    1: inivalue (the rule, like C:A(-):B(-))
;    2: converted sentence (A is preferred to B)
;    3: the rule with mod names and components replaced with IDs (C:123|456&789&101|202:645&8910)
;         if user ignores this rule (via right-click menu), BWS will prefix this value with 'W'
;    4: 0/1 - is the rule a CW: or DW: warning (ignorable by the user)?

;~ $g_ActiveConnections is an array of mod/component entries, with the following fields:
;    0: connection type ('C', 'DS', 'DO', 'DM')
;          C = this mod/component conflicts with all other mods/components in the array that have the same rule ID
;         DS = this mod/component is active and "in need" of mods/components that are not active
;         DO = this mod/component is inactive and "needed" but is OPTIONAL to satisfy the rule (has alternatives)
;         DM = this mod/component is inactive and "needed" and is MANDATORY to satisfy the rule (no alternatives)
;    1: rule ID (index to the associated rule for this connection in $g_Connections)
;    2: control ID (index to the specific mod/component in $g_CentralArray for toggling status)
;    3: group ID (blank '' unless the mod/component is listed in the '[Groups]' section of Game.ini)
;    4: and-group (zero if rule does not contain '&', else each side of '&' is a non-zero 'and-group')
;
;    this array is only for mods/components involved in rules with unsolved conflicts or missing dependencies
;        connections for the same rule should be sequential in the array, "in need" followed by "needed"
;        connections from rules that have been right-click ignored by user will not be added to this array
;      mods/components that are "needed" (can satisfy missing dependencies) will be added only if they are INACTIVE
;      mods/components that are "in need" (have missing dependencies) will be added only if they are ACTIVE
;      mods/components that are in conflict with other mods in the rule will be added only if they are ACTIVE
;    note: the same mod/component can be added to the array multiple times if it is involved in more than one rule
;         - or (error case) if the same mod/component is on both sides of the rule - D:a(-):a(-) or C:b(-):b(-)

; ---------------------------------------------------------------------------------------------
; Automatically solve dependencies and conflicts of provided type (used before and after selection)
;  p_Type = which type of connection to change (see comments above for $g_ActiveConnections)
;    C = change mods/components that conflict with the one that appears first in the list
;    DS = change mods/components that are active and have missing dependencies
;    DO = change first mod/component that can satisfy 
;  p_State = what to do with mods/components of specified type (1 = activate, 2 = deactivate)
;  p_skipWarnings = whether or not to skip user-ignorable rules (1 = skip, 0 = don't)
;  Return value will be an array with five fields:
;    Return[0][0] will be the number of changes made by this function
;    Return[N][0] will be the setup-name of a mod/component whose status this function changed
;    Return[N][1] will be the setup-name of a mod/component whose status this function changed
;    Return[N][2] will be the description of a component whose status this function changed
;    Return[N][3] will be the mod-name of a mod/component whose status this function changed
; ---------------------------------------------------------------------------------------------
Func _Depend_AutoSolve($p_Type, $p_State, $p_skipWarnings = 1)
	Local $RuleID, $GroupID, $and_Group, $Return[9999][4]
	While 1
		$Restart=0
		$Progress=Round((($g_Flags[23]-$g_ActiveConnections[0][0])*100)/$g_Flags[23], 0)
		GUICtrlSetData($g_UI_Interact[9][1], $Progress); update progress bar
		GUICtrlSetData($g_UI_Static[9][2], $Progress &  ' %'); update progress text
		For $a=1 to $g_ActiveConnections[0][0]; for each active connection (representing a particular active mod/component)
			If $g_ActiveConnections[$a][0] <> $p_Type Then ContinueLoop; if the connection isn't the type we are looking for, skip it
			If $p_skipWarnings And $g_Connections[$RuleID][4] = 1 Then ContinueLoop; optionally, also skip if the rule is user-ignorable
			$RuleID=$g_ActiveConnections[$a][1]; else, save the current connection's associated rule ID (index to $g_Connections)
			$GroupID=$g_ActiveConnections[$a][3]; save the current connection's associated 'group' ID (groups can be enabled/disabled together)
			$and_Group=$g_ActiveConnections[$a][4]; save the current connection's 'and-group' number (zero unless the rule contains '&')
			If $p_Type <> 'C' Then $a-=1; if we are NOT looking for conflicts, back-step so the inner loop starts from the current mod/component
			While 1; iterate over all mods/components after 'saved' one (we've already checked the mods/components before 'saved')
				$a+=1; advance inner loop
				If $a > $g_ActiveConnections[0][0] Then ExitLoop ; we reached the end of the inner loop (compared 'saved' to all of its connections)
				If $GroupID <> '' And $GroupID=$g_ActiveConnections[$a][3] Then ContinueLoop; go to next if 'saved' and 'this' belong to same 'group'
				If $p_Type <> $g_ActiveConnections[$a][0] Then ContinueLoop; ignore connections of different types than the one are looking for
				If $RuleID <> $g_ActiveConnections[$a][1] Then; if the saved rule ID doesn't match the rule ID of 'this' connection
					$a-=1; we passed the last of the connections for the current rule - go back so outer loop (which steps +1) starts at next connection
					ExitLoop; stop the inner loop - we are done scanning connections for the current mod/component
				EndIf
				; if we reached this point, we found a connection for the 'saved' rule that has the type we want
				If Not _Depend_SetModState($g_ActiveConnections[$a][2], $p_State) then ExitLoop; activate or deactivate the mod/component
				; if we were unable to make a change, just keep going through other active connections (give up on automatically solving this one)
				$Return[0][0]+=1; else, the change succeeded -> record the change we just made
				$Return[$Return[0][0]][0]=$g_CentralArray[$g_ActiveConnections[$a][2]][0]; record setup-name
				$Return[$Return[0][0]][2]=$g_CentralArray[$g_ActiveConnections[$a][2]][4]; record mod name
				If $g_CentralArray[$g_ActiveConnections[$a][2]][2] <> '-' Then
					$Return[$Return[0][0]][1]=$g_CentralArray[$g_ActiveConnections[$a][2]][2]; record component type (MUC +, SUB ?)
					$Return[$Return[0][0]][3]=$g_CentralArray[$g_ActiveConnections[$a][2]][3]; record component description
				EndIf
				$Restart=1; we made a change, so we will need to rebuild $g_ActiveConnections after we finish the inner loop
				If $p_Type = 'DO' Then
					If $and_Group = 0 Then ExitLoop; only one of the possible dependencies is needed, so no need to keep searching
					If $and_Group = $g_ActiveConnections[$a][4] Then ContinueLoop; we made a change, skip to next and-group if any
					; we use 'and-group' to represent sub-groups when we need one from each sub-group (ex: a|b&c|d is satisfied by ac, bc, ad, bd)
					; _Depend_GetActiveDependAdv implements this as follows: each '&' we encounter in a rule increments the 'group' count by one
				EndIf
			WEnd
			If $Restart = 1 Then
				_Depend_GetActiveConnections(0); we made a change, so clear and rebuild $g_ActiveConnections
				ExitLoop; jump to CHECK FOR COMPLETION
			EndIf
		Next
		; CHECK FOR COMPLETION
		If $Restart = 0 Then ExitLoop; we reached the end of the active connections without making any changes -> jump to FINAL
		For $r = 1 to $Return[0][0]; Prevent crashes...
			If $Return[$r][1] = '' Then ExitLoop; one of the recorded component types was blank 
		Next
	WEnd
	; FINAL
	ReDim $Return[$Return[0][0]+1][4]; trim any excess slots from the end of the return array
	If $Return[0][0] = 0 Then Return $Return; if we made no changes, return the empty array
	_Depend_CreateSortedOutput($Return); otherwise, sort the array of changes
	Return $Return
EndFunc   ;==>_Depend_AutoSolve

; ---------------------------------------------------------------------------------------------
; show the mods that would be removed. Reload saved settings if desired
;  p_Type =
;	3 - autosolve both dependencies and conflicts
;	2 - autosolve dependencies
;	1 - autosolve conflicts
;  p_Force = whether to display 'this was forced' text or not (no other effect)
; ---------------------------------------------------------------------------------------------
Func _Depend_AutoSolveWarning($p_Type, $p_Force=0)
	Local $Message = IniReadSection($g_TRAIni, 'DP-Msg')
	Local $Return, $Output = ''
	_Tree_GetCurrentSelection(1)
	; resolve dependencies only, or if also resolving conflicts, resolve dependencies first
	If $p_Type = 2 or $p_Type = 3 Then; activate mods/components that can satisfy missing dependencies
		;$Test = $g_Compilation
		;$g_Compilation = 'E'
		$Return=_Depend_AutoSolve('DM', 1, 0); don't skip warning rules
		If $Return[0][1] <> '' Then $Output &= _GetTR($Message, 'L4') & @CRLF & $Return[0][1] & @CRLF & @CRLF; => mod/component will be added
		$Return=_Depend_AutoSolve('DO', 1, 0); don't skip warning rules
		If $Return[0][1] <> '' Then $Output &= _GetTR($Message, 'L4') & @CRLF & $Return[0][1] & @CRLF & @CRLF; => mod/component will be added
		;$g_Compilation = $Test
	EndIf
	If $p_Type = 1 or $p_Type = 3 Then; deactivate mods/components that conflict
		$Return=_Depend_AutoSolve('C', 2, 0); don't skip warning rules
		If $Return[0][1] <> '' Then $Output &= _GetTR($Message, 'L3') & @CRLF & $Return[0][1] & @CRLF & @CRLF; => mod/component will be removed
	EndIf
	If $p_Type = 2 Or $p_Type = 3 Then; deactivate any "in need" mods/components that are still missing dependencies
		$Return=_Depend_AutoSolve('DS', 2, 0); don't skip warning rules
		If $Return[0][1] <> '' Then $Output &= _GetTR($Message, 'L3') & @CRLF & $Return[0][1] & @CRLF & @CRLF; => mod/component will be removed
	EndIf
	If $Output <> '' Then
		If $p_Force = 1 Then
			$Output =  _GetTR($Message, 'L6')&@CRLF&$Output; => auto-solve forced
		Else
			$Output &= _GetTR($Message, 'L5'); => proceed or go back?
		EndIf
		$Answer = _Misc_MsgGUI(2, _GetTR($g_UI_Message, '0-T1'), $Output, 2, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2')); => ok to continue with this result?
		If $Answer = 1 Then
			_Misc_SetTab(9); view progress-bar
			_Tree_Reload(); reload saved settings
			_Depend_GetActiveConnections(); reset view
			_Misc_SetTab(10); view connections-screen
			Return
		EndIf
	EndIf
	_Depend_GetActiveConnections()
EndFunc   ;==>_Depend_AutoSolveWarning

; ---------------------------------------------------------------------------------------------
; Creates a context menu to solve dependencies and conflicts
; ---------------------------------------------------------------------------------------------
Func _Depend_Contextmenu()
	Local $Message = IniReadSection($g_TRAIni, 'DP-Msg')
	Local $MenuItem[10]
	$oldState = $g_Compilation
	$g_Compilation = 'E'
	GUISetState(@SW_DISABLE); disable the GUI itself while selection is pending to avoid unwanted treeview-changes
	$g_UI_Menu[0][4] = GUICtrlCreateContextMenu($g_UI_Menu[0][6]); create a context-menu on the clicked item
	$MenuLabel = _GetTR($Message, 'L2'); => mod
	GUICtrlCreateMenuItem($g_CentralArray[$g_UI_Menu[0][9]][4] , $g_UI_Menu[0][4])
	GUICtrlSetState(-1, $GUI_DISABLE)
	If $g_CentralArray[$g_UI_Menu[0][9]][3] <> '-' Then
		$MenuLabel = _GetTR($Message, 'L1'); => component
		GUICtrlCreateMenuItem($g_CentralArray[$g_UI_Menu[0][9]][2]&': '&$g_CentralArray[$g_UI_Menu[0][9]][3] , $g_UI_Menu[0][4])
		GUICtrlSetState(-1, $GUI_DISABLE)
	EndIf
	GUICtrlCreateMenuItem('', $g_UI_Menu[0][4])
; ---------------------------------------------------------------------------------------------
; Create the menu items
; ---------------------------------------------------------------------------------------------
	If $g_UI_Menu[0][7] = 'C' Then; Conflict
		If $g_CentralArray[$g_UI_Menu[0][9]][2] <> '-' Then
			$MenuItem[0] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M1'), _GetTR($Message, 'L1'), _GetTR($Message, 'M6')), $g_UI_Menu[0][4]); => item: remove conflicts > others (local)
			$MenuItem[1] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M1'), _GetTR($Message, 'L1'), _GetTR($Message, 'M7')), $g_UI_Menu[0][4]); => item: remove conflicts > others (global)
			$MenuItem[2] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M4'), _GetTR($Message, 'L1')), $g_UI_Menu[0][4]); => item: remove conflicts > itself (local)
			GUICtrlCreateMenuItem('', $g_UI_Menu[0][4])
			$MenuItem[3] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M1'), _GetTR($Message, 'L2'), _GetTR($Message, 'M7')), $g_UI_Menu[0][4]); => mod: remove conflicts > others (global)
			$MenuItem[4] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M2'), _GetTR($Message, 'M7')), $g_UI_Menu[0][4]); => mod: remove conflicts > itself (global)
			$MenuItem[5] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M4'), _GetTR($Message, 'L2')), $g_UI_Menu[0][4]); => mod: remove conflicts > itself (local)
		Else
			$MenuItem[0] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M1'), _GetTR($Message, 'L2'), _GetTR($Message, 'M6')), $g_UI_Menu[0][4]); => mod: remove conflicts > others (local)
			$MenuItem[3] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M1'), _GetTR($Message, 'L2'), _GetTR($Message, 'M7')), $g_UI_Menu[0][4]); => mod: remove conflicts > others (global)
			$MenuItem[2] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M4'), _GetTR($Message, 'L2')), $g_UI_Menu[0][4]); => mod: remove conflicts > itself (local)
		EndIf
	ElseIf $g_UI_Menu[0][7] = 'DS' Then; selected items that have open dependencies
		$MenuItem[0] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M3'), $MenuLabel), $g_UI_Menu[0][4]); => solve open dependencies
		$MenuItem[1] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M4'), $MenuLabel), $g_UI_Menu[0][4]); => remove mod itself
	ElseIf StringRegExp($g_UI_Menu[0][7], 'D(M|O)') Then; missing dependencies
		$MenuItem[0] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M5'), $MenuLabel), $g_UI_Menu[0][4]); => install the item
	EndIf
	If $g_Connections[$g_UI_Menu[0][8]][4]=1 Then; this is rather a notice/warning than a conflict
		GUICtrlCreateMenuItem('', $g_UI_Menu[0][4])
		$MenuItem[6] = GUICtrlCreateMenuItem(_GetTR($Message, 'M8'), $g_UI_Menu[0][4]); => ignore this problem
	EndIf
	__ShowContextMenu($g_UI[0], $g_UI_Menu[0][6], $g_UI_Menu[0][4])
; ---------------------------------------------------------------------------------------------
; Create another Msg-loop, since the GUI is disabled and only the menuitems should be available
; ---------------------------------------------------------------------------------------------
	While 1
		$Msg = GUIGetMsg()
		If $Msg = $MenuItem[0] And $MenuItem[0] <> '' Then
			If $g_UI_Menu[0][7] = 'C' Then
				_Depend_SetGroupByNumber($g_UI_Menu[0][8], 2, $g_UI_Menu[0][9]); item or mod: remove conflicts > others (local)
			ElseIf $g_UI_Menu[0][7] = 'DS' Then
				_Depend_SetGroupByNumber($g_UI_Menu[0][8], 1); solve open dependencies
			Else
				_Depend_SetModState($g_UI_Menu[0][9], 1); install the item
			EndIf
			_Depend_GetActiveConnections()
			ExitLoop
		ElseIf $Msg =  $MenuItem[1] And $MenuItem[1] <> '' Then
			If $g_UI_Menu[0][7] = 'C' Then
				_Depend_SolveConflict($g_UI_Menu[0][9], 1); item: remove conflicts > others (global)
			ElseIf $g_UI_Menu[0][7] = 'DS' Then
				_Depend_SetModState($g_UI_Menu[0][9], 2); item or mod: remove mod itself
			EndIf
			_Depend_GetActiveConnections()
			ExitLoop
		ElseIf $Msg =  $MenuItem[2] And $MenuItem[2] <> '' Then
			_Depend_SetModState($g_UI_Menu[0][9], 2); item or mod: remove conflicts > itself (local)
			_Depend_GetActiveConnections()
			ExitLoop
		ElseIf $Msg =  $MenuItem[3] And $MenuItem[3] <> '' Then
			_Depend_SolveConflict($g_CentralArray[$g_UI_Menu[0][9]][0], 1, 1); mod: remove conflicts > others (global)
			_Depend_GetActiveConnections()
			ExitLoop
		ElseIf $Msg =  $MenuItem[4] And $MenuItem[4] <> '' Then
			_Depend_SolveConflict($g_CentralArray[$g_UI_Menu[0][9]][0], 2, 1); mod: remove conflicts > itself (global)
			_Depend_GetActiveConnections()
			ExitLoop
		ElseIf $Msg =  $MenuItem[5] And $MenuItem[5] <> '' Then
			_Depend_SetModState(_AI_GetStart($g_UI_Menu[0][9], '-'), 2); mod: remove conflicts > itself (local)
			_Depend_GetActiveConnections()
		ElseIf $Msg =  $MenuItem[6] And $MenuItem[6] <> '' Then
			$g_Connections[$g_UI_Menu[0][8]][3]= 'W'&$g_Connections[$g_UI_Menu[0][8]][3]; make the warning disappear
			_Depend_GetActiveConnections()
			ExitLoop
		ElseIf _IsPressed('01', $g_UDll) Then; react to a left mouseclick outside of the menu
			While _IsPressed('01', $g_UDll)
				Sleep(10)
			WEnd
			ExitLoop
		ElseIf _IsPressed('02', $g_UDll) Then; react to a right mouseclick outside of the menu
			While _IsPressed('02', $g_UDll)
				Sleep(10)
			WEnd
			ExitLoop
		EndIf
		Sleep(10)
	WEnd
	$g_Compilation = $oldState
	GUISetState(@SW_ENABLE); enable the GUI again
	GUICtrlDelete($g_UI_Menu[0][4])
	$g_Flags[16] = 0
EndFunc   ;==>_Depend_Contextmenu

; ---------------------------------------------------------------------------------------------
; Create a sorted output for message-boxes and others
;  p_Array[][0] = setup-name
;  p_Array[][1] = component-type ('', '+' MUC, '?' SUB, '-' if a mod, not a component)
;  p_Array[][2] = mod name
;  p_Array[][3] = component description or '-' if a mod, not a component
; ---------------------------------------------------------------------------------------------
Func _Depend_CreateSortedOutput(ByRef $p_Array)
	Local $Complete='|'
	$p_Array[0][1]=''
	_ArraySort($p_Array, 0, 1, 0, 1)
	For $p=1 to $p_Array[0][0]
		If $p_Array[$p][1] <> '' Then
			If $p <> 1 Then _ArraySort($p_Array, 0, 1, $p-1)
			_ArraySort($p_Array, 0, $p, 0)
			ExitLoop
		EndIf
		$Complete&=$p_Array[$p][0]&'|'
	Next
	Local $Current=''
	For $p=1 to $p_Array[0][0]
		If $p_Array[$p][1] <> '' And StringInStr($Complete, '|'&$p_Array[$p][0]&'|') Then ContinueLoop; don't show component if mod is shown
		If $Current <> $p_Array[$p][0] Then
			$p_Array[0][1]&=@CRLF&$p_Array[$p][2]
			If $p_Array[$p][1] = '' Then
				$p_Array[0][1]&=@CRLF
				ContinueLoop
			Else
				$p_Array[0][1]&=':'&@CRLF
			EndIf
			$Current = $p_Array[$p][0]
		EndIf
		$p_Array[0][1]&=_Tree_SetLength($p_Array[$p][1]) & ': '& $p_Array[$p][3] & @CRLF
	Next
EndFunc   ;==>_Depend_CreateSortedOutput

; ---------------------------------------------------------------------------------------------
; Add entries to the array of active problems
; ---------------------------------------------------------------------------------------------
Func _Depend_ActiveAddItem($p_Type, $p_Num, $p_Setup, $p_ID=0, $and_Group=0)
	$g_ActiveConnections[0][0]+=1
	$g_ActiveConnections[$g_ActiveConnections[0][0]][0]=$p_Type
	$g_ActiveConnections[$g_ActiveConnections[0][0]][1]=$p_Num
	$g_ActiveConnections[$g_ActiveConnections[0][0]][2]=$p_Setup
	$g_ActiveConnections[$g_ActiveConnections[0][0]][3]=$p_ID
	$g_ActiveConnections[$g_ActiveConnections[0][0]][4]=$and_Group
EndFunc   ;==>_Depend_ActiveAddItem

; ---------------------------------------------------------------------------------------------
; Clear and fill $g_ActiveConnections array
; If $p_Show is true, display all conflicts and dependencies as needed (used during selection)
; ---------------------------------------------------------------------------------------------
Func _Depend_GetActiveConnections($p_Show=1)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Depend_GetActiveConnections')
	Global $g_ActiveConnections[99999][5]; initialize/clear active connections (will fill using _Depend_ActiveAddItem)
	$g_ActiveConnections[0][0] = 0; reset number of active connections counter to zero
	If $p_Show=1 Then _GUICtrlListView_BeginUpdate($g_UI_Handle[1])
	If $p_Show=1 Then _GUICtrlListView_DeleteAllItems($g_UI_Handle[1])
	For $c = 1 To $g_Connections[0][0]; loop through array of all Game.ini rules
		If StringLeft ($g_Connections[$c][3], 1) = 'W' Then; skip rules that have been right-click ignored by user
			ContinueLoop
		ElseIf StringLeft ($g_Connections[$c][3], 1) = 'D' Then; this is a dependency rule
			$String=StringTrimLeft($g_Connections[$c][3], 2)
			If Not StringInStr($String, ':') Then; all items are needed
				_Depend_GetActiveDependAll($String, $c, $p_Show)
			Else; some items need some other items
				_Depend_GetActiveDependAdv($String, $c, $p_Show)
			EndIf
		ElseIf StringLeft ($g_Connections[$c][3], 1) = 'C' Then; this is a conflict rule
			$String=StringTrimLeft($g_Connections[$c][3], 2)
			If StringInStr($String, ':') Then; this is an advanced conflict
				_Depend_GetActiveConflictAdv($String, $c, $p_Show)
			Else; this is a normal conflict
				_Depend_GetActiveConflictStd($String, $c, $p_Show)
			EndIf
		Else; this is an unknown type of connection
			_PrintDebug('+' & @ScriptLineNumber & ' Unknown type encountered in _Depend_GetActiveConnections: ' & $g_Connections[$c][3])
		EndIf
	Next
	If $p_Show=1 Then _GUICtrlListView_EndUpdate($g_UI_Handle[1])
EndFunc   ;==>_Depend_GetActiveConnections

; ---------------------------------------------------------------------------------------------
; Handle dependency rules without a ':' delimiter
; This is usually for rules like D:modA(1|2)&modB(3)|modC(-)
; We interpret this to mean that all parts are "needed" ONLY if at least one part is active
; Effectively this is equivalent to D:modA(1|2):modB(3)|modC(-) and D:modB(3)|modC(-):modA(1|2)
; Therefore, to avoid duplication of parsing logic, we reuse the advanced parsing method
; Dependency rules that do not contain any '&' will be silently ignored (e.g., D:a or D:a|b)
; ---------------------------------------------------------------------------------------------
Func _Depend_GetActiveDependAll($p_String, $p_ID, $p_Show)
	$Return=_Depend_ItemGetSelected($p_String)
	If $Return[0][1] = 0 or $Return[0][1] = $Return[0][0] Then Return; nothing selected or all selected
	;check for a special case - game type can also be a dependency satisfying an OR condition
	If StringRegExp($p_String, '\x7c('&$g_Flags[14]&')[^[:alpha:]]') Then Return; found OR '|' followed by current game type -> do nothing
	$Parts=StringSplit($p_String, '&'); we split the rule into '&'-subsets
	If @error Then Return; if no '&' in the rule then do nothing
	For $and_Group = 1 to $Parts[0]; this $and_Group number is also used for adding dependency connections
		$ThisPart=_Depend_ItemGetSelected($Parts[$and_Group]); this is inefficient but simpler than reusing $Return
		If $ThisPart[0][1] > 0 Then; at least one active mod/component in this part -> call _Depend_GetActiveDependAdv
			; for each part that is active, we treat it like an advanced rule of the form D:ThisPart:OtherParts
			$OtherParts=''
			For $p=1 to $Parts[0]
				If $p <> $and_Group Then
					$OtherParts &= $Parts[$p]
					If $p <> 1 And $p <> $Parts[0] Then $OtherParts &= '&'
				EndIf
			Next
			_Depend_GetActiveDependAdv($Parts[$and_Group] & ':' & $OtherParts, $p_ID, $p_Show)
			_PrintDebug('_Depend_GetActiveDependAll called _Depend_GetActiveDependAdv('& $Parts[$and_Group]&':'&$OtherParts & ') for original rule '&$p_String)
		EndIf
	Next
	Return; disable all code after this line
	$Prefix = ''
	$Warning = ''
	If $g_Connections[$p_ID][4]=1 Then $Warning=' **'
	For $r=1 to $Return[0][0]; show selected items first
		If $Return[$r][1]=1 Then
			If $p_Show=1 Then GUICtrlCreateListViewItem($Prefix&$g_CentralArray[$Return[$r][0]][4]&$Warning & '|' & $g_CentralArray[$Return[$r][0]][3], $g_UI_Interact[10][1])
			_Depend_ActiveAddItem('DS', $p_ID, $Return[$r][0])
			If $Prefix='' Then $Prefix='+ '
		EndIf
	Next
	$Prefix = ''
	For $r=1 to $Return[0][0]; then show the missing ones
		If $Return[$r][1]=0 Then
			$Mod=$g_CentralArray[$Return[$r][0]][4]
			If $Mod = '' Then
				$Mod=_GetTR($g_UI_Message, '10-L1'); => removed due to translation
				$Comp=''
			Else
				$Comp=$g_CentralArray[$Return[$r][0]][3]
			EndIf
			If $p_Show=1 Then GUICtrlCreateListViewItem($Prefix&$Mod & '|' & $Comp, $g_UI_Interact[10][1])
			_Depend_ActiveAddItem('DM', $p_ID, $Return[$r][0])
			If $p_Show=1 Then GUICtrlSetBkColor(-1, 0xFFA500)
			If $Prefix='' Then $Prefix='+ '
		EndIf
	Next
EndFunc    ;==>_Depend_GetActiveDependAll

; ---------------------------------------------------------------------------------------------
; Check if currently active/selected mods/components satisfy a provided dependency rule or not
; If conditions on the LEFT side of the rule (mods/components "in need") are unmet, do nothing
; If any conditions on the RIGHT side of the rule (mods/components "needed") are not met, then:
;  Add all active "in need" mods and inactive "needed" mods in the rule to $g_ActiveConnections
;  If $p_Show is true, build text for 'resolve dependencies' screen (display handled elsewhere)
;
; How do we interpret rules that contain combinations of AND '&' and OR '|'?
;
; Examples:
;
;  D:DrizztSaga(0|1)&InfinityAnimations(0):IAContent08(-)&IAContent01(-)&IAContent04(-)&IAContent05(-)
;    rule only applies if InfinityAnimations 0 is active AND DrizztSaga 0 or 1 is active
;  D:DrizztIsNotStupid(0)&DrizztSaga(0|1):DrizztSaga(3)
;    rule only applies if Drizzt Saga 0 or 1 is active AND DrizztIsNotStupid 0 is active
;
; What if multiple '&' and '|' are alternated in the rule?
;
; Consider an alternate form of the first rule:
;   D:DrizztSaga(0)&InfinityAnimations(0)|DrizztSaga(1)&InfinityAnimations(0):IAContent08(-)&IAContent01(-)&IAContent04(-)&IAContent05(-)
;     This rule is improperly written because the InfinityAnimations 0 component is repeated
;     It will be interpreted by BWS as Drizzt Saga 0 AND (Infinity Animations 0 or Drizzt Saga 1) AND Infinity Animations 0
;     If only Drizzt Saga 1 and Infinity Animations 0 are active, BWS will NOT require the dependencies (contrary to intent)
;
; Examples of '&' and '|' combinations on left side of dependency rule ('in need'):
;  D:aa|bb&cc:zz 		means that zz is needed only if cc AND (aa or bb) aew active
;  D:aa&bb|cc:zz 		means that zz is needed only if aa AND (bb or cc) are active
;  D:aa&bb|cc&dd:zz 	means that zz is needed only if aa AND (bb or cc) AND dd are active
;  D:aa|bb&cc&dd|ee:zz 	means that zz is needed only if (aa or bb) AND cc AND (dd or ee) are active
;
; Examples of '&' and '|' combinations on right side of dependency rule ('needed'):
;  D:aa:zz&xx|yy 		means that zz AND (xx or yy) are needed
;  D:aa:zz|xx&yy 		means that (zz or xx) AND yy are needed
;  D:aa:zz|xx&yy|ww 	means that (zz or xx) AND yy or ww are needed
;  D:aa:zz|xx&yy|ww&uu 	means that (zz or xx) AND (yy or ww) AND uu are needed
;    note the above rule does NOT mean "zz OR both xx and yy OR both ww and uu"
;
; Therefore: we split rules into 'and-group' sub-sets and require at least one from each set
; ---------------------------------------------------------------------------------------------
Func _Depend_GetActiveDependAdv($p_String, $p_ID, $p_Show)
	;IniWrite("depend.ini", "debug", "_Depend_GADA_"&$p_ID, $g_Connections[$p_ID][0]&" ~~ "&$g_Connections[$p_ID][1]&" ~~ "&$p_String)
	$p_String=StringSplit($p_String, ':'); p_String will be a dependency rule like "123&456:789" without the "D:" prefix
	$Left=_Depend_ItemGetSelected($p_String[1]); otherwise, check which mods/components from the LEFT side of the dependency rule are active
	If $Left[0][1] = 0 Then Return; NOTHING on the LEFT side of the rule is active/selected, so the RIGHT side does not matter -> do nothing
	$Right=_Depend_ItemGetSelected($p_String[2]); check which mods/components from the RIGHT side of the dependency rule are active
	If $Right[0][0] = $Right[0][1] Then Return; if ALL mods/components on the RIGHT side of the rule are active, the rule is satisfied -> do nothing
	;check for a special case - game type can also be a dependency satisfying an OR condition
	If StringRegExp($p_String[2], '\x7c('&$g_Flags[14]&')[^[:alpha:]]') Then Return; found OR '|' followed by game type in dependencies -> do nothing
	; at this point, we know at least one mod/component on the LEFT is active, but there could still be unsatisfied '&' rules on the LEFT side
	; at this point, we know at least one mod/component on the RIGHT is inactive, but not necessarily a needed dependency (it could be an '|' rule)
	; now we need to evaluate the rule to check which conditions on the LEFT are satisfied and which conditions on the RIGHT are not satisfied
	; we only have two operators (AND/OR) -- if we had more, we would need a parser (http://effbot.org/zone/simple-top-down-parsing.htm)
	; to handle rules with combinations of AND/OR, we will split each side of the rule into parts separated by '&' operators
	; we will do two passes through both sides of the rule because we need to check conditions on both sides before adding connections
	Local $Warning = ''
	If $g_Connections[$p_ID][4]=1 Then $Warning=' **'; the rule we are checking is a 'CW' or 'DW'
	Local $foundMissingDependency=0
	For $secondPass = 0 to 1
		; evaluate the rule to check if conditions on the LEFT are satisfied and conditions on the RIGHT are not satisfied
		If $secondPass And $foundMissingDependency = 0 Then Return; first pass did not find any missing dependencies -> do nothing
		For $s = 1 to 2; outer loop to check LEFT side (1) followed by RIGHT side (2)
			$Prefix = ''; we need to clear the prefix (only used if $p_Show = 1) when we switch from LEFT side to RIGHT side
			$Parts=StringSplit($p_String[$s], '&'); we split the rule into '&'-subsets (this also works on strings without '&')
			For $and_Group = 1 to $Parts[0]; this $and_Group number is also used for adding dependency connections
				$ThisPart=_Depend_ItemGetSelected($Parts[$and_Group]); this is inefficient but simpler than reusing $Left/$Right
				If $s = 1 Then; on the left side, we need at least one active mod in EVERY '&'-subset, else the entire rule does not apply
					If $ThisPart[0][1] = 0 Then Return; left side, no active mods/components in this part (which needs at least one) -> do nothing
					If $secondPass = 0 And $ThisPart[0][0] = $ThisPart[0][1] Then ContinueLoop; all mods/components are active -> check next part
					If $secondPass Then
						; if we reached this point, conditions on the LEFT side are met and there is at least one missing dependency on the RIGHT side
						$Prefix = ''
						For $t=1 to $ThisPart[0][0]; process mods/components "in need" (from the LEFT side of the rule)
							If $ThisPart[$t][1]=1 Then; only consider "in need" mods/components if they are ACTIVE
								If $p_Show=1 Then GUICtrlCreateListViewItem($Prefix & $g_CentralArray[$ThisPart[$t][0]][4] & $Warning & '|' & $g_CentralArray[$ThisPart[$t][0]][3], $g_UI_Interact[10][1]); mod name, component description
								_Depend_ActiveAddItem('DS', $p_ID, $ThisPart[$t][0]); add an "in need" connection from this mod/component
								If $Prefix='' Then $Prefix='+ '
							EndIf
						Next
					EndIf
				Else;If $s = 2 Then; on the right side, we need at least one inactive mod in ANY '&'-subset, else no missing dependencies
					If $ThisPart[0][1] > 0 Then ContinueLoop; at least one active mod/component in this part -> skip to next part
					$foundMissingDependency=1; else, we found at least one missing ('needed') dependency here
					If $secondPass Then
						$inActiveCount = $ThisPart[0][0]; - $ThisPart[0][1]; 'total in group' minus 'active in group' (we already checked none are active)
						For $t = 1 to $ThisPart[0][0]; iterate over inactive mods/components in this part
							If $inActiveCount = 1 Then; if it is the only missing dependency in this '&'-subset, it is MANDATORY
								_Depend_ActiveAddItem('DM', $p_ID, $ThisPart[$t][0], $and_Group); add MANDATORY connection for this mod/component
								If $Prefix <> '' Then $Prefix='+ '
								If $p_Show = 1 Then
									$ModName=$g_CentralArray[$ThisPart[$t][0]][4]; mod name
									If $ModName = '' Then
										$ModName=_GetTR($g_UI_Message, '10-L1'); => removed due to purge/translation/invalid
										$CompDesc=''; no component description
									Else
										$CompDesc=$g_CentralArray[$ThisPart[$t][0]][3]; component description
									EndIf
									GUICtrlCreateListViewItem($Prefix&$ModName & '|' & $CompDesc, $g_UI_Interact[10][1])
									GUICtrlSetBkColor(-1, 0xFFA500)
								EndIf
							ElseIf $inActiveCount > 1 Then; if it is one of multiple missing dependencies in this '&'-subset, it is OPTIONAL
								_Depend_ActiveAddItem('DO', $p_ID, $ThisPart[$t][0], $and_Group); add OPTIONAL connection for this mod/component
								If $Prefix <> '' Then $Prefix='/ '
								If $p_Show = 1 Then
									$ModName=$g_CentralArray[$ThisPart[$t][0]][4]; mod name
									If $ModName = '' Then
										$ModName=_GetTR($g_UI_Message, '10-L1'); => removed due to purge/translation/invalid
										$CompDesc=''; no component description
									Else
										$CompDesc=$g_CentralArray[$ThisPart[$t][0]][3]; component description
									EndIf
									GUICtrlCreateListViewItem($Prefix&$ModName & '|' & $CompDesc, $g_UI_Interact[10][1])
									GUICtrlSetBkColor(-1, 0xFFA500)
								EndIf
							EndIf; else $inActiveCount is 0 (we never encounter this case because we check earlier and skip)
						Next; LOOP: check next mod/component
					EndIf; secondPass
				Endif; left/right side
			Next; LOOP: check next '&'-subset 
		Next; LOOP: left side -> right side
	Next; LOOP: first pass -> second pass
EndFunc    ;==>_Depend_GetActiveDependAdv

; ---------------------------------------------------------------------------------------------
; See if a component is installed that has a conflict with a combination of other listed components
; ---------------------------------------------------------------------------------------------
Func _Depend_GetActiveConflictAdv($p_String, $p_ID, $p_Show)
	$p_String=StringSplit($p_String, ':')
	Local $Test[$p_String[0]+1][50]
	For $s=1 to $p_String[0]
		$Active=_Depend_ItemGetSelected($p_String[$s])
		For $r=1 to $Active[0][0]
			If StringInStr($p_String[$s], '&') And $Active[0][1] <> $Active[0][0] Then $r=$Active[0][0]; skip if all are required and not all are active
			If $Active[$r][1] = 1 Then
				$Test[$s][0]+=1
				$Test[$s][$Test[$s][0]]=$Active[$r][0]
			EndIf
		Next
		If $Test[$s][0]<> 0 Then $Test[0][0]+=1
	Next
	If $Test[0][0] <= 1 Then Return; no multiple conflicts were selected
	Local $IsConflict = 0
	$Warning = ''
	If $g_Connections[$p_ID][4]=1 Then $Warning=' **'
	For $s=1 to $p_String[0]
		If $Test[$s][0] <> 0 Then
			Local $Prefix = ''
			For $r=1 to $Test[$s][0]
				If $p_Show=1 Then GUICtrlCreateListViewItem($Prefix&$g_CentralArray[$Test[$s][$r]][4]&$Warning & '|' & $g_CentralArray[$Test[$s][$r]][3], $g_UI_Interact[10][1])
				_Depend_ActiveAddItem('C', $p_ID, $Test[$s][$r], $s)
				$Prefix='+ '
				If $p_Show=1 And $IsConflict = 1 Then GUICtrlSetBkColor(-1, 0xFF0000)
			Next
			$IsConflict = 1
			$Warning = ''
		EndIf
	Next
EndFunc    ;==>_Depend_GetActiveConflictAdv

; ---------------------------------------------------------------------------------------------
; See if a component is installed that has a conflict with other listed components
; ---------------------------------------------------------------------------------------------
Func _Depend_GetActiveConflictStd($p_String, $p_ID, $p_Show)
	Local $IsConflict = 0
	$Active=_Depend_ItemGetSelected($p_String)
	If $Active[0][1] = 0 or $Active[0][1] = 1 Then Return
	$Warning = ''
	If $g_Connections[$p_ID][4]=1 Then $Warning=' **'
	For $r=1 to $Active[0][0]
		If $Active[$r][1]=1 Then
			If $p_Show=1 Then GUICtrlCreateListViewItem($g_CentralArray[$Active[$r][0]][4]&$Warning & '|' & $g_CentralArray[$Active[$r][0]][3], $g_UI_Interact[10][1])
			_Depend_ActiveAddItem('C', $p_ID, $Active[$r][0])
			If $IsConflict = 0 Then
				$IsConflict=1
				$Warning=''
			Else
				If $p_Show=1 Then GUICtrlSetBkColor(-1, 0xFF0000)
			EndIf
		EndIf
	Next
EndFunc    ;==>_Depend_GetActiveConflictStd

; ---------------------------------------------------------------------------------------------
; Gather the mods and components that will not be able to be installed / are missing (used during download, extraction, installation)
; ---------------------------------------------------------------------------------------------
Func _Depend_GetUnsolved($p_Setup='', $p_Comp='')
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Depend_GetUnsolved')
	Local $Output, $Return[1][4], $String = '|'
	Local $Tmp[$g_CentralArray[0][0]-$g_CentralArray[0][1]+2][2]; fetch all the current selection-numbers and put them into an array
	For $a=$g_CentralArray[0][1] to $g_CentralArray[0][0]
		$Tmp[0][0]+=1
		$Tmp[$Tmp[0][0]][0]=$a
		$Tmp[$Tmp[0][0]][1]=$g_CentralArray[$a][9]
	Next
	; disable the mods that are listed as faults
	Local $Fault=IniReadSection($g_BWSIni, 'Faults')
	If IsArray($Fault) Then
		For $f=1 to $Fault[0][0]
			For $a=$g_CentralArray[0][1] to $g_CentralArray[0][0]
				If $g_CentralArray[$a][2] <> '-' Then ContinueLoop
				If $g_CentralArray[$a][0] = $Fault[$f][0] Then
					$String &= $g_CentralArray[$a][0]&'|'
					$Fault[$f][1]=$a
					_Depend_SetModState($a, 2)
					ExitLoop
				EndIf
			Next
		Next
	EndIf
	; also disable setups component if defined
	If $p_Setup <> '' Then
		For $a=$g_CentralArray[0][1] to $g_CentralArray[0][0]
			If $p_Setup = $g_CentralArray[$a][0] And $p_Comp = $g_CentralArray[$a][2] Then _AI_SetClicked($a, 2)
		Next
	EndIf
	; only list unsolved mods in the array & create some formatted output
	_Depend_GetActiveConnections(0); rebuild currently active connections
	If $g_ActiveConnections[0][0] <> 0 Then
		$Return=_Depend_AutoSolve('DS', 2, 1); remove all mods and components that have an open dependency (skip ignorable rules)
		If $Return[0][1] <> '' Then
			For $r =1 to $Return[0][0]
				If StringInStr($String, '|'&$Return[$r][0]&'|') Then
					$Return[$r][0]=''; don't show those that are missing - have already been displayed as they are in the faults-section
				Else
					$Return[0][2]+=1; increase counter for unsolved components/mods that depend on mods from faults-section
					For $s=0 to 3; re-arrange array
						$Return[$Return[0][2]][$s]=$Return[$r][$s]
					Next
				EndIf
			Next
		EndIf
		$Return[0][0]=$Return[0][2]; set new number of items in the array
		ReDim $Return[$Return[0][0]+1][4]
	EndIf
	If IsArray($Fault) Then $Return[0][2]+=$Fault[0][0]; set number of total "faulty" components/mods
	If $Return[0][1] <> '' Then _Depend_CreateSortedOutput($Return)
; reset the selection before the testing was done
	For $t=1 to $Tmp[0][0]
		$g_CentralArray[$Tmp[$t][0]][9]=$Tmp[$t][1]
	Next
	Return $Return; $Return[0][unsolved, output, missing + unsolved]
EndFunc   ;==>_Depend_GetUnsolved

; ---------------------------------------------------------------------------------------------
; List all connections that are met/affected by a mod/component
; ---------------------------------------------------------------------------------------------
Func _Depend_ItemGetConnections(ByRef $p_Array, $p_ID, $p_String, $p_Setup, $p_Comp='-')
	Local $Array, $LastMod='', $Return=''
	$p_String=StringSplit($p_String, '|')
	For $p=1 to $p_String[0]
		$r=$p_String[$p]
		$Test=StringRegExp($p_Array[$r][3], '(?i)(\x3a|\x3e|\x7c|\x26)'&$p_Setup&'\x28'&$p_Comp&'\x29', 3); '\x3a|\x3e|\x7c|\x26') ; Get the :>|&
		If IsArray($Test) Then
			$Return&=@CRLF & $p_Array[$r][2]
			If $p_Array[$r][4] = 1 Then $Return&=' **'
			For $t=0 to UBound($Test)-1
				$Sign=StringLeft($Test[$t], 1)
				$p_Array[$r][3]=StringReplace($p_Array[$r][3], $Sign&$p_Setup&'('&$p_Comp&')', $Sign&$p_ID, 1)
			Next
		EndIf
	Next
	If StringRegExp($Return, '\x2a{2}(\z|\n)') Then $Return&=@CRLF&@CRLF&_GetTR($g_UI_Message, '4-L20')
	Return $Return
EndFunc   ;==>_Depend_ItemGetConnections

; ---------------------------------------------------------------------------------------------
; Expects a rule 
; Just return an array of mod/component IDs and whether they are selected (active) or not
;  Return[0][0] = total number of mod/component IDs in the array
;  Return[0][1] = number of active mod/component IDs in the array
;  Return[N][0] = mod/component ID
;  Return[N][1] = 0/1 active/inactive
; ---------------------------------------------------------------------------------------------
Func _Depend_ItemGetSelected($p_String, $p_Debug=0)
	If Not IsArray($p_String) Then
		$Array=StringSplit($p_String, ':|&>')
	Else
		$Array = $p_String
	EndIf
	Local $Return[$Array[0]+1][3]; create a return array with three values for each element in the split array
	$Return[0][0]=$Array[0]; set number of elements in return array equal to number of elements in split array
	;Return[0][1] will be used to count the total number of active mods/components in the return array
	For $a=1 to $Array[0]; loop
		$Return[$a][0]=$Array[$a]; copy next mod/component ID from split array into return array
		If $p_Debug Then IniWrite("debug.ini", "debug", "_Depend_IGS_"&$p_String&"_"&$Array[$a], "#active: "&$g_CentralArray[$Array[$a]][9]&" ~ modname: "&$g_CentralArray[$Array[$a]][4]&" ~ component? "&$g_CentralArray[$Array[$a]][3]&" ~ multi-install? "&$g_CentralArray[$Array[$a]][13])
		If StringInStr($Array[$a], ')') Then; if item is not a number, it does not exist/is not available in this selection (might have been purged)
			$Return[$a][1]=0; so just mark this element in the return array as not-active and continue
		ElseIf $g_CentralArray[$Array[$a]][2] <> '-' Then; ID points to a single component (not a mod)
			$Return[$a][1]=$g_CentralArray[$Array[$a]][9]; 0 if component not active, 1 if active 
			$Return[0][1]+=$g_CentralArray[$Array[$a]][9]; add to count of active mods/components found
		Else;If $g_CentralArray[$Array[$a]][2] = '-' Then; ID points to a mod heading, not a component
			If $g_CentralArray[$Array[$a]][9] > 0 Then; at least one component of the mod is active, so no other tests are needed here
				$Return[$a][1]=1; 0 if not active, 1 if active - the mod is active, so 1
				$Return[0][1]+=1; add to count of active mods/components found
			ElseIf $g_CentralArray[$Array[$a]][13] <> '' Then; it is not active here, but components might be installed later in the installation
				$Splitted=StringSplit($g_CentralArray[$Array[$a]][13], ','); get the other possible selections and check them, too
				For $s=1 to $Splitted[0]
					If $g_CentralArray[$Splitted[$s]][9] > 0 Then; we found an active selection
						$Return[$a][1]=1
						$Return[0][1]+=1
						ExitLoop
					EndIf
				Next
			EndIf
		EndIf
		If $p_Debug Then ConsoleWrite('>'&$g_CentralArray[$Return[$a][0]][4] & ' - ' & $g_CentralArray[$Return[$a][0]][3] & @CRLF)
		If $p_Debug Then ConsoleWrite('-'&$Return[$a][0]& ' => ' & $Return[$a][1] & @CRLF)
	Next
	Return $Return
EndFunc   ;==>_Depend_ItemGetSelected

; ---------------------------------------------------------------------------------------------
; Returns a description-string
; ---------------------------------------------------------------------------------------------
Func _Depend_ListInstallAddItem($p_Setup, $p_Comp='-', $p_Num = 1)
	Local $Return
	$Return = IniRead($g_MODIni, $p_Setup, 'Name', $p_Setup)
	If $p_Comp <> '-' Then $Return &= @CRLF & _Tree_SetLength($p_Comp) & ': '& _GetTra($p_Setup, $p_Comp)
	If $p_Num = 1 Then $Return &= ' ' & Chr(0xB9)
	If $p_Num = 2 Then $Return &= ' ' & Chr(0xB2)
	$Return &= @CRLF & @CRLF
	Return $Return
EndFunc   ;==>_Depend_AddDescription

; ---------------------------------------------------------------------------------------------
; Display all conflicts of a mods component, just for safety reasons if someone installed mods on his own (used during installation)
; ---------------------------------------------------------------------------------------------
Func _Depend_ListInstallConflicts($p_Setup, $p_Comp)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Depend_ListInstallConflicts')
	Local $Return
	If $g_ActiveConnections[0][0] = 0 Then Return
	For $g=1 to $g_ActiveConnections[0][0]
		If $g_ActiveConnections[$g][0] <> 'C' Then ContinueLoop; skip other stuff
		If $g_CentralArray[$g_ActiveConnections[$g][2]][0] <> $p_Setup Then ContinueLoop
		If $g_CentralArray[$g_ActiveConnections[$g][2]][2] <> $p_Comp Then ContinueLoop
		$Return &= $g_Connections[$g_ActiveConnections[$g][1]][2] & @CRLF
		Local $Current = $g, $Prefix = ''
		While $g_ActiveConnections[$g-1][1] = $g_ActiveConnections[$Current][1]; get to the starting-point
			$g-= 1
		WEnd
		While $g_ActiveConnections[$g+1][1] = $g_ActiveConnections[$Current][1]
			$g+= 1
			If $g > $g_ActiveConnections[0][0] Then Return $Return
			If $g_CentralArray[$g_ActiveConnections[$g][2]][0] = $p_Setup And $g_CentralArray[$g_ActiveConnections[$g][2]][2] = $p_Comp Then ContinueLoop; don't display own component
			$Return&=$Prefix&_Depend_ListInstallAddItem($g_CentralArray[$g_ActiveConnections[$g][2]][0], $g_CentralArray[$g_ActiveConnections[$g][2]][2], 2)
			If $Prefix='' Then $Prefix='+ '
		WEnd
	Next
	Return $Return
EndFunc   ;==>_Depend_ListInstallConflicts

; ---------------------------------------------------------------------------------------------
; Display all unsolved dependencies, can be set to a mods component (used during installation)
; ---------------------------------------------------------------------------------------------
Func _Depend_ListInstallUnsolved($p_Setup, $p_Comp)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Depend_ListInstallUnsolved')
	Local $Return
	If $g_ActiveConnections[0][0] = 0 Then Return
	For $g=1 to $g_ActiveConnections[0][0]
		If $g_ActiveConnections[$g][0] <> 'DS' Then ContinueLoop; skip other stuff
		If $g_CentralArray[$g_ActiveConnections[$g][2]][0] <> $p_Setup Then ContinueLoop
		If $g_CentralArray[$g_ActiveConnections[$g][2]][2] <> '-' Then
			If $g_CentralArray[$g_ActiveConnections[$g][2]][2] <> $p_Comp Then ContinueLoop
		EndIf
		$Return &= $g_Connections[$g_ActiveConnections[$g][1]][2] & @CRLF
		Local $Current = $g, $Prefix = ''
		While $g_ActiveConnections[$g+1][1] = $g_ActiveConnections[$Current][1]
			$g+= 1
			If $g > $g_ActiveConnections[0][0] Then Return $Return
			$Return&=$Prefix&_Depend_ListInstallAddItem($g_CentralArray[$g_ActiveConnections[$g][2]][0], $g_CentralArray[$g_ActiveConnections[$g][2]][2], 1)
			If $Prefix='' Then $Prefix='+ '
		WEnd
	Next
	Return $Return
EndFunc   ;==>_Depend_ListInstallUnsolved

; ---------------------------------------------------------------------------------------------
; Use install-order and assign the lines where the mod is mentioned in the [connections]-section
; ---------------------------------------------------------------------------------------------
Func _Depend_PrepareBuildIndex($p_Array, $p_Select)
	Local $Return[9999][4], $OldSetup
	For $a=1 to $p_Select[0][0]
		If $p_Select[$a][2] <> $OldSetup Then
			$Return[0][0]+=1
			$Return[$Return[0][0]][1]=$p_Select[$a][2]; setup
			$OldSetup = $p_Select[$a][2]
		Else
			ContinueLoop
		EndIf
	Next
	Local $Setups=$g_Setups
	$Index=_IniCreateIndex($Setups)
	ReDim $Return[$Return[0][0]+1][4]
	For $a=1 to $p_Array[0][0]; Create a shortened list of affected mods by removing components
		$p_Array[$a][0]='|'&StringRegExpReplace(StringRegExpReplace(StringRegExpReplace($p_Array[$a][1], '\A.+?\x3a', ''), '\x28[^\x29]*\x29', ''), '\x3a|\x26|\x3e', '|')&'|' ; 28/29=(), :|&|>
		$Test=StringRegExp($p_Array[$a][0], '\x7c', 3)
		$p_Array[$a][1]=UBound($Test)-1
	Next
	For $a=1 to $p_Array[0][0]; Create a shortened list of affected mods by removing components
		$Mods=StringSplit($p_Array[$a][0], '|')
		For $m=1 to $Mods[0]
			If $Mods[$m]='' Then ContinueLoop
			$StartIdx=$Index[Asc(StringLower(StringLeft($Mods[$m], 1)))]
			$Found=0
			For $s=$StartIdx To $Setups[0][0]
				If $Setups[$s][0] = $Mods[$m] Then
					$Setups[$s][2]&='|'&$a
					$Found=1
					ExitLoop
				EndIf
			Next
			If $Found=0 Then ConsoleWrite('!'&$Mods[$m]&@CRLF)
		Next
		If StringInStr($p_Array[$a][0], '||') Then ConsoleWrite('!'&$p_Array[$a][0]& ' == ' & $p_Array[$a][1] &@CRLF)
	Next
	; goal is to identify connections (or better their index number) that may be connected to a mod into $Return[$r][2]
	For $r=1 to $Return[0][0]
		GUICtrlSetData($g_UI_Interact[9][1], 20*$r/$Return[0][0]); update the progress bar
		If _MathCheckDiv($r, 10) = 2 Then GUICtrlSetData($g_UI_Static[9][2], Round(20*$r/$Return[0][0], 0) & ' %'); update progress text
		$Lines=''
		$StartIdx=$Index[Asc(StringLower(StringLeft($Return[$r][1], 1)))]
		For $s=$StartIdx To $Setups[0][0]
			If $Setups[$s][0] = $Return[$r][1] Then
				$Return[$r][2]=StringRegExpReplace($Setups[$s][2], '\A\x7c', '')
				ExitLoop
			EndIf
		Next
	Next
	Return $Return
EndFunc   ;==>_Depend_PrepareBuildIndex

; ---------------------------------------------------------------------------------------------
; Build resize [Connections]-array and append the sentences that are displayed for each line
; ---------------------------------------------------------------------------------------------
Func _Depend_PrepareBuildSentences($p_Array)
	Local $Message = IniReadSection($g_TRAIni, 'DP-BuildSentences')
	Local $Array, $LastMod='', $Return = $p_Array
	ReDim $Return[$Return[0][0]+1][5]
	For $r=1 to $Return[0][0]
		If StringMid($Return[$r][1], 2, 1) = 'W' Then;Strip warning character
			$Return[$r][1]=StringLeft($Return[$r][1], 1)&StringMid($Return[$r][1], 3)
			$Return[$r][4]=1
		EndIf
		If StringLeft($Return[$r][1], 1) = 'C' Then
			$String=StringTrimLeft($Return[$r][1], 2)
			$LastConflict=-1
			$Number=StringRegExp($String, '\x3e', 3)
			$Number=UBound($Number)-1
			If $Number >0 Then
				$LastConflict = StringInStr($String, '>', 1, -1)
			EndIf
		Else
			$String=StringTrimLeft($Return[$r][1], 2)
			$LastConflict=-1
			$Number=UBound(StringRegExp($String, '(\x29\x7c)', 3))-1
			If $Number >0 Then
				$LastConflict = StringInStr($String, ')|', 1, -1)+1
			Else
				$Number=UBound(StringRegExp($String, '\x26', 3))-1
				If $Number >0 Then $LastConflict = StringInStr($String, '&', 1, -1)
			EndIf
		EndIf
		$Array=StringSplit($String, '')
		$Current=''
		$FirstConflict=0
		$Mod=0
		For $a=1 to $Array[0]
			If $Array[$a] = ':' And StringLeft($Return[$r][1], 1) = 'C' Then
				If $FirstConflict = 0 Then
					$Current&=' '&_GetTR($Message, 'L5')&' '; => is preferred
				Else
					$Current&=' '&_GetTR($Message, 'L6')&' '; => and
				EndIf
				$FirstConflict=1
			ElseIf $Array[$a] = ':' Then
				If $Mod = 1 Then
					$Current&=' '&_GetTR($Message, 'L1')&' '; => needs
				Else
					$Current&=' '&_GetTR($Message, 'L2')&' '; => need
				EndIf
			ElseIf $Array[$a] = '(' Then
				$Mod+=1
				$Comp = ''
				While $Array[$a] <> ')'
					$a+=1
					$Comp&=$Array[$a]
				WEnd
				$Number=StringRegExp($Comp, '\x7c', 3)
				$Number=UBound($Number)-1
				If $Number >=0 Then
					If $Number > 0 Then $Comp=StringReplace($Comp, '|' , ', ', $Number)
					$Comp=StringReplace($Comp, '|' , ' '&_GetTR($Message, 'L3')&' '); => or
				EndIf
				If $Comp <> '-)' Then $Current&=' ('&_GetTR($Message, 'L4')&' '&$Comp; => is
			ElseIf $Array[$a] = '>' Then
				If $FirstConflict = 0 Then
					$Current&=' '&_GetTR($Message, 'L5')&' '; => is preferred (part I)
					$FirstConflict = 1
				Else
					If $a=$LastConflict Then
						$Current&=' '&_GetTR($Message, 'L6')&' '; => and
					Else
						$Current&=', '
					EndIf
				EndIf
			ElseIf $Array[$a] = '|' Then
				If $LastConflict <> -1 Then
					If $a=$LastConflict Then
						$Current&=' '&_GetTR($Message, 'L3')&' '; => or
					Else
						$Current&=', '
					EndIf
				Else
					$Current&=' '&_GetTR($Message, 'L3')&' '; => or
				EndIf
			ElseIf $Array[$a] = '&' Then
				If $LastConflict <> -1 Then
					If $a=$LastConflict Then
						$Current&=' '&_GetTR($Message, 'L6')&' '; => and
					Else
						$Current&=', '
					EndIf
				Else
					$Current&=' '&_GetTR($Message, 'L6')&' '; => and
				EndIf
			Else
				$Current&=$Array[$a]
			EndIf
		If $a = $Array[0] Then
			If StringInStr($String, '&') And Not StringInStr($String, ':') Then
				$Current&=' '&_GetTR($Message, 'L7'); => are installed togther
			ElseIf StringLeft($Return[$r][1], 1) = 'C' Then
				If _GetTR($Message, 'L8') <> '.' Then $Current&=' '&_GetTR($Message, 'L8'); => is preferred (part II)
			EndIf
			$Return[$r][2]=$Current&'.'
		EndIf
		Next
	Next
	Return $Return
EndFunc   ;==>_Depend_PrepareBuildSentences

; ---------------------------------------------------------------------------------------------
; Replace multiple numbers in brackets
; ---------------------------------------------------------------------------------------------
Func _Depend_PrepareToUseID($p_Array)
	For $p=1 to $p_Array[0][0]
		$Bracket=StringRegExp($p_Array[$p][1], '\x28[^\x29]*\x29', 3)
		If Not IsArray($Bracket) Then
			$p_Array[$p][3]=$p_Array[$p][1]
			ContinueLoop
		EndIf
		For $b=0 To UBound($Bracket)-1
			$Sign=StringRegExp($Bracket[$b], '\x7c|\x26', 3)
			If Not IsArray($Sign) Then ContinueLoop
			$a=StringInStr($p_Array[$p][1], $Bracket[$b])-1
			Local $Mod='', $String='', $s=-1
			$Array=StringSplit($p_Array[$p][1], '')
			While Not StringRegExp($Array[$a], '\x3a|\x3e|\x7c|\x26') ; Get the :>|&
				$Mod=$Array[$a]&$Mod
				$a-=1
			WEnd
			$Num=StringSplit(StringRegExpReplace($Bracket[$b], '\A.|.\z', ''), '|&')
			For $n=1 to $Num[0]
				If $n<> 1 Then
					$s+=1
					$String&=$Sign[$s]&$Mod
				EndIf
				$String&='('&$Num[$n]&')'
			Next
			$p_Array[$p][1]=StringReplace($p_Array[$p][1], $Bracket[$b], $String, 1)
		Next
		$p_Array[$p][3]=$p_Array[$p][1]
	Next
	Return $p_Array
EndFunc   ;==>_Depend_PrepareToUseID

; ---------------------------------------------------------------------------------------------
; Remove some mods or components from the current-section
; ---------------------------------------------------------------------------------------------
Func _Depend_RemoveFromCurrent($p_Array, $p_Comp=1)
	Local $String
	If Not IsArray($p_Array) Then Return
	For $a=1 to $p_Array[0][0]
		If $p_Array[$a][0]=''  Then ContinueLoop
		$p_Array[$a][1]=String($p_Array[$a][1])
		If $p_Comp = 0 Then $p_Array[$a][1]=''; force to remove the whole mod
		FileWrite($g_LogFile, 'Removing ' & $p_Array[$a][0] &' #' & $p_Array[$a][1] & @CRLF)
		If $p_Array[$a][1] = '' Then
			$Return=IniRead($g_UsrIni, 'RemovedFromCurrent', $p_Array[$a][0], '')
			IniWrite($g_UsrIni, 'RemovedFromCurrent', $p_Array[$a][0], $Return&' '&IniRead($g_UsrIni, 'Current', $p_Array[$a][0], '')); add to mods that are listed as not installed
			IniDelete($g_UsrIni, 'Current', $p_Array[$a][0]); remove from current list of mods to install
			IniDelete($g_BWSIni, 'Faults', $p_Array[$a][0]); remove faults
			$String&='|'&$p_Array[$a][0]
			$File=_Test_GetCustomTP2($p_Array[$a][0]); remove mods that are uninstallable
			If FileExists($File) Then FileMove($File, $File&'.dlt', 1)
		Else
			$Return=IniRead($g_UsrIni, 'RemovedFromCurrent', $p_Array[$a][0], '')
			If StringRegExp($Return, '(\A|\s)'&$p_Array[$a][1]&'(\s|\z)', ' ') = 0 Then $Return&=' '&$p_Array[$a][1]; add component if not included
			IniWrite($g_UsrIni, 'RemovedFromCurrent', $p_Array[$a][0], $Return)
			$Return=IniRead($g_UsrIni, 'Current', $p_Array[$a][0], '')
			$Return=StringStripWS(StringRegExpReplace($Return, '(\A|\s)'&$p_Array[$a][1]&'(\s|\z)', ' '), 3)
			If $Return = '' Then; remove entry or write new value of mod
				IniDelete($g_UsrIni, 'Current', $p_Array[$a][0])
				$String&='|'&$p_Array[$a][0]
			Else
				IniWrite($g_UsrIni, 'Current', $p_Array[$a][0], $Return)
				_Tree_Purge(0, $p_Array[$a][0], $p_Array[$a][1])
			EndIf
		EndIf
	Next
	_Tree_Purge(0, StringTrimLeft($String, 1)); remove entire pending mods
EndFunc   ;==>_Depend_RemoveFromCurrent

; ---------------------------------------------------------------------------------------------
; this function displays and handles the UI for the 'resolve conflicts and dependencies' screen
; checks the mods from the connections-array (Select-GUILoop calls this when leaving tree-view)
;   p_Solve = auto-solve (deactivate) conflict losers and missing dependencies first?
;       this option is currently not used anywhere in BWS
; ---------------------------------------------------------------------------------------------
Func _Depend_ResolveGui($p_Solve=0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Depend_ResolveGui')
	_Depend_GetActiveConnections()
	If $p_Solve = 1 Then
		_Depend_AutoSolve('C', 2, 1); disable all conflict losers (but skip warning rules)
		_Depend_AutoSolve('DS', 2, 1); disable mods/components with missing dependencies (but skip warning rules)
	EndIf
	If $g_ActiveConnections[0][0] <> 0 Then _Misc_SetTab(10); dependencies-tab
	$g_Flags[16] = 0
	While 1
		If $g_ActiveConnections[0][0] = 0 Then
			_Misc_SetTab(2); back to folder-tab
			Return 1
		EndIf
		$aMsg = GUIGetMsg()
		If $g_Flags[16]=1 Then _Depend_Contextmenu()
		Switch $aMsg
			Case $g_UI_Button[0][3]; exit
				Exit
			Case $Gui_Event_Close
				Exit
			Case $g_UI_Button[10][1]; autosolve both dependencies and conflicts, not including warnings
				_Depend_AutoSolveWarning(3)
			Case $g_UI_Button[10][2]; autosolve conflicts
				_Depend_AutoSolveWarning(1)
			Case $g_UI_Button[10][3]; autosolve dependencies
				_Depend_AutoSolveWarning(2)
			Case $g_UI_Button[10][4]; help on/off
				_Depend_ToggleHelp()
			Case $g_UI_Button[0][2]; continue: autosolve both dependencies and conflicts, including warnings
				_Depend_AutoSolveWarning(4, 1)
			Case $g_UI_Button[0][1]; cancel
				_Misc_SetTab(4); advsel-tab
				Return 0
		EndSwitch
		Sleep(10)
	WEnd
EndFunc   ;==>_Depend_ResolveGui

; ---------------------------------------------------------------------------------------------
; Force a state on items in a certain "connection-group" $p_State: 1=select, 2=deselect
; ---------------------------------------------------------------------------------------------
Func _Depend_SetGroupByNumber($p_Num, $p_State, $p_Skip='')
	Local $GroupID
	If $p_Skip <> '' Then
		For $a=1 to $g_ActiveConnections[0][0]
			If $g_ActiveConnections[$a][2] <> $p_Skip Then ContinueLoop
			$GroupID = $g_ActiveConnections[$a][3]; look if item is part of a group
			ExitLoop
		Next
	EndIf
	For $a=1 to $g_ActiveConnections[0][0]
		If $g_ActiveConnections[$a][1] <> $p_Num Then ContinueLoop
		If $GroupID <> '' And $GroupID = $g_ActiveConnections[$a][3] Then ContinueLoop; keep items of the same group
		If $p_Skip <> '' And $p_Skip = $g_ActiveConnections[$a][2] Then ContinueLoop
		If $g_ActiveConnections[$a][0] = 'DO' And $g_ActiveConnections[$a][3] = 1 Then ContinueLoop
		_Depend_SetModState($g_ActiveConnections[$a][2], $p_State)
		;ConsoleWrite(@ScriptLineNumber & ': '&$g_CentralArray[$g_ActiveConnections[$a][2]][0] & ' - ' & $g_CentralArray[$g_ActiveConnections[$a][2]][2] & ' - ' & $p_State & @CRLF)
		;ConsoleWrite($g_ActiveConnections[$a][0] & ' - ' &$g_ActiveConnections[$a][1] & ' - ' &$g_ActiveConnections[$a][2] & ' - ' &$g_ActiveConnections[$a][3] &  @CRLF)
	Next
EndFunc   ;==>_Depend_SetGroupByNumber

; ---------------------------------------------------------------------------------------------
; Activate or deactivate all parts of a mod (returns 1 if success, 0 if state change failed)
;   p_State = 1 (enable) or 2 (disable)
; ---------------------------------------------------------------------------------------------
Func _Depend_SetModState($p_ControlID, $p_State)
	_AI_SetClicked($p_ControlID, $p_State)
	;ConsoleWrite(@ScriptLineNumber & ': '&$g_CentralArray[$p_ControlID][0] & ' - ' & $g_CentralArray[$p_ControlID][2] & ' - ' & $p_State & @CRLF)
	If $g_CentralArray[$p_ControlID][2] = '-' Then
		If $g_CentralArray[$p_ControlID][13] <> '' Then
			$Splitted=StringSplit($g_CentralArray[$p_ControlID][13], ',')
			For $s=1 to $Splitted[0]
				_AI_SetClicked($Splitted[$s], $p_State)
				;ConsoleWrite(@ScriptLineNumber & ': '&$g_CentralArray[$Splitted[$s]][0] & ' - ' & $g_CentralArray[$Splitted[$s]][2] & ' - ' & $p_State & @CRLF)
			Next
		EndIf
	EndIf
	If $p_State = 1 And $g_CentralArray[$p_ControlID][9] = 0 Then; failed to activate
		_PrintDebug('ERROR! Unable to activate ' & $g_CentralArray[$p_ControlID][4] & '(' & $g_CentralArray[$p_ControlID][3] & ')' & @CRLF, 1); mod name(component name or - for entire mod)
		Return 0
	ElseIf $p_State = 2 And $g_CentralArray[$p_ControlID][9] <> 0 Then; failed to deactivate
		_PrintDebug('ERROR! Unable to deactivate ' & $g_CentralArray[$p_ControlID][4] & '(' & $g_CentralArray[$p_ControlID][3] & ')' & @CRLF, 1); mod name(component name or - for entire mod)
		Return 0
	EndIf
	Return 1
EndFunc   ;==>_Depend_SetModState

; ---------------------------------------------------------------------------------------------
; Remove all items that have problems with a specific item or setup. Invert is possible.
; ---------------------------------------------------------------------------------------------
Func _Depend_SolveConflict($p_Setup, $p_State, $p_Type=0)
	Local $GroupID
	For $a=1 to $g_ActiveConnections[0][0]
		If $p_Type = 0 Then $Test = $g_ActiveConnections[$a][2]
		If $p_Type = 1 Then $Test = $g_CentralArray[$g_ActiveConnections[$a][2]][0]
		If $Test = $p_Setup Then
			If $g_ActiveConnections[$a][0] <> 'C' Then ContinueLoop
			$n=$a
			$GroupID = $g_ActiveConnections[$a][3]
			While $g_ActiveConnections[$n][1]=$g_ActiveConnections[$a][1]; get the beginning of the conflict
				$n-=1
			WEnd
			While 1
				$n+=1
				If $g_ActiveConnections[$n][1]<>$g_ActiveConnections[$a][1] Then ExitLoop; continue to the next possible step or exit
				If $p_Type = 0 Then $Test = $g_ActiveConnections[$n][2]
				If $p_Type = 1 Then $Test = $g_CentralArray[$g_ActiveConnections[$n][2]][0]
				If $p_State = 1 Then
					If $GroupID <> '' And $GroupID = $g_ActiveConnections[$n][3] Then ContinueLoop
					If $Test <> $p_Setup Then _Depend_SetModState($g_ActiveConnections[$n][2], 2); remove the item if it is not the setup itself
					;If $Test <> $p_Setup Then ConsoleWrite(@ScriptLineNumber & ': '&$g_CentralArray[$g_ActiveConnections[$n][2]][0] & ' - ' & $g_CentralArray[$g_ActiveConnections[$n][2]][2] & ' - ' & $p_State & @CRLF)
				Else
					If $Test = $p_Setup Then _Depend_SetModState($g_ActiveConnections[$n][2], 2); remove the item if it is the setup itself
					;If $Test = $p_Setup Then ConsoleWrite(@ScriptLineNumber & ': '&$g_CentralArray[$g_ActiveConnections[$n][2]][0] & ' - ' & $g_CentralArray[$g_ActiveConnections[$n][2]][2] & ' - ' & $p_State & @CRLF)
				EndIf
			WEnd
		EndIf
	Next
EndFunc   ;==>_Depend_SolveConflict

; ---------------------------------------------------------------------------------------------
; Switch help on / off on depend tab
; ---------------------------------------------------------------------------------------------
Func _Depend_ToggleHelp()
	$Pos=ControlGetPos($g_UI[0], '', $g_UI_Interact[10][1])
	$State=GUICtrlGetState($g_UI_Interact[10][2])
	If BitAND($State, $GUI_HIDE) Then
		GUICtrlSetPos($g_UI_Interact[10][1], 15, 100, $Pos[2]-305, $Pos[3])
		GUICtrlSetPos($g_UI_Button[10][4], $Pos[2]-290, 100, 15, $Pos[3])
		GUICtrlSetState($g_UI_Interact[10][2], $GUI_SHOW)
		GUICtrlSetData($g_UI_Button[10][4], '>')
	Else
		GUICtrlSetPos($g_UI_Interact[10][1], 15, 100, $Pos[2]+305, $Pos[3])
		GUICtrlSetPos($g_UI_Button[10][4], $Pos[2]+320, 100, 15, $Pos[3])
		GUICtrlSetState($g_UI_Interact[10][2], $GUI_HIDE)
		GUICtrlSetData($g_UI_Button[10][4], '<')
	EndIf
	$Pos=ControlGetPos($g_UI[0], '', $g_UI_Interact[10][1])
	_GUICtrlListView_SetColumnWidth($g_UI_Handle[1], 0, Floor($Pos[2]/2)-5)
	_GUICtrlListView_SetColumnWidth($g_UI_Handle[1], 1, Floor($Pos[2]/2))
EndFunc   ;==>_Depend_ToggleHelp

; ---------------------------------------------------------------------------------------------
; Removes lines which contain component-numbers / which are only used in BWS-installs
; ---------------------------------------------------------------------------------------------
Func _Depend_TrimBWSConnections()
	Local $Return[$g_Connections[0][0]+1][2]
	For $c=1 to $g_Connections[0][0]
		If StringRegExp($g_Connections[$c][1], '\x28[1234567890\x7c]*\x29') = 1 Then ContinueLoop
		$Return[0][0]+=1
		$Return[$Return[0][0]][0]=$g_Connections[$c][0]
		$Return[$Return[0][0]][1]=$g_Connections[$c][1]
	Next
	ReDim $Return[$Return[0][0]+1][2]
	$g_Connections=$Return
EndFunc   ;==>_Depend_TrimBWSConnections

; ---------------------------------------------------------------------------------------------
; Create a contextmenu for the selected listview-item (got it from the helpfile)
; ---------------------------------------------------------------------------------------------
Func _Depend_WM_Notify($p_Handle, $iMsg, $iwParam, $ilParam)
	#forceref $p_Handle, $iMsg, $iwParam
	Local $HandleFrom, $iIDFrom, $iCode, $tNMHDR, $tInfo
	$tNMHDR = DllStructCreate($tagNMHDR, $ilParam)
	$HandleFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
	$iIDFrom = DllStructGetData($tNMHDR, "IDFrom")
	$iCode = DllStructGetData($tNMHDR, "Code")
	Switch $HandleFrom
		Case $g_UI_Handle[1]
			Switch $iCode
				Case $NM_RCLICK ; Sent by a list-view control when the user clicks an item with the right mouse button
					$g_Flags[16] = 1; enable the building of menu-entries now
					$tInfo = DllStructCreate($tagNMITEMACTIVATE, $ilParam)
					$Index = DllStructGetData($tInfo, "Index"); get the zero-based index
					$g_UI_Menu[0][6] = GUICtrlRead($g_UI_Interact[10][1], $Index); get the handle
					$g_UI_Menu[0][7] = $g_ActiveConnections[$Index + 1][0]; type
					$g_UI_Menu[0][8] = $g_ActiveConnections[$Index + 1][1]; num
					$g_UI_Menu[0][9] = $g_ActiveConnections[$Index + 1][2]; setup
					$String=$g_Connections[$g_UI_Menu[0][8]][0]&': '&$g_Connections[$g_UI_Menu[0][8]][2]
					If $g_Connections[$g_UI_Menu[0][8]][4]=1 Then $String=_GetTR($g_UI_Message, '10-L2')&': '&$String; => notice
					GUICtrlSetData($g_UI_Interact[10][3], $String)
				Case $NM_CLICK ; Sent by a list-view control when the user clicks an item with the left mouse button
					$tInfo = DllStructCreate($tagNMITEMACTIVATE, $ilParam)
					$Index = DllStructGetData($tInfo, "Index"); get the zero-based index
					$Index = $g_ActiveConnections[$Index + 1][1]; num
					$String=$g_Connections[$Index][0]&': '&$g_Connections[$Index][2]
					If $g_Connections[$Index][4]=1 Then $String=_GetTR($g_UI_Message, '10-L2')&': '&$String; => notice
					GUICtrlSetData($g_UI_Interact[10][3], $String)
				Case $LVN_KEYDOWN ; A key has been pressed
					Local $Diff = '-'
					$tInfo = DllStructCreate($tagNMLVKEYDOWN, $ilParam)
					If DllStructGetData($tInfo, "VKey") = '21495846' Then; Up was pressed
						$Diff = ''
					ElseIf DllStructGetData($tInfo, "VKey") = '22020136' Then; Down was pressed
						$Diff = 2
					ElseIf DllStructGetData($tInfo, "VKey") = '22151213' Then; Insert was pressed
						$Index = ControlListView($g_UI[0], '', $g_UI_Interact[10][1], 'GetSelected')+1
						_Depend_SetModState($g_ActiveConnections[$Index][2], 1); item or mod: remove
						_Depend_GetActiveConnections()
					ElseIf DllStructGetData($tInfo, "VKey") = '22216750' Then; Delete was pressed
						$Index = ControlListView($g_UI[0], '', $g_UI_Interact[10][1], 'GetSelected')+1
						_Depend_SetModState($g_ActiveConnections[$Index][2], 2); item or mod: remove
						_Depend_GetActiveConnections()
					EndIf
					If $Diff = '-' Then Return $GUI_RUNDEFMSG; no up/down
					$Index = ControlListView($g_UI[0], '', $g_UI_Interact[10][1], 'GetSelected')+$Diff
					If $Index = '' Then Return $GUI_RUNDEFMSG; nothing selected
					If $Index >  $g_ActiveConnections[0][0] Then Return $GUI_RUNDEFMSG; down @ last item = no update
					$Index = $g_ActiveConnections[$Index][1]; num
					$String=$g_Connections[$Index][0]&': '&$g_Connections[$Index][2]
					If $g_Connections[$Index][4]=1 Then $String=_GetTR($g_UI_Message, '10-L2')&': '& $String; => notice
					GUICtrlSetData($g_UI_Interact[10][3], $String)
			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>_Depend_WM_Notify