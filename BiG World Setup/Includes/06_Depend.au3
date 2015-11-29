#include-once

; Note that you have to edit the functions when doing changes:
; _Depend_AutoSolve => solve problems right from start or in the dependency/connections-screen
; _Depend_Contextmenu => start solving the problems in the dependency/connections-screen
; _Depend_GetActiveConnections => build the list for the dependency/connections-screen after the selection

; _Depend_GetUnsolved => list mods that cannot be installed due to missing mods during download, extraction and installation
; _Depend_ListInstallConflicts => list mods that have conflicts during download, extraction and installation
; _Depend_ListInstallUnsolved => list mods that have open dependencies during download, extraction and installation

; Not used items from g_CentralArray: 5 - 6 - 7 - 8 - 11 - 12 - 14 - 15

;~ $g_Connections contains: 0: inikey (A conflicts b)- 1: inivalue (C:A(-):B(-))- 2: converted sentence (A is preffered to B)- 3: IDs(C:312:645) - 4: Warning (0/1)

; ---------------------------------------------------------------------------------------------
; Automatically solve the dependencies and conflicts (used before and after selection)
; ---------------------------------------------------------------------------------------------
Func _Depend_AutoSolve($p_Type, $p_State)
	Local $Num, $Number, $Return[5000][4]
	While 1
		$Restart=0
		$Progress=Round(($g_Flags[23]-$g_ActiveConnections[0][0])*100/$g_Flags[23], 0)
		GUICtrlSetData($g_UI_Interact[9][1], $Progress)
		GUICtrlSetData($g_UI_Static[9][2], $Progress &  ' %')
		For $a=1 to $g_ActiveConnections[0][0]
			If $g_ActiveConnections[$a][0] <> $p_Type Then ContinueLoop
			$Num=$g_ActiveConnections[$a][1]
			$Number=$g_ActiveConnections[$a][3]
			If $p_Type <> 'C' Then $a-=1
			While 1
				$a+=1
				If $a > $g_ActiveConnections[0][0] Then ExitLoop
				If $Number <> '' And $Number=$g_ActiveConnections[$a][3] Then ContinueLoop
				If $p_Type <> $g_ActiveConnections[$a][0] Then ContinueLoop; skip other types
				If $Num <> $g_ActiveConnections[$a][1] Then
					$a-=1
					ExitLoop; exit if case / problem was left
				EndIf
				_Depend_SetModState($g_ActiveConnections[$a][2], $p_State)
				;ConsoleWrite($g_CentralArray[$g_ActiveConnections[$a][2]][0] & ' ' & $g_CentralArray[$g_ActiveConnections[$a][2]][2] & @CRLF)
				$Return[0][0]+=1
				$Return[$Return[0][0]][0]=$g_CentralArray[$g_ActiveConnections[$a][2]][0]
				$Return[$Return[0][0]][2]=$g_CentralArray[$g_ActiveConnections[$a][2]][4]
				If $g_CentralArray[$g_ActiveConnections[$a][2]][2] <> '-' Then
					$Return[$Return[0][0]][1]=$g_CentralArray[$g_ActiveConnections[$a][2]][2]
					$Return[$Return[0][0]][3]=$g_CentralArray[$g_ActiveConnections[$a][2]][3]
				EndIf
				$Restart=1
				If $p_Type = 'DO' Then ExitLoop; only one of the possible dependencies is needed
			WEnd
			If $Restart = 1 Then
				_Depend_GetActiveConnections(0)
				ExitLoop
			EndIf
		Next
		If $Restart = 0 Then ExitLoop
		For $r = 1 to $Return[0][0]
			If $Return[$r][1] = '' Then ExitLoop; Prevent crashes...
		Next
	WEnd
	ReDim $Return[$Return[0][0]+1][4]
	If $Return[0][0] = 0 Then Return $Return
	_Depend_CreateSortedOutout($Return)
	Return $Return
EndFunc   ;==>_Depend_AutoSolve

