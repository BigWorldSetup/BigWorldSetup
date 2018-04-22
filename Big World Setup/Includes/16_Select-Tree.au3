; ---------------------------------------------------------------------------------------------
; end the current selection and go on with the installation
; ---------------------------------------------------------------------------------------------
Func _Tree_EndSelection()
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Tree_EndSelection')
	_Tree_GetCurrentSelection(1)
	If _Test_CheckBG1TP() = 1 Then IniDelete($g_UsrIni, 'Current', 'BG1TP'); Remove download for german totsc-textpatch if not required
	If _Test_CheckTotSCFiles_BG1() = 1 Then IniDelete($g_UsrIni, 'Current', 'BG1TotSCSound'); Remove download for spanish totsc-sounds if not required
	_ResetInstall(0); Reset the installation-order
	Local $Ignores[$g_Connections[0][0]][2]; save ignored warnings for reloads
	For $c=1 to $g_Connections[0][0]
		If StringLeft($g_Connections[$c][3], 1) = 'W' Then _IniWrite($Ignores, $g_Connections[$c][0], $g_Connections[$c][1])
	Next
	ReDim $Ignores[$Ignores[0][0]+1][2]
	IniWriteSection($g_UsrIni, 'IgnoredConnections', $Ignores)
	Local $Current, $Array
	For $l=1 to 3
		$Current=GUICtrlRead($g_UI_Interact[14][$l])
		$Array = StringSplit(IniRead($g_TRAIni, 'UI-Buildtime', 'Interact[14]['&$l&']', ''), '|')
		For $a=1 to $Array[0]
			If $Array[$a] = $Current Then IniWrite($g_UsrIni, 'Options', 'Logic'&$l, $a)
		Next
	Next
	If GUICtrlRead($g_UI_Interact[14][4]) = $GUI_CHECKED Then
		IniWrite($g_UsrIni, 'Options', 'GroupInstall', 1); install in groups
	Else
		IniWrite($g_UsrIni, 'Options', 'GroupInstall', 0)
	EndIf
	If GUICtrlRead($g_UI_Interact[14][10]) = $GUI_CHECKED Then
		IniWrite($g_UsrIni, 'Options', 'Beep', 1); beep on interruptions
		$g_Flags[18]=1
	Else
		IniWrite($g_UsrIni, 'Options', 'Beep', 0)
		$g_Flags[18]=0
	EndIf
	If GUICtrlRead($g_UI_Interact[14][8]) = $GUI_CHECKED Then
		IniWrite($g_UsrIni, 'Options', 'TAPatch', 1); textpatches
	Else
		IniWrite($g_UsrIni, 'Options', 'TAPatch', 0)
	EndIf
	If GUICtrlRead($g_UI_Interact[14][5]) = $GUI_CHECKED Then ; widescreen
		If $g_Flags[14]='PST' Then
			IniWrite($g_UsrIni, 'Current', 'widescreen', '0 0?1_'&GUICtrlRead($g_UI_Interact[14][6]) & ' 0?2_' & GUICtrlRead($g_UI_Interact[14][7]) & ' 0?3_N 0?4_N 0?5_Y')
		Else
			IniWrite($g_UsrIni, 'Current', 'widescreen', '0 0?1_'&GUICtrlRead($g_UI_Interact[14][6]) & ' 0?2_' & GUICtrlRead($g_UI_Interact[14][7]) & ' 0?3_Y')
		EndIf
	Else
		IniDelete($g_UsrIni, 'Current', 'widescreen')
	EndIf
	IniWrite($g_BWSIni, 'Order', 'Au3Select', 0); Enable the restart of a "paused" installation
	If _Test_Get_EET_Mods() = 1 Then
		IniWrite($g_UsrIni, 'Options', 'AppType', 'BG2EE:BG1EE'); change $g_Flags[14] (and so the games type) to BG1EE
		IniWrite($g_BWSIni, 'Order', 'Au3CleanInst', 1); enable a backup of BG1
	EndIf
	DllClose($g_UDll); close the dll for detecting keypresses
	_Misc_SetTab(6); switch to Console-tab
EndFunc    ;==>_Tree_EndSelection

; ---------------------------------------------------------------------------------------------
; save/export the current selection
; ---------------------------------------------------------------------------------------------
Func _Tree_Export($p_File='')
	Local $File=$p_File
	If $File = '' Then
		$File = FileSaveDialog(_GetTR($g_UI_Message, '4-F2'), $g_ProgDir, 'Ini files (*.ini)', 2, 'BWS-Selection.ini', $g_UI[0]); => save selection as
		If @error Then Return
		If StringRight($File, 4) <> '.ini' Then $File&='.ini'
	EndIf
	_Tree_GetCurrentSelection(0)
	FileClose(FileOpen($File, 2))
	Local $Text
	If StringInStr ($p_File, 'PreSelection00.ini') Then; adjust current date in the preselection-hints
		For $a=1 to $g_ATrans[0]
			$Text=IniRead($g_GConfDir&'\Mod-'&$g_ATrans[$a]&'.ini', 'Preselect', '00', '')
			$Text=StringRegExpReplace($Text, '\x28.*\x29', @MDAY&'.'&@MON&'.'&@YEAR)
			IniWrite($g_GConfDir&'\Mod-'&$g_ATrans[$a]&'.ini', 'Preselect', '00', $Text)
		Next
		IniWrite($g_UsrIni, 'Options', 'InstallType', '01'); set user ini to reload auto-export on restart
	EndIf
	IniWriteSection($File, 'Save', IniReadSection($g_UsrIni, 'Save'))
	IniWriteSection($File, 'DeSave', IniReadSection($g_UsrIni, 'DeSave'))
	IniWriteSection($File, 'Edit', IniReadSection($g_UsrIni, 'Edit'))
	$g_Flags[24]=0
EndFunc   ;==>_Tree_Export

; ---------------------------------------------------------------------------------------------
; save/export the current selection
; ---------------------------------------------------------------------------------------------
Func _Tree_Import($p_File)
	Local $Section = IniReadSectionNames($p_File)
	If @error Then; IniReadSectionNames did not return a valid array
		_PrintDebug(_GetTR($g_UI_Message, '4-F3'), 1); => The selected file was not in the expected format
		Return -1
	EndIf
	Local $Success=0
	For $s=1 to $Section[0]; backward compatibility format check (1=old, 2=new)
		If $Section[$s] = 'Current' Then $Success = 1
		If $Section[$s] = 'Save' Then $Success = 2
	Next
	If $Success=0 Then
		_PrintDebug(_GetTR($g_UI_Message, '4-F3'), 1); => The selected file was not in the expected format
		Return -1
	ElseIf $Success = 1 Then
		IniWriteSection($g_UsrIni, 'Current', IniReadSection($p_File, 'Current'))
		IniWriteSection($g_UsrIni, 'Save', IniReadSection($p_File, 'Current'))
		IniDelete($g_UsrIni, 'DeSave')
	ElseIf $Success = 2 Then
		IniWriteSection($g_UsrIni, 'Current', IniReadSection($p_File, 'Save'))
		IniWriteSection($g_UsrIni, 'Save', IniReadSection($p_File, 'Save'))
		IniWriteSection($g_UsrIni, 'DeSave', IniReadSection($p_File, 'DeSave'))
	EndIf
	IniWriteSection($g_UsrIni, 'Edit', IniReadSection($p_File, 'Edit')); import any saved Edits
	Return 0
EndFunc   ;==>_Tree_Import

; ---------------------------------------------------------------------------------------------
; Get the list of current selected components
; ---------------------------------------------------------------------------------------------
Func _Tree_GetCurrentList()
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Tree_GetCurrentList')
	Local $tPackages[$g_CentralArray[0][0]][2]
	$tPackages[0][0] = 0
	GUICtrlSetData($g_UI_Static[9][2], _GetTR($g_UI_Message, '4-L3')); => search components
	For $m = $g_CentralArray[0][1] To $g_CentralArray[0][0]
		If $g_CentralArray[$m][2] <> '-' Then ContinueLoop; only got interest in headlines
		If GUICtrlRead($m) = 0 Then ContinueLoop
		If $g_CentralArray[$m][9] <> 0 Then _IniWrite($tPackages, $g_CentralArray[$m][0], $g_CentralArray[$m][4], 'O')
	Next
	ReDim $tPackages[$tPackages[0][0]+1][2]
	Return $tPackages
EndFunc   ;==>_Tree_GetCurrentList

; ---------------------------------------------------------------------------------------------
; Write to current selection to [Current], [Options] and [Order]
; ---------------------------------------------------------------------------------------------
Func _Tree_GetCurrentSelection($p_Show = 0, $p_Write=''); $a=hide seletion-GUI
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Tree_GetCurrentSelection')
	Local $Select[$g_CentralArray[0][0]][2]
	Local $DeSelect[$g_CentralArray[0][0]][2]
	$Select[0][0] = 0
	$DeSelect[0][0] = 0
	If $p_Show = 0 Then _Misc_ProgressGUI(_GetTR($g_UI_Message, '4-T2'), _GetTR($g_UI_Message, '4-L4')); => write entries
	IniDelete($g_UsrIni, 'Current'); delete old selections
	; Keep this section consistent with _Tree_Reload in Select-Tree.au3
	If $g_Flags[14] = 'BG2EE' Then
		IniWrite($g_UsrIni, 'Options', 'BG1EE', StringRegExpReplace(GUICtrlRead($g_UI_Interact[2][1]), '\x5c{1,}\z', ''))
		IniWrite($g_UsrIni, 'Options', 'BG2EE', StringRegExpReplace(GUICtrlRead($g_UI_Interact[2][2]), '\x5c{1,}\z', ''))
	ElseIf StringRegExp($g_Flags, 'BWP|BWS') Then
		IniWrite($g_UsrIni, 'Options', 'BG1', StringRegExpReplace(GUICtrlRead($g_UI_Interact[2][1]), '\x5c{1,}\z', ''))
		IniWrite($g_UsrIni, 'Options', 'BG2', StringRegExpReplace(GUICtrlRead($g_UI_Interact[2][2]), '\x5c{1,}\z', ''))
	Else
		IniWrite($g_UsrIni, 'Options',  $g_Flags[14], StringRegExpReplace(GUICtrlRead($g_UI_Interact[2][2]), '\x5c{1,}\z', ''))
	EndIf
	IniWrite($g_UsrIni, 'Options', 'Download', StringRegExpReplace(GUICtrlRead($g_UI_Interact[2][3]), '\x5c{1,}\z', ''))
	Local $Comp = '', $DComp = ''
	Local $Setup = $g_CentralArray[$g_CentralArray[0][1]][0]
; ---------------------------------------------------------------------------------------------
; loop through the elements of the main-array. We make heavy usage of the main-array here. Now you know why it's that important. :)
; ---------------------------------------------------------------------------------------------
	For $m = $g_CentralArray[0][1] To $g_CentralArray[0][0]
		If $g_CentralArray[$m][2] = '-' Then ContinueLoop; no interest in headlines
		If $g_CentralArray[$m][2] = '+' Then ContinueLoop; no interest in subtrees
		If $g_CentralArray[$m][2] = '!' Then ContinueLoop; no interest in categories
		If $Setup <> $g_CentralArray[$m][0] Then; if the mod isn't the same as before
			If $Comp <> '' Then _IniWrite($Select, $Setup, StringTrimLeft($Comp, 1)); if needed, write into an array - to speed up the process
			If $DComp <> '' Then _IniWrite($DeSelect, $Setup, StringTrimLeft($DComp, 1)); if needed, write into an array - to speed up the process
			$Setup = $g_CentralArray[$m][0]
			Local $Comp = '', $DComp = ''
		EndIf
		GUICtrlSetData($g_UI_Interact[9][1], $m * 100 / $g_CentralArray[0][0]); set progress
		If _MathCheckDiv($m, 10) = 2 Then GUICtrlSetData($g_UI_Static[9][2], Round($m * 100 / $g_CentralArray[0][0], 0) & ' %')
		If GUICtrlGetState($m) = 0 Then ContinueLoop; item was deleted (unlikely with new language-handling, but just in case)
		If $g_CentralArray[$m][15] = 1 Then IniWrite($g_UsrIni, 'Pause', $Setup, IniRead($g_UsrIni, 'Pause', $Setup, '') & ' ' & $g_CentralArray[$m][2])
		If $g_CentralArray[$m][9] = 1 Then
			$Comp &= ' ' & $g_CentralArray[$m][2]; collect selected components
		Else
			$DComp &= ' ' & $g_CentralArray[$m][2]; collect deselected components
		EndIf
	Next
	If $Comp <> '' Then _IniWrite($Select, $Setup, StringTrimLeft($Comp, 1))
	If $DComp <> '' Then _IniWrite($DeSelect, $Setup, StringTrimLeft($DComp, 1))
	ReDim $Select[$Select[0][0]+1][2]
	ReDim $DeSelect[$DeSelect[0][0]+1][2]
	If $p_Write = '' Then
		IniWriteSection($g_UsrIni, 'Current', $Select)
		IniWriteSection($g_UsrIni, 'Save', $Select)
		IniWriteSection($g_UsrIni, 'DeSave', $DeSelect)
	Else
		IniWriteSection($p_Write, 'Current', $Select)
		IniWriteSection($p_Write, 'Save', $Select)
		IniWriteSection($p_Write, 'DeSave', $DeSelect)
	EndIf
	If $p_Show = 0 Then _Misc_SetTab(4); show the advsel-tab
