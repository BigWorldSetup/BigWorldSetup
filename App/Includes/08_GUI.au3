#include-once

Func Au3BuildGUI($p_Num = 0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling Au3BuildGUI')
	Local $Message = IniReadSection($g_TRAIni, 'UI-Buildtime')
	$g_UI[0] = GUICreate($g_ProgName, 750, 480, -1, -1, $WS_MINIMIZEBOX + $WS_MAXIMIZEBOX + $WS_CAPTION + $WS_POPUP + $WS_SYSMENU + $WS_SIZEBOX)
	GUISetOnEvent($GUI_EVENT_CLOSE, '_Process_OnEvent')
	GUISetOnEvent($GUI_EVENT_MINIMIZE, '_Process_OnEvent')
	GUISetOnEvent($GUI_EVENT_RESTORE, '_Process_OnEvent')
	GUISetOnEvent($GUI_EVENT_MAXIMIZE, '_Process_OnEvent')
	GUISetFont(8, 400, 0, 'MS Sans Serif')
	GUISetIcon (@ScriptDir&'\Pics\BWS.ico', 0); sets the GUIs icon
	;#cs Uncomment to do GUI tests
	GUICtrlCreateLabel("", 0, 0, 750, 50)
	GUICtrlSetResizing(-1, 544)
	GUICtrlSetBkColor(-1, 0xFFFFFF)
	GUICtrlSetState(-1, $GUI_DISABLE)
	$g_UI_Static[0][3] = GUICtrlCreatePic(@ScriptDir & "\Pics\Logo.jpg", 133, 0, 493, 50)
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetResizing(-1, 800)
	;#ce Uncomment to do GUI tests
; ---------------------------------------------------------------------------------------------
#Region Always visible buttons
	$g_UI_Static[0][1] = GUICtrlCreateGroup("", 15, 425, 720, 50)
	GUICtrlSetResizing(-1, 576)
	$g_UI_Button[0][1] = GUICtrlCreateButton('', 30, 440, 170, 25, 0); Back
	GUICtrlSetResizing(-1, 576)
	GUICtrlSetOnEvent(-1, '_Process_OnEvent')
	$g_UI_Button[0][2] = GUICtrlCreateButton('', 230, 440, 170, 25, 0); Next
	GUICtrlSetResizing(-1, 576)
	GUICtrlSetOnEvent(-1, '_Process_OnEvent')
	GUICtrlSetState($g_UI_Button[0][2], $GUI_DEFBUTTON)
	$g_UI_Button[0][3] = GUICtrlCreateButton('', 505, 440, 170, 25, 0); Exit
	GUICtrlSetResizing(-1, 576)
	GUICtrlSetOnEvent(-1, '_Process_OnEvent')
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$g_UI[1] = GUICreate("", 400, 260, 15, 105, $WS_POPUP, BitOR($WS_EX_LAYERED, $WS_EX_MDICHILD), $g_UI[0])
	$g_UI_Static[0][2]=GUICtrlCreatePic(@ScriptDir & "\Pics\Greet.gif", 0, 0, 400, 260)
	GUISwitch($g_UI[0]); continue with the creation of controls on the main-gui
	$g_UI[4] = GUICreate('', 750, 375, 0, 50, $WS_POPUP, $WS_EX_MDICHILD, $g_UI[0])
	$g_UI_Seperate[0][1] = GUICtrlCreateGroup('', 175, 70, 400, 240); Please wait
	GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
	$g_UI_Static[0][4] = GUICtrlCreateLabel('', 215, 120, 320, 30, BitOR($SS_CENTER, $SS_CENTERIMAGE)); topic
	GUICtrlSetFont(-1, 8, 800, -1, "MS Sans Serif")
	$g_UI_Interact[0][1] = GUICtrlCreateProgress(215, 210, 320, 30, $PBS_SMOOTH)
	$g_UI_Static[0][5]  = GUICtrlCreateLabel('', 215, 265, 320, 25, BitOR($SS_CENTER, $SS_CENTERIMAGE)); description
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	GUISwitch($g_UI[0]); continue with the creation of controls on the main-gui
	$g_UI_Static[8][1] = GUICtrlCreateIcon(@ScriptDir & "\Pics\Info.ico", -1, 60, 60, 48, 48); placed here to avoid overlay-effects
	$g_UI_Seperate[0][0] = GUICtrlCreateTab(10, 25, 730, 400, BitOR($TCS_BUTTONS, $TCS_FOCUSONBUTTONDOWN, $TCS_FOCUSNEVER, $WS_GROUP))
	GUICtrlSetState(-1, $GUI_DISABLE); disable the tab so it cannot be changed by clicking through the label (strange effect)
	GUICtrlSetResizing(-1, 802)
	GUICtrlSetOnEvent(-1, '_Process_OnEvent')
#EndRegion Always visible buttons
; ---------------------------------------------------------------------------------------------
#Region Welcome - TAB
	$g_UI_Seperate[1][0] = GUICtrlCreateTabItem("Welcome")
	$g_UI_Static[1][1] = GUICtrlCreateLabel('', 15, 65, 720, 25, $SS_CENTER); header
	GUICtrlSetFont(-1, 12, 800, 0, 'MS Sans Serif')
	$g_UI_Interact[1][1] = GUICtrlCreateEdit('', 430, 105, 305, 260, BitOR($SS_Left, $WS_VSCROLL, $ES_READONLY)); introduction
	GUICtrlSetBkColor(-1, 0xFFFFFF)
	$g_UI_Static[1][2] = GUICtrlCreateLabel('', 15, 390, 400, 20, $SS_CENTER+$SS_CENTERIMAGE); language
	$g_UI_Interact[1][2] = GUICtrlCreateCombo('', 430, 390, 305, 100)
	$g_UI_Static[1][3] = GUICtrlCreateLabel('', 15, 390, 400, 20, $SS_CENTER+$SS_CENTERIMAGE); install method
	GUICtrlSetState(-1, $GUI_HIDE)
	$g_UI_Interact[1][3] = GUICtrlCreateCombo('', 430, 390, 305, 100); install method
	GUICtrlSetState(-1, $GUI_HIDE)
	$g_UI_Static[1][4] = GUICtrlCreateLabel('', 15, 105, 400, 260); dummy for resizing the picture in the screen
#EndRegion Welcome - TAB
; ---------------------------------------------------------------------------------------------
#Region Files and Folders -  TAB
	$g_UI_Seperate[2][0] = GUICtrlCreateTabItem("Files And Folders")
	$g_UI_Seperate[2][1] = GUICtrlCreateGroup('', 15, 60, 400, 190)
	GUICtrlSetFont(-1, 8, 800, 0, 'MS Sans Serif')
	$g_UI_Static[2][1] =  GUICtrlCreateLabel('', 30, 80, 370, 15); BG1 if BWS/BWP
	$g_UI_Interact[2][1] = GUICtrlCreateInput('', 30, 95, 300, 20)
	$g_UI_Button[2][1] = GUICtrlCreateButton(_GetTR($g_UI_Message, '0-B6'), 350, 95, 50, 20, 0)
	$g_UI_Static[2][2] =  GUICtrlCreateLabel('', 30, 135, 370, 15); BG2/IWD1/IWD2/PST/BG1EE/BG2EE
	$g_UI_Interact[2][2] = GUICtrlCreateInput('', 30, 150, 300, 20)
	$g_UI_Button[2][2] = GUICtrlCreateButton(_GetTR($g_UI_Message, '0-B6') , 350, 150, 50, 20, 0)
	$g_UI_Static[2][3] = GUICtrlCreateLabel('', 30, 190, 370, 15); download
	$g_UI_Interact[2][3] = GUICtrlCreateInput($g_DownDir, 30, 205, 300, 20)
	$g_UI_Button[2][3] = GUICtrlCreateButton(_GetTR($g_UI_Message, '0-B6'), 350, 205, 50, 20, 0)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$g_UI_Seperate[2][2] = GUICtrlCreateGroup('', 15, 270, 400, 140); selection
	GUICtrlSetFont(-1, 8, 800, 0, 'MS Sans Serif')
	$g_UI_Static[2][5] = GUICtrlCreateLabel('', 30, 290, 370, 15); language
	$g_UI_Interact[2][5] = GUICtrlCreateInput('', 30, 305, 300, 20)
	$g_UI_Button[2][4] = GUICtrlCreateButton(_GetTR($g_UI_Message, '0-B6'), 350, 305, 50, 20, 0)
	$g_UI_Static[2][4] = GUICtrlCreateLabel('', 30, 345, 370, 15); compilation / pre-selection menu
	$g_UI_Interact[2][4] = GUICtrlCreateCombo('', 30, 360, 370, 20)
	$g_UI_Button[2][5] = GUICtrlCreateButton(_GetTR($g_UI_Message, '0-B7'), 29, 385, 302, 20, 0); open mod/componentselection
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$g_UI_Interact[2][6] = GUICtrlCreateEdit('', 430, 65, 305, 345, BitOR($SS_Left, $WS_VSCROLL, $ES_READONLY, 0x0100)); help
	GUICtrlSetBkColor(-1, 0xFFFFFF)
#EndRegion Files and Folders -  TAB
; ---------------------------------------------------------------------------------------------
#Region Backup - TAB
	$g_UI_Seperate[3][0] = GUICtrlCreateTabItem('Backup')
	$g_UI_Seperate[3][1] = GUICtrlCreateGroup('', 15, 60, 400, 200); backup group
	GUICtrlSetFont(-1, 8, 800, 0, 'MS Sans Serif')
	$g_UI_Static[3][1] = GUICtrlCreateLabel('', 30, 90, 370, 50)
	$g_UI_Button[3][1] = GUICtrlCreateButton('', 30, 160, 175, 20, 0); create backup
	$g_UI_Button[3][2] = GUICtrlCreateButton('', 225, 160, 175, 20, 0); restore backup
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$g_UI_Seperate[3][2] = GUICtrlCreateGroup('', 15, 275, 400, 135); advanced group
	GUICtrlSetFont(-1, 8, 800, 0, 'MS Sans Serif')
	$g_UI_Static[3][4] = GUICtrlCreateLabel('', 30, 300, 170, 20, $SS_Center+$SS_CENTERIMAGE); test links
	$g_UI_Button[3][4] = GUICtrlCreateButton('', 30, 320, 170, 20, 0)
	$g_UI_Static[3][5] = GUICtrlCreateLabel('', 230, 300, 170, 20, $SS_Center+$SS_CENTERIMAGE); test present
	$g_UI_Button[3][5] = GUICtrlCreateButton('', 230, 320, 170, 20, 0)
	$g_UI_Static[3][6] = GUICtrlCreateLabel('', 30, 355, 170, 20, $SS_Center+$SS_CENTERIMAGE); look for update
	$g_UI_Button[3][6] = GUICtrlCreateButton('', 30, 375, 170, 20, 0)
	$g_UI_Static[3][7] = GUICtrlCreateLabel('', 230, 355, 170, 20, $SS_Center+$SS_CENTERIMAGE); list links
	$g_UI_Button[3][7] = GUICtrlCreateButton('', 230, 375, 170, 20, 0)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$g_UI_Interact[3][4] = GUICtrlCreateEdit('', 430, 65, 305, 345, BitOR($SS_Left, $WS_VSCROLL, $ES_READONLY)); help for this screen
	GUICtrlSetBkColor(-1, 0xFFFFFF)
#EndRegion Selection - TAB
; ---------------------------------------------------------------------------------------------
#Region Advanced selection - TAB
	$g_UI_Seperate[4][0] = GUICtrlCreateTabItem("Advanced")
	$g_UI_Interact[4][1] = GUICtrlCreateTreeView(15, 85, 400, 240, BitOR($TVS_HASBUTTONS, $TVS_HASLINES, $TVS_LINESATROOT, $TVS_DISABLEDRAGDROP, $TVS_CHECKBOXES), $WS_EX_CLIENTEDGE); the treeview
	GUICtrlSetResizing(-1, 102)
	$g_UI_Handle[0] = GUICtrlGetHandle($g_UI_Interact[4][1])
	$g_UI_Button[4][3] = GUICtrlCreateButton('i', 15, 330, 18, 18, 0x0001)
	GUICtrlSetFont(-1, 8, 800, 4, "MS Sans Serif")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetResizing(-1, 832)
	GUICtrlSetTip(-1, _GetTR($g_UI_Message, '4-L6')); => Visit the homepage
	$g_UI_Button[4][4] = GUICtrlCreateButton('k', 35, 330, 18, 18, 0x0001)
	GUICtrlSetFont(-1, 8, 800, 4, "MS Sans Serif")
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetResizing(-1, 832)
	GUICtrlSetTip(-1, _GetTR($g_UI_Message, '4-L19')); => Visit the wiki page
	$g_UI_Static[4][1] = GUICtrlCreateLabel('', 60, 330, 675, 20, BitOR($SS_Left, $SS_CENTERIMAGE)); Modgroup, size, translation
	GUICtrlSetResizing(-1, 832)
	GUICtrlSetFont(-1, 8, 800, 4, "MS Sans Serif")
	$g_UI_Interact[4][2] = GUICtrlCreateEdit('', 15, 350, 720, 70, BitOR($SS_Left, $WS_VSCROLL, $WS_Border, $ES_READONLY), 0); Extended info
	GUICtrlSetResizing(-1, 576)
	GUICtrlSetFont(-1, 8, 400, 0, "Arial")
	GUICtrlSetBkColor(-1, 0xFFFFFF)
	$g_UI_Static[4][2] = GUICtrlCreateLabel('', 15, 60, 75, 20, BitOR($SS_Left, $SS_CENTERIMAGE)); options
	$g_UI_Static[4][3] = GUICtrlCreateLabel('', 175, 60, 75, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE)); add
	$g_UI_Static[4][4] = GUICtrlCreateLabel('', 250, 60, 75, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE)); remove
	$g_UI_Static[4][5] = GUICtrlCreateLabel('', 325, 60, 75, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE)); mark
	For $s=2 to 5
		GUICtrlSetCursor($g_UI_Static[4][$s], 0)
		GUICtrlSetResizing($g_UI_Static[4][$s], 802)
	Next
	$g_UI_Interact[4][3] = GUICtrlCreateInput('', 450, 60, 175, 20); search field
	GUICtrlSetResizing(-1, 548)
	$g_UI_Button[4][1] = GUICtrlCreateButton('', 650, 60, 85, 20, 0); search button
	GUICtrlSetResizing(-1, 804)
	$g_UI_Button[4][2] = GUICtrlCreateButton('>', 415, 85, 15, 240, -1, 0x00000200)
	GUICtrlSetResizing(-1, 356)
	$g_UI_Interact[4][4] = GUICtrlCreateEdit('', 430, 85, 305, 240, BitOR($SS_Left, $WS_VSCROLL, $ES_READONLY))
	GUICtrlSetBkColor(-1, 0xFFFFFF)
	GUICtrlSetResizing(-1, 356)
