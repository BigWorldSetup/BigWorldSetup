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
	$File=$p_File
	If $File = '' Then
		$File = FileSaveDialog(_GetTR($g_UI_Message, '4-F2'), $g_ProgDir, 'Ini files (*.ini)', 2, 'BWS-Selection.ini', $g_UI[0]); => save selection as
		If @error Then Return
		If StringRight($File, 4) <> '.ini' Then $File&='.ini'
	EndIf
	_Tree_GetCurrentSelection(0)
	FileClose(FileOpen($File, 2))
	If StringInStr ($p_File, 'PreSelection00.ini') Then; adjust current date in the preselection-hints
		For $a=1 to $g_ATrans[0]
			$Text=IniRead($g_GConfDir&'\Mod-'&$g_ATrans[$a]&'.ini', 'Preselect', '00', '')
			$Text=StringRegExpReplace($Text, '\x28.*\x29', @MDAY&'.'&@MON&'.'&@YEAR)
			IniWrite($g_GConfDir&'\Mod-'&$g_ATrans[$a]&'.ini', 'Preselect', '00', $Text)
		Next
		IniWrite($g_UsrIni, 'Options', 'InstallType', '01'); auto-export will be No 1.
	EndIf
	IniWriteSection($File, 'Save', IniReadSection($g_UsrIni, 'Save'))
	IniWriteSection($File, 'DeSave', IniReadSection($g_UsrIni, 'DeSave'))
	$g_Flags[24]=0
EndFunc   ;==>_Tree_Export

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
	$Setup = $g_CentralArray[$g_CentralArray[0][1]][0]
