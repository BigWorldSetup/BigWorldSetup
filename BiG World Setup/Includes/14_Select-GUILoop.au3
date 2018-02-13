#include-once

Func Au3Select($p_Num = 0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling Au3Select')
	Local $MouseClicked, $SpaceClicked
	Local $ReadSection = IniReadSection($g_UsrIni, 'Options')
	Local $AccelKeys[1][2] = [["{F1}", $g_UI_Static[0][3]]]
	GUISetAccelerators($AccelKeys)
	GUISwitch($g_UI[0])
	Local $Test=StringSplit(_IniRead($ReadSection, 'AppType', ''),':'); need correct gametype
	If $Test[0] = 2 Then
		_Misc_Set_GConfDir($Test[1]); conf folder
		$g_Flags[14] = $Test[1]; rely on conf gametype instead of target folder so we return to last used game type tab on BWS UI restart (EET fix)
	EndIf
	__TristateTreeView_LoadStateImage($g_UI_Handle[0], $g_ProgDir & '\Pics\Icons.bmp')
	_Misc_SetLang()
	_Misc_SetTab(9)
	If Not FileExists($g_DownDir) Then DirCreate($g_DownDir)
	_Process_StartCmd()
	IniDelete($g_BWSIni, 'Faults', 'BWS-URLUpdate')
; ---------------------------------------------------------------------------------------------
; setting some defaults or using old settings
; ---------------------------------------------------------------------------------------------
	If _IniRead($ReadSection, 'TAPatch', 1) = 1 Then ; textpatches
		GUICtrlSetState($g_UI_Interact[14][8], $GUI_CHECKED)
	Else
		GUICtrlSetState($g_UI_Interact[14][8], $GUI_UNCHECKED)
	EndIf
	Local $a, $Array, $Current
	For $l=1 to 3; logics
		$a=_IniRead($ReadSection, 'Logic'&$l, 1)
		$Array = StringSplit(IniRead($g_TRAIni, 'UI-Buildtime', 'Interact[14]['&$l&']', $a), '|')
		$Current=GUICtrlSetData($g_UI_Interact[14][$l], $Array[$a])
	Next
	If _IniRead($ReadSection, 'GroupInstall', 1) = 1 Then ; install in groups
		GUICtrlSetState($g_UI_Interact[14][4], $GUI_CHECKED)
	Else
		GUICtrlSetState($g_UI_Interact[14][4], $GUI_UNCHECKED)
	EndIf
	If _IniRead($ReadSection, 'Beep', 0) = 1 Then GUICtrlSetState($g_UI_Interact[14][10], $GUI_CHECKED)
	Local $WScreen = IniReadSection($g_UsrIni, 'Save'); looking for an old save
	If @error Then; no selection found
		If @DesktopWidth*3=@DesktopHeight*4 Then; this is a 4:3 res
			$WScreen = ''; disable Widescreen by default
		Else
			$WScreen = '0'; this thing might need widescreen
		EndIf
	Else
		$WScreen=_IniRead($WScreen, 'widescreen', '')
	EndIf
	If $WScreen = '' Then ; widescreen
		GUICtrlSetState($g_UI_Interact[14][5], $GUI_UNCHECKED)
		GUICtrlSetState($g_UI_Interact[14][6], $GUI_DISABLE)
		GUICtrlSetState($g_UI_Interact[14][7], $GUI_DISABLE)
	Else
		GUICtrlSetState($g_UI_Interact[14][5], $GUI_CHECKED)
		GUICtrlSetState($g_UI_Interact[14][6], $GUI_ENABLE)
		GUICtrlSetState($g_UI_Interact[14][7], $GUI_ENABLE)
		$WScreen = StringSplit(StringRegExpReplace($WScreen, '\A0\s|0\x3f\d_', ''), ' ')
		If IsArray($WScreen) And $WScreen[0] = 2 Then
			GUICtrlSetData($g_UI_Interact[14][6], $WScreen[1])
			GUICtrlSetData($g_UI_Interact[14][7], $WScreen[2])
		Else
			GUICtrlSetData($g_UI_Interact[14][6], @DesktopWidth)
			GUICtrlSetData($g_UI_Interact[14][7], @DesktopHeight)
		EndIf
	EndIf
; ---------------------------------------------------------------------------------------------
; lift off
; ---------------------------------------------------------------------------------------------
	GUICtrlSetState($g_UI_Button[3][6], $GUI_DISABLE); disable update-button (remove and uncomment lines below to restore it)
	If $g_Flags[14] <> '' Then
		_Misc_SwitchGUIToInstallMethod()
;		If _IniRead($ReadSection, 'SuppressUpdate', 0) = 0 Then
;			_Net_StartupUpdate()
;		ElseIf Not StringRegExp($g_Flags[14], 'BWP|BWS') Then; currently no updates for other games than BWP
;			GUICtrlSetState($g_UI_Button[3][6], $GUI_DISABLE)
;		EndIf
        _Misc_SetAvailableSelection()
		_Misc_SetTab(2)
		GUICtrlSetState($g_UI_Interact[1][2], $GUI_HIDE); combobox
		GUICtrlSetState($g_UI_Static[1][2], $GUI_HIDE); language label
		GUICtrlSetState($g_UI_Interact[1][3], $GUI_SHOW); combobox
		GUICtrlSetState($g_UI_Static[1][3], $GUI_SHOW); install label
	ElseIf _IniRead($ReadSection, 'AppLang', '') <> '' Then
		_Misc_Set_GConfDir($g_GameList[1][0])
		_Misc_SetWelcomeScreen('+')
		_Misc_SetTip()
		$g_Flags[10] = 1
		_Misc_SetTab(1)
	Else
		_Misc_Set_GConfDir($g_GameList[1][0])
		_Misc_SetTip(0)
		$g_Flags[10] = 2
		_Misc_SetTab(1)
	EndIf
	Local $sMsg, $s=0
	Local $WPos0, $CPos, $XControlOffSet, $YControlOffSet

#cs
	For $s=1 to 5
		_Misc_Search($g_UI_Interact[2][6], 'Spiel', $s); $Search[$s])
		Sleep(1000)
	Next
