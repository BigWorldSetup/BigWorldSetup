#include-once

; ---------------------------------------------------------------------------------------------
; Change the dir in the cmd-session to the desired directory and return if it worked
; ---------------------------------------------------------------------------------------------
Func _Process_ChangeDir($p_Dir, $p_Exit=0)
	Local $p_Answer[1]=[0]
	$g_ConsoleOutput = StringReplace($g_ConsoleOutput, 'cd /D', 'cd  /D') & @CRLF
	StdinWrite($g_STDStream, 'cd /D "'&_StringVerifyAscII($p_Dir)&'"' & @CRLF)
	While 1
		_Process_Read($p_Answer)
		If StringRegExp($g_ConsoleOutput, '(?i)cd /D ".*"(\r\n){1,3}[[:alpha:]]') Then ExitLoop; wait for change to take effect
	WEnd
	$Test=StringRegExp($g_ConsoleOutput, '.*\z', 3)
	If $Test[0] = StringRegExpReplace($p_Dir, '\x5c{1,}\z', '')&'>' Then Return 1
	If $Test[0] = StringRegExpReplace(_StringVerifyAscII($p_Dir), '\x5c{1,}\z', '')&'>' Then Return 1
	If $p_Exit = 1 Then
		_Process_SetConsoleLog(StringFormat(_GetTR($g_UI_Message, '6-L5'), $p_Dir)); => cannot change path > exit
		_Process_Gui_Delete(6, 6, 1); Delete the window
		Exit
	EndIf
	Return 0
EndFunc   ;==>_Process_ChangeDir

; ---------------------------------------------------------------------------------------------
; Only enable the button to go back, no others
; ---------------------------------------------------------------------------------------------
Func _Process_EnableBackButtonOnly()
	GUICtrlSetState($g_UI_Button[0][1], $GUI_DISABLE)
	GUICtrlSetState($g_UI_Button[0][2], $GUI_DISABLE)
	GUICtrlSetState($g_UI_Button[0][3], $GUI_ENABLE)
EndFunc   ;==>_Process_EnableBackButtonOnly

; ---------------------------------------------------------------------------------------------
; Sets defaults to use the pause/resume-buttons
; ---------------------------------------------------------------------------------------------
Func _Process_EnablePause($p_Enable=1)
	$g_Flags[5] = 1; enable pause
	$g_Flags[11] = 0
	$g_Flags[12] = 0; restet pause/resume-button
	GUICtrlSetData($g_UI_Button[0][1], _GetTR($g_UI_Message, '0-B4')); => pause
	GUICtrlSetData($g_UI_Button[0][2], _GetTR($g_UI_Message, '0-B5')); => resume
	If $p_Enable = 1 Then
		GUICtrlSetState($g_UI_Button[0][1], $GUI_ENABLE); enable pause
	Else
		GUICtrlSetState($g_UI_Button[0][1], $GUI_DISABLE); disable pause
	EndIf
	GUICtrlSetState($g_UI_Button[0][2], $GUI_DISABLE); disable resume
EndFunc   ;==>_Process_EnablePause

; ---------------------------------------------------------------------------------------------
; Create a small gui that will be used to monitor the progess
; ---------------------------------------------------------------------------------------------
Func _Process_Gui_Create($p_Scroll = 0, $p_Pause=1)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Process_Gui_Create')
	If $p_Scroll = 2 Then
		$Error=_Test_CheckRequiredFiles(); do filecheck if we do restarts
		If $Error>0 Then Exit
	EndIf
	_Process_SwitchEdit($p_Scroll, $p_Pause)
	GUICtrlSetState($g_UI_Button[6][1], $GUI_ENABLE)
	GUICtrlSetState($g_UI_Interact[6][5], $GUI_ENABLE)
	If $p_Scroll = 0 Then; Do this so the updates don't crash if no bg2-path was selected until now or it is wrong
		$Dir = $g_GameDir
	Else
		$Dir = @ScriptDir
	EndIf
	_Process_StartCmd($Dir)
	_Misc_SetTab(6)
	$g_Flags[0] = 1
	GUICtrlSetState($g_UI_Button[6][1], $GUI_DEFBUTTON)
	AutoItSetOption('GUIOnEventMode', 1)
EndFunc   ;==>_Process_Gui_Create