; ---------------------------------------------------------------------------------------------
; loop through the elemets of the main-array. We make heavy usage of the main-array here. Now you know why it's that important. :)
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
	$Array=StringSplit(StringTrimLeft($Doubles, 1) , ','); work on those mods
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
			$Output=''
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
	$Split = StringSplit(IniRead($g_TRAIni, 'UI-Buildtime', 'Menu[2][1]', ''), '|'); => Special|All
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
	Local $ch, $cs, $cc, $ReadSection, $Type, $ATMod, $ATIdx, $NotFixedItems
	_Misc_ProgressGUI(_GetTR($g_UI_Message, '0-T2'), _GetTR($g_UI_Message, '0-L3')); => building dependencies-table
	GUISwitch($g_UI[0])
	_Tree_PurgeUnNeeded(); calculate unsuited mods
	$g_Groups=IniReadSection($g_GConfDir&'\Game.ini', 'Groups'); replace the ampersands with a vertical line so that regex will work on these components
	For $g = 1 To $g_Groups[0][0]
		$g_Groups[$g][1]=StringReplace($g_Groups[$g][1], '&', '|')
	Next
	$g_Connections=IniReadSection($g_GConfDir&'\Game.ini', 'Connections')
	If $g_Flags[14] = 'BWP' Then
		$Setup=_Tree_SelectReadForBatch()
		_Depend_TrimBWSConnections(); remove connections for BWS-installs (which contain component-numbers)
	Else; do a bws install
		$Setup=_Tree_SelectRead(); read the select.txt-file
		If $p_Show Then
			If $g_Flags[21] = 0 Then $Setup=_Tree_SelectConvert($Setup); convert it to a theme-sorted view
		Else
			$Trans = StringSplit(IniRead($g_TRAIni, 'UI-Buildtime', 'Menu[2][2]', ''), '|'); => translations for themes
			$Setup[0][3] = $Trans[0]
		EndIf
	EndIf
	$Index=_Depend_PrepareBuildIndex($g_Connections, $Setup)
	$g_Connections=_Depend_PrepareBuildSentences($g_Connections)
	$g_Connections=_Depend_PrepareToUseID($g_Connections)
	GUICtrlSetData($g_UI_Interact[9][1], 20); set the progress
	GUICtrlSetData($g_UI_Static[9][2], '20 %')
	GUICtrlSetData ($g_UI_Static[9][1], _GetTR($g_UI_Message, '0-L2')); => search component
	GUICtrlSetData($g_UI_Interact[9][1], 32); set the progress
	GUICtrlSetData($g_UI_Static[9][2], '32 %')
	ReDim $Setup[$Setup[0][0] + 2][10]
	ReDim $g_TreeviewItem[$Setup[0][1] + 1][250]; if the BWS goes kaboom, adjust this numbers...
	ReDim $g_CHTreeviewItem[$Setup[0][3]+1]
	$ATMod=_IniReadSection($g_GConfDir&'\Mod-'&$g_ATrans[$g_ATNum]&'.ini', 'Description')
	$ATIdx=_IniCreateIndex($ATMod)
	$Setup[0][8]=-1
	_Tree_GetTags()
	$g_UI_Menu[0][1]='|'
	$Compnote = _GetTR($g_UI_Message, '4-L1'); => in the future you will be able to select components
	$ConnNote = IniRead($g_TRAIni, 'DP-BuildSentences', 'L9', ''); => dependencies and conflicts
	_GUICtrlTreeView_BeginUpdate($g_UI_Handle[0])
	For $s = 1 To $Setup[0][0]; loop through the elements of the array (contains the chapters)
		If $Setup[$s][2] <> $Setup[$s-1][2] Then
			$Setup[0][2]+=1; set old compnumber
			$cs+=1
			GUICtrlSetData($g_UI_Interact[9][1], 32+($cs * 45 / $Setup[0][1])); set the progress
			If _MathCheckDiv($Setup[0][2], 10) = 2 Then GUICtrlSetData($g_UI_Static[9][2], Round(32+($cs * 45 / $Setup[0][1]), 0) & ' %')
			$ReadSection = IniReadSection($g_ModIni, $Setup[$s][2])
			$NotFixedItems = _IniRead($ReadSection, 'NotFixed', '') ; see if there are not fixed items (among the fixed)
			$Setup[$s][5] = _GetTra($ReadSection, 'T+')
			If $Setup[$s][5]='' Then
				If StringInStr(_IniRead($ReadSection, 'Type', ''), 'F') And Not StringRegExp($g_fLock, ','&$Setup[$s][2]&'(,|\z)') Then $g_fLock&=','&$Setup[$s][2]
				$Tmp=$s; see for more components of this mod
				While $Setup[$Tmp+1][2] = $Setup[$s][2]
					$Tmp+=1
					If $Tmp = $Setup[0][0] Then ExitLoop
				WEnd
				$s=$Tmp
				ContinueLoop
			EndIf
			If $Setup[$s][8]+3 > $g_Tags[0][0] Then $Setup[$s][8] = 0; don't crash if tag does not fit -> move it to general
			If $g_CHTreeviewItem[$Setup[$s][8]] = '' Then; if current tree does not exist, create it
				If $g_Flags[21]=0 Then; new theme-based-sorting
					$g_CHTreeviewItem[$Setup[$s][8]] = GUICtrlCreateTreeViewItem($g_Tags[$Setup[$s][8]+3][1], $g_UI_Interact[4][1]); create a treeviewitem (gui-element) for the chapter itself (headline)
				Else
					$g_CHTreeviewItem[$Setup[$s][8]] = $g_UI_Interact[4][1]
				EndIf
				GUICtrlSetState($g_CHTreeviewItem[$Setup[$s][8]], $GUI_DEFBUTTON); only set the chapter-line bold
				$g_CentralArray[$g_CHTreeviewItem[$Setup[$s][8]]][1]= $Setup[$s][8]; tag
				$g_CentralArray[$g_CHTreeviewItem[$Setup[$s][8]]][2]= '!'; tag as no component
				$g_CentralArray[$g_CHTreeviewItem[$Setup[$s][8]]][5] = GUICtrlGetHandle($g_CHTreeviewItem[$Setup[$s][8]]); handle
				$g_CentralArray[$g_CHTreeviewItem[$Setup[$s][8]]][9]= 0; set "current selected mods per chapter" counter
				$g_CentralArray[$g_CHTreeviewItem[$Setup[$s][8]]][10]= 0; set "mods per chapter" counter
				If Not StringInStr($g_UI_Menu[0][1], '|'&$Setup[$s][8]&'|') Then $g_UI_Menu[0][1]&=$Setup[$s][8]&'|'; save used themes for the creation of menus
			EndIf
			$Setup[$s][7]=_IniRead($ReadSection, 'Name', $Setup[$s][2])
			$Ext = _IniRead($ATMod, $Setup[$s][2], '', $ATIdx[Asc(StringLower(StringLeft($Setup[$s][2], 1)))]); gather the mods description
			If $Ext = '' Then ConsoleWrite('!No mod description: '&$Setup[$s][2]&@CRLF)
			$g_TreeviewItem[$cs][0] = GUICtrlCreateTreeViewItem($Setup[$s][7]&' ['&$Setup[$s][5]& ']', $g_CHTreeviewItem[$Setup[$s][8]]); create a treeviewitem (gui-element) for the mod itself (headline)
			$g_CentralArray[$g_CHTreeviewItem[$Setup[$s][8]]][10]+= 1; increase "mods per chapter" counter
			GUICtrlSetState($g_TreeviewItem[$cs][0], $GUI_DEFBUTTON); only set the mod-line bold