; ---------------------------------------------------------------------------------------------
; show the mods that would be removed. Reload saved settings if desired
; ---------------------------------------------------------------------------------------------
Func _Depend_AutoSolveWarning($p_Type, $p_Force=0)
	Local $Message = IniReadSection($g_TRAIni, 'DP-Msg')
	Local $Return, $Output = ''
	_Tree_GetCurrentSelection(1); remove conflicts
	If StringInStr($p_Type, 1) Then
		$Return=_Depend_AutoSolve('C', 2)
		If $Return[0][1] <> '' Then $Output &= _GetTR($Message, 'L3') & @CRLF & $Return[0][1] & @CRLF & @CRLF; => item will be removed
	EndIf
	If StringInStr($p_Type, 2) Then; add open dependencies
		$Test = $g_Compilation
		$g_Compilation = 'E'
		$Return=_Depend_AutoSolve('DM', 1)
		If $Return[0][1] <> '' Then $Output &= _GetTR($Message, 'L4') & @CRLF & $Return[0][1] & @CRLF & @CRLF; => mod will be added
		$Return=_Depend_AutoSolve('DO', 1)
		If $Return[0][1] <> '' Then $Output &= _GetTR($Message, 'L4') & @CRLF & $Return[0][1] & @CRLF & @CRLF; => mod will be added
		$g_Compilation = $Test
	EndIf
	If StringInStr($p_Type, 3) Then; remove mods that are missing something
		$Return=_Depend_AutoSolve('DS', 2)
		If Not StringInStr($p_Type, 1) Then $Output &= _GetTR($Message, 'L3') & @CRLF; => mod will be removed
		If $Return[0][1] <> '' Then $Output &= $Return[0][1] & @CRLF & @CRLF
	EndIf
	If StringInStr($p_Type, 1) And StringInStr($p_Type, 2) Then; remove conflicts if dependencies were added
		$Return=_Depend_AutoSolve('C', 2)
		If $Return[0][1] <> '' Then $Output &= _GetTR($Message, 'L3') & @CRLF & $Return[0][1] & @CRLF & @CRLF; => mod will be removed
	EndIf
	If $Output <> '' Then
		$Output &= _GetTR($Message, 'L5'); => proceed or go back?
		If $p_Force = 1 Then $Output =  _GetTR($Message, 'L6')&@CRLF&$Output; => autosolve forced
		$Answer = _Misc_MsgGUI(2, _GetTR($g_UI_Message, '0-T1'), $Output, 2, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2')); => ok to continue with this results?
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
; ---------------------------------------------------------------------------------------------
Func _Depend_CreateSortedOutout(ByRef $p_Array)
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
EndFunc   ;==>_Depend_CreateSortedOutout

; ---------------------------------------------------------------------------------------------
; Add entries to the array of active problems
; ---------------------------------------------------------------------------------------------
Func _Depend_GetActiveAddItem($p_Type, $p_Num, $p_Setup, $p_ID=0)
	$g_ActiveConnections[0][0]+=1
	$g_ActiveConnections[$g_ActiveConnections[0][0]][0]=$p_Type
	$g_ActiveConnections[$g_ActiveConnections[0][0]][1]=$p_Num
	$g_ActiveConnections[$g_ActiveConnections[0][0]][2]=$p_Setup
	$g_ActiveConnections[$g_ActiveConnections[0][0]][3]=$p_ID
EndFunc   ;==>_Depend_GetActiveAddItem

; ---------------------------------------------------------------------------------------------
; Display all conflicts and depencies as needed (used during selection)
; ---------------------------------------------------------------------------------------------
Func _Depend_GetActiveConnections($p_Show=1)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Depend_GetActiveConnections')
	Local $Mod, $Comp
	Global $g_ActiveConnections[999][4]
	$g_ActiveConnections[0][0] = 0
	If $p_Show=1 Then _GUICtrlListView_BeginUpdate($g_UI_Handle[1])
	If $p_Show=1 Then _GUICtrlListView_DeleteAllItems($g_UI_Handle[1])
	For $c = 1 To $g_Connections[0][0]; loop through array
		If StringLeft ($g_Connections[$c][3], 1) = 'W' Then; ignore warnings

		ElseIf StringLeft ($g_Connections[$c][3], 1) = 'D' Then; dependencies first
			$String=StringTrimLeft($g_Connections[$c][3], 2)
			If Not StringInStr($String, ':') Then; all items are needed
				_Depend_GetActiveDependAll($String, $c, $p_Show)
			Else; some items need some other
				_Depend_GetActiveDependAdv($String, $c, $p_Show)
			EndIf
		Else; conflicts
			$String=StringTrimLeft($g_Connections[$c][3], 2)
			If StringInStr($String, ':') Then; This is an advanced conflict
				_Depend_GetActiveConflictAdv($String, $c, $p_Show)
			Else; this is a normal conflict
				_Depend_GetActiveConflictStd($String, $c, $p_Show)
			EndIf
		EndIf
	Next
	If $p_Show=1 Then _GUICtrlListView_EndUpdate($g_UI_Handle[1])
EndFunc   ;==>_Depend_GetActiveConnections

; ---------------------------------------------------------------------------------------------
; See if a component is installed that needs all other listed components
; ---------------------------------------------------------------------------------------------
Func _Depend_GetActiveDependAll($p_String, $p_ID, $p_Show)
	$Return=_Depend_ItemGetSelected($p_String)
	If $Return[0][1] = 0 or $Return[0][1] = $Return[0][0] Then Return; nothin selected or all selected
	$Prefix = ''
	$Warning = ''
	If $g_Connections[$p_ID][4]=1 Then $Warning=' **'
	For $r=1 to $Return[0][0]; show selected items first
		If $Return[$r][1]=1 Then
			If $p_Show=1 Then GUICtrlCreateListViewItem($Prefix&$g_CentralArray[$Return[$r][0]][4]&$Warning & '|' & $g_CentralArray[$Return[$r][0]][3], $g_UI_Interact[10][1])
			_Depend_GetActiveAddItem('DS', $p_ID, $Return[$r][0])
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
			_Depend_GetActiveAddItem('DM', $p_ID, $Return[$r][0])
			If $p_Show=1 Then GUICtrlSetBkColor(-1, 0xFFA500)
			If $Prefix='' Then $Prefix='+ '
		EndIf
	Next
EndFunc    ;==>_Depend_GetActiveDependAll

; ---------------------------------------------------------------------------------------------
; See if a component is installed that needs another listed components
; ---------------------------------------------------------------------------------------------
Func _Depend_GetActiveDependAdv($p_String, $p_ID, $p_Show)
	$p_String=StringSplit($p_String, ':')
	$Test=_Depend_ItemGetSelected($p_String[1])
	If $Test[0][1] = 0 Then Return; nothing was selected
	If StringInStr($p_String[1], '&') And $Test[0][1] <> $Test[0][0] Then Return; "&" means that all items require one. If that's not matched, the compartibility-item is not needed
	$Return=_Depend_ItemGetSelected($p_String[2])
	If $Return[0][0] = $Return[0][1] Then Return; all possible items are selected which were needed
	If StringInStr($p_String[2], '|') And $Return[0][1] <> 0 Then Return; "|" means that one item is needed. If selected is above 0, that's ok
	$Prefix = ''
	$Warning = ''
	If $g_Connections[$p_ID][4]=1 Then $Warning=' *'
	For $t=1 to $Test[0][0]; show selected items in need first
		If $Test[$t][1]=1 Then
			If $p_Show=1 Then GUICtrlCreateListViewItem($Prefix&$g_CentralArray[$Test[$t][0]][4]&$Warning & '|' & $g_CentralArray[$Test[$t][0]][3], $g_UI_Interact[10][1])
			_Depend_GetActiveAddItem('DS', $p_ID, $Test[$t][0])
			If $Prefix='' Then $Prefix='+ '
		EndIf
	Next
	$Prefix = ''
	For $r=1 to $Return[0][0]; then show missing needed items
		If $Return[$r][1]=0 Then
			$Mod=$g_CentralArray[$Return[$r][0]][4]
			If $Mod = '' Then
				$Mod=_GetTR($g_UI_Message, '10-L1'); => removed due to translation
				$Comp=''
			Else
				$Comp=$g_CentralArray[$Return[$r][0]][3]
			EndIf
			If $p_Show=1 Then GUICtrlCreateListViewItem($Prefix&$Mod & '|' & $Comp, $g_UI_Interact[10][1])
			If $p_Show=1 Then GUICtrlSetBkColor(-1, 0xFFA500)
			If $Prefix='' And StringInStr($p_String[2], '|') Then; first of serveral possible items
				_Depend_GetActiveAddItem('DO', $p_ID, $Return[$r][0])
				$Prefix='/ '
			ElseIf $Prefix='/ ' Then; other possible items that are skipped when solving dependencies
				_Depend_GetActiveAddItem('DO', $p_ID, $Return[$r][0], 1)
			Else
				_Depend_GetActiveAddItem('DM', $p_ID, $Return[$r][0])
				If $Prefix='' Then $Prefix='+ '
			EndIf
		EndIf
	Next
EndFunc    ;==>_Depend_GetActiveDependAdv

; ---------------------------------------------------------------------------------------------
; See if a component is installed that has a conflict with a combination of other listed components
; ---------------------------------------------------------------------------------------------
Func _Depend_GetActiveConflictAdv($p_String, $p_ID, $p_Show)
	$p_String=StringSplit($p_String, ':')
	Local $Test[$p_String[0]+1][50]
	For $s=1 to $p_String[0]
		$Return=_Depend_ItemGetSelected($p_String[$s])
		For $r=1 to $Return[0][0]
			If StringInStr($p_String[$s], '&') And $Return[0][1] <> $Return[0][0] Then $r=$Return[0][0]; skip if all items are required and only one was selected
			If $Return[$r][1] = 1 Then
				$Test[$s][0]+=1
				$Test[$s][$Test[$s][0]]=$Return[$r][0]
			EndIf
		Next
		If $Test[$s][0]<> 0 Then $Test[0][0]+=1
	Next
	If $Test[0][0] <= 1 Then Return; no multiple conflicts were selected
	Local $IsConflict = 0
	$Warning = ''
	If $g_Connections[$p_ID][4]=1 Then $Warning=' *'
	For $s=1 to $p_String[0]
		If $Test[$s][0] <> 0 Then
			Local $Prefix = ''
			For $r=1 to $Test[$s][0]
				If $p_Show=1 Then GUICtrlCreateListViewItem($Prefix&$g_CentralArray[$Test[$s][$r]][4]&$Warning & '|' & $g_CentralArray[$Test[$s][$r]][3], $g_UI_Interact[10][1])
				_Depend_GetActiveAddItem('C', $p_ID, $Test[$s][$r], $s)
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
	$Return=_Depend_ItemGetSelected($p_String)
	If $Return[0][1] = 0 or $Return[0][1] = 1 Then Return
	$Warning = ''
	If $g_Connections[$p_ID][4]=1 Then $Warning=' *'
	For $r=1 to $Return[0][0]
		If $Return[$r][1]=1 Then
			If $p_Show=1 Then GUICtrlCreateListViewItem($g_CentralArray[$Return[$r][0]][4]&$Warning & '|' & $g_CentralArray[$Return[$r][0]][3], $g_UI_Interact[10][1])
			_Depend_GetActiveAddItem('C', $p_ID, $Return[$r][0])
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
; only list unsolved mods in the array & create some formated output
	_Depend_GetActiveConnections(0); fetch active connections
	If $g_ActiveConnections[0][0] <> 0 Then
		$Return=_Depend_AutoSolve('DS', 2); remove all mods and components that have an open dependency
		If $Return[0][1] <> '' Then
			For $r =1 to $Return[0][0]
				If StringInStr($String, '|'&$Return[$r][0]&'|') Then
					$Return[$r][0]=''; don't show those that are mssing - have already been displayed as they are in the faults-section
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
	If $Return[0][1] <> '' Then _Depend_CreateSortedOutout($Return)
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
; Just return an array with the items and wheather they are selected or not
; ---------------------------------------------------------------------------------------------
Func _Depend_ItemGetSelected($p_String, $p_Debug=0)
	If Not IsArray($p_String) Then
		$Array=StringSplit($p_String, ':|&>')
	Else
		$Array = $p_String
	EndIf
	Local $Return[$Array[0]+1][2]
	$Return[0][0]=$Array[0]
	For $a=1 to $Array[0]; loop
		$Return[$a][0]=$Array[$a]
		If StringInStr($Array[$a], ')') Then; if item is no number, it does not exist/is not available in this selection (being a foreign language)
			; so just keep this as not selected and continue
		ElseIf $g_CentralArray[$Array[$a]][2] <> '-' Then; check a component
			$Return[$a][1]=$g_CentralArray[$Array[$a]][9]
			$Return[0][1]+=$g_CentralArray[$Array[$a]][9]
		Else; check a mod
			If $g_CentralArray[$Array[$a]][9] > 0 Then; already selected, so no other tests are needed
				$Return[$a][1]=1
				$Return[0][1]+=1
			ElseIf 	$g_CentralArray[$Array[$a]][13] <> '' Then; the mod installed at different times during the installation
				$Splitted=StringSplit($g_CentralArray[$Array[$a]][13], ','); get the other possible selections and check them, too
				For $s=1 to $Splitted[0]
					If $g_CentralArray[$Splitted[$s]][9] > 0 Then
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
	Local $Return[1000][4], $OldSetup
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
		GUICtrlSetData($g_UI_Interact[9][1], 20*$r/$Return[0][0]); set the progress
		If _MathCheckDiv($r, 10) = 2 Then GUICtrlSetData($g_UI_Static[9][2], Round(20*$r/$Return[0][0], 0) & ' %')
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
; checks the mods from the connections-array
; ---------------------------------------------------------------------------------------------
Func _Depend_ResolveGui($p_Solve=0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Depend_ResolveGui')
	_Depend_GetActiveConnections()
	If $p_Solve = 1 Then
		_Depend_AutoSolve('C', 2)
		_Depend_AutoSolve('DS', 2)
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
			Case $g_UI_Button[10][1]; autosolve both dependencies and confilcts
				_Depend_AutoSolveWarning(3)
			Case $g_UI_Button[10][2]; autosolve confilcts
				_Depend_AutoSolveWarning(1)
			Case $g_UI_Button[10][3]; autosolve dependencies
				_Depend_AutoSolveWarning(2)
			Case $g_UI_Button[10][4]; help on/off
				_Depend_ToggleHelp()
			Case $g_UI_Button[0][2]; continue: force autosolve
				_Depend_AutoSolveWarning(13, 1)
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
	Local $Number
	If $p_Skip <> '' Then
		For $a=1 to $g_ActiveConnections[0][0]
			If $g_ActiveConnections[$a][2] <> $p_Skip Then ContinueLoop
			$Number = $g_ActiveConnections[$a][3]; look if item is part of a group
			ExitLoop
		Next
	EndIf
	For $a=1 to $g_ActiveConnections[0][0]
		If $g_ActiveConnections[$a][1] <> $p_Num Then ContinueLoop
		If $Number <> '' And $Number = $g_ActiveConnections[$a][3] Then ContinueLoop; keep items of the same group
		If $p_Skip <> '' And $p_Skip = $g_ActiveConnections[$a][2] Then ContinueLoop
		If $g_ActiveConnections[$a][0] = 'DO' And $g_ActiveConnections[$a][3] = 1 Then ContinueLoop
		_Depend_SetModState($g_ActiveConnections[$a][2], $p_State)
		;ConsoleWrite(@ScriptLineNumber & ': '&$g_CentralArray[$g_ActiveConnections[$a][2]][0] & ' - ' & $g_CentralArray[$g_ActiveConnections[$a][2]][2] & ' - ' & $p_State & @CRLF)
		;ConsoleWrite($g_ActiveConnections[$a][0] & ' - ' &$g_ActiveConnections[$a][1] & ' - ' &$g_ActiveConnections[$a][2] & ' - ' &$g_ActiveConnections[$a][3] &  @CRLF)
	Next
EndFunc   ;==>_Depend_SetGroupByNumber

; ---------------------------------------------------------------------------------------------
; Enable or disable all parts of a mod
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
EndFunc   ;==>_Depend_SetModState

; ---------------------------------------------------------------------------------------------
; Remove all items that have problems with a sepcific item or setup. Invert is possible.
; ---------------------------------------------------------------------------------------------
Func _Depend_SolveConflict($p_Setup, $p_State, $p_Type=0)
	Local $Number
	For $a=1 to $g_ActiveConnections[0][0]
		If $p_Type = 0 Then $Test = $g_ActiveConnections[$a][2]
		If $p_Type = 1 Then $Test = $g_CentralArray[$g_ActiveConnections[$a][2]][0]
		If $Test = $p_Setup Then
			If $g_ActiveConnections[$a][0] <> 'C' Then ContinueLoop
			$n=$a
			$Number = $g_ActiveConnections[$a][3]
			While $g_ActiveConnections[$n][1]=$g_ActiveConnections[$a][1]; get the beginning of the conflict
				$n-=1
			WEnd
			While 1
				$n+=1
				If $g_ActiveConnections[$n][1]<>$g_ActiveConnections[$a][1] Then ExitLoop; continue to the next possible step or exit
				If $p_Type = 0 Then $Test = $g_ActiveConnections[$n][2]
				If $p_Type = 1 Then $Test = $g_CentralArray[$g_ActiveConnections[$n][2]][0]
				If $p_State = 1 Then
					If $Number <> '' And $Number = $g_ActiveConnections[$n][3] Then ContinueLoop
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