#EndRegion Advanced selection - TAB
; ---------------------------------------------------------------------------------------------
#Region Download - TAB
	$g_UI_Seperate[5][0] = GUICtrlCreateTabItem("Download")
	$g_UI_Static[5][1] = GUICtrlCreateLabel('', 15, 65, 720, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE)); topic
	GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
	GUICtrlSetResizing(-1, 550)
	$g_UI_Interact[5][1] = GUICtrlCreateProgress(15, 85, 720, 20, $PBS_SMOOTH)
	GUICtrlSetResizing(-1, 550)
	$g_UI_Static[5][2] = GUICtrlCreateLabel('', 15, 115, 720, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE)); step
	GUICtrlSetResizing(-1, 550)
	$g_UI_Seperate[5][1] = GUICtrlCreateGroup('', 15, 140, 400, 235); active downloads
	GUICtrlSetResizing($g_UI_Seperate[5][1], 102)
	For $i=1 to 5
		$g_UI_Button[5][($i*2)-1] = GUICtrlCreateButton('X', 30, $i*40+120, 20, 20)
		GUICtrlSetResizing(-1, 258)
		GUICtrlSetOnEvent(-1, '_Process_OnEvent')
		$g_UI_Button[5][$i*2] = GUICtrlCreateButton('II', 50, $i*40+120, 20, 20)
		GUICtrlSetResizing(-1, 258)
		GUICtrlSetOnEvent(-1, '_Process_OnEvent')
		$g_UI_Static[5][$i+2] = GUICtrlCreateLabel('', 80, $i*40+120, 320, 20); label for download queue 1
		GUICtrlSetResizing(-1, 6)
		GUICtrlSetOnEvent(-1, '_Process_OnEvent')
		$g_UI_Interact[5][$i+1] = GUICtrlCreateProgress(30, $i*40+140, 370, 10); download progress queue 1
		GUICtrlSetResizing(-1, 6)
	Next
	GUICtrlCreateGroup("", -99, -99, 1, 1) ;close group
	$g_UI_Interact[5][7] = GUICtrlCreateEdit('', 430, 145, 305, 230, BitOR($SS_Left, $WS_VSCROLL, $ES_READONLY)); help
	GUICtrlSetBkColor(-1, 0xFFFFFF)
	GUICtrlSetResizing(-1, 356)
	$g_UI_Button[5][11] = GUICtrlCreateButton('', 505, 390, 170, 20, 0); open debug
	GUICtrlSetResizing(-1, 576)
	GUICtrlSetOnEvent(-1, '_Process_OnEvent')