; ---------------------------------------------------------------------------------------------
; Create the entries for the mod in an two-dimensional main-array.
; ---------------------------------------------------------------------------------------------
			$g_CentralArray[$g_TreeviewItem[$cs][0]][0] = $Setup[$s][2]; current setup
			$g_CentralArray[$g_TreeviewItem[$cs][0]][1] = $Setup[$s][8]; tag
			$g_CentralArray[$g_TreeviewItem[$cs][0]][2] = '-'; tag as no component
			$g_CentralArray[$g_TreeviewItem[$cs][0]][3] = '-'; it's a mod, there is no component-discription
			$g_CentralArray[$g_TreeviewItem[$cs][0]][4] = $Setup[$s][7]; mod description
			$g_CentralArray[$g_TreeviewItem[$cs][0]][5] = GUICtrlGetHandle($g_TreeviewItem[$cs][0]); handle
			$Test = _Depend_ItemGetConnections($g_Connections, $g_TreeviewItem[$cs][0],  $Index[$Setup[$s][1]][2], $Setup[$s][2])
			If $Test <> '' Then
				$g_CentralArray[$g_TreeviewItem[$cs][0]][6] = StringReplace($Ext, '|', @CRLF) & @CRLF & @CRLF & $ConnNote & $Test
			Else
				$g_CentralArray[$g_TreeviewItem[$cs][0]][6] = StringReplace($Ext, '|', @CRLF)
			EndIf
			$g_CentralArray[$g_TreeviewItem[$cs][0]][7] = _IniRead($ReadSection, 'Size', '102400'); get the size of the mod
			$g_CentralArray[$g_TreeviewItem[$cs][0]][8] = $Setup[$s][5] ; get the language of the mod
			$g_CentralArray[$g_TreeviewItem[$cs][0]][9] = 0
			$g_CentralArray[$g_TreeviewItem[$cs][0]][10] = 0
			$g_CentralArray[$g_TreeviewItem[$cs][0]][11] = _IniRead($ReadSection, 'Type', '')
			$g_CentralArray[$g_TreeviewItem[$cs][0]][12] = $Setup[$s][4]
			$g_CentralArray[$g_TreeviewItem[$cs][0]][15] = _IniRead($ReadSection, 'Rev', '')
			If $g_Flags[14] = 'BWP' Then; prevent search if batch-install is used
				Local $ReadSection[1][2]
			ElseIf $Setup[$s][5] = '--' Then
				$ReadSection=IniReadSection($g_GConfDir&'\WeiDU-'&_GetTra($ReadSection, 'T')&'.ini', $Setup[$s][2])
			Else
				$ReadSection=IniReadSection($g_GConfDir&'\WeiDU-'&$Setup[$s][5]&'.ini', $Setup[$s][2])
			EndIf
			If StringInStr($g_CentralArray[$g_TreeviewItem[$cs][0]][11], 'F') And Not StringRegExp($g_fLock, ','&$Setup[$s][2]&'(,|\z)') Then $g_fLock&=','&$Setup[$s][2]
			If $p_Show Then
				; 0x1a8c14 lime = recommanded / 0x000070 dark = standard / 0xe8901a = tactics / 0xad1414 light = expert / checkbox-default = 0x1c5180
				If StringInStr($g_CentralArray[$g_TreeviewItem[$cs][0]][11], 'R') Then
					If $g_Flags[14]='BWP' Then $Type='1111'; set defaults for batch install
					GUICtrlSetColor($g_TreeviewItem[$cs][0], 0x1a8c14); lime = recommanded
				ElseIf StringInStr($g_CentralArray[$g_TreeviewItem[$cs][0]][11], 'S') Then
					If $g_Flags[14]='BWP' Then $Type='0111'; set defaults for batch install
					GUICtrlSetColor($g_TreeviewItem[$cs][0], 0x000070); dark = standard
				ElseIf StringInStr($g_CentralArray[$g_TreeviewItem[$cs][0]][11], 'T') Then
					If $g_Flags[14]='BWP' Then $Type='0011'; set defaults for batch install
					GUICtrlSetColor($g_TreeviewItem[$cs][0], 0xe8901a); yellow = tactics
				Else
					If $g_Flags[14]='BWP' Then $Type='0001'; set defaults for batch install
					GUICtrlSetColor($g_TreeviewItem[$cs][0], 0xad1414); light = expert
				EndIf
			EndIf
			$cc = 0
		Else
			$Setup[$s][5]=$Setup[$s-1][5]
			$Setup[$s][7]=$Setup[$s-1][7]
		EndIf
		$cc+=1
		$Dsc = _IniRead($ReadSection, '@' & $Setup[$s][3], $Compnote)
		If @error = -1 Then ConsoleWrite($Setup[$s][2]& ' @' & $Setup[$s][3] & @CRLF)