EndFunc   ;==>_Tree_GetCurrentSelection

; ---------------------------------------------------------------------------------------------
; Returns the TreeViewItem-ID for the mods component
; ---------------------------------------------------------------------------------------------
Func _Tree_GetID($p_Mod, $p_Comp='-')
	For $m = $g_CentralArray[0][1] To $g_CentralArray[0][0]
		If $g_CentralArray[$m][0] = $p_Mod Then
			If $g_CentralArray[$m][2] = $p_Comp Then Return $m
		EndIf
	Next
	Return '-'
EndFunc    ;==>_Tree_GetID

; ---------------------------------------------------------------------------------------------
; Detect mods that are splitted and save for later
; ---------------------------------------------------------------------------------------------
Func _Tree_GetSplittedMods()
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Tree_GetSplittedMods')
	Local $Index[750][2]; build an index with modname & id of its treeitem
	For $s = $g_CentralArray[0][1] To $g_CentralArray[0][0]
		If $g_CentralArray[$s][2] <> '-' Then ContinueLoop
		$Index[0][0]+=1
		$Index[$Index[0][0]][0]=$g_CentralArray[$s][0]
		$Index[$Index[0][0]][1]=$s
	Next
	ReDim $Index[$Index[0][0]+1][2]
	Local $Found ='|', $Doubles; check for mods that are splitted
	For $i=1 to $Index[0][0]
		If Not StringInStr($Found, '|'&$Index[$i][0]&'|') Then
			$Found&=$Index[$i][0]&'|'
		Else
			$Doubles&=','&$Index[$i][0]&':'&$Index[$i][1]
		EndIf
	Next
	Local $Mod, $Len, $Num, $Doubles, $Array=StringSplit(StringTrimLeft($Doubles, 1) , ','); work on those mods
	For $a = 1 to $Array[0]
		If $Array[$a] = '' Then ContinueLoop
		$Mod=StringLeft($Array[$a], StringInStr($Array[$a], ':')-1)
		$Len=StringLen($Mod)
		For $i=1 to $Index[0][0]; find the first treeviewitem-id of the mod
			If $Index[$i][0] = $Mod Then
				$Num=$Index[$i][1]
				ExitLoop
			EndIf
		Next
		$Doubles=''
		For $d = 1 to $Array[0]; get the other ids
			If StringLeft($Array[$d], $Len+1) = $Mod&':' Then
				$Doubles&=','&StringTrimLeft($Array[$d], $Len+1)
				$Array[$d]=''
			EndIf
		Next
		$Doubles = StringSplit($Num&$Doubles, ','); sort the output, so the next id comes first in line (e.g. 402=> 501, 102)
		For $d=1 to $Doubles[0]
			GUICtrlSetData($Doubles[$d], GUICtrlRead($Doubles[$d], 1)&'*')
			Local $Output=''
			For $e=$d to $Doubles[0]
				If $e=$d Then ContinueLoop
				$Output&=','&$Doubles[$e]
			Next
			For $e=1 to $d
				If $e=$d Then ContinueLoop
				$Output&=','&$Doubles[$e]
			Next
			$g_CentralArray[$Doubles[$d]][13]=StringTrimLeft($Output,1)
		Next
	Next
EndFunc   ;==>_Tree_GetSplittedMods

; ---------------------------------------------------------------------------------------------
; Delete the old menu-entries and create new ones
; ---------------------------------------------------------------------------------------------
Func _Tree_GetTags()
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Tree_GetTags')
	If $g_Flags[14] = 'BWS' Then
		$g_UI_Menu[0][2]=StringRegExp(IniRead($g_TRAIni, 'UI-Buildtime', 'Menu[2][2]', ''), '\x7c', 3)
	ElseIf $g_Flags[14] = 'BWP' Then
		$g_UI_Menu[0][2]=StringRegExp(IniRead($g_TRAIni, 'UI-Buildtime', 'Menu[2][4]', ''), '\x7c', 3)
	Else
		$g_UI_Menu[0][2]=StringRegExp(IniRead($g_TRAIni, 'UI-Buildtime', 'Menu[2][5]', ''), '\x7c', 3)
	EndIf
	$g_UI_Menu[0][2]=UBound($g_UI_Menu[0][2])+2
	$g_UI_Menu[0][3]=2+$g_Groups[0][0]+$g_UI_Menu[0][2]
	If $g_UI_Menu[0][3] > 18 Then
		ReDim $g_UI_Menu[10][$g_UI_Menu[0][3]+2]
	Else
		ReDim $g_UI_Menu[10][$g_UI_Menu[0][3]+2]
	EndIf
	Global $g_Tags[$g_UI_Menu[0][3]][2]; localized menu-items
	$g_Tags[0][0]=$g_UI_Menu[0][3]-1
	Local $Split = StringSplit(IniRead($g_TRAIni, 'UI-Buildtime', 'Menu[2][1]', ''), '|'); => Special|All
	$g_Tags[2][0]='*'
	$g_Tags[2][1]=$Split[2]
	If $g_Flags[14] = 'BWS' Then
		$Split = StringSplit(IniRead($g_TRAIni, 'UI-Buildtime', 'Menu[2][2]', ''), '|'); => BWS themes
	ElseIf $g_Flags[14] = 'BWP' Then
		$Split = StringSplit(IniRead($g_TRAIni, 'UI-Buildtime', 'Menu[2][4]', ''), '|'); => BWP chapters
	Else
		$Split = StringSplit(IniRead($g_TRAIni, 'UI-Buildtime', 'Menu[2][5]', ''), '|'); => general themes (for other games)
	EndIf
	For $n=1 to $Split[0]
		$g_Tags[$n+2][0]=$n-1
		$g_Tags[$n+2][1]=$Split[$n]
	Next
	$Split = StringSplit(IniRead($g_GConfDir&'\Translation-'&$g_ATrans[$g_ATNum]&'.ini', 'UI-Buildtime', 'Menu[2][3]', ''), '|'); => groups
	For $n=1 to $Split[0]
		$g_Tags[$g_UI_Menu[0][2]+$n+1][0]=$g_UI_Menu[0][2]+$n-2
		$g_Tags[$g_UI_Menu[0][2]+$n+1][1]=$Split[$n]
	Next
EndFunc    ;==>_Tree_GetTags