#EndRegion Download - TAB
; ---------------------------------------------------------------------------------------------
#Region Console = Output - TAB
	$g_UI_Seperate[6][0] = GUICtrlCreateTabItem("Console")
	$g_UI_Static[6][1] = GUICtrlCreateLabel('', 15, 65, 720, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE)); topic
	GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
	GUICtrlSetResizing(-1, 550)
	$g_UI_Interact[6][1] = GUICtrlCreateProgress(15, 85, 720, 20, $PBS_SMOOTH)
	GUICtrlSetResizing(-1, 550)
	$g_UI_Static[6][2] = GUICtrlCreateLabel('', 15, 115, 720, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE)); step
	GUICtrlSetResizing(-1, 550)
	$g_UI_Interact[6][2] = GUICtrlCreateEdit('', 15, 145, 400, 230, $ES_READONLY + $WS_HSCROLL + $WS_VSCROLL + $ES_AUTOVSCROLL + $ES_READONLY); scrollable output
	GUICtrlSetBkColor(-1, 0xFFFFFF)
	GUICtrlSetResizing(-1, 102)
	_GUICtrlEdit_SetLimitText($g_UI_Interact[6][2], 64000)
	$g_UI_Interact[6][3] = GUICtrlCreateEdit('', 15, 145, 400, 230, $ES_READONLY + $WS_HSCROLL); fixed output
	GUICtrlSetBkColor(-1, 0xFFFFFF)
	GUICtrlSetResizing(-1, 102)
	$g_UI_Button[6][3] = GUICtrlCreateButton('>', 415, 145, 15, 230, -1, 0x00000200)
	GUICtrlSetOnEvent(-1, '_Process_SetSize')
	GUICtrlSetResizing(-1, 356)
	$g_UI_Interact[6][4] = GUICtrlCreateEdit('', 430, 145, 305, 230, BitOR($SS_Left, $WS_VSCROLL, $ES_READONLY)); help
	GUICtrlSetBkColor(-1, 0xFFFFFF)
	GUICtrlSetResizing(-1, 356)
	$g_UI_Interact[6][5] = GUICtrlCreateInput('', 30, 390, 170, 20); type input
	GUICtrlSetResizing(-1, 576)
	$g_UI_Button[6][1] = GUICtrlCreateButton('', 230, 390, 170, 20, 0); send input
	GUICtrlSetResizing(-1, 576)
	GUICtrlSetOnEvent(-1, '_Process_OnEvent')
	$g_UI_Button[6][2] = GUICtrlCreateButton('', 505, 390, 170, 20, 0); open debug
	GUICtrlSetResizing(-1, 576)
	GUICtrlSetOnEvent(-1, '_Process_OnEvent')
#EndRegion Console = Output - TAB
; ---------------------------------------------------------------------------------------------
#Region About - TAB
	$g_UI_Seperate[7][0] = GUICtrlCreateTabItem('About')
	;$pic1 = GUICreate("", 400, 260, 15, 105, $WS_POPUP, BitOR($WS_EX_LAYERED, $WS_EX_MDICHILD), $g_sGui); reminder. Created at main-gui-section.
	$g_UI_Static[7][1] = GUICtrlCreateLabel('', 15, 385, 400, 20, $SS_CENTER+$SS_CENTERIMAGE)
	$g_UI_Interact[7][1] = GUICtrlCreateEdit('', 430, 65, 305, 345, BitOR($SS_Left, $WS_VSCROLL, $ES_READONLY))
	GUICtrlSetBkColor(-1, 0xFFFFFF)
#EndRegion About - TAB
; ---------------------------------------------------------------------------------------------
#Region MsgBox - substitution - TAB
	$g_UI_Seperate[8][0] = GUICtrlCreateTabItem("Message")
	$g_UI_Seperate[8][1] = GUICtrlCreateGroup('', 175, 120, 400, 240); hint
	GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
	;$g_UI_Static[8][1] = GUICtrlCreateIcon(@ScriptDir & "\Pics\Info.ico", -1, 60, 60, 48, 48); reminder. Created at main-gui-section.
	$g_UI_Static[8][2] = GUICtrlCreateLabel('', 245, 145, 310, 145); message
	$g_UI_Interact[8][1] = GUICtrlCreateEdit('', 245, 145, 310, 145, BitOR($SS_Left, $WS_VSCROLL, $ES_READONLY), 0); fallback for big messages
	$g_UI_Button[8][1] = GUICtrlCreateButton('', 195, 315, 110, 20, $BS_CENTER + $BS_PUSHLIKE); selection 1-3
	$g_UI_Button[8][2] = GUICtrlCreateButton('', 320, 315, 110, 20, $BS_CENTER + $BS_PUSHLIKE)
	$g_UI_Button[8][3] = GUICtrlCreateButton('', 445, 315, 110, 20, $BS_CENTER + $BS_PUSHLIKE)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
#EndRegion MsgBox - substitution - TAB
; ---------------------------------------------------------------------------------------------
#Region Progress - substitution - TAB
	$g_UI_Seperate[9][0] = GUICtrlCreateTabItem("Progress")
	$g_UI_Seperate[9][1] = GUICtrlCreateGroup('', 175, 120, 400, 240); Please wait
	GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
	$g_UI_Static[9][1] = GUICtrlCreateLabel('', 215, 170, 320, 30, BitOR($SS_CENTER, $SS_CENTERIMAGE)); topic
	GUICtrlSetFont(-1, 8, 800, -1, "MS Sans Serif")
	$g_UI_Interact[9][1] = GUICtrlCreateProgress(215, 260, 320, 30, $PBS_SMOOTH)
	$g_UI_Static[9][2] = GUICtrlCreateLabel('', 215, 315, 320, 25, BitOR($SS_CENTER, $SS_CENTERIMAGE)); description
	GUICtrlCreateGroup("", -99, -99, 1, 1)