; ---------------------------------------------------------------------------------------------
; SUB: A selectable sub-component/question  (SUB-Selectionen are counted as possible selections to [10][0])
; ---------------------------------------------------------------------------------------------
		If StringInStr($Setup[$s][3], '?') Then
			$n = 1
			While StringInStr($Setup[$s-$n][3], '?')
				$n += 1
			WEnd
			$g_TreeviewItem[$cs][$cc] = GUICtrlCreateTreeViewItem($Dsc, $g_TreeviewItem[$cs][$cc - $n]); create a "sub-"treeviewitem (gui-element) for the component
			If $g_CentralArray[$g_TreeviewItem[$cs][$cc - $n]][10] = 0 Then; this was markes a a normal component before
				$g_CentralArray[$g_TreeviewItem[$cs][$cc - $n]][10] = 2; this item has it's own subtree now
				$t = $s-$n+1
				While StringInStr($Setup[$t+1][3], '?')
					$t += 1
				WEnd
				$g_CentralArray[$g_TreeviewItem[$cs][0]][10]+=Number(StringRegExpReplace($Setup[$t][3], '\A\d{1,}\x3f|\x5f.*', '')); increase the possible selection
			EndIf
			$g_CentralArray[$g_TreeviewItem[$cs][$cc]][8] = $Setup[$s][5] ; available languages
			$g_CentralArray[$g_TreeviewItem[$cs][$cc]][10] = 1 ; is subitem
; ---------------------------------------------------------------------------------------------
; MUC create a subtree-item since the component has it's own number (MUC-Select-Headlines are not counted as possible selections to [10][0])
; ---------------------------------------------------------------------------------------------
		ElseIf $Setup[$s][0] = 'MuC'  Then
			If $Setup[$s][3] = 'Init' Then
				$g_TreeviewItem[$cs][$cc] = GUICtrlCreateTreeViewItem(StringRegExpReplace(_IniRead($ReadSection, '@'&$Setup[$s+1][3], ''), '\s?->.*\z', ''), $g_TreeviewItem[$cs][0]); create a treeviewitem (gui-element) for the component
				$g_CentralArray[0][0] = $g_TreeviewItem[$cs][$cc] ; last item in array
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][0] = $g_CentralArray[$g_TreeviewItem[$cs][0]][0] ; setup-name
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][2] = '+'
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][4] = $g_CentralArray[$g_TreeviewItem[$cs][0]][4]
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][5] = GUICtrlGetHandle($g_TreeviewItem[$cs][$cc]); handle
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][8] = $Setup[$s][5]
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][9] = 0
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][10] = 0
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][11] = $g_CentralArray[$g_TreeviewItem[$cs][0]][11]
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][12] = $Setup[$s][4]
				;$g_CentralArray[$g_TreeviewItem[$cs][$cc]][13] = $g_CentralArray[$g_TreeviewItem[$cs][0]][13]
				$g_CentralArray[$g_TreeviewItem[$cs][0]][10]+=2; increase possible selections
				$g_CentralArray[0][0] = $g_TreeviewItem[$cs][$cc] ; last item in array
				$cc+=1
				ContinueLoop
			Else
				$n = 1
				While StringRegExp($Setup[$s-$n][3], '\A\d{1,}\z'); get the select-item
					$n+=1
				WEnd
				$g_TreeviewItem[$cs][$cc] = GUICtrlCreateTreeViewItem(_Tree_SetLength($Setup[$s][3])&': ' &StringRegExpReplace($Dsc, '\A.*\s?->\s?', ''), $g_TreeviewItem[$cs][$cc-$n-1]); create a treeviewitem (gui-element) for the component
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][8] = $Setup[$s][5]; language
				$g_CentralArray[$g_TreeviewItem[$cs][$cc]][10] = 1; this item is part of a subtree
			EndIf
; ---------------------------------------------------------------------------------------------
; this is a normal component
; ---------------------------------------------------------------------------------------------
		Else
			$g_TreeviewItem[$cs][$cc] = GUICtrlCreateTreeViewItem(_Tree_SetLength($Setup[$s][3])&': ' &$Dsc, $g_TreeviewItem[$cs][0])
			$g_CentralArray[$g_TreeviewItem[$cs][$cc]][8] = $Setup[$s][5]; possible languages
			$g_CentralArray[$g_TreeviewItem[$cs][$cc]][10] = 0; this item is _not_ part of a subtree
			$g_CentralArray[$g_TreeviewItem[$cs][0]][10]+=1; increase possible selections
		EndIf
