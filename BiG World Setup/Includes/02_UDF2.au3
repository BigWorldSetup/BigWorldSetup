#include-once
; ---------------------------------------------------------------------------------------------
; Little helpers oder ripped UDFs from other people. May be slightly modified
; ---------------------------------------------------------------------------------------------

; __Http-stuff
Global $g_HTTPUserAgent = 'AutoIt3/'&@AutoItVersion, $g_Limit_TimeOut = 5000
Global $g_HTTP_TCP_Def_Port = 80, $g_HTTP_TCP_Port = $g_HTTP_TCP_Def_Port, $g_LAST_SOCKET = -1


#Region HTTP: Done by MrCreatoR
Func __HTTPClose($Socket = -1)
	TCPCloseSocket($Socket)
	TCPShutdown()
	Return 1
EndFunc   ;==>__HTTPClose

Func __HTTPConnect($Host)
	TCPStartup()
	Local $Name_To_IP = TCPNameToIP($Host)
	Local $Socket = TCPConnect($Name_To_IP, $g_HTTP_TCP_Port)
	If $Socket = -1 Then
		TCPCloseSocket($Socket)
		Return SetError(1, 0, "")
	EndIf
	$g_LAST_SOCKET = $Socket
	Return $Socket
EndFunc   ;==>__HTTPConnect

Func __HTTPGet($Host, $Page, $Socket, $sRequest = "GET", $sReferrer = "")
	Local $Command = $sRequest & " " & $Page & " HTTP/1.1" & @CRLF
	$Command &= "Host: " & $Host & @CRLF
	$Command &= "User-Agent: " & $g_HTTPUserAgent & @CRLF
	$Command &= "Referer: " & $sReferrer & @CRLF
	$Command &= "Connection: close" & @CRLF & @CRLF
	Local $BytesSent = TCPSend($Socket, $Command)
	If $BytesSent = 0 Then Return SetError(1, @error, 0)
	Return $BytesSent
EndFunc   ;==>__HTTPGet
#EndRegion HTTP

; ---------------------------------------------------------------------------------------------
; Tries to reduce it's own memory usage if called without parameters. Done by w0uter
; ---------------------------------------------------------------------------------------------
Func __ReduceMemory($p_Process = -1)
	If $p_Process <> -1 Then
		Local $ai_Handle = DllCall("kernel32.dll", 'int', 'OpenProcess', 'int', 0x1f0fff, 'int', False, 'int', $p_Process)
		Local $ai_Return = DllCall("psapi.dll", 'int', 'EmptyWorkingSet', 'long', $ai_Handle[0])
		DllCall('kernel32.dll', 'int', 'CloseHandle', 'int', $ai_Handle[0])
	Else
		Local $ai_Return = DllCall("psapi.dll", 'int', 'EmptyWorkingSet', 'long', -1)
	EndIf

	Return $ai_Return[0]
EndFunc   ;==>__ReduceMemory

; ---------------------------------------------------------------------------------------------
; Show a menu at the given Ctrl in a given window. Lend from helpfile-example
; ---------------------------------------------------------------------------------------------
Func __ShowContextMenu($p_Title, $p_Handle, $p_Menu); $a=GUI, $b=GuiCtrl, $c=ContextMenu
	Local $arPos, $x, $y
	Local $hMenu = GUICtrlGetHandle($p_Menu)
	Local $stPoint = DllStructCreate("int;int")
	$arPos = ControlGetPos($p_Title, "", $p_Handle)
	If @error = 1 Then
		$arPos=GUIGetCursorInfo($g_UI[0])
		DllStructSetData($stPoint, 1, $arPos[0])
		DllStructSetData($stPoint, 2, $arPos[1])
	Else
		DllStructSetData($stPoint, 1, $arPos[0])
		DllStructSetData($stPoint, 2, $arPos[1] + $arPos[3])
	EndIf
	DllCall("user32.dll", "int", "ClientToScreen", "hwnd", $p_Title, "ptr", DllStructGetPtr($stPoint))
	$x = DllStructGetData($stPoint, 1)
	$y = DllStructGetData($stPoint, 2)
	$stPoint = 0
	DllCall("user32.dll", "int", "TrackPopupMenuEx", "hwnd", $hMenu, "int", 0, "int", $x, "int", $y, "hwnd", $p_Title, "ptr", 0)
EndFunc   ;==>__ShowContextMenu