#EndRegion Progress - substitution - TAB
; ---------------------------------------------------------------------------------------------
#Region Dependencies - TAB
	$g_UI_Seperate[10][0] = GUICtrlCreateTabItem('Dependencies')
	$g_UI_Static[10][1] = GUICtrlCreateLabel('', 15, 60, 720, 40); GUI-description
	GUICtrlSetResizing(-1, 544)
	$g_UI_Button[10][1] = GUICtrlCreateButton('', 30, 400, 170, 20, $SS_CENTER+$SS_CENTERIMAGE); basis...
	GUICtrlSetBkColor(-1, 0xFFFFFF)
	GUICtrlSetResizing(-1, 576)
	$g_UI_Button[10][2] = GUICtrlCreateButton('', 230, 400, 170, 20, $SS_CENTER+$SS_CENTERIMAGE); has conflict with...
	GUICtrlSetBkColor(-1, 0xFF0000)
	GUICtrlSetResizing(-1, 576)
	$g_UI_Button[10][3] = GUICtrlCreateButton('', 505, 400, 170, 20, $SS_CENTER+$SS_CENTERIMAGE); is in need of...
	GUICtrlSetBkColor(-1, 0xFFA500)
	GUICtrlSetResizing(-1, 576)
	$g_UI_Interact[10][1] = GUICtrlCreateListView('1|2', 15, 100, 400, 255, $LVS_SINGLESEL + $LVS_NOSORTHEADER, $LVS_EX_GRIDLINES + $LVS_EX_FULLROWSELECT + $LVS_EX_INFOTIP + $WS_Ex_Clientedge)
	GUICtrlSetResizing(-1, 102)
	$g_UI_Handle[1] = GUICtrlGetHandle($g_UI_Interact[10][1])
	_GUICtrlListView_SetColumnWidth($g_UI_Handle[1], 0, 205)
	_GUICtrlListView_SetColumnWidth($g_UI_Handle[1], 1, 800)
	$g_UI_Button[10][4] = GUICtrlCreateButton('>', 415, 100, 15, 255, -1, 0x00000200)
	GUICtrlSetResizing(-1, 356)
	$g_UI_Interact[10][2] = GUICtrlCreateEdit('', 430, 100, 305, 255, BitOR($SS_Left, $WS_VSCROLL, $ES_READONLY))
	GUICtrlSetBkColor(-1, 0xFFFFFF)
	GUICtrlSetResizing(-1, 356)
	$g_UI_Interact[10][3] = GUICtrlCreateEdit('', 15, 355, 720, 35, BitOR($SS_Left, $WS_VSCROLL, $ES_READONLY))
	GUICtrlSetResizing(-1, 582)
#EndRegion Dependencies - TAB
; ---------------------------------------------------------------------------------------------
#Region ModAdmin - TAB
	$g_UI_Seperate[11][0] = GUICtrlCreateTabItem('Mods')
	$g_UI_Static[11][1] = GUICtrlCreateLabel('', 15, 60, 75, 20, BitOR($SS_Left, $SS_CENTERIMAGE)); options
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetResizing(-1, 800)
	$g_UI_Static[11][2] = GUICtrlCreateLabel('', 45, 60, 60, 20, BitOR($SS_RIGHT , $SS_CENTERIMAGE)); mod
	GUICtrlSetResizing(-1, 800)
	$g_UI_Interact[11][1] = GUICtrlCreateCombo('', 115, 60, 315, 250)
	GUICtrlSetResizing(-1, 800)
	$g_UI_Static[11][3] = GUICtrlCreateLabel('', 445, 60, 50, 20, $SS_CENTERIMAGE); rev
	GUICtrlSetResizing(-1, 800)
	$g_UI_Interact[11][2] = GUICtrlCreateInput('', 500, 60, 100, 20)
	GUICtrlSetResizing(-1, 800)
	$g_UI_Button[11][1] = GUICtrlCreateCheckbox('R', 610, 60, 20, 20, 0x1000+0x0009)
	GUICtrlSetResizing(-1, 800)
	$g_UI_Button[11][2] = GUICtrlCreateCheckbox('S', 630, 60, 20, 20, 0x1000+0x0009)
	GUICtrlSetResizing(-1, 800)
	$g_UI_Button[11][3] = GUICtrlCreateCheckbox('T', 650, 60, 20, 20, 0x1000+0x0009)
	GUICtrlSetResizing(-1, 800)
	$g_UI_Button[11][4] = GUICtrlCreateCheckbox('E', 670, 60, 20, 20, 0x1000+0x0009)
	GUICtrlSetResizing(-1, 800)
	$g_UI_Static[11][4] = GUICtrlCreateLabel('', 700, 60, 35, 20, BitOR($SS_Center , $SS_CENTERIMAGE)); descriptions translation
	GUICtrlSetResizing(-1, 800)
	$g_UI_Static[11][5] = GUICtrlCreateLabel('<', 15, 185, 30, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetResizing(-1, 800)
	GUICtrlSetCursor(-1, 0)
	$g_UI_Static[11][6] = GUICtrlCreateLabel('', 340, 185, 70, 20, $SS_CENTERIMAGE); ext
	GUICtrlSetResizing(-1, 800)
	$g_UI_Static[11][7] = GUICtrlCreateIcon(@SystemDir&'\shell32.dll', 7, 640, 185, 20, 20); save mod icon
	GUICtrlSetResizing(-1, 800)
	GUICtrlSetState(-1, $GUI_HIDE)
	$g_UI_Static[11][8] = GUICtrlCreateLabel('>', 705, 185, 30, 20, BitOR($SS_CENTER, $SS_CENTERIMAGE))
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetResizing(-1, 800)
	$g_UI_Interact[11][3] = GUICtrlCreateEdit('', 15, 85, 720, 90, $ES_WANTRETURN + $ES_MULTILINE + $ES_AUTOVSCROLL)
	GUICtrlSetResizing(-1, 806)
	$g_UI_Interact[11][4] = GUICtrlCreateListView('1|2', 15, 220, 720, 160, $LVS_REPORT+$LVS_SORTASCENDING+$LVS_NOSORTHEADER, $LVS_EX_GRIDLINES+$LVS_EX_FULLROWSELECT+$LVS_EX_INFOTIP+$WS_Ex_Clientedge)
	$g_UI_Handle[2] = GUICtrlGetHandle($g_UI_Interact[11][4])
	GUICtrlSetResizing(-1, 102)
	_GUICtrlListView_SetColumnWidth($g_UI_Interact[11][4], 0, 170)
	_GUICtrlListView_SetColumnWidth($g_UI_Interact[11][4], 1, 525)
	$g_UI_Interact[11][5] = GUICtrlCreateCombo('', 30, 250, 170, 20); hidden input for type
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 768)
	$g_UI_Interact[11][6] = GUICtrlCreateInput('', 230, 250, 470, 20); hidden input for value
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 768)
	$g_UI_Button[11][5] = GUICtrlCreateButton('<<<', 200, 250, 30, 20); save changes to the selected line
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 768)
	$g_UI_Interact[11][7] = GUICtrlCreateCombo('', 30, 400, 170, 90); setup
	GUICtrlSetResizing(-1, 576)
	$g_UI_Interact[11][8] = GUICtrlCreateInput('', 230, 400, 170, 20); translation
	GUICtrlSetResizing(-1, 576)
	$g_UI_Button[11][6] = GUICtrlCreateButton('', 505, 400, 170, 20); edit components
	GUICtrlSetResizing(-1, 576)
