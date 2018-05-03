#include-once

; #INTERNAL_USE_ONLY#============================================================================================================
; Description ...: This is just a bunch of Constants and some UDFs that are shipped with AutoIt3 -- so I did not write this.
; I ripped them out of the original files to reduce the "overhead". Have a look at the original files if you like to know the author.
; ===============================================================================================================================

#Region Constants
; ---------------------------------------------------------------------------------------------
; GuiConstants
; ---------------------------------------------------------------------------------------------
Global Const $GUI_EVENT_CLOSE = -3
Global Const $GUI_DROPACCEPTED = 8
Global Const $GUI_NODROPACCEPTED = 4096
Global Const $GUI_WS_EX_PARENTDRAG = 0x00100000
Global Const $GUI_RUNDEFMSG = 'GUI_RUNDEFMSG'
Global Const $GUI_EXPAND = 1024
Global Const $GUI_SHOW = 16
Global Const $GUI_HIDE = 32
Global Const $GUI_ENABLE = 64
Global Const $GUI_DISABLE = 128
Global Const $GUI_FOCUS = 256
Global Const $GUI_NOFOCUS = 8192
Global Const $GUI_DEFBUTTON = 512
Global Const $GUI_CHECKED = 1
Global Const $GUI_UNCHECKED = 4
Global Const $GUI_ONTOP = 2048

; Events and messages
Global Const $GUI_EVENT_MINIMIZE = -4
Global Const $GUI_EVENT_RESTORE = -5
Global Const $GUI_EVENT_MAXIMIZE = -6
Global Const $GUI_EVENT_PRIMARYDOWN = -7
Global Const $GUI_EVENT_PRIMARYUP = -8
Global Const $GUI_EVENT_SECONDARYDOWN = -9
Global Const $GUI_EVENT_SECONDARYUP = -10
Global Const $GUI_EVENT_MOUSEMOVE = -11
Global Const $GUI_EVENT_RESIZED = -12
Global Const $GUI_EVENT_DROPPED = -13
; ---------------------------------------------------------------------------------------------
; Constants
; ---------------------------------------------------------------------------------------------
Global Const $STDIN_CHILD = 1
Global Const $STDOUT_CHILD = 2
Global Const $STDERR_CHILD = 4
Global Const $STDERR_MERGED = 8
Global Const $GWL_STYLE = 0xFFFFFFF0

; ---------------------------------------------------------------------------------------------
; WindowsConstants
; ---------------------------------------------------------------------------------------------
Global Const $WS_MAXIMIZEBOX = 0x00010000
Global Const $WS_MINIMIZEBOX = 0x00020000
Global Const $WS_SIZEBOX = 0x00040000
Global Const $WS_SYSMENU = 0x00080000
Global Const $WS_HSCROLL = 0x00100000
Global Const $WS_VSCROLL = 0x00200000
Global Const $WS_BORDER = 0x00800000
Global Const $WS_CAPTION = 0x00C00000
Global Const $WS_GROUP = 0x00020000
Global Const $WS_EX_LAYERED = 0x00080000
Global Const $WS_EX_MDICHILD = 0x00000040
Global Const $WS_EX_CLIENTEDGE = 0x00000200
Global Const $WS_POPUP = 0x80000000
Global Const $WS_DISABLED = 0x08000000
Global Const $WM_NOTIFY = 0x004E
Global Const $WM_GETMINMAXINFO = 0x0024
Global Const $WS_EX_TOPMOST = 0x00000008
Global Const $WS_EX_TOOLWINDOW = 0x00000080
Global Const $WM_GETFONT = 0x0031
Global Const $WS_CLIPSIBLINGS = 0x04000000

Global Const $NM_FIRST = 0
Global Const $NM_OUTOFMEMORY = $NM_FIRST - 1
Global Const $NM_CLICK = $NM_FIRST - 2
Global Const $NM_DBLCLK = $NM_FIRST - 3
Global Const $NM_RETURN = $NM_FIRST - 4
Global Const $NM_RCLICK = $NM_FIRST - 5
Global Const $NM_RDBLCLK = $NM_FIRST - 6
Global Const $NM_SETFOCUS = $NM_FIRST - 7
Global Const $NM_KILLFOCUS = $NM_FIRST - 8

; ---------------------------------------------------------------------------------------------
; StaticConstants
; ---------------------------------------------------------------------------------------------
Global Const $SS_LEFT = 0
Global Const $SS_CENTER = 1
Global Const $SS_RIGHT = 2
Global Const $SS_CENTERIMAGE = 0x0200
Global Const $GUI_SS_DEFAULT_LABEL = 0
Global Const $ES_CENTER = 1
Global Const $SS_NOTIFY = 0x0100

; ---------------------------------------------------------------------------------------------
; ProgressConstants
; ---------------------------------------------------------------------------------------------
Global Const $PBS_SMOOTH = 1
Global Const $PBS_MARQUEE = 0x00000008
Global Const $__PROGRESSBARCONSTANT_WM_USER = 0X400
Global Const $PBM_SETMARQUEE = $__PROGRESSBARCONSTANT_WM_USER + 10

; ---------------------------------------------------------------------------------------------
; StructureConstants
; ---------------------------------------------------------------------------------------------
Global Const $tagNMLVKEYDOWN = "hwnd hWndFrom;int IDFrom;int Code;int VKey;int Flags"
Global Const $tagNMHDR = "hwnd hWndFrom;int IDFrom;int Code"
Global Const $tagNMITEMACTIVATE = "hwnd hWndFrom;int IDFrom;int Code;int Index;int SubItem;int NewState;int OldState;" & _
		"int Changed;int X;int Y;int lParam;int KeyFlags"
Global Const $tagTVITEMEX = "int Mask;int hItem;int State;int StateMask;ptr Text;int TextMax;int Image;int SelectedImage;" & _
		"int Children;int Param;int Integral"
Global Const $tagRECT = "int Left;int Top;int Right;int Bottom"
Global Const $tagTVHITTESTINFO = "int X;int Y;int Flags;int Item"
Global Const $tagPOINT = "int X;int Y"
Global Const $tagMEMMAP = "hwnd hProc;int Size;ptr Mem"
Global Const $tagTOKEN_PRIVILEGES = "int Count;int64 LUID;int Attributes"
Global Const $tagLVITEM = "int Mask;int Item;int SubItem;int State;int StateMask;ptr Text;int TextMax;int Image;int Param;" & _
		"int Indent;int GroupID;int Columns;ptr pColumns"
Global Const $tagNMLISTVIEW = "hwnd hWndFrom;int IDFrom;int Code;int Item;int SubItem;int NewState;int OldState;int Changed;" & _
	"int ActionX;int ActionY;int Param"
		
; ---------------------------------------------------------------------------------------------
; Tab Constants
; ---------------------------------------------------------------------------------------------
Global Const $TCS_BUTTONS = 0x00000100
Global Const $TCS_FOCUSONBUTTONDOWN = 0x00001000
Global Const $TCS_FOCUSNEVER = 0x00008000
; ---------------------------------------------------------------------------------------------
; Button Constants
; ---------------------------------------------------------------------------------------------
Global Const $BS_ICON = 0x0040
Global Const $BS_FLAT = 0x8000
Global Const $BS_CENTER = 0x0300
Global Const $BS_PUSHLIKE = 0x1000
#EndRegion Constants

#Region GuiTreeView
; ---------------------------------------------------------------------------------------------
; GuiTreeview
; ---------------------------------------------------------------------------------------------
Global $__ghTVLastWnd
Global Const $__TREEVIEWCONSTANT_WM_SETREDRAW = 0x000B
Global Const $TVIF_IMAGE = 0x00000002
Global Const $TVIF_SELECTEDIMAGE = 0x00000020
Global Const $TVIS_SELECTED = 0x00000002
Global Const $TVIS_EXPANDED = 0x00000020
Global Const $TVS_HASBUTTONS = 0x00000001 ; Displays plus (+) and minus (-) buttons next to parent items
Global Const $TVS_HASLINES = 0x00000002 ; Uses lines to show the hierarchy of items
Global Const $TVS_LINESATROOT = 0x00000004 ; Uses lines to link items at the root of the control
Global Const $TVS_DISABLEDRAGDROP = 0x00000010 ; Prevents the from sending $TVN_BEGINDRAG notification messages
Global Const $TVGN_FIRSTVISIBLE = 0x00000005
Global Const $TVGN_ROOT = 0x00000000
Global Const $TVS_CHECKBOXES = 0x00000100 ; Enables check boxes for items
Global Const $TVN_FIRST = -400
Global Const $TVN_KEYDOWN = $TVN_FIRST - 12
Global Const $TV_FIRST = 0x1100
Global Const $TVM_ENSUREVISIBLE = $TV_FIRST + 20
Global Const $TVM_DELETEITEM = $TV_FIRST + 1
Global Const $TVM_GETITEMRECT = $TV_FIRST + 4
Global Const $TVM_GETITEMW = $TV_FIRST + 62
Global Const $TVM_GETIMAGELIST = $TV_FIRST + 8
Global Const $TVM_SETIMAGELIST = $TV_FIRST + 9
Global Const $TVM_GETNEXTITEM = $TV_FIRST + 10
Global Const $TVM_SELECTITEM = $TV_FIRST + 11
Global Const $TVM_HITTEST = $TV_FIRST + 17
Global Const $TVM_EXPAND = $TV_FIRST + 2
Global Const $TVM_GETITEMA = $TV_FIRST + 12
Global Const $TVM_SETITEMW = $TV_FIRST + 63
Global Const $TVM_SETITEMA = $TV_FIRST + 13
Global Const $TVM_SETITEM = $TVM_SETITEMA
Global Const $TVM_GETITEM = $TVM_GETITEMA
Global Const $TVHT_ONITEMSTATEICON = 0x00000040
Global Const $TVHT_ONITEMLABEL = 0x00000004
Global Const $TVGN_CARET = 0x00000009
Global Const $TVI_ROOT = 0xFFFF0000
Global Const $TVIF_STATE = 0x00000008
Global Const $TVIF_PARAM = 0x00000004
Global Const $TVE_COLLAPSE = 0x0001
Global Const $TVE_EXPAND = 0x0002
Global Const $TVGN_NEXT = 0x00000001
Global Const $TVGN_CHILD = 0x00000004