; ---------------------------------------------------------------------------------------------
; Get the dpi-length of a text. Code by Zedna
; ---------------------------------------------------------------------------------------------
Func __StringSplit_ByLength($p_String, $p_Length, $p_Handle)
	Local $Num = 1
	If IsHWnd($p_Handle) = 0 Then $p_Handle = ControlGetHandle($g_UI[0], "", $p_Handle)
	If $p_Length = -1 Then
		$p_Length = ControlGetPos($g_UI[0], '', $p_Handle)-10
		$p_Length = $p_Length[2]-10
		If $p_Handle = ControlGetHandle($g_UI[0], "",$g_UI_Interact[6][2]) Then $p_Length -= 20; scrollbar is always visible
	EndIf
	Local $hDC = DLLCall("user32.dll","int","GetDC","hwnd",$p_Handle)
	$hDC = $hDC[0]
	Local $hFont = DllCall("user32.dll", "ptr", "SendMessage", "hwnd", $p_Handle, "int", $WM_GETFONT, "int", 0, "int", 0)
	$hFont = $hFont[0]
	Local $hOld = DllCall("gdi32.dll", "Hwnd", "SelectObject", "int", $hDC, "ptr", $hFont)
	Local $struct_size = DllStructCreate("int;int")
	$p_String=StringReplace($p_String, '|', ' '&@CRLF&' ')
	$p_String=StringSplit($p_String, ' ')
	Local $Out='', $Len='', $Tmp2
	For $t=1 to $p_String[0]
		If $p_String[$t] = @CRLF Then; handle manual line-breaks
			$Out=$Out & @CRLF
			$Len=''
			$Num+=1
			$t+=1
			$Tmp2=$p_String[$t]
		Else
			$Tmp2=$Len & ' ' &$p_String[$t]
		EndIf
		Local $ret = DllCall("gdi32.dll", "int", "GetTextExtentPoint32", "int", $hDC, "str", $Tmp2, "long", StringLen($Tmp2), "ptr", DllStructGetPtr($struct_size))
		$Tmp2 = DllStructGetData($struct_size,1)
		If $Tmp2 > $p_Length Then
			$Out=$Out & @CRLF &$p_String[$t]
			$Len=$p_String[$t]
			$Num+=1
		Else
			If $Len = '' Then ; no need to add spaces for seperation if nothing is written in this line.
				$Out=$Out & $p_String[$t]
				$Len=$p_String[$t]
			Else
				$Out=$Out & ' ' & $p_String[$t]
				$Len=$Len & ' ' & $p_String[$t]
			EndIf
		EndIf
	Next
	$hOld = DllCall("gdi32.dll", "Hwnd", "SelectObject", "int", $hDC, "ptr", $hOld)
	DLLCall("user32.dll","int","ReleaseDC","hwnd",$p_Handle,"int",$hDC)
	$struct_size = 0
	Local $Tmp2 [2] = [$Out, $Num]
	Return $Tmp2
EndFunc   ;==>__StringSplit_ByLength

; ---------------------------------------------------------------------------------------------
; Returns handle of tree item under mouse: Done by Siao
; ---------------------------------------------------------------------------------------------
Func __TreeItemFromPoint($p_Handle)
	Local $Point = _WinAPI_GetMousePos(True, $p_Handle)
	Return _GUICtrlTreeView_HitTestItem($p_Handle, DllStructGetData($Point, 1), DllStructGetData($Point, 2))
EndFunc   ;==>__TreeItemFromPoint

#Region TristateTreeView: Done by Helge
Func __TristateTreeView_GetCursorPos($p_Handle)
	DllCall("user32.dll", "int", "GetCursorPos", "ptr", DllStructGetPtr($p_Handle))
EndFunc   ;==>__TristateTreeView_GetCursorPos

Func __TristateTreeView_GetWindowLong($p_Handle, $p_Index)
	Local $s = DllCall("user32.dll", "int", "GetWindowLong", "hwnd", $p_Handle, "int", $p_Index)
	Return $s[0]
EndFunc   ;==>__TristateTreeView_GetWindowLong

Func __TristateTreeView_ImageList_LoadImage($p_Handle, $p_File, $p_Width, $p_Grow, $p_Mask, $p_Type, $p_Flags)
	Local $s = DllCall("comctl32.dll", "hwnd", "ImageList_LoadImage", "hwnd", $p_Handle, "str", $p_File, "int", $p_Width, "int", $p_Grow, "int", $p_Mask, "int", $p_Type, "int", $p_Flags)
	Return $s[0]
EndFunc   ;==>__TristateTreeView_ImageList_LoadImage

Func __TristateTreeView_InvalidateRect($p_Handle, $p_String, $p_Num)
	DllCall("user32.dll", "int", "InvalidateRect", "hwnd", $p_Handle, "ptr", $p_String, "int", $p_Num)
EndFunc   ;==>__TristateTreeView_InvalidateRect

Func __TristateTreeView_LoadStateImage($p_Handle, $p_File); $a=handle; $b=file
	Local $Tmp1 = __TristateTreeView_ImageList_LoadImage(0, $p_File, 16, 1, 0xFFFFFFFF, 0, BitOR(0x0010, 0x0020, 0x2000))
	__TristateTreeView_SendMessage($p_Handle, 0x1100 + 9, 2, $Tmp1)
	__TristateTreeView_InvalidateRect($p_Handle, 0, 1)
EndFunc   ;==>__TristateTreeView_LoadStateImage