; ---------------------------------------------------------------------------------------------
; Create the other entries for the component in the two-dimensional main-array.
; ---------------------------------------------------------------------------------------------
		$g_CentralArray[0][0] = $g_TreeviewItem[$cs][$cc] ; last item in array
		$g_CentralArray[$g_TreeviewItem[$cs][$cc]][0] = $g_CentralArray[$g_TreeviewItem[$cs][0]][0] ; setup-name
		$g_CentralArray[$g_TreeviewItem[$cs][$cc]][1] = $Setup[$s][8] ; tag
		$g_CentralArray[$g_TreeviewItem[$cs][$cc]][2] = $Setup[$s][3] ; componentnumber
		$g_CentralArray[$g_TreeviewItem[$cs][$cc]][3] = $Dsc ; componentdescription
		$g_CentralArray[$g_TreeviewItem[$cs][$cc]][4] = $Setup[$s][7]; mod description
		$g_CentralArray[$g_TreeviewItem[$cs][$cc]][5] = GUICtrlGetHandle($g_TreeviewItem[$cs][$cc]); handle
		$Test = _Depend_ItemGetConnections($g_Connections, $g_TreeviewItem[$cs][$cc], $Index[$Setup[$s][1]][2], $Setup[$s][2], $Setup[$s][3]); get dependencies and conflicts; takes 800 ms
		$g_CentralArray[$g_TreeviewItem[$cs][$cc]][11] = $g_CentralArray[$g_TreeviewItem[$cs][0]][11]
		If $g_Flags[14]='BWP' Then; batch-install
			$g_CentralArray[$g_TreeviewItem[$cs][$cc]][12] = $Type; insert calculated component type
		Else
			$g_CentralArray[$g_TreeviewItem[$cs][$cc]][12] = $Setup[$s][4]
		EndIf
		If $NotFixedItems <> '' Then; see if the item is not among the fixed ones
			$ItemIsNotFixed = StringRegExp($NotFixedItems, '(?i)(\A|\s)' & $Setup[$s][3] & '(\s|\z)'); Note: Not checking for SUBs here.
			If $ItemIsNotFixed Then $g_CentralArray[$g_TreeviewItem[$cs][$cc]][11]=StringRegExpReplace($g_CentralArray[$g_TreeviewItem[$cs][$cc]][11], '\AF,|,F', '')
		EndIf
		If $p_Show Then
			$Ext = ''; _IniRead($ReadSection, 'E' & $Setup[$s][3], ''); read the components extended info ==> disabled since no info exists and it takes ~450 ms!!
			If $Test <> '' Then
				If $Ext <> '' Then
					$g_CentralArray[$g_TreeviewItem[$cs][$cc]][6] =  $Ext & @CRLF & @CRLF & $ConnNote & $Test
				Else
					$g_CentralArray[$g_TreeviewItem[$cs][$cc]][6] =  $ConnNote & $Test
				EndIf
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
		_AI_GetType(); calculate the icon-color/shifing
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
	If _Test_CheckRequieredFiles() > 0 Then Return 0; see if files are present
	If _Misc_LS_Verify() = 0 Then Return 0; look if language settings are ok