; ---------------------------------------------------------------------------------------------
; Create all the items in the treeview for the Au3Select-function. See 13_Select-AI.au3 for an overview of g_CentralArray
; ---------------------------------------------------------------------------------------------
Func _Tree_Populate($p_Show=1)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Tree_Populate')
	Local $ch, $cs, $cc, $ReadSection, $Type='0000', $ATMod, $ATIdx, $NotFixedItems, $p_Debug = 0
	_Misc_ProgressGUI(_GetTR($g_UI_Message, '0-T2'), _GetTR($g_UI_Message, '0-L3')); => building dependencies-table
	GUISwitch($g_UI[0])
	_Tree_PurgeUnNeeded(); calculate unsuited mods
	$g_Groups=IniReadSection($g_GConfDir&'\Game.ini', 'Groups')
	For $g = 1 To $g_Groups[0][0]; replace the ampersands with a vertical line so that regex will work on these components
		$g_Groups[$g][1]=StringReplace($g_Groups[$g][1], '&', '|')
	Next
	Local $SelectArray
	Local $RuleLines =_IniReadSection($g_ConnectionsConfDir&'\Game.ini', 'Connections'); must precede _Depend_TrimBWSConnections()
	If $p_Debug Then FileWrite($g_LogFile, '_Tree_Populate $RuleLines[0][0]='&$RuleLines[0][0]&@CRLF)
	If $p_Debug Then FileWrite($g_LogFile, '_Tree_Populate $g_Flags[14]='&$g_Flags[14]&@CRLF)
	If $g_Flags[14] = 'BWP' Then; we are doing a BWP batch-install
		$SelectArray=_Tree_SelectReadForBatch(); read the InstallOrder.ini-file, ignoring ANN/CMD/GRP
		$RuleLines = _Depend_TrimBWSConnections($RuleLines); remove rule lines with component numbers because BWP batch-install ignores such rules
		If $p_Debug Then FileWrite($g_LogFile, '_Tree_Populate $RuleLines[0][0] after _Depend_TrimBWSConnections='&$RuleLines[0][0]&@CRLF)
	Else; we are doing a BWS customizable install
		$SelectArray=_Tree_SelectRead(); read the InstallOrder.ini-file, ignoring ANN/CMD/GRP
		If $p_Show Then
			If $g_Flags[21] = 0 Then $SelectArray=_Tree_SelectConvert($SelectArray); convert it to a theme-sorted view
		Else
			Local $Trans = StringSplit(IniRead($g_TRAIni, 'UI-Buildtime', 'Menu[2][2]', ''), '|'); => translations for themes
			$SelectArray[0][3] = $Trans[0] ; how many '|'-separated themes were found at the line starting 'Menu[2][2]=' in Translation-??.ini
		EndIf
	EndIf
	If $p_Debug Then FileWrite($g_LogFile, '_Tree_Populate $RuleLines[0][0]='&$RuleLines[0][0]&@CRLF)
	Local $Index=_Depend_PrepareBuildIndex($RuleLines, $SelectArray)
	$g_Connections=_Depend_PrepareBuildSentences($RuleLines)
	$g_Connections=_Depend_PrepareToUseID($g_Connections)
	; final step in building $g_Connections is _Depend_ItemGetConnections which is done for each treeview-item representing a mod headline or (sub-)component
	GUICtrlSetData($g_UI_Interact[9][1], 20); set the progress
	GUICtrlSetData($g_UI_Static[9][2], '20 %')
	GUICtrlSetData ($g_UI_Static[9][1], _GetTR($g_UI_Message, '0-L2')); => search component
	GUICtrlSetData($g_UI_Interact[9][1], 32); set the progress
	GUICtrlSetData($g_UI_Static[9][2], '32 %')
	ReDim $SelectArray[$SelectArray[0][0] + 2][10]
	ReDim $g_TreeviewItem[$SelectArray[0][1] + 1][500]; if BWS goes kaboom, increase this number...
	ReDim $g_CHTreeviewItem[$SelectArray[0][3]+1]
	$ATMod=_IniReadSection($g_GConfDir&'\Mod-'&$g_ATrans[$g_ATNum]&'.ini', 'Description', 1)
	$ATIdx=_IniCreateIndex($ATMod); => ASCII char lookup table (# of lines in $ATMod starting with ASCII char, first such index in $ATMod, last such index in $ATMod)
	$SelectArray[0][8]=-1
	_Tree_GetTags()
	$g_UI_Menu[0][1]='|'
	Local $Compnote = _GetTR($g_UI_Message, '4-L1'); => in the future you will be able to select components
	Local $ConnNote = IniRead($g_TRAIni, 'DP-BuildSentences', 'L9', ''); => dependencies and conflicts
	Local $EditSubs = IniReadSection($g_GConfDir&'\Game.ini', 'Edit')
	_GUICtrlTreeView_BeginUpdate($g_UI_Handle[0])
	For $s = 1 To $SelectArray[0][0]; loop through the elements of the array (contains the chapters)
		If $SelectArray[$s][2] <> $SelectArray[$s-1][2] Then
			$SelectArray[0][2]+=1; set old compnumber
			$cs+=1
			GUICtrlSetData($g_UI_Interact[9][1], 32+($cs * 45 / $SelectArray[0][1])); set the progress
			If _MathCheckDiv($SelectArray[0][2], 10) = 2 Then GUICtrlSetData($g_UI_Static[9][2], Round(32+($cs * 45 / $SelectArray[0][1]), 0) & ' %')
			$ReadSection = IniReadSection($g_ModIni, $SelectArray[$s][2])
			$NotFixedItems = _IniRead($ReadSection, 'NotFixed', '') ; see if there are not fixed items (among the fixed)
			$SelectArray[$s][5] = _GetTra($ReadSection, 'T+')
			If $SelectArray[$s][5]='' Then
				If StringInStr(_IniRead($ReadSection, 'Type', ''), 'F') And Not StringRegExp($g_fLock, ','&$SelectArray[$s][2]&'(,|\z)') Then $g_fLock&=','&$SelectArray[$s][2]
				Local $Tmp=$s; see for more components of this mod
				While $SelectArray[$Tmp+1][2] = $SelectArray[$s][2]
					$Tmp+=1
					If $Tmp = $SelectArray[0][0] Then ExitLoop
				WEnd
				$s=$Tmp
				ContinueLoop
			EndIf
			If $SelectArray[$s][8]+3 > $g_Tags[0][0] Then $SelectArray[$s][8] = 0; don't crash if tag does not fit -> move it to general
			If $g_CHTreeviewItem[$SelectArray[$s][8]] = '' Then; if current tree does not exist, create it
				If $g_Flags[21]=0 Then; new theme-based-sorting
					$g_CHTreeviewItem[$SelectArray[$s][8]] = GUICtrlCreateTreeViewItem($g_Tags[$SelectArray[$s][8]+3][1], $g_UI_Interact[4][1]); create a treeviewitem (gui-element) for the chapter itself (headline)
				Else
					$g_CHTreeviewItem[$SelectArray[$s][8]] = $g_UI_Interact[4][1]
				EndIf
				GUICtrlSetState($g_CHTreeviewItem[$SelectArray[$s][8]], $GUI_DEFBUTTON); only set the chapter-line bold
				$g_CentralArray[$g_CHTreeviewItem[$SelectArray[$s][8]]][1]= $SelectArray[$s][8]; tag/theme/category
				$g_CentralArray[$g_CHTreeviewItem[$SelectArray[$s][8]]][2]= '!'; tag as no component
				$g_CentralArray[$g_CHTreeviewItem[$SelectArray[$s][8]]][5] = GUICtrlGetHandle($g_CHTreeviewItem[$SelectArray[$s][8]]); handle
				$g_CentralArray[$g_CHTreeviewItem[$SelectArray[$s][8]]][9]= 0; set "current selected mods per chapter" counter
				$g_CentralArray[$g_CHTreeviewItem[$SelectArray[$s][8]]][10]= 0; set "mods per chapter" counter
				If Not StringInStr($g_UI_Menu[0][1], '|'&$SelectArray[$s][8]&'|') Then $g_UI_Menu[0][1]&=$SelectArray[$s][8]&'|'; save used themes for the creation of menus
			EndIf
			$SelectArray[$s][7]=_IniRead($ReadSection, 'Name', $SelectArray[$s][2])
			$g_TreeviewItem[$cs][0] = GUICtrlCreateTreeViewItem($SelectArray[$s][7]&' ['&$SelectArray[$s][5]& ']', $g_CHTreeviewItem[$SelectArray[$s][8]]); create a treeviewitem (gui-element) for the mod itself (headline)
			$g_CentralArray[$g_CHTreeviewItem[$SelectArray[$s][8]]][10]+= 1; increase "mods per chapter" counter
			GUICtrlSetState($g_TreeviewItem[$cs][0], $GUI_DEFBUTTON); only set the mod-line bold
; ---------------------------------------------------------------------------------------------
; Create the entries for a mod headline in the two-dimensional main-array.
; ---------------------------------------------------------------------------------------------
			$g_CentralArray[$g_TreeviewItem[$cs][0]][0] = $SelectArray[$s][2]; current setup
			$g_CentralArray[$g_TreeviewItem[$cs][0]][1] = $SelectArray[$s][8]; tag
			$g_CentralArray[$g_TreeviewItem[$cs][0]][2] = '-'; tag as no component
			$g_CentralArray[$g_TreeviewItem[$cs][0]][3] = '-'; it's a mod, there is no component-description
			$g_CentralArray[$g_TreeviewItem[$cs][0]][4] = $SelectArray[$s][7]; mod description
			$g_CentralArray[$g_TreeviewItem[$cs][0]][5] = GUICtrlGetHandle($g_TreeviewItem[$cs][0]); handle
			Local $Char = Asc(StringLower(StringLeft($SelectArray[$s][2], 1))); ASCII-symbol of first character in the mod's setup-name from InstallOrder.ini
			Local $Ext = _IniRead($ATMod, $SelectArray[$s][2], '', $ATIdx[$Char][1], $ATIdx[$Char][2]); gather the mod's translated description for the given setup-name, limiting search range for efficiency to only look for the [setup-name] ini section between previously determined first and last possible match
			If $Ext = '' Then ConsoleWrite('!No mod description: '&$SelectArray[$s][2]&@CRLF)
			If $p_Debug Then FileWrite($g_LogFile, '_Tree_Populate calling _Depend_ItemGetConnections $SelectArray[$s='&$s&'][1] = '&$SelectArray[$s][1]&', $SelectArray[$s][2]='&$SelectArray[$s][2]&', $Index[$SelectArray[$s][1]][0]='&$Index[$SelectArray[$s][1]][0]&', $Index[$SelectArray[$s][1]][1]='&$Index[$SelectArray[$s][1]][1]&@CRLF)
			Local $Test = _Depend_ItemGetConnections($g_Connections, $g_TreeviewItem[$cs][0], $Index[$SelectArray[$s][1]][1], $SelectArray[$s][2]); get dependencies and conflicts; parameters = rules array, treeview-item ID, array of indices to other rules in $g_Connections that might be connected to this treeview-item (based on its associated mod-setup-name, and pre-calculated by _Depend_PrepareBuildIndex), and finally the mod-setup-name for this mod headline -- we do not pass a component number because this is the mod headline so it only connects with rules that contain 'mod-setup-name(-)'
			If $Test <> '' Then
				$g_CentralArray[$g_TreeviewItem[$cs][0]][6] = StringReplace($Ext, '|', @CRLF) & @CRLF & @CRLF & $ConnNote & $Test
			Else
				$g_CentralArray[$g_TreeviewItem[$cs][0]][6] = StringReplace($Ext, '|', @CRLF)
			EndIf
			$g_CentralArray[$g_TreeviewItem[$cs][0]][7] = _IniRead($ReadSection, 'Size', '102400'); get the size of the mod
			$g_CentralArray[$g_TreeviewItem[$cs][0]][8] = $SelectArray[$s][5] ; get the language of the mod
			$g_CentralArray[$g_TreeviewItem[$cs][0]][9] = 0; number of selected/active components counter (changes when components are toggled)
			$g_CentralArray[$g_TreeviewItem[$cs][0]][10] = 0; number of components total (includes both active and inactive components)
			$g_CentralArray[$g_TreeviewItem[$cs][0]][11] = _IniRead($ReadSection, 'Type', '')
			$g_CentralArray[$g_TreeviewItem[$cs][0]][12] = $SelectArray[$s][4]; pre-selection bits (0000 to 1111)
			$g_CentralArray[$g_TreeviewItem[$cs][0]][15] = _IniRead($ReadSection, 'Rev', '')
			If $g_Flags[14] = 'BWP' Then; prevent search if batch-install is used
				Local $ReadSection[1][2]
			ElseIf $SelectArray[$s][5] = '--' Then
				$ReadSection=IniReadSection($g_GConfDir&'\WeiDU-'&_GetTra($ReadSection, 'T')&'.ini', $SelectArray[$s][2])
			Else
				$ReadSection=IniReadSection($g_GConfDir&'\WeiDU-'&$SelectArray[$s][5]&'.ini', $SelectArray[$s][2])
			EndIf
			If StringInStr($g_CentralArray[$g_TreeviewItem[$cs][0]][11], 'F') And Not StringRegExp($g_fLock, ','&$SelectArray[$s][2]&'(,|\z)') Then $g_fLock&=','&$SelectArray[$s][2]
			If $p_Show Then
				; 0x1a8c14 lime = recommended / 0x000070 dark = standard / 0xe8901a = tactics / 0xad1414 light = expert / checkbox-default = 0x1c5180
				If StringInStr($g_CentralArray[$g_TreeviewItem[$cs][0]][11], 'R') Then
					If $g_Flags[14]='BWP' Then $Type='1111'; set defaults for batch install
					GUICtrlSetColor($g_TreeviewItem[$cs][0], 0x1a8c14); lime foreground = recommended
				ElseIf StringInStr($g_CentralArray[$g_TreeviewItem[$cs][0]][11], 'S') Then
					If $g_Flags[14]='BWP' Then $Type='0111'; set defaults for batch install
					GUICtrlSetColor($g_TreeviewItem[$cs][0], 0x000070); dark foreground = stable
				ElseIf StringInStr($g_CentralArray[$g_TreeviewItem[$cs][0]][11], 'T') Then
					If $g_Flags[14]='BWP' Then $Type='0011'; set defaults for batch install
					GUICtrlSetColor($g_TreeviewItem[$cs][0], 0xe8901a); yellow foreground = tactical
				Else ;'E'
					If $g_Flags[14]='BWP' Then $Type='0001'; set defaults for batch install
					GUICtrlSetColor($g_TreeviewItem[$cs][0], 0xad1414); light foreground = expert
				EndIf
				; If a mod ini has 'W' or 'M' in its comma-separated Type list, highlight the background of the mod name
				; This is purely cosmetic to encourage users to read the mod description, which should explain the warning
				If StringInStr($g_CentralArray[$g_TreeviewItem[$cs][0]][11], 'W') Then
;					If $g_Flags[14]='BWP' Then $Type='0000'; don't select warning mods by default for batch install
					GUICtrlSetBkColor($g_TreeviewItem[$cs][0], 0xffff99); yellow background = warning
				ElseIf StringInStr($g_CentralArray[$g_TreeviewItem[$cs][0]][11], 'M') Then
					GUICtrlSetBkColor($g_TreeviewItem[$cs][0], 0xdddddd); light grey background = manual download
				EndIf
			EndIf
			$cc = 0
		Else ; If $SelectArray[$s][2] = $SelectArray[$s-1][2] Then
			$SelectArray[$s][5]=$SelectArray[$s-1][5]; preselection bits
			$SelectArray[$s][7]=$SelectArray[$s-1][7]; mod description
		EndIf
		$cc+=1
		Local $Dsc = _IniRead($ReadSection, '@' & $SelectArray[$s][3], $Compnote)
		If @error = -1 Then ConsoleWrite($SelectArray[$s][2]& ' @' & $SelectArray[$s][3] & @CRLF)
; ---------------------------------------------------------------------------------------------
; SUB: A selectable sub-component/question  (SUB-Selections are counted as possible selections to [10][0])
; ---------------------------------------------------------------------------------------------
		Local $Pos=StringInStr($SelectArray[$s][3], '?', 0, 1)
		If $Pos > 0 Then
			If $SelectArray[$s][0] <> 'SUB' Then
				_PrintDebug('! Error - non-SUB with ? component in InstallOrder.ini: '&$SelectArray[$s][0]&';'&$SelectArray[$s][2]&';'&$SelectArray[$s][3], 1)
				Exit
			EndIf
			Local $ComponentNum = StringLeft($SelectArray[$s][3], $Pos-1); number on left side of '?' in component string
			Local $n = 1
			While $n < $s And StringInStr($SelectArray[$s-$n][3], '?'); search backwards until first non-sub-component (in current theme chapter)
				$n += 1
			WEnd
			;$SelectArray[$s-$n] / $g_TreeviewItem[$cs][$cc - $n] is now the first line/item preceding this line without a '?' in its component string, i.e., the full component to which this subcomponent belongs
			If $SelectArray[$s-$n][2] <> $SelectArray[$s][2] Or $SelectArray[$s-$n][3] <> $ComponentNum Then; this sub-component has a setup-name or component-number different from the first preceding full component
				ContinueLoop; mistake or was purged - skip this sub-component
			EndIf
			Local $SubPrefix
			Local $Pos=StringInStr($SelectArray[$s][3], '_', 0, 1)
			Local $Definition=_IniRead($EditSubs, $SelectArray[$s][2]&';'&StringLeft($SelectArray[$s][3], $Pos-1), '')
			If $Definition <> '' Then
				$SubPrefix=_GetTR($g_UI_Message, '4-L23')&' '; => Suggested answer:
			Else
				$SubPrefix=''
			EndIf
			$g_TreeviewItem[$cs][$cc] = GUICtrlCreateTreeViewItem($SubPrefix&$Dsc, $g_TreeviewItem[$cs][$cc - $n]); create a "sub-"treeviewitem (gui-element) for the component
			If $g_CentralArray[$g_TreeviewItem[$cs][$cc - $n]][10] = 0 Then; this was marked as a normal component before
				$g_CentralArray[$g_TreeviewItem[$cs][$cc - $n]][10] = 2; this item has its own subtree now
				Local $t = $s-$n+1
				While StringInStr($SelectArray[$t+1][3], '?')
					If $SelectArray[$t+1][2] <> $SelectArray[$s][2] Then
						_PrintDebug('! Found a different mod while searching for sub-components below '&$SelectArray[$s][2]&';'&$SelectArray[$s][3], 1)
						Exit
					EndIf
					$t += 1
				WEnd
				$g_CentralArray[$g_TreeviewItem[$cs][0]][10]+=Number(StringRegExpReplace($SelectArray[$t][3], '\A\d{1,}\x3f|\x5f.*', '')); increase the possible selection
			EndIf
			$g_CentralArray[$g_TreeviewItem[$cs][$cc]][8] = $SelectArray[$s][5] ; available languages
			$g_CentralArray[$g_TreeviewItem[$cs][$cc]][10] = 1; is subitem
; ---------------------------------------------------------------------------------------------
; MUC create a subtree-item since the component has it's own number (MUC-Select-Headlines are not counted as possible selections to [10][0])
; ---------------------------------------------------------------------------------------------
		ElseIf $SelectArray[$s][0] = 'MUC'  Then
			If $SelectArray[$s][3] = 'Init' Then
				If $s = $SelectArray[0][0] Then; no lines after this
					ContinueLoop; mistake or all choices in this MUC sub-tree were purged - skip this MUC-headline
				ElseIf $SelectArray[$s+1][0] <> 'MUC' Or $SelectArray[$s+1][3] = 'Init' Or $SelectArray[$s+1][2] <> $SelectArray[$s][2] Then; next line is not a MUC or is another MUC Init or belongs to a different setup-name
					ContinueLoop; mistake or all choices in this MUC sub-tree were purged - skip this MUC-headline
				EndIf
				$g_TreeviewItem[$cs][$cc] = GUICtrlCreateTreeViewItem(StringRegExpReplace(_IniRead($ReadSection, '@'&$SelectArray[$s+1][3], ''), '\s?->.*\z', ''), $g_TreeviewItem[$cs][0]); create a treeviewitem (gui-element) for the component
				$g_CentralArray[0][0] = $g_TreeviewItem[$cs][$cc] ; last item in array
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][0] = $g_CentralArray[$g_TreeviewItem[$cs][0]][0] ; setup-name
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][2] = '+'
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][4] = $g_CentralArray[$g_TreeviewItem[$cs][0]][4]
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][5] = GUICtrlGetHandle($g_TreeviewItem[$cs][$cc]); handle
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][8] = $SelectArray[$s][5]
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][9] = 0
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][10] = 0
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][11] = $g_CentralArray[$g_TreeviewItem[$cs][0]][11]
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][12] = $SelectArray[$s][4]; pre-selection bits (0000 to 1111)
				;$g_CentralArray[$g_TreeviewItem[$cs][$cc]][13] = $g_CentralArray[$g_TreeviewItem[$cs][0]][13]
				$g_CentralArray[$g_TreeviewItem[$cs][0]][10]+=2; increase possible selections
				$g_CentralArray[0][0] = $g_TreeviewItem[$cs][$cc] ; last item in array
				$cc+=1
				ContinueLoop
			Else; MUC component, not Init
				Local $n = 1
				While $n < $s And $SelectArray[$s-$n][3] <> 'Init'; search backwards until the select-item