#ce

	While 1
; ---------------------------------------------------------------------------------------------
; Update the tips for the treeviewitems.
; ---------------------------------------------------------------------------------------------
		If  $g_Flags[8] = 1 Then
			$s += 1
			If $s > 20 Then
				_Selection_TipUpdate()
				$s=0
			EndIf
; ---------------------------------------------------------------------------------------------
; Monitor changes of treeviewitems.
; ---------------------------------------------------------------------------------------------
			If $g_Flags[16] = 1 Then; tv-icon is clicked
				$MouseClicked = 1; this also catches the spacebar!
				$sMsg = GUICtrlRead($g_UI_Interact[4][1]); control ID of selected tree-view item
				$g_Flags[16] = 0
			;ElseIf _IsPressed('20', $g_UDll) Then; space was pressed -- but this code is unnecessary and caused bugs!
			;	While _IsPressed('20', $g_UDll)
			;		Sleep(10)
			;	WEnd
			;	$MouseClicked = 1
			;	$SpaceClicked = 1
			;	$sMsg = GUICtrlRead($g_UI_Interact[4][1]); control ID of selected tree-view item
			ElseIf $g_Flags[16] = 2 Then; tvitem is right-clicked
				_Selection_ContextMenu()
			EndIf
			If $MouseClicked = 1 Then
				If $sMsg <> 0 Then
					ControlFocus($g_UI[0], '', $g_UI_Interact[4][2]); focus a dummy to block keystrokes during actions
					WinSetState($g_UI[0], '', @SW_DISABLE); disable the GUI to block mouse-clicks
					$g_Flags[9]=1
					_AI_SetClicked($sMsg, 0, $SpaceClicked); spaceclicked always zero .. legacy code .. we treat mouse-click and spacebar the same now
					WinSetState($g_UI[0], '', @SW_ENABLE)
					$g_Flags[9]=0
					ControlFocus($g_UI[0], '', $g_UI_Interact[4][1])
				EndIf
				$MouseClicked = 0
				$SpaceClicked = 0
			EndIf
		EndIf
		$sMsg = GUIGetMsg()
		If $g_Flags[15]=1 Then; in greet-screen
			If $sMsg = $GUI_EVENT_RESIZED Then; if window is resized, move the childwindow containing the BWS-picture
				$WPos0 = WinGetPos($g_UI[0])
				$CPos = ControlGetPos($g_UI[0], '', $g_UI_Static[1][4])
				$XControlOffSet=($CPos[2]-400)/2
				$YControlOffSet=($CPos[3]-260)
				WinMove($g_UI[1], '', $WPos0[0]+$g_UI[2]+$XControlOffSet, $WPos0[1]+$g_UI[3]+$YControlOffSet)
			EndIf
		EndIf
		;If $sMsg >0 Then ConsoleWrite($sMsg & @CRLF)
		Switch $sMsg
		Case 0; nothing happened
			Sleep(10)
			ContinueLoop
		Case -11; mouse moved
			Sleep(10)
			ContinueLoop