Func _GUICtrlTreeView_GetExpanded($hWnd, $hItem)
	Return BitAND(_GUICtrlTreeView_GetState($hWnd, $hItem), $TVIS_EXPANDED) <> 0
EndFunc   ;==>_GUICtrlTreeView_GetExpanded

Func _GUICtrlTreeView_GetState($hWnd, $hItem = 0)
	Local $tTVITEM, $iSize, $tMemMap, $pItem, $pMemory
	If $hItem = 0 Then $hItem = 0x00000000
	$hItem = _GUICtrlTreeView_GetItemHandle($hWnd, $hItem)
	If $hItem = 0x00000000 Then Return SetError(1, 1, 0)
	$tTVITEM = DllStructCreate($tagTVITEMEX)
	$pItem = DllStructGetPtr($tTVITEM)
	DllStructSetData($tTVITEM, "Mask", $TVIF_STATE)
	DllStructSetData($tTVITEM, "hItem", $hItem)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	If _WinAPI_InProcess($hWnd, $__ghTVLastWnd) Then
		_SendMessage($hWnd, $TVM_GETITEM, 0, $pItem)
	Else
		$iSize = DllStructGetSize($tTVITEM)
		$pMemory = _MemInit($hWnd, $iSize, $tMemMap)
		_MemWrite($tMemMap, $pItem)
		_SendMessage($hWnd, $TVM_GETITEM, 0, $pMemory)
		_MemRead($tMemMap, $pMemory, $pItem, $iSize)
		_MemFree($tMemMap)
	EndIf
	Return DllStructGetData($tTVITEM, "State")
EndFunc   ;==>_GUICtrlTreeView_GetState


Func _GUICtrlTreeView_HitTestItem($hWnd, $iX, $iY)
	Local $tHitTest
	$tHitTest = _GUICtrlTreeView_HitTestEx($hWnd, $iX, $iY)
	Return DllStructGetData($tHitTest, "Item")
EndFunc   ;==>_GUICtrlTreeView_HitTestItem

Func _GUICtrlTreeView_HitTestEx($hWnd, $iX, $iY)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	Local $iHitTest, $pHitTest, $tHitTest, $pMemory, $tMemMap
	$tHitTest = DllStructCreate($tagTVHITTESTINFO)
	$pHitTest = DllStructGetPtr($tHitTest)
	DllStructSetData($tHitTest, "X", $iX)
	DllStructSetData($tHitTest, "Y", $iY)
	If _WinAPI_InProcess($hWnd, $__ghTVLastWnd) Then
		_SendMessage($hWnd, $TVM_HITTEST, 0, $pHitTest, 0, "wparam", "ptr")
	Else
		$iHitTest = DllStructGetSize($tHitTest)
		$pMemory = _MemInit($hWnd, $iHitTest, $tMemMap)
		_MemWrite($tMemMap, $pHitTest)
		_SendMessage($hWnd, $TVM_HITTEST, 0, $pMemory, 0, "wparam", "ptr")
		_MemRead($tMemMap, $pMemory, $pHitTest, $iHitTest)
		_MemFree($tMemMap)
	EndIf
	Return $tHitTest
EndFunc   ;==>_GUICtrlTreeView_HitTestEx

Func _GUICtrlTreeView_SetState($hWnd, $hItem, $iState = 0, $iSetState = True)
	If Not IsHWnd($hItem) Then $hItem = _GUICtrlTreeView_GetItemHandle($hWnd, $hItem)
	If $hItem = 0x00000000 Or ($iState = 0 And $iSetState = False) Then Return False
	Local $tTVITEM = DllStructCreate($tagTVITEMEX)
	If @error Then Return SetError(1, 1, 0)
	DllStructSetData($tTVITEM, "Mask", $TVIF_STATE)
	DllStructSetData($tTVITEM, "hItem", $hItem)
	If $iSetState Then
		DllStructSetData($tTVITEM, "State", $iState)
	Else
		DllStructSetData($tTVITEM, "State", BitAND($iSetState, $iState))
	EndIf
	DllStructSetData($tTVITEM, "StateMask", $iState)
	If $iSetState Then DllStructSetData($tTVITEM, "StateMask", BitOR($iSetState, $iState))
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	Return _GUICtrlTreeView_SetItem($hWnd, $tTVITEM)
EndFunc   ;==>_GUICtrlTreeView_SetState

Func _GUICtrlTreeView_SetItem($hWnd, ByRef $tItem)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	Local $iItem, $pItem, $pMemory, $tMemMap, $iResult
	$pItem = DllStructGetPtr($tItem)
	If _WinAPI_InProcess($hWnd, $__ghTVLastWnd) Then
		$iResult = _SendMessage($hWnd, $TVM_SETITEMW, 0, $pItem, 0, "wparam", "ptr")
	Else
		$iItem = DllStructGetSize($tItem)
		$pMemory = _MemInit($hWnd, $iItem, $tMemMap)
		_MemWrite($tMemMap, $pItem)
		$iResult = _SendMessage($hWnd, $TVM_SETITEMW, 0, $pMemory, 0, "wparam", "ptr")
		_MemFree($tMemMap)
	EndIf
	Return $iResult = True
EndFunc   ;==>_GUICtrlTreeView_SetItem

Func _GUICtrlTreeView_BeginUpdate($hWnd)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	Return _SendMessage($hWnd, $__TREEVIEWCONSTANT_WM_SETREDRAW) = 0
EndFunc   ;==>_GUICtrlTreeView_BeginUpdate

Func _GUICtrlTreeView_EndUpdate($hWnd)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	Return _SendMessage($hWnd, $__TREEVIEWCONSTANT_WM_SETREDRAW, 1) = 0
EndFunc   ;==>_GUICtrlTreeView_EndUpdate

Func _GUICtrlTreeView_SelectItem($hWnd, $hItem, $iFlag = 0)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	If Not IsHWnd($hItem) Then $hItem = _GUICtrlTreeView_GetItemHandle($hWnd, $hItem)
	If $iFlag = 0 Then $iFlag = $TVGN_CARET
	Return _SendMessage($hWnd, $TVM_SELECTITEM, $iFlag, $hItem, 0, "wparam", "hwnd") <> 0
EndFunc   ;==>_GUICtrlTreeView_SelectItem

Func _GUICtrlTreeView_GetItemHandle($hWnd, $hItem = 0)
	Local $hTempItem
	If $hItem = 0 Then $hItem = 0x00000000
	If IsHWnd($hWnd) Then
		If $hItem = 0x00000000 Then $hItem = _SendMessage($hWnd, $TVM_GETNEXTITEM, $TVGN_ROOT, 0, 0, "wparam", "lparam", "hwnd")
	Else
		If $hItem = 0x00000000 Then
			$hItem = GUICtrlSendMsg($hWnd, $TVM_GETNEXTITEM, $TVGN_ROOT, 0)
		Else
			$hTempItem = GUICtrlGetHandle($hItem)
			If $hTempItem <> 0x00000000 Then $hItem = $hTempItem
		EndIf
	EndIf
	Return $hItem
EndFunc   ;==>_GUICtrlTreeView_GetItemHandle

Func _GUICtrlTreeView_Expand($hWnd, $hItem = 0, $fExpand = True)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	Local $hItem_tmp
	If $hItem = 0 Then $hItem = 0x00000000
	If $hItem = 0x00000000 Then
		$hItem = $TVI_ROOT
	Else
		If Not IsHWnd($hItem) Then
			$hItem_tmp = GUICtrlGetHandle($hItem)
			If $hItem_tmp <> 0x00000000 Then $hItem = $hItem_tmp
		EndIf
	EndIf
	If $fExpand Then
		_GUICtrlTreeView_ExpandItem($hWnd, $TVE_EXPAND, $hItem)
	Else
		_GUICtrlTreeView_ExpandItem($hWnd, $TVE_COLLAPSE, $hItem)
	EndIf