;				StringRegExp($SelectArray[$s-$n][3], '\A\d{1,}\z'); search backwards until the select-item
					$n+=1
				WEnd
				If $n = $s Or $SelectArray[$s-$n][2] <> $SelectArray[$s][2] Then; MUC Init not found or belongs to a different setup-name
					_PrintDebug('MUC Init not found before '&$SelectArray[$s][2]&';'&$SelectArray[$s][3], 1)
					ContinueLoop; mistake
				EndIf
				$g_TreeviewItem[$cs][$cc] = GUICtrlCreateTreeViewItem(_Tree_SetLength($SelectArray[$s][3])&': '&StringRegExpReplace($Dsc, '\A.*\s?->\s?', ''), $g_TreeviewItem[$cs][$cc-$n-1]); create a treeviewitem (gui-element) for the component
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][8] = $SelectArray[$s][5]; language
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][10] = 1; this item is part of a subtree
			EndIf
; ---------------------------------------------------------------------------------------------
; this is a normal component (STD) without subcomponents or a normal component (SUB) expected to be followed by at least one SUB-component
; ---------------------------------------------------------------------------------------------
		Else
			If $SelectArray[$s][0] = 'SUB' Then; we expect this component to be followed by at least one SUB-component
				If $s = $SelectArray[0][0] Then; no lines after this
					ContinueLoop; mistake or all SUB lines for this component were purged - skip this component
				ElseIf ($SelectArray[$s+1][0] <> 'SUB' Or $SelectArray[$s+1][2] <> $SelectArray[$s][2]) Then; next line is not a SUB or is a different setup-name
					ContinueLoop; mistake or all SUB lines after this component were purged - skip this component
				EndIf
			EndIf
			$g_TreeviewItem[$cs][$cc] = GUICtrlCreateTreeViewItem(_Tree_SetLength($SelectArray[$s][3])&': ' &$Dsc, $g_TreeviewItem[$cs][0])
			$g_CentralArray[$g_TreeviewItem[$cs][$cc]][8] = $SelectArray[$s][5]; possible languages
			$g_CentralArray[$g_TreeviewItem[$cs][$cc]][10] = 0; this item is _not_ part of a subtree
			$g_CentralArray[$g_TreeviewItem[$cs][0]][10]+=1; increase possible selections
		EndIf
; ---------------------------------------------------------------------------------------------
; Create the other entries for the component in the two-dimensional main-array.
; ---------------------------------------------------------------------------------------------
		$g_CentralArray[0][0] = $g_TreeviewItem[$cs][$cc] ; last item in array
		$g_CentralArray[$g_TreeviewItem[$cs][$cc]][0] = $g_CentralArray[$g_TreeviewItem[$cs][0]][0] ; setup-name
		$g_CentralArray[$g_TreeviewItem[$cs][$cc]][1] = $SelectArray[$s][8] ; tag
		$g_CentralArray[$g_TreeviewItem[$cs][$cc]][2] = $SelectArray[$s][3] ; component number
		$g_CentralArray[$g_TreeviewItem[$cs][$cc]][3] = $Dsc ; component description
		$g_CentralArray[$g_TreeviewItem[$cs][$cc]][4] = $SelectArray[$s][7]; mod description
		$g_CentralArray[$g_TreeviewItem[$cs][$cc]][5] = GUICtrlGetHandle($g_TreeviewItem[$cs][$cc]); handle
		$Test = _Depend_ItemGetConnections($g_Connections, $g_TreeviewItem[$cs][$cc], $Index[$SelectArray[$s][1]][1], $SelectArray[$s][2], $SelectArray[$s][3]); get dependencies and conflicts; parameters = rules array, treeview-item ID, array of indices to other rules in $g_Connections that might be connected to this treeview-item (based on its associated mod-setup-name, and pre-calculated by _Depend_PrepareBuildIndex), the mod-setup-name for this (sub-?)component, and finally the component number -- this might take some time (800ms last time it was measured, but we've changed code since then)
		$g_CentralArray[$g_TreeviewItem[$cs][$cc]][11] = $g_CentralArray[$g_TreeviewItem[$cs][0]][11]
		If $g_Flags[14]='BWP' Then; batch-install
			$g_CentralArray[$g_TreeviewItem[$cs][$cc]][12] = $Type; set pre-selection bits based on mod Type ($Type is set earlier in this function)
		ElseIf StringRegExp($g_CentralArray[$g_TreeviewItem[$cs][0]][11], '\A[^FRST]+\z') Then; mod Type does not include 'F'ixed, 'R'ecommended, Maximi'S'ed or 'T'actical
			$g_CentralArray[$g_TreeviewItem[$cs][$cc]][12] = '0001'; mark the item Expert regardless of InstallOrder.ini
		Else
			$g_CentralArray[$g_TreeviewItem[$cs][$cc]][12] = $SelectArray[$s][4]; pre-selection bits (0000 to 1111) according to InstallOrder.ini
		EndIf
		If $NotFixedItems <> '' Then; see if the item is among the 'not fixed' ones
			Local $ItemIsNotFixed = StringRegExp($NotFixedItems, '(?i)(\A|\s)' & $SelectArray[$s][3] & '(\s|\z)'); Note: Not checking for SUBs here.
			If $ItemIsNotFixed Then $g_CentralArray[$g_TreeviewItem[$cs][$cc]][11]=StringRegExpReplace($g_CentralArray[$g_TreeviewItem[$cs][$cc]][11], '\AF,|,F', '')
		EndIf
		If $p_Show Then
			Local $Ext = ''; _IniRead($ReadSection, 'E' & $SelectArray[$s][3], ''); read the components extended info ==> disabled since no info exists and it takes ~450 ms!!
			If $Test <> '' Then
;				If $Ext <> '' Then
;					$g_CentralArray[$g_TreeviewItem[$cs][$cc]][6] =  $Ext & @CRLF & @CRLF & $ConnNote & $Test
;				Else
					$g_CentralArray[$g_TreeviewItem[$cs][$cc]][6] = $ConnNote & $Test
;				EndIf
			Else
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][6] = $Ext
			EndIf
		EndIf
	Next
	$g_CentralArray[0][1] = $g_UI_Menu[8][10]+1; first item is created after last fixed menu entry
	ReDim $g_CentralArray[$g_CentralArray[0][0] + 1][16]
	_Tree_GetSplittedMods()
	If $p_Show Then
		_Misc_CreateMenu(); rebuild menus so not present settings are left out
		GUICtrlSetData($g_UI_Interact[9][1], 82); set the progress
		GUICtrlSetData($g_UI_Static[9][2], '82 %')
		_AI_GetType(); calculate the icon-color/shifting
		GUICtrlSetData($g_UI_Interact[9][1], 87); set the progress
		GUICtrlSetData($g_UI_Static[9][2], '90 %')
		For $s = $g_CentralArray[0][1] To $g_CentralArray[0][0]
			If $g_CentralArray[$s][7] = 1 Then
				__TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$s][5], 2+$g_CentralArray[$s][14]); display disabled check/uncheck icon for essential components
			EndIf
		Next
		If $p_Show = 1 Then _Tree_SetPreSelected(); so $p_Show=2 will do the reload later
		If StringInStr($g_Flags[14], 'EE') Then; no widescreen for BG1EE/BG2EE needed
		ElseIf $g_Flags[14] = 'BWP' Then; do a batch-install
			$g_Flags[22] = _Tree_GetID('widescreen', 'BATCH')
		Else; do a bws-install
			$g_Flags[22] = _Tree_GetID('widescreen', '0')
		EndIf
	EndIf
	; language-dependant stuff
	If $g_MLang[1] <> 'GE' Then; is not available for non-German BWP-installs
		GUICtrlSetState($g_UI_Interact[14][8], $GUI_HIDE)
	ElseIf Not StringRegExp($g_Flags[14], 'BWS|BWP') Then; doesn't install BWP anyway
		GUICtrlSetState($g_UI_Interact[14][8], $GUI_HIDE)
	Else
		GUICtrlSetState($g_UI_Interact[14][8], $GUI_SHOW)
	EndIf
	_Tree_ShowComponents($g_GUIFold)
	_GUICtrlTreeView_EndUpdate($g_UI_Handle[0])
EndFunc   ;==>_Tree_Populate

; ---------------------------------------------------------------------------------------------
; Run checks before rebuilding the treeview
; ---------------------------------------------------------------------------------------------
Func _Tree_Populate_PreCheck()
	Local $Error=0, $Rebuild=0
	For $i = 1 To 3
		$Error+=_Test_RejectPath($i); see if paths are set
	Next
	If $Error > 0 Then Return 0
	If _Test_CheckRequiredFiles() > 0 Then Return 0; see if files are present
	If _Misc_LS_Verify() = 0 Then Return 0; look if language settings are ok
