#include-once

; ---------------------------------------------------------------------------------------------
; Get weidu and all selected mods.
; ---------------------------------------------------------------------------------------------
Func Au3Net($p_Num = 0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling Au3Net')
	Local $Message = IniReadSection($g_TRAIni, 'NT-DownloadFile')
	GUICtrlSetData($g_UI_Static[5][1], _GetTR($Message, 'L1')); => watch progress
	GUICtrlSetData($g_UI_Static[6][1], _GetTR($Message, 'L1')); => watch progress
	_Misc_SetTab(5)
	_Process_EnablePause(1)
	GUICtrlSetData($g_UI_Interact[5][7], _GetSTR($Message, 'H1')); => help text
	Local $Prefix[4] = [3, '', 'Add', $g_ATrans[$g_ATNum] & '-Add']
	Local $Sizes = _GetArchiveSizes()
	Local $DArray[$g_CurrentPackages[0][0]*3][12]
	Local $IsPaused=0, $Loop=0
	$g_Flags[0]=1
	DirCreate($g_DownDir)
	$g_LogFile = $g_LogDir & '\BWS-Debug-Download.txt'
	If $p_Num = 2 Then Local $Fault=IniReadSection($g_BWSIni, 'Faults'); rerun - get faults
	GUICtrlSetData($g_UI_Interact[6][1], ($Sizes[0][2] * 100) / $Sizes[0][1]); set the current value at the beginning
; ---------------------------------------------------------------------------------------------
; put relevant data for a download into an array
; ---------------------------------------------------------------------------------------------
	For $d = 1 To $g_CurrentPackages[0][0]; loop through the elements of an array
		If $p_Num = 2 And _IniRead($Fault, $g_CurrentPackages[$d][0], '') = '' Then ContinueLoop; rerun - continue if download did not fail
		$ReadSection = IniReadSection($g_MODIni, $g_CurrentPackages[$d][0])
		$Prefix[3] = _GetTra($ReadSection, 'T')&'-Add'; adjust the language-addon
		For $p=1 to 3
			If $g_Flags[0] = 0 Then; the exit button was pressed
				Exit
			EndIf
			$URL=_IniRead($ReadSection, $Prefix[$p]&'Down', 'Manual')
			$File=_IniRead($ReadSection, $Prefix[$p]&'Save', ''); filename
			$Text=FileRead($g_LogFile)
			If StringInStr($Text, StringFormat(_GetTR($Message, 'L5'), $File)) Or StringInStr($Text, $File & ' ' & _GetTR($Message, 'L7')) Then; => download successful / has been done before - skip downloads that the log stated as done
				$Sizes[0][2]+=_IniRead($ReadSection, $Prefix[$p]&'Size', 0); add size to progressbar
				Continueloop
			EndIf
			If $URL <> 'Manual' Then
				$DArray[0][0]+=1
				$DArray[$DArray[0][0]][0]=$URL; URL
				$DArray[$DArray[0][0]][1]=$File
				$DArray[$DArray[0][0]][2]=$g_CurrentPackages[$d][0]; ini-key
				$DArray[$DArray[0][0]][3]=$Prefix[$p]; Add/XX-Add
				$DArray[$DArray[0][0]][4]=_IniRead($ReadSection, 'Name', ''); modname
				$DArray[$DArray[0][0]][5]=_IniRead($ReadSection, $Prefix[$p]&'Size', 0); size
				$URL=StringRegExpReplace($URL, '\A.*//|/.*\z', ''); shorten to get the server only
				If StringInStr($URL, '.', 0, 2) Then $URL=StringRegExpReplace($URL, '\A[^\x2e]*\x2e', '')
				$DArray[$DArray[0][0]][6]=$URL; server/queue
				; [7]=pid
				$DArray[$DArray[0][0]][8]=$p; used to write to [faults]-section
				; [9]=resume
				; [10]=Check:time
				; [11]=Check:size
			EndIf
		Next
	Next
; ---------------------------------------------------------------------------------------------
; now create an array which tells us which elements of the array are located on which server
; ---------------------------------------------------------------------------------------------
	ReDim $DArray[$DArray[0][0]+1][12]
	Local $DpS[100][2]
	$DpS[0][0]=1; make shs the first one
	$DpS[1][0]='shsforums.net'
	For $s=0 to 99
		$DpS[$s][1]='|'
	Next
	For $d=1 to $DArray[0][0]
		$Found=0
		For $s=1 to $DpS[0][0]
			If $DpS[$s][0] = $DArray[$d][6] Then; append downloads on known servers
				$DpS[$s][1]&=$d&'|'
				$Found=1
				ExitLoop
			EndIf
		Next
		If $Found=0 Then; create a new server-entry
			$DpS[0][0]+=1
			$DpS[$DpS[0][0]][0]=$DArray[$d][6]
			$DpS[$DpS[0][0]][1]&=$d&'|'
		EndIf
	Next
	ReDim $DpS[$DpS[0][0]+1][2]
	For $d=1 to $DpS[0][0]
		;ConsoleWrite($DpS[$d][0]&' ' & UBound(StringRegExp($Dps[$d][1], '\x7c', 3))-1&@CRLF)
		$DpS[0][1]&=$d&'|'; add queue to pending queues
		$Split=StringSplit(StringRegExpReplace($DpS[$d][1], '\A\x7c|\x7c\z', ''), '|')
		For $s=1 to $Split[0]
			$DArray[$Split[$s]][6]=$d; replace the url with the DpS-entry to minimize later searches
		Next
	Next
	If $DpS[1][1] = '|' Then $DpS[0][1]=StringReplace($DpS[0][1], '|1|', '|'); if shs is not used, don't use its queue
	GUICtrlSetData($g_UI_Interact[5][1], ($Sizes[0][2] * 100) / $Sizes[0][1]); update download-progress (maybe ran app before)
	AdlibEnable('_NET_Update_Progress', 1000); do progress updates with adlib so GUI updates on a regular basis
	Local $DSlot[6]=[5]
	Do ; run until all queues are empty
; ---------------------------------------------------------------------------------------------
; stop/pause/resume downloads (one by one)
; ---------------------------------------------------------------------------------------------
		If $g_Flags[23] <> '' Then
			If $g_Flags[23]<0 Then; show wget-progress
				GUICtrlSetData($g_UI_Static[6][2], _GetTR($Message, 'L4') & ' ' & $DArray[$DSlot[-$g_Flags[23]]][4] & _GetTR($g_UI_Message, '0-B6')); => loading
				_Net_WGetShow($DArray[$DSlot[-$g_Flags[23]]][7], -$g_Flags[23])
				ContinueLoop
			EndIf
			$d=StringLeft(($g_Flags[23]+1)/2, 1); the queue to work on
			$list = ProcessList('wget.exe'); check wget-process only so we don't kill other processes
			For $l = 1 To $list[0][0]
				If $DArray[$DSlot[$d]][7] = $list[$l][1] Then
					GUICtrlSetColor($g_UI_Interact[5][$d+1], Default); repaint progress-bar in case there was an error on this queue before
					GUICtrlSetColor($g_UI_Static[5][$d+2], Default)
					GUICtrlSetCursor($g_UI_Static[5][$d+2], -1)
					ProcessClose($DArray[$DSlot[$d]][7])
					ProcessWaitClose($DArray[$DSlot[$d]][7])
					$Result=StdoutRead($DArray[$DSlot[$d]][7]); read the output of wget...
					$Result&=StderrRead($DArray[$DSlot[$d]][7])
					FileWrite($g_LogFile, @CRLF&_StringVerifyExtAscII($Result)&@CRLF); ... and write it into the log
					$DArray[$DSlot[$d]][7]=''
					$g_Down[$d][0]=''; disable updates by AdLib-function
				EndIf
			Next
			If IsInt($g_Flags[23]/2) Then; pause/resume-button
				If GUICtrlRead($g_UI_Button[5][$g_Flags[23]]) = 'II' Then; execute pause-function
					GUICtrlSetColor($g_UI_Interact[5][$d+1], Default); repaint progress-bar in case there was an error on this queue before
					GUICtrlSetColor($g_UI_Static[5][$d+2], Default)
					$DArray[$DSlot[$d]][7]='PAUSE'; mark as paused
					GUICtrlSetData($g_UI_Button[5][$g_Flags[23]], '>')
				Else; execute resume-function
					$Result=_Net_DownloadStart($DArray[$DSlot[$d]][0], $DArray[$DSlot[$d]][1], $DArray[$DSlot[$d]][2], $DArray[$DSlot[$d]][3], $DArray[$DSlot[$d]][4])
					If IsArray($Result) Then; download started
						$DArray[$DSlot[$d]][7] = $Result[0]; wget-PID
						$g_Down[$d][0]=$DArray[$DSlot[$d]][1]; enable updates by AdLib-function
					EndIf
					GUICtrlSetData($g_UI_Button[5][$g_Flags[23]], 'II')
					GUICtrlSetCursor($g_UI_Static[5][$d+2], 0)
				EndIf
			Else; stop-button
				FileDelete($g_DownDir&'\'&$DArray[$DSlot[$d]][1])
			EndIf
		EndIf
		$g_Flags[23]=''
; ---------------------------------------------------------------------------------------------
; exit/pause/resume all due to current decision
; ---------------------------------------------------------------------------------------------
		If $g_Flags[11]=1 Or $g_Flags[13] = 1 Then
			$Found=0
			If $g_Flags[13] = 1 Then $Dps[0][1] = '|'; remove pending from queues
			For $d=1 to 5
				If $DSlot[$d] <> '' And $DSlot[$d] <> '-' Then
					If $DArray[$DSlot[$d]][9]=1 Then; able to resume download
						$list = ProcessList('wget.exe'); check wget-process only so we don't kill other processes
						For $l = 1 To $list[0][0]
							If $DArray[$DSlot[$d]][7] = $list[$l][1] Then
								GUICtrlSetColor($g_UI_Interact[5][$d+1], Default); repaint progress-bar in case there was an error on this queue before
								GUICtrlSetColor($g_UI_Static[5][$d+2], Default)
								GUICtrlSetCursor($g_UI_Static[5][$d+2], -1)
								ProcessClose($DArray[$DSlot[$d]][7])
								ProcessWaitClose($DArray[$DSlot[$d]][7])
								$Result=StdoutRead($DArray[$DSlot[$d]][7]); read the output of wget...
								$Result&=StderrRead($DArray[$DSlot[$d]][7])
								FileWrite($g_LogFile, @CRLF&_StringVerifyExtAscII($Result)&@CRLF); ... and write it into the log
								If $g_Flags[13] = 1 Then; exit was pressed
									GUICtrlSetData($g_UI_Static[5][$d+2], ''); empty download-slot visually
									GUICtrlSetData($g_UI_Interact[5][$d+1], 0)
									$g_Down[$d][0]=''; disable updates by AdLib-function
									$DSlot[$d]='-'; disable further downloads
									$DSlot[0]-=1; decrease the counter for active download-slots
								ElseIf $g_Flags[11] = 1 Then; pause was pressed
									If GUICtrlRead($g_UI_Button[5][$d*2]) = 'II' Then; execute pause-function if still loading
										$DArray[$DSlot[$d]][7]='PAUSE'; mark as paused
										GUICtrlSetData($g_UI_Button[5][$d*2], '>')
										$g_Down[$d][0]=''; disable updates by AdLib-function
									EndIf
								EndIf
							EndIf
						Next
					Else; no resume -- wait and tell user
						$Found+=1
						GUICtrlSetData($g_UI_Static[5][2], _GetTR($Message, 'L12')); => wait for dl without resume
					EndIf
				Else
					If $g_Flags[13] = 1 Then; exit was pressed
						$g_Down[$d][0]=''; disable updates by AdLib-function
						$DSlot[$d]='-'; disable further downloads
						$DSlot[0]-=1; decrease the counter for active download-slots
					EndIf
				EndIf
			Next
			If $Found = 0 And $g_Flags[13] = 1 Then Exit
			$IsPaused=1
			If $g_Flags[11] = 1 Then GUICtrlSetData($g_UI_Static[5][1], _GetTR($g_UI_Message, '0-B4')); => wait for dl without resume
			$g_Flags[11]=0
		ElseIf $g_Flags[12] = 1 Then
			For $d=1 to 5
				If GUICtrlRead($g_UI_Button[5][$d*2]) <> 'II' Then; pause-function was executed before
					$Result=_Net_DownloadStart($DArray[$DSlot[$d]][0], $DArray[$DSlot[$d]][1], $DArray[$DSlot[$d]][2], $DArray[$DSlot[$d]][3], $DArray[$DSlot[$d]][4])
					If IsArray($Result) Then; download started
						$DArray[$DSlot[$d]][7] = $Result[0]; wget-PID
						$g_Down[$d][0]=$DArray[$DSlot[$d]][1]; enable updates by AdLib-function
					EndIf
					GUICtrlSetData($g_UI_Button[5][$d*2], 'II')
				EndIf
			Next
			$IsPaused = 0; reset pause
			$g_Flags[12] = 0; reset resume
		EndIf
; ---------------------------------------------------------------------------------------------
; "real" download-management begins here
; ---------------------------------------------------------------------------------------------
		For $d=1 to 5
			If $DSlot[$d] = '' Then; no DArray-entry assigned to that slot
				If $IsPaused = 1 Then ContinueLoop
				If $DpS[0][1] = '|1|' Then; only shs-queue left. bws may use more than one download
					$Queue=1
				Else
					$Available=$DpS[0][1]; get current unused queues
					For $s=1 to 5
						If $DSlot[$s] <> '' Then $Available=StringReplace($Available, '|'&$DArray[$DSlot[$s]][6]&'|', '|')
					Next
					If $Available='|' Then; all pending queues are already in process
						If $DpS[1][1]<>'|' Then; shs still has downloads pending -> add another shs
							$Available='|1|'
						Else
							$DSlot[$d]='-'; no more queues to work with -> stop working with this slot
							$DSlot[0]-=1; decrease the counter for active download-slots
							ContinueLoop
						EndIf
					EndIf
					$Available=StringSplit(StringRegExpReplace($Available, '\A\x7c|\x7c\z', ''), '|')
					If $Available[0] = 1 Then
						$Queue=$Available[1]
					Else
						$Queue=$Available[Random(1, $Available[0], 1)]; take a random queue
					EndIf
				EndIf
				$Available=StringSplit(StringRegExpReplace($DpS[$Queue][1], '\A\x7c|\x7c\z', ''), '|')
				If $Available[0] = 1 Then
					$DSlot[$d]=$Available[1]
				Else
					$DSlot[$d]=$Available[Random(1, $Available[0], 1)]; take a random item
				EndIf
				If Not StringInStr($DArray[$DSlot[$d]][0], '://') Then; fallback/debug for errors -- best if never used
					ConsoleWrite('!'&$DSlot[$d] & ' == ' & $DArray[$DSlot[$d]][0] & ' == ' & $DArray[$DSlot[$d]][1] & ' == ' & $DArray[$DSlot[$d]][2] & ' == ' & $DArray[$DSlot[$d]][3] & ' == ' & $DArray[$DSlot[$d]][4]&@CRLF)
					ConsoleWrite('-'&$Queue & ' == ' & StringSplit(StringRegExpReplace($DpS[$Queue][1], '\A\x7c|\x7c\z', ''), '|')&@CRLF)
					ConsoleWrite('>'&$DpS[0][0]& ' == ' &$DpS[0][1] &@CRLF)
					For $s=1 to $DpS[0][0]
						ConsoleWrite($DpS[$s][0] & ' == "' & $DpS[$s][1]&'"'&@CRLF)
					Next
					$DSlot[$d] = ''
					ContinueLoop
				EndIf
				$DpS[$Queue][1]=StringReplace($DpS[$Queue][1], '|'&$DSlot[$d]&'|', '|'); remove item from queue
				If $DpS[$Queue][1]='|' Then $DpS[0][1]=StringReplace($DpS[0][1], '|'&$Queue&'|', '|'); remove queue from pending if empty
				$Result=_Net_DownloadStart($DArray[$DSlot[$d]][0], $DArray[$DSlot[$d]][1], $DArray[$DSlot[$d]][2], $DArray[$DSlot[$d]][3], $DArray[$DSlot[$d]][4]); URL, file, setup, prefix, name
				GUICtrlSetColor($g_UI_Interact[5][$d+1], Default); repaint progress-bar in case there was an error on this queue before
				GUICtrlSetColor($g_UI_Static[5][$d+2], Default)
				If IsArray($Result) Then; download started
					$DArray[$DSlot[$d]][1] = $Result[1]; filename
					$DArray[$DSlot[$d]][5] = $Result[2]; size
					$DArray[$DSlot[$d]][7] = $Result[0]; wget-PID
					$DArray[$DSlot[$d]][9] = $Result[3]; resume
					$DArray[$DSlot[$d]][10]=TimerInit(); reset timer
					$DArray[$DSlot[$d]][11]=0; reset size
					If $Result[2] < 0 Then $Result[2]=-$Result[2]
					GUICtrlSetData($g_UI_Static[5][$d+2], $DArray[$DSlot[$d]][4] & ' (' & Round($Result[2]/1048576, 2) & ' MB)')
					GUICtrlSetCursor($g_UI_Static[5][$d+2], 0)
					GUICtrlSetData($g_UI_Interact[5][$d+1], 0)
					$g_Down[$d][0]=$Result[1]; enable updates by AdLib-function
					$g_Down[$d][1]=$Result[2]
					If $Result[3] Then; enable pause/resume
						GUICtrlSetState($g_UI_Button[5][$d*2], $GUI_ENABLE)
					Else
						GUICtrlSetState($g_UI_Button[5][$d*2], $GUI_DISABLE)
					EndIf
				ElseIf $Result = 2 Then; file already downloaded
					$DpS[$DArray[$DSlot[$d]][6]][1]=StringReplace($DpS[$DArray[$DSlot[$d]][6]][1], '|'&$DSlot[$d]&'|', '|'); remove from queue
					$Sizes[0][2]+=$DArray[$DSlot[$d]][5]; increase progress for total downloads
					GUICtrlSetData($g_UI_Interact[5][1], ($Sizes[0][2] * 100) / $Sizes[0][1])
					$DSlot[$d]=''
				ElseIf $Result = 0 Then; fault
					;_Net_SingleLinkUpdate has been deprecated
					;_Process_SetConsoleLog(_GetTR($Message, 'L9')); => fetching update...
					;If StringRegExp(_Net_SingleLinkUpdate($DArray[$DSlot[$d]][2]), '(?i)(\A|\x2c)'&$DArray[$DSlot[$d]][3]&'Down(\z|\x2c)') Then
					;	_Process_SetConsoleLog(_GetTR($Message, 'L10')); => ...was a success, checking again
					;	$ReadSection = IniReadSection($g_MODIni, $DArray[$DSlot[$d]][2])
					;	$DArray[$DSlot[$d]][0]=_IniRead($ReadSection, $DArray[$DSlot[$d]][3]&'Down', 'Manual')
					;	$DArray[$DSlot[$d]][1]=_IniRead($ReadSection, $DArray[$DSlot[$d]][3]&'Save', '')
					;	$DpS[$DArray[$DSlot[$d]][6]][1]&=$d&'|'; add the download to the queue for a later retry
					;	ContinueLoop
					;EndIf
					$DpS[$DArray[$DSlot[$d]][6]][1]=StringReplace($DpS[$DArray[$DSlot[$d]][6]][1], '|'&$DSlot[$d]&'|', '|'); remove from queue
					$Error=IniRead($g_BWSIni, 'Faults', $DArray[$DSlot[$d]][2], '')
					If Not StringInStr($Error, $DArray[$DSlot[$d]][8]) Then
						IniWrite($g_BWSIni, 'Faults', $DArray[$DSlot[$d]][2], $Error & $DArray[$DSlot[$d]][8])
						;FileWrite($g_LogFile, '!0 Need archive for '&$DArray[$DSlot[$d]][2]&' '&$DArray[$DSlot[$d]][8]&@CRLF)
					EndIf
					$DSlot[$d]=''
				EndIf
				$Loop=0
			ElseIf $DSlot[$d] = '-' Then; don't use the slot any more
			Else
				If $DArray[$DSlot[$d]][7] = 'PAUSE' Then; do nothing if marked as paused
				ElseIf Not ProcessExists($DArray[$DSlot[$d]][7]) Then; download finished for that slot
					$Result=StdoutRead($DArray[$DSlot[$d]][7]); read the output of wget...
					$Result&=StderrRead($DArray[$DSlot[$d]][7])
					FileWrite($g_LogFile, @CRLF&_StringVerifyExtAscII($Result)&@CRLF); ... and write it into the log
					$Result=_Net_DownloadStop($DArray[$DSlot[$d]][0], $DArray[$DSlot[$d]][1], $DArray[$DSlot[$d]][2], $DArray[$DSlot[$d]][3], $DArray[$DSlot[$d]][5]); URL, filename, setup/ini-name, prefix, expected size
					If $Result=0 Then; checking the saved file revealed an error
						$Error=IniRead($g_BWSIni, 'Faults', $DArray[$DSlot[$d]][2], '')
						If Not StringInStr($Error, $DArray[$DSlot[$d]][8]) Then
							IniWrite($g_BWSIni, 'Faults', $DArray[$DSlot[$d]][2], $Error & $DArray[$DSlot[$d]][8])
							;FileWrite($g_LogFile, '!1 Need archive for '&$DArray[$DSlot[$d]][2]&' '&$DArray[$DSlot[$d]][8]&@CRLF)
						EndIf
					EndIf
					GUICtrlSetData($g_UI_Static[5][$d+2], ''); clear data of the download-slot
					GUICtrlSetCursor($g_UI_Static[5][$d+2], -1)
					GUICtrlSetData($g_UI_Interact[5][$d+1], 0)
					GUICtrlSetColor($g_UI_Interact[5][$d+1], Default); repaint progress-bar in case there was an error on this queue before
					GUICtrlSetColor($g_UI_Static[5][$d+2], Default)
					$Sizes[0][2]+=$DArray[$DSlot[$d]][5]; increase progress for total downloads
					GUICtrlSetData($g_UI_Interact[5][1], ($Sizes[0][2] * 100) / $Sizes[0][1])
					$DSlot[$d]=''; clean for new item
					$g_Down[$d][0]=''; disable updates by AdLib-function
				EndIf
			EndIf
		Next
		;Sleep(10)
		$Loop+=1
		If $Loop=6 Then
			$Loop=0; reset loop
			GUICtrlSetData($g_UI_Static[5][2], ''); reset the current information-bar 3 seconds after last action
			For $d=1 to $DSlot[0]
				If $DSlot[$d] = '-' Or $DArray[$DSlot[$d]][7] = 'PAUSE' Then ContinueLoop; do nothing if unused or paused
				If TimerDiff($DArray[$DSlot[$d]][10]) > 20000 Then; 20 seconds have passed since last test
					$DArray[$DSlot[$d]][10]=TimerInit(); reset timer
					$localSize=FileGetSize($g_DownDir&'\'&$g_Down[$d][0])
					If $DArray[$DSlot[$d]][11] = $localSize Then
						GUICtrlSetColor($g_UI_Interact[5][$d+1], 0xff0000); paint the progressbar in a red color
						GUICtrlSetColor($g_UI_Static[5][$d+2], 0xff0000)
					Else
						GUICtrlSetColor($g_UI_Interact[5][$d+1], Default); repaint progress-bar in case there was an error on this queue before
						GUICtrlSetColor($g_UI_Static[5][$d+2], Default)
					EndIf
					$DArray[$DSlot[$d]][11]=$localSize
				EndIf
			Next
		EndIf
	Until $Dps[0][1] = '|' And $DSlot[0] = 0  ; run until all queues are empty and downloads are finished
	AdlibDisable()
	If $g_Flags[13] = 1 Then Exit
	GUICtrlSetData($g_UI_Interact[5][1], 100)
	IniWrite($g_BWSIni, 'Order', 'Au3Net', 0); Skip this one if the Setup is rerun
	$g_FItem = 1
EndFunc   ;==>Au3Net

; ---------------------------------------------------------------------------------------------
; Things to do after download (avoid errors for setup-bg1tp)
; ---------------------------------------------------------------------------------------------
Func Au3NetFix($p_Num = 0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling Au3NetFix')
	$g_LogFile = $g_LogDir & '\BWS-Debug-Download.txt'
	$g_CurrentPackages = _GetCurrent(); items may be removed after failed download
	_Process_SwitchEdit(0, 0)
	If FileExists($g_GameDir&'\WeiDU') And Not StringInStr(FileGetAttrib($g_GameDir&'\WeiDU'), 'D') Then FileDelete($g_GameDir&'\WeiDU'); remove WeiDU for mac/linux (if it exists)
	If FileExists($g_DownDir&'\WeiDU.exe') Then FileCopy($g_DownDir&'\WeiDU.exe', $g_GameDir&'\WeiDU\WeiDU.exe', 9); file will be overwritten if it's a beta, since that had to be extracted later
	$ExtractOnlyMods=IniRead($g_GConfDir&'\Game.ini', 'Options', 'ExtractOnly', 'BWFixpack,BWTextpack,BWInstallpack,WeiDU,BeregostCF')
	$DownloadOnlyMods=IniRead($g_GConfDir&'\Game.ini', 'Options', 'DownloadOnly', 'BG1TP,BWPDF')
	For $c=1 to $g_CurrentPackages[0][0]
		If StringRegExp($ExtractOnlyMods, '(?i)(\A|\x2c)'&$g_CurrentPackages[$c][0]&'(\z|\x2c)') Then; avoid file movements from Au3Extract (subdir-logic will move if no tp2 is found)
			_Install_CreateTP2Entry($g_CurrentPackages[$c][0], IniRead($g_MODIni, $g_CurrentPackages[$c][0], 'Name', $g_CurrentPackages[$c][0]), 0)
		ElseIf StringRegExp($DownloadOnlyMods, '(?i)(\A|\x2c)'&$g_CurrentPackages[$c][0]&'(\z|\x2c)') Then; avoid unpacking of pdfs and other bg1-files
			IniDelete ($g_UsrIni, 'Current', $g_CurrentPackages[$c][0])
		EndIf
	Next
	_Net_FixSHSAttachment('ASKARIA'); fix SHS-forum attachment/download
	$g_FItem = 1
	IniWrite($g_BWSIni, 'Order', 'Au3NetFix', 0); Skip this one if the Setup is rerun
	If IniRead($g_UsrIni, 'Options', 'Logic1', 1) = 3 Then
		IniWrite($g_BWSIni, 'Options', 'Start', 1)
		_Process_SetConsoleLog(IniRead($g_TRAIni, 'NT-Au3NetTest', 'L9', ''))
		_Process_Pause(); pause after download
	EndIf
EndFunc   ;==>Au3NetFix

; ---------------------------------------------------------------------------------------------
; Testing function to see if all needed files are loaded
; ---------------------------------------------------------------------------------------------
Func Au3NetTest($p_Num = 0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling Au3NetTest')
	$g_LogFile = $g_LogDir & '\BWS-Debug-Download.txt'
	_Process_Gui_Create(1, 0); switch to correct screen and edit-box after running download-tab
	GUICtrlSetData($g_UI_Interact[6][1], 0)
	Local $Message = IniReadSection($g_TRAIni, 'NT-Au3NetTest')
	GUICtrlSetData($g_UI_Interact[6][4], _GetSTR($Message, 'H1')); => help text
	Local $Prefix[4] = [3, '', 'Add', $g_ATrans[$g_ATNum] & '-Add']
	Local $Down=0
; ---------------------------------------------------------------------------------------------
; Add faults for missing files that have a download-link (Down= in mod.ini is not 'Manual')
; ---------------------------------------------------------------------------------------------
	For $c=1 to $g_CurrentPackages[0][0]
		$ReadSection=IniReadSection($g_MODIni, $g_CurrentPackages[$c][0])
		$Prefix[3] = _GetTra($ReadSection, 'T')&'-Add'; adjust the language-addon
		For $p=1 to $Prefix[0]
			$File = _IniRead($ReadSection, $Prefix[$p]&'Down', 'Manual')
			If $File = 'Manual' Then ContinueLoop
			$expectedSize = _IniRead($ReadSection, $Prefix[$p]&'Size', -1)
			If $expectedSize = 0 Then ContinueLoop; if Size=0 then we always download, so not a fault
			$localSize = FileGetSize($g_DownDir & '\' & $File)
			If $expectedSize <> $localSize Then
				$Error=IniRead($g_BWSIni, 'Faults', $g_CurrentPackages[$c][0], '')
				If Not StringInStr($Error, $p) Then
					IniWrite($g_BWSIni, 'Faults', $g_CurrentPackages[$c][0], $Error & $p); save the error
					;FileWrite($g_LogFile, 'Need archive for '&$g_CurrentPackages[$c][0]&' '& $Error & $p &@CRLF)
				EndIf
			EndIf
		Next
	Next
; ---------------------------------------------------------------------------------------------
; Test if errors exist
; ---------------------------------------------------------------------------------------------
	$Test=_Net_ListMissing()
	If $Test[0][2] = 0 And $Test[0][3] = 0 Then
		_Net_EndAu3NetTest()
		Return
	EndIf
; ---------------------------------------------------------------------------------------------
; Automatically remove all mods with errors if it's selected that way
; ---------------------------------------------------------------------------------------------
	If IniRead($g_UsrIni, 'Options', 'Logic1', 1) = 2 Then; remove all mods with download-errors
		If $Test[0][3] = 0 Then; no essentials are missing
			_Process_SetScrollLog(_GetTR($Message, 'L6')); => this should run properly
			If $Test[0][0] <> 0 Then _Depend_RemoveFromCurrent($Test); remove mods/tp2-files that cannot be installed due to dependencies
			$Fault=IniReadSection($g_BWSIni, 'Faults')
			_Depend_RemoveFromCurrent($Fault, 0); remove mods that could not be loaded completely
			_Net_EndAu3NetTest()
			Return
		Else
			_Process_SetScrollLog(_GetTR($Message, 'L7')); => this does not work > end
			IniWrite($g_UsrIni, 'Options', 'Logic1', 1); set interaction-mode for next BWS start
			$g_Flags[0] = 1
			_Process_Gui_Delete(6, 6, 1)
			Exit
		EndIf
	EndIf
; ---------------------------------------------------------------------------------------------
; What do you want to do?
; ---------------------------------------------------------------------------------------------
	While 1
		_Process_SetScrollLog(_GetTR($Message, 'L1'), 1, -1); => provide files yourself?
		_Process_Question('r|p|c', _GetTR($Message, 'L2'), _GetTR($Message, 'Q1'), 3, $g_Flags[18]); => yes or no?
		If $g_pQuestion = 'r' Then
			Au3Net(2); download
			_Process_Gui_Create(1, 0); switch back to console-screen
			$Test=_Net_ListMissing()
			If $Test[0][2] = 0 And $Test[0][3] = 0 Then
				_Net_EndAu3NetTest()
				Return
			EndIf
		Else
			ExitLoop
		EndIf
	WEnd
; ---------------------------------------------------------------------------------------------
; Provide the files by loading them with the default browser or select them through a fileopendialog
; ---------------------------------------------------------------------------------------------
	If $g_pQuestion = 'p' Then
		$Fault=IniReadSection($g_BWSIni, 'Faults')
		For $f=1 to $Fault[0][0]
			$ReadSection=IniReadSection($g_MODIni, $Fault[$f][0])
			$Prefix[3] = _GetTra($ReadSection, 'T')&'-Add'; adjust the language-addon
			For $l=1 to StringLen($Fault[$f][1])
				$Type=StringMid($Fault[$f][1], $l, 1)
				$Save=_IniRead($ReadSection, $Prefix[$Type]&'Save', '')
				$expectedSize=_IniRead($ReadSection, $Prefix[$Type]&'Size', '')
				$Name=_IniRead($ReadSection, 'Name', $Fault[$f][0])
				GUICtrlSetData($g_UI_Static[6][2], $Name)
				_Process_SetScrollLog('|'&StringFormat(_GetTR($Message, 'L5'), $Save, $Name),0, -1); => if found, save as
				_Process_Question('d|f|s|c', _GetTR($Message, 'L3'), _GetTR($Message, 'Q2'), 4); => download/search/skip one/skip all?
				If $g_pQuestion = 'd' Then; download
					ShellExecute(_IniRead($ReadSection, $Prefix[$Type]&'Down', '')); start browser
					$Down+=1
				ElseIf $g_pQuestion = 'f' Then; file
					While 1
						$Test=FileOpenDialog(_GetTR($Message, 'L10'), $g_DownDir, _GetTR($Message, 'F1') &' (*.7z;*.ace;*.exe;*.rar;*.zip)', 1, $Save, $g_UI[0]); => archives
						If $Test='' Then; user hit cancel button, go back to 'p'rovide prompt
							$f -= 1; back-track the outer loop so we process the same 'fault' (this mod) again
							ExitLoop 2; break out of the two inner loops (While 1 and For $l) to get back to the For $f loop
						EndIf
						Local $File[3] = [$Test, StringLeft($Test, StringInStr($Test, '\', 1, -1)-1), StringTrimLeft($Test, StringInStr($Test, '\', 1, -1))]
						$localSize = FileGetSize($File[0])
						If $localSize = $expectedSize Then; selection matches
							If $File[0] <> $g_DownDir&'\'&$Save Then FileCopy($File[0], $g_DownDir&'\'&$Save, 1)
							ExitLoop
						Else
							_Process_SetScrollLog(_GetTR($Message, 'L11'), 1, -1); =>does not fit, still use it, select another or cancel?
							_Process_Question('f|s|c', _GetTR($Message, 'L12'), _GetTR($Message, 'Q4'), 3); =>Enter force, select or cancel.
							If $g_pQuestion = 'f' Then
								IniWrite($g_MODIni, $Fault[$f][0], $Prefix[$Type]&'Save', $File[2])
								IniWrite($g_MODIni, $Fault[$f][0], $Prefix[$Type]&'Size', $localSize)
								FileCopy($File[0], $g_DownDir&'\', 1)
								ExitLoop
							ElseIf $g_pQuestion = 'c' Then; user chose to cancel, go back to 'p'rovide prompt
								$f -= 1; back-track the outer loop so we process the same 'fault' (this mod) again
								ExitLoop 2; break out of the two inner loops (While 1 and For $l) to get back to the For $f loop
							EndIf
						EndIf
					WEnd
				ElseIf $g_pQuestion = 's' Then; skip this mod
					ExitLoop; break out of While 1 loop
				ElseIf $g_pQuestion = 'c' Then; user chose to cancel, go back to 'p'rovide prompt
					$f -= 1; back-track the outer loop so we process the same 'fault' (this mod) again
					ExitLoop 2; break out of the two inner loops (While 1 and For $l) to get back to the For $f loop
				EndIf
			Next
		Next
		If $Down > 0 Then _Process_Question('c', _GetTR($Message, 'L13'), _GetTR($Message, 'Q5')); =>Enter continue after downloads are finished
		$Test=_Net_ListMissing()
		If $Test[0][2] = 0 And $Test[0][3] = 0 Then
			_Process_SetScrollLog(_GetTR($Message, 'L14'), 1, -1); =>missing found, continue in 5 seconds
			Sleep(5000)
			_Net_EndAu3NetTest()
			Return
		EndIf
	EndIf
; ---------------------------------------------------------------------------------------------
; No essential files are missing: Solve the problem
; ---------------------------------------------------------------------------------------------
	If $Test[0][3] = 0 Then; no essentials are missing.
		_Process_SetScrollLog('|'&_GetTR($Message, 'L6')); => this should run properly
		_Process_SetScrollLog(_GetTR($Message, 'L4'), 1, -1); => please check the missing ones
		_Process_Question('r|e', _GetTR($Message, 'L8'), _GetTR($Message, 'Q3'), 2); => remove mod/exit?
		If $g_pQuestion = 'r' Then; user want's to remove all mods with missing files
			If $Test[0][0] <> 0 Then _Depend_RemoveFromCurrent($Test); remove mods/tp2-files that cannot be installed due to dependencies
			$Fault=IniReadSection($g_BWSIni, 'Faults')
			_Depend_RemoveFromCurrent($Fault, 0)
			_Net_EndAu3NetTest()
			Return
		Else
			Exit
		EndIf
	Else
		_Process_SetScrollLog(_GetTR($Message, 'L7')); => this does not work > end
		$g_Flags[0] = 1
		_Process_Gui_Delete(6, 6, 1)
		Exit
	EndIf
EndFunc   ;==>Au3NetTest

; ---------------------------------------------------------------------------------------------
; Start a download of a file. Return values: 0: failed, 1: loaded, 2: existed
; ---------------------------------------------------------------------------------------------
Func _Net_DownloadStart($p_URL, $p_File, $p_Setup, $p_Prefix, $p_String); Link, SaveAs, Setup-name, Prefix, Modname, Tested
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Net_DownloadStart')
	Local $Message = IniReadSection($g_TRAIni, 'NT-DownloadFile')
	Local $Result, $Loaded = 0, $Referer=''
	If $p_String = '' Then $p_String = $p_Setup
	GUICtrlSetData($g_UI_Static[5][2], _GetTR($Message, 'L2') & ' ' & $p_String & ' ...'); => checking
	$NetInfo=_Net_LinkUpdateInfo($p_URL, $p_File, $p_Setup, $p_Prefix)
	$Changed = @extended
	If $NetInfo[0] = 0 Then; server or file not found
		Return SetError(1, 1, 0)
	ElseIf $p_File = '' Then; Don't work on empty strings. This will just lead in deleting your complete download-folder.
		Return SetError(1, 1, 0)
	Else; file found
		If $Changed Then _Process_SetConsoleLog(_GetTR($Message, 'L8')); => hint that this is a new version
		If $Changed And $p_File <> $NetInfo[1] And Not StringRegExp($p_URL, 'us\.v-cdn\.net\/5019558') Then ; update filename only if changed (might be just size), ignore forums.beamdog.com's attachment like "us.v-cdn.net/5019558/aaaa/bbbb/cccc/XXXYYYZZZ.zip"
			$p_File = $NetInfo[1]
			; save new file name for following sessions
			IniWrite($g_MODIni, $p_Setup, $p_Prefix&'Save', $p_File)
			IniWrite($g_ProgDir&'\Config\Global\'&$p_Setup&'.ini', 'Mod', $p_Prefix&'Save', $p_File)
		EndIf
		If $NetInfo[2] < 0 Then; server returned a 0-byte filesize or no info at all
			If StringInStr($p_URL, 'master') Then; for Git master branch downloads, the file name does not change for new commits
				; we can't assume a local copy is still up to date if we didn't get a valid size, so ensure we do not use a local copy
				If FileExists($g_DownDir & '\' & $p_File) Then
					FileDelete($g_DownDir & '\' & $p_File); delete old copy of file to ensure we download a fresh copy
				EndIf
				$expectedSize = 0; failsafe - if the $p_File name isn't correct in the ini file, still avoid using a local copy (ensure mismatch in size check below)
			Else
				_Process_SetConsoleLog(StringFormat(_GetTR($Message, 'L11'), $p_File)); => server did not return valid filesize, use old value
				$expectedSize = 0-$NetInfo[2]; use the old existing value
			EndIf
		Else
			$expectedSize = $NetInfo[2]
		EndIf
		If FileExists($g_DownDir & '\' & $p_File) Then
			$localSize = FileGetSize($g_DownDir & '\' & $p_File)
			If $expectedSize = $localSize Then; local file has expected size
				FileWrite($g_LogFile, '<= '& $p_File & ' = ' & $localSize & @CRLF)
				_Process_SetConsoleLog($p_File & ' ' & _GetTR($Message, 'L7')); => downloaded before
				; the ini update here is necessary to recognize new local copies that are properly sized according to server info but don't match ini size
				IniWrite($g_MODIni, $p_Setup, $p_Prefix&'Size', $localSize); save file size for following sessions (might be unchanged: this is a catch-all)
				IniWrite($g_ProgDir&'\Config\Global\'&$p_Setup&'.ini', 'Mod', $p_Prefix&'Size', $localSize)
				;Sleep(10)
				Return SetError(0, $Loaded, 2)
			Else ; local file does not have expected size, so we will try to download it
				FileWrite($g_LogFile, '<= '& $p_File & ' <> ' & $localSize & @CRLF)
				$Text=FileRead($g_LogFile)
				If StringInStr($Text, _GetTR($Message, 'L4') & ' ' & $p_File) And StringInStr($Text, '= '&$p_File&' = '&$expectedSize) Then; => fetching - loading logged with same name and size before
				Else; not able to resume
					FileDelete($g_DownDir & '\' & $p_File); delete old copy of file
				EndIf
			EndIf
		Else ; no local copy of the file
			FileWrite($g_LogFile, '<= NA' & @CRLF)
		EndIf
		GUICtrlSetData($g_UI_Static[5][2], _GetTR($Message, 'L4') & ' ' & $p_String & ' (' & Round($expectedSize/1048576, 2) & ' MB)'); => fetching
		_Process_SetConsoleLog(_GetTR($Message, 'L4') & ' ' & $p_File); => Fetching
		If StringInStr($p_URL, 'fastshare.org') Then
			$p_URL = StringReplace($p_URL, 'download', 'files')
			_Net_LoginFastShare($p_URL); activate/unlock the fastshare-link again.
		ElseIf StringLeft($p_URL, 4) = 'http' And Not StringInStr($p_URL, 'sourceforge.net') Then
			$Referer='--referer="'&StringLeft($p_URL, StringInStr($p_URL, '/', 1, 3)-1)&'"'
		EndIf
		_Process_SetConsoleLog('')
		If $expectedSize < 4000000 Then; each output-line has 384KB for smaller files
			$PID=Run('"' & $g_ProgDir & '\Tools\wget.exe" '&$Referer&' --no-passive-ftp --no-check-certificate --connect-timeout=20 --tries=3 --continue --progress=dot:binary --output-document="' & $g_DownDir & '\' & $p_File & '" "' & $p_URL & '"', @ScriptDir, @SW_HIDE, 9)
		Else; each output-line has 3 MB > Save space for big files
			$PID=Run('"' & $g_ProgDir & '\Tools\wget.exe" '&$Referer&' --no-passive-ftp --no-check-certificate --connect-timeout=20 --tries=3 --continue --progress=dot:mega --output-document="' & $g_DownDir & '\' & $p_File & '" "' & $p_URL & '"', @ScriptDir, @SW_HIDE, 9)
		EndIf
	EndIf
	If $NetInfo[2] < 0 Then $expectedSize = $NetInfo[2]; if we did not get a valid size from the server, return negative of size to inform calling function of this
	Local $Return[4]=[$PID, $p_File, $expectedSize, $NetInfo[3]]
	Return $Return
EndFunc   ;==>_Net_DownloadStart

; ---------------------------------------------------------------------------------------------
; Finished a download of a file. Return values: 0: failed, 1: loaded, 2: existed
; ---------------------------------------------------------------------------------------------
Func _Net_DownloadStop($p_URL, $p_File, $p_Setup, $p_Prefix, $p_expectSize)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Net_DownloadStop')
	Local $Message = IniReadSection($g_TRAIni, 'NT-DownloadFile')
	Local $Result
	$Tested=FileRead($g_DownDir & '\' & $p_File, 100)
	If StringInStr($Tested, '<html>') Then; this is just a mere html-page
		FileDelete($g_DownDir & '\' & $p_File)
		$Result='Fault'
	Else
		$localSize = FileGetSize($g_DownDir & '\' & $p_File)
		If $p_expectSize = $localSize Or $p_expectSize = 0-$localSize Then; local file has expected size (second case is for problematic servers - wget timed out, but we got size info another way)
			_Process_SetConsoleLog(StringFormat(_GetTR($Message, 'L5'), $p_File)); => download successful
			IniWrite($g_MODIni, $p_Setup, $p_Prefix&'Size', $localSize); save file size for following sessions (might be unchanged: this is a catch-all)
			IniWrite($g_ProgDir&'\Config\Global\'&$p_Setup&'.ini', 'Mod', $p_Prefix&'Size', $localSize)
			;Sleep(10)
		ElseIf $localSize = 0 Then
			FileDelete($g_DownDir & '\' & $p_File)
			$Result='Fault'
		ElseIf Not FileExists($g_DownDir & '\' & $p_File) Then; broken download
			_Process_SetConsoleLog(StringFormat(_GetTR($Message, 'L6'), $p_File)); => an error occurred. network problems?
			$Result='Fault'
		ElseIf $p_expectSize <= 0 Then; no expected size in mod ini or actual file size does not match server info; save actual size for following sessions
			_Process_SetConsoleLog(StringFormat(_GetTR($Message, 'L5'), $p_File)); => download successful
			IniWrite($g_MODIni, $p_Setup, $p_Prefix&'Size', $localSize)
			IniWrite($g_ProgDir&'\Config\Global\'&$p_Setup&'.ini', 'Mod', $p_Prefix&'Size', $localSize)
			;Sleep(10)
		EndIf
	EndIf
	_Process_SetConsoleLog('')
	If $Result<>'Fault' Then Return SetError(0, 1, 1)
	_Process_SetConsoleLog(StringFormat(_GetTR($Message, 'L3'), $p_File, $p_URL)); => file not found
	;Sleep(10)
	Return SetError(1, 1, 0)
EndFunc   ;==>_Net_DownloadStop

; ---------------------------------------------------------------------------------------------
; End the testing
; ---------------------------------------------------------------------------------------------
Func _Net_EndAu3NetTest()
	IniDelete($g_BWSIni, 'Faults')
	IniWrite($g_BWSIni, 'Order', 'Au3NetTest', 0); Skip this one if the Setup is rerun
	$g_FItem = 1
EndFunc   ;==>_Net_EndAu3NetTest

; ---------------------------------------------------------------------------------------------
; Fix an attachment from SHS
; ---------------------------------------------------------------------------------------------
Func _Net_FixSHSAttachment($p_Mod, $p_Prefix='')
	$Save=IniRead($g_ModIni, $p_Mod, $p_Prefix&'Save', 'Manual')
	If $Save = 'Manual' Or $Save = '' Then Return -1
	If Not FileExists($g_DownDir&'\'&$Save) Then Return -1
	If Asc(FileRead($g_DownDir&'\'&$Save, 1)) <> 10 Then Return 1
	FileCopy($g_DownDir&'\'&$Save, @TempDir&'\'&$Save, 1); backup
	$Raw=StringTrimLeft(FileRead($g_DownDir&'\'&$Save), 1); read the file and strip the linefeed at the start
	$Handle=FileOpen($g_DownDir&'\'&$Save, 2)
	FileWrite($Handle, $Raw)
	FileClose($Handle)
	If Asc(FileRead($g_DownDir&'\'&$Save, 1)) <> 10 Then; success
		FileDelete(@TempDir&'\'&$Save); remove backup
		$Size=FileGetSize($g_DownDir&'\'&$Save)
		IniWrite($g_ModIni, $p_Mod, $p_Prefix&'Size', $Size); adjust the filesize
		IniWrite($g_ProgDir&'\Config\Global\'&$p_Mod&'.ini', 'Mod', $p_Prefix&'Size', $Size)
		Return 1
	Else
		FileCopy(@TempDir&'\'&$Save, $g_DownDir&'\'&$Save, 1); restore backup
		Return SetError(1, 0, 0)
	EndIf
EndFunc   ;==>_Net_FixSHSAttachment

; ---------------------------------------------------------------------------------------------
; List the download-links that would be fetched
; ---------------------------------------------------------------------------------------------
Func _Net_LinkList($p_Num = 0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Net_LinkList')
	Local $Message = IniReadSection($g_TRAIni, 'NT-LinkList')
	$g_Flags[0] = 1
	$g_LogFile = $g_LogDir & '\Big World Link List.txt'
	_Process_Gui_Create(1, 0)
	Local $List = _Tree_GetCurrentList()
	GUICtrlSetData($g_UI_Interact[6][4], _GetSTR($Message, 'H1')); => help text
	GUICtrlSetData($g_UI_Static[6][1], _GetTR($Message, 'L1')); => watch progress
	GUICtrlSetData($g_UI_Interact[6][5], '%MOD%|%URL%|')
	_Net_LinkListUpdate($List)
	While 1
		If $g_Flags[0] = 0 Or $g_Flags[11] = 1 Or $g_Flags[12] = 1 Then ExitLoop
		If $g_pQuestion <> 'Need4Answer' Then _Net_LinkListUpdate($List)
		;Sleep(10)
	WEnd
	Local $List = ''
	GUICtrlSetData($g_UI_Interact[6][5], IniRead($g_TRAIni, 'UI-Buildtime', 'Interact[6][5]', '%URL%'))
	Return _Process_Gui_Delete(3, 3, 1)
EndFunc   ;==>_Net_LinkList

; ---------------------------------------------------------------------------------------------
; Updates the output for the Link-List
; ---------------------------------------------------------------------------------------------
Func _Net_LinkListUpdate($p_List)
	Local $Prefix[4] = [3, '', 'Add', $g_ATrans[$g_ATNum] & '-Add'], $TestedBefore=0, $Fault
	$Format=GUICtrlRead($g_UI_Interact[6][5])
	GUICtrlSetData($g_UI_Interact[6][2], '')
	$Handle=FileOpen($g_LogFile, 2)
	For $l = 1 To $p_List[0][0]; loop through the list
		If $g_Flags[0] = 0 Or $g_Flags[11] = 1 Or $g_Flags[12] = 1 Then ExitLoop
		If $p_List[$l][0] = $p_List[$l - 1][0] Then ContinueLoop; don't show links twice
		$ReadSection=IniReadSection($g_ModIni, $p_List[$l][0])
		$Mod = _IniRead($ReadSection, 'Name', $p_List[$l][0])
		$Prefix[3] = _GetTra($ReadSection, 'T')&'-Add'; adjust the language-addon
		For $p=1 to 3
			$Down = _IniRead($ReadSection, $Prefix[$p]&'Down', '')
			$Save = _IniRead($ReadSection, $Prefix[$p]&'Save', '')
			If $Down = '' Then ContinueLoop; if no additonal stuff is found, skip forward
			If $Down <> 'MANUAL' Then
				$Output=StringReplace(StringReplace(StringReplace($Format, '%URL%', $Down), '%MOD%', $Mod), '|', @CRLF)
				_Process_SetScrollLog($Output, 0)
				FileWrite($Handle, $Output&@CRLF)
			EndIf
		Next
		GUICtrlSetData($g_UI_Interact[6][1], ($l * 100) / $p_List[0][0])
	Next
	GUICtrlSetData($g_UI_Interact[6][1], 100)
	FileClose($Handle)
	$g_pQuestion = 'Need4Answer'
EndFunc   ;==>_Net_LinkListUpdate

; ---------------------------------------------------------------------------------------------
; Retrieve the fileinfo from the url
; ---------------------------------------------------------------------------------------------
Func _Net_LinkGetInfo($p_URL, $p_Debug=0)
	Local $Return[4] = [0, '', 0, 0]; active, name, size, resume
	If $p_URL = '' Or $p_URL = 'Manual' Then Return SetError(1, 0, $Return)
; ---------------------------------------------------------------------------------------------
; Use wget to get the filesize
; ---------------------------------------------------------------------------------------------
	If StringInStr($p_URL, 'fastshare.org') Then
		$p_URL = StringReplace($p_URL, 'download', 'files')
		_Net_LoginFastShare($p_URL); before the link is activated, we have to send a request
	EndIf
	If StringRegExp($p_URL, 'mediafire.com|clandlan.net|zippyshare.com') Then Return $Return; these servers need some manual interaction
	$Return = _Net_WGetSize($p_URL)
	#cs
	ConsoleWrite('[0]'&$Return[0]&@CRLF)
	ConsoleWrite('[1]'&$Return[1]&@CRLF)
	ConsoleWrite('[2]'&$Return[2]&@CRLF)
	#ce
	If $Return[1] <> '' And $Return[2] <> 0 Then; name and size defined => ok
		$Return[0] = 1
		Return $Return
	ElseIf $Return[1] <> '' And $Return[0] = 1 Then; attachment found => ok
		$Return[0] = 1
		Return $Return
	ElseIf $Return[0] = 2 Then; wget-timeout, inetgetsize-fallback
		Return $Return
	ElseIf $Return[0] = -1 Then; an error occurred/giving up/html-site was opened => bad
		$Return[0]=0
		Return $Return
	EndIf
; ---------------------------------------------------------------------------------------------
; Fetch a little piece of the file to determine if it is a real file or just html-stuff
; ---------------------------------------------------------------------------------------------
	If $Return[2] = 0 Then
		If $p_Debug = 1 Then ConsoleWrite(@CRLF&'>Test'&@CRLF)
		FileWrite($g_LogFile, '>Test '); debug
		If $Return[1] = '' Then $Return[1] = StringRegExpReplace($p_URL, '\A.*\x2f', '')
		InetGet($p_URL, @TempDir&'\'&$Return[1], 1, 1)
		While @InetGetActive
			Sleep(50)
			If @InetGetBytesRead > 1000  Then InetGet("abort")
		WEnd
		If StringInStr(FileRead(@TempDir&'\'&$Return[1]), '<html') Then
			For $i=1 to 5
				If FileExists(@TempDir&'\'&$Return[1]) Then
					FileDelete(@TempDir&'\'&$Return[1])
					Sleep(5)
				EndIf
			Next
			$Return[0] = 0
			Return $Return
		EndIf
	EndIf
	If Not StringRegExp($Return[1], '(?i)(pdf|exe|rar|zip|7z|ace)\z') Then
		$Return[0] = 0
		Return $Return; this was some garbage
	EndIf
	$Return[0] = 1; has to be ok if it comes to this point
	Return $Return
EndFunc   ;==>_Net_LinkGetInfo

; ---------------------------------------------------------------------------------------------
; Update the fileinfo of the url
; ---------------------------------------------------------------------------------------------
Func _Net_LinkUpdateInfo($p_URL, $p_File, $p_Setup, $p_Prefix)
	Local $Extended
	FileWrite($g_LogFile, $p_Setup&'['&$p_Prefix&'] ')
	$Return = _Net_LinkGetInfo($p_URL)
	If $Return[0] = 0 Then
		FileWrite($g_LogFile, '= NA' & @CRLF)
		Return SetError(1, 0, $Return)
	EndIf
	Local $ExpectedSize=IniRead($g_MODIni, $p_Setup, $p_Prefix&'Size', -1)
	If $Return[0] = 2 Then; wget-timeout ... inetgetsize-fallback-mode (wget timed out but we got size info from the server using another method)
		If $Return[2] = $ExpectedSize Then; size info from server matches expected size info in our mod ini file 
			$Return[0]=1; ...assume that this is fine
			$Return[1]=$p_File
			FileWrite($g_LogFile, '= FB'); fallback to local copy of file, if available
		Else ; size info from server does not match expected size info in our mod ini file
			$Return[0]=0; mark as error
			FileWrite($g_LogFile, '= FB = NA' & @CRLF); fallback size does not match, cannot proceed
			Return SetError(1, 0, $Return)
		EndIf
	EndIf
	$Return[1]=StringReplace(StringReplace($Return[1], '%20', ' '), '\', ''); set correct space
	If StringLower($Return[1]) <> StringLower($p_File) And Not StringRegExp($p_URL, 'us\.v-cdn\.net\/5019558') Then; name changed, ignore forums.beamdog.com's attachment like "us.v-cdn.net/5019558/aaaa/bbbb/cccc/XXXYYYZZZ.zip"
		;If StringRegExp($p_URL, 'lynxlynx') Then ; http://lynxlynx.info/ie/modhub.php?AstroBryGuy/bg1ub -> AstroBryGuy-bg1ub-???.zip
			; zip file name will change each time there is a new commit; to avoid accumulating copies, reuse 'Save' name from mod ini
			; also don't set $Extended to 1 because of this (we might still set it later because of different filesize, which is fine)
			; N.B. $Extended = 1 is indication to the caller of this function that the filename or filesize does not match the mod ini
		;	FileWrite($g_LogFile, '~ '&$Return[1]&' ')
		;	$Return[1] = $p_File
		;Else ; for any other URL, upon starting download we will save to the filename given by the server
			FileWrite($g_LogFile, '> '&$Return[1] & ' on server <> ' & $p_File &' expected ')
			$Extended = 1
		;EndIf
	Else
		FileWrite($g_LogFile, '= '&$Return[1]&' ')
	EndIf
	If $Return[2] <> 0 Then; got size info from server, one way or another
		If $Return[2] <> $ExpectedSize Then
			FileWrite($g_LogFile, '> '&$Return[2] & ' on server <> ' & $ExpectedSize & ' expected ' & @CRLF)
			$Extended = 1
		Else
			FileWrite($g_LogFile, '= '&$Return[2] & @CRLF)
		EndIf
	Else; did not get size info from server
		FileWrite($g_LogFile, '= NA > ' & $ExpectedSize & @CRLF)
		$Return[2] = 0-$ExpectedSize; negative value indicates no size info from server
	EndIf
	Return SetError(0, $Extended, $Return)
EndFunc	   ;==>_Net_LinkUpdateInfo

; ---------------------------------------------------------------------------------------------
; List the missing downloads / files
; ---------------------------------------------------------------------------------------------
Func _Net_ListMissing()
	Local $Message = IniReadSection($g_TRAIni, 'Net-ListMissing')
	Local $FNum=0, $Host=0, $Dependent
	Local $Prefix[4] = [3, '', 'Add', $g_ATrans[$g_ATNum] & '-Add']
	_Net_RemoveFixedFaults()
	Local $Fault=IniReadSection($g_BWSIni, 'Faults')
	If @error Then
		_Net_EndAu3NetTest()
		Local $Dependent[1][4] = [[0, '', 0, 0]]
		Return $Dependent
	EndIf
	_Process_SetScrollLog(_GetTR($Message, 'L1')&'|'); => could not load following mods
	For $f=1 to $Fault[0][0]
		$ReadSection=IniReadSection($g_MODIni, $Fault[$f][0])
		$Prefix[3] = _GetTra($ReadSection, 'T')&'-Add'; adjust the language-addon
		For $l=1 to StringLen($Fault[$f][1])
			$Type=StringMid($Fault[$f][1], $l, 1)
			If $Type = '1' Then
				$Hint = _GetTR($Message, 'L2'); => main
			ElseIf $Type = '2' Then
				$Hint = _GetTR($Message, 'L3'); => additional
			Else
				$Hint = _GetTR($Message, 'L4'); => translation
			EndIf
			If StringRegExp($g_fLock, '(?i)(\A|\x2c)'&$Fault[$f][0]&'(\z|\x2c)') Then; if mod is fixed, mark as missing essential
				$FNum=1
				$Mark='*  '
			ElseIf StringRegExp(_IniRead($ReadSection, $Prefix[$Type]&'Down', ''), 'mediafire.com|clandlan.net|zippyshare.com|sentrizeal.com') Then; these servers need some manual interaction
				$Host=1
				$Mark='** '
			Else
				$Mark='   '
			EndIf
			_Process_SetScrollLog($Mark&_IniRead($ReadSection, 'Name', $Fault[$f][0])&': '&$Hint &' ('&_IniRead($ReadSection, $Prefix[$Type]&'Save', '')&')'); tell what's missing
			_Process_SetScrollLog('          '&_IniRead($ReadSection, $Prefix[$Type]&'Down', '')); download link
		Next
	Next
	$Dependent=_Depend_GetUnsolved('', ''); $Dependent[0][unsolved, output, missing + unsolved]
	If $Dependent[0][0] <> 0 Then
		_Process_SetScrollLog('|'& _GetTR($g_UI_Message, '6-L6'), 1, -1); => mods cannot be installed due to dependencies
		_Process_SetScrollLog($Dependent[0][1])
	EndIf
	_Process_SetScrollLog('')
	If $FNum = 1 Then
		_Process_SetScrollLog(_GetTR($Message, 'L5')); => * = this is essential mod
		$Dependent[0][3] = 1
	EndIf
	If $Host = 1 Then _Process_SetScrollLog(_GetTR($Message, 'L6')); => ** = the website requires manual interaction
	_Process_SetScrollLog('')
	Return $Dependent
EndFunc   ;==>_Net_ListMissing

; ---------------------------------------------------------------------------------------------
; activate the download-link
; ---------------------------------------------------------------------------------------------
Func _Net_LoginFastShare($p_URL)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Net_LoginFastShare')
	$p_URL = StringReplace($p_URL, 'download', 'files')
	$p_URL = StringSplit($p_URL, '/')
	$Handle = __HTTPConnect("fastshare.org")
	__HTTPGet("fastshare.org", "/dlgo/"&$p_URL[$p_URL[0]]&"?submit=Download&accept=yes", $Handle)
	__HTTPClose($Handle)
EndFunc   ;==>_Net_LoginFastShare

; ---------------------------------------------------------------------------------------------
; Checks if the links are up and shows their size and their filename
; ---------------------------------------------------------------------------------------------
Func _Net_LinkTest($p_Num = 0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Net_LinkTest')
	Local $Message = IniReadSection($g_TRAIni, 'NT-LinkTest')
	Local $Prefix[4] = [3, '', 'Add', $g_ATrans[$g_ATNum] & '-Add'], $TestedBefore=0, $Fault
	$NeedInteract=StringTrimLeft(IniRead($g_TRAIni, 'Net-ListMissing', 'L6', ''), 3)
	$g_Flags[0] = 1
	_Process_Gui_Create(1, 0)
	Local $List = _Tree_GetCurrentList()
	GUICtrlSetData($g_UI_Interact[6][4], _GetSTR($Message, 'H1')); => help text
	GUICtrlSetData($g_UI_Static[6][1], _GetTR($Message, 'L1')); => watch progress
	GUICtrlSetState($g_UI_Button[6][1], $GUI_DISABLE); we don't need input here
	GUICtrlSetState($g_UI_Interact[6][5], $GUI_DISABLE)
	$g_LogFile = $g_LogDir & '\BWS-Debug-Link.txt'
	FileClose(FileOpen($g_LogFile, 2))
	Local $TestedBefore = 0, $Fault = ''
	For $l = 1 To $List[0][0]; loop through the list
		GUICtrlSetData($g_UI_Static[6][2], _GetTR($Message, 'L2') & ' ' & $List[$l][1] & ' ...'); => checking
		If $g_Flags[0] = 0 Or $g_Flags[11] = 1 Or $g_Flags[12] = 1 Then ExitLoop
		If $List[$l][0] = $List[$l - 1][0] Then ContinueLoop; don't show links twice
		Local $ReadSection=IniReadSection($g_ModIni, $List[$l][0])
		$Prefix[3] = _GetTra($ReadSection, 'T')&'-Add'; adjust the language-addon
		For $p=1 to 3
			Local $Down = _IniRead($ReadSection, $Prefix[$p]&'Down', '')
			Local $Save = _IniRead($ReadSection, $Prefix[$p]&'Save', '')
			Local $ExpectedSize = _IniRead($ReadSection, $Prefix[$p]&'Size', -1)
			If $Down = '' Then ContinueLoop; if no additional stuff is found, skip forward
			If $Down <> '' Then
				If $TestedBefore = 0 Then _Process_SetScrollLog($List[$l][1])
				If $Down <> 'Manual' Then _Process_SetScrollLog($Down) ; suppress unnecessary logging of 'Manual' line for downloads that are included in another archive
			EndIf
			If $Down = 'Manual' Then
				$TestedBefore=0; resetting
				_Process_SetScrollLog(_GetTR($Message, 'L5')); => included in another mod
			ElseIf StringRegExp($Down, 'mediafire.com|clandlan.net|zippyshare.com') Then; these servers need some manual interaction
				_Process_SetScrollLog($NeedInteract); => Download needs interaction
			Else
				Local $NetInfo = _Net_LinkUpdateInfo($Down, $Save, $List[$l][0], $Prefix[$p])
				Local $Extended = @extended
				;_Net_SingleLinkUpdate has been deprecated
				;If $NetInfo[0] = 0 And $TestedBefore = 0 Then
				;	_Process_SetScrollLog(_GetTR($Message, 'L11')); => try to update...
				;	If StringRegExp(_Net_SingleLinkUpdate($List[$l][0]), '(?i)(\A|\x2c)'&$Prefix[$p]&'down(\z|\x2c)') Then
				;		_Process_SetScrollLog(_GetTR($Message, 'L12')); => ... was a success, try again
				;		$TestedBefore=1
				;		$p-=1
				;		ContinueLoop
				;	EndIf
				;Else
					If $NetInfo[2] < 0 Then $NetInfo[2] = 0-$NetInfo[2]
					If $Extended Then _Process_SetScrollLog(StringFormat(_GetTR($Message, 'L10'), $Save & ' / ' & $ExpectedSize & ' > ' & $NetInfo[1] & ' / ' & $NetInfo[2])); => hint that this is a new version
					$Size = Round($NetInfo[2]/1048576, 2)
					If $Size = '0' Then $Size='0,01'
					_Process_SetScrollLog(StringFormat(_GetTR($Message, 'L4'), $Size)); => archive found
				;EndIf
				If $NetInfo[0] = 0 Then
					$Fault = $Fault & '|' & $List[$l][1]; collect list of files that weren't found (or had wrong sizes)
					_Process_SetScrollLog(_GetTR($Message, 'L3')); => not found
					;GUICtrlSetColor($g_UI_Interact[6][2], 0xff0000); paint the item red
					;Sleep(500)
					;GUICtrlSetColor($g_UI_Interact[6][2], 0x000000); paint the item black
					$TestedBefore = 0
				EndIf
			EndIf
			_Process_SetScrollLog('')
		Next
		GUICtrlSetData($g_UI_Interact[6][1], ($l * 100) / $List[0][0])
	Next
	GUICtrlSetData($g_UI_Interact[6][1], 100)
	_Process_SetScrollLog(_GetTR($Message, 'L6')); => summary
	If $Fault = '' Then
		_Process_SetScrollLog(_GetTR($Message, 'L7')); => got all files
	Else
		_Process_SetScrollLog(_GetTR($Message, 'L8')); => some are missing
		_Process_SetScrollLog('')
		$Fault = StringSplit(StringTrimLeft($Fault, 1), '|')
		For $f = 1 To $Fault[0]
			_Process_SetScrollLog($Fault[$f])
		Next
	EndIf
	_Process_SetScrollLog(_GetTR($Message, 'L9')); => done
	GUICtrlSetData($g_UI_Static[6][2], _GetTR($Message, 'L9')); => done
	Local $List = '', $b = ''
	Return _Process_Gui_Delete(3, 3)
EndFunc   ;==>_Net_LinkTest

; ---------------------------------------------------------------------------------------------
; Remove resolved entries from the faults-section
; ---------------------------------------------------------------------------------------------
Func _Net_RemoveFixedFaults()
	Local $Prefix[4] = [3, '', 'Add', $g_ATrans[$g_ATNum] & '-Add']
	Local $Fault=IniReadSection($g_BWSIni, 'Faults')
	If @error Then Return
	For $f=1 to $Fault[0][0]
		$ReadSection = IniReadSection($g_MODIni, $Fault[$f][0])
		$Prefix[3] = _GetTra($ReadSection, 'T')&'-Add'; adjust the language-addon
		For $p=1 To $Prefix[0]
			If Not StringInStr($Fault[$f][1], $p) Then ContinueLoop
			$Save=_IniRead($ReadSection, $Prefix[$p]&'Save', '')
			$Size=_IniRead($ReadSection, $Prefix[$p]&'Size', '')
			If FileExists($g_DownDir&'\'&$Save) And FileGetSize($g_DownDir&'\'&$Save) = $Size Then
				$Fault[$f][1]=StringRegExpReplace($Fault[$f][1], '(?i)'&$p, '')
			EndIf
		Next
		If $Fault[$f][1] = '' Then; faults got solved -> remove entries for mod
			;FileWrite($g_LogFile, 'Got all missing files for '&$Fault[$f][0]&@CRLF)
			IniDelete($g_BWSIni, 'Faults', $Fault[$f][0])
		Else
			IniWrite($g_BWSIni, 'Faults', $Fault[$f][0], $Fault[$f][1])
		EndIf
	Next
EndFunc   ;==>_Net_RemoveFixedFaults

; ---------------------------------------------------------------------------------------------
; Function called by AdLib that updates download-progressbars. Otherwise updates would be less frequently
; ---------------------------------------------------------------------------------------------
Func _Net_Update_Progress()
	$DoUpdate=StringRegExp(@OSVersion, 'WIN_VISTA|WIN_7|WIN_2008|WIN_2008R2')
	For $d=1 to 5
		If $g_Down[$d][0] <> '' Then
			If $DoUpdate Then FileRead($g_DownDir&'\'&$g_Down[$d][0], 1); files are not updated on windows 7. Use this as a workaround.
			$localSize=FileGetSize($g_DownDir&'\'&$g_Down[$d][0])
			GUICtrlSetData($g_UI_Interact[5][$d+1], $localSize*100/$g_Down[$d][1])
		EndIf
	Next
EndFunc   ;==>_Net_Update_Progress

; ---------------------------------------------------------------------------------------------
; Shows and updates WGET-output (you can interact)
; ---------------------------------------------------------------------------------------------
Func _Net_WGetShow($p_PID, $p_Num)
	Local $State[5]=[$g_STDStream, 0, 0, 0, GUICtrlGetState($g_UI_Interact[6][4])]; save current settings
	Local $p_Answer[1]=[0]
	For $s=1 to 3
		$State[$s] = GUICtrlGetState($g_UI_Button[0][$s])
	Next
	GUICtrlSetState($g_UI_Interact[6][2], $GUI_SHOW); show scroll-screen
	GUICtrlSetState($g_UI_Interact[6][3], $GUI_HIDE)
	$g_STDStream=$p_PID; use PID, peak from it for initial stdout, scroll to bottom
	$Text=StdoutRead($p_PID, True)
	$OldNum=StringLen($Text)
	$Text = StringRegExpReplace(_StringVerifyExtAscII($Text), '\r\n|\x7c|\r\|\n', @CRLF)
	$Line = @extended
	_GUICtrlEdit_AppendText($g_UI_Interact[6][2], $Text)
	_GUICtrlEdit_LineScroll($g_UI_Interact[6][2], 0, 1 + $Line)
	If BitAND($State[4], $GUI_SHOW) Then _Process_SetSize(2); hide help
	_Process_EnableBackButtonOnly(); disable pause
	GUICtrlSetData($g_UI_Button[0][3],  IniRead($g_TRAIni, 'UI-Buildtime', 'Button[0][1]', 'Back'))
	GUICtrlSetState($g_UI_Seperate[6][0], $GUI_SHOW)
	While 1
		$Text=StdoutRead($p_PID, True); peek for new output and append new text
		$Num=StringLen($Text)
		If $Num <> $OldNum Then
			$NewText = StringRegExpReplace(_StringVerifyExtAscII(StringMid($Text, $OldNum+1)), '\r\n|\x7c|\r\|\n', @CRLF)
			$Line = @extended
			_GUICtrlEdit_AppendText($g_UI_Interact[6][2], $NewText)
			_GUICtrlEdit_LineScroll($g_UI_Interact[6][2], 0, 1 + $Line)
			$OldNum=$Num
		EndIf
		If $g_Flags[13] = 1 Or ProcessExists($p_PID) = 0 Then
			$g_Flags[13] = 0; disable exit -> we just want to leave the current screen
			If BitAND($State[4], $GUI_SHOW) Then _Process_SetSize(1); show help again if needed
			For $s=1 to 3
				If BitAND($State[$s], $GUI_ENABLE) Then GUICtrlSetState($g_UI_Button[0][$s], $GUI_ENABLE)
			Next
			$g_STDStream=$State[0]; reset PID
			GUICtrlSetData($g_UI_Button[0][3],  IniRead($g_TRAIni, 'UI-Buildtime', 'Button[0][3]', 'Exit'))
			GUICtrlSetState($g_UI_Seperate[5][0], $GUI_SHOW)
			ExitLoop
		EndIf
		$DoUpdate=StringRegExp(@OSVersion, 'WIN_VISTA|WIN_7|WIN_2008|WIN_2008R2')
		If $DoUpdate Then FileRead($g_DownDir&'\'&$g_Down[$p_Num][0], 1); files are not updated on windows 7. Use this as a workaround.
		$localSize=FileGetSize($g_DownDir&'\'&$g_Down[$p_Num][0])
		GUICtrlSetData($g_UI_Interact[6][1], $localSize*100/$g_Down[$p_Num][1])
		Sleep(75)
	WEnd
	GUICtrlSetData($g_UI_Interact[6][1], 0)
	GUICtrlSetData($g_UI_Static[6][2], '')
	$g_Flags[23]=''
EndFunc   ;==>_Net_WGetShow

; ---------------------------------------------------------------------------------------------
; Use wget to get the filesize of a download
; ---------------------------------------------------------------------------------------------
Func _Net_WGetSize($p_URL)
	Local $Name='', $Return[4] = [-1, '', 0, 0], $param
	If StringLeft($p_URL, 6) <> 'ftp://' Then $param='--no-check-certificate --server-response'
	$PID = Run('"'&$g_ProgDir&'\Tools\wget.exe" --no-passive-ftp --connect-timeout=20 --tries=1 '&$param&' --spider "'&$p_URL&'"', $g_ProgDir&'\Tools', @SW_HIDE, 8)
	$Success=ProcessWaitClose($PID, 20); wait for 20 seconds -- some servers are slow, e.g. eros.gram.pl
	If $Success=0 Then; timeout was reached
		ProcessClose($PID); close wget (possible hangup)
		$Return[2] = InetGetSize($p_URL)
		If $Return[2] <> 0 Then $Return[0] = 2; mark as fallback-check
		If StringLeft($p_URL, 3) = 'ftp' Then $Return[3]=1
		Return $Return
	EndIf
	$Allines=StdoutRead($PID)
	$Allines&=StderrRead($PID)
	;ConsoleWrite($Allines & @CRLF&@CRLF); remove for debugging
	If StringInStr($Allines, 'unable to resolve') Then Return $Return; unable to get IP
	If StringRegExp(StringStripCR($Allines), '\nGiving up.\n') Or StringRegExp($Allines, '\sERROR\s') Then Return $Return
	If StringLeft($p_URL, 3) = 'ftp' Then; handle ftp-requests
		$Return[3]=1
		If StringRegExp(StringStripCR($Allines), '==> SIZE.*done\x2e\n|No such directory') Then Return $Return; file is not in folder/folder does not exist
		$Size=StringRegExp(StringStripCR($Allines), '\n==> SIZE.*\n', 3)
		If IsArray($Size) Then
			$Return[2]=StringRegExpReplace(StringReplace($Size[0], @LF, ''), '\A.*\s', '')
			$Return[1] = StringRegExpReplace($p_URL, '\A.*\x2f', '')
		EndIf
	Else
		If StringInStr($Allines, '[text/html]') Then Return $Return; this is a plain html-page, file was removed
		If StringInStr($Allines, 'broken link') Then Return $Return; file does not exist
		$Return[0]=0; set "file-exists-guess" (used if size is not specified) to unsure
		If StringInStr($Allines, 'Content-disposition:') Then
			$Return[0]=1
			$Tmp = StringRegExp($Allines, "(?i)Content-disposition: (.*?)" & @CRLF, 3)
			If StringInStr($Tmp[0], '=') Then; skip false/empty declarations
				$Tmp = StringRegExpReplace($Tmp[0], "\A[^=]*=|\x22", '')
				$Return[1] = StringRegExpReplace($Tmp, "\AUTF-8''", ''); remove UTF-8-coding of filenames on foreign servers
				$Return[1] = StringRegExpReplace($Return[1], '\;.*\z', ''); remove UTF-8-coding of filenames on dropbox servers
			EndIf
		EndIf
		If StringInStr($Allines, 'Location:') And $Return[1] = '' Then
			$Tmp = StringRegExp($Allines, "(?i)Location\x3a\s[^\x5b\r]*\r", 3); use server-response. Skip spider-output by using [ in regexp
			If IsArray($Tmp) Then
				$Return[1] = StringRegExpReplace($Tmp[UBound($Tmp)-1], '\A.*\x2f|\r\z', '')
			EndIf
		EndIf
		If Not StringInStr($p_URL, '?') And $Return[1] = '' Then $Return[1] = StringRegExpReplace($p_URL, '\A.*\x2f', '')
		$Size=StringRegExp(StringStripCR($Allines), '\nLength.*\n', 3)
		If IsArray($Size) Then
			$Return[2]=StringReplace(StringRegExpReplace($Size[0], 'Length\x3a\s|\x2c|\x0a|\s\x5b.*|\s\x28.*', ''), 'unspecified', 0)
		EndIf
		If StringInStr($Allines, "HTTP/1.1 206 Partial Content") Or _
			StringInStr($Allines, "Accept-Ranges:") Then $Return[3]=1 ; Resume supported
		If $Return[3]=0 Then ConsoleWrite('!No Resume for '&$p_URL&@CRLF)
	EndIf
	$Return[1]=StringReplace($Return[1], '\', ''); remove backslashes (like from \' )
	Return $Return
EndFunc   ;==>_Net_WGetSize


; ---------------------------------------------------------------------------------------------
; checks for updates for a single mod
; ---------------------------------------------------------------------------------------------
Func _Net_SingleLinkUpdate($p_Setup, $p_Update = 0)
	_PrintDebug('_Net_SingleLinkUpdate has been deprecated - this message should never be seen', 1)
	Return
	Local $Result = '', $UpdateIni = $g_ProgDir & '\Update\Mod.ini'
;	If Not StringRegExp($g_Flags[14], 'BWP|BWS') Then Return; currently no updates for other games than BWP
	Return; new string
	$OldTime = StringTrimRight(FileGetTime($UpdateIni,1,1), 4)
	$NewTime = @YEAR&@MON&@MDAY&@HOUR
	If $NewTime <> $OldTime Or StringInStr($p_Update, 1) Then
		_Net_Update_Link(0)
		FileSetTime($UpdateIni,@YEAR&@MON&@MDAY&@HOUR&@MIN&@SEC,1); save time so file won't get fetched within current hour
	EndIf
	If Not FileExists($UpdateIni) Then Return SetError(1, 0, '')
	$ReadSection = IniReadSection($g_MODIni, $p_Setup)
	$New = IniReadSection($UpdateIni, $p_Setup)
	If @error Then Return ''; this setup has no infos -> return
	For $n=1 to $New[0][0]
		$OldValue = _IniRead($ReadSection, $New[$n][0], 'Manual'); get the old entry
		If $New[$n][1] <> $OldValue Then
			IniWrite($g_MODIni, $p_Setup, $New[$n][0], $New[$n][1]); write if they differ
			$Result&=','&$New[$n][0]
		EndIf
	Next
	Return StringRegExpReplace($Result, '\A,', '')
EndFunc   ;==>_Net_SingleLinkUpdate

; ---------------------------------------------------------------------------------------------
; Fetches an update-packages, extracts it, installs the files and creates backups of the old ones
; ---------------------------------------------------------------------------------------------
Func _Net_StartupUpdate()
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Net_StartupUpdate')
	Local $Message = IniReadSection($g_TRAIni, 'NT-StartupUpdate')
	Local $Reload=0
	If Not StringRegExp($g_Flags[14], 'BWP|BWS') Then; currently no updates for other games than BWP
		GUICtrlSetState($g_UI_Button[3][6], $GUI_DISABLE)
		Return
	EndIf
	$Answer = _Misc_MsgGUI(2, _GetTR($Message, 'L1'), _GetTR($Message, 'L2'), 2, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2')); => look for configuration-updates now?
	If $Answer = 1 Then Return
	_Process_SetSize(0)
	_Process_Gui_Create(1, 0)
	_Process_EnableBackButtonOnly()
	GUICtrlSetStyle($g_UI_Interact[6][1], $PBS_MARQUEE)
	GUICtrlSendMsg($g_UI_Interact[6][1], $PBM_SETMARQUEE, True, 50); final parameter is update time in ms
	_Process_SetScrollLog(_GetTR($Message, 'L3'), '', -1); => wait for inet
	While 1
		$Ping = Ping('194.25.0.60', 1000); test if computer is online -- ip is a tcom-dns-server
		If $Ping <> 0 Then ExitLoop
		If $g_Flags[13] = 1 Then Exit
	WEnd
	GUICtrlSendMsg($g_UI_Interact[6][1], $PBM_SETMARQUEE, False, 50)
	GUICtrlSetStyle($g_UI_Interact[6][1], $PBS_SMOOTH)
	_Process_SetScrollLog(_GetTR($Message, 'L4'), '', -1); => check link updates
	$Success = _Net_Update_Link(2)
	If $Success = 0 Then
		_Process_SetScrollLog(_GetTR($Message, 'L5'), '', -1); => check link updates
		_Process_Gui_Exit(1); exit on failure
	ElseIf $Success = 1 Then
		$g_Setups = _CreateList('s')
	EndIf
	AutoItSetOption('GUIOnEventMode', 0); exit event mode
EndFunc   ;==>_Net_StartupUpdate

; ---------------------------------------------------------------------------------------------
; Updates the names, homepages and links via build package at http://baldurs-gate.eu/bws/mod.ini.gz
; ---------------------------------------------------------------------------------------------
Func _Net_Update_Link($p_Show = 0); Show GUI
	_PrintDebug('_Net_Update_Link has been deprecated - this message should never be seen', 1)
	Return
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Net_Update_Link')
	Local $Message = IniReadSection($g_TRAIni, 'Nt-LinkUpdate')
	Local $Extract, $Fetch, $n, $Entry
	If StringInStr($p_Show, 1) Then GUICtrlSetData($g_UI_Interact[6][4], _GetSTR($Message, 'H1')); => help text
	$UpdateIni = $g_ProgDir & '\Update\Mod.ini'
	$UpdateURL = IniRead($g_MODIni, 'BWS-URLUpdate', 'Down', 'http://baldurs-gate.eu/bws/mod.ini.gz')
	$UpdateArchive = IniRead($g_MODIni, 'BWS-URLUpdate', 'Save', 'mod.ini.gz')
; ---------------------------------------------------------------------------------------------
; 1. Step: Show the console and test connectivity
; ---------------------------------------------------------------------------------------------
	If StringInStr($p_Show, 1) Then
		Global $g_LogFile = $g_LogDir & '\Big World Update Debug.txt'
		$g_Flags[0] = 1
		_Process_Gui_Create(1, 0)
		GUICtrlSetData($g_UI_Static[6][1], _GetTR($Message, 'L1')); => watch progress
		GUICtrlSetState($g_UI_Button[6][1], $GUI_DISABLE); we don't need input here
		GUICtrlSetState($g_UI_Interact[6][5], $GUI_DISABLE)
		GUICtrlSetData($g_UI_Static[6][2], _GetTR($Message, 'L2')); => loading data
		FileClose(FileOpen($g_LogFile, 2))
		For $p=1 to 3
			$Ping = Ping('194.25.0.60', 1000); test if computer is online -- ip is a tcom-dns-server
			If $Ping <> 0 Then ExitLoop
		Next
		If $Ping = 0 Then
			GUICtrlSetData($g_UI_Interact[6][1], 100)
			_Process_SetScrollLog(_GetTR($Message, 'L9')); => ping failed
			GUICtrlSetState($g_UI_Button[0][3], $GUI_ENABLE); Enable the key
			_Process_Gui_Delete(3, 3, 1)
			Return; not connected to the net
		EndIf
	EndIf
; ---------------------------------------------------------------------------------------------
; 2. Step: Get the update-file and save the file - if the actual one is too old
; ---------------------------------------------------------------------------------------------
	If StringTrimRight(FileGetTime($UpdateIni,1,1), 4) <> @YEAR&@MON&@MDAY&@HOUR Or StringInStr($p_Show, 1) Then; only fetch if forced or file is not modified in current @HOUR
		$Fetch=_Net_DownloadStart($UpdateURL, $UpdateArchive, 'BWS-URLUpdate', '', 'Big World URL-Update')
		If IsArray($Fetch) Then; download started
			If $Fetch[2] < 0 Then $Fetch[2]=-$Fetch[2]
			ProcessWaitClose($Fetch[0])
			If FileGetSize($g_DownDir&'\'&$Fetch[1]) = $Fetch[2] Then
				$Fetch = 1
			Else
				$Fetch = 0
			EndIf
		EndIf
		If $Fetch = 0 And $p_Show = '0' Then; failure: single update
			Return; don't halt during download
		ElseIf $Fetch = 0 And StringInStr($p_Show, '2') Then; failure: boot update
			Return 0; not connected to the net
		ElseIf $Fetch = 0 And StringInStr($p_Show, '1') Then; failure: manual update
			_Process_SetScrollLog(_GetTR($Message, 'L7')); => page could not be loaded
			GUICtrlSetState($g_UI_Button[0][3], $GUI_ENABLE); Enable the key
			_Process_Gui_Delete(3, 3, 1)
			Return
		ElseIf $Fetch = 2 Then; exists -- but since single updates are possible
			If Not FileExists($UpdateIni) Then $Fetch = 1; make sure update\mod.ini exists and still look for updates
		EndIf
		If $Fetch = 1 Then; loaded: all update-types
			$UpdateArchive = IniRead($g_MODIni, 'BWS-URLUpdate', 'Save', 'mod.ini.gz')
			$Extract = _Extract_7z($g_DownDir&'\'&$UpdateArchive, $g_ProgDir & '\Update')
			If $Extract = 0 Or Not FileExists($UpdateIni) Then ; extract failed / Ini does not exist
				If StringInStr($p_Show, '1') Then
					GUICtrlSetData($g_UI_Interact[6][1], 100)
					_Process_SetScrollLog(_GetTR($Message, 'L7')); => page could not be loaded
					GUICtrlSetState($g_UI_Button[0][3], $GUI_ENABLE); Enable the key
					_Process_Gui_Delete(3, 3, 0)
				EndIf
				Return -1
			Else
				FileSetTime($UpdateIni,@YEAR&@MON&@MDAY&@HOUR&@MIN&@SEC,1); save time so file won't get fetched within current hour
				GUICtrlSetData($g_UI_Interact[6][1], 20)
				GUICtrlSetData($g_UI_Static[6][2], _GetTR($Message, 'L3')); => prepare
			EndIf
		EndIf
	EndIf
; ---------------------------------------------------------------------------------------------
; 3. Step: Get and write the new entries into the config-files
; ---------------------------------------------------------------------------------------------
	If StringInStr($p_Show, '2') Then
		If $p_Show Then GUICtrlSetData($g_UI_Interact[6][1], 40)
		If $p_Show Then GUICtrlSetData($g_UI_Static[6][2], _GetTR($Message, 'L4')); => process
		If $p_Show Then GUICtrlSetState($g_UI_Button[0][3], $GUI_DISABLE); Don't screw things up
		If $Extract = 1 Then FileCopy($g_MODIni, $g_MODIni & '-' & @MON & '.' & @MDAY & '-' & @HOUR & '.' & @MIN & '.' & @SEC & '.bak'); create a backup
		$SectionNames = IniReadSectionNames($UpdateIni)
		For $s = 1 To $g_Setups[0][0]
			If _MathCheckDiv($s, 10) = 2 Then GUICtrlSetData($g_UI_Interact[6][1], 40 + ($s * 60 / $g_Setups[0][0]))
			$Success = 0
			For $n=1 to $SectionNames[0]
				If $g_Setups[$s][0] = $SectionNames[$n] Then
					$Success = 1
					ExitLoop
				EndIf
			Next
			If $Success = 0 Then ContinueLoop; don't update if the chapter is not mentioned
			$h = 0; "mod is changed-line" is shown
			$NewSection = IniReadSection($UpdateIni, $g_Setups[$s][0]); has to exist we searched for sections from the update-file
			$OldSection = IniReadSection($g_MODIni, $g_Setups[$s][0])
			If Not IsArray($OldSection) Then; create dummy entry for new additions
				Local $OldSection[1][2]
				$OldSection[0][0]=0
			EndIf
			ReDim $OldSection[$NewSection[0][0]+$OldSection[0][0]+1][2]; ReDim seems be faster once & big than small & every time during _IniWrite/Delete, so use a size big enough.
			For $n = 1 to $NewSection[0][0]
				If $NewSection[$n][0] = 'Rev' Then
					$NewValue=StringRegExpReplace($NewSection[$n][1], '\Av|\A\x28|\x29\z', '')
				Else
					$NewValue=$NewSection[$n][1]
				EndIf
				$OldValue = _IniRead($OldSection, $NewSection[$n][0], ''); get the old entry
				If $NewValue == $OldValue Then; exactly the same (case sensitive)
				Else; there is a change
					If $h = 0 Then; make a note
						$h = 1
						If $p_Show Then _Process_SetScrollLog(_GetTR($Message, 'L5') & ' ' &  $g_Setups[$s][1] & ':'); => update entry
					EndIf
					If $NewSection[$n][1] = '' Then; empty key-value => delete key in original file
						_IniDelete($OldSection, $NewSection[$n][0])
					Else; new or changed value
						_IniWrite($OldSection, $NewSection[$n][0], $NewValue, 'O')
					EndIf
					If $p_Show Then _Process_SetScrollLog($NewSection[$n][0] & '=' & $NewValue)
				EndIf
			Next
			If $h = 1 Then
				ReDim $OldSection[$OldSection[0][0]+1][2]
				IniWriteSection($g_MODIni, $g_Setups[$s][0], $OldSection); write changes
				If $p_Show Then _Process_SetScrollLog('')
			EndIf
		Next
		#cs Remove unused sections -- currently unused
		$NewSection = IniReadSection($UpdateIni, 'DeletedIniSections'); delete removed section
		If Not @error Then
			For $n=1 To $NewSection[0][0]
				IniDelete($g_MODIni, $NewSection[$n][0])
			Next
		EndIf
		#ce Remove unused sections -- currently unused
		GUICtrlSetData($g_UI_Interact[6][1], 100)
		GUICtrlSetState($g_UI_Button[3][6], $GUI_DISABLE); Disable another manual check during runtime
		If $p_Show = 2 Then
			GUICtrlSetState($g_UI_Button[0][3], $GUI_ENABLE); Enable the key
			Return 1
		EndIf
		GUICtrlSetData($g_UI_Static[6][2], _GetTR($Message, 'L6')); => reloading to apply changes
		_Process_SetScrollLog(_GetTR($Message, 'L6')); => reloading to apply changes
		_Tree_GetCurrentSelection(1)
		_Misc_ReBuildTreeView(1)
		_Tree_Reload()
		_Misc_SetTab(6)
		_Process_SetScrollLog(_GetTR($Message, 'L8')); => finished
		GUICtrlSetState($g_UI_Button[0][3], $GUI_ENABLE); Enable the key
		If StringInStr($p_Show, 1) Then _Process_Gui_Delete(3, 3, 1)
	EndIf
EndFunc   ;==>_Net_Update_Link