#EndRegion ModAdmin - TAB
; ---------------------------------------------------------------------------------------------
#Region ComponentAdmin - TAB
	$g_UI_Seperate[12][0] = GUICtrlCreateTabItem('Components')
	$g_UI_Static[12][4] = GUICtrlCreateLabel('', 15, 60, 75, 20, BitOR($SS_Left, $SS_CENTERIMAGE)); options
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetResizing(-1, 800)
	$g_UI_Static[12][5] = GUICtrlCreateLabel('', 45, 60, 60, 20, BitOR($SS_RIGHT , $SS_CENTERIMAGE)); modname
	GUICtrlSetResizing(-1, 800)
	$g_UI_Interact[12][7] = GUICtrlCreateCombo('', 115, 60, 620, 250)
	GUICtrlSetResizing(-1, 800)
	$g_UI_Interact[12][1] = GUICtrlCreateListView('1|2', 15, 90, 335, 290, $LVS_REPORT+$LVS_SORTASCENDING+$LVS_NOSORTHEADER, $LVS_EX_GRIDLINES + $LVS_EX_FULLROWSELECT + $LVS_EX_INFOTIP + $WS_Ex_Clientedge)
	GUICtrlSetResizing(-1, 98)
	$g_UI_Handle[6] = GUICtrlGetHandle($g_UI_Interact[12][1])
	$g_UI_Interact[12][2] = GUICtrlCreateListView('1|2', 400, 90, 335, 290, $LVS_REPORT+$LVS_SORTASCENDING+$LVS_NOSORTHEADER, $LVS_EX_GRIDLINES + $LVS_EX_FULLROWSELECT + $LVS_EX_INFOTIP + $WS_Ex_Clientedge)
	GUICtrlSetResizing(-1, 100)
	$g_UI_Handle[7] = GUICtrlGetHandle($g_UI_Interact[12][2])
	_GUICtrlListView_SetColumnWidth($g_UI_Interact[12][1], 1, 265)
	_GUICtrlListView_SetColumnWidth($g_UI_Interact[12][2], 1, 265)
	$g_UI_Static[12][1] = GUICtrlCreateLabel('', 350, 95, 50, 20, $SS_Center)
	GUICtrlSetFont(-1, 8, 800)
	GUICtrlSetResizing(-1, 544)
	$g_UI_Static[12][2] = GUICtrlCreateLabel('', 350, 115, 50, 20, $SS_Center)
	GUICtrlSetFont(-1, 8, 800)
	GUICtrlSetResizing(-1, 544)
	$g_UI_Button[12][1] = GUICtrlCreateButton('>', 360, 150, 30, 40)
	$g_UI_Button[12][2] = GUICtrlCreateButton('>>', 360, 225, 30, 40)
	$g_UI_Static[12][3] = GUICtrlCreateIcon(@SystemDir&'\shell32.dll', 7, 359, 300); save component icon
	GUICtrlSetState(-1, $GUI_HIDE)
	$g_UI_Interact[12][5] = GUICtrlCreateInput('', 30, 250, 170, 20); hidden input for type
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 768)
	$g_UI_Interact[12][6] = GUICtrlCreateInput('', 230, 250, 470, 20); hidden input for value
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 768)
	$g_UI_Button[12][3] = GUICtrlCreateButton('<<<', 200, 250, 30, 20); save changes to the selected line
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 768)
	$g_UI_Interact[12][3]  = GUICtrlCreateCombo('', 30, 400, 170, 90); setup
	GUICtrlSetResizing(-1, 576)
	$g_UI_Interact[12][4]  = GUICtrlCreateCombo('', 230, 400, 120, 90); translation
	GUICtrlSetResizing(-1, 576)
	$g_UI_Button[12][4] = GUICtrlCreateButton('', 505, 400, 170, 20); edit components
	GUICtrlSetResizing(-1, 576)
#EndRegion ComponentAdmin - TAB
; ---------------------------------------------------------------------------------------------
#Region Conflicts/DependenciesAdmin - TAB
	$g_UI_Seperate[13][0] = GUICtrlCreateTabItem('Depend')
	$g_UI_Static[13][1] = GUICtrlCreateLabel('', 15, 60, 75, 20, BitOR($SS_Left, $SS_CENTERIMAGE)); options
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetResizing(-1, 800)
	$g_UI_Static[13][5] = GUICtrlCreateIcon(@SystemDir&'\shell32.dll', 7, 400, 60, 20, 20); save dependency icon
	GUICtrlSetResizing(-1, 800)
	GUICtrlSetState(-1, $GUI_HIDE)
	$g_UI_Interact[13][2] = GUICtrlCreateInput('', 450, 60, 175, 20); search field
	GUICtrlSetResizing(-1, 548)
	$g_UI_Button[13][1] = GUICtrlCreateButton('', 650, 60, 85, 20, 0); search button
	GUICtrlSetResizing(-1, 804)
	$g_UI_Interact[13][1] = GUICtrlCreateListView('1|2|3', 15, 90, 720, 330, $LVS_NOSORTHEADER+$LVS_SHOWSELALWAYS, $LVS_EX_GRIDLINES + $LVS_EX_FULLROWSELECT + $LVS_EX_INFOTIP)
	_GUICtrlListView_SetColumnWidth($g_UI_Interact[13][1], 0, 250)
	_GUICtrlListView_SetColumnWidth($g_UI_Interact[13][1], 1, 400)
	_GUICtrlListView_SetColumnWidth($g_UI_Interact[13][1], 2, 50)
	GUICtrlSetResizing(-1, 98)
	$g_UI_Handle[4] = GUICtrlGetHandle($g_UI_Interact[13][1])
	$g_UI_Static[13][2] = GUICtrlCreateLabel('', 30, 60, 290, 20); => start a check
	GUICtrlSetResizing(-1, 802)
	GUICtrlSetState(-1, $GUI_HIDE)
	$g_UI_Interact[13][4] = GUICtrlCreateCombo('', 30, 90, 290, 20); condition
	GUICtrlSetResizing(-1, 802)
	GUICtrlSetState(-1, $GUI_HIDE)
	$g_UI_Static[13][3] = GUICtrlCreateLabel('', 30, 120, 290, 20); => because
	GUICtrlSetResizing(-1, 802)
	GUICtrlSetState(-1, $GUI_HIDE)
	$g_UI_Interact[13][5] = GUICtrlCreateCombo('', 30, 150, 290, 20); connection
	GUICtrlSetResizing(-1, 802)
	GUICtrlSetState(-1, $GUI_HIDE)
	$g_UI_Static[13][4] = GUICtrlCreateLabel('', 30, 180, 290, 30, $SS_Center); => error
	GUICtrlSetResizing(-1, 802)
	GUICtrlSetState(-1, $GUI_HIDE)
	$g_UI_Interact[13][6] = GUICtrlCreateCombo('', 30, 220, 290, 20); modname
	GUICtrlSetResizing(-1, 802)
	GUICtrlSetState(-1, $GUI_HIDE)
	$g_UI_Interact[13][7] = GUICtrlCreateCombo('', 30, 250, 170, 20); setup
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 802)
	$g_UI_Interact[13][8] = GUICtrlCreateCombo('', 230, 250, 90, 20); comp number
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 802)
	$g_UI_Interact[13][9] = GUICtrlCreateCombo('', 30, 280, 290, 20); comp desc
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 802)
	$g_UI_Button[13][4] = GUICtrlCreateButton('', 30, 320, 290, 20); save
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 802)
	$g_UI_Interact[13][10] = GUICtrlCreateEdit('', 15, 355, 720, 35, BitOR($SS_Left, $WS_VSCROLL, $ES_READONLY))
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 582)
	$g_UI_Interact[13][11] = GUICtrlCreateRadio('', 350, 90, 20, 20)
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 802)
	$g_UI_Interact[13][12] = GUICtrlCreateRadio('', 350, 150, 20, 20)
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 802)
	$g_UI_Button[13][3] = GUICtrlCreateButton('>>', 345, 250, 30, 50)
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 802)
	$g_UI_Interact[13][13] = GUICtrlCreateInput('', 400, 60, 335, 20)
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 804)
	$g_UI_Interact[13][3] = GUICtrlCreateListView('1|2|3|4', 400, 90, 335, 255, $LVS_NOSORTHEADER+$LVS_SHOWSELALWAYS, $LVS_EX_GRIDLINES + $LVS_EX_FULLROWSELECT + $LVS_EX_INFOTIP + $WS_Ex_Clientedge)
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 102)
	$g_UI_Handle[5] = GUICtrlGetHandle($g_UI_Interact[13][3])
	_GUICtrlListView_SetColumnWidth($g_UI_Handle[5], 0, 150)
	_GUICtrlListView_SetColumnWidth($g_UI_Handle[5], 1, 50)
	_GUICtrlListView_SetColumnWidth($g_UI_Handle[5], 2, 200)
	_GUICtrlListView_SetColumnWidth($g_UI_Handle[5], 3, 0)
	GUICtrlCreateTabItem('')