;	If _Test_ACP() = 1 Then Return 0; remove infinity-mods if codepage may not support the mods files characters
	If $g_CentralArray[0][0] = '' Then _Tree_Populate(1); build the tree if needed
	If $g_Flags[14] = 'BG2EE' Then
		If $g_BG1EEDir = '-' Then; BG2EE-only-install
			If Not StringInStr($g_Skip, '|EET|') Then $Rebuild=1; skipped mods did not include EET -> rebuild
		Else; EET-install
			If StringInStr($g_Skip, '|EET|') Then $Rebuild=1; skipped mods did include EET -> rebuild
		EndIf
	ElseIf StringRegExp($g_Flags[14], 'BWP|BWS') Then
		If $g_BG1Dir = '-' Then; BG2-only-install
			If Not StringInStr($g_Skip, '|BGT|') Then $Rebuild=1; skipped mods did not include BGT -> rebuild
		Else; BGT-install
			If StringInStr($g_Skip, '|BGT|') Then $Rebuild=1; skipped mods did include BGT -> rebuild
		EndIf
	EndIf
	If $Rebuild Then _Misc_ReBuildTreeView()
	Return 1
EndFunc   ;==>_Tree_Populate_PreCheck

; ---------------------------------------------------------------------------------------------
; Remove treeview-items from the selection-screen, either based on setup-names or groups
; ---------------------------------------------------------------------------------------------
Func _Tree_Purge($p_Index, $p_String, $p_Comp='*')
	Local $Delete = 0
	_GUICtrlTreeView_BeginUpdate($g_UI_Handle[0])
	For $m = $g_CentralArray[0][1] To $g_CentralArray[0][0]
		If StringRegExp($g_CentralArray[$m][$p_Index], '(?i)(\A|,)('&$p_String&')(\z|,)') Then
			If $p_Comp <> '*' And StringRegExp($g_CentralArray[$m][2], '(?i)(\A|,)('&$p_Comp&')(\z|,)') = 0 Then
				$Delete = 0
			Else
				$Delete = 1
			EndIf
		Else
			$Delete = 0
		EndIf
		If $Delete = 1 Then _Tree_PurgeItem($m)
	Next
	_GUICtrlTreeView_SelectItem($g_UI_Handle[0], $g_CentralArray[$g_TreeviewItem[1][0]][5], $TVGN_FIRSTVISIBLE)
	_GUICtrlTreeView_EndUpdate($g_UI_Handle[0])
EndFunc   ;==>_Tree_Purge

; ---------------------------------------------------------------------------------------------
; Purge an item by its index/controlID
; ---------------------------------------------------------------------------------------------
Func _Tree_PurgeItem($p_Index)
	Local $DeleteSub
	If Not IsNumber($p_Index) Then Return
	If $g_CentralArray[$p_Index][3]='' Then Return; already purged
	$ModID=_AI_GetStart($p_Index, '-')
	$ModState=_AI_GetModState($ModID)
	$g_CentralArray[$p_Index][3]=''; mark as deleted by removing the items description
	If $g_CentralArray[$p_Index][9] = 1 Then $g_CentralArray[$ModID][9]-=1; decrease actual counter
	$g_CentralArray[$p_Index][9]=0; set items to deselected
	$g_CentralArray[$ModID][10]-=1; decrease possible components per mod-counter
	$g_CentralArray[$p_Index][12]='0000'; disable items selection to prevent selection while switching versions / adding mods...
	;GUICtrlDelete($p_Index)
	If $g_CentralArray[$p_Index][2] = '-' Then
		$Num=$p_Index+1
		While StringRegExp($g_CentralArray[$Num][2], '-|!') = 0
			$g_CentralArray[$Num][3]=''; mark as deleted by removing the items description
			$g_CentralArray[$Num][9]=0; set items to deselected
			$g_CentralArray[$Num][12]='0000'; disable items selection to prevent selection while switching versions / adding mods...
	;		GUICtrlDelete($Num)
			$Num +=1
			If $Num > $g_CentralArray[0][0] Then ExitLoop
		WEnd
		$g_CentralArray[$ModID][9]=0; no components
		$g_CentralArray[$ModID][10]=0; no possible selection
	ElseIf $g_CentralArray[$p_Index][10] = 1 Then; working with subtrees
		$Num=_AI_GetStart($p_Index, '+')
		$n=$Num+1
		$DeleteSub=1
		While _AI_IsInSubtree($n)=1
			If $g_CentralArray[$n][3] <> '' Then $DeleteSub =0
			$n+=1
			If $n>$g_CentralArray[0][0] Then ExitLoop
		WEnd
		If $DeleteSub = 1 Then
			If $g_CentralArray[$Num][9] = 1 Then $g_CentralArray[$ModID][9]-=1; decrease actual counter
			$g_CentralArray[$ModID][10]-=1; decrease possible components per mod-counter
			$g_CentralArray[$Num][3]=''; reset items description
			$g_CentralArray[$Num][9]=0; set items to deselected
			$g_CentralArray[$Num][12]='0000'; disable items selection to prevent selection while switching versions / adding mods...
	;		GUICtrlDelete($Num); delete mod icon if no components are displayed
		Else
			$g_CentralArray[$ModID][10]+=1; increase mod-counter because possible selections remain the same since only one of multiple MUCs was deleted
		EndIf
	EndIf
	If $g_CentralArray[$ModID][10] = 0 Then; mod is completely purged
		If $g_CentralArray[$ModID][13] <> '' Then
			$Splitted=StringSplit($g_CentralArray[$ModID][13], ',')
			For $s=1 to $Splitted[0]
				$Replace=''
				$Found=StringRegExp($g_CentralArray[Number($Splitted[$s])][13], '(\A|\x2c)'&$ModID&'(\x2c|\z)', 2)
				$Num=StringRegExp($Found[0], '\x2c', 3)
				If UBound($Num) = 2 Then $Replace=','
				$g_CentralArray[Number($Splitted[$s])][13]=StringReplace($g_CentralArray[Number($Splitted[$s])][13], $Found[0], $Replace)
			Next
		EndIf
	;	GUICtrlDelete($ModID); delete mod icon if no components are displayed
		$g_CentralArray[$g_CHTreeviewItem[$g_CentralArray[$ModID][1]]][10]-=1; decrease possible mods per chapter-counter
		If $g_CentralArray[$g_CHTreeviewItem[$g_CentralArray[$ModID][1]]][10] = 0 Then; chapter is purged
	;		GUICtrlDelete($g_CHTreeviewItem[$g_CentralArray[$ModID][1]])
		Else
			_AI_SetModStateIcon($g_CHTreeviewItem[$g_CentralArray[$ModID][1]]); update icon
		EndIf
	Else
		_AI_SetModStateIcon($ModID); update icon
	EndIf
EndFunc   ;==>_Tree_PurgeItem

; ---------------------------------------------------------------------------------------------
; Remove items that cannot be installed (due to language, game version or BGT/EET requirements)
; ---------------------------------------------------------------------------------------------
Func _Tree_PurgeUnNeeded()
	Local $Version='-', $SplitPurgeLine
	$g_Skip='BGTNeJ;0;'; not sure why this rule is hard-coded, but we don't want blank because next lines start with |
	If $g_BG1Dir = '-' Then $g_Skip&='|BGT'
	If $g_BG1EEDir = '-' Then $g_Skip&='|EET'
	If $g_Flags[14]='IWD1' Then $Version=StringReplace(FileGetVersion($g_IWD1Dir&'\idmain.exe'), '.', '\x2e') ; unicode full stop
	Local $ReadSection=IniReadSection($g_GConfDir&'\Game.ini', 'Purge')
	Local $LanguageRegexp = ''
	For $eachlang = 1 to $g_MLang[0]
		$LanguageRegexp &= '\b'&$g_MLang[$eachlang]&'\b'
		If $eachLang < $g_MLang[0] Then $LanguageRegexp &= '|'
	Next
	; Keep this function consistent with _Test_Get_EET_Mods in Testing.au3
	If IsArray($ReadSection) Then
		For $r=1 to $ReadSection[0][0]
			$SplitPurgeLine = StringSplit($ReadSection[$r][1], ':')
			If ($SplitPurgeLine[0] <> 3) Then ContinueLoop; Purge lines should have exactly three sections (D : ... : ...)
