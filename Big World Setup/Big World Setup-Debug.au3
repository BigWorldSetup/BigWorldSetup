AutoItSetOption('TrayIconHide', 1)

Global $g_TraceFile=@ScriptDir&'\Logs\BWS_Trace.txt', $g_DebugFile = @ScriptDir & '\Logs\BWS_Debug.txt'

; =========================  Start the script with debugging-support =========================
If $CmdLine[0] = 1 Then
	FileDelete($g_TraceFile)
	FileDelete($g_DebugFile)
	Trace()
	Run(@ComSpec & ' /c AutoIt3.exe /ErrorStdOut Traced.au3 | AutoIt3.exe "BiG World Setup-Debug.au3"', @ScriptDir, @SW_HIDE)
	Exit
EndIf

; =========================  Test if the program crashed and report  =========================
$IsCrashed = Observe()
If $IsCrashed = 1 Then
	If @extended = 0 Or FileExists ($g_DebugFile) Then
		If FileExists($g_DebugFile) Then 
			$Handle=FileOpen($g_TraceFile, 1)
			FileWrite($Handle, @CRLF&'----------'&@CRLF&'Variables:'&@CRLF&'----------'&@CRLF&FileRead($g_DebugFile))
			FileClose($Handle)
		EndIf
		MsgBox(48, 'BiG World Setup - '&_GetSTR('T1'), _GetSTR('L1'))
		ShellExecute($g_TraceFile)
		Exit
	EndIf	
	$Answer=MsgBox(3+32, 'BiG World Setup - '&_GetSTR('T1'), _GetSTR('L2'))
	If $Answer=6 Then
		Run(@ComSpec & ' /c AutoIt3.exe /ErrorStdOut Traced.au3 | AutoIt3.exe "BiG World Setup-Debug.au3"', @ScriptDir, @SW_HIDE)
	ElseIf $Answer=7 Then
		MsgBox(48, 'BiG World Setup - '&_GetSTR('T1'), _GetSTR('L1'))
		ShellExecute($g_TraceFile)
		Exit
	EndIf
EndIf

; =========================  Trace and test if the program crashed   =========================
Func Observe()
	Local $data, $IsCrashed=0, $DoDebug=1
	;/ErrorStdOut
	While 1
		$Tmp=ConsoleRead()
		If @error Then ExitLoop
		If $Tmp <> '' Then
			$data &= $Tmp
			$data = StringRight($data, StringLen($data) - StringInStr($data, @CR, 0, -25)); just get the last X lines
		EndIf	
		Sleep(25)
	WEnd
	FileWrite(@ScriptDir&'\Logs\BWS_Tracedump.txt', $data)
	$Handle=FileOpen($g_TraceFile, 2)
	$String=StringTrimLeft($data, 1)
	$String=StringSplit(StringStripCR($String), @LF)
	For $s=1 to $String[0]
; ---------------------------------------------------------------------------------------------
; look if we can edit the trace-file to get more informations
; ---------------------------------------------------------------------------------------------
		If StringInStr($String[$s], ') : ==> ') Then; This is the AutoIt3-diagnostic
			$IsCrashed=1
			If StringInStr($String[$s], 'Variable used without being declared') Then
				$DoDebug=0
			Else ;If StringInStr($String, 'Array variable has incorrect number') Then
				$Num=StringSplit($String[$s], '()')
				$File=StringStripWS($Num[1], 1+2); strip leading and trailing white space
				$Num=$Num[2]; 1= text ( 2 = line number ) 3 = other text
				$Array=StringSplit(StringStripCR(FileRead($File)), @LF)
				_InsertDebug($Array, $Num, $File)
			EndIf
		EndIf