EndFunc   ;==>_GUICtrlTreeView_Expand

Func _GUICtrlTreeView_ExpandItem($hWnd, $iExpand, $hItem)
	Local $h_child
	If Not IsHWnd($hWnd) Then
		If $hItem = 0x00000000 Then
			$hItem = $TVI_ROOT
		Else
			$hItem = GUICtrlGetHandle($hItem)
			If $hItem = 0 Then Return
		EndIf
		$hWnd = GUICtrlGetHandle($hWnd)
	EndIf
	_SendMessage($hWnd, $TVM_EXPAND, $iExpand, $hItem, 0, "wparam", "hwnd")
	If $iExpand = $TVE_EXPAND And $hItem > 0 Then _SendMessage($hWnd, $TVM_ENSUREVISIBLE, 0, $hItem, 0, "wparam", "hwnd")
	$hItem = _SendMessage($hWnd, $TVM_GETNEXTITEM, $TVGN_CHILD, $hItem, 0, "wparam", "hwnd")
	While $hItem <> 0x00000000
		$h_child = _SendMessage($hWnd, $TVM_GETNEXTITEM, $TVGN_CHILD, $hItem, 0, "wparam", "hwnd")
		If $h_child <> 0x00000000 Then _GUICtrlTreeView_ExpandItem($hWnd, $iExpand, $hItem)
		$hItem = _SendMessage($hWnd, $TVM_GETNEXTITEM, $TVGN_NEXT, $hItem, 0, "wparam", "hwnd")
	WEnd
EndFunc   ;==>_GUICtrlTreeView_ExpandItem

Func _GUICtrlTreeView_GetItemParam($hWnd, $hItem = 0)
	Local $tItem, $hTempItem
	If $hItem = 0 Then $hItem = 0x00000000
	$tItem = DllStructCreate($tagTVITEMEX)
	DllStructSetData($tItem, "Mask", $TVIF_PARAM)
	DllStructSetData($tItem, "Param", 0)
	If IsHWnd($hWnd) Then
		; get the handle to item selected
		If $hItem = 0x00000000 Then $hItem = _SendMessage($hWnd, $TVM_GETNEXTITEM, $TVGN_CARET, 0, 0, "wparam", "lparam", "hwnd")
		If $hItem = 0x00000000 Then Return False
		DllStructSetData($tItem, "hItem", $hItem)
		; get the item properties
		If _SendMessage($hWnd, $TVM_GETITEMW, 0, DllStructGetPtr($tItem), 0, "wparam", "ptr") = 0 Then Return False
	Else
		; get the handle to item selected
		If $hItem = 0x00000000 Then
			$hItem = GUICtrlSendMsg($hWnd, $TVM_GETNEXTITEM, $TVGN_CARET, 0)
			If $hItem = 0x00000000 Then Return False
		Else
			$hTempItem = GUICtrlGetHandle($hItem)
			If $hTempItem <> 0x00000000 Then
				$hItem = $hTempItem
			Else
				Return False
			EndIf
		EndIf
		DllStructSetData($tItem, "hItem", $hItem)
		; get the item properties
		If GUICtrlSendMsg($hWnd, $TVM_GETITEMW, 0, DllStructGetPtr($tItem)) = 0 Then Return False
	EndIf
	Return DllStructGetData($tItem, "Param")
EndFunc   ;==>_GUICtrlTreeView_GetItemParam

Func _GUICtrlTreeView_DisplayRect($hWnd, $hItem, $fTextOnly = False)
	Local $aRect[4], $tRect
	$tRect = _GUICtrlTreeView_DisplayRectEx($hWnd, $hItem, $fTextOnly)
	$aRect[0] = DllStructGetData($tRect, "Left")
	$aRect[1] = DllStructGetData($tRect, "Top")
	$aRect[2] = DllStructGetData($tRect, "Right")
	$aRect[3] = DllStructGetData($tRect, "Bottom")
	Return SetError(@error, @error, $aRect)
EndFunc   ;==>_GUICtrlTreeView_DisplayRect

Func _GUICtrlTreeView_DisplayRectEx($hWnd, $hItem, $fTextOnly = False)
	Local $iRect, $pRect, $tRect, $pMemory, $tMemMap, $iResult
	$tRect = DllStructCreate($tagRECT)
	$pRect = DllStructGetPtr($tRect)
	If IsHWnd($hWnd) Then
		DllStructSetData($tRect, "Left", $hItem)
		If _WinAPI_InProcess($hWnd, $__ghTVLastWnd) Then
			$iResult = _SendMessage($hWnd, $TVM_GETITEMRECT, $fTextOnly, $pRect, 0, "wparam", "ptr")
		Else
			$iRect = DllStructGetSize($tRect)
			$pMemory = _MemInit($hWnd, $iRect, $tMemMap)
			_MemWrite($tMemMap, $pRect)
			$iResult = _SendMessage($hWnd, $TVM_GETITEMRECT, $fTextOnly, $pMemory, 0, "wparam", "ptr")
			_MemRead($tMemMap, $pMemory, $pRect, $iRect)
			_MemFree($tMemMap)
		EndIf
	Else
		If Not IsHWnd($hItem) Then $hItem = _GUICtrlTreeView_GetItemHandle($hWnd, $hItem)
		DllStructSetData($tRect, "Left", $hItem)
		$iResult = GUICtrlSendMsg($hWnd, $TVM_GETITEMRECT, $fTextOnly, $pRect)
	EndIf
	If $iResult = 0 Then DllStructSetData($tRect, "Left", 0)
	Return SetError($iResult = 0, $iResult = 0, $tRect)
EndFunc   ;==>_GUICtrlTreeView_DisplayRectEx

Func _GUICtrlTreeView_SetSelected($hWnd, $hItem, $fFlag = True)
	Return _GUICtrlTreeView_SetState($hWnd, $hItem, $TVIS_SELECTED, $fFlag)
EndFunc   ;==>_GUICtrlTreeView_SetSelected
#EndRegion GuiTreeView

#Region SendMessage
; ---------------------------------------------------------------------------------------------
; SendMessage
; ---------------------------------------------------------------------------------------------
Func _SendMessage($hWnd, $iMsg, $wParam = 0, $lParam = 0, $iReturn = 0, $wParamType = "wparam", $lParamType = "lparam", $sReturnType = "lparam")
	Local $aResult = DllCall("user32.dll", $sReturnType, "SendMessage", "hwnd", $hWnd, "int", $iMsg, $wParamType, $wParam, $lParamType, $lParam)
	If @error Then Return SetError(@error, @extended, "")
	If $iReturn >= 0 And $iReturn <= 4 Then Return $aResult[$iReturn]
	Return $aResult
EndFunc   ;==>_SendMessage

Func _SendMessageA($hWnd, $iMsg, $wParam = 0, $lParam = 0, $iReturn = 0, $wParamType = "wparam", $lParamType = "lparam", $sReturnType = "lparam")
	Local $aResult = DllCall("user32.dll", $sReturnType, "SendMessageA", "hwnd", $hWnd, "int", $iMsg, $wParamType, $wParam, $lParamType, $lParam)
	If @error Then Return SetError(@error, @extended, "")
	If $iReturn >= 0 And $iReturn <= 4 Then Return $aResult[$iReturn]
	Return $aResult
EndFunc   ;==>_SendMessageA
#EndRegion SendMessage
#Region WinAPI
; ---------------------------------------------------------------------------------------------
; WinAPI
; ---------------------------------------------------------------------------------------------
Global $winapi_gaInProcess[64][2] = [[0, 0]]
Global Const $__WINAPCONSTANT_TOKEN_ADJUST_PRIVILEGES = 0x00000020
Global Const $__WINAPCONSTANT_TOKEN_QUERY = 0x00000008
Global Const $__WINAPCONSTANT_FORMAT_MESSAGE_FROM_SYSTEM = 0x1000

Func _WinAPI_GetMousePos($fToClient = False, $hWnd = 0)
	Local $iMode, $aPos, $tPoint

	$iMode = Opt("MouseCoordMode", 1)
	$aPos = MouseGetPos()
	Opt("MouseCoordMode", $iMode)
	$tPoint = DllStructCreate($tagPOINT)
	DllStructSetData($tPoint, "X", $aPos[0])
	DllStructSetData($tPoint, "Y", $aPos[1])
	If $fToClient Then _WinAPI_ScreenToClient($hWnd, $tPoint)
	Return $tPoint
EndFunc   ;==>_WinAPI_GetMousePos

Func _WinAPI_ScreenToClient($hWnd, ByRef $tPoint)
	Local $aResult

	$aResult = DllCall("User32.dll", "int", "ScreenToClient", "hwnd", $hWnd, "ptr", DllStructGetPtr($tPoint))
	Return $aResult[0] <> 0
EndFunc   ;==>_WinAPI_ScreenToClient

Func _WinAPI_GetClassName($hWnd)
	Local $aResult
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	$aResult = DllCall("User32.dll", "int", "GetClassName", "hwnd", $hWnd, "str", "", "int", 4096)
	Return $aResult[2]
EndFunc   ;==>_WinAPI_GetClassName