;			IniWrite($g_UsrIni, 'Debug', 'SplitPurgeLine'&$r, $SplitPurgeLine[1]&' ~ '&$SplitPurgeLine[2]&' ~ '&$SplitPurgeLine[3])
			If $SplitPurgeLine[1] = 'D' Then; check if dependencies are met, otherwise purge
				If StringRegExp($SplitPurgeLine[3], $LanguageRegexp) Then ContinueLoop; don't purge mods that depend on a language if that language is among the user's chosen translations
				If $Version <> '-' And StringRegExp($SplitPurgeLine[3], $Version) Then ContinueLoop; don't purge mods for current game version
				; Checks for BGT / EET dependencies
				If $g_Flags[14] = 'BG1EE' Then; user is installing BG1EE
					If StringRegExp($SplitPurgeLine[3], '(?i)\bBG1EE\b') Then ContinueLoop; don't purge mods/components that depend on BG1EE
					; else, fall through to purge mods/components that DO depend on BG1EE
				ElseIf $g_Flags[14] = 'BG2EE' Then; user is installing BG2EE or EET
					If $g_BG1EEDir <> '-' Then; BG1EE path is set, therefore this is an EET install
						If StringRegExp($SplitPurgeLine[3], '(?i)\bEET\x28\x2d\x29') Then ContinueLoop; don't purge mods/components that depend on EET
						; else, fall through to purge mods/components that DO depend on EET
					Else; this is a BG2EE-only install
						If StringRegExp($SplitPurgeLine[3], '(?i)\bBG2EE\b') Then ContinueLoop; don't purge mods/components that depend on BG2EE
						; else, fall through to purge mods/components that DO depend on BG2EE
					EndIf
				ElseIf StringRegExp($g_Flags[14], 'BWP|BWS') Then
					If $g_BG1Dir <> '-' Then; BG1 path is set, therefore this is a BGT install
						If StringRegExp($SplitPurgeLine[3], '(?i)BGT\x28\x2d\x29') Then ContinueLoop; don't purge mods/components that depend on BGT
						; else, fall through to purge mods/components that DO depend on BGT
					EndIf
				EndIf
			Else; not a dependency rule - invalid
				_PrintDebug($g_GConfDir&'\Game.ini contains an invalid rule (expected D: form): '&$ReadSection[$r][1],1)
			EndIf
			; If we reached this line, we found something that needs to be purged
			$g_Skip&='|'&StringReplace(StringReplace(StringReplace(StringReplace($SplitPurgeLine[2], '&', '|'), "(-)", ''), '(', ';('), '?', '\x3f')
			;  a purge rule "D:abc(0)&def(3):EET(-)" will be interpreted as "abc(0) and def(3) each independently depend on EET"
			;  in this example abc(0) and def(3) will both be purged/hidden (in non-EET installs) even if only one of them is selected
		Next
	EndIf
	If _Test_ACP() = 1 Then Exit
	If $g_BG1Dir <> '-' And $g_MLang[0] = 2 And $g_MLang[1] = 'GE' Then; second $g_MLang-entry is --
		$g_Skip&='|BG1NPC|BG1NPCMusic'
	ElseIf $g_BG1Dir <> '-' And $g_MLang[1] = 'GE' Then
		Local $Trans=IniRead($g_ModIni, 'BG1NPC', 'Tra', ''); get other translations
		Local $ReadSection[1]=[StringRegExpReplace($Trans, '(?i)\x2cGE\x3a\d{1,2}', '')]
		Local $Test=_GetTra($ReadSection, 'T+')
		If $Test <> 'EN' Then; user doesn't want mods in English
			If $Test = '' Then; nothing would be installed, so purge them
				$g_Skip&='|BG1NPC|BG1NPCMusic'
			Else; another language would be chosen, so remove the German one
				IniWrite($g_ModIni, 'BG1NPC', 'Tra', $ReadSection[0])
			EndIf
		Else
			If _IniRead($g_Order, 'Au3Select', 1) = 0 Then Return; no need to ask when reloading installation
			Local $Answer=_Misc_MsgGUI(2, _GetTR($g_UI_Message, '0-T1'), _GetTR($g_UI_Message, '2-L10'), 2, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2')); => install unfinished BG1NPC translation
			_Misc_SetTab(9)
			If $Answer = 1 Then; remove part-translation
				IniWrite($g_ModIni, 'BG1NPC', 'Tra', $ReadSection[0])
			Else; add if needed
				If Not StringInStr($Trans, 'GE') Then
					Local $Num=IniRead($g_GConfDir&'\WeiDU-GE.ini', 'BG1NPC', 'TRA', 3); get the translation-number
					IniWrite($g_ModIni, 'BG1NPC', 'Tra', $Trans&',GE:'&$Num); append the translation again
				EndIf
			EndIf
		EndIf
	EndIf
;	IniWrite($g_UsrIni, 'Debug', 'g_Skip', $g_Skip)
	If StringInStr($g_Flags[14], 'BWS') And $g_MLang[1] = 'PO' Then; user is installing 'BWS' and user selected language is Polish
		IniWrite($g_ConnectionsConfDir&'\Game.ini', 'Connections', 'NTotSC Natalin fix by dradiel is required for NTotSC but only for Polish', 'D:NTotSC(-)&NTotSC-Natalin-fix(-)')
		
	Else; remove special case rules (language + game type specific)
		IniDelete($g_ConnectionsConfDir&'\Game.ini', 'Connections','NTotSC Natalin fix by dradiel is required for NTotSC but only for Polish')
		
	EndIf
EndFunc   ;==>_Tree_PurgeUnNeeded

; ---------------------------------------------------------------------------------------------
; Sets the saved items for Au3Select
; ---------------------------------------------------------------------------------------------
Func _Tree_Reload($p_Show=1, $p_Hint=0, $p_Ini=$g_UsrIni)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Tree_Reload')
	GUISwitch($g_UI[0])
	; Keep this section consistent with _Tree_GetCurrentSelection in Select-Tree.au3
	If $g_Flags[14] = 'BG2EE' Then ; BG2EE / EET
		GUICtrlSetData($g_UI_Interact[2][1], IniRead($g_UsrIni, 'Options', 'BG1EE', GUICtrlRead($g_UI_Interact[2][1]))); BG1 folder path
		GUICtrlSetData($g_UI_Interact[2][2], IniRead($g_UsrIni, 'Options', 'BG2EE', GUICtrlRead($g_UI_Interact[2][2]))); BG2 folder path
	ElseIf StringRegExp($g_Flags, 'BWP|BWS') Then ; BWP / BWS / BGT
		GUICtrlSetData($g_UI_Interact[2][1], IniRead($g_UsrIni, 'Options', 'BG1', GUICtrlRead($g_UI_Interact[2][1]))); BG1 folder path
		GUICtrlSetData($g_UI_Interact[2][2], IniRead($g_UsrIni, 'Options', 'BG2', GUICtrlRead($g_UI_Interact[2][2]))); BG2 folder path
	Else ; other game types
		GUICtrlSetData($g_UI_Interact[2][2], IniRead($g_UsrIni, 'Options', $g_Flags[14], GUICtrlRead($g_UI_Interact[2][2]))); game folder path
	EndIf
	GUICtrlSetData($g_UI_Interact[2][3], IniRead($g_UsrIni, 'Options', 'Download', GUICtrlRead($g_UI_Interact[2][3])))
	Local $ModID = '', $ChapterID = '', $Tag = '', $Mod = 0, $Found = 0
; ---------------------------------------------------------------------------------------------
; loop through the elements of the main-array. We make heavy usage of the main-array here. Now you know why it's that important. :)
; ---------------------------------------------------------------------------------------------
	GUICtrlSetData($g_UI_Interact[9][1], 0)
	GUICtrlSetData($g_UI_Static[9][2], '0 %')
	_GUICtrlTreeView_BeginUpdate($g_UI_Handle[0]); speed up BWS by suppressing display of changes until we finish the update
	GUICtrlSetData($g_UI_Menu[1][5], _GetTR($g_UI_Message, '4-M1')); => hide components
	Local $Select = IniReadSection($p_Ini, 'Save')
	If @error Then $Select = IniReadSection($p_Ini, 'Current'); needed to still be able to load saves of older BWS-versions
	Local $DeSelect = IniReadSection($p_Ini, 'DeSave')
	If @error Then Local $DeSelect[1][1]
	Local $UserEdits=IniReadSection($p_Ini, 'Edit')
	If @error Then Local $UserEdits[1][1]
	$g_GUIFold = 1
	Local $Mark=_GetTR($g_UI_Message, '4-L17'); => NEW
	Local $Token = ' ['&StringLeft($Mark, 1)&']'
	$Mark = ' ['&$Mark&']'
	Local $Text, $Len = StringLen($Mark)
	For $m = $g_CentralArray[0][1] To $g_CentralArray[0][0]; strip old [NEW]-tags
 		$Text=GUICtrlRead($m, 1)
		If StringInStr($Text, $Token) Then
			GUICtrlSetData($m, StringReplace($Text, $Token, ''))
			If $g_CentralArray[$m][2] = '-' Then
				$g_CentralArray[$m][4] = StringTrimRight($g_CentralArray[$m][4], $Len)
			Else
				$g_CentralArray[$m][3] = StringTrimRight($g_CentralArray[$m][3], $Len)
			EndIf
		EndIf
	Next
	Local $Comp='-1', $DComp='-1'
	For $m = $g_CentralArray[0][1] To $g_CentralArray[0][0]
		If $g_CentralArray[$m][2] = '!' Then; chapters headline
			If $p_Show = 1 Then
				If $ModID <> '' Then; add last mod-item to chapter we're about to close -- otherwise it will be added to the next chapter
					_AI_SetModStateIcon($ModID)
					If Not StringInStr($g_CentralArray[$ModID][11], 'F') Then $g_CentralArray[$ChapterID][9]+=_AI_GetModState($ModID); sum up the current chapter count
				EndIf
				$ModID = ''; don't work on the mod-item we just processed
				_AI_SetModStateIcon($ChapterID)
				$ChapterID = $m
			EndIf
			ContinueLoop
		EndIf
		$Mod += 1
		If $g_CentralArray[$m][2] = '-' Then; mods headline
			_AI_SetMod_Disable($m); all are deselected at first
			$Comp = _IniRead($Select, $g_CentralArray[$m][0], '-1'); read the selected components of the mod.
			$DComp = _IniRead($DeSelect, $g_CentralArray[$m][0], '-1'); read the deselected components of the mod.
			If $Comp = '-1' And $DComp = '-1' Then
				GUICtrlSetData($m, GUICtrlRead($m, 1)&$Token); mark as a new mod
				$g_CentralArray[$m][4]&=$Mark; add a mark that is searchable
				$Found += 1
				ConsoleWrite('> New mod: ' & $g_CentralArray[$m][0] & ' = ' & $g_CentralArray[$m][2] & @CRLF)
			EndIf
			If $ModID <> '' And $p_Show Then
				_AI_SetModStateIcon($ModID)
				If Not StringInStr($g_CentralArray[$ModID][11], 'F') Then $g_CentralArray[$ChapterID][9]+=_AI_GetModState($ModID); sum up the current chapter count
			EndIf
			$ModID = $m
			ContinueLoop
		EndIf
		Local $ModCounter = $g_CentralArray[0][0] - $g_CentralArray[0][1]
		If _MathCheckDiv($m, 10) = 2 Then
			GUICtrlSetData($g_UI_Interact[9][1], $Mod * 100 / $ModCounter); set progress
			GUICtrlSetData($g_UI_Static[9][2], Round($Mod * 100 / $ModCounter, 0) & ' %')
		EndIf
		If StringInStr($g_CentralArray[$m][11], 'F') Then; special handling for fixed mods (note components still might be not-fixed)
			If StringRegExp($DComp, '(?i)(\A|\s)' & StringReplace($g_CentralArray[$m][2], '?', '\x3f') & '(\s|\z)') Then; if the component-number of the current mod was deselected
				; do nothing :D
			ElseIf $g_CentralArray[$m][10] = 2 Then; enable the standards of an item which has its own sub-tree (useful for new defaults)
				_AI_SetSUB_Enable($m, 0, 1)
			ElseIf StringInStr($g_CentralArray[$m][2], '?') Then; set the subs that were selected
				If StringRegExp($Comp, '(?i)(\A|\s)' & StringReplace($g_CentralArray[$m][2], '?', '\x3f') & '(\s|\z)') Then _AI_SetInSUB_Enable($m)
			ElseIf $g_CentralArray[$m][2] = '+' Then; enable default MUC
				_AI_SetMUC_Enable($m, 0, 1)
			ElseIf $g_CentralArray[$m][10] = 1 Then; set the MUC that were selected
				If StringRegExp($Comp, '(?i)(\A|\s)' & StringReplace($g_CentralArray[$m][2], '?', '\x3f') & '(\s|\z)') Then _AI_SetInMUC_Enable($m)
			Else; enable standard-components
				_AI_SetSTD_Enable($m)
			EndIf
			ContinueLoop
		EndIf
;		If Not IsDeclared('Comp') Then; this code is legacy and can never execute
;			ConsoleWrite($m & ': '& $g_CentralArray[$m][0] & ' == ' &  $g_CentralArray[$m][2] & @CRLF)
;			ConsoleWrite(GUICtrlRead($m) & @CRLF)
;			ContinueLoop
;		EndIf
		If $Comp = '-1' Then; entire mod was not selected
			If $g_CentralArray[$m][2] <> '+' Then; if it's not a tree heading, then check if it's a known component (even though it's not selected)
				If StringRegExp($DComp, '(?i)(\A|\s)' & StringReplace($g_CentralArray[$m][2], '?', '\x3f') & '(\s|\z)') = 0 Then; not a known component
					GUICtrlSetData($m, GUICtrlRead($m, 1)&$Token); mark as a new component
					$g_CentralArray[$m][3]&=$Mark; add a mark that is searchable
					$Found += 1
					ConsoleWrite('> New component: ' & $g_CentralArray[$m][0] & ' ' & $g_CentralArray[$m][2]  & @CRLF)
				EndIf
			EndIf
			If $p_Show Then __TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$m][5], 1+$g_CentralArray[$m][14])
			$g_CentralArray[$m][9] = 0
		ElseIf StringRegExp($Comp, '(?i)(\A|\s)' & StringReplace($g_CentralArray[$m][2], '?', '\x3f') & '(\s|\z)') Then; this matches all selected STD/MUC/SUB - in case of SUBs we use StringReplace since RegExp has it's own thoughts of a ? -- exact match for SUB in case multiple SUBs have same comp-num?sub-comp-num part but different answers
			;If $p_Show Then __TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$m][5], 2+$g_CentralArray[$m][14])
			If $g_CentralArray[$m][10] = 1 Then; component is member of a sub-tree (either SUB or MUC)
				If StringInStr($g_CentralArray[$m][2], '?') Then; it's a SUB-item
					Local $UserEditedValue=_IniRead($UserEdits, $g_CentralArray[$m][0]&';'&$g_CentralArray[$m][2], '')
					If $UserEditedValue <> '' Then
						GUICtrlSetData($m, $g_CentralArray[$m][3]&' => '&_GetTR($g_UI_Message, '4-L21')&' '&$UserEditedValue); => Your edited value is:
					EndIf
					_AI_SetInSUB_Enable($m); safer to use this function instead of code below, in case mod components were renumbered after selection was saved
					;Local $Component=StringRegExpReplace($g_CentralArray[$m][2], '\x5f.*', ''); x5f = '_' (unicode low line); strip answer, keep 'comp-num?sub-comp-num' part
					;If $p_Show Then __TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[_AI_GetStart($m, $Component)][5], 2+$g_CentralArray[$m][14])
					;$g_CentralArray[_AI_GetStart($m, $Component)][9] = 1
				Else; it's a MUC-item
					_AI_SetInMUC_Enable($m); safer to use this function instead of code below, in case mod components were renumbered after selection was saved
					;If $p_Show Then __TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[_AI_GetStart($m, '+')][5], 2+$g_CentralArray[$m][14])
					;$g_CentralArray[_AI_GetStart($m, '+')][9] = 1
					;$g_CentralArray[$ModID][9] += 1; increase due to the selected subtree
				EndIf
			Else; not member of a sub-tree, so it's a STD-item
				_AI_SetSTD_Enable($m); safer to use this function instead of code below, in case mod components were renumbered after selection was saved
			EndIf
			;$g_CentralArray[$m][9] = 1
			;$g_CentralArray[$ModID][9] += 1
		Else; component is not selected
			If $DComp = '-1' Or StringRegExp($DComp, '(?i)(\A|\s)' & StringReplace($g_CentralArray[$m][2], '?', '\x3f') & '(\s|\z)') = 0 Then
				If $g_CentralArray[$m][2] <> '+' Then
					GUICtrlSetData($m, GUICtrlRead($m, 1)&$Token); if component was selected before and is not listed as deselected, mark as new
					$g_CentralArray[$m][3]&=$Mark; add a mark that is searchable
					$Found += 1
					ConsoleWrite('> New unsure: '&$g_CentralArray[$m][0] & ' = ' & $g_CentralArray[$m][2] & @CRLF)
				EndIf
			EndIf
			If $p_Show Then __TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$m][5], 1+$g_CentralArray[$m][14])
			$g_CentralArray[$m][9] = 0
		EndIf
	Next
	If $p_Show Then
		_AI_SetModStateIcon($ModID); set the last mods headline
		$g_CentralArray[$ChapterID][9]+=_AI_GetModState($ModID); sum up the last chapter count
		_AI_SetModStateIcon($ChapterID)
		_GUICtrlTreeView_SelectItem($g_UI_Handle[0], $g_CentralArray[$g_TreeviewItem[1][0]][5], $TVGN_FIRSTVISIBLE)
	EndIf
	_GUICtrlTreeView_EndUpdate($g_UI_Handle[0]); now do the updates all at once
	If $Found > 0 And $p_Hint = 1 Then _Misc_MsgGUI(1, _GetTR($g_UI_Message, '0-B3'), StringFormat(_GetTR($g_UI_Message, '4-L18'), $Token, $Mark)); => Hint new content found. How to find / search it.
