$debug_Handle=FileOpen($g_LogDir & '\BWS_Debug.txt', 1)
$debug_Line=StringSplit($debug_Line, ' ')
$debug_Skip='ineedthisdummy'
If UBound($debug_Line) < 3 Then FileWriteLine($debug_Handle, '$debug_Line has only one element:  ' & $debug_Line[1])
If UBound($debug_Line) > 2 Then
	For $debug_l=1 to $debug_Line[0] Step 2
		$debug_Var=$debug_Line[$debug_l]
		$debug_pDimension=$debug_Line[$debug_l+1]
		If IsDeclared(StringTrimLeft($debug_Var, 1)) Then
			$debug_EVar=Execute($debug_Var)
			$debug_rDimension=UBound($debug_EVar, 0)
			If $debug_rDimension > 0 Then FileWriteLine($debug_Handle, 'Size of 0. Dim. of '&$debug_Var&': '&$debug_rDimension)
			If $debug_rDimension = 1 And $debug_pDimension > 1 Then FileWriteLine($debug_Handle, 'Size of 0. Dim. of '&$debug_Var&' does not match expression.')
			If $debug_rDimension > 0 Then FileWriteLine($debug_Handle, 'Size of 1. Dim. of '&$debug_Var&': '&UBound($debug_EVar, 1))
			If $debug_rDimension = 1 Then
				$debug_output = ''
				For $debug_c = 0 to UBound($debug_EVar,1) - 1
					$debug_output = $debug_output & $debug_EVar[$debug_c] & ' || '
				Next
				FileWriteLine($debug_Handle, 'Value of 1. Dim. of '&$debug_Var &': '& StringTrimRight($debug_output, 4))
			EndIf
			If $debug_rDimension > 1 Then
				FileWriteLine($debug_Handle, 'Size of 2. Dim. of '&$debug_Var&': '&UBound($debug_EVar, 2))
				For $debug_r = 0 to UBound($debug_EVar,1) - 1
					$debug_output = ''
					For $debug_c = 0 to UBound($debug_EVar,2) - 1
						$debug_output = $debug_output & $debug_EVar[$debug_r][$debug_c] & " - "
					Next
					FileWriteLine($debug_Handle, 'Value of '&$debug_r&'. Dim. of '&$debug_Var &': '& StringTrimRight($debug_output, 4))
				Next
			EndIf
			If $debug_rDimension = 0 Then FileWriteLine($debug_Handle, 'Value of '&$debug_Var&': '&$debug_EVar)
		Else
			FileWriteLine($debug_Handle, 'Variable '&$debug_Var&' is not declared.')
		EndIf
	Next
EndIf
FileClose($debug_Handle)