; ---------------------------------------------------------------------------------------------
#Region special events
		Case $GUI_EVENT_CLOSE
			If $g_Flags[24]=1 Then _Tree_Export($g_GConfDir&'\PreSelection00.ini')
			#cs
			$Current = GUICtrlRead($g_UI_Seperate[0][0])+1
			If $Current = 4 Then
				$Test=_Misc_MsgGUI(3, _GetTR($g_UI_Message, '0-T1'), _GetTR($g_UI_Message, '4-L13'), 2, _GetTR($g_UI_Message, '0-B2'), _GetTR($g_UI_Message, '0-B1')); => really want to exit?
				If $Test=2 Then ContinueLoop
			EndIf
			#ce
			Exit
		Case $GUI_EVENT_MINIMIZE
			GUISetState(@SW_MINIMIZE, $g_UI[0])
		Case $GUI_EVENT_RESTORE
			GUISetState(@SW_RESTORE, $g_UI[0])
		Case $GUI_EVENT_MAXIMIZE
			GUISetState(@SW_MAXIMIZE, $g_UI[0])
#EndRegion special events
; ---------------------------------------------------------------------------------------------
#Region always visible buttons
		Case $g_UI_Static[0][3]; bws-pic
			_Misc_AboutGUI()
		Case $g_UI_Button[0][1]; back
			$Current = GUICtrlRead($g_UI_Seperate[0][0])+1
			If StringRegExp($Current, '\A(4|15)\z') Then _Misc_SwitchWideScreen(); toggle the widescreen checkbox if necessary
			If $Current = 14 Then
				_Misc_SetTab(3)
			ElseIf StringRegExp($Current, '\A(1|2)\z') Then
				_Misc_SetWelcomeScreen('-')
			ElseIf $Current > 1 Then
				_Misc_SetTab($Current-1)
			EndIf
		Case $g_UI_Button[0][2]; next
			$Current = GUICtrlRead($g_UI_Seperate[0][0])+1
; ---------------------------------------------------------------------------------------------
; leaving language-selection-state
; ---------------------------------------------------------------------------------------------
			If $Current = 1 Then
				If _Misc_SetWelcomeScreen('+') = 0 Then ContinueLoop
; ---------------------------------------------------------------------------------------------
; leaving folder selection
; ---------------------------------------------------------------------------------------------
			ElseIf $Current = 2 Then
				If _Tree_Populate_PreCheck() = 0 Then ContinueLoop
; ---------------------------------------------------------------------------------------------
; backup / update menu
; ---------------------------------------------------------------------------------------------
			ElseIf $Current = 3 Then
				If $g_Flags[1] = 0 Then
					$Answer = _Misc_MsgGUI(3, _GetTR($g_UI_Message, '0-T1'), _GetTR($g_UI_Message, '5-L1'), 2); => continue without _Net_LinkTest?
					$g_Flags[1] = 1
					If $Answer = 1 Then ContinueLoop
				EndIf
				_Misc_SetTab(14)
				ContinueLoop