Func __TristateTreeView_ScreenToClient($p_Handle, $p_String)
	DllCall("user32.dll", "int", "ScreenToClient", "hwnd", $p_Handle, "ptr", DllStructGetPtr($p_String))
EndFunc   ;==>__TristateTreeView_ScreenToClient

Func __TristateTreeView_SendMessage($p_Handle, $p_Msg, $p_wParm, $p_lParm)
	Local $s = DllCall("user32.dll", "int", "SendMessage", "hwnd", $p_Handle, "int", $p_Msg, "int", $p_wParm, "int", $p_lParm)
	Return $s[0]
EndFunc   ;==>__TristateTreeView_SendMessage

; ---------------------------------------------------------------------------------------------
; Sets the tristate icon - code by Helge
; $GUI_UNCHECKED=1; $GUI_CHECKED=2; $GUI_INDETERMINATE=3; $GUI_DISABLE+$GUI_UNCHECKED=4; $GUI_DISABLE+$GUI_CHECKED=5
; ---------------------------------------------------------------------------------------------
Func __TristateTreeView_SetItemState($p_Handle, $p_Num, $p_Show); $a=handle tree; $b=handle item; $c=state
	$p_Show = BitShift($p_Show, -12)
	Local $Tmp1 = DllStructCreate("uint;dword;uint;uint;ptr;int;int;int;int;int;int")
	DllStructSetData($Tmp1, 1, 0x0008)
	DllStructSetData($Tmp1, 2, $p_Num)
	DllStructSetData($Tmp1, 3, $p_Show)
	DllStructSetData($Tmp1, 4, 0xF000)
	__TristateTreeView_SendMessage($p_Handle, 0x1100 + 13, 0, DllStructGetPtr($Tmp1))
EndFunc   ;==>__TristateTreeView_SetItemState

Func __TristateTreeView_WM_Notify($p_Handle, $p_Msg, $p_wParam, $p_lParam)
	Local $stNmhdr = DllStructCreate("dword;int;int", $p_lParam)
	Local $HandleFrom = DllStructGetData($stNmhdr, 1)
	Local $nNotifyCode = DllStructGetData($stNmhdr, 3)
	Local $hItem = 0
	; Check if its treeview and only NM_CLICK and TVN_KEYDOWN
	If Not BitAND(__TristateTreeView_GetWindowLong($HandleFrom, $GWL_STYLE), $TVS_CHECKBOXES) Or Not ($nNotifyCode = $NM_CLICK Or $nNotifyCode = $NM_RCLICK Or $nNotifyCode = $TVN_KEYDOWN) Then Return $GUI_RUNDEFMSG
	If $nNotifyCode = $TVN_KEYDOWN Then
		Local $lpNMTVKEYDOWN = DllStructCreate("dword;int;int;short;uint", $p_lParam)
		; Check for 'SPACE'-press
		If DllStructGetData($lpNMTVKEYDOWN, 4) <> 32 Then Return $GUI_RUNDEFMSG
		$hItem = __TristateTreeView_SendMessage($HandleFrom, $TVM_GETNEXTITEM, $TVGN_CARET, 0)
	Else
		Local $Point = DllStructCreate("int;int")
		__TristateTreeView_GetCursorPos($Point)
		__TristateTreeView_ScreenToClient($HandleFrom, $Point)
		; Check if clicked on state icon
		Local $tvHit = DllStructCreate("int[2];uint;dword")
		DllStructSetData($tvHit, 1, DllStructGetData($Point, 1), 1)
		DllStructSetData($tvHit, 1, DllStructGetData($Point, 2), 2)
		$hItem = __TristateTreeView_SendMessage($HandleFrom, $TVM_HITTEST, 0, DllStructGetPtr($tvHit))
		If $nNotifyCode = $NM_CLICK Then
			If Not BitAND(DllStructGetData($tvHit, 2), $TVHT_ONITEMSTATEICON) Then
				If BitAND(DllStructGetData($tvHit, 2), $TVHT_ONITEMLABEL) Then $g_Flags[17] = 1
				Return $GUI_RUNDEFMSG
			EndIf
		Else
			If Not BitAND(DllStructGetData($tvHit, 2), $TVHT_ONITEMLABEL) Then Return $GUI_RUNDEFMSG
		EndIf
	EndIf
	If $hItem > 0 Then
		If $nNotifyCode = $NM_RCLICK Then
			$g_Flags[16] = 2
			;_GUICtrlTreeView_SetSelected($g_UI_Handle[0], $g_CentralArray[GUICtrlRead($g_UI_Interact[4][1])][5], False); deselect current active item
			_GUICtrlTreeView_SelectItem($g_UI_Handle[0], $hItem, $TVGN_CARET)
		Else
			$g_Flags[16] = 1
		EndIf
		_GUICtrlTreeView_SetSelected($g_UI_Handle[0], $hItem)
		$g_Flags[17] = 1
	EndIf
EndFunc   ;==>__TristateTreeView_WM_Notify
#EndRegion TristateTreeView: Done by Helge