Func _WinAPI_InProcess($hWnd, ByRef $hLastWnd)
	Local $iI, $iCount, $iProcessID

	If $hWnd = $hLastWnd Then Return True
	For $iI = $winapi_gaInProcess[0][0] To 1 Step -1
		If $hWnd = $winapi_gaInProcess[$iI][0] Then
			If $winapi_gaInProcess[$iI][1] Then
				$hLastWnd = $hWnd
				Return True
			Else
				Return False
			EndIf
		EndIf
	Next
	_WinAPI_GetWindowThreadProcessId($hWnd, $iProcessID)
	$iCount = $winapi_gaInProcess[0][0] + 1
	If $iCount >= 64 Then $iCount = 1
	$winapi_gaInProcess[0][0] = $iCount
	$winapi_gaInProcess[$iCount][0] = $hWnd
	$winapi_gaInProcess[$iCount][1] = ($iProcessID = @AutoItPID)
	Return $winapi_gaInProcess[$iCount][1]
EndFunc   ;==>_WinAPI_InProcess

Func _WinAPI_GetWindowThreadProcessId($hWnd, ByRef $iPID)
	Local $pPID, $tPID, $aResult

	$tPID = DllStructCreate("int ID")
	$pPID = DllStructGetPtr($tPID)
	$aResult = DllCall("User32.dll", "int", "GetWindowThreadProcessId", "hwnd", $hWnd, "ptr", $pPID)
	$iPID = DllStructGetData($tPID, "ID")
	Return $aResult[0]
EndFunc   ;==>_WinAPI_GetWindowThreadProcessId

Func _WinAPI_OpenProcess($iAccess, $fInherit, $iProcessID, $fDebugPriv = False)
	Local $hToken, $aResult

	; Attempt to open process with standard security priviliges
	$aResult = DllCall("Kernel32.dll", "int", "OpenProcess", "int", $iAccess, "int", $fInherit, "int", $iProcessID)
	If Not $fDebugPriv Or ($aResult[0] <> 0) Then
		_WinAPI_Check("_WinAPI_OpenProcess:Standard", ($aResult[0] = 0), 0, True)
		Return $aResult[0]
	EndIf

	; Enable debug privileged mode
	$hToken = _Security__OpenThreadTokenEx(BitOR($__WINAPCONSTANT_TOKEN_ADJUST_PRIVILEGES, $__WINAPCONSTANT_TOKEN_QUERY))
	_WinAPI_Check("_WinAPI_OpenProcess:OpenThreadTokenEx", @error, @extended)
	_Security__SetPrivilege($hToken, "SeDebugPrivilege", True)
	_WinAPI_Check("_WinAPI_OpenProcess:SetPrivilege:Enable", @error, @extended)

	; Attempt to open process with debug priviliges
	$aResult = DllCall("Kernel32.dll", "int", "OpenProcess", "int", $iAccess, "int", $fInherit, "int", $iProcessID)
	_WinAPI_Check("_WinAPI_OpenProcess:Priviliged", ($aResult[0] = 0), 0, True)

	; Disable debug privileged mode
	_Security__SetPrivilege($hToken, "SeDebugPrivilege", False)
	_WinAPI_Check("_WinAPI_OpenProcess:SetPrivilege:Disable", @error, @extended)
	_WinAPI_CloseHandle($hToken)

	Return $aResult[0]
EndFunc   ;==>_WinAPI_OpenProcess

Func _WinAPI_WriteProcessMemory($hProcess, $pBaseAddress, $pBuffer, $iSize, ByRef $iWritten, $sBuffer = "ptr")
	Local $pWritten, $tWritten, $aResult

	$tWritten = DllStructCreate("int Written")
	$pWritten = DllStructGetPtr($tWritten)
	$aResult = DllCall("Kernel32.dll", "int", "WriteProcessMemory", "int", $hProcess, "int", $pBaseAddress, $sBuffer, $pBuffer, _
			"int", $iSize, "int", $pWritten)
	_WinAPI_Check("_WinAPI_WriteProcessMemory", ($aResult[0] = 0), 0, True)
	$iWritten = DllStructGetData($tWritten, "Written")
	Return $aResult[0]
EndFunc   ;==>_WinAPI_WriteProcessMemory

Func _WinAPI_ReadProcessMemory($hProcess, $pBaseAddress, $pBuffer, $iSize, ByRef $iRead)
	Local $pRead, $tRead, $aResult

	$tRead = DllStructCreate("int Read")
	$pRead = DllStructGetPtr($tRead)
	$aResult = DllCall("Kernel32.dll", "int", "ReadProcessMemory", "int", $hProcess, "int", $pBaseAddress, "ptr", $pBuffer, "int", $iSize, "ptr", $pRead)
	_WinAPI_Check("_WinAPI_ReadProcessMemory", ($aResult[0] = 0), 0, True)
	$iRead = DllStructGetData($tRead, "Read")
	Return $aResult[0]
EndFunc   ;==>_WinAPI_ReadProcessMemory

Func _WinAPI_CloseHandle($hObject)
	Local $aResult

	$aResult = DllCall("Kernel32.dll", "int", "CloseHandle", "int", $hObject)
	_WinAPI_Check("_WinAPI_CloseHandle", ($aResult[0] = 0), 0, True)
	Return $aResult[0] <> 0
EndFunc   ;==>_WinAPI_CloseHandle

Func _WinAPI_Check($sFunction, $fError, $vError, $fTranslate = False)
	If $fError Then
		If $fTranslate Then $vError = _WinAPI_GetLastErrorMessage()
		_WinAPI_ShowError($sFunction & ": " & $vError)
	EndIf
EndFunc   ;==>_WinAPI_Check

Func _WinAPI_GetLastErrorMessage()
	Local $tText

	$tText = DllStructCreate("char Text[4096]")
	_WinAPI_FormatMessage($__WINAPCONSTANT_FORMAT_MESSAGE_FROM_SYSTEM, 0, _WinAPI_GetLastError(), 0, DllStructGetPtr($tText), 4096, 0)
	Return DllStructGetData($tText, "Text")
EndFunc   ;==>_WinAPI_GetLastErrorMessage

Func _WinAPI_GetLastError()
	Local $aResult

	$aResult = DllCall("Kernel32.dll", "int", "GetLastError")
	Return $aResult[0]
EndFunc   ;==>_WinAPI_GetLastError

Func _WinAPI_FormatMessage($iFlags, $pSource, $iMessageID, $iLanguageID, $pBuffer, $iSize, $vArguments)
	Local $aResult

	$aResult = DllCall("Kernel32.dll", "int", "FormatMessageA", "int", $iFlags, "hwnd", $pSource, "int", $iMessageID, "int", $iLanguageID, _
			"ptr", $pBuffer, "int", $iSize, "ptr", $vArguments)
	Return $aResult[0]
EndFunc   ;==>_WinAPI_FormatMessage

Func _WinAPI_ShowError($sText, $fExit = True)
	_WinAPI_MsgBox(266256, "Error", $sText)
	If $fExit Then Exit
EndFunc   ;==>_WinAPI_ShowError

Func _WinAPI_MsgBox($iFlags, $sTitle, $sText)
	BlockInput(0)
	MsgBox($iFlags, $sTitle, $sText & "      ")
EndFunc   ;==>_WinAPI_MsgBox

Func _WinAPI_GetCurrentThread()
	Local $aResult

	$aResult = DllCall("Kernel32.dll", "int", "GetCurrentThread")
	Return $aResult[0]
EndFunc   ;==>_WinAPI_GetCurrentThread
#EndRegion WinAPI

#Region Memory
; ---------------------------------------------------------------------------------------------
; Memory
; ---------------------------------------------------------------------------------------------
Global Const $__MEMORYCONSTANT_PROCESS_VM_OPERATION = 0x00000008
Global Const $__MEMORYCONSTANT_PROCESS_VM_READ = 0x00000010
Global Const $__MEMORYCONSTANT_PROCESS_VM_WRITE = 0x00000020

Global Const $MEM_RESERVE = 0x00002000
Global Const $MEM_COMMIT = 0x00001000
Global Const $MEM_SHARED = 0x08000000
Global Const $PAGE_READWRITE = 0x00000004
Global Const $MEM_RELEASE = 0x00008000

Func _MemInit($hWnd, $iSize, ByRef $tMemMap)
	Local $iAccess, $iAlloc, $pMemory, $hProcess, $iProcessID

	_WinAPI_GetWindowThreadProcessId($hWnd, $iProcessID)
	If $iProcessID = 0 Then _MemShowError("_MemInit: Invalid window handle [0x" & Hex($hWnd) & "]")

	$iAccess = BitOR($__MEMORYCONSTANT_PROCESS_VM_OPERATION, $__MEMORYCONSTANT_PROCESS_VM_READ, $__MEMORYCONSTANT_PROCESS_VM_WRITE)
	$hProcess = _WinAPI_OpenProcess($iAccess, False, $iProcessID, True)
	; Thanks to jpm for his tip on using @OSType instead of @OSVersion
	If @OSTYPE = "WIN32_WINDOWS"  Then
		$iAlloc = BitOR($MEM_RESERVE, $MEM_COMMIT, $MEM_SHARED)
		$pMemory = _MemVirtualAlloc(0, $iSize, $iAlloc, $PAGE_READWRITE)
	Else
		$iAlloc = BitOR($MEM_RESERVE, $MEM_COMMIT)
		$pMemory = _MemVirtualAllocEx($hProcess, 0, $iSize, $iAlloc, $PAGE_READWRITE)
	EndIf

	If $pMemory = 0 Then _MemShowError("_MemInit: Unable to allocate memory")
	$tMemMap = DllStructCreate($tagMEMMAP)
	DllStructSetData($tMemMap, "hProc", $hProcess)
	DllStructSetData($tMemMap, "Size", $iSize)
	DllStructSetData($tMemMap, "Mem", $pMemory)
	Return $pMemory