; ---------------------------------------------------------------------------------------------
; Install-Opts: Final actions
; ---------------------------------------------------------------------------------------------
			ElseIf $Current = 14 Then
				If _Selection_ExpertWarning(2) = 1 Then ContinueLoop
				_Tree_EndSelection()
				If IniRead($g_UsrIni, 'Options', 'Logic1', 1) = 4 Then IniWrite($g_BWSIni, 'Order', 'Au3Net', 0); skip download-checks and download
				_Process_Gui_Create(0, 0)
				Return
			EndIf
			If $Current < 6 Then _Misc_SetTab($Current + 1); next tab
		Case $g_UI_Button[0][3]; exit
			$Current = GUICtrlRead($g_UI_Seperate[0][0])+1
			If $Current = 6 Then
				$g_Flags[0] = 1
				GUICtrlSetData($g_UI_Static[6][1], _GetTR($g_UI_Message, '0-L1')); => set hint to be patient
				GUICtrlSetState($g_UI_Static[6][1], $GUI_HIDE)
				Sleep(1000)
				GUICtrlSetState($g_UI_Static[6][1], $GUI_SHOW)
				GUICtrlSetState($g_UI_Button[0][3], $GUI_DISABLE)
			ElseIf $Current = 4 Then; leaving 'choose mods and components' tree-view
				_Misc_SwitchWideScreen(); toggle the widescreen checkbox if necessary
				If _Selection_ExpertWarning(2) = 1 Then ContinueLoop
				If _Depend_ResolveGui() = 0 Then ContinueLoop
				_Misc_SetTab(2)
			Else
				If $g_Flags[24]=1 Then _Tree_Export($g_GConfDir&'\PreSelection00.ini')
				Exit
			EndIf
#EndRegion always visible buttons
; ---------------------------------------------------------------------------------------------
#Region welcome
		Case $g_UI_Interact[1][2]; language selector
			_Misc_SwitchLang()
		Case $g_UI_Interact[1][3]; install method
			_Misc_SetTip()
#EndRegion welcome
; ---------------------------------------------------------------------------------------------
#Region folder
		Case $g_UI_Button[2][1]; select BG1/BG1EE-for-BGT/EET folder
			If $g_Flags[14] = 'BG2EE' Then; (EET)
				_Misc_SelectFolder('BG1EE', StringFormat(_GetTR($g_UI_Message, '2-F1'), _GetGameName('BG1EE'))); => select a folder
			Else
				_Misc_SelectFolder('BG1', StringFormat(_GetTR($g_UI_Message, '2-F1'), _GetGameName('BG1'))); => select a folder
			EndIf
		Case $g_UI_Button[2][2]; select BG2/BG1EE/BG2EE/IWD/IWD2/IWD1EE/PSTEE/PST folder
			If StringRegExp($g_Flags[14], '(?i)BWP|BWS') Then
				_Misc_SelectFolder('BG2', StringFormat(_GetTR($g_UI_Message, '2-F1'), _GetGameName())); => select a folder
			Else
				_Misc_SelectFolder($g_Flags[14], StringFormat(_GetTR($g_UI_Message, '2-F1'), _GetGameName())); => select a folder
			EndIf
		Case $g_UI_Button[2][3]; select download folder
			_Misc_SelectFolder('Down', _GetTR($g_UI_Message, '2-F2')); => select a download-folder
		Case $g_UI_Button[2][4]; edit used languages for installation
			_Misc_LS_GUI()
		Case $g_UI_Interact[2][4]; presel combo
			If $g_CentralArray[0][0] <> '' Then _Tree_SetPreSelected(2)
			$g_Flags[24]=0; no need to save changes to selection any more after some reload
			_Selection_GetCurrentInstallType()
		Case $g_UI_Button[2][5]; adv. selection
			If _Tree_Populate_PreCheck() = 0 Then ContinueLoop
			_Misc_SetTab(4)