; ---------------------------------------------------------------------------------------------
; Switch the gui buttons are pressed
; ---------------------------------------------------------------------------------------------
Func _Process_Gui_Delete($p_Tab1, $p_Tab2, $p_Pause=1); go back to the tab where we left before
	If $g_Flags[13] = 1 Then Exit
	If $p_Pause = 0 Then $g_Flags[0]=0
	$EventMode=AutoItSetOption('GUIOnEventMode')
	If Not $EventMode Then AutoItSetOption('GUIOnEventMode', 1)
	If $g_Flags[0] = 1 Then
		While $g_Flags[11] = 0 And $g_Flags[12] = 0 And $g_Flags[13] = 0
			Sleep(10)
		WEnd
	EndIf
	If $g_Flags[0] = 0 Then $g_Flags[11] = 1
	If $g_Flags[13] = 1 Then Exit
	If $g_Flags[11] = 1 Then $Switch = $p_Tab1
	If $g_Flags[12] = 1 Then $Switch = $p_Tab2
	$g_Flags[11]=0
	$g_Flags[12]=0
	_Misc_SetTab($Switch)
	If $Switch <> 6 Then AutoItSetOption('GUIOnEventMode', 0)
	If $Switch = $p_Tab1 Then Return 0
	If $Switch = $p_Tab2 Then Return 1
EndFunc   ;==>_Process_Gui_Delete

; ---------------------------------------------------------------------------------------------
; Delete the gui after the close-button is pressed
; ---------------------------------------------------------------------------------------------
Func _Process_Gui_Exit($p_Exit=1)
	$g_Flags[13] = 0
	GUICtrlSetState($g_UI_Button[0][1], $GUI_DISABLE)
	GUICtrlSetState($g_UI_Button[0][2], $GUI_DISABLE)
	While $g_Flags[13] = 0
		Sleep(10)
	WEnd
	If $p_Exit = 1 Then Exit
EndFunc    ;==>_Process_Gui_Exit

; ---------------------------------------------------------------------------------------------
; OnEvent actions for the gui
; ---------------------------------------------------------------------------------------------
Func _Process_OnEvent()
	Switch @GUI_CtrlId
		Case $g_UI_Button[0][1]
			$g_Flags[11]=1
			If $g_Flags[5] = 1 Then
				$g_Flags[12]=0
				$Current = GUICtrlRead($g_UI_Seperate[0][0])+1
				$g_Flags[6]=GUICtrlRead($g_UI_Static[$Current][1])
				GUICtrlSetData($g_UI_Static[$Current][1], _GetTR($g_UI_Message, '0-L1')); => wait til action is finished
				GUICtrlSetState($g_UI_Button[0][1], $GUI_DISABLE); disable pause
				GUICtrlSetState($g_UI_Button[0][2], $GUI_ENABLE); enable resume
			EndIf
		Case $g_UI_Button[0][2]
			$g_Flags[12]=1
			If $g_Flags[5] = 1 Then
				$g_Flags[11]=0
				$Current = GUICtrlRead($g_UI_Seperate[0][0])+1
				GUICtrlSetData($g_UI_Static[$Current][1], $g_Flags[6]); reset old description
				GUICtrlSetState($g_UI_Button[0][1], $GUI_ENABLE); enable pause
				GUICtrlSetState($g_UI_Button[0][2], $GUI_DISABLE); disable resume
			EndIf
		Case $g_UI_Button[0][3]
			$g_Flags[13]=1
			$g_Flags[0]=0
			$Current = GUICtrlRead($g_UI_Seperate[0][0])+1
			GUICtrlSetData($g_UI_Static[$Current][1], _GetTR($g_UI_Message, '0-L1')); => wait til action is finished
			GUICtrlSetState($g_UI_Static[$Current][1], $GUI_HIDE)
			Sleep(1000)
			GUICtrlSetState($g_UI_Static[$Current][1], $GUI_SHOW)
			GUICtrlSetState($g_UI_Button[0][3], $GUI_Disable)