EndFunc   ;==>_Tree_Reload

; ---------------------------------------------------------------------------------------------
; Take read selection-array and sort it theme-wise for the selection-screen
; ---------------------------------------------------------------------------------------------
Func _Tree_SelectConvert($p_Array)
	Local $Trans = StringSplit(IniRead($g_ProgDir & '\Config\Translation-EN.ini', 'UI-Buildtime', 'Menu[2][2]', ''), '|'); => translations for themes
	Dim $Theme[$Trans[0]]
	For $a=1 to $p_Array[0][0]
		$Theme[Number($p_Array[$a][8])]&='|'&$a; add index-numbers to a string that represents a theme
	Next
	Local $Return[$p_Array[0][0]+1000][10]
	For $t=0 to $Trans[0]-1
		If $Theme[$t] = '' Then ContinueLoop; skip if nothing was assigned to the theme
		Local $Index=StringSplit(StringTrimLeft($Theme[$t], 1), '|'); get index-numbers of the array assigned to the theme
		Local $SameThemeMods[200][4], $Found=0; enable 200 additions
		For $i=1 to $Index[0]
			If StringRegExp($p_Array[$Index[$i]][3], '[0123456789]') Then; look for components
				$Found=1
				ExitLoop
			EndIf
		Next
		If $Found = 0 Then ContinueLoop; skip if no components are assigned (only something like a remaining SELECT-entry)
		For $i=1 to $Index[0]
			$SameThemeMods[0][0]+=1
			$SameThemeMods[$SameThemeMods[0][0]][0]=$p_Array[$Index[$i]][2]; setup
			$SameThemeMods[$SameThemeMods[0][0]][1]=$Index[$i]; index (start)
			While $i+1 <= $Index[0]; search for last item of the setup
				If $SameThemeMods[$SameThemeMods[0][0]][0] = $p_Array[$Index[$i+1]][2] And $Index[$i]+1= $Index[$i+1] Then
					$i+=1
				Else
					ExitLoop
				EndIf
			WEnd
			$SameThemeMods[$SameThemeMods[0][0]][2]=$Index[$i]; index (end)
			$SameThemeMods[$SameThemeMods[0][0]][3]=_IniRead($g_Setups, $SameThemeMods[$SameThemeMods[0][0]][0], $SameThemeMods[$SameThemeMods[0][0]][0]); get the name of the mod
		Next
		_ArraySort($SameThemeMods, 0, 1, $SameThemeMods[0][0], 3); sort the same "themed" mods based on the mods names
		For $s=1 to $SameThemeMods[0][0]; create output
			For $a=$SameThemeMods[$s][1] to $SameThemeMods[$s][2]
				$Return[0][0]+=1
				$Return[$Return[0][0]][0] = $p_Array[$a][0]; type
				$Return[$Return[0][0]][2] = $p_Array[$a][2]; setup
				$Return[$Return[0][0]][3] = $p_Array[$a][3]; component
				$Return[$Return[0][0]][4] = $p_Array[$a][4]; defaults
				$Return[$Return[0][0]][7] = $SameThemeMods[$s][3]; name
				$Return[$Return[0][0]][8] = $t; theme
				If $Return[$Return[0][0]][2] <> $Return[0][2] Then
					$Return[0][1]+=1
					$Return[0][2] = $Return[$Return[0][0]][2]
				EndIf
				$Return[$Return[0][0]][1]=$Return[0][1]; index-number of this mod/component in the select-array (will be used for connections)
				;											this is the same as $SelectArray[$s][1] in _Tree_Populate
			Next
		Next
	Next
	$Return[0][3]=$Trans[0]
	ReDim $Return[$Return[0][0]+1][10]
	Return $Return
EndFunc   ;==>Tree_SelectConvert

; ---------------------------------------------------------------------------------------------
; Read some parts of the InstallOrder.ini-file for Batch-installations
; ---------------------------------------------------------------------------------------------
Func _Tree_SelectReadForBatch()
	Local $Array=StringSplit(StringStripCR(FileRead($g_GConfDir&'\InstallOrder.ini')), @LF); go through InstallOrder.ini
	Local $Split, $Type, $Setup, $Return[$Array[0]][10], $Theme=-1
	For $a=1 to $Array[0]
		If StringLeft($Array[$a], 5) = 'ANN;#' Then $Theme+=1; don't read values because they are not consistent (usage of 5A)
		If StringRegExp($Array[$a], '(?i)\A(ANN|CMD|GRP)') Then ContinueLoop; skip annotations,commands,groups
		If StringRegExp($Array[$a], '\A(\s.*\z|\z)') Then ContinueLoop; skip empty lines
		If StringRegExp($Array[$a], '(?i);('&$g_Skip&');') Then ContinueLoop; skip mods that don't fit the selection
		$Split=StringSplit($Array[$a], ';')
		$Type = $Split[1]; lineType
		$Setup = $Split[2]; setup
		If $Return[0][0]>0 And $Setup = $Return[$Return[0][0]][2] Then ContinueLoop; don't create more than one entry for batch-mode
		$Return[0][0]+=1
		$Return[$Return[0][0]][0]=StringRegExpReplace($Type, '(?i)MUC|SUB', ''); linetype
		;  1 >> Index
		$Return[$Return[0][0]][2]= $Setup
		$Return[$Return[0][0]][3]='BATCH'; use something that won't break the dependency-management
		$Return[$Return[0][0]][4]='0000'; defaults for components
		;  5 >> Translation
		;  6 >> component requirements
		;  7 >> Name
		$Return[$Return[0][0]][8]=$Theme; theme
		If $Return[$Return[0][0]][2] <> $Return[0][2] Then
			$Return[0][1]+=1
			$Return[0][2] = $Return[$Return[0][0]][2]
		EndIf
		$Return[$Return[0][0]][1]=$Return[0][1]; $Index-number (will be used for connections)
	Next
	$Return[0][3]=$Theme
	$Return[0][4]=$Return[0][0]+$Return[0][1]+$Return[0][3]+$g_UI_Menu[8][10]+100; calculate Treeview-items: Items+Mods+Themes+GUI-items+Error-Margin for wrong calculation
	Global $g_CentralArray[$Return[0][4]][16];set size for global array before running _Tree_Populate -- if BWS goes kaboom, recalculate this number...
	ReDim $Return[$Return[0][0]+1][10]
	Return $Return
EndFunc   ;==>_Tree_SelectReadForBatch

; ---------------------------------------------------------------------------------------------
; Read the InstallOrder.ini-file which contains the installation-procedure
; ---------------------------------------------------------------------------------------------
Func _Tree_SelectRead($p_Admin=0)
	Local $Array=StringSplit(StringStripCR(FileRead($g_GConfDir&'\InstallOrder.ini')), @LF)
	Local $LastFullComp[3], $Split, $Return[$Array[0]+1][10]
	;FileWriteLine($g_LogFile, $g_Skip)
	For $a=1 to $Array[0]
		If StringRegExp($Array[$a], '\A(\s.*\z|\z)') Then ContinueLoop; skip empty lines
		If StringRegExp($Array[$a], '(?i)\A(ANN|CMD|GRP)') Then
			If $p_Admin=0 Then
				ContinueLoop; skip annotations,commands,groups
			Else
				$Split=StringSplit($Array[$a], ';')
				$Return[0][0]+=1
				$Return[$Return[0][0]][0]=$Split[1]; linetype
				$Return[$Return[0][0]][7]=$Split[2]; annotation/command-line/start-stop
				If $Split[0]>2 Then $Return[$Return[0][0]][6]=$Split[$Split[0]]; take whatever follows final semicolon as component requirements
;~ 				ConsoleWrite($Array[$a] & @CRLF)
				ContinueLoop
			EndIf
		EndIf
		$Split=StringSplit($Array[$a], ';')
		If $Split[0] < 6 Then; five semicolons = 6 split sections (LineType;Setup-Name;Component;Theme-Tag;Preselection-Bits;)
			_PrintDebug('Expected at least five semicolons on InstallOrder.ini line '&$a&': '&$Array[$a], 1)
			Exit
		EndIf
		; make sure any sub-components match the full components that precede them
		Local $Pos=StringInStr($Split[3], '?', 0, 1); position of first '?' in component, or zero if not found (first character position is 1)
		If $Pos < 2 Then; line is not a sub-component
			$LastFullComp[0] = $Array[$a]; InstallOrder.ini line
			$LastFullComp[1] = $Split[3]; component number
			$LastFullComp[2] = $Split[4]; theme/category/tag
			;FileWriteLine($g_LogFile, '$LastFullComp = '&$Array[$a])
		ElseIf StringLeft($Split[3], $Pos-1) <> $LastFullComp[1] Then; line is a sub-component without a preceding full component
			_PrintDebug('Sub-component line '&$Array[$a]&' does not match last full component number '&$LastFullComp[1], 1)
			Exit; error - this InstallOrder.ini is invalid and needs to be fixed manually
		ElseIf $Split[4] <> $LastFullComp[2] Then; line is a sub-component with a different theme
			_PrintDebug('Sub-component line '&$Array[$a]&' does not match last full component theme '&$LastFullComp[2], 1)
			$Split[4] = $LastFullComp[2]; change theme of subcomponent to match preceding full component and continue
		ElseIf $p_Admin = 0 And StringRegExp($LastFullComp[0], '(?i);('&$g_Skip&');') Then
			;FileWriteLine($g_LogFile, '_Tree_SelectRead() skipped '&$Array[$a]&' because preceding component '&$LastFullComp[0]&' was purged')
			ContinueLoop; skip subcomponents if the preceding full component was purged
		EndIf
		If $p_Admin = 0 And StringRegExp($Array[$a], '(?i);('&$g_Skip&');') Then ContinueLoop; skip mods that don't fit the selection
		$Return[0][0]+=1
		$Return[$Return[0][0]][0]=$Split[1]; linetype
		;  1 >> Index (points to the 'root'/'headline' of a sequential series of lines for the same mod)
		$Return[$Return[0][0]][2]=$Split[2]; setup
		$Return[$Return[0][0]][3]=$Split[3]; component
		$Return[$Return[0][0]][4]=$Split[5]; pre-selection bits
		;  5 >> Translation
		$Return[$Return[0][0]][6]=$Split[6]; component requirements
		;  7 >> Name (is this GRP name / description for CMD/ANN lines?)
		$Return[$Return[0][0]][8]=$Split[4]; theme
		If $Return[$Return[0][0]][8] <> $Return[$Return[0][0]-1][8] Then $Return[0][3]+=1
		If $Return[$Return[0][0]][2] <> $Return[0][2] Then; setup-name of previous line was different
			$Return[0][1]+=1; increment highest index-number
			$Return[0][2] = $Return[$Return[0][0]][2]; remember current line setup-name
		EndIf
		$Return[$Return[0][0]][1]=$Return[0][1]; index-number (will be used for connections)
	Next
	$Return[0][4]=$Return[0][0]+$Return[0][1]+$Return[0][3]+$g_UI_Menu[8][10]+100; calculate Treeview-items: Items+Mods+Themes+GUI-items+Error-Margin for wrong calculation
	Global $g_CentralArray[$Return[0][4]][16];set size for global array before running _Tree_Populate -- if BWS goes kaboom, recalculate this number...
	ReDim $Return[$Return[0][0]+1][10]
	Return $Return
EndFunc   ;==>_Tree_SelectRead