EndFunc   ;==>_MemInit

Func _MemWrite(ByRef $tMemMap, $pSrce, $pDest = 0, $iSize = 0, $sSrce = "ptr")
	Local $iWritten

	If $pDest = 0 Then $pDest = DllStructGetData($tMemMap, "Mem")
	If $iSize = 0 Then $iSize = DllStructGetData($tMemMap, "Size")
	Return _WinAPI_WriteProcessMemory(DllStructGetData($tMemMap, "hProc"), $pDest, $pSrce, $iSize, $iWritten, $sSrce)
EndFunc   ;==>_MemWrite

Func _MemVirtualAlloc($pAddress, $iSize, $iAllocation, $iProtect)
	Local $aResult

	$aResult = DllCall("Kernel32.dll", "ptr", "VirtualAlloc", "ptr", $pAddress, "int", $iSize, "int", $iAllocation, "int", $iProtect)
	Return SetError($aResult[0] = 0, 0, $aResult[0])
EndFunc   ;==>_MemVirtualAlloc

Func _MemVirtualAllocEx($hProcess, $pAddress, $iSize, $iAllocation, $iProtect)
	Local $aResult

	$aResult = DllCall("Kernel32.dll", "ptr", "VirtualAllocEx", "int", $hProcess, "ptr", $pAddress, "int", $iSize, "int", $iAllocation, "int", $iProtect)
	Return SetError($aResult[0] = 0, 0, $aResult[0])
EndFunc   ;==>_MemVirtualAllocEx

Func _MemRead(ByRef $tMemMap, $pSrce, $pDest, $iSize)
	Local $iRead

	Return _WinAPI_ReadProcessMemory(DllStructGetData($tMemMap, "hProc"), $pSrce, $pDest, $iSize, $iRead)
EndFunc   ;==>_MemRead

Func _MemFree(ByRef $tMemMap)
	Local $hProcess, $pMemory, $bResult

	$pMemory = DllStructGetData($tMemMap, "Mem")
	$hProcess = DllStructGetData($tMemMap, "hProc")
	; Thanks to jpm for his tip on using @OSType instead of @OSVersion
	If @OSTYPE = "WIN32_WINDOWS"  Then
		$bResult = _MemVirtualFree($pMemory, 0, $MEM_RELEASE)
	Else
		$bResult = _MemVirtualFreeEx($hProcess, $pMemory, 0, $MEM_RELEASE)
	EndIf
	_WinAPI_CloseHandle($hProcess)
	Return $bResult
EndFunc   ;==>_MemFree

Func _MemShowError($sText, $fExit = True)
	_MemMsgBox(16 + 4096, "Error", $sText)
	If $fExit Then Exit
EndFunc   ;==>_MemShowError

Func _MemMsgBox($iFlags, $sTitle, $sText)
	BlockInput(0)
	MsgBox($iFlags, $sTitle, $sText & "      ")
EndFunc   ;==>_MemMsgBox

Func _MemVirtualFree($pAddress, $iSize, $iFreeType)
	Local $aResult

	$aResult = DllCall("Kernel32.dll", "ptr", "VirtualFree", "ptr", $pAddress, "int", $iSize, "int", $iFreeType)
	Return $aResult[0]
EndFunc   ;==>_MemVirtualFree

Func _MemVirtualFreeEx($hProcess, $pAddress, $iSize, $iFreeType)
	Local $aResult

	$aResult = DllCall("Kernel32.dll", "ptr", "VirtualFreeEx", "hwnd", $hProcess, "ptr", $pAddress, "int", $iSize, "int", $iFreeType)
	Return $aResult[0]
EndFunc   ;==>_MemVirtualFreeEx
#EndRegion Memory

#Region Security
; ---------------------------------------------------------------------------------------------
; Security
; ---------------------------------------------------------------------------------------------
Global Const $ERROR_NO_TOKEN = 1008
Global Const $SE_PRIVILEGE_ENABLED = 0x00000002

Func _Security__OpenThreadTokenEx($iAccess, $hThread = 0, $fOpenAsSelf = False)
	Local $hToken

	$hToken = _Security__OpenThreadToken($iAccess, $hThread, $fOpenAsSelf)
	If $hToken = 0 Then
		If _WinAPI_GetLastError() = $ERROR_NO_TOKEN Then
			If Not _Security__ImpersonateSelf() Then Return SetError(-1, _WinAPI_GetLastError(), 0)
			$hToken = _Security__OpenThreadToken($iAccess, $hThread, $fOpenAsSelf)
			If $hToken = 0 Then Return SetError(-2, _WinAPI_GetLastError(), 0)
		Else
			Return SetError(-3, _WinAPI_GetLastError(), 0)
		EndIf
	EndIf
	Return SetError(0, 0, $hToken)
EndFunc   ;==>_Security__OpenThreadTokenEx

Func _Security__OpenThreadToken($iAccess, $hThread = 0, $fOpenAsSelf = False)
	Local $tData, $pToken, $aResult

	If $hThread = 0 Then $hThread = _WinAPI_GetCurrentThread()
	$tData = DllStructCreate("int Token")
	$pToken = DllStructGetPtr($tData, "Token")
	$aResult = DllCall("Advapi32.dll", "int", "OpenThreadToken", "int", $hThread, "int", $iAccess, "int", $fOpenAsSelf, "ptr", $pToken)
	Return SetError($aResult[0] = 0, 0, DllStructGetData($tData, "Token"))
EndFunc   ;==>_Security__OpenThreadToken

Func _Security__ImpersonateSelf($iLevel = 2)
	Local $aResult

	$aResult = DllCall("Advapi32.dll", "int", "ImpersonateSelf", "int", $iLevel)
	Return SetError($aResult[0] = 0, 0, $aResult[0] <> 0)
EndFunc   ;==>_Security__ImpersonateSelf

Func _Security__SetPrivilege($hToken, $sPrivilege, $fEnable)
	Local $pRequired, $tRequired, $iLUID, $iAttributes, $iCurrState, $pCurrState, $tCurrState, $iPrevState, $pPrevState, $tPrevState

	$iLUID = _Security__LookupPrivilegeValue("", $sPrivilege)
	If $iLUID = 0 Then Return SetError(-1, 0, False)

	$tCurrState = DllStructCreate($tagTOKEN_PRIVILEGES)
	$pCurrState = DllStructGetPtr($tCurrState)
	$iCurrState = DllStructGetSize($tCurrState)
	$tPrevState = DllStructCreate($tagTOKEN_PRIVILEGES)
	$pPrevState = DllStructGetPtr($tPrevState)
	$iPrevState = DllStructGetSize($tPrevState)
	$tRequired = DllStructCreate("int Data")
	$pRequired = DllStructGetPtr($tRequired)
	; Get current privilege setting
	DllStructSetData($tCurrState, "Count", 1)
	DllStructSetData($tCurrState, "LUID", $iLUID)
	If Not _Security__AdjustTokenPrivileges($hToken, False, $pCurrState, $iCurrState, $pPrevState, $pRequired) Then
		Return SetError(-2, @error, False)
	EndIf
	; Set privilege based on prior setting
	DllStructSetData($tPrevState, "Count", 1)
	DllStructSetData($tPrevState, "LUID", $iLUID)
	$iAttributes = DllStructGetData($tPrevState, "Attributes")
	If $fEnable Then
		$iAttributes = BitOR($iAttributes, $SE_PRIVILEGE_ENABLED)
	Else
		$iAttributes = BitAND($iAttributes, BitNOT($SE_PRIVILEGE_ENABLED))
	EndIf
	DllStructSetData($tPrevState, "Attributes", $iAttributes)
	If Not _Security__AdjustTokenPrivileges($hToken, False, $pPrevState, $iPrevState, $pCurrState, $pRequired) Then
		Return SetError(-3, @error, False)
	EndIf
	Return SetError(0, 0, True)
EndFunc   ;==>_Security__SetPrivilege

Func _Security__LookupPrivilegeValue($sSystem, $sName)
	Local $tData, $aResult

	$tData = DllStructCreate("int64 LUID")
	$aResult = DllCall("Advapi32.dll", "int", "LookupPrivilegeValue", "str", $sSystem, "str", $sName, "ptr", DllStructGetPtr($tData))
	Return SetError($aResult[0] = 0, 0, DllStructGetData($tData, "LUID"))