#EndRegion Conflicts/DependenciesAdmin - TAB
; ---------------------------------------------------------------------------------------------
#Region Install-options - TAB
	$g_UI_Seperate[14][0] = GUICtrlCreateTabItem("InstallOpts")
	$g_UI_Seperate[14][1] = GUICtrlCreateGroup('', 15, 60, 400, 190)
	GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
	$g_UI_Static[14][1] = GUICtrlCreateLabel('', 30, 90, 100, 20, $SS_CENTERIMAGE); download logic
	$g_UI_Interact[14][1] = GUICtrlCreateCombo('', 140, 90, 260, 20)
	$g_UI_Static[14][2] = GUICtrlCreateLabel('', 30, 125, 100, 20, $SS_CENTERIMAGE); extraction logic
	$g_UI_Interact[14][2] = GUICtrlCreateCombo('', 140, 125, 260, 120)
	$g_UI_Static[14][3] = GUICtrlCreateLabel('', 30, 160, 100, 20, $SS_CENTERIMAGE); install logic
	$g_UI_Interact[14][3] = GUICtrlCreateCombo('', 140, 160, 260, 20)
	$g_UI_Interact[14][4] = GUICtrlCreateCheckbox('', 30, 190, 370, 20); install in groups
	$g_UI_Interact[14][10] = GUICtrlCreateCheckbox('', 30, 220, 370, 20); signal pauses
	GUICtrlCreateGroup('', -99, -99, 1, 1)
	$g_UI_Seperate[14][2] = GUICtrlCreateGroup('', 15, 270, 400, 140)
	GUICtrlSetFont(-1, 8, 800, 0, "MS Sans Serif")
	$g_UI_Interact[14][5] = GUICtrlCreateCheckbox('', 30, 305, 370, 20); use widescreen
	$g_UI_Interact[14][6] = GUICtrlCreateInput('', 30, 345, 170, 20, $SS_CENTER)
	$g_UI_Interact[14][7] = GUICtrlCreateInput('', 230, 345, 170, 20, $SS_CENTER)
	$g_UI_Interact[14][8] = GUICtrlCreateCheckbox('', 30, 375, 370, 20); add text-patches
	GUICtrlCreateGroup('', -99, -99, 1, 1)
	$g_UI_Interact[14][9] = GUICtrlCreateEdit('', 430, 65, 305, 345, BitOR($SS_Left, $WS_VSCROLL, $ES_READONLY)); help
	GUICtrlSetBkColor(-1, 0xFFFFFF)
	GUICtrlCreateTabItem('')
#EndRegion Install-options - TAB
; ---------------------------------------------------------------------------------------------
#Region language-options - TAB
	$g_UI_Seperate[15][0] = GUICtrlCreateTabItem('Language')
	$g_UI_Interact[15][1] = GUICtrlCreateListView('1', 15, 65, 190, 175, $LVS_REPORT+$LVS_SORTASCENDING+$LVS_NOSORTHEADER, $LVS_EX_GRIDLINES + $LVS_EX_FULLROWSELECT + $LVS_EX_INFOTIP + $WS_Ex_Clientedge)
	;GUICtrlSetResizing(-1, 98)
	$g_UI_Interact[15][2] = GUICtrlCreateListView('1', 225, 65, 190, 175, $LVS_REPORT+$LVS_NOSORTHEADER+$LVS_SINGLESEL, $LVS_EX_GRIDLINES + $LVS_EX_FULLROWSELECT + $LVS_EX_INFOTIP + $WS_Ex_Clientedge)
	;GUICtrlSetResizing(-1, 100)
	$g_UI_Button[15][1] = GUICtrlCreateButton('', 15, 250, 90, 20)
	$g_UI_Button[15][2] = GUICtrlCreateButton('', 115, 250, 90, 20)
	$g_UI_Button[15][3] = GUICtrlCreateButton('',  225, 250, 90, 20)
	$g_UI_Button[15][4] = GUICtrlCreateButton('',  325, 250, 90, 20)
	$g_UI_Button[15][5] = GUICtrlCreateButton('', 15, 280, 400, 20, $BS_FLAT)
	$g_UI_Interact[15][3] = GUICtrlCreateEdit('', 15, 305, 400, 105, BitOR($SS_Left, $WS_VSCROLL, $ES_READONLY)); list translations
	GUICtrlSetBkColor(-1, 0xFFFFFF)
	$g_UI_Interact[15][4] = GUICtrlCreateEdit('', 430, 65, 305, 345, BitOR($SS_Left, $WS_VSCROLL, $ES_READONLY)); help for this screen
	GUICtrlSetBkColor(-1, 0xFFFFFF)
	GUICtrlCreateTabItem('')