; ---------------------------------------------------------------------------------------------
; Add nulls in front of the component number so the length is always 4
; ---------------------------------------------------------------------------------------------
Func _Tree_SetLength($p_String)
	If $p_String = '-' Then Return $p_String
	While StringLen($p_String) < 4
		$p_String = 0 & $p_String
	WEnd
	Return $p_String
EndFunc   ;==>_Tree_SetLength

; ---------------------------------------------------------------------------------------------
; Sets the treeview-items to preselected defaults
; ---------------------------------------------------------------------------------------------
Func _Tree_SetPreSelected($p_Num='')
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Tree_SetPreSelected')
	Local $Current = ''
	Local $Type = _Selection_GetCurrentInstallType()
	_Misc_ProgressGUI(_GetTR($g_UI_Message, '4-T1'), _GetTR($g_UI_Message, '4-L2')); => setting entries
	If StringLen($Type)=2 then
		_Tree_Reload(1, 0, $g_GConfDir&'\Preselection'&$Type&'.ini'); show reload the settings from a file without hints about new items
	Else
		_GUICtrlTreeView_BeginUpdate($g_UI_Handle[0])
		_AI_SetDefaults()
		_GUICtrlTreeView_EndUpdate($g_UI_Handle[0])
	EndIf
	If $Type <> '00' Then; don't auto-solve conflicts and dependencies when reloading "last saved selection"
		_Depend_AutoSolve('DS', 2, 1); disable mods/components with unsatisfied dependencies, skip warning rules
		_Depend_AutoSolve('C', 2, 1); disable conflict losers, skip warning rules
		_Depend_AutoSolve('DS', 2, 1); disable mods/components with unsatisfied dependencies, skip warning rules
	EndIf
	If $p_Num <> '' Then _Misc_SetTab($p_Num); selected another version on selection-tab 2
EndFunc   ;==>_Tree_SetPreSelected

; ---------------------------------------------------------------------------------------------
; (De)Select (mostly) all mods of a certain group/theme (Quest, NPC...) or special selections
; ---------------------------------------------------------------------------------------------
Func _Tree_SetSelectedGroup($p_Num, $p_State)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Tree_SetSelectedGroup')
	_GUICtrlTreeView_BeginUpdate($g_UI_Handle[0])
	Local $FirstModItem, $OldCompilation = $g_Compilation
	If $p_Num > $g_UI_Menu[0][2]-2 Then; theme groups = menu - all + select entries
		$FirstModItem = _Tree_SetSelectedGroup_Special($p_Num, $p_State)
	Else
		If $g_LimitedSelection = 0 And $p_State = 1 Then; the user did not limit himself to a mod-category while adding mods
			$FirstModItem = _Tree_SetSelectedGroup_Request($p_Num)
		Else
			$FirstModItem = _Tree_SetSelectedGroup_Limited($p_Num, $p_State)
		EndIf
	EndIf
	_GUICtrlTreeView_EndUpdate($g_UI_Handle[0])
	$g_Compilation = $OldCompilation
	Return $FirstModItem
EndFunc   ;==>_Tree_SetSelectedGroup

; ---------------------------------------------------------------------------------------------
;	This is a group that was defined from the chapters of the BWP. Warn user if mods that will be >>enabled<< don't match the current version.
; ---------------------------------------------------------------------------------------------
Func _Tree_SetSelectedGroup_Request($p_Num)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Tree_SetSelectedGroup_Request')
	Local $Array[750][2], $FirstModItem, $Test, $Compilation[5]=[4, 'R', 'S', 'T', 'E'], $OldCompilation = $g_Compilation
	For $c = $g_CentralArray[0][1] To $g_CentralArray[0][0]; loop through all mod-headlines and components
		If $g_CentralArray[$c][2] = '' Then ContinueLoop
		If $g_CentralArray[$c][2] <> '-' Then ContinueLoop
		If IsString($p_Num) Or StringRegExp($g_CentralArray[$c][1], '(\A|,)'&$p_Num&'(\z|,)') Then; is element selected?
			If $FirstModItem = '' Then $FirstModItem = $g_CentralArray[$c][5]
			$Array[0][0]+=1
			$Test= _AI_GetSelect($c, 1)
			$Array[$Array[0][0]][0]=$c
			$Array[$Array[0][0]][1]=$Test
			If $Test < 0 Then $Array[0][1]&=$g_CentralArray[$c][4] &'|'
		EndIf
	Next
	ReDim $Array[$Array[0][0]+1][2]
	Local $Request
	If $Array[0][1] <> '' Then
		$Request = _Misc_MsgGUI(3, _GetTR($g_UI_Message, '0-T1'), $Array[0][1]&'|'&  _GetTR($g_UI_Message, '4-L7'), 3, _GetTR($g_UI_Message, '8-B1'), _GetTR($g_UI_Message, '8-B5'), _GetTR($g_UI_Message, '8-B2')); => select mods from other versions?
		If $Request = 1 Then Return; user does not want to add this
	EndIf
	For $a=1 to $Array[0][0]
		If $Array[$a][1] < 0 And $Request = 3 Then
			$g_Compilation = $Compilation[-$Array[$a][1]]
		Else
			$g_Compilation = $OldCompilation
		EndIf
		_AI_SetMod_Enable($Array[$a][0])
	Next
	Return $FirstModItem
EndFunc   ;==>_Tree_SetSelectedGroup_Request

; ---------------------------------------------------------------------------------------------
;	This is a group that was defined from the chapters of the BWP. The user does not want mods that don't match. Also used for disabling not limited groups.
; ---------------------------------------------------------------------------------------------
Func _Tree_SetSelectedGroup_Limited($p_Num, $p_State)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Tree_SetSelectedGroup_Limited')
	Local $FirstModItem
	For $c = $g_CentralArray[0][1] To $g_CentralArray[0][0]; loop through all mod-headlines and components
		If $g_CentralArray[$c][2] = '' Then ContinueLoop
		If $g_CentralArray[$c][2] <> '-' Then ContinueLoop
		If IsString($p_Num) Or StringRegExp($g_CentralArray[$c][1], '(\A|,)'&$p_Num&'(\z|,)') Then
			If $FirstModItem = '' Then $FirstModItem = $g_CentralArray[$c][5]
			If $p_State = 1 Then
				_AI_SetMod_Enable($c); set checkboxes
			Else
				If Not StringInStr($g_CentralArray[$c][11], 'F') Then _AI_SetMod_Disable($c); or deselect
			EndIf
		EndIf
	Next
	Return $FirstModItem
EndFunc   ;==>_Tree_SetSelectedGroup_Limited

; ---------------------------------------------------------------------------------------------
;	This is a special group that was defined in the Game.ini.
; ---------------------------------------------------------------------------------------------
Func _Tree_SetSelectedGroup_Special($p_Num, $p_State)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Tree_SetSelectedGroup_Special')
	Local $FirstModItem
	$g_Compilation = 'E'
	Local $Num=$p_Num - ($g_UI_Menu[0][2]-2)
	Local $Mod, $RemoveMod, $Comp
	For $c = $g_CentralArray[0][1] To $g_CentralArray[0][0]; loop through all mod-headlines and components
		If $g_CentralArray[$c][2] = '' Then ContinueLoop
		If $g_CentralArray[$c][2] <> '-' Then ContinueLoop
		If StringRegExp($g_Groups[$Num][1], '(?i)(\A|,)'&$g_CentralArray[$c][0]&'(\x28|\x5b)') Then; is element effected?
			$Mod=StringRegExp($g_Groups[$Num][1], '(?i)'&$g_CentralArray[$c][0]&'[^\x29^\x5d]*[\x29|\x5d]', 3)
			If Not IsArray($Mod) Then
				$c=_AI_GetStart($c+1, '-', '+')-1
				If $c<0 Then ExitLoop
				ContinueLoop
			EndIf
			If StringInStr($Mod[0], ']') Then
				$RemoveMod=1
			Else
				$RemoveMod=0
				If $FirstModItem = '' Then $FirstModItem = $g_CentralArray[$c][5]; remind the item that will be shown to the user
			EndIf
			$Comp=StringRegExpReplace($Mod[0], '\A[^\x28|^\x5b]*', '')
			If $Comp = '(-)' Then
				If $p_State = 1 And $RemoveMod =0 Then
					_AI_SetMod_Enable($c, 1); set checkboxes
				ElseIf $p_State = 0 And $RemoveMod =1 Then
					; this would only remove a conflict, but since things are deselected during this run, just do nothing
				Else
					_AI_SetMod_Disable($c); deselect checkboxes
				EndIf
				$c=_AI_GetStart($c+1, '-', '+')-1
				If $c<0 Then ExitLoop
			Else
				$c+=1
				If $RemoveMod = 1 Then
					If $p_State = 0 Then; this would only remove a conflict, but since things are deselected during this run, just do nothing
						$c=_AI_GetStart($c+1, '-', '+')-1
						If $c<0 Then ExitLoop
						ContinueLoop
					Else
						$Comp='('&StringRegExpReplace($Comp, '\A.|.\z', '')&')'
					EndIf
				EndIf
				While $g_CentralArray[$c][2] <> '-'
					If StringRegExp($g_CentralArray[$c][2], '(?i)\A' & $Comp & '\z') Then
						If $g_CentralArray[$c][10] = 2 Then; enable the standards of an item which has SUBs (useful for modified mods)
							If $p_State = 1 And $RemoveMod =0 Then
								_AI_SetSUB_Enable($c, 0, 1)
							ElseIf $p_State = 0 And $RemoveMod =1 Then
							Else
								_AI_SetSUB_Disable($c)
							EndIf
						ElseIf StringInStr($g_CentralArray[$c][2], '?') Then; set the SUB
							If StringRegExp($Comp, '(?i)(\A|\s)' & StringReplace($g_CentralArray[$c][2], '?', '\x3f') & '(\s|\z)') Then
								If $p_State = 1 And $RemoveMod =0 Then
									_AI_SetInSUB_Enable($c)
								ElseIf $p_State = 1 And $RemoveMod =1 Then
								Else
									_AI_SetInSUB_Disable($c)
								EndIf
							EndIf
						ElseIf $g_CentralArray[$c][10] = 1 Then; set the MUC
							If $p_State = 1 And $RemoveMod =0 Then
								_AI_SetInMUC_Enable($c)
							ElseIf $p_State = 0 And $RemoveMod =1 Then
							Else
								_AI_SetInMUC_Disable($c)
							EndIf
						Else; enable standard-components
							If $p_State = 1 And $RemoveMod =0 Then
								If $g_CentralArray[$c][9]=0 Then _AI_SetSTD_Enable($c)
							ElseIf $p_State = 0 And $RemoveMod =1 Then
							Else
								If $g_CentralArray[$c][9]=1 Then _AI_SetSTD_Disable($c)
							EndIf
						EndIf
					EndIf
					$c+=1
					If $c > $g_CentralArray[0][0] Then ExitLoop
				WEnd
			EndIf
		EndIf
	Next
	Return $FirstModItem
EndFunc   ;==>_Tree_SetSelectedGroup_Special

; ---------------------------------------------------------------------------------------------
; toggles the expanded-state of the treeview
; ---------------------------------------------------------------------------------------------
Func _Tree_ShowComponents($p_Show = '')
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Tree_ShowComponents')
	If $p_Show = '' Then _GUICtrlTreeView_BeginUpdate($g_UI_Handle[0])
	If $p_Show <> '' Then $g_GUIFold = Not $p_Show
	If $g_GUIFold = '0' Then
		GUICtrlSetData($g_UI_Menu[1][5], _GetTR($g_UI_Message, '4-M1')); => hide components
		IniWrite($g_UsrIni, 'Options', 'UnFold', '1')
		_GUICtrlTreeView_Expand($g_UI_Handle[0], 0, True)
		_GUICtrlTreeView_SelectItem($g_UI_Handle[0], $g_CentralArray[$g_CHTreeviewItem[0]][5], $TVGN_FIRSTVISIBLE)
		$g_GUIFold = '1'
	Else
		GUICtrlSetData($g_UI_Menu[1][5], _GetTR($g_UI_Message, '4-M2')); => show components
		IniWrite($g_UsrIni, 'Options', 'UnFold', '0')
		_GUICtrlTreeView_Expand($g_UI_Handle[0], 0, False)
		_GUICtrlTreeView_SelectItem($g_UI_Handle[0], $g_CentralArray[$g_CHTreeviewItem[0]][5], $TVGN_FIRSTVISIBLE)
		$g_GUIFold = '0'
	EndIf
	If $p_Show = '' Then _GUICtrlTreeView_EndUpdate($g_UI_Handle[0])
EndFunc   ;==>_Tree_ShowComponents