EndFunc   ;==>_Security__LookupPrivilegeValue

Func _Security__AdjustTokenPrivileges($hToken, $fDisableAll, $pNewState, $iBufferLen, $pPrevState = 0, $pRequired = 0)
	Local $aResult

	$aResult = DllCall("Advapi32.dll", "int", "AdjustTokenPrivileges", "hwnd", $hToken, "int", $fDisableAll, "ptr", $pNewState, _
			"int", $iBufferLen, "ptr", $pPrevState, "ptr", $pRequired)
	Return SetError($aResult[0] = 0, 0, $aResult[0] <> 0)
EndFunc   ;==>_Security__AdjustTokenPrivileges
#EndRegion Security

#Region Combo
Global Const $CB_GETCOUNT = 0x146
Global Const $CB_GETCURSEL = 0x147

Func _GUICtrlComboBox_GetCurSel($hWnd)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	Return _SendMessage($hWnd, $CB_GETCURSEL)+1
EndFunc   ;==>_GUICtrlComboBox_GetCurSel

Func _GUICtrlComboBox_GetCount($hWnd)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	Return _SendMessage($hWnd, $CB_GETCOUNT)
EndFunc   ;==>_GUICtrlComboBox_GetCount
#EndRegion Combo

#Region Edit
Global Const $ES_READONLY = 2048
Global Const $ES_AUTOVSCROLL = 64
Global Const $ES_WANTRETURN = 4096
Global Const $ES_MULTILINE = 4

Global Const $__EDITCONSTANT_SB_LINEDOWN = 1
Global Const $__EDITCONSTANT_SB_LINEUP = 0
Global Const $__EDITCONSTANT_SB_PAGEDOWN = 3
Global Const $__EDITCONSTANT_SB_PAGEUP = 2
Global Const $__EDITCONSTANT_SB_SCROLLCARET = 4
Global Const $__EDITCONSTANT_WM_GETTEXTLENGTH = 0x000E

Global Const $EM_LINESCROLL = 0xB6
Global Const $EM_SETSEL = 0xB1
Global Const $EM_SCROLLCARET = 0x00B7
Global Const $EM_SCROLL = 0xB5
Global Const $EM_REPLACESEL = 0xC2
Global Const $EM_LIMITTEXT = 0xC5
Global Const $EM_SETLIMITTEXT = $EM_LIMITTEXT

Func _GUICtrlEdit_LineScroll($hWnd, $iHoriz, $iVert)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	Return _SendMessage($hWnd, $EM_LINESCROLL, $iHoriz, $iVert) <> 0
EndFunc   ;==>_GUICtrlEdit_LineScroll

Func _GUICtrlEdit_Scroll($hWnd, $iDirection)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	If BitAND($iDirection, $__EDITCONSTANT_SB_LINEDOWN) <> $__EDITCONSTANT_SB_LINEDOWN And _
			BitAND($iDirection, $__EDITCONSTANT_SB_LINEUP) <> $__EDITCONSTANT_SB_LINEUP And _
			BitAND($iDirection, $__EDITCONSTANT_SB_PAGEDOWN) <> $__EDITCONSTANT_SB_PAGEDOWN And _
			BitAND($iDirection, $__EDITCONSTANT_SB_PAGEUP) <> $__EDITCONSTANT_SB_PAGEUP And _
			BitAND($iDirection, $__EDITCONSTANT_SB_SCROLLCARET) <> $__EDITCONSTANT_SB_SCROLLCARET Then Return 0
	If $iDirection == $__EDITCONSTANT_SB_SCROLLCARET Then
		Return _SendMessage($hWnd, $EM_SCROLLCARET)
	Else
		Return _SendMessage($hWnd, $EM_SCROLL, $iDirection)
	EndIf
EndFunc   ;==>_GUICtrlEdit_Scroll

Func _GUICtrlEdit_SetLimitText($hWnd, $iLimit)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	_SendMessageA($hWnd, $EM_SETLIMITTEXT, $iLimit)
EndFunc   ;==>_GUICtrlEdit_SetLimitText

Func _GUICtrlEdit_SetSel($hWnd, $iStart, $iEnd)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	_SendMessage($hWnd, $EM_SETSEL, $iStart, $iEnd)
EndFunc   ;==>_GUICtrlEdit_SetSel

Func _GUICtrlEdit_GetTextLen($hWnd)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	Return _SendMessage($hWnd, $__EDITCONSTANT_WM_GETTEXTLENGTH)
EndFunc   ;==>_GUICtrlEdit_GetTextLen

Func _GUICtrlEdit_AppendText($hWnd, $sText)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	Local $struct_MemMap, $struct_String, $sBuffer_pointer, $iLength
	$struct_String = DllStructCreate("char Text[" & StringLen($sText) + 1 & "]")
	$sBuffer_pointer = DllStructGetPtr($struct_String)
	DllStructSetData($struct_String, "Text", $sText)
	_MemInit($hWnd, StringLen($sText) + 1, $struct_MemMap)
	_MemWrite($struct_MemMap, $sBuffer_pointer)
	$iLength = _GUICtrlEdit_GetTextLen($hWnd)
	_GUICtrlEdit_SetSel($hWnd, $iLength, $iLength)
	_SendMessage($hWnd, $EM_REPLACESEL, True, $sBuffer_pointer, 0, "wparam", "ptr")
	_MemFree($struct_MemMap)
EndFunc   ;==>_GUICtrlEdit_AppendText
#EndRegion Edit

#Region Listview
Global $_lv_ghLastWnd
Global Const $LVS_SHOWSELALWAYS = 0x0008 ; The selection is always shown
Global Const $LVS_REPORT = 0x0001; This style specifies report view
Global Const $LVS_SORTASCENDING = 0x0010; Item indices are sorted based on item text in ascending order
Global Const $LVS_EDITLABELS = 0x0200 ; Item text can be edited in place
Global Const $LVS_SINGLESEL = 0x0004 ; Only one item at a time can be selected
Global Const $LVS_NOSORTHEADER = 0x8000 ; Column headers do not work like buttons
Global Const $LVS_EX_GRIDLINES = 0x00000001 ; Displays gridlines around items and subitems
Global Const $LVS_EX_FULLROWSELECT = 0x00000020 ; When an item is selected, the item and all its subitems are highlighted
Global Const $LVS_EX_INFOTIP = 0x00000400 ; A message is sent to the parent before displaying an item's ToolTip
Global Const $LVIF_IMAGE = 0x00000002
Global Const $LVIF_PARAM = 0x00000004
Global Const $LVIF_TEXT = 0x00000001
Global Const $LVM_FIRST = 0x1000
Global Const $LVM_GETITEMA = ($LVM_FIRST + 5)
Global Const $LVM_DELETEITEM = ($LVM_FIRST + 8)
Global Const $LVM_DELETEALLITEMS = ($LVM_FIRST + 9)
Global Const $LVM_GETITEMCOUNT = ($LVM_FIRST + 4)
Global Const $LVM_ENSUREVISIBLE = ($LVM_FIRST + 19)
Global Const $LVM_GETCOLUMNWIDTH = ($LVM_FIRST + 29)
Global Const $LVM_SETCOLUMNWIDTH = ($LVM_FIRST + 30)
Global Const $LVM_GETITEMSTATE = ($LVM_FIRST + 44)
Global Const $LVM_GETSUBITEMRECT = ($LVM_FIRST + 56)
Global Const $LVM_GETITEMW = ($LVM_FIRST + 75)
Global Const $LVM_SETITEMW = ($LVM_FIRST + 76)
Global Const $LVM_INSERTITEMW = ($LVM_FIRST + 77)
Global Const $LVM_MAPINDEXTOID = ($LVM_FIRST + 180)
Global Const $LVIS_SELECTED = 0x0002
Global Const $__LISTVIEWCONSTANT_WM_SETREDRAW = 0x000B
Global Const $LVN_FIRST = -100
Global Const $LVN_COLUMNCLICK = ($LVN_FIRST - 8) ; A column was clicked
Global Const $LVN_KEYDOWN = ($LVN_FIRST - 55)
Global Const $LVIR_BOUNDS = 0
Global Const $LVIR_ICON = 1


Func _GUICtrlListView_BeginUpdate($hWnd)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	Return _SendMessage($hWnd, $__LISTVIEWCONSTANT_WM_SETREDRAW) = 0
EndFunc   ;==>_GUICtrlListView_BeginUpdate

Func _GUICtrlListView_EndUpdate($hWnd)
	If Not IsHWnd($hWnd) Then $hWnd = GUICtrlGetHandle($hWnd)
	Return _SendMessage($hWnd, $__LISTVIEWCONSTANT_WM_SETREDRAW, 1) = 0
EndFunc   ;==>_GUICtrlListView_EndUpdate

Func _GUICtrlListView_EnsureVisible($hWnd, $iIndex, $fPartialOK = False)
	Return GUICtrlSendMsg($hWnd, $LVM_ENSUREVISIBLE, $iIndex, $fPartialOK)
EndFunc   ;==>_GUICtrlListView_EnsureVisible