#EndRegion language-options - TAB
; ---------------------------------------------------------------------------------------------
#Region install-order-admin - TAB
	$g_UI_Seperate[16][0] = GUICtrlCreateTabItem('Select')
	$g_UI_Static[16][1] = GUICtrlCreateLabel('', 15, 60, 75, 20, BitOR($SS_Left, $SS_CENTERIMAGE)); options
	GUICtrlSetCursor(-1, 0)
	GUICtrlSetResizing(-1, 800)
	$g_UI_Static[16][2] = GUICtrlCreateLabel('', 45, 60, 60, 20, BitOR($SS_RIGHT , $SS_CENTERIMAGE)); mod
	GUICtrlSetResizing(-1, 800)
	$g_UI_Interact[16][1] = GUICtrlCreateCombo('', 115, 60, 285, 20); modname
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, 800)
	$g_UI_Interact[16][11] = GUICtrlCreateInput('', 450, 60, 175, 20); search field
	GUICtrlSetResizing(-1, 548)
	GUICtrlSetState(-1, $GUI_HIDE)
	$g_UI_Button[16][6] = GUICtrlCreateButton('', 650, 60, 85, 20, 0); search button
	GUICtrlSetResizing(-1, 804)
	GUICtrlSetState(-1, $GUI_HIDE)
	$g_UI_Static[16][3] = GUICtrlCreateLabel('', 400, 60, 50, 20, BitOR($SS_RIGHT , $SS_CENTERIMAGE)); theme
	GUICtrlSetResizing(-1, 800)
	$g_UI_Interact[16][2] = GUICtrlCreateCombo('', 460, 60, 140, 20); theme/group
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, 800)
	$g_UI_Button[16][1] = GUICtrlCreateCheckbox('R', 620, 60, 20, 20, 0x1000)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, 800)
	$g_UI_Button[16][2] = GUICtrlCreateCheckbox('S', 640, 60, 20, 20, 0x1000)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, 800)
	$g_UI_Button[16][3] = GUICtrlCreateCheckbox('T', 660, 60, 20, 20, 0x1000)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, 800)
	$g_UI_Button[16][4] = GUICtrlCreateCheckbox('E', 680, 60, 20, 20, 0x1000)
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, 800)
	$g_UI_Static[16][5] = GUICtrlCreateIcon(@SystemDir&'\shell32.dll', 7, 710, 60, 20, 20); save selection icon
	GUICtrlSetResizing(-1, 804)
	GUICtrlSetState(-1, $GUI_HIDE)
	$g_UI_Interact[16][3] = GUICtrlCreateListView('1|2|3|4|5|6|7|8', 15, 90, 720, 330, $LVS_REPORT+$LVS_NOSORTHEADER+$LVS_SHOWSELALWAYS, $LVS_EX_GRIDLINES + $LVS_EX_FULLROWSELECT + $LVS_EX_INFOTIP + $WS_Ex_Clientedge)
	GUICtrlSetResizing(-1, 98)
	$g_UI_Handle[8] = GUICtrlGetHandle($g_UI_Interact[16][3])
	_GUICtrlListView_SetColumnWidth($g_UI_Interact[16][3], 0, 50)
	_GUICtrlListView_SetColumnWidth($g_UI_Interact[16][3], 1, 100)
	_GUICtrlListView_SetColumnWidth($g_UI_Interact[16][3], 2, 50)
	_GUICtrlListView_SetColumnWidth($g_UI_Interact[16][3], 3, 465)
	$g_UI_Static[16][4] = GUICtrlCreateLabel('', 30, 220, 20, 20, $SS_CENTERIMAGE); translation
	GUICtrlSetState(-1, $GUI_DISABLE)
	GUICtrlSetResizing(-1, 768)
	$g_UI_Interact[16][4] = GUICtrlCreateCombo('', 30, 250, 170, 20); setup
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 768)
	$g_UI_Interact[16][5] = GUICtrlCreateCombo('', 230, 250, 170, 20); comp number
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 768)
	$g_UI_Interact[16][6] = GUICtrlCreateCombo('', 420, 250, 280, 20); comp desc
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 768)
	$g_UI_Button[16][5] = GUICtrlCreateButton('<<<', 705, 250, 30, 20); save changes to the selected line
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 768)
	$g_UI_Interact[16][7] = GUICtrlCreateCombo('', 30, 280, 170, 20); linetype
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 768)
	$g_UI_Interact[16][8] = GUICtrlCreateCheckbox('', 230, 280, 60, 20, 0x1000); to checkbox
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 768)
	$g_UI_Interact[16][9] = GUICtrlCreateCombo('', 300, 280, 100, 20); to comp
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 768)
	$g_UI_Interact[16][10] = GUICtrlCreateInput('', 420, 280, 280, 20); install dependencies
	GUICtrlSetState(-1, $GUI_HIDE)
	GUICtrlSetResizing(-1, 768)
	GUICtrlCreateTabItem('')
#EndRegion install-order-admin - TAB
; ---------------------------------------------------------------------------------------------
#Region Creating contextmenus
	$g_UI_Menu[1][0] = GUICtrlCreateContextMenu($g_UI_Static[4][2]); >> option-menu
	$g_UI_Menu[1][6] = GUICtrlCreateMenu('6', $g_UI_Menu[1][0]); Click properties
	$g_UI_Menu[1][12] = GUICtrlCreateMenu('12', $g_UI_Menu[1][0]); View
	$g_UI_Menu[1][13] = GUICtrlCreateMenu('13', $g_UI_Menu[1][0]); Tools
	GUICtrlCreateMenuItem('', $g_UI_Menu[1][0])
	$g_UI_Menu[1][1] = GUICtrlCreateMenuItem('1', $g_UI_Menu[1][0]); Load
	$g_UI_Menu[1][2] = GUICtrlCreateMenuItem('2', $g_UI_Menu[1][0]); Save
	$g_UI_Menu[1][3] = GUICtrlCreateMenuItem('3', $g_UI_Menu[1][0]); Import
	$g_UI_Menu[1][4] = GUICtrlCreateMenuItem('4', $g_UI_Menu[1][0]); Export
	$g_UI_Menu[1][11] = GUICtrlCreateMenuItem('11', $g_UI_Menu[1][0]); Import WeiDU
; Creating sub-menuitems for click-properties
	$g_UI_Menu[1][7] = GUICtrlCreateMenuItem('7', $g_UI_Menu[1][6]); recommended
	GUICtrlSetState(-1, $GUI_CHECKED)
	$g_UI_Menu[1][8] = GUICtrlCreateMenuItem('8', $g_UI_Menu[1][6]); standard
	$g_UI_Menu[1][9] = GUICtrlCreateMenuItem('9', $g_UI_Menu[1][6]); tactic
	$g_UI_Menu[1][10] = GUICtrlCreateMenuItem('10', $g_UI_Menu[1][6]); expert
; Creating sub-menuitems for View-menu
	$g_UI_Menu[1][5] = GUICtrlCreateMenuItem('5', $g_UI_Menu[1][12]); Extend
	$g_UI_Menu[1][16] = GUICtrlCreateMenuItem('16', $g_UI_Menu[1][12]); pdf-sorting
; Creating sub-menuitems for tools-menu
	$g_UI_Menu[1][14] = GUICtrlCreateMenuItem('14', $g_UI_Menu[1][13]); administrate mods
	$g_UI_Menu[1][15] = GUICtrlCreateMenuItem('15', $g_UI_Menu[1][13]); administrate components
	$g_UI_Menu[1][17] = GUICtrlCreateMenuItem('17', $g_UI_Menu[1][13]); administrate selection
	$g_UI_Menu[1][18] = GUICtrlCreateMenuItem('18', $g_UI_Menu[1][13]); administrate dependencies
; Creating basic add/remove/mark-entries
	For $m=2 to 4
		$g_UI_Menu[$m][0] = GUICtrlCreateContextMenu($g_UI_Static[4][$m+1]); context-menu
		$g_UI_Menu[$m][1] = GUICtrlCreateMenu(0, $g_UI_Menu[$m][0]); special groups-menu
		GUICtrlCreateMenuItem('', $g_UI_Menu[$m][0]); seperator
		$g_UI_Menu[$m][2] = GUICtrlCreateMenuItem(0, $g_UI_Menu[$m][0]); all
	Next
; Creating admin-options-menu
	$g_UI_Menu[5][0] = GUICtrlCreateContextMenu($g_UI_Static[11][1]); >> option-menu
	$g_UI_Menu[5][1] = GUICtrlCreateMenuItem('1', $g_UI_Menu[5][0]); New
	$g_UI_Menu[5][2] = GUICtrlCreateMenuItem('2', $g_UI_Menu[5][0]); Save
	$g_UI_Menu[5][3] = GUICtrlCreateMenuItem('3', $g_UI_Menu[5][0]); Delete
	$g_UI_Menu[5][4] = GUICtrlCreateMenuItem('4', $g_UI_Menu[5][0]); Revert
	GUICtrlCreateMenuItem('', $g_UI_Menu[5][0])
	$g_UI_Menu[5][5] = GUICtrlCreateMenu('5', $g_UI_Menu[5][0]); Edit