;	If _Test_ACP() = 1 Then Return 0; remove infiniy-mods if codepage may not support the mods files characters
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
; Removes items that cannot be installed (due to language or BGT not found)
; ---------------------------------------------------------------------------------------------
Func _Tree_PurgeUnNeeded()
	Local $Version='-'
	$g_Skip='BGTNeJ;0;19;0001'
	If $g_BG1Dir = '-' Then $g_Skip&='|BGT'
	If $g_BG1EEDir = '-' Then $g_Skip&='|EET'
	If $g_Flags[14]='IWD1' Then $Version=StringReplace(FileGetVersion($g_IWD1Dir&'\idmain.exe'), '.', '\x2e')
	$ReadSection=IniReadSection($g_GConfDir&'\Game.ini', 'Purge')
	If IsArray($ReadSection) Then
		For $r=1 to $ReadSection[0][0]
			If StringLeft($ReadSection[$r][1], 1) = 'D' Then; look if depends are met
				If StringRegExp($ReadSection[$r][1], ':'&$g_MLang[1]&'\z') Then ContinueLoop; only remove mods that require a certain language
				If $g_BG1Dir <> '-' And StringRegExp($ReadSection[$r][1], '(?i)BGT\x28\x2d\x29\z') Then ContinueLoop; remove mods that require BGT
				If $g_BG1EEDir <> '-' And StringRegExp($ReadSection[$r][1], '(?i)EET\x28\x2d\x29\z') Then ContinueLoop; remove mods that require EET
				If $Version <> '-' And StringRegExp($ReadSection[$r][1], $Version) Then ContinueLoop; remove mods that require a certain version
			Else; look for conflicts
				If Not StringRegExp($ReadSection[$r][1], '\x3a'&$g_MLang[1]&'\x3a') Then ContinueLoop; remove mods only if certain language was selected
			EndIf
			$Line=StringRegExpReplace($ReadSection[$r][1], '(?i)\AD\x3a|\AC\x3a[[:alpha:]]{2}\x3a|\x3a(BGT|EET)\x28\x2d\x29\z|\x28\x2d\x29|\x3a[[:alpha:]]{2}\z|\x3a\d[\x2e\d|\x7c]{1,}\z', ''); remove D:|C:XX:|:BGT(-)|:EET(-)|(-)|:XX
			$g_Skip&='|'&StringReplace(StringReplace(StringReplace($Line, '&', '|'), '(', ';('), '?', '\x3f')
		Next
	EndIf
	If _Test_ACP() = 1 Then Exit
	If $g_BG1Dir <> '-' And $g_MLang[0] = 2 And $g_MLang[1] = 'GE' Then; second $g_Mlang-entry is --
		$g_Skip&='|BG1NPC|BG1NPCMusic'
	ElseIf $g_BG1Dir <> '-' And $g_MLang[1] = 'GE' Then
		$Trans=IniRead($g_ModIni, 'BG1NPC', 'Tra', ''); get other translations
		Local $ReadSection[1]=[StringRegExpReplace($Trans, '(?i)\x2cGE\x3a\d{1,2}', '')]
		$Test=_GetTra($ReadSection, 'T+')
		If $Test <> 'EN' Then; user doesn't want mods in English
			If $Test = '' Then; nothing would be installed, so purge them
				$g_Skip&='|BG1NPC|BG1NPCMusic'
			Else; another language would be chosen, so remove the German one
				IniWrite($g_ModIni, 'BG1NPC', 'Tra', $ReadSection[0])
			EndIf
		Else
			If _IniRead($g_Order, 'Au3Select', 1) = 0 Then Return; no need to ask when reloading installation
			$Answer=_Misc_MsgGUI(2, _GetTR($g_UI_Message, '0-T1'), _GetTR($g_UI_Message, '2-L10'), 2, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2')); => install unfinished BG1NPC translation
			_Misc_SetTab(9)
			If $Answer = 1 Then; remove part-translation
				IniWrite($g_ModIni, 'BG1NPC', 'Tra', $ReadSection[0])
			Else; add if needed
				If Not StringInStr($Trans, 'GE') Then
					$Num=IniRead($g_GConfDir&'\WeiDU-GE.ini', 'BG1NPC', 'TRA', 3); get the translation-number
					IniWrite($g_ModIni, 'BG1NPC', 'Tra', $Trans&',GE:'&$Num); append the translation again
				EndIf
			EndIf
		EndIf
	EndIf
	If $g_MLang[1] = 'PO' Then
		; stuff to add if Polish
		IniWrite($g_GConfDir&'\Game.ini', 'Connections', 'NTotSC Natalin fix by dradiel is requred for NTotSC but works only for Polish', 'D:NTotSC(-)&NTotSC-Natalin-fix(-)')
		IniWrite($g_GConfDir&'\Game.ini', 'Connections', 'Secret of Bone Hill Part II fix by dradiel is requred for SoBH but works only for Polish', 'D:BoneHillv275(-)&sobh-part2-fix(-)')
		Else
		; stuff to remove if not Polish
		IniDelete($g_GConfDir&'\Game.ini', 'Connections', 'NTotSC Natalin fix by dradiel is requred for NTotSC but works only for Polish')
		IniDelete($g_GConfDir&'\Game.ini', 'Connections', 'Secret of Bone Hill Part II fix by dradiel is requred for SoBH but works only for Polish')
	EndIf
EndFunc   ;==>_Tree_PurgeUnNeeded

; ---------------------------------------------------------------------------------------------
; Sets the saved items for Au3Select
; ---------------------------------------------------------------------------------------------
Func _Tree_Reload($p_Show=1, $p_Hint=0, $p_Ini=$g_UsrIni)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Tree_Reload')
	GUISwitch($g_UI[0])
	GUICtrlSetData($g_UI_Interact[2][1], IniRead($g_UsrIni, 'Options', 'BG1', GUICtrlRead($g_UI_Interact[2][1]))); set the data for the folder
	GUICtrlSetData($g_UI_Interact[2][2], IniRead($g_UsrIni, 'Options', 'BG2', GUICtrlRead($g_UI_Interact[2][2])))
	GUICtrlSetData($g_UI_Interact[2][3], IniRead($g_UsrIni, 'Options', 'Download', GUICtrlRead($g_UI_Interact[2][3])))
	Local $ModID = '', $ChapterID = '', $Tag = '', $Mod = 0, $Found = 0
; ---------------------------------------------------------------------------------------------
; loop through the elemets of the main-array. We make heavy usage of the main-array here. Now you know why it's that important. :)
; ---------------------------------------------------------------------------------------------
	GUICtrlSetData($g_UI_Interact[9][1], 0)
	GUICtrlSetData($g_UI_Static[9][2], '0 %')
	_GUICtrlTreeView_BeginUpdate($g_UI_Handle[0]); speed up the update-process by tellig all the stuff at once later
	GUICtrlSetData($g_UI_Menu[1][5], _GetTR($g_UI_Message, '4-M1')); => hide components
	$Select = IniReadSection($p_Ini, 'Save')
	If @error Then $Select = IniReadSection($p_Ini, 'Current'); needed to still be able to load saves of older BWS-versions
	$DeSelect = IniReadSection($p_Ini, 'DeSave')
	If @error Then Local $DeSelect[1][1]
	$g_GUIFold = 1
	$Mark=_GetTR($g_UI_Message, '4-L17'); => New
	$Token = ' ['&StringLeft($Mark, 1)&']'
	$Mark=' ['&$Mark&']'
	$Len = StringLen($Mark)
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
		If $g_CentralArray[$m][2] = '-' Then ; mods headline
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
		$ModCounter = $g_CentralArray[0][0] - $g_CentralArray[0][1]
		If _MathCheckDiv($m, 10) = 2 Then
			GUICtrlSetData($g_UI_Interact[9][1], $Mod * 100 / $ModCounter); set progress
			GUICtrlSetData($g_UI_Static[9][2], Round($Mod * 100 / $ModCounter, 0) & ' %')
		EndIf
		If StringInStr($g_CentralArray[$m][11], 'F') Then
			If StringRegExp($DComp, '(?i)(\A|\s)' & StringReplace($g_CentralArray[$m][2], '?', '\x3f') & '(\s|\z)') Then; if the component-number of the current mod was deselected
				; do nothing :D
			ElseIf $g_CentralArray[$m][10] = 2 Then; enable the standards of an item which has SUBs (useful for new defaults)
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
		If Not IsDeclared('Comp') Then
			ConsoleWrite($m & ': '& $g_CentralArray[$m][0] & ' == ' &  $g_CentralArray[$m][2] & @CRLF)
			ConsoleWrite(GUICtrlRead($m) & @CRLF)
			ContinueLoop
		EndIf
		If $Comp = '-1' Then; mod was not selected
			If StringRegExp($DComp, '(?i)(\A|\s)' & StringReplace($g_CentralArray[$m][2], '?', '\x3f') & '(\s|\z)') = 0 Then
				If $g_CentralArray[$m][2] <> '+' Then
					GUICtrlSetData($m, GUICtrlRead($m, 1)&$Token); mark as a new component
					$g_CentralArray[$m][3]&=$Mark; add a mark that is searchable
					$Found += 1
					ConsoleWrite('> New component: ' & $g_CentralArray[$m][0] & ' ' & $g_CentralArray[$m][2]  & @CRLF)
				EndIf
			EndIf
			If $p_Show Then __TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$m][5], 1+$g_CentralArray[$m][14])
			$g_CentralArray[$m][9] = 0
		ElseIf StringRegExp($Comp, '(?i)(\A|\s)' & StringReplace($g_CentralArray[$m][2], '?', '\x3f') & '(\s|\z)') Then; if the component-number of the current mod was selected. Use StringReplace since RegExp has it's own thoughts of a ?.
			If $p_Show Then __TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[$m][5], 2+$g_CentralArray[$m][14])
			If $g_CentralArray[$m][10] = 1 Then
				If StringInStr($g_CentralArray[$m][2], '?') Then; it's a SUB-item
					$Component=StringRegExpReplace($g_CentralArray[$m][2], '\x5f.*', '')
					If $p_Show Then __TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[_AI_GetStart($m, $Component)][5], 2+$g_CentralArray[$m][14])
					$g_CentralArray[_AI_GetStart($m, $Component)][9] = 1
				Else; it's a MUC-item
					If $p_Show Then __TristateTreeView_SetItemState($g_UI_Handle[0], $g_CentralArray[_AI_GetStart($m, '+')][5], 2+$g_CentralArray[$m][14])
					$g_CentralArray[_AI_GetStart($m, '+')][9] = 1
					$g_CentralArray[$ModID][9] += 1; increase due to the selected subtree
				EndIf
			EndIf
			$g_CentralArray[$m][9] = 1
			$g_CentralArray[$ModID][9] += 1
		Else
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
	$Trans = StringSplit(IniRead($g_ProgDir & '\Config\Translation-EN.ini', 'UI-Buildtime', 'Menu[2][2]', ''), '|'); => translations for themes
	Dim $Theme[$Trans[0]]
	For $a=1 to $p_Array[0][0]
		$Theme[Number($p_Array[$a][8])]&='|'&$a; add index-numbers to a string that represents a theme
	Next
	Local $Return[4000][10]
	For $t=0 to $Trans[0]-1
		If $Theme[$t] = '' Then ContinueLoop; skip if nothing was assigned to the theme
		$Index=StringSplit(StringTrimLeft($Theme[$t], 1), '|'); get index-numbers of the array assigned to the theme
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
		_ArraySort($SameThemeMods, 0, 1, $SameThemeMods[0][0], 3); sort the same "themed" mods base on the mods names
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
				$Return[$Return[0][0]][1]=$Return[0][1]; $Index-number (will be used for connections)
			Next
		Next
	Next
	$Return[0][3]=$Trans[0]
	ReDim $Return[$Return[0][0]+1][10]
	Return $Return