; ---------------------------------------------------------------------------------------------
#Region Console
		Case $g_UI_Button[6][1]; send input
			If $g_pQuestion = 'Need4Answer' Then
				$g_pQuestion = GUICtrlRead($g_UI_Interact[6][5])
			Else
				StdinWrite($g_STDStream, GUICtrlRead($g_UI_Interact[6][5]) & @CRLF)
				If @error = -1 Then ConsoleWrite('!Error'&@CRLF)  ; _Process_SetConsoleLog(_GetTR($g_UI_Message, '6-L1')); => text could not be piped to process
			EndIf
		Case $g_UI_Button[6][2]; open debug
			ShellExecute($g_LogFile)
#EndRegion Console
		Case $g_UI_Button[6][3]; resize
			_Selection_SetSize()
	EndSwitch
	For $i=1 to 10
		If @GUI_CtrlId = $g_UI_Button[5][$i] Then $g_Flags[23]=$i
	Next
	For $i=1 to 5
		If @GUI_CtrlId = $g_UI_Static[5][$i+2] Then $g_Flags[23]=-$i
	Next
EndFunc   ;==>_Process_OnEvent

; ---------------------------------------------------------------------------------------------
; Pause the process until continue is pressed
; ---------------------------------------------------------------------------------------------
Func _Process_Pause($p_Setup='')
	If $p_Setup <> '' Then GUICtrlSetData($g_UI_Static[6][2], $p_Setup); show setup that is paused
	If $g_Flags[11] = 0 Then; if this is planed, the buttons have to be set
		GUICtrlSetState($g_UI_Button[0][1], $GUI_DISABLE); disable pause
		GUICtrlSetState($g_UI_Button[0][2], $GUI_ENABLE); enable resume
	EndIf
	$g_Flags[11] = 0
	$g_Flags[12] = 0
	GUICtrlSetData($g_UI_Static[6][1], _GetTR($g_UI_Message, '0-B4')); => pause
	_Process_SetConsoleLog(@CRLF&'##### ' & _GetTR($g_UI_Message, '0-B4') &' #####'); => pause
	While $g_Flags[12] = 0
		If $g_Flags[0] = 0 Then Exit
		Sleep(10)
	WEnd
	GUICtrlSetData($g_UI_Static[6][1], $g_Flags[6]); reset old description
	GUICtrlSetState($g_UI_Button[0][1], $GUI_ENABLE); enable pause
	GUICtrlSetState($g_UI_Button[0][2], $GUI_DISABLE); disable resume
EndFunc   ;==>_Process_Pause

; ---------------------------------------------------------------------------------------------
; Wait until $g_pQuestion matches Regexp $p_String. If not, dispay $p_Text
; ---------------------------------------------------------------------------------------------
Func _Process_Question($p_String, $p_Text, $p_Translation, $p_Close=-1, $p_Ring=0)
	$localString=$p_Translation&StringTrimLeft($p_String, StringLen($p_Translation))
	$State = GUICtrlGetState($g_UI_Interact[6][2])
	If BitAND($State, $GUI_SHOW) Then
		_Process_SetScrollLog($p_Text, 1, 0)
	Else
		_Process_SetConsoleLog($p_Text, 0)
	EndIf
	GUICtrlSetState($g_UI_Interact[6][5], $GUI_FOCUS); focus and highlight input
	GUICtrlSetBkColor($g_UI_Interact[6][5], 0x000070)
	Sleep(500)
	GUICtrlSetBkColor($g_UI_Interact[6][5], 0xffffff)
	$g_pQuestion = 'Need4Answer'
	While 1
		AutoItSetOption("GUIOnEventMode", 0)
		While $g_pQuestion = 'Need4Answer'
			If $p_Ring>0 Then; If wanted, make a sound to signalize pauses
				$p_Ring+=1
				If $p_Ring >= 500 Then
					SoundPlay(@WindowsDir&'\Media\ringin.wav', 1)
					$p_Ring = 1
				EndIf
			EndIf
			$msg = GUIGetMsg()
			; If Not StringRegExp($msg, '\A(0|-11|-8|-7)\z') Then ConsoleWrite($msg & @CRLF)
			If $msg = $g_UI_Button[0][3] And $p_Close<>-1 Then
				$g_pQuestion=StringSplit($p_Translation, '|')
				If $g_pQuestion[0] >= $p_Close Then
					$g_pQuestion=$g_pQuestion[$p_Close]
				Else
					$g_pQuestion = 'Need4Answer'
				EndIf
			EndIf
			If $msg = $g_UI_Button[6][1] Then $g_pQuestion=GUICtrlRead($g_UI_Interact[6][5])
			If $msg = $g_UI_Button[6][2] Then ShellExecute($g_LogFile)
			Sleep(10)
		WEnd
		AutoItSetOption("GUIOnEventMode", 1)
		If StringRegExp($g_pQuestion, '(?i)\A'&$localString&'\z') Then; String matches regexp = valid answer
			$g_pQuestion=StringLower($g_pQuestion)
			ExitLoop
		Else
			If BitAND($State, $GUI_SHOW) Then
				_Process_SetScrollLog($p_Text, 1, 0)
			Else
				_Process_SetConsoleLog($p_Text, 0)
			EndIf
			$g_pQuestion = 'Need4Answer'
		EndIf
	WEnd
	If StringLen($g_pQuestion) = 1 Then
		$Ascii=Asc($g_pQuestion)
		If StringLen($g_pQuestion) = 1 Then $g_pQuestion = StringMid($p_String, StringInStr($p_Translation, $g_pQuestion), 1)
	EndIf
	FileWrite($g_LogFile, '['&$g_pQuestion&']'&@CRLF)
