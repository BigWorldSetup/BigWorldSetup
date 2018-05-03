#include-once

; ---------------------------------------------------------------------------------------------
; Open or close all cd-trays
; ---------------------------------------------------------------------------------------------
Func _CDTray($p_String)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _CDTray')
	Local $Status, $Ret = 0
	For $c = 65 To 90
		If DriveGetType(Chr($c) & ':\') = 'CDROM' Then; Chr converts an ascii-code to a string, here a-z
			If $p_String = 'Open' Then
				$Status=DriveStatus(Chr($c) & ':')
				If $Status = 'Ready' Then
					CDTray(Chr($c) & ':', $p_String)
					$Ret=1
				EndIf
			Else
				CDTray(Chr($c) & ':', $p_String)
			EndIf
		EndIf
	Next
EndFunc   ;==>_CDTray

; ---------------------------------------------------------------------------------------------
; Replaces strings in a file
; ---------------------------------------------------------------------------------------------
Func _FileReplace($p_File, $p_String, $p_Text)
	Local $Text = StringReplace(FileRead($p_File), $p_String, $p_Text); read the file at once
	Local $Handle = FileOpen($p_File, 2)
	FileWrite($Handle, $Text)
	FileClose($Handle)
EndFunc    ;==>_FileReplace

; ---------------------------------------------------------------------------------------------
; Searches for files with a certain pattern
; ---------------------------------------------------------------------------------------------
Func _FileSearch($p_Dir, $p_String)
	Local $Return[1] = [0]
	Local $Search = FileFindFirstFile($p_Dir&'\'&$p_String)
	If $Search = -1 Then Return SetError(1, 0, $Return)
	Local $Ubound=1000
	Local $File, $Return[$Ubound]
	While 1
		$File = FileFindNextFile($Search)
		If @error Then ExitLoop
		If $File = '.' Or $File = '..' Then ContinueLoop
        If $Ubound=$Return[0]+10 Then
			$Ubound+=1000
			ReDim $Return[$Ubound]
		EndIf
		$Return[0]+=1
		$Return[$Return[0]]=$File
	WEnd
	FileClose($Search)
	ReDim $Return[$Return[0]+1]
	Return SetError(0, 0, $Return)
EndFunc    ;==>_FileSearch

; ---------------------------------------------------------------------------------------------
; Searches for files with a certain pattern and deletes these
; ---------------------------------------------------------------------------------------------
Func _FileSearchDelete($p_Dir, $p_String, $p_Attrib='F')
	Local $File, $Search = FileFindFirstFile($p_Dir&'\'&$p_String)
	If $Search = -1 Then Return
	While 1
		$File = FileFindNextFile($Search)
		If @error Then ExitLoop
		If $File = '.' Or $File = '..' Then ContinueLoop
        If StringInStr(FileGetAttrib($p_Dir&'\'&$File), $p_Attrib) Then
			If $p_Attrib = 'D' Then DirRemove($p_Dir&'\'&$File, 1)
			If $p_Attrib = 'F' Then FileDelete($p_Dir&'\'&$File)
		EndIf
	WEnd
	FileClose($Search)
EndFunc    ;==>_FileSearchDelete

; ---------------------------------------------------------------------------------------------
; Returns the bytesize of all archives to update the progressbar properly
; ---------------------------------------------------------------------------------------------
Func _GetArchiveSizes()
	Local $Prefix[4] = [3, '', 'Add', $g_ATrans[$g_ATNum] & '-Add']
	Local $Setups=$g_CurrentPackages
	If $Setups[0][0] = 0 Then
		Local $InstSize[1][4]
		Return $InstSize
	EndIf
	Local $ReadSection, $Size, $InstSize[$Setups[0][0]*3][4]
	For $s=1 to $Setups[0][0]
		$InstSize[0][0] += 1
		$ReadSection=IniReadSection($g_ModIni, $Setups[$s][0])
		$Prefix[3] = _GetTra($ReadSection, 'T')&'-Add'; adjust the language-addon
		For $p=1 to 3
			$Size=_IniRead($ReadSection, $Prefix[$p]&'Size', 0)
			If $Size = 0 Then ContinueLoop
			If $Size = 'Manual' Then $Size=0
			$InstSize[0][1] += $Size
			$InstSize[$InstSize[0][0]][0] = $Setups[$s][0]
			$InstSize[$InstSize[0][0]][$p] = $Size
		Next
	Next
	ReDim $InstSize[$InstSize[0][0]+1][4]
	Return $InstSize
EndFunc    ;==>_GetArchiveSizes

; ---------------------------------------------------------------------------------------------
; Get the possible list of games/flavours that can be installed
; ---------------------------------------------------------------------------------------------
Func _GetGameList()
	Local $GameList[100][3]=[[0]], $Game
	$Game=_FileSearch($g_ProgDir & '\Config', '*')
	Local $Contains, $Description
	For $g=1 to $Game[0]
		If StringRegExp($Game[$g], '(?i)\x2e|\AGlobal\z') Then ContinueLoop
		$Contains=StringSplit(IniRead($g_ProgDir & '\Config\'&$Game[$g]&'\Game.ini', 'Options', 'Contains', ''), '|')
		$Description=StringSplit(IniRead($g_ProgDir & '\Config\'&$Game[$g]&'\Translation-'&$g_ATrans[$g_ATNum]&'.ini', 'UI-BuildTime', 'Interact[1][3]', ''), '|')
		If $Contains[0] <> $Description[0] Then
			ConsoleWrite('!Faulty Game:' & $Game[$g] & @CRLF)
			ContinueLoop
		EndIf
		For $c=1 to $Contains[0]
			$GameList[0][0]+=1
			$GameList[$GameList[0][0]][0]=$Game[$g]
			$GameList[$GameList[0][0]][1]=StringUpper($Contains[$c])
			$GameList[$GameList[0][0]][2]=$Description[$c]
			$GameList[0][2]&='|'&$Description[$c]
		Next
		$GameList[0][1]&='|'&$Game[$g]
	Next
	$GameList[0][2]=StringRegExpReplace($GameList[0][2], '\A\x7c{1,}', '')
	$GameList[0][1]=StringRegExpReplace($GameList[0][1], '\A\x7c{1,}', '')
	ReDim $GameList[$GameList[0][0]+1][3]
	Return $GameList
EndFunc    ;==>_GetGameList

; ---------------------------------------------------------------------------------------------
; Returns the "long" gamename
; ---------------------------------------------------------------------------------------------
Func _GetGameName($p_Text='-')
	Local $Return[12][2]=[[11], ['BG1', "Baldur's Gate"],['BG2', "Baldur's Gate II"],['BWP', "Baldur's Gate II"], ['BWS', "Baldur's Gate II"], ['IWD1', 'Icewind Dale'], ['IWD2', 'Icewind Dale II'], ['PST', 'Planescape: Torment'], ['BG1EE', "Baldur's Gate: Enhanced Edition"], ['BG2EE', "Baldur's Gate II: Enhanced Edition"], ['IWD1EE', 'Icewind Dale: Enhanced Edition'], ['PSTEE', 'Planescape Torment: Enhanced Edition']]
	If $p_Text = '-' Then $p_Text = $g_Flags[14]
	For $r=1 to $Return[0][0]
		If $p_Text = $Return[$r][0] Then Return $Return[$r][1]
	Next
EndFunc    ;==>_GetGameName

; ---------------------------------------------------------------------------------------------
; Just give me the requested translation-string
; ---------------------------------------------------------------------------------------------
Func _GetTR($p_Handle, $p_Num)
	Local $Value = _IniRead($p_Handle, $p_Num, '')
	If $Value = '' Then ConsoleWrite('! Missing: ' & $p_Num & ' for ' & $g_ATrans[$g_ATNum] & @CRLF)
	Return $Value
EndFunc   ;==>_GetTR

; ---------------------------------------------------------------------------------------------
; Returns the WeiDU-file or a translation for a component of a mod. [0-9]*=component translation, R=Read section, S=XX:0-string, T=XX-token & converted -- to XX, T+=XX-token & --, W=Weidu-file
; ---------------------------------------------------------------------------------------------
Func _GetTra($p_Setup, $p_Comp)
	Local $Tra
	If IsArray($p_Setup) Then
		If UBound($p_Setup, 0) = 2 Then
			$Tra=_IniRead($p_Setup, 'Tra', 'EN:0')
		Else
			$Tra=$p_Setup[0]
		EndIf
	Else
		$Tra=IniRead($g_MODIni, $p_Setup, 'Tra', 'EN:0'); CompTra
	EndIf
	Local $Num
	For $m=1 to $g_MLang[0]
		If Not IsArray($Num) Then $Num = StringRegExp($Tra, '(?i)'&$g_MLang[$m]&':\d{1,}', 3)
	Next
	If Not IsArray($Num) Then Return SetError(1, 0, '')
	If StringLeft($Num[0], 2) = '--' Then
		If $p_Comp = 'T+' Then Return '--'
		$Num = StringRegExp($Tra, '(?i)[^--]{2}'&StringTrimLeft($Num[0], 2), 3); return the correct token if NT-dummy was found
		If Not IsArray($Num) Then Return SetError(1, 0, ''); prevent errors on false configuration
	EndIf
	If $p_Comp = 'S' Then Return $Num[0]
	$Tra=StringLeft($Num[0], 2); Langnumber
	If $p_Comp = 'R' Then Return IniReadSection($g_GConfDir&'\WeiDU-'&$Tra&'.ini', $p_Setup)
	If $p_Comp = 'T' Or $p_Comp = 'T+' Then Return $Tra
	If $p_Comp = 'W' Then Return $g_GConfDir&'\WeiDU-'&$Tra&'.ini'
	Return IniRead($g_GConfDir&'\WeiDU-'&$Tra&'.ini', $p_Setup, '@'&$p_Comp, $p_Comp)
EndFunc   ;==>_GetTra

; ---------------------------------------------------------------------------------------------
; Returns the splitted transplation-string
; ---------------------------------------------------------------------------------------------
Func _GetSTR($p_Handle, $p_Num)
	Local $Value = StringReplace(_GetTR($p_Handle, $p_Num), '|', @CRLF)
	Return $Value
EndFunc   ;==>_GetSTR

; ---------------------------------------------------------------------------------------------
; Create a first/last-occurrance lookup index to speed up searching through arrays
;		this is usually used on arrays obtained from _IniRead (which are inikey, inivalue pairs)
;	p_Handle[0][0] = number of items in p_Handle array
;	p_Handle[N][0] = item (string) to be indexed
;   Return[0][0] = number of entries in the index (always 255 for ASCII index)
;	Return[0][1] = number of 
;   Return[ASCII-symbol][0] = number of items in p_Handle whose strings start with ASCII-symbol
;	Return[ASCII-symbol][1] = first index in p_Handle whose string starts with ASCII-symbol
;   Return[ASCII-symbol][2] = last index in p_Handle whose string starts with ASCII-symbol
; ---------------------------------------------------------------------------------------------
Func _IniCreateIndex($p_Handle)
	Local $Return[256][3], $Char;, $OldChar
	$Return[0][0]=255
	For $h=1 to $p_Handle[0][0]
		$Char=Asc(StringLeft($p_Handle[$h][0], 1)); ASCII-symbol of first character
		If $Return[$Char][0] Then; already found first matching index for this ASCII-symbol		
			$Return[$Char][2] = $h; update last matching index for this ASCII-symbol
		Else
			$Return[$Char][1] = $h; first matching index
			$Return[$Char][2] = $h; is also last matching index (until another is found)
		EndIf
		$Return[$Char][0] += 1; count number of matches for this ASCII-symbol
	Next
	Return $Return
EndFunc   ;==>_IniCreateIndex

; ---------------------------------------------------------------------------------------------
; Get items from an IniReadSection-array
; ---------------------------------------------------------------------------------------------
Func _IniDelete(ByRef $p_Handle, $p_Key)
	If Not IsArray($p_Handle) Then
		ConsoleWrite('! Handle not defined for '& $p_Key & @CRLF)
		Return
	EndIf
	For $h = 1 To $p_Handle[0][0]
		If $p_Handle[$h][0] = $p_Key Then
			$p_Handle[0][0] = $p_Handle[0][0]-1
			For $h = $h To $p_Handle[0][0]
				$p_Handle[$h][0] = $p_Handle[$h+1][0]
				$p_Handle[$h][1] = $p_Handle[$h+1][1]
			Next
		EndIf
	Next
EndFunc   ;==>_IniDelete

; ---------------------------------------------------------------------------------------------
; Get the inivalue associated with p_Key from an IniReadSection-array
;	if p_StartLine and p_EndLine are specified (optional), search within that range only
;		_IniCreateIndex can be used to obtain these start and end points more efficiently
; ---------------------------------------------------------------------------------------------
Func _IniRead($p_Handle, $p_Key, $p_Value, $p_StartLine=1, $p_EndLine=0);$p_Value=default
	If Not IsArray($p_Handle) Then
		ConsoleWrite('! Handle not defined for '& $p_Key & ' ' & $p_Value & @CRLF)
		Return SetError(-1, 0, $p_Value)
	EndIf
	If Not $p_EndLine Then $p_EndLine = $p_Handle[0][0]
	For $h = $p_StartLine To $p_EndLine
		If $p_Handle[$h][0] = $p_Key Then
			Return SetError($h, 0, $p_Handle[$h][1])
		EndIf
	Next
	Return SetError(0, 0, $p_Value)
EndFunc   ;==>_IniRead

; ---------------------------------------------------------------------------------------------
; Read a section that's too big for std-ini-function
; ---------------------------------------------------------------------------------------------
Func _IniReadSection($p_File, $p_Section, $p_Sort=0)
	Local $p_Debug = 0, $linecount = 0
	Local $r, $Num, $ReadSection, $Return, $Text
	$Text=@LF&StringStripCR(FileRead($p_File))&@LF&'['
	; Search for: linefeed,possible whitespace,[,section,],possible whitespace,linefeed,something,linefeed,possible whitespace,[
	Local $ReadSection=StringRegExp($Text, '(?is)\n\s{0,}\x5b'&$p_Section&'\x5d\s{0,}\n.*?\n\s{0,}\x5b', 1); x5b = '[', x5d = ']'
	If @error Then Return SetError(@error); nothing found => error out
	If $p_Debug Then FileWrite($g_LogFile, '_IniReadSection $p_Section='&$p_Section&', $p_Sort='&$p_Sort);&') => '&$Text&@CRLF)
	$ReadSection=StringSplit($ReadSection[0], @LF)
;	If $p_Debug Then FileWrite($g_LogFile, '_IniReadSection $ReadSection[0]='&$ReadSection[0]&@CRLF)
	Local $Return[$ReadSection[0]][2]
	For $r=1 to $ReadSection[0]
;		If $p_Debug Then FileWrite($g_LogFile, '_IniReadSection $ReadSection['&$r&']:  '&$ReadSection[$r]&@CRLF)
		If $p_Debug Then $linecount += 1
		$Num=StringInStr($ReadSection[$r], '=')
		If $Num=0 Then ContinueLoop; skip lines that don't contain a = (ini-files delimiter)
		If StringRegExp($ReadSection[$r], '\A\s{0,}\x3b') Then ContinueLoop; skip comments (semicolon ';')
		$Return[0][0]+=1
		$Return[$Return[0][0]][0]=StringStripWS(StringLeft($ReadSection[$r], $Num-1), 3)
		If $p_Sort Then $Return[$Return[0][0]][0]=StringLower($Return[$Return[0][0]][0])
		$Return[$Return[0][0]][1]=StringStripWS(StringMid($ReadSection[$r], $Num+1), 3)
		If $p_Debug Then FileWrite($g_LogFile, $linecount & ': ' & $Return[$Return[0][0]][1]&@CRLF)
	Next
	ReDim $Return[$Return[0][0]+1][2]
	If $p_Sort Then _ArraySort($Return, 0, 1)
	If $p_Debug Then FileWrite($g_LogFile, '_IniReadSection $Return[0][0]='&$Return[0][0]&@CRLF)
	Return $Return
EndFunc    ;==>_IniReadSection

; ---------------------------------------------------------------------------------------------
; Write items to an IniWriteSection(able)-array
; ---------------------------------------------------------------------------------------------
Func _IniWrite(ByRef $p_Handle, $p_Key, $p_Value, $p_Type='A'); $p_Handle=array, $p_Key=key, $p_Value=value, $p_Type=mode (A=append, O=Overwrite, N=New Entry)
	If $p_Type='N' Then
		$p_Handle[0][0]+=1
		$p_Handle[$p_Handle[0][0]][0]=$p_Key
		$p_Handle[$p_Handle[0][0]][1]=$p_Value
	Else
		_IniRead($p_Handle, $p_Key, '')
		Local $Num = @error
		If $Num Then
			If $p_Type='A' Then
				$p_Handle[$Num][1]=$p_Handle[$Num][1]&' '&$p_Value
			ElseIf $p_Type='O' Then
				$p_Handle[$Num][1]=$p_Value
			ElseIf $p_Type='T' Then
				If Not StringInStr($p_Handle[$Num][1], $p_Value) Then $p_Handle[$Num][1]=$p_Handle[$Num][1]&' '&$p_Value
			EndIf
		Else
			$p_Handle[0][0]+=1
			$p_Handle[$p_Handle[0][0]][0]=$p_Key
			$p_Handle[$p_Handle[0][0]][1]=$p_Value
		EndIf
	EndIf
EndFunc   ;==>_IniWrite

; ---------------------------------------------------------------------------------------------
; Runs with stdout/err caption. Returns the output, writes it into a file
; ---------------------------------------------------------------------------------------------
Func _RunSTD($p_File, $p_Dir = @ScriptDir, $p_Log = ''); $a=file, $b=dir, $c=log
	Local $line, $Return
	Local $Stream = Run($p_File, $p_Dir, @SW_HIDE, $STDERR_CHILD + $STDOUT_CHILD); run hidden with stdout/err-read
	If @error Then Return 'ERROR'
	While 1
		$line = StdoutRead($Stream); capture while getting stream
		If @error Then ExitLoop; exit if program does not run any more
		$Return = $Return & $line
		If $p_Log <> '' Then FileWrite($p_Log, $line); log the output
	WEnd
	While 1
		$line = StderrRead($Stream)
		If @error Then ExitLoop
		$Return = $Return & $line
		If $p_Log <> '' Then FileWrite($p_Log, $line)
	WEnd
	Return $Return; Send back the captured stream
EndFunc   ;==>_RunSTD

; ---------------------------------------------------------------------------------------------
; add spaces after an expression a until its length is b
; ---------------------------------------------------------------------------------------------
Func _SetLength($p_String, $p_Length)
	While StringLen($p_String) <> $p_Length
		$p_String = $p_String & ' '
	WEnd
	Return $p_String
EndFunc   ;==>_SetLength

; ---------------------------------------------------------------------------------------------
; Create an array of the input
; ---------------------------------------------------------------------------------------------
Func _SplitComp($p_String)
	Local $Array[2]
	$Array[0] = 1
	If StringInStr($p_String, ' ') Then
		$Array = StringSplit($p_String, ' ')
	Else
		$Array[1] = $p_String
	EndIf
	Return $Array
EndFunc   ;==>_SplitComp

; ---------------------------------------------------------------------------------------------
; Strip leading and trailing @CRLF
; ---------------------------------------------------------------------------------------------
Func _StringStripCRLF($p_String, $p_Num=0)
	Local $Lead='\A(\r\n|\r|\n){1,}'
	Local $Trail='(\r\n|\r|\n){1,}\z'
	Local $Exp
	If $p_Num = 0 Then
		$Exp=$Lead&'|'&$Trail
	ElseIf $p_Num = 1 Then
		$Exp=$Lead
	ElseIf $p_Num = 2 Then
		$Exp=$Trail
	EndIf
	Return StringRegExpReplace($p_String, $Exp, '')
EndFunc    ;==>_StringStripCRLF

; ---------------------------------------------------------------------------------------------
; Test if the string contains other characters than standard-AscII. If it does, translate to dos-codepage
; ---------------------------------------------------------------------------------------------
Func _StringVerifyAscII($p_String)
	Local $dosDir, $Array = StringSplit($p_String, '')
	For $a = 1 To $Array[0]
		If Asc($Array[$a]) > 126 Then
			RunWait(@ComSpec&' /c echo '&$p_String&' > dospath.txt', $g_ProgDir, @SW_HIDE); translate into dos-readable-charakters (doh)
			$dosDir=StringStripWS(StringReplace(FileRead($g_ProgDir&'\dospath.txt'), @CRLF, ''), 3); yes, it's ugly, but it takes some mere 0.03-0.04 seconds - so who cares...
			FileDelete($g_ProgDir&'\dospath.txt')
			Return $dosDir
		EndIf
	Next
	Return $p_String
EndFunc    ;==>_StringVerifyAscII

; ---------------------------------------------------------------------------------------------
; Replace some extended AscII
; ---------------------------------------------------------------------------------------------
Func _StringVerifyExtAscII($p_String)
	; German replacement characters
	If StringRegExp(@OSLang, '0407|0807|0c07|1007|1407') Then
		$p_String = StringReplace($p_String, Chr(0x84), Chr(0xE4)); ae
		$p_String = StringReplace($p_String, Chr(0x94), Chr(0xF6)); oe
		$p_String = StringReplace($p_String, Chr(0x81), Chr(0xFC)); ue
		$p_String = StringReplace($p_String, Chr(0xE1), Chr(0xDF)); sz
		$p_String = StringReplace($p_String, Chr(0x8E), Chr(0xC4)); Ae
		$p_String = StringReplace($p_String, Chr(0x99), Chr(0xD6)); Oe
		$p_String = StringReplace($p_String, Chr(0x9A), Chr(0xDC)); Ue
		$p_String = StringReplace($p_String, Chr(0xA2), Chr(0xD3)); o with accent
		$p_String = StringReplace($p_String, Chr(0xA0), Chr(0xE1)); a with accent
		Return $p_String
	EndIf
	; Spanish OSLANG
	If StringRegExp(@OSLang, '(?i)040a|080a|0c0a|100a|140a|180a|1c0a|200a|240a|280a|2c0a|300a|340a|380a|3c0a|400a|440a|480a|4c0a|500a') Then
		$p_String = StringReplace($p_String, Chr(0xA2), Chr(0xD3))
		$p_String = StringReplace($p_String, Chr(0xA0), Chr(0xE1))
		Return $p_String
	EndIf
	; Russian replacement characters
	$p_String = StringReplace($p_String, Chr(0xA9), Chr(0xE9))
	$p_String = StringReplace($p_String, Chr(0xE6), Chr(0xF6))
	$p_String = StringReplace($p_String, Chr(0xE3), Chr(0xF3))
	$p_String = StringReplace($p_String, Chr(0xAA), Chr(0xEA))
	$p_String = StringReplace($p_String, Chr(0xA5), Chr(0xE5))
	$p_String = StringReplace($p_String, Chr(0xAD), Chr(0xED))
	$p_String = StringReplace($p_String, Chr(0xA3), Chr(0xE3))
	$p_String = StringReplace($p_String, Chr(0xE8), Chr(0xF8))
	$p_String = StringReplace($p_String, Chr(0xE9), Chr(0xF9))
	$p_String = StringReplace($p_String, Chr(0xA7), Chr(0xE7))
	$p_String = StringReplace($p_String, Chr(0xE5), Chr(0xF5))
	$p_String = StringReplace($p_String, Chr(0xEA), Chr(0xFA))
	$p_String = StringReplace($p_String, Chr(0xE4), Chr(0xF4))
	$p_String = StringReplace($p_String, Chr(0xEB), Chr(0xFB))
	$p_String = StringReplace($p_String, Chr(0xA2), Chr(0xE2))
	$p_String = StringReplace($p_String, Chr(0xA0), Chr(0xE0))
	Return $p_String
EndFunc   ;==>_StringVerifyExtAscII