#EndRegion folder
; ---------------------------------------------------------------------------------------------
#Region backup / tests
		Case $g_UI_Button[3][1]; create backup
			Au3CleanInst(2, 2)
		Case $g_UI_Button[3][2]; restore backup
			Au3CleanInst(3, 2)
		Case $g_UI_Button[3][4]; test download links
			_Net_LinkTest(2)
			$g_Flags[1] = 1
		Case $g_UI_Button[3][5]; filecheck
			_Test_ArchivesExist()
		Case $g_UI_Button[3][6]; update download links
			If $g_Flags[2] = 0 Then
				$Answer = _Misc_MsgGUI(2, _GetTR($g_UI_Message, '0-T1'), _GetTR($g_UI_Message, '5-L3'), 2); => links will be overwritten
				$g_Flags[2] = 1
				If $Answer = 1 Then ContinueLoop
			EndIf
			_Net_Update_Link('1+2')
		Case $g_UI_Button[3][7]; list download links
			_Net_LinkList()
#EndRegion backup / tests
; ---------------------------------------------------------------------------------------------
#Region advsel
		Case $g_UI_Static[4][2]; options
			__ShowContextMenu($g_UI[0], $g_UI_Static[4][2], $g_UI_Menu[1][0])
		Case $g_UI_Static[4][3]; add
			__ShowContextMenu($g_UI[0], $g_UI_Static[4][3], $g_UI_Menu[2][0])
		Case $g_UI_Static[4][4]; remove
			__ShowContextMenu($g_UI[0], $g_UI_Static[4][4], $g_UI_Menu[3][0])
		Case $g_UI_Static[4][5]; mark
			__ShowContextMenu($g_UI[0], $g_UI_Static[4][5], $g_UI_Menu[4][0])
		Case $g_UI_Button[4][1]; search button
			_Selection_SearchSingle(GUICtrlRead($g_UI_Interact[4][3]), _GetTR($g_UI_Message, '4-I1')); => enter search term
		Case $g_UI_Button[4][2]; help on/off
			_Selection_SetSize()
		Case $g_UI_Button[4][3]; show homepage
			_Selection_OpenPage()
		Case $g_UI_Button[4][4]; show wiki-page
			_Selection_OpenPage('wiki')
		Case $g_UI_Menu[1][1]; load
			_Misc_ProgressGUI(_GetTR($g_UI_Message, '4-T1'), _GetTR($g_UI_Message, '4-L2')); => setting entries
			_Tree_Reload(1, 1)
			_Misc_SetTab(4)
		Case $g_UI_Menu[1][2]; save
			_Tree_GetCurrentSelection(0)
		Case $g_UI_Menu[1][3]; Import
			Local $File = FileOpenDialog(_GetTR($g_UI_Message, '4-F1'), $g_ProgDir, 'Ini files (*.ini)', 1, 'BWS-Selection.ini', $g_UI[0]); => load selection from
			If @error Then ContinueLoop; user clicked cancel button or escape key or some error occurred trying to load the chosen file
			If _Tree_Import($File) = -1 Then ContinueLoop; in this case the function printed => The selected file was not in the expected format
			_Misc_ProgressGUI(_GetTR($g_UI_Message, '4-T1'), _GetTR($g_UI_Message, '4-L2')); => setting entries
			_Tree_Reload(1, 1)
			_Misc_SetTab(4)
		Case $g_UI_Menu[1][4]; Export
			_Tree_Export()
		Case $g_UI_Menu[1][5]; Extend
			_Tree_ShowComponents()
		Case $g_UI_Menu[1][7]; Recommended-clicking-behaviour
			_AI_SwitchComp(1, 1)
		Case $g_UI_Menu[1][8]; Stable-clicking-behaviour
			_AI_SwitchComp(2, 1)
		Case $g_UI_Menu[1][9]; Tactical-clicking-behaviour
			_AI_SwitchComp(3, 1)
		Case $g_UI_Menu[1][10]; Expert-clicking-behaviour
			_AI_SwitchComp(4, 1)
		Case $g_UI_Menu[1][11]; Import from WeiDU
			Local $File = FileOpenDialog(_GetTR($g_UI_Message, '4-F1'), $g_GameDir, 'WeiDu (WeiDU.log)', 1, 'WeiDU.log', $g_UI[0]); => load selection from
			If @error Then ContinueLoop
			Local $Array=_Selection_ReadWeidu($File)
			If Not IsArray($Array) Then
				_PrintDebug(_GetTR($g_UI_Message, '4-F3'), 1); => The selected file was not in the expected format.
				ContinueLoop
			ElseIf $Array[0][0] = 0 Then
				_PrintDebug(_GetTR($g_UI_Message, '4-F3'), 1); => The selected file was not in the expected format.
				ContinueLoop
			Else
				IniWriteSection($g_UsrIni, 'Current', $Array)
				IniWriteSection($g_UsrIni, 'Save', $Array)
				IniDelete($g_UsrIni, 'DeSave')
				IniDelete($g_UsrIni, 'Edit')
			EndIf
			_Misc_ProgressGUI(_GetTR($g_UI_Message, '4-T1'), _GetTR($g_UI_Message, '4-L2')); => setting entries
			_Tree_Reload(1, 1)
			_Misc_SetTab(4)
		Case $g_UI_Menu[1][14]; mod administration
			_Admin_ModGui()
		Case $g_UI_Menu[1][15]; component administration
			_Tra_Gui()
		Case $g_UI_Menu[1][17]; selection administration
			_Select_Gui()
		Case $g_UI_Menu[1][18]; dependency administration
			_Dep_Gui()
		Case $g_UI_Menu[1][16]; sort according to PDF
			$g_Flags[7]=''
			If BitAND(GUICtrlRead($g_UI_Menu[1][16]), $GUI_CHECKED) = $GUI_CHECKED Then
                GUICtrlSetState($g_UI_Menu[1][16], $GUI_UNCHECKED)
                $g_Flags[21]=0
            Else
                GUICtrlSetState($g_UI_Menu[1][16], $GUI_CHECKED)
                $g_Flags[21]=1
            EndIf
			_Misc_ReBuildTreeView(1)
			_Misc_SetTab(4)
			While GUIGetMsg() <> 0; throw away events prior to this point
			WEnd
