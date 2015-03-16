AutoItSetOption('WinTitleMatchMode', 2); set a more flexible way to search for windows
AutoItSetOption('GUIResizeMode', 1); resize and reposition GUI-elements according to new window size
AutoItSetOption('GUICloseOnESC', 0);  don't send the $GUI_EVENT_CLOSE message when ESC is pressed
AutoItSetOption('TrayIconDebug', 1); shows the current script line in the tray icon tip to help debugging
AutoItSetOption('GUIOnEventMode', 1); disable OnEvent functions notifications
AutoItSetOption('OnExitFunc','Au3Exit'); sets the name of the function called when AutoIt exits

TraySetIcon (@ScriptDir&'\Pics\BWS.ico'); sets the tray-icon

#Region Global vars
; Global are named with a $g_ , parameters with a $p_ . Normal variables don't have a prefix.
; files and folders
Global $g_BaseDir = StringLeft(@ScriptDir, StringInStr(@ScriptDir, '\', 1, -1)-1), $g_GConfDir, $g_GameDir, $g_ProgName = 'BiG World Setup'
Global $g_ProgDir = $g_BaseDir & '\BiG World Setup', $g_LogDir=$g_ProgDir&'\Logs', $g_DownDir = $g_BaseDir & '\BiG World Downloads'
Global $g_BG1Dir, $g_BG2Dir, $g_BGEEDIR, $g_BG2EEDIR, $g_IWD1Dir, $g_IWD2Dir, $g_PSTDir, $g_RemovedDir, $g_BackupDir, $g_LogFile = $g_LogDir & '\BiG World Debug.txt'
Global $g_BWSIni = $g_ProgDir & '\Config\Setup.ini', $g_MODIni, $g_UsrIni = $g_ProgDir & '\Config\User.ini'
; select-gui vars
Global $g_Compilation='R', $g_LimitedSelection = 0, $g_Tags, $g_ActiveConnections[1], $g_Groups
Global $g_TreeviewItem[1][1], $g_CHTreeviewItem[1][1], $g_Connections, $g_CentralArray[4000][16], $g_GUIFold
; Logging, Reading Streams / Process-Window
Global $g_ConsoleOutput = '', $g_STDStream, $g_ConsoleOutput, $g_pQuestion = 0
; program options and misc
Global $g_Setups, $g_Skip, $g_Clip; available setups, items to skip
Global $g_CurrentPackages, $g_fLock, $g_FItem = IniRead($g_BWSIni, 'Options', 'Start', '1'); selected packages, fixed mods and last processed item
Global $g_ATrans = StringSplit(IniRead($g_BWSIni, 'Options', 'AppLang', 'EN|GE'), '|'), $g_ATNum = 1, $g_MLang; available translations and mod translations
Global $g_UDll = DllOpen('user32.dll'); we have to use this for detecting the mouse or keboard-usage
Global $g_Down[6][2]; used for updating download-progressbar
; ---------------------------------------------------------------------------------------------
; New GUI-Builing
; ---------------------------------------------------------------------------------------------
Global $g_UI[5], $g_UI_Static[17][20], $g_UI_Button[17][20], $g_UI_Seperate[17][10], $g_UI_Interact[17][20], $g_UI_Menu[10][50]
Global $g_Search[5], $g_Flags[24] = [1], $g_UI_Handle[10]
Global $g_TRAIni = $g_ProgDir & '\Config\Translation-'&$g_ATrans[$g_ATNum]&'.ini', $g_UI_Message = IniReadSection($g_TRAIni, 'UI-Runtime')
; g_Flags => 1=w: continue without link checking; 2=w: update links; 3=mod language-string; 4=w: mc-disabled 5=admin-tokens short/Enable Pause-Resume
; 6=admin-tokens long/overwitten text by pause, 7=current tip-handle, 8=current tab is advsel, 9=window is locked, 10=Rebuild when leaving first screens/tab to go back from admin-tabs
; 11=back is pressed, 12=forward is pressed, 13=real exit, 14=current selected install method, 15=greet-picture is visible
; 16=admin-lv has focus/treeicon clicked, 17=treelabel clicked, 18=beep, 19=cmd-started, 20=w: selection-is-higer-than-your-preselection
; 21=use old sorting format, 22=wscreen ID, 23=download-button-number/unsolved dependencies
; g_UI_Handle => 0=adv. TreeView, 1=dep. ListView, 2=mod ListView, 3= 4/5=dep admin ListViews, 6/7=comp Listviews, 8=select admin
; g_UI_Menu[0] => 0=, 1=used themes in advmenu, 2=number of themes in adv-menus, 3=number of themes+groups in adv-menus, 4=mod, depend and select-contextmenu, 5=, 6-9=depend-context-menu
; $g_UI 0=main, 1=child-window with BWP-pic, 2=width, 3=height, 4=child-window with progress-bar

#EndRegion Global vars
#Region Includes
#include'Includes\01_UDF1.au3'
#include'Includes\02_UDF2.au3'
#include'Includes\03_Admin.au3'
#include'Includes\04_Backup.au3'
#include'Includes\05_Basics.au3'
#include'Includes\06_Depend.au3'
#include'Includes\07_Extract.au3'
#include'Includes\08_GUI.au3'
#include'Includes\09_Install.au3'
#include'Includes\10_Misc-GUI.au3'
#include'Includes\11_NET.au3'
#include'Includes\12_Process.au3'
#include'Includes\13_Select-AI.au3'
#include'Includes\14_Select-GUILoop.au3'
#include'Includes\15_Select-Helper.au3'
#include'Includes\16_Select-Tree.au3'
#include'Includes\17_Testing.au3'
#EndRegion Includes
;#NoTrayIcon

$g_DownDir = IniRead($g_UsrIni, 'Options', 'Download', $g_DownDir)
$g_Flags[14]='BWP'
$g_GConfDir = $g_ProgDir & '\Config\'&$g_Flags[14]
$g_ModIni= $g_GConfDir & '\Mod.ini'
$g_Setups = _CreateList()

Global $g_Note='', $g_Error
Global $Prefix[14] = [13, '', 'Add', 'CH-Add', 'CZ-Add', 'EN-Add', 'FR-Add', 'GE-Add', 'IT-Add', 'JP-Add', 'KO-Add', 'PO-Add', 'RU-Add', 'SP-Add']

#cs
$Return=_Net_LinkGetInfo('http://www.shsforums.net/index.php?app=downloads&module=display&section=download&do=confirm_download&id=121', 1)
ConsoleWrite($Return[0] & ' == ' & $Return[1] & ' == ' & $Return[2]&@CRLF)
Exit
#ce
; $g_Flags 1=Write into ini 2=download file 3=show changes/erros only 4=Pause 5=
; 6=current name 7=last shown name in console 8=last shown name in note 9=last shown name in errors


$g_UI[0] = GuiCreate($g_ProgName, 500, 290, -1, -1, $WS_MINIMIZEBOX + $WS_MAXIMIZEBOX + $WS_CAPTION + $WS_POPUP + $WS_SYSMENU + $WS_SIZEBOX)

GUISetFont(8, 400, 0, 'MS Sans Serif')
GUISetOnEvent($GUI_EVENT_CLOSE, "_Check_OnEvent")
GUISetIcon (@ScriptDir&'\Pics\BWS.ico', 0); sets the GUIs icon

$g_UI_Static[1][1] = GuiCtrlCreateLabel("Mod", 10, 10, 480, 20, $SS_CENTER+$SS_CENTERIMAGE)
GUICtrlSetFont(-1, 10, 800, 0, 'MS Sans Serif')
GUICtrlSetResizing(-1, 512+32); => top, no height-change
$g_UI_Interact[1][1] = GuiCtrlCreateProgress(10, 50, 480, 10)
GUICtrlSetResizing(-1, 512+32); => top, no height-change
$g_UI_Interact[1][6] = GuiCtrlCreateProgress(10, 65, 480, 10)
GUICtrlSetResizing(-1, 512+32); => top, no height-change
GUICtrlSetState(-1, $GUI_HIDE)
$g_UI_Interact[1][2] = GuiCtrlCreateEdit("", 10, 80, 480, 140)
_GUICtrlEdit_SetLimitText($g_UI_Interact[1][2], 64000)
GUICtrlSetResizing(-1, 2+4+32+64); => left,right, top, bottom
$g_UI_Interact[1][3] = GuiCtrlCreateCheckbox("Save changes", 10, 230, 150, 20)
GUICtrlSetResizing(-1, 512+64); => bottom, no height-change
GUICtrlSetOnEvent(-1, '_Check_OnEvent')
$g_UI_Interact[1][4] = GuiCtrlCreateCheckbox("Load changed data", 175, 230, 150, 20)
GUICtrlSetResizing(-1, 512+64); => bottom, no height-change
GUICtrlSetOnEvent(-1, '_Check_OnEvent')
$g_UI_Interact[1][5] = GuiCtrlCreateCheckbox("Only show changes", 340, 230, 150, 20)
GUICtrlSetResizing(-1, 512+64); => bottom, no height-change
GUICtrlSetOnEvent(-1, '_Check_OnEvent')
$g_UI_Button[1][1] = GuiCtrlCreateButton("Start", 10, 255, 150, 20)
GUICtrlSetResizing(-1, 512+64); => bottom, no height-change
GUICtrlSetOnEvent(-1, '_Check_OnEvent')
$g_UI_Button[1][2] = GuiCtrlCreateButton("Export", 175, 255, 150, 20)
GUICtrlSetResizing(-1, 512+64); => bottom, no height-change
GUICtrlSetOnEvent(-1, '_Check_OnEvent')
$g_UI_Button[1][3] = GuiCtrlCreateButton("Exit", 340, 255, 150, 20)
GUICtrlSetResizing(-1, 512+64); => bottom, no height-change
GUICtrlSetOnEvent(-1, '_Check_OnEvent')

GuiSetState()

Local $Start = TimerInit()

GUICtrlSetState($g_UI_Interact[1][6], $GUI_SHOW)

For $s=1 to $g_Setups[0][0]
	ConsoleWrite($g_Setups[$s][0] & @CRLF)
	While $g_Flags[4] = 0
		Sleep(10)
	WEnd
	
;~ $New='YESLICKNPC'
;~ 	If Not StringInStr('|'&$New&'|', '|'&$g_Setups[$s][0]&'|') Then ContinueLoop; only test a few
	;_GrabFiles($g_Setups[$s][0])
	_CheckURL($g_Setups[$s][0], $g_Setups[$s][1], $s)
Next

If $g_Flags[3] = 0 Then; show output
	_Check_SetScroll(@CRLF&'Done. Time:'&Round(TimerDiff($Start), 3)&@CRLF, 0)
	_Check_SetScroll(@CRLF&'NOTE:'&@CRLF&$g_Note&@CRLF&'ERROR:'&@CRLF&$g_Error, 0)
Else
	$g_Flags[3] = 1
	_Check_SetScroll(@CRLF&'Done. Time:'&Round(TimerDiff($Start), 3)&@CRLF, 0)
EndIf

While 1
	Sleep(10)
WEnd
Exit

Func _GrabFiles($p_Setup, $p_String='', $p_Num=0)
	$Section=IniReadSection($g_MODIni, $p_Setup)
	$g_Flags[6] = _IniRead($Section, 'Name', '')&' ['&$p_Setup&']'
	GUICtrlSetData($g_UI_Static[1][1], $g_Flags[6])
	GUICtrlSetData($g_UI_Interact[1][1], ($p_Num*100)/$g_Setups[0][0])
	For $p=1 to $Prefix[0]
		$Update=0
		$File=_IniRead($Section, $Prefix[$p]&'Save', '')
		If $File = '' Or $File = 'Manual' Then ContinueLoop
		$URL=_IniRead($Section, $Prefix[$p]&'Down', '')
		;If Not StringInStr($URL, 'baldursgatemods.com') Then ContinueLoop
		ConsoleWrite($p_Setup&' ['&$Prefix[$p]&'Down]'&@CRLF)
		$Size=_IniRead($Section, $Prefix[$p]&'Size', '')
		If FileExists($g_DownDir&'\'&$File) And FileGetSize($g_DownDir&'\'&$File) = $Size Then ContinueLoop
		If $File <> '' Then
			While 1
				If Not FileExists($g_DownDir&'\'&$File) Then ExitLoop
				$Test=FileDelete($g_DownDir & '\' & $File)
				If $Test = 0 Then
					$Test=MsgBox(16+5, $g_ProgName&': Löschen', 'Konnte '&$g_DownDir & '\' & $File&' nicht entfernen.', 0, $g_UI[0])
					If $Test = 2  Then Exit
				Else
					While FileExists($g_DownDir&'\'&$File)
						Sleep(50)
					WEnd	
					ExitLoop
				EndIf
			WEnd
		EndIf			
		_Check_SetScroll('Lade: ['&$Prefix[$p]&'] '&$File&' von ' & $p_Setup, 1)
		$PID=Run('"' & $g_ProgDir & '\Tools\wget.exe" --tries=3 --no-check-certificate --continue --progress=dot:binary  --output-file="'&@TempDir&'\'&$File&'.log" --output-document="' & $g_DownDir & '\' & $File & '" "' & $URL & '"', @ScriptDir, @SW_HIDE)
		While ProcessExists($PID)
			GUICtrlSetData($g_UI_Interact[1][6], (FileGetSize($g_DownDir & '\' & $File)*100)/$Size)
			Sleep(1000)
		WEnd
		GUICtrlSetData($g_UI_Interact[1][6], 0)
		$Log=FileRead(@TempDir&'\'&$File&'.log')
		If StringInStr($Log, 'saved ['&$Size&'/'&$Size&']') Then
			FileDelete(@TempDir&'\'&$File&'.log'); all ok
		ElseIf StringRegExp($Log, 'saved\s\x5b\d*\x5d') Then
			If $g_Flags[1] = 1 Then IniWrite($g_ModIni, $p_Setup, $Prefix[$p]&'Size', FileGetSize($g_DownDir & '\' & $File)); save size for later
		Else
			ShellExecute(@TempDir&'\'&$File&'.log'); show error-log
		EndIf
	Next		
EndFunc	

; ---------------------------------------------------------------------------------------------
; OnEvent actions for the gui
; ---------------------------------------------------------------------------------------------
Func _Check_OnEvent()
	Switch @GUI_CtrlId
		Case $GUI_EVENT_CLOSE
			Exit
		Case $g_UI_Interact[1][3]
			$g_Flags[1]=GUICtrlRead($g_UI_Interact[1][3]); Test
		Case $g_UI_Interact[1][4]
			$g_Flags[2]=GUICtrlRead($g_UI_Interact[1][4]); Download
			If $g_Flags[2] = 1 Then
				GUICtrlSetState($g_UI_Interact[1][6], $GUI_SHOW)
			Else
				GUICtrlSetState($g_UI_Interact[1][6], $GUI_HIDE)
			EndIf
		Case $g_UI_Interact[1][5]
			$g_Flags[3]=GUICtrlRead($g_UI_Interact[1][5]); Suppress
		Case $g_UI_Button[1][1]
			If $g_Flags[4]=0 Then; Start/Stop
				GUICtrlSetData($g_UI_Button[1][1], 'Pause')
				$g_Flags[4]=1
			Else
				GUICtrlSetData($g_UI_Button[1][1], 'Start')
				$g_Flags[4]=0
			EndIf
		Case $g_UI_Button[1][2]; Export
			_Check_Output2Html()
		Case $g_UI_Button[1][3]; Exit
			Exit
	EndSwitch
EndFunc   ;==>__Check_OnEvent

; ---------------------------------------------------------------------------------------------
; Dump the value of the Edit-control into a formated html-file
; ---------------------------------------------------------------------------------------------
Func _Check_Output2Html()
	$File = FileSaveDialog($g_ProgName&': Speichern', @ScriptDir, 'HTML files (*.html)',  16, 'Export_'&@YEAR&@MON&@MDAY&'.html', $g_UI[0])
	$Handle = FileOpen($File, 2)
	If $Handle = -1 Then Return SetError(1)
	FileWriteLine($Handle, '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">')
	FileWriteLine($Handle, '<html xmlns="http://www.w3.org/1999/xhtml">')
	FileWriteLine($Handle, '<head>')
	FileWriteLine($Handle, '<title>'&$File&'</title>')
	FileWriteLine($Handle, '<style type="text/css">')
	FileWriteLine($Handle, 'span {')
	FileWriteLine($Handle, "font-family: 'Courier New';")
	FileWriteLine($Handle, 'color: #000000;')
	FileWriteLine($Handle, 'font-size: 10pt;')
	FileWriteLine($Handle, '}')
	FileWriteLine($Handle, '</style>')
	FileWriteLine($Handle, '</head>')
	FileWriteLine($Handle, '<body bgcolor="#FFFFFF">')
	FileWriteLine($Handle, '<span>')
	$Array=StringSplit(StringStripCR(GUICtrlRead($g_UI_Interact[1][2])), @LF)
	For $a=1 to $Array[0]
		$Sign=StringLeft($Array[$a], 1)
		$Color = ''
		If $Sign = '-' Then $Color='ff8800'
		If $Sign = '>' Then $Color='0000ff'
		If $Sign = '+' Then $Color='007f00'
		If $Sign = '!' Then $Color='f70000'
		If $Color <> '' Then
			If $Sign='-' And StringRight($Array[$a], 4) = '.TP2' Then
				FileWriteLine($Handle, '<FONT COLOR="#'&$Color&'"><a href="'&_StringTranslate(StringTrimLeft($Array[$a], 1))&'">'&_StringTranslate(StringTrimLeft($Array[$a], 1))&'</a></FONT><br />')
			Else
				FileWriteLine($Handle, '<FONT COLOR="#'&$Color&'">'&_StringTranslate(StringTrimLeft($Array[$a], 1))&'</FONT><br />')
			EndIf
		Else
			FileWriteLine($Handle, _StringTranslate($Array[$a])&'<br />')
		EndIf
	Next
	FileWriteLine($Handle, '</span>')
	FileWriteLine($Handle, '</BODY>')
	FileWriteLine($Handle, '</HTML>')
	FileClose($Handle)
	ShellExecute($File)
EndFunc

; ---------------------------------------------------------------------------------------------
; Append and scroll some text
; ---------------------------------------------------------------------------------------------
Func _Check_SetScroll($p_Text, $p_IsChange)
	Local $Num=0
	If $g_Flags[3] = 1 And $p_IsChange = 0 Then Return 0; show changes only if wished
	If $p_IsChange = 1 Then
		If Not ($g_Flags[6] == $g_Flags[8]) Then
			$g_Note&=@CRLF&$g_Flags[6]; modname has not been shown in note-variable
			$g_Flags[8]=$g_Flags[6]
		EndIf
		$g_Note&=@CRLF&$p_Text
	ElseIf	$p_IsChange = 2 Then
		If Not ($g_Flags[6] == $g_Flags[9]) Then
			$g_Error&=@CRLF&$g_Flags[6]; modname has not been shown in error-variable
			$g_Flags[9]=$g_Flags[6]
		EndIf
		$g_Error&=@CRLF&$p_Text
	EndIf
	If Not ($g_Flags[6] == $g_Flags[7]) Then; modname has not been shown in edit-contol
		$p_Text=@CRLF&$g_Flags[6]&@CRLF&$p_Text
		$g_Flags[7]=$g_Flags[6]
		$Num=2
	EndIf
	_GUICtrlEdit_AppendText($g_UI_Interact[1][2], $p_Text & @CRLF)
	_GUICtrlEdit_LineScroll($g_UI_Interact[1][2], 0, 1+$Num)
EndFunc

; ---------------------------------------------------------------------------------------------
; Check if the downloads are still available and/or have changed
; ---------------------------------------------------------------------------------------------
Func _CheckURL($p_Setup, $p_String='', $p_Num=0)
	$Section=IniReadSection($g_MODIni, $p_Setup)
	$g_Flags[6] = _IniRead($Section, 'Name', '')&' ['&$p_Setup&']'
	GUICtrlSetData($g_UI_Static[1][1], $g_Flags[6])
	GUICtrlSetData($g_UI_Interact[1][1], ($p_Num*100)/$g_Setups[0][0])
	For $p=1 to $Prefix[0]
		$Update=0
		$URL=_IniRead($Section, $Prefix[$p]&'Down', '')
		;If Not StringInStr($URL, 'baldursgatemods.com') Then ContinueLoop
		If $URL = '' Or $URL = 'Manual' Then ContinueLoop
		ConsoleWrite($p_Setup&' ['&$Prefix[$p]&'Down]'&@CRLF)
		$File=_IniRead($Section, $Prefix[$p]&'Save', '')
		$Size=_IniRead($Section, $Prefix[$p]&'Size', '')
		$Return=_Net_LinkGetInfo($URL, 1)
		If $Return[0] = 0 Then
			_Check_SetScroll('!Missing: ['&$Prefix[$p]&'Down] unter '& $URL, 2)
			ContinueLoop
		Else
			_Check_SetScroll('+Online: ['&$Prefix[$p]&'Down]', 0)
		EndIf
		If $Return[2] <> 0 Then; don't change the filesize if it is zero
			If $Return[2] <>$Size Then
				ConsoleWrite('>"'&$Size&'"'&@CRLF&'"' & $Return[2]&'"'&@CRLF)
				$Update=1
				If $g_Flags[1] = 1 Then IniWrite($g_MODIni, $p_Setup, $Prefix[$p]&'Size', $Return[2])
				_Check_SetScroll('-Size changed: ['&$Prefix[$p]&'Size] from ' & $Size & ' to ' & $Return[2], 1)
			EndIf
		EndIf
		$Return[1]=StringReplace(StringReplace($Return[1], '%20', ' '), '\', ''); set correct space
		If StringLower($Return[1]) <> StringLower($File) Then; name changed
			ConsoleWrite('>"'&$File&'"'&@CRLF&'"' & $Return[1]&'"'&@CRLF)
			$Update=1
			If $g_Flags[1] = 1 Then IniWrite($g_MODIni, $p_Setup, $Prefix[$p]&'Save', $Return[1])
			_Check_SetScroll('-Name geändert: ['&$Prefix[$p]&'Save] von ' & $File & ' nach ' & $Return[1], 1)
		EndIf
		If $g_Flags[2] = 1 And $Update = 1 Then
			If $Return[1] = '' Then
				_Check_SetScroll('!The name is empty.', 1)
				ContinueLoop
			EndIf	
			If $Return[2] = 0 Then $Return[2]=_IniRead($Section, $Prefix[$p]&'Size', 1)
			If FileExists($g_DownDir & '\' & $Return[1]) Then; remove old files
				If FileGetSize($g_DownDir & '\' & $Return[1]) = $Return[2] Then
					ContinueLoop
				Else
					While 1
						$Test=FileDelete($g_DownDir & '\' & $Return[1])
						If $Test = 0 Then
							$Test=MsgBox(16+5, $g_ProgName&': Delete', 'could '&$g_DownDir & '\' & $Return[1]&' do not remove.', 0, $g_UI[0])
							If $Test = 2  Then Exit
						Else
							ExitLoop
						EndIf
					WEnd
				EndIf
			EndIf
			$PID=Run('"' & $g_ProgDir & '\Tools\wget.exe" --tries=3 --no-check-certificate --continue --progress=dot:binary  --output-file="'&@TempDir&'\'&$Return[1]&'.log" --output-document="' & $g_DownDir & '\' & $Return[1] & '" "' & $URL & '"', @ScriptDir, @SW_HIDE)
			While ProcessExists($PID)
				GUICtrlSetData($g_UI_Interact[1][6], (FileGetSize($g_DownDir & '\' & $Return[1])*100)/$Return[2])
				Sleep(1000)
			WEnd
			GUICtrlSetData($g_UI_Interact[1][6], 0)
			$Log=FileRead(@TempDir&'\'&$Return[1]&'.log')
			If StringInStr($Log, 'saved ['&$Return[2]&'/'&$Return[2]&']') Then
				FileDelete(@TempDir&'\'&$Return[1]&'.log'); all ok
			ElseIf StringRegExp($Log, 'saved\s\x5b\d*\x5d') Then
				If $g_Flags[1] = 1 Then IniWrite($g_ModIni, $p_Setup, $Prefix[$p]&'Size', FileGetSize($g_DownDir & '\' & $Return[1])); save size for later
			Else
				ShellExecute(@TempDir&'\'&$Return[1]&'.log'); show error-log
			EndIf
		EndIf
	Next
EndFunc

; ---------------------------------------------------------------------------------------------
; Convert spaces for HTML
; ---------------------------------------------------------------------------------------------
Func _StringTranslate($p_String)
	Local $Old, $Return
	$Array=StringSplit($p_String, '')
	For $a=1 to $Array[0]
		If $Array[$a]=' ' Then
			If $Old = ' ' Then
				$Return&='&nbsp;'
			Else
				$Return&=' '
				$Old=' '
			EndIf
		Else
			$Return&=$Array[$a]
			$Old=''
		EndIf
	Next
	Return $Return
EndFunc


#cs
DNT0.9.rar
1195373035_rukrakiav0.7.7z
NMT-V2.0.zip
+135 Calling A
#ce

#cs
$Return=_Net_LinkGetInfo('http://gx005d.mofile.com/OTE3MjIzMDI0ODg1NDEwODo0NjcwNTQ2NjAzOTg0Mjk3OkRpc2sxLzczLzczNDMyOTkxNjAvMi8yNDk4MTA5NzI5MDEzNTU6MTo1MTIwMDowOjEyOTM0NDc4NDg0NjE./43447BCB53D12881B55D6F13F4F74C08/DNT0.9.rar')
ConsoleWrite($Return[1] & @CRLF)
$Return=_Net_LinkGetInfo('http://club.paran.com/club/bbsdownload.do?clubno=1130917&menuno=2667641&file_seq=1195373035&file_name=1195373035_rukrakiav0.7.7z&p_eye=club^ccl^cna^clu^htpdown')
ConsoleWrite($Return[1] & @CRLF)
$Return=_Net_LinkGetInfo('http://nmi.forum-free.net/download/file.php?id=22')
ConsoleWrite($Return[1] & @CRLF)
Exit
#ce

#Region URL-check
$Note=''
Dim $Prefix[14] = [13, '', 'Add', 'CH-Add', 'CZ-Add', 'EN-Add', 'FR-Add', 'GE-Add', 'IT-Add', 'JP-Add', 'KO-Add', 'PO-Add', 'RU-Add', 'SP-Add']

#cs
$Test=StringSplit('imoenfriendship', '|')
Auden|BEAR_ANIMATIONS_D2|bgqe|BGT|BWS-Update|BWS-URLUpdate|cliffkey|DNT|Eilistraee|gavin|gavin_bg2|HARPSCOUT|HOUYI|Hubelpot|imoenfriendship|item_rev|iwditempack|JanQuest|Kari|KHALID|level1npcs|LOHMod|ModKitRemover|Nikita|NML|NMR-HAPPY|NMT|NMTP|randomiser|SAGAMAN|SDMODS|SWYLIF|TheUndying|UoT|VolcanicArmoury|Wikaede|WSR|
For $t=1 to $Test[0]
	_CheckURL($Test[$t])
	;_CheckDownload($Test[$t])
Next
ConsoleWrite(@CRLF&@CRLF&$Note)
Exit
#ce

For $s=1 to $g_Setups[0][0]
	;ConsoleWrite($g_Setups[$s][0] & @CRLF)
	;If $g_Setups[$s][0] <> 'alternatives' Then ContinueLoop

	_CheckURL($g_Setups[$s][0], $g_Setups[$s][1], $s)
Next
ConsoleWrite(@CRLF&@CRLF&$Note)
Exit


Exit
#EndRegion URL-check

; ---------------------------------------------------------------------------------------------
; If you place Au3Exit=X in the Order-section, the setup will close at this point. If X=0, the setup will ask you to start with the next key of the "current-package"-section.
; Usefull if you want to do some things manually, test things until a certain point...
; ---------------------------------------------------------------------------------------------
Func Au3Exit($p_Num = 0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling Au3Exit')
	DllClose($g_UDll); close the dll for detecting "space"-keypresses
	If $g_STDStream <> '' Then; close the backend-cmd-instance
		StdinWrite($g_STDStream, 'exit' & @CRLF)
		StdinWrite($g_STDStream, @CRLF)
	EndIf
	Exit
EndFunc    ;==>Au3Exit

; ---------------------------------------------------------------------------------------------
; Get the core-settings for the current installation
; ---------------------------------------------------------------------------------------------
Func Au3GetVal($p_Num = 0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling Au3GetVal')
	$g_Order = IniReadSection($g_BWSIni, 'Order'); reload this to get the new selected functions
	$ReadSection = IniReadSection($g_UsrIni, 'Options')
	$g_Flags[14]=_IniRead($ReadSection, 'AppType', ''); need correct gametype
	If StringRegExp($g_Flags[14], 'EET') Then
		$g_GConfDir = $g_ProgDir & '\Config\EET'
		_Test_GetGamePath('BGEE')
		_Test_GetGamePath('BG2EE')
		$g_GameDir = $g_BG2Dir
	ElseIf StringRegExp($g_Flags[14], 'BWS|BWP') Then
		$g_GConfDir = $g_ProgDir & '\Config\BWP'
		_Test_GetGamePath('BG1')
		_Test_GetGamePath('BG2')
		$g_GameDir = $g_BG2Dir
	Else
		$g_GConfDir = $g_ProgDir & '\Config\'&$g_Flags[14]
		_Test_GetGamePath($g_Flags[14])
		$g_GameDir = Eval('g_'&$g_Flags[14]&'Dir')
	EndIf
	$g_ModIni = $g_GConfDir & '\Mod.ini'
	$g_Setups=_CreateList('s')
	$g_DownDir = _IniRead($ReadSection, 'Download', '')
	$g_GUIFold = _IniRead($ReadSection, 'UnFold', '1')
	$g_Flags[18] = _IniRead($ReadSection, 'Beep', 0)
	$g_CurrentPackages = IniReadSection($g_UsrIni, 'Current')
	AutoItSetOption('GUIOnEventMode', 1)
	If IniRead($g_BWSIni, 'Order', 'Au3Select', 1) = 0 And GUICtrlRead($g_UI_Button[0][1]) = '' Then; this is a restart > show the question-dialog
		_Misc_SetLang()
		GUICtrlSetState($g_UI_Seperate[8][0], $GUI_SHOW)
		For $o = 1 To $g_Order[0][0]
			If $g_Order[$o][1] = '0' Then ContinueLoop
			If StringRegExp('Au3BuildGui,Au3Detect,Au3GetVal,Au3ResetEdit', '(\A|\x2c)'&$g_Order[$o][0]&'(\z|\x2c)') Then ContinueLoop
			$Nextstep=$g_Order[$o][0]
			ExitLoop
		Next
		If StringRegExp($g_FItem, '\A\d{1,}\z') Then
			$Array = StringSplit(StringStripCR(FileRead($g_GConfDir&'\Select.txt')), @LF)
			If _IniRead($ReadSection, 'GroupInstall', 0) =  1 Then $Array = _Install_ModifyForGroupInstall($Array); always install in groups
			$a=$g_FItem
			While StringRegExp($Array[$a], '(?i)\A(CMD|ANN|DWN|GRP)') And $a<$Array[0]
				$a+=1
			WEnd
			$Split=StringSplit($Array[$a], ';')
			$Name=$Split[2]
			$Name=IniRead($g_MODIni, $Name, 'Name', $Name); SetupName
			$Comp=$Split[3]; CompNumber
			$Answer = _Misc_MsgGUI(2, $g_ProgName, StringFormat(_GetTR($g_UI_Message, '0-L4'), $Nextstep, $Name&', #'&$Comp), 2, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2')); => continue installation?
		Else
			$Name=IniRead($g_MODIni, $g_FItem, 'Name', $g_FItem); SetupName
			$Answer = _Misc_MsgGUI(2, $g_ProgName, StringFormat(_GetTR($g_UI_Message, '0-L4'), $Nextstep, $Name), 2, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2')); => continue installation?
		EndIf
		If $Answer = 2 Then;Continue
			_Misc_SetLang()
			_Tree_Populate(0)
			_Tree_Reload(0)
			If $Nextstep <> 'Au3Net' Then _Process_Gui_Create(2)
			GUICtrlSetState($g_UI_Button[0][1], $GUI_DISABLE)
			GUICtrlSetState($g_UI_Button[0][2], $GUI_DISABLE)
		ElseIf $Answer = 1 Then ; No
			$g_FItem = 1
			IniDelete($g_BWSIni, 'Faults'); remove old errors
			_ResetInstall()
			$g_Order = IniReadSection($g_BWSIni, 'Order'); Reread to be aware of the changes
			$g_CurrentOrder = 2
			GUICtrlSetState($g_UI_Seperate[2][0], $GUI_SHOW); show the fileselection-dialog
			AutoItSetOption('GUIOnEventMode', 0)
		EndIf
	Else
		GUICtrlSetState($g_UI_Button[0][1], $GUI_DISABLE)
		GUICtrlSetState($g_UI_Button[0][2], $GUI_DISABLE)
	EndIf
EndFunc   ;==>Au3GetVal

; ---------------------------------------------------------------------------------------------
; Generate the current list of exe's in the section-list
; ---------------------------------------------------------------------------------------------
Func _CreateList($p_Num='s'); $a=Type ('s' = setup, 'c' = chapters)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _CreateList')
	If $p_Num='c' Then; chapters
; ---------------------------------------------------------------------------------------------
; Create an index of first characters and assign the number to begin with
; ---------------------------------------------------------------------------------------------
		If Not IsArray($g_Setups) Then $g_Setups=_CreateList()
		Local $Index[100][2]
		For $s = 1 To $g_Setups[0][0]
			$Test=StringLeft($g_Setups[$s][0], 1)
			If $Index[0][1] <> $Test Then
				$Index[0][0]+=1
				$Index[0][1]=$Test
				$Index[$Index[0][0]][0] = Asc(StringLower($Test))
				$Index[$Index[0][0]][1] = $s
			EndIf
		Next
; ---------------------------------------------------------------------------------------------
; loop through select.txt-array and if new setup is used...
; ---------------------------------------------------------------------------------------------
		Local $Setups[1000][3], $OldSetup
		Local $Array=StringSplit(StringStripCR(FileRead($g_GConfDir&'\Select.txt')), @LF)
		For $a=1 to $Array[0]
			If StringRegExp($Array[$a], '(?i)\A(CMD|ANN|GRP)') Then ContinueLoop
			$Split=StringSplit($Array[$a], ';')
			$Test=$Split[2]; setup
			If $Test <> $OldSetup Then
				$Setups[0][0]+=1
				$Setups[$Setups[0][0]][1]=$Test; setup
; ---------------------------------------------------------------------------------------------
; ...use the index to start at a smart index-number
; ---------------------------------------------------------------------------------------------
				$Num=Asc(StringLower(StringLeft($Test, 1))); asc-number for the character
				For $i=1 to $Index[0][0]
					If $Num = $Index[$i][0] Then
						ExitLoop
					ElseIf $Num < $Index[$i][0]Then
						$i-=1
						ExitLoop
					EndIf
				Next
				For $g = $Index[$i][1] To $g_Setups[0][0]; start searching from assigned index-number
					If $g_Setups[$g][0] = $Test Then
						$Setups[$Setups[0][0]][2]=$g_Setups[$g][1]
						ExitLoop
					EndIf
				Next
				If $Setups[$Setups[0][0]][2] = '' Then ConsoleWrite('!'&$Test&': Missing Name in Mod.ini' & @CRLF)
				$OldSetup = $Test
			Else
				ContinueLoop
			EndIf
		Next
	Else; Search for mods and their names (with a fallback-version)
		$SectionNames=IniReadSectionNames($g_ModIni)
		Local $Setups[$SectionNames[0]+1][3]
		$Setups[0][0] = $SectionNames[0]
		$File=FileRead($g_ModIni)
		$Array=StringRegExp($File, '(?i)\nName=.*\n', 3)
		If UBound($Array) = $SectionNames[0] Then
			for $a=0 to UBound($Array)-1
				$Setups[$a+1][0] = $SectionNames[$a+1]
				$Setups[$a+1][1] = StringStripWS(StringTrimRight(StringTrimLeft($Array[$a], 6), 2), 2)
			Next
		Else
			ConsoleWrite('!Missing Name-definition in Mod.ini'  & @CRLF)
			$Array=StringSplit(StringStripCR($File), @LF)
			For $a=1 to $Array[0]
				If StringLeft($Array[$a], 1) = '[' Then
					$Setups[0][0] = $Setups[0][0] + 1
					$Setups[$Setups[0][0]][0] = $SectionNames[$Setups[0][0]]
					For $a=$a to $Array[0]
						If StringLeft($Array[$a], 5) = 'Name=' Then
							$Setups[$Setups[0][0]][1] = StringStripWS(StringTrimLeft($Array[$a], 5), 2)
							ExitLoop
						EndIf
					Next
				EndIf
			Next
		EndIf
	EndIf
	ReDim $Setups[$Setups[0][0] + 1][3]
	If $p_Num = 's' Then _ArraySort($Setups, 0, 1)
	Return $Setups
EndFunc   ;==>_CreateList

; ---------------------------------------------------------------------------------------------
; Well, print a debug message. :D
; ---------------------------------------------------------------------------------------------
Func _PrintDebug($p_String, $p_Show = 0)
	ConsoleWrite($p_String & @CR)
	If $p_Show = 1 Then MsgBox(64, $g_ProgName, $p_String)
EndFunc   ;==>_PrintDebug

; ---------------------------------------------------------------------------------------------
; Set all values to start a new install
; ---------------------------------------------------------------------------------------------
Func _ResetInstall($p_DeletePause=1)
	IniWrite($g_BWSIni, 'Order', 'Au3Select', '1'); Enable the start of the selection-gui
	IniWrite($g_BWSIni, 'Order', 'Au3PrepInst', '1'); remove cds
	IniWrite($g_BWSIni, 'Order', 'Au3CleanInst', '1'); backup
	IniWrite($g_BWSIni, 'Order', 'Au3Net', '1'); download
	IniWrite($g_BWSIni, 'Order', 'Au3NetFix', '1'); post-download-processess
	IniWrite($g_BWSIni, 'Order', 'Au3NetTest', '1'); download test
	IniWrite($g_BWSIni, 'Order', 'Au3Extract', '1'); extract
	IniWrite($g_BWSIni, 'Order', 'Au3ExFix', '1'); extract
	IniWrite($g_BWSIni, 'Order', 'Au3ExTest', '1'); extract test
	IniWrite($g_BWSIni, 'Order', 'Au3RunFix', '1'); fixes and patches
	IniWrite($g_BWSIni, 'Order', 'Au3Install', '1'); install
	IniWrite($g_BWSIni, 'Options', 'Start', '1')
	FileMove($g_LogDir & '\*.txt', $g_LogDir & '\Bak\', 9); save old logs
	If DirGetSize($g_LogDir & '\Bak') > 0 Then
		DirMove($g_LogDir & '\Bak', $g_LogDir & '\Bak-'& @YEAR & @MON & @MDAY & @HOUR & @MIN)
	Else
		DirRemove($g_LogDir & '\Bak')
	EndIf
	IniDelete($g_UsrIni, 'RemovedFromCurrent'); delete old failures-mesages
	If $p_DeletePause = 1 Then IniDelete($g_UsrIni, 'Pause'); delete old pauses
EndFunc   ;==>_ResetInstall