EndFunc   ;==>Tree_SelectConvert

; ---------------------------------------------------------------------------------------------
; Read some parts of the select.txt-file for Batch-installations
; ---------------------------------------------------------------------------------------------
Func _Tree_SelectReadForBatch()
	$Array=StringSplit(StringStripCR(FileRead($g_GConfDir&'\Select.txt')), @LF); go through select.txt
	Local $Return[$Array[0]][10], $Theme=-1
	For $a=1 to $Array[0]
		If StringLeft($Array[$a], 5) = 'ANN;#' Then $Theme+=1; don't read values because there are not consistent (usage of 5A)
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
	Global $g_CentralArray[$Return[0][4]][16];set size for global array before running _Tree_Populate -- if the BWS goes kaboom, recalculatre this number...
	ReDim $Return[$Return[0][0]+1][10]
	Return $Return
EndFunc   ;==>_Tree_SelectReadForBatch

; ---------------------------------------------------------------------------------------------
; Read the select.txt-file which contains the installation-procedure
; ---------------------------------------------------------------------------------------------
Func _Tree_SelectRead($p_Admin=0)
	$Array=StringSplit(StringStripCR(FileRead($g_GConfDir&'\Select.txt')), @LF)
	Local $Return[$Array[0]+1][10]
	For $a=1 to $Array[0]
		If StringRegExp($Array[$a], '\A(\s.*\z|\z)') Then ContinueLoop; skip emtpty lines
		If StringRegExp($Array[$a], '(?i)\A(ANN|CMD|GRP)') Then
			If $p_Admin=0 Then
				ContinueLoop; skip annotations,commands,groups
			Else
				$Split=StringSplit($Array[$a], ';')
				$Return[0][0]+=1
				$Return[$Return[0][0]][0]=$Split[1]; linetype
				$Return[$Return[0][0]][7]=$Split[2]; description
				If $Split[0]>5 Then $Return[$Return[0][0]][6]=$Split[6]; component requirements