#EndRegion advsel
; ---------------------------------------------------------------------------------------------
#Region install opts
		Case $g_UI_Interact[14][5]; toggle widescreen (user command)
			_Misc_SwitchWideScreen(1); toggle widescreen mod and checkbox if game type uses it
#EndRegion install opts
; ---------------------------------------------------------------------------------------------
#Region contextmenu
		Case Else; check menus
			If $g_Flags[8] = 0 Then ContinueLoop; don't loop if not in adv. sel. screen
			If $sMsg < 1 Then ContinueLoop; add a search-pattern for the menu-area
			For $t=2 to 4; >> add/remove/mark-menu
				For $c = 1 To $g_Tags[0][0]
					If $sMsg = $g_UI_Menu[$t][$c] Then
						If $t=2 Then
							_GUICtrlTreeView_SelectItem($g_UI_Handle[0], _Tree_SetSelectedGroup($g_Tags[$c][0], 1), $TVGN_FIRSTVISIBLE)
						ElseIf $t=3 Then
							_GUICtrlTreeView_SelectItem($g_UI_Handle[0], _Tree_SetSelectedGroup($g_Tags[$c][0], 0), $TVGN_FIRSTVISIBLE)
						Else
							_Selection_SearchMulti($g_Tags[$c][0], $g_Search[3])
							$g_Search[0] = 'T'
							$g_Search[3] = $g_Tags[$c][0]
						EndIf
						ContinueLoop
					EndIf
				Next
			Next
#EndRegion contextment
		EndSwitch
		Sleep(10)
	WEnd
EndFunc   ;==>Au3Select