; Creating sub-menuitems for editing entries
	$g_UI_Menu[5][13] = GUICtrlCreateMenuItem('13', $g_UI_Menu[5][5]); new entry
	$g_UI_Menu[5][6] = GUICtrlCreateMenuItem('6', $g_UI_Menu[5][5]); edit entry
	$g_UI_Menu[5][7] = GUICtrlCreateMenuItem('7', $g_UI_Menu[5][5]); delete entry
	$g_UI_Menu[5][8] = GUICtrlCreateMenuItem('8', $g_UI_Menu[5][5]); open entry
	$g_UI_Menu[5][9] = GUICtrlCreateMenuItem('9', $g_UI_Menu[5][5]); test enty
	$g_UI_Menu[5][14] = GUICtrlCreateMenuItem('14', $g_UI_Menu[5][5]); select all
	$g_UI_Menu[5][10] = GUICtrlCreateMenu('10', $g_UI_Menu[5][0]); administration
; Creating sub-menuitems for administration
	$g_UI_Menu[5][11] = GUICtrlCreateMenuItem('11', $g_UI_Menu[5][10]); web-update
	$g_UI_Menu[5][12] = GUICtrlCreateMenuItem('12', $g_UI_Menu[5][10]); administrate components
	$g_UI_Menu[5][15] = GUICtrlCreateMenuItem('15', $g_UI_Menu[5][10]); administrate selection
	$g_UI_Menu[5][16] = GUICtrlCreateMenuItem('16', $g_UI_Menu[5][10]); administrate dependencies
; Creating component-options-menu
	$g_UI_Menu[6][0] = GUICtrlCreateContextMenu($g_UI_Static[12][4]); >> option-menu
	$g_UI_Menu[6][1] = GUICtrlCreateMenuItem('1', $g_UI_Menu[6][0]); Save
	$g_UI_Menu[6][2] = GUICtrlCreateMenuItem('2', $g_UI_Menu[6][0]); Scan
	$g_UI_Menu[6][3] = GUICtrlCreateMenuItem('3', $g_UI_Menu[6][0]); switch to English
	$g_UI_Menu[6][10] = GUICtrlCreateMenuItem('10', $g_UI_Menu[6][0]); Revert
	$g_UI_Menu[6][11] = GUICtrlCreateMenuItem('11', $g_UI_Menu[6][0]); switch edit-mode
	GUICtrlCreateMenuItem('', $g_UI_Menu[6][0])
	$g_UI_Menu[6][4] = GUICtrlCreateMenu('4', $g_UI_Menu[6][0]); Edit
; Creating sub-menuitems for editing entries
	$g_UI_Menu[6][9] = GUICtrlCreateMenuItem('9', $g_UI_Menu[6][4]); new entry
	$g_UI_Menu[6][5] = GUICtrlCreateMenuItem('5', $g_UI_Menu[6][4]); copy entry
	$g_UI_Menu[6][6] = GUICtrlCreateMenuItem('6', $g_UI_Menu[6][4]); edit entry
	$g_UI_Menu[6][7] = GUICtrlCreateMenuItem('7', $g_UI_Menu[6][4]); delete entry
	$g_UI_Menu[6][8] = GUICtrlCreateMenuItem('8', $g_UI_Menu[6][4]); select all
	$g_UI_Menu[6][12] = GUICtrlCreateMenu('7', $g_UI_Menu[6][0]); administration
; Creating sub-menuitems for administration
	$g_UI_Menu[6][13] = GUICtrlCreateMenuItem('13', $g_UI_Menu[6][12]); administrate mods
	$g_UI_Menu[6][14] = GUICtrlCreateMenuItem('14', $g_UI_Menu[6][12]); administrate selection
	$g_UI_Menu[6][15] = GUICtrlCreateMenuItem('15', $g_UI_Menu[6][12]); administrate dependencies
; Creating select-options-menu
	$g_UI_Menu[7][0] = GUICtrlCreateContextMenu($g_UI_Static[16][1]); >> option-menu
	$g_UI_Menu[7][1] = GUICtrlCreateMenuItem('1', $g_UI_Menu[7][0]); Save
	$g_UI_Menu[7][2] = GUICtrlCreateMenuItem('2', $g_UI_Menu[7][0]); Revert
	GUICtrlCreateMenuItem('', $g_UI_Menu[7][0])
	$g_UI_Menu[7][3] = GUICtrlCreateMenu('3', $g_UI_Menu[7][0]); Edit
; Creating sub-menuitems for editing entries
	$g_UI_Menu[7][4] = GUICtrlCreateMenuItem('4', $g_UI_Menu[7][3]); new entry
	$g_UI_Menu[7][5] = GUICtrlCreateMenuItem('5', $g_UI_Menu[7][3]); cut entry
	$g_UI_Menu[7][6] = GUICtrlCreateMenuItem('6', $g_UI_Menu[7][3]); copy entry
	$g_UI_Menu[7][7] = GUICtrlCreateMenuItem('7', $g_UI_Menu[7][3]); paste entry
	$g_UI_Menu[7][8] = GUICtrlCreateMenuItem('8', $g_UI_Menu[7][3]); edit entry
	$g_UI_Menu[7][9] = GUICtrlCreateMenuItem('9', $g_UI_Menu[7][3]); delete entry
	$g_UI_Menu[7][10] = GUICtrlCreateMenu('10', $g_UI_Menu[7][0]); administration
; Creating sub-menuitems for administration
	$g_UI_Menu[7][11] = GUICtrlCreateMenuItem('11', $g_UI_Menu[7][10]); administrate mods
	$g_UI_Menu[7][12] = GUICtrlCreateMenuItem('12', $g_UI_Menu[7][10]); administrate components
	$g_UI_Menu[7][13] = GUICtrlCreateMenuItem('13', $g_UI_Menu[7][10]); administrate dependencies
; Creating dependency-options-menu
	$g_UI_Menu[8][0] = GUICtrlCreateContextMenu($g_UI_Static[13][1]); >> option-menu
	$g_UI_Menu[8][1] = GUICtrlCreateMenuItem('1', $g_UI_Menu[8][0]); Save
	$g_UI_Menu[8][2] = GUICtrlCreateMenuItem('2', $g_UI_Menu[8][0]); Revert
	GUICtrlCreateMenuItem('', $g_UI_Menu[8][0])
	$g_UI_Menu[8][3] = GUICtrlCreateMenu('3', $g_UI_Menu[8][0]); Edit
; Creating sub-menuitems for editing entries
	$g_UI_Menu[8][4] = GUICtrlCreateMenuItem('4', $g_UI_Menu[8][3]); new entry
	$g_UI_Menu[8][5] = GUICtrlCreateMenuItem('5', $g_UI_Menu[8][3]); edit entry
	$g_UI_Menu[8][6] = GUICtrlCreateMenuItem('6', $g_UI_Menu[8][3]); delete entry
	$g_UI_Menu[8][7] = GUICtrlCreateMenu('7', $g_UI_Menu[8][0]); administration
; Creating sub-menuitems for administration
	$g_UI_Menu[8][8] = GUICtrlCreateMenuItem('8', $g_UI_Menu[8][7]); administrate mods
	$g_UI_Menu[8][9] = GUICtrlCreateMenuItem('9', $g_UI_Menu[8][7]); administrate components
	$g_UI_Menu[8][10] = GUICtrlCreateMenuItem('10', $g_UI_Menu[8][7]); administrate selection
; Adjust $g_CentralArray[0][1] (end of _Tree_Populate) if you add more GUI-items
#EndRegion Creating contextmenus
EndFunc   ;==>_BuildGUI