Func _GUICtrlListView_GetSubItemRect($hWnd, $iIndex, $iSubItem, $iPart = 0)
	Local $iRect, $pRect, $tRect, $pMemory, $tMemMap, $aRect[4], $aPart[2] = [$LVIR_BOUNDS, $LVIR_ICON]
	$tRect = DllStructCreate($tagRECT)
	$pRect = DllStructGetPtr($tRect)
	DllStructSetData($tRect, "Top", $iSubItem)
	DllStructSetData($tRect, "Left", $aPart[$iPart])
	GUICtrlSendMsg($hWnd, $LVM_GETSUBITEMRECT, $iIndex, $pRect)
	$aRect[0] = DllStructGetData($tRect, "Left")
	$aRect[1] = DllStructGetData($tRect, "Top")
	$aRect[2] = DllStructGetData($tRect, "Right")
	$aRect[3] = DllStructGetData($tRect, "Bottom")
	Return $aRect
EndFunc   ;==>_GUICtrlListView_GetSubItemRect

Func _GUICtrlListView_InsertItem($hWnd, $sText, $iIndex = -1, $iImage = -1, $iParam = 0)
	Local $iBuffer, $pBuffer, $tBuffer, $iItem, $pItem, $tItem, $pMemory, $tMemMap, $pText, $iMask, $iResult
	If $iIndex = -1 Then $iIndex = 999999999
	$tItem = DllStructCreate($tagLVITEM)
	$pItem = DllStructGetPtr($tItem)
	DllStructSetData($tItem, "Param", $iParam)
	If $sText <> -1 Then
		$iBuffer = StringLen($sText) + 1
		$tBuffer = DllStructCreate("wchar Text[" & $iBuffer & "]")
		$pBuffer = DllStructGetPtr($tBuffer)
		DllStructSetData($tBuffer, "Text", $sText)
		DllStructSetData($tItem, "Text", $pBuffer)
		DllStructSetData($tItem, "TextMax", $iBuffer)
	Else
		DllStructSetData($tItem, "Text", -1)
	EndIf
	$iMask = BitOR($LVIF_TEXT, $LVIF_PARAM)
	If $iImage >= 0 Then $iMask = BitOR($iMask, $LVIF_IMAGE)
	DllStructSetData($tItem, "Mask", $iMask)
	DllStructSetData($tItem, "Item", $iIndex)
	DllStructSetData($tItem, "Image", $iImage)
	If IsHWnd($hWnd) Then
		If _WinAPI_InProcess($hWnd, $_lv_ghLastWnd) Or ($sText = -1) Then
			$iResult = _SendMessage($hWnd, $LVM_INSERTITEMW, 0, $pItem, 0, "wparam", "ptr")
		Else
			$iItem = DllStructGetSize($tItem)
			$pMemory = _MemInit($hWnd, $iItem + $iBuffer, $tMemMap)
			$pText = $pMemory + $iItem
			DllStructSetData($tItem, "Text", $pText)
			_MemWrite($tMemMap, $pItem, $pMemory, $iItem)
			_MemWrite($tMemMap, $pBuffer, $pText, $iBuffer)
			$iResult = _SendMessage($hWnd, $LVM_INSERTITEMW, 0, $pMemory, 0, "wparam", "ptr")
			_MemFree($tMemMap)
		EndIf
	Else
		$iResult = GUICtrlSendMsg($hWnd, $LVM_INSERTITEMW, 0, $pItem)
	EndIf
	Return $iResult
EndFunc   ;==>_GUICtrlListView_InsertItem

Func _GUICtrlListView_MapIndexToID($hWnd, $iIndex)
	If IsHWnd($hWnd) Then
		Return _SendMessage($hWnd, $LVM_MAPINDEXTOID, $iIndex)
	Else
		Return GUICtrlSendMsg($hWnd, $LVM_MAPINDEXTOID, $iIndex, 0)
	EndIf
EndFunc   ;==>_GUICtrlListView_MapIndexToID

Func _GUICtrlListView_SetItemParam($hWnd, $iIndex, $iParam)
	Local $tItem
	$tItem = DllStructCreate($tagLVITEM)
	DllStructSetData($tItem, "Mask", $LVIF_PARAM)
	DllStructSetData($tItem, "Item", $iIndex)
	DllStructSetData($tItem, "Param", $iParam)
	Return _GUICtrlListView_SetItemEx($hWnd, $tItem)
EndFunc   ;==>_GUICtrlListView_SetItemParam

Func _GUICtrlListView_SetItemEx($hWnd, ByRef $tItem)
	Local $iItem, $pItem, $iBuffer, $pBuffer, $pMemory, $tMemMap, $pText, $iResult
	$pItem = DllStructGetPtr($tItem)
	If IsHWnd($hWnd) Then
		$iItem = DllStructGetSize($tItem)
		$iBuffer = DllStructGetData($tItem, "TextMax")
		$pBuffer = DllStructGetData($tItem, "Text")
		$pMemory = _MemInit($hWnd, $iItem + $iBuffer, $tMemMap)
		$pText = $pMemory + $iItem
		DllStructSetData($tItem, "Text", $pText)
		_MemWrite($tMemMap, $pItem, $pMemory, $iItem)
		If $pBuffer <> 0 Then _MemWrite($tMemMap, $pBuffer, $pText, $iBuffer)
		$iResult = _SendMessage($hWnd, $LVM_SETITEMW, 0, $pMemory, 0, "wparam", "ptr")
		_MemFree($tMemMap)
	Else
		$iResult = GUICtrlSendMsg($hWnd, $LVM_SETITEMW, 0, $pItem)
	EndIf
	Return $iResult <> 0
EndFunc   ;==>_GUICtrlListView_SetItemEx

Func _GUICtrlListView_SetColumnWidth($hWnd, $iCol, $iWidth)
	If IsHWnd($hWnd) Then
		Return _SendMessage($hWnd, $LVM_SETCOLUMNWIDTH, $iCol, $iWidth)
	Else
		Return GUICtrlSendMsg($hWnd, $LVM_SETCOLUMNWIDTH, $iCol, $iWidth)
	EndIf
EndFunc   ;==>_GUICtrlListView_SetColumnWidth

Func _GUICtrlListView_GetItemCount($hWnd)
	If IsHWnd($hWnd) Then
		Return _SendMessage($hWnd, $LVM_GETITEMCOUNT)
	Else
		Return GUICtrlSendMsg($hWnd, $LVM_GETITEMCOUNT, 0, 0)
	EndIf
EndFunc   ;==>_GUICtrlListView_GetItemCount

Func _GUICtrlListView_DeleteAllItems($hWnd)
	Local $ctrlID, $index
	If _GUICtrlListView_GetItemCount($hWnd) == 0 Then Return True
	If IsHWnd($hWnd) Then
		Return _SendMessage($hWnd, $LVM_DELETEALLITEMS) <> 0
	Else
		For $index = _GUICtrlListView_GetItemCount($hWnd) - 1 To 0 Step -1
			$ctrlID = _GUICtrlListView_GetItemParam($hWnd, $index)
			If $ctrlID Then GUICtrlDelete($ctrlID)
		Next
		If _GUICtrlListView_GetItemCount($hWnd) == 0 Then Return True
	EndIf
	Return False
EndFunc   ;==>_GUICtrlListView_DeleteAllItems

Func _GUICtrlListView_GetItemParam($hWnd, $iIndex)
	Local $tItem
	$tItem = DllStructCreate($tagLVITEM)
	DllStructSetData($tItem, "Mask", $LVIF_PARAM)
	DllStructSetData($tItem, "Item", $iIndex)
	_GUICtrlListView_GetItemEx($hWnd, $tItem)
	Return DllStructGetData($tItem, "Param")
EndFunc   ;==>_GUICtrlListView_GetItemParam

Func _GUICtrlListView_GetItemEx($hWnd, ByRef $tItem)
	Local $iItem, $pItem, $pMemory, $tMemMap, $iResult
	$pItem = DllStructGetPtr($tItem)
	If IsHWnd($hWnd) Then
		If _WinAPI_InProcess($hWnd, $_lv_ghLastWnd) Then
			$iResult = _SendMessage($hWnd, $LVM_GETITEMW, 0, $pItem, 0, "wparam", "ptr")
		Else
			$iItem = DllStructGetSize($tItem)
			$pMemory = _MemInit($hWnd, $iItem, $tMemMap)
			_MemWrite($tMemMap, $pItem)
			_SendMessage($hWnd, $LVM_GETITEMW, 0, $pMemory, 0, "wparam", "ptr")
			_MemRead($tMemMap, $pMemory, $pItem, $iItem)
			_MemFree($tMemMap)
		EndIf
	Else
		$iResult = GUICtrlSendMsg($hWnd, $LVM_GETITEMW, 0, $pItem)
	EndIf
	Return $iResult <> 0
EndFunc   ;==>_GUICtrlListView_GetItemEx
#EndRegion Listview