EndFunc   ;==>_Process_Question

; ---------------------------------------------------------------------------------------------
; [Scs] Write captured input into the logfile and update the edit-control
; ---------------------------------------------------------------------------------------------
Func _Process_Read(ByRef $p_Answer); $p_Answer=Array with questions from weidu/batches and selected answers
	Local $LastLine='', $FilteredLines
	$line = StdoutRead($g_STDStream); capture while getting stream
	If @error Then Return
	If $line Then
		$Line=_StringVerifyExtAscII($Line)
		FileWrite($g_LogFile, $line); write the log
		$g_ConsoleOutput = $g_ConsoleOutput & $line; append the new text
		$LastIsLF=StringRegExp($line, '\s\z')
		$OutputArray = StringSplit(StringStripCR($g_ConsoleOutput), @LF)
		$g_ConsoleOutput=''
		For $o = $OutputArray[0] To 1 Step -1
			If StringRegExp($OutputArray[$o], '(?i)\sTime\s\x3d\s|Tiles processed|% decoded|%]|\A(Tile|Pos:|\s?Oggdec|\sEncoder|\sSerial|\sBitstream|\sScale|\sDecoded|\sEncoded)\s') Then ContinueLoop; cmd itself
			If $LastLine = '' And $OutputArray[$o] = '' Then ContinueLoop
			$FilteredLines+=1
			$LastLine=$OutputArray[$o]
			$g_ConsoleOutput=$OutputArray[$o]&@CRLF&$g_ConsoleOutput
			If $FilteredLines=15 Then ExitLoop
			If $LastIsLF = 0 Then $g_ConsoleOutput=StringRegExpReplace($g_ConsoleOutput, '\s\z', '')
		Next
		ControlSetText($g_UI[0], '', $g_UI_Interact[6][3], $g_ConsoleOutput); set the text
	ElseIf $p_Answer[0] <> 0 Then
		;ConsoleWrite('Test:' & $p_Answer[1] & @CRLF)
		$Lines = StringSplit(StringStripCR($g_ConsoleOutput), @LF)
		For $t = 1 To $Lines[0]
			If StringInStr($Lines[$t], $p_Answer[1]) Then
				StdinWrite($g_STDStream, $p_Answer[2] & @CRLF)
				If @error = -1 Then
					_Process_SetConsoleLog(_GetTR($g_UI_Message, '6-L1')); => text could not be piped to process
				Else
					_ArrayDelete($p_Answer, 1)
					_ArrayDelete($p_Answer, 1)
					$p_Answer[0] -= 1
				EndIf
				ExitLoop
			EndIf
		Next
	EndIf
EndFunc   ;==>_Process_Read