; ---------------------------------------------------------------------------------------------
; create the logfile
; ---------------------------------------------------------------------------------------------	
		$Num=StringLeft($String[$s], 2)
		If StringRegExp($Num, '\D{1,2}') Then
			FileWriteLine($Handle, $String[$s])
		ElseIf $Num = '00' Then
			$Line=_FileReadLine(@ScriptDir&'\BiG World Setup.au3', StringRegExpReplace($String[$s], '.*\s', ''))
			FileWriteLine($Handle, $String[$s] & ' - ' & $Line)
		Else
			$Search=FileFindFirstFile(@ScriptDir&'\Includes\'&$Num&'*')
			If $Search=-1 Then
				FileClose($Search)
				ContinueLoop
			EndIf	
			$File=FileFindNextFile($Search)
			If @error Then 
				FileClose($Search)
				ContinueLoop
			EndIf
			$Num=StringTrimLeft($String[$s], StringInStr($String[$s], ' '))
			$Line=_FileReadLine(@ScriptDir&'\Includes\'&$File, $Num)
			FileWriteLine($Handle, $String[$s] & ' - ' & $Line)
			FileClose($Search)
		EndIf
	Next	
	FileClose($Handle)
	Return SetError($IsCrashed, $DoDebug, $IsCrashed)
EndFunc

; =========================  Create a trace-version of the scripts  =========================
Func Trace ()
	Local $Files[50]
	$Search = FileFindFirstFile(@ScriptDir&'\Includes\*.*')  
	While 1
		$File = FileFindNextFile($Search) 
		If @error Then ExitLoop
		$Files[0]+=1
		$Files[$Files[0]]=$File
	WEnd
	FileClose($search)
	ReDim $Files[$Files[0]+1]
	_AddTrace(@ScriptDir&'\Big World Setup.au3', @ScriptDir&'\Traced.au3', '00')
	$String=StringReplace(FileRead(@ScriptDir&'\Traced.au3'), 'Includes\', 'Includes_Traced\')
	$Handle = FileOpen(@ScriptDir&'\Traced.au3', 2)
	FileWrite($Handle, $String)
	FileClose($Handle)
	DirRemove(@ScriptDir&'\Includes_Traced', 1)
	DirCreate(@ScriptDir&'\Includes_Traced')
	For $f=1 to $Files[0]
		If StringInStr($Files[$f], 'UDF') Or StringInStr($Files[$f], 'Debug') Then
			FileCopy(@ScriptDir&'\Includes\'&$Files[$f], @ScriptDir&'\Includes_Traced\'&$Files[$f])
		Else	
			_AddTrace(@ScriptDir&'\Includes\'&$Files[$f], @ScriptDir&'\Includes_Traced\'&$Files[$f], StringLeft($Files[$f], 2))
		EndIf
	Next	
EndFunc	

; =========================  Create a trace-version of a script  =========================
Func _AddTrace($p_File, $p_TraceFile, $p_Num)
	$Skip = '_ezy|_gettr|_iniread|_iniwrite|_selection_populate|__http|__ispressed' 
	$Array = StringSplit(StringStripCR(FileRead($p_File)), @LF)
	$Handle = FileOpen($p_TraceFile, 2)
	For $a = 1 to $Array[0]-1
		If $Array[$a] = '' Then ContinueLoop
		If StringLeft($Array[$a], 3) =  '#cs' Then
			While 1
				$a +=1
				If StringLeft($Array[$a], 3) =  '#ce' Then ExitLoop
			WEnd	
			ContinueLoop
		EndIf
		If StringLeft($Array[$a], 4) = 'Func' Then
			FileWrite($Handle, 'ConsoleWrite("Calling '& $p_Num & ' ' &StringRegExpReplace(StringTrimLeft($Array[$a], 5), '\x28.*', '') & '"&@CRLF)'&@CRLF)
			If StringRegExp(StringLower($Array[$a]), $Skip) Then
				FileWrite($Handle, $Array[$a]&@CRLF)
				While 1
					$a +=1
					If $Array[$a] = '' Then ContinueLoop
					If StringLeft($Array[$a], 1) = ';' Then ContinueLoop
					FileWrite($Handle, $Array[$a]&@CRLF)
					If StringLeft($Array[$a], 7) =  'EndFunc' Then ExitLoop
				WEnd
				FileWrite($Handle, @CRLF&@CRLF)
				ContinueLoop
			EndIf
		EndIf
		If StringLeft($Array[$a], 1) = ';' Then ContinueLoop
		If StringInStr($Array[$a+1], '@error') Then 
			FileWrite($Handle, $Array[$a]&@CRLF)
		ElseIf StringInStr($Array[$a+1]	, '@extended') Then
			FileWrite($Handle, $Array[$a]&@CRLF)
		ElseIf StringInStr($Array[$a]	, 'Select') Then
			FileWrite($Handle, $Array[$a]&@CRLF)
		ElseIf StringInStr($Array[$a]	, 'Switch') Then
			FileWrite($Handle, $Array[$a]&@CRLF)
		ElseIf StringRight($Array[$a], 1) = '_' Then
			FileWrite($Handle, $Array[$a]&@CRLF)
		Else
			FileWrite($Handle, $Array[$a]&@CRLF&'ConsoleWrite("' & $p_Num & ': ' & $a & '"&@CRLF)'&@CRLF)
		EndIf
		If StringLeft($Array[$a], 7) =  'EndFunc' Then FileWrite($Handle, @CRLF&@CRLF)	
	Next
	FileWrite($Handle, $Array[$Array[0]]&@CRLF)
	FileClose($Handle)
EndFunc

; =========================  Create a trace-version of the scripts  =========================
Func _CheckLine($p_Array, $p_Num)
	$iNum=$p_Num
	$Line=StringLower($p_Array[$iNum])
	$Test=StringRegExp($Line, '\A\s{0,}(case|elseif)', 3)
	If @error = 0 Then
		If $Test[0]='case' Then 
			$RegExString = 'select'
		Else	
			$RegExString = 'if.*then\z'
		EndIf
		While 1
			$iNum-=1
			$Line=StringLower(StringStripWS(StringRegExpReplace($p_Array[$iNum], '\x3b.*', ''), 2)); remove trailing comments and spaces
			If StringRegExp($Line, '\A\s{0,}'&$RegExString) Then ExitLoop
		WEnd
	Else
		$iNum = $p_Num
	EndIf
	Return $iNum
EndFunc	

; =========================  Create an array from the given file  =========================
Func _FileReadLine($p_File, $p_Num)
	$Array = StringSplit(StringStripCR(FileRead($p_File)), @LF)
	Return $Array[$p_Num]
EndFunc	

; ---------------------------------------------------------------------------------------------
; Insert a debug-line 
; ---------------------------------------------------------------------------------------------
Func _InsertDebug($p_Array, $p_Num, $p_File)
	$iNum=_CheckLine($p_Array, $p_Num); see if the debugging has to start a few lines before the one that crashed
	ConsoleWrite('!!BWS!! inserting debugging code in '&$p_File&' before line #'&$iNum&': '&$p_Array[$iNum]&@CRLF)
	ConsoleWrite('!!BWS!! original line #'&$p_Num&': '&$p_Array[$p_Num]&@CRLF)
	If StringInStr($p_Array[$iNum-1], '#EndRegion Debug') Then Return SetError(1, 0, 'Debug code was inserted already'); expected if debugging is repeated
	$debug_String=''
	$debug_Skip='ineedthisdummy'
	$debug_Line=StringStripWS($p_Array[$p_Num], 1+2); strip leading and trailing white space
	$debug_Line=StringRegExpReplace($debug_Line, '\s{2,}', ' '); replace multiple spaces with single spaces
	$debug_Line=StringRegExpReplace($debug_Line, '\x3b.*', ''); remove trailing comments
	$debug_Line=StringSplit($debug_Line, ' ()')
	For $debug_l=1 to $debug_Line[0]
		If StringLeft($debug_Line[$debug_l], 1) = '$' Then; test for variables
			$debug_pDimension=StringRegExp($debug_Line[$debug_l], '\x5b', 3); test if it's an array
			$debug_pDimension=UBound($debug_pDimension)
			If @error = 1 Then; this is a normal var, but may be an array
				$debug_Var=$debug_Line[$debug_l]
			ElseIf $debug_pDimension = 1 Or $debug_pDimension = 2 Then; this is a one- or two-dimensional array
				$debug_Var=StringLeft($debug_Line[$debug_l], StringInStr($debug_Line[$debug_l], '[')-1)
			Else
				ContinueLoop
			EndIf
			If StringRegExp(StringLower(StringTrimLeft($debug_Var, 1)), $debug_Skip) Then ContinueLoop
			$debug_String&=' ' & $debug_Var & ' ' & $debug_pDimension
			$debug_Skip=StringRegExpReplace($debug_Skip&'|\A'&StringLower(StringTrimLeft($debug_Var, 1))&'\z', '\A\x7c', '')
		EndIf
	Next
	$debug_String=String(StringReplace($debug_String, ' ', '', 1))
	If $debug_String = '' Then Return SetError(1, 0, 'debug_String is blank'); not expected - something went wrong 
; ---------------------------------------------------------------------------------------------
; create the new file
; ---------------------------------------------------------------------------------------------
	$debug_Handle=FileOpen($p_File, 2)		
	For $a=1 to $p_Array[0]
		If $a=$iNum Then FileWrite($debug_Handle, '#Region Debug' & @CRLF & '$debug_Line="' & $debug_String & '"' & _ 
		@CRLF & FileRead(@ScriptDir&'\Includes\00_Debug.au3') & @CRLF & '#EndRegion Debug'&@CRLF)
		FileWriteLine($debug_Handle, $p_Array[$a])
	Next
	FileClose($debug_Handle)
EndFunc

; ---------------------------------------------------------------------------------------------
; Returns the splitted transplation-string
; ---------------------------------------------------------------------------------------------
Func _GetSTR($p_Num)
	$Tra=IniRead('Config\User.ini', 'Options', 'Lang', 'EN')
	$Value = IniRead('Config\Translation-'&$Tra&'.ini', 'TR-Trace',  $p_Num, '')
	$Value = StringReplace($Value, '|', @CRLF)
	Return $Value
EndFunc   ;==>_GetTR