;~ 				ConsoleWrite($Array[$a] & @CRLF)
				ContinueLoop
			EndIf
		EndIf
		If $p_Admin = 0 And StringRegExp($Array[$a], '(?i);('&$g_Skip&');') Then ContinueLoop; skip mods that don't fit the selection
		$Split=StringSplit($Array[$a], ';')
		$Return[0][0]+=1
		$Return[$Return[0][0]][0]=$Split[1]; linetype
		;  1 >> Index
		$Return[$Return[0][0]][2]=$Split[2]; setup
		$Return[$Return[0][0]][3]=$Split[3]; component
		$Return[$Return[0][0]][4]=$Split[5]; defaults
		;  5 >> Translation
		$Return[$Return[0][0]][6]=$Split[6]; component requirements
		;  7 >> Name
		$Return[$Return[0][0]][8]=$Split[4]; theme
		If $Return[$Return[0][0]][8] <> $Return[$Return[0][0]-1][8] Then $Return[0][3]+=1
		If $Return[$Return[0][0]][2] <> $Return[0][2] Then
			$Return[0][1]+=1
			$Return[0][2] = $Return[$Return[0][0]][2]
		EndIf
		$Return[$Return[0][0]][1]=$Return[0][1]; $Index-number (will be used for connections)
	Next
	$Return[0][4]=$Return[0][0]+$Return[0][1]+$Return[0][3]+$g_UI_Menu[8][10]+100; calculate Treeview-items: Items+Mods+Themes+GUI-items+Error-Margin for wrong calculation
	Global $g_CentralArray[$Return[0][4]][16];set size for global array before running _Tree_Populate -- if the BWS goes kaboom, recalculatre this number...
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
	$Current = ''
	$Type = _Selection_GetCurrentInstallType()
	_Misc_ProgressGUI(_GetTR($g_UI_Message, '4-T1'), _GetTR($g_UI_Message, '4-L2')); => setting entries
	If StringLen($Type)=2 then
		_Tree_Reload(1, 0, $g_GConfDir&'\Preselection'&$Type&'.ini'); show reload the settings from a file without hints about new items
	Else
		_GUICtrlTreeView_BeginUpdate($g_UI_Handle[0])
		_AI_SetDefaults()
		_GUICtrlTreeView_EndUpdate($g_UI_Handle[0])
	EndIf
	_Depend_GetActiveConnections()
	$g_Flags[23]=$g_ActiveConnections[0][0]
	_Depend_AutoSolve('C', 2)
	_Depend_AutoSolve('DS', 2)
	$g_Flags[23]=''
	GUICtrlSetData($g_UI_Static[9][2], '100 %')
	If $p_Num <> '' Then _Misc_SetTab($p_Num); selected another version on selection-tab 2
EndFunc   ;==>_Tree_SetPreSelected

; ---------------------------------------------------------------------------------------------
; (De)Select (mostly) all mods of a certain group/theme (Quest, NPC...) or special selections. $p_Num =
; ---------------------------------------------------------------------------------------------
Func _Tree_SetSelectedGroup($p_Num, $p_State)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Tree_SetSelectedGroup')
	Local $FirstModItem
	_GUICtrlTreeView_BeginUpdate($g_UI_Handle[0])
	$OldCompilation = $g_Compilation
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
	Local $Array[750][2], $FirstModItem, $Compilation[5]=[4, 'R', 'S', 'T', 'E'], $OldCompilation = $g_Compilation
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
	$Num=$p_Num - ($g_UI_Menu[0][2]-2)
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