; ---------------------------------------------------------------------------------------------
; Run a process and monitor the console that it's running in
; ---------------------------------------------------------------------------------------------
Func _Process_Run($p_String, $p_File, $p_Answer = ''); $p_String=complete call, $p_File=process or filename; $p_Answer=array with questions and answers
	If $p_Answer = '' Then Dim $p_Answer[1]=[0]
	;_PrintDebug('+' & @ScriptLineNumber & ' Calling _Process_Run')
	If Not ProcessExists($g_STDStream) Then
		FileWrite($g_LogFile, @CRLF&'Process-Error: STDStream does not exist.'&@CRLF)
		$g_Flags[19]=0; enable to start a new process
		_Process_StartCmd(); launch
	EndIf
	; remove old task-done marker file if not an exe
	If StringRight($p_File, 3) <> 'exe' Then
		If FileExists($g_GameDir & '\' & $p_File) Then
			$Success = FileDelete($g_GameDir & '\' & $p_File)
			If $Success = 0 Then FileWriteLine($g_LogFile, 'Process-Error: Could not delete file '& $p_File)
		EndIf
	EndIf
	$PIDExist = 0
	$g_ConsoleOutput = $g_ConsoleOutput & @CRLF
	StdinWrite($g_STDStream, $p_String & @CRLF); write the command into the console
	If Not @error Then; the command was sent to the console successfully
		If StringRight($p_File, 3) = 'exe' Then; it's an executable
			$PIDExist = ProcessWait($p_File, 5); wait until the process starts
			If $PIDExist = 0 Then; create an error message
				_Process_SetConsoleLog(@CRLF & _GetTR($g_UI_Message, '6-L2') & @CRLF & $p_String & '.' & @CRLF & _GetTR($g_UI_Message, '6-L3') & @CRLF); => process could not be started for unknown reasons
				FileWrite($g_LogFile, 'ProcessWait-Error: '&$p_File& @CRLF)
				GUICtrlSetColor($g_UI_Interact[6][3], 0xff0000); paint the item red
				Sleep(1000)
				GUICtrlSetColor($g_UI_Interact[6][3], 0x000000); paint the item black again
				Return 0
			Else; go on
				While ProcessExists($p_File)
					_Process_Read($p_Answer)
					Sleep(750)
				WEnd
				_Process_Read($p_Answer); get the last messages
				Return 1
			EndIf
		Else; it's a batch, so just go ahead
			While Not FileExists($g_GameDir & '\' & $p_File); loop til the file appears
				_Process_Read($p_Answer)
				Sleep(750)
			WEnd
			_Process_Read($p_Answer); get the last messages
			Return 1
		EndIf
	Else
		_Process_SetConsoleLog(@CRLF & _GetTR($g_UI_Message, '6-L2') & @CRLF & $p_String & '.' & @CRLF & _GetTR($g_UI_Message, '6-L3') & @CRLF); => process could not be started for unknown reasons
		FileWrite($g_LogFile, 'STDInWrite-Error: '&ProcessExists($g_STDStream) &  @CRLF)
		GUICtrlSetColor($g_UI_Interact[6][3], 0xff0000); paint the item red
		Sleep(1000)
		GUICtrlSetColor($g_UI_Interact[6][3], 0x000000); paint the item black again
		Return 0
	EndIf
EndFunc   ;==>_Process_Run

; ---------------------------------------------------------------------------------------------
; [ScS] Updated edit-control
; ---------------------------------------------------------------------------------------------
Func _Process_SetConsole($p_Text, $p_Length=0); $p_Length will auto-resize the text
	If $p_Length <> 0 Then
		$String = __StringSplit_ByLength($p_Text, $p_Length, $g_UI_Interact[6][3])
		$p_Text = $String[0]
	EndIf
	$g_ConsoleOutput = $g_ConsoleOutput & @CRLF & $p_Text
	$g_ConsoleOutput = StringRight($g_ConsoleOutput, StringLen($g_ConsoleOutput) - StringInStr($g_ConsoleOutput, @LF, 0, -24))
	ControlSetText($g_UI[0], '', $g_UI_Interact[6][3], $g_ConsoleOutput)
EndFunc   ;==>_Process_SetConsole

; ---------------------------------------------------------------------------------------------
; [ScS] Append text to non-scrollable edit-control and log
; ---------------------------------------------------------------------------------------------
Func _Process_SetConsoleLog($p_Text, $p_Length=0); $p_Length will auto-resize the text
	$p_Text = StringRegExpReplace($p_Text, '\r\n|\x7c|\r\|\n', @CRLF)
	_Process_SetConsole($p_Text, $p_Length)
	FileWrite($g_LogFile, $p_Text & @CRLF)
EndFunc   ;==>_Process_SetConsoleLog

; ---------------------------------------------------------------------------------------------
; [ScS] Append text to edit-control and log
; ---------------------------------------------------------------------------------------------
Func _Process_SetScrollLog($p_Text, $p_Write = 1, $p_Length=0); $p_Length will auto-resize the text
	If $p_Length <> 0 Then
		$String = __StringSplit_ByLength($p_Text, $p_Length, $g_UI_Interact[6][2])
		$p_Text = $String[0]
	EndIf
	$p_Text = StringRegExpReplace($p_Text, '\r\n|\x7c|\r\|\n', @CRLF)
	$Num = @extended
	_GUICtrlEdit_AppendText($g_UI_Interact[6][2], $p_Text & @CRLF)
	_GUICtrlEdit_LineScroll($g_UI_Interact[6][2], 0, 1 + $Num)
	If $p_Write = 1 Then FileWrite($g_LogFile, $p_Text & @CRLF)
EndFunc   ;==>_Process_SetScrollLog

; ---------------------------------------------------------------------------------------------
; Switch help on / off on output tab
; ---------------------------------------------------------------------------------------------
Func _Process_SetSize($p_State='')
	If Not IsDeclared('p_State') Then $p_State=''
	$Pos=ControlGetPos($g_UI[0], '', $g_UI_Interact[6][2])
	$State=GUICtrlGetState($g_UI_Interact[6][4])
	If BitAND($State, $GUI_HIDE) Or $p_State = 1 Then
		GUICtrlSetPos($g_UI_Interact[6][2], 15, 145, $Pos[2]-305, $Pos[3])
		GUICtrlSetPos($g_UI_Interact[6][3], 15, 145, $Pos[2]-305, $Pos[3])
		GUICtrlSetPos($g_UI_Button[6][3], $Pos[2]-290, 145, 15, $Pos[3])
		GUICtrlSetState($g_UI_Interact[6][4], $GUI_SHOW)
		GUICtrlSetData($g_UI_Button[6][3], '>')
	Else
		GUICtrlSetPos($g_UI_Interact[6][2], 15, 145, $Pos[2]+305, $Pos[3])
		GUICtrlSetPos($g_UI_Interact[6][3], 15, 145, $Pos[2]+305, $Pos[3])
		GUICtrlSetPos($g_UI_Button[6][3], $Pos[2]+320, 145, 15, $Pos[3])
		GUICtrlSetState($g_UI_Interact[6][4], $GUI_HIDE)
		GUICtrlSetData($g_UI_Button[6][3], '<')
	EndIf
EndFunc    ;==>_Process_SetSize

; ---------------------------------------------------------------------------------------------
; Start the background-console
; ---------------------------------------------------------------------------------------------
Func _Process_StartCmd($p_Dir = @ScriptDir)
	If $g_Flags[19] = 1 Then Return
	$g_STDStream = Run(@ComSpec & ' /k', $p_Dir, @SW_HIDE, 9); run hidden with stderr-mergedread and stdinwrite
	If @error Then
		_Misc_MsgGUI(4, _GetTR($g_UI_Message, '0-T1'), _GetTR($g_UI_Message, '6-L4')); => unable to connect to cmds stdin/stdout
		Exit
	EndIf
	$g_Flags[19] = 1
EndFunc    ;==>_Process_StartCmd

; ---------------------------------------------------------------------------------------------
; Just show the (not) scrollable editcontrol
; ---------------------------------------------------------------------------------------------
Func _Process_SwitchEdit($p_Scroll = 0, $p_Pause=1)
	_Process_EnablePause($p_Pause)
	If $p_Scroll = 1 Then; scrollable output
		GUICtrlSetData($g_UI_Interact[6][2], '')
		GUICtrlSetState($g_UI_Interact[6][2], $GUI_SHOW)
		GUICtrlSetState($g_UI_Interact[6][3], $GUI_HIDE)
	Else; fixed output
		GUICtrlSetData($g_UI_Interact[6][3], '')
		GUICtrlSetState($g_UI_Interact[6][3], $GUI_SHOW)
		GUICtrlSetState($g_UI_Interact[6][2], $GUI_HIDE)
	EndIf
EndFunc    ;==>_Process_SwitchEdit