#Region Array
Func _ArrayDelete(ByRef $avArray, $iElement)
	If Not IsArray($avArray) Then Return SetError(1, 0, 0)
	Local $iUBound = UBound($avArray, 1) - 1
	If Not $iUBound Then
		$avArray = ""
		Return 0
	EndIf
	; Bounds checking
	If $iElement < 0 Then $iElement = 0
	If $iElement > $iUBound Then $iElement = $iUBound
	; Move items after $iElement up by 1
	Switch UBound($avArray, 0)
		Case 1
			For $i = $iElement To $iUBound - 1
				$avArray[$i] = $avArray[$i + 1]
			Next
			ReDim $avArray[$iUBound]
		Case 2
			Local $iSubMax = UBound($avArray, 2) - 1
			For $i = $iElement To $iUBound - 1
				For $j = 0 To $iSubMax
					$avArray[$i][$j] = $avArray[$i + 1][$j]
				Next
			Next
			ReDim $avArray[$iUBound][$iSubMax + 1]
		Case Else
			Return SetError(3, 0, 0)
	EndSwitch
	Return $iUBound
EndFunc   ;==>_ArrayDelete

Func _ArraySort(ByRef $avArray, $iDescending = 0, $iStart = 0, $iEnd = 0, $iSubItem = 0)
	If Not IsArray($avArray) Then Return SetError(1, 0, 0)
	Local $iUBound = UBound($avArray) - 1
	; Bounds checking
	If $iEnd < 1 Or $iEnd > $iUBound Then $iEnd = $iUBound
	If $iStart < 0 Then $iStart = 0
	If $iStart > $iEnd Then Return SetError(2, 0, 0)
	; Sort
	Switch UBound($avArray, 0)
		Case 1
			__ArrayQuickSort1D($avArray, $iStart, $iEnd)
			If $iDescending Then _ArrayReverse($avArray, $iStart, $iEnd)
		Case 2
			Local $iSubMax = UBound($avArray, 2) - 1
			If $iSubItem > $iSubMax Then Return SetError(3, 0, 0)
			If $iDescending Then
				$iDescending = -1
			Else
				$iDescending = 1
			EndIf
			__ArrayQuickSort2D($avArray, $iDescending, $iStart, $iEnd, $iSubItem, $iSubMax)
		Case Else
			Return SetError(4, 0, 0)
	EndSwitch
	Return 1
EndFunc   ;==>_ArraySort

Func __ArrayQuickSort1D(ByRef $avArray, ByRef $iStart, ByRef $iEnd)
	If $iEnd <= $iStart Then Return
	Local $vTmp
	; InsertionSort (faster for smaller segments)
	If ($iEnd - $iStart) < 15 Then
		Local $i, $j, $vCur
		For $i = $iStart + 1 To $iEnd
			$vTmp = $avArray[$i]
			If IsNumber($vTmp) Then
				For $j = $i - 1 To $iStart Step -1
					$vCur = $avArray[$j]
					; If $vTmp >= $vCur Then ExitLoop
					If ($vTmp >= $vCur And IsNumber($vCur)) Or (Not IsNumber($vCur) And StringCompare($vTmp, $vCur) >= 0) Then ExitLoop
					$avArray[$j + 1] = $vCur
				Next
			Else
				For $j = $i - 1 To $iStart Step -1
					If (StringCompare($vTmp, $avArray[$j]) >= 0) Then ExitLoop
					$avArray[$j + 1] = $avArray[$j]
				Next
			EndIf
			$avArray[$j + 1] = $vTmp
		Next
		Return
	EndIf
	; QuickSort
	Local $L = $iStart, $R = $iEnd, $vPivot = $avArray[Int(($iStart + $iEnd) / 2)], $fNum = IsNumber($vPivot)
	Do
		If $fNum Then
			; While $avArray[$L] < $vPivot
			While ($avArray[$L] < $vPivot And IsNumber($avArray[$L])) Or (Not IsNumber($avArray[$L]) And StringCompare($avArray[$L], $vPivot) < 0)
				$L += 1
			WEnd
			; While $avArray[$R] > $vPivot
			While ($avArray[$R] > $vPivot And IsNumber($avArray[$R])) Or (Not IsNumber($avArray[$R]) And StringCompare($avArray[$R], $vPivot) > 0)
				$R -= 1
			WEnd
		Else
			While (StringCompare($avArray[$L], $vPivot) < 0)
				$L += 1
			WEnd
			While (StringCompare($avArray[$R], $vPivot) > 0)
				$R -= 1
			WEnd
		EndIf
		; Swap
		If $L <= $R Then
			$vTmp = $avArray[$L]
			$avArray[$L] = $avArray[$R]
			$avArray[$R] = $vTmp
			$L += 1
			$R -= 1
		EndIf
	Until $L > $R
	__ArrayQuickSort1D($avArray, $iStart, $R)
	__ArrayQuickSort1D($avArray, $L, $iEnd)
EndFunc   ;==>__ArrayQuickSort1D

Func __ArrayQuickSort2D(ByRef $avArray, ByRef $iStep, ByRef $iStart, ByRef $iEnd, ByRef $iSubItem, ByRef $iSubMax)
	If $iEnd <= $iStart Then Return
	; QuickSort
	Local $i, $vTmp, $L = $iStart, $R = $iEnd, $vPivot = $avArray[Int(($iStart + $iEnd) / 2)][$iSubItem], $fNum = IsNumber($vPivot)
	Do
		If $fNum Then
			; While $avArray[$L][$iSubItem] < $vPivot
			While ($iStep * ($avArray[$L][$iSubItem] - $vPivot) < 0 And IsNumber($avArray[$L][$iSubItem])) Or (Not IsNumber($avArray[$L][$iSubItem]) And $iStep * StringCompare($avArray[$L][$iSubItem], $vPivot) < 0)
				$L += 1
			WEnd
			; While $avArray[$R][$iSubItem] > $vPivot
			While ($iStep * ($avArray[$R][$iSubItem] - $vPivot) > 0 And IsNumber($avArray[$R][$iSubItem])) Or (Not IsNumber($avArray[$R][$iSubItem]) And $iStep * StringCompare($avArray[$R][$iSubItem], $vPivot) > 0)
				$R -= 1
			WEnd
		Else
			While ($iStep * StringCompare($avArray[$L][$iSubItem], $vPivot) < 0)
				$L += 1
			WEnd
			While ($iStep * StringCompare($avArray[$R][$iSubItem], $vPivot) > 0)
				$R -= 1
			WEnd
		EndIf
		; Swap
		If $L <= $R Then
			For $i = 0 To $iSubMax
				$vTmp = $avArray[$L][$i]
				$avArray[$L][$i] = $avArray[$R][$i]
				$avArray[$R][$i] = $vTmp
			Next
			$L += 1
			$R -= 1
		EndIf
	Until $L > $R
	__ArrayQuickSort2D($avArray, $iStep, $iStart, $R, $iSubItem, $iSubMax)
	__ArrayQuickSort2D($avArray, $iStep, $L, $iEnd, $iSubItem, $iSubMax)
EndFunc   ;==>__ArrayQuickSort2D

Func _ArrayReverse(ByRef $avArray, $iStart = 0, $iEnd = 0)
	If Not IsArray($avArray) Then Return SetError(1, 0, 0)
	Local $vTmp, $iUBound = UBound($avArray) - 1
	; Bounds checking
	If $iEnd < 1 Or $iEnd > $iUBound Then $iEnd = $iUBound
	If $iStart < 0 Then $iStart = 0
	If $iStart > $iEnd Then Return SetError(2, 0, 0)
	; Reverse
	For $i = $iStart To Int(($iStart + $iEnd - 1) / 2)
		$vTmp = $avArray[$i]
		$avArray[$i] = $avArray[$iEnd]
		$avArray[$iEnd] = $vTmp
		$iEnd -= 1
	Next
	Return 1
EndFunc   ;==>_ArrayReverse
#EndRegion Array
#Region Misc
; ---------------------------------------------------------------------------------------------
; Keypress-function ripped out of an included udf
; ---------------------------------------------------------------------------------------------
Func _IsPressed($p_String, $p_Dll = 'user32.dll')
	; $hexKey must be the value of one of the keys.
	; _Is_Key_Pressed will return 0 if the key is not pressed, 1 if it is.
	Local $Tmp1 = DllCall($p_Dll, "int", "GetAsyncKeyState", "int", '0x' & $p_String)
	If Not @error And BitAND($Tmp1[0], 0x8000) = 0x8000 Then Return 1
	Return 0
EndFunc   ;==>__IsPressed
#EndRegion Misc
#Region Math
; ---------------------------------------------------------------------------------------------
; Check if A can be devided by B (ripped out of the Math.au3-UDF bundled with AutoIt3)
; ---------------------------------------------------------------------------------------------
Func _MathCheckDiv($p_Text1, $p_Text2 = 2)
	If Number($p_Text1) = 0 Or Number($p_Text2) = 0 Or Int($p_Text1) <> $p_Text1 Or Int($p_Text2) <> $p_Text2 Then
		Return SetError(1, 0, -1)
	ElseIf Int($p_Text1 / $p_Text2) <> $p_Text1 / $p_Text2 Then
		Return 1
	Else
		Return 2
	EndIf
EndFunc   ;==>__MathCheckDiv
#EndRegion Math
