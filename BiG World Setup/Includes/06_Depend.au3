#include-once

; Note that you have to edit the functions when doing changes:
; _Depend_AutoSolve => solve problems right from start or in the dependency/connections-screen
; _Depend_Contextmenu => start solving the problems in the dependency/connections-screen
; _Depend_GetActiveConnections => build the list for the dependency/connections-screen after the selection

; _Depend_GetUnsolved => list mods that cannot be installed due to missing mods during download, extraction and installation
; _Depend_ListInstallConflicts => list mods that have conflicts during download, extraction and installation
; _Depend_ListInstallUnsolved => list mods that have open dependencies during download, extraction and installation

; Not used items from g_CentralArray: 5 - 6 - 7 - 8 - 11 - 12 - 14 - 15

;~ $g_CentralArray is an array of all mods/components from Select.txt, with the following fields:
;     0: mod setup-name
;     1: tag (theme/category number)
;     2: '-' for the headline (top level) of a mod, '+' for the top of a multiple choice menu,
;        '!' for a chapter headline, '####' comp-num for a component, '##?##_##' for a sub-component
;     3: component description (if 2 is '-' then this also will be '-')
;     4: name of the mod (from modname.ini) or '' if removed due to purge/translation
;     5: tree-view-item GUI handle
;     6: extended description of the mod (displayed below tree-view)
;     7: size (in bytes) of the mod, from mod.ini
;     8: language of the mod
;     9: number of active items (0 or 1 for a component; can be > 1 for a mod/chapter headline as it includes children)
;    10: for chapter headings, mods per chapter counter
;      / for mods, number of active components counter
;      / for components, 1 = member of a sub-tree, 0 = not member of a sub-tree, 2 = item is parent of its own sub-tree
;    11: type of the mod, from mod.ini
;    12: pre-selection bits (0000 to 1111)
;    13: blank '' or comma separated list of sections if mod is installed in different places
;    15: 'rev'ision of the mod, from mod.ini
;
;  _Tree_Populate calls _Tree_SelectRead or _Tree_SelectReadForBatch to initialize, then populates this array

;~ $g_Connections is an array of rules entries (derived from Game.ini), with the following fields:
;    0: inikey (rule descriptive text from left side of the equal sign '=')
;    1: inivalue (the rule, like C:A(-):B(-))
;    2: converted sentence (A is preferred to B)
;    3: the rule with mod names and components replaced with IDs (C:123|456&789&101|202:645&8910)
;         if user ignores this rule (via right-click menu), BWS will prefix this string with 'W'
;    4: 0/1 - was the rule a CW: or DW: warning (ignorable by the user)?
;
;  _Tree_Populate initializes, then calls _Depend_PrepareBuildIndex, _Depend_PrepareBuildSentences, _Depend_PrepareToUseID to populate array

;~ $g_ActiveConnections is an array of mod/component entries (derived by , with the following fields:
;    0: connection type ('C', 'DS', 'DO', 'DM')
;          C = this mod/component conflicts with all other mods/components in the array that have the same rule ID
;         DS = this mod/component is ACTIVE and is "in need" of other mods/components that are NOT active
;         DO = this mod/component is NOT active and is "needed" but OPTIONAL to satisfy the rule (has alternatives)
;         DM = this mod/component is NOT active and is "needed" and MANDATORY to satisfy the rule (no alternatives)
;    1: rule ID (index to the associated rule for this connection in $g_Connections)
;    2: control ID (index to the specific mod/component in $g_CentralArray for toggling status) or string if not found in Select.txt
;    3: sub-group (zero unless '&' for dependencies or ':' for conflicts splits the rule into non-zero 'sub-groups')
;
;  various methods call _Depend_GetActiveConnections to clear and (re-)populate this array after changes to selection
;
;  this array is only for mods/components involved in rules with unsolved conflicts or missing dependencies
;    connections for the same rule should be sequential in the array, "in need" followed by "needed"
;    connections from rules that have been right-click ignored by user will not be added to this array
;  note: the same mod/component can be added to the array multiple times if it is involved in more than one rule
;        - or (error case) if the same mod/component is on both sides of the rule - D:a(-):a(-) or C:b(-):b(-)

Func _Depend_PrepareBuildIndex($p_RuleLines, $p_Select)
; ---------------------------------------------------------------------------------------------
; Use install-order and assign the lines where the mod is mentioned in the [Connections]-section
;  p_RuleLines = copy of _IniReadSection($g_ConnectionsConfDir&'\Game.ini', 'Connections')
;					possibly after _Depend_TrimBWSConnections()
;		p_RuleLines[0][0] = number of connections-rule lines
;		p_RuleLines[N][0] = rule description text (inikey, left of =)
;		p_RuleLines[N][1] = the rule itself (inivalue, right of =), e.g. DW:a(-)&b(1|2):c(3)|d(4&5)
;  p_Select = output of _Tree_SelectRead or _Tree_SelectReadFromBatch - array of parsed lines from Select.txt, skipping ANN/CMD/GRP
;		p_Select[0][0] = number of entries
;		p_Select[0][1] = +1 each time the next line is a different mod (different mods or 1+ of mod's components installed separately)
;		p_Select[0][3] = +1 each time the next line is a different theme
;		p_Select[0][4] = number of tree-view items = Items+Mods+Themes+GUI-items+Error-Margin for wrong calculation
;		p_Select[N][0] = linetype (STD/MUC/SUB)
;		  1 >> Index (position of this line in the array, should always equal N in this case)
;		p_Select[N][2] = mod-setup-name
;		p_Select[N][3] = component number or sub-component answer
;		p_Select[N][4] = default pre-selection bits (0000 to 1111)
;		  5 >> Translation
;		p_Select[N][6] = component requirements
;		  7 >> Name
;		p_Select[N][8] = theme
;  $Return[0][0] = size of the index array (set to same size as $p_Select input array)
;  $Return[N][0] = mod setup-name
;  $Return[N][1] = '|'-separated list of mod setup-names or index-numbers
; ---------------------------------------------------------------------------------------------
	Local $p_Debug = 0
	If $p_Debug Then FileWrite($g_LogFile, @CRLF&'_Depend_PrepareBuildIndex starting $p_RuleLines[0][0]='&$p_RuleLines[0][0]&@CRLF)
	For $a=1 to $p_RuleLines[0][0]; create a list of the mod-setup-names listed in each rule from [Connections]-list (on either side)
		If $p_Debug Then FileWrite($g_LogFile, '_Depend_PrepareBuildIndex $p_RuleLines['&$a&'][0] for rule '&$p_RuleLines[$a][0])
		; replace p_RuleLines[$a][0] (rule description, left of '=' symbol) with p_RuleLines[$a][1] (rule itself, right of '=' symbol)
		;	for this index, the rule description is not needed, and we will replace the second slot [1] with a count
		; step 1 - trim rule type and first colon ':'									  DW:abc(-):def(1|3)&g(-) => abc(-):def(1|3)&g(-)
		; step 2 - trim components (anything contained in parentheses x28='(', x29=')')		 abc(-):def(1|3)&g(-) => abc:def&g
		; step 3 - replace any ':', '&' or '>' with '|' (x3a=':', x26='&', x3e='>')						abc:def&g => abc|def|g
		; step 4 - surround the string with '|' vertical bars on both sides so that we always find at least two '|' in the next step     
		$p_RuleLines[$a][0]='|'&StringRegExpReplace(StringRegExpReplace(StringRegExpReplace($p_RuleLines[$a][1], '\A.+?\x3a', ''), '\x28[^\x29]*\x29', ''), '\x3a|\x26|\x3e', '|')&'|'
		If $p_Debug Then FileWrite($g_LogFile, ' => '&$p_RuleLines[$a][0]&@CRLF)
		; step 5 - count the number of '|' (and subtract 1 because we added a trailing '|') to get the number of mod names in the rule
		Local $Test=StringRegExp($p_RuleLines[$a][0], '\x7c', 3); x7c = '|', 3 = return array of global matches
		$p_RuleLines[$a][1]=UBound($Test)-1; this is the number of mod-setup-names in the rule (the same name could be repeated multiple times)
	Next
	Local $Setups=$g_Setups; this is the array returned by _CreateList('s') defined in BiG World Setup.au3
	;		Setups[N][0] = mod-setup-name (ex. 1pp)
	;		Setups[N][1] = long mod name (ex. One Pixel Productions)
	;		Setups[N][2] = after next step, a list of '|'-separated indices into p_RuleLines from every rule that includes THIS entry's mod-setup-name
	;						indices into p_RuleLines are equivalent to indices into $g_Connections, i.e. pointers to conflict/dependency rules
	Local $Index=_IniCreateIndex($Setups); create a lookup-index for all known mod-setup-names, keyed on first letter
		; this index will point to the positions of the first and last mod-setup-name in $Setups that starts with the given letter
	For $a=1 to $p_RuleLines[0][0]; for each of the rules in p_RuleLines...
		Local $Mods=StringSplit($p_RuleLines[$a][0], '|'); split the mod-setup-names list from the previous step
		For $m=1 to $Mods[0]; for each of those mod-setup-names...
			If $Mods[$m]='' Then ContinueLoop; ignore blank mod-setup-names (shouldn't be any, but a typo in a rule could cause this)
			Local $Char = Asc(StringLower(StringLeft($Mods[$m], 1))); ASCII-symbol value of the first character in the mod-setup-name
			Local $Found=0
			For $s = $Index[$Char][1] To $Index[$Char][2]; search in $Setups from index of first mod-setup-name starting with $Char to index of last
				If $Setups[$s][0] = $Mods[$m] Then; if we found the same mod-setup-name in $Setups
					$Setups[$s][2] &= '|'&$a; then add the index to that mod-setup-name in $Setups to $Setups[N][2]
					$Found=1; we found a match for this mod-setup-name
					ExitLoop; we are done with this mod-setup-name; stop searching after first match is found in case there are duplicates
				EndIf
			Next
			If $p_Debug And Not $Found Then FileWrite($g_LogFile, '! _Depend_PrepareBuildIndex did not find ~'&$Mods[$m]&'~ in Select.txt'&@CRLF)
		Next
		If $p_Debug And StringInStr($p_RuleLines[$a][0], '||') Then FileWrite($g_LogFile, '!'&$p_RuleLines[$a][0]&' == '&$p_RuleLines[$a][1]&@CRLF)
		If $p_Debug And $a = $p_RuleLines[0][0] Then; it's the last iteration and debugging is enabled
			For $s = 1 To $Setups[0][0]; for each mod-setup-name from Select.txt that is in any rules, log the indices of the rules containing it
				If $Setups[$s][2] Then FileWrite($g_LogFile, '_Depend_PrepareBuildIndex $Setups['&$s&']'&$Setups[$s][1]&'='&$Setups[$s][2]&@CRLF)
			Next
		EndIf
	Next
	Local $PrevSetup, $Return[$p_Select[0][0]+1][2]
	For $a=1 to $p_Select[0][0]; scan through lines from Select.txt, copy mod setup-names into $Return[N][0]
		If $p_Select[$a][2] = $PrevSetup Then
			ContinueLoop
		Else; copy setup-mod-name to the index (no harm if duplicates - we will ignore them later)
			$Return[0][0] += 1
			$Return[$Return[0][0]][0]=$p_Select[$a][2]; $Return[N][0] = mod setup-name
			$PrevSetup = $p_Select[$a][2]
		EndIf
	Next
	ReDim $Return[$Return[0][0]+1][2]; trim the array ...
	If $p_Debug Then FileWrite($g_LogFile, '_Depend_PrepareBuildIndex $Return[0][0] = '&$Return[0][0]&@CRLF)
	; at this point, $Return[N][0] contains an array all of mod-setup-names from Select.txt, with some duplicates
	; at this point, $Setups[N][2] contains an '|'-separated array of indices into p_RuleLines for any mod-setup-names in a rule
	; 	indices into p_RuleLines are equivalent to indices into $g_Connections, i.e. pointers to conflict/dependency rules
	; goal is to identify connections (or better their index number) that may be connected to a mod into $Return[N][1]
	; this index will be used to speed up finding rules associated with this mod
	For $m = 1 to $Return[0][0]; for each mod-setup-name we copied from $p_Select...
		GUICtrlSetData($g_UI_Interact[9][1], 20*$m/$Return[0][0]); update the progress bar
		If _MathCheckDiv($m, 10) = 2 Then GUICtrlSetData($g_UI_Static[9][2], Round(20*$m/$Return[0][0], 0) & ' %'); update progress text
		Local $Char = Asc(StringLower(StringLeft($Return[$m][0], 1))); ASCII-symbol value of the first character in the mod-setup-name
		For $s = $Index[$Char][1] To $Index[$Char][2]; search in $Setups from index of first mod-setup-name starting with $Char to index of last
			If $Setups[$s][0] = $Return[$m][0] Then; if we found the same mod-setup-name in $Setups
				$Return[$m][1]=StringRegExpReplace($Setups[$s][2], '\A\x7c', ''); copy rule indices list and remove leading '|' if any
				If $p_Debug Then FileWrite($g_LogFile, '_Depend_PrepareBuildIndex $Return['&$m&'][0] = '&$Return[$m][0]&@CRLF)
				If $p_Debug Then FileWrite($g_LogFile, '_Depend_PrepareBuildIndex $Return['&$m&'][1] = '&$Return[$m][1]&@CRLF)
				ExitLoop; we are done with this mod-setup-name; stop searching after first match is found in case there are duplicates
			EndIf
		Next
	Next
	; $Return[0][0] now contains the number of mod-setup-names in the index (there may be some duplicate mod-setup-names)
	; $Return[N][0] now contains a mod-setup-name
	; $Return[N][1] now contains a '|'-separated array of indices to rules in $g_Connections that may be connected to a mod
	; 	(only the first entry for each mod-setup-name has a $Return[N][1] value, and only if that mod is part of some rules)
	Return $Return
EndFunc   ;==>_Depend_PrepareBuildIndex

Func _Depend_PrepareBuildSentences($p_RuleLines); called by _Tree_Populate and _Dep_ItemSave
; ---------------------------------------------------------------------------------------------
; Build [Connections]-array, strip warnings and build sentences to display for each rule
;  p_RuleLines = copy of _IniReadSection($g_ConnectionsConfDir&'\Game.ini', 'Connections')
;					possibly after _Depend_TrimBWSConnections()
;			or = [[1], [1, $Rule]] if called by _Dep_ItemSave
;		p_RuleLines[0][0] = number of connections-rule lines
;		p_RuleLines[N][0] = rule description text (inikey, left of =)
;		p_RuleLines[N][1] = the rule itself (inivalue, right of =), ex. DW:a(-)&b(1|2):c(3)|d(4&5)
;   Return[0][0] = number of rules entries
;	Return[N][0] = rule description (inikey)
;	Return[N][1] = rule itself, stripped of warning character (ex. DW:abc:def => D:abc:def)
;   Return[N][2] = user-readable translated sentence describing the rule (X needs Y etc.)
;		>> Return[N][3] = blank, will be filled by _Depend_PrepareToUseID
;	Return[N][4] = 1 if the rule had a warning character (DW: or CW: prefix), otherwise 0
; ---------------------------------------------------------------------------------------------
	Local $Message = IniReadSection($g_TRAIni, 'DP-BuildSentences')
	Local $Array, $LastMod='', $Return[$p_RuleLines[0][0]+1][5], $p_Debug = 0
	If $p_Debug Then FileWrite($g_LogFile, '_Depend_PrepareBuildSentences $p_RuleLines[0][0] = '&$p_RuleLines[0][0]&@CRLF)
	For $r=1 to $p_RuleLines[0][0]; for each rule in the array...
		$Return[0][0] += 1
		$Return[$r][0] = $p_RuleLines[$r][0]; copy rule description (inikey) from input array
		$Return[$r][1] = $p_RuleLines[$r][1]; copy rule itself (inivalue) from input array
		If StringInStr($Return[$r][1], ' ') Then
			_PrintDebug('! Error ! Invalid rule (whitespace) in Connections section of '&$g_ConnectionsConfDir&'\Game.ini: '&$Return[$r][0]&'='&$Return[$r][1], 1)
			Exit
		ElseIf StringInStr($Return[$r][1], '()') Then
			_PrintDebug('! Error ! Invalid rule (empty parentheses) in Connections section of '&$g_ConnectionsConfDir&'\Game.ini: '&$Return[$r][0]&'='&$Return[$r][1], 1)
			Exit
		EndIf
		If StringMid($Return[$r][1], 2, 1) = 'W' Then; strip warning character (DW => D, CW => C)
			$Return[$r][1]=StringLeft($Return[$r][1], 1)&StringMid($Return[$r][1], 3)
			$Return[$r][4]=1; remember that this was a warning rule (user-ignorable)
		EndIf
		; convert a copy of the rule into a user-readable translated sentence for $Return[$r][2]
		Local $String=StringTrimLeft($Return[$r][1], 2); first strip off the 'D:' or 'C:' prefix
		Local $Number, $LastSymbol=-1; keep track of the last symbol we find
		If StringLeft($Return[$r][1], 1) = 'C' Then; if it is a conflict rule...
			Local $Number=UBound(StringRegExp($String, '\x3e', 3))-1; number of '>' symbols in the rule
			If $Number > 0 Then
				$LastSymbol = StringInStr($String, '>', 1, -1); position of the last '>' in the rule
			EndIf
		Else; if it is a dependency rule
			Local $Number=UBound(StringRegExp($String, '(\x29\x7c)', 3))-1; number of x29=')', x7c='|' symbols
			If $Number > 0 Then
				$LastSymbol = StringInStr($String, ')|', 1, -1)+1; position of the last '|' in the rule 
			Else
				$Number=UBound(StringRegExp($String, '\x26', 3))-1
				If $Number > 0 Then
					$LastSymbol = StringInStr($String, '&', 1, -1); position of the last '&' in the rule
				EndIf
			EndIf
		EndIf
		Local $Array=StringSplit($String, '')
		Local $Current=''
		Local $FirstConflict=0
		Local $Mod=0
		For $a=1 to $Array[0]
			If $Array[$a] = ':' And StringLeft($Return[$r][1], 1) = 'C' Then
				If $FirstConflict = 0 Then
					$Current &= ' '&_GetTR($Message, 'L5')&' '; => is preferred
				Else
					$Current &= ' '&_GetTR($Message, 'L6')&' '; => and
				EndIf
				$FirstConflict=1
			ElseIf $Array[$a] = ':' Then
				If $Mod = 1 Then
					$Current &= ' '&_GetTR($Message, 'L1')&' '; => needs
				Else
					$Current &= ' '&_GetTR($Message, 'L2')&' '; => need
				EndIf
			ElseIf $Array[$a] = '(' Then
				$Mod+=1
				Local $Comp = ''
				While $Array[$a] <> ')'
					$a+=1
					$Comp &= $Array[$a]
				WEnd
				$Number=StringRegExp($Comp, '\x7c', 3)
				$Number=UBound($Number)-1
				If $Number >=0 Then
					If $Number > 0 Then $Comp=StringReplace($Comp, '|' , ', ', $Number)
					$Comp=StringReplace($Comp, '|' , ' '&_GetTR($Message, 'L3')&' '); => or
				EndIf
				If $Comp <> '-)' Then $Current &= ' ('&_GetTR($Message, 'L4')&' '&$Comp; => is
			ElseIf $Array[$a] = '>' Then
				If $FirstConflict = 0 Then
					$Current &= ' '&_GetTR($Message, 'L5')&' '; => is preferred (part I)
					$FirstConflict = 1
				Else
					If $a=$LastSymbol Then
						$Current &= ' '&_GetTR($Message, 'L6')&' '; => and
					Else
						$Current &= ', '
					EndIf
				EndIf
			ElseIf $Array[$a] = '|' Then
;				If $LastSymbol <> -1 Then
;					If $a=$LastSymbol Then
;						$Current &= ' '&_GetTR($Message, 'L3')&' '; => or
;					Else
;						$Current &= ', '
;					EndIf
;				Else
					$Current &= ' '&_GetTR($Message, 'L3')&' '; => or
;				EndIf
			ElseIf $Array[$a] = '&' Then
;				If $LastSymbol <> -1 Then
;					If $a=$LastSymbol Then
;						$Current &= ' '&_GetTR($Message, 'L6')&' '; => and
;					Else
;						$Current &= ', '
;					EndIf
;				Else
					$Current &= ' '&_GetTR($Message, 'L6')&' '; => and
;				EndIf
			Else
				$Current &= $Array[$a]
			EndIf
			If $a = $Array[0] Then
				If StringInStr($String, '&') And Not StringInStr($String, ':') Then
					$Current &= ' '&_GetTR($Message, 'L7'); => are installed together
				ElseIf StringLeft($Return[$r][1], 1) = 'C' Then
					If _GetTR($Message, 'L8') <> '.' Then $Current &= ' '&_GetTR($Message, 'L8'); => is preferred (part II)
				EndIf
				$Return[$r][2] = $Current&'.'
				If $p_Debug Then FileWrite($g_LogFile, '_Depend_PrepareBuildSentences $Return['&$r&'][2] = '&$Return[$r][2]&@CRLF)
			EndIf
		Next
	Next
	Return $Return
EndFunc   ;==>_Depend_PrepareBuildSentences

Func _Depend_PrepareToUseID($p_Array)
; ---------------------------------------------------------------------------------------------
; Process $g_Connections and split "mod-name(component number)" sub-strings
;   ex. C:modA(1|2|3):modB(1&2) => C:modA(1)|modA(2)|modA(3):modB(1)&modB(2)
; ---------------------------------------------------------------------------------------------
	Local $p_Debug = 0
	For $p=1 to $p_Array[0][0]
		Local $Bracket=StringRegExp($p_Array[$p][1], '\x28[^\x29]*\x29', 3); x28 = '(', x29=')'
		; $Bracket now contains an array of all '(...)' sub-strings in the current rule
		If Not IsArray($Bracket) Then
			$p_Array[$p][3]=$p_Array[$p][1]
			ContinueLoop
		EndIf
		For $b=0 To UBound($Bracket)-1
			Local $Sign=StringRegExp($Bracket[$b], '\x7c|\x26', 3)
			If Not IsArray($Sign) Then ContinueLoop
			Local $a=StringInStr($p_Array[$p][1], $Bracket[$b])-1
			Local $Mod='', $String='', $s=-1
			Local $Array=StringSplit($p_Array[$p][1], '')
			While Not StringRegExp($Array[$a], '\x3a|\x3e|\x7c|\x26') ; Get the :>|&
				$Mod=$Array[$a]&$Mod
				$a-=1
			WEnd
			Local $Num=StringSplit(StringRegExpReplace($Bracket[$b], '\A.|.\z', ''), '|&')
			For $n=1 to $Num[0]
				If $n <> 1 Then
					$s+=1
					$String &= $Sign[$s]&$Mod
				EndIf
				$String &= '('&$Num[$n]&')'
			Next
			$p_Array[$p][1]=StringReplace($p_Array[$p][1], $Bracket[$b], $String, 1)
		Next
		$p_Array[$p][3]=$p_Array[$p][1]
		If $p_Debug Then FileWrite($g_LogFile, '_Depend_PrepareToUseID $p_Array['&$p&'][3]='&$p_Array[$p][3]&@CRLF)
	Next
	Return $p_Array
EndFunc   ;==>_Depend_PrepareToUseID

; ---------------------------------------------------------------------------------------------
; 1. Prepare text listing all of the connections that are linked to a specific mod/component
; 2. Replace '$p_Setup($p_Comp)' substrings in $g_Connections with $p_TreeviewItemIdx
;	p_Array should be $g_Connections, passed by reference so we can modify it directly
;	p_TreeviewItemIdx = index of entry in $g_CentralArray corresponding to a tree-view item
;		this is $g_TreeviewItem[$cs][0] from _Tree_Populate
;	p_String = Return[N][1] from _Depend_PrepareBuildIndex -- array of indices to $g_Connection
;	  i.e., rules that might be connected to this mod/component = all rules that contain it
;	p_Setup = mod-setup-name associated with the p_TreeviewItem
;	p_Comp = list of '|'-separated components or '-' for any
; for each rule index in $p_String, get the associated rule from $g_Connections
;   then check if that rule contains $p_Setup with the specified component(s)
;     if it does, add a newline and the 'converted rule sentence' for the rule to $Return
;		also, if the rule is a warning rule (user ignorable), add ' **' after the sentence
;     then replace each substring in the rule that matches 'mod-setup-name(component)'
;       with the index of that mod/component in $g_CentralArray
; finally, if $Return contains any lines ending with two asterisks, add translated note below:
;	=> "** This is rather a notice of an inconsistency than a real issue/cause for bugs, so you may ignore this."
; ---------------------------------------------------------------------------------------------
Func _Depend_ItemGetConnections(ByRef $p_Array, $p_TreeviewItemIdx, $p_String, $p_Setup, $p_Comp='-')
	Local $Test, $Return='', $p_Debug = 0
	If $p_Debug Then FileWrite($g_LogFile, '_Depend_ItemGetConnections $p_TreeViewItemIdx='&$p_TreeViewItemIdx&', $p_String='&$p_String&', $p_Setup='&$p_Setup&', $p_Comp='&$p_Comp)
	$p_String=StringSplit($p_String, '|')
	Local $RegexComp = StringReplace($p_Comp, '?', '\x3f')
	If $p_Debug Then FileWrite($g_LogFile, ', $RegexComp='&$RegExComp&@CRLF)
	For $p=1 to $p_String[0]
		Local $r=$p_String[$p]; index to a rule in $g_Connections, one of the list of '|'-separated indices in $p_String
		If $p_Debug Then FileWrite($g_LogFile, ' $p_Array['&$r&'][3]='&$p_Array[$r][3]&@CRLF)
		; replace question mark (representing SUB-component) with unicode equivalent (x3f) for proper regex matching
		Local $Test=StringRegExp($p_Array[$r][3], '(?i)(\x3a|\x3e|\x7c|\x26)'&$p_Setup&'\x28'&$RegexComp&'\x29', 3); '\x3a|\x3e|\x7c|\x26' = :>|&
		If IsArray($Test) Then
			If $p_Debug Then FileWrite($g_LogFile, ' found '&UBound($Test)&' matches:'&@CRLF)
			$Return &= @CRLF & $p_Array[$r][2]
			If $p_Array[$r][4] = 1 Then $Return &= ' **'
			For $t=0 to UBound($Test)-1
				Local $PrevSymbol=StringLeft($Test[$t], 1)
				$p_Array[$r][3]=StringReplace($p_Array[$r][3], $PrevSymbol&$p_Setup&'('&$p_Comp&')', $PrevSymbol&$p_TreeviewItemIdx, 1)
			Next
			If $p_Debug Then FileWrite($g_LogFile, ' $p_Array['&$r&'][3]='&$p_Array[$r][3]&@CRLF)
		EndIf
	Next
	If StringRegExp($Return, '\x2a{2}(\z|\n)') Then $Return &= @CRLF&_GetTR($g_UI_Message, '4-L20')
	If $p_Debug Then FileWrite($g_LogFile, '_Depend_ItemGetConnections $Return='&$Return&@CRLF)
	Return $Return
EndFunc   ;==>_Depend_ItemGetConnections

; ---------------------------------------------------------------------------------------------
; Add entries to the array of active problems
; ---------------------------------------------------------------------------------------------
Func _Depend_ActiveAddItem($p_Type, $p_RuleID, $p_Setup, $SubGroup=0)
	Local $p_Debug=0
	$g_ActiveConnections[0][0]+=1
	$g_ActiveConnections[$g_ActiveConnections[0][0]][0]=$p_Type
	$g_ActiveConnections[$g_ActiveConnections[0][0]][1]=$p_RuleID
	$g_ActiveConnections[$g_ActiveConnections[0][0]][2]=$p_Setup
	$g_ActiveConnections[$g_ActiveConnections[0][0]][3]=$SubGroup
	If $p_Debug Then FileWrite($g_LogFile, '_Depend_ActiveAddItem:  p_Type='&$p_Type&', p_RuleID='&$p_RuleID&', p_Setup='&$p_Setup&', SubGroup='&$SubGroup&@CRLF)
EndFunc   ;==>_Depend_ActiveAddItem

; ---------------------------------------------------------------------------------------------
; Clear and fill $g_ActiveConnections array
; If $p_Show is true, display all conflicts and dependencies as needed (used during selection)
; ---------------------------------------------------------------------------------------------
Func _Depend_GetActiveConnections($p_Show=1)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Depend_GetActiveConnections')
	Global $g_ActiveConnections[9999][4]; initialize/clear active connections (will fill using _Depend_ActiveAddItem)
	$g_ActiveConnections[0][0] = 0; reset number of active connections counter to zero
	If $p_Show=1 Then _GUICtrlListView_BeginUpdate($g_UI_Handle[1])
	If $p_Show=1 Then _GUICtrlListView_DeleteAllItems($g_UI_Handle[1])
	Local $String
	For $c = 1 To $g_Connections[0][0]; loop through array of all Game.ini rules
		If StringLeft ($g_Connections[$c][3], 1) = 'W' Then; skip rules that have been right-click ignored by user
			ContinueLoop
		ElseIf StringLeft ($g_Connections[$c][3], 1) = 'D' Then; this is a dependency rule
			If StringMid($g_Connections[$c][3], 2, 1) = 'W' Then
				$String=StringTrimLeft($g_Connections[$c][3], 3)
			Else
				$String=StringTrimLeft($g_Connections[$c][3], 2)
			EndIf
			If Not StringInStr($String, ':') Then; all items are needed
				_Depend_GetActiveDependAll($String, $c, $p_Show)
			Else; some items need some other items
				_Depend_GetActiveDependAdv($String, $c, $p_Show)
			EndIf
		ElseIf StringLeft ($g_Connections[$c][3], 1) = 'C' Then; this is a conflict rule
			If StringMid($g_Connections[$c][3], 2, 1) = 'W' Then
				$String=StringTrimLeft($g_Connections[$c][3], 3)
			Else
				$String=StringTrimLeft($g_Connections[$c][3], 2)
			EndIf
			If StringInStr($String, ':') Then; this is an advanced conflict
				_Depend_GetActiveConflictAdv($String, $c, $p_Show)
			Else; this is a normal conflict
				_Depend_GetActiveConflictStd($String, $c, $p_Show)
			EndIf
		Else; this is an unknown type of connection
			_PrintDebug('+' & @ScriptLineNumber & ' Unknown type encountered in _Depend_GetActiveConnections: ' & $g_Connections[$c][3])
		EndIf
	Next
	If $p_Show=1 Then _GUICtrlListView_EndUpdate($g_UI_Handle[1])
EndFunc   ;==>_Depend_GetActiveConnections

; ---------------------------------------------------------------------------------------------
; Automatically solve dependencies and conflicts of provided type (used before and after selection)
;  p_Type = which type of connection to change (see comments above for $g_ActiveConnections)
;    C = change mods/components that conflict with the one that appears first in the list
;    DS = change mods/components that are active and have missing dependencies
;    DO = change first mod/component that can satisfy 
;  p_State = what to do with mods/components of specified type (1 = activate, 2 = deactivate)
;  p_skipWarnings = whether or not to skip user-ignorable rules (1 = skip, 0 = don't)
;  Return value will be an array with five fields:
;    Return[0][0] will be the number of changes made by this function
;    Return[N][0] will be the setup-name of a mod/component whose status this function changed
;    Return[N][1] will be the setup-name of a mod/component whose status this function changed
;    Return[N][2] will be the description of a component whose status this function changed
;    Return[N][3] will be the mod-name of a mod/component whose status this function changed
;
;   called from 10_Misc-GUI.au3 and 16_Select-Tree.au3
; ---------------------------------------------------------------------------------------------
Func _Depend_AutoSolve($p_Type, $p_State, $p_skipWarnings = 1)
	Local $Progress, $RuleID, $GroupID, $SubGroup, $Return[9999][4], $p_Debug=0
	If $p_Debug Then FileWrite($g_LogFile, 'starting _Depend_AutoSolve('&$p_Type&'_'&$p_State&'_'&$p_SkipWarnings&')'&@CRLF&@CRLF)
	_Depend_GetActiveConnections(0); build (or clear and rebuild) $g_ActiveConnections
	$g_Flags[23] = $g_ActiveConnections[0][0]; save original number of active connections for progress bar
	While 1
		Local $Restart=0
		If $p_Debug Then FileWrite($g_LogFile, @CRLF&'rebuilding active connections'&@CRLF)
		$Progress = $g_Flags[23] - $g_ActiveConnections[0][0]; how many connections we have removed since the last check
		If $Progress < 0 Then $g_Flags[23]=$g_ActiveConnections[0][0]; number of active connections has increased since we started -> use new count
		If $Progress > 0 And $g_Flags[23] <> 0 Then; avoid displaying negative progress and avoid division by zero
			$Progress=Round(($Progress*100)/$g_Flags[23], 0)
			GUICtrlSetData($g_UI_Interact[9][1], $Progress); update progress bar
			GUICtrlSetData($g_UI_Static[9][2], $Progress &  ' %'); update progress text
		EndIf
		For $a=1 to $g_ActiveConnections[0][0]; OUTER LOOP - check connection entries (each representing a particular mod/component)
			If $g_ActiveConnections[$a][0] <> $p_Type Then ContinueLoop; if the connection isn't the type we are looking for, skip it
			Local $RuleID=$g_ActiveConnections[$a][1]; else, save the current connection's associated rule ID (index to $g_Connections)
			If $p_skipWarnings And $g_Connections[$RuleID][4] = 1 Then ContinueLoop; optionally, skip if the rule is user-ignorable
			Local $SubGroup=$g_ActiveConnections[$a][3]; save the current connection's subgroup number (if any)
			If $p_Debug Then FileWrite($g_LogFile, @CRLF&'outer loop $a='&$a&' '&$g_ActiveConnections[$a][0]&' '&$g_ActiveConnections[$a][1]&' '&$g_ActiveConnections[$a][2]&' '&$SubGroup&' ~ '&$g_CentralArray[$g_ActiveConnections[$a][2]][4]&'('&$g_CentralArray[$g_ActiveConnections[$a][2]][3]&') rule('&$RuleID&'~'&$g_Connections[$RuleID][4]&')='&$g_Connections[$RuleID][1]&@CRLF)
			If $p_Type <> 'C' Then $a -= 1; for any connection type except conflict, back-step so the inner loop starts from current mod/component
			; because if it is a conflict, we never want to disable the first conflict (that's the preferred one), but if it is a dependency, we might
			Local $change_within_subgroup = 0
			While 1; INNER LOOP - iterate over following active connections (other mods/components)
				$a += 1; advance inner loop
				If $a > $g_ActiveConnections[0][0] Then ExitLoop ; we reached the end of the active connections array
				If $g_ActiveConnections[$a][1] <> $RuleID Then; check this FIRST -- saved rule ID doesn't match the rule ID of 'this' connection
					$a -= 1; we passed the last of the connections for the current rule - go back so outer loop (which steps +1) starts at this connection
					If $p_Debug Then FileWrite($g_LogFile, 'inner loop reached end of connections for rule '&$RuleID&@CRLF)
					ExitLoop; stop the inner loop - we are done scanning connections for the current mod/component
				EndIf
				If $p_Debug Then FileWrite($g_LogFile, 'inner loop $a='&$a&' '&$g_ActiveConnections[$a][0]&' '&$g_ActiveConnections[$a][1]&' '&$g_ActiveConnections[$a][2]&' '&$g_ActiveConnections[$a][3]&' ~ '&$g_CentralArray[$g_ActiveConnections[$a][2]][4]&'('&$g_CentralArray[$g_ActiveConnections[$a][2]][3]&')'&@CRLF)
				If $g_ActiveConnections[$a][0] <> $p_Type Then ContinueLoop; skip connections of different types than the type we are looking for
				If $p_Type = 'C' And $SubGroup <> 0 And $SubGroup = $g_ActiveConnections[$a][3] Then ContinueLoop; if multiple sub-groups, ignore conflicts within same sub-group
				If $p_Type = 'DO' And $change_within_subgroup And $SubGroup = $g_ActiveConnections[$a][3] Then
					$change_within_subgroup  = 0
					ContinueLoop; after changing the first optional dependency in a sub-group, skip to the next sub-group if any
				EndIf
				If $p_Debug Then FileWrite($g_LogFile, 'inner loop attempting to change status'&@CRLF)
				; if we reached this point, we found a connection for the 'saved' rule that has the type we want
				If Not _Depend_SetModState($g_ActiveConnections[$a][2], $p_State) then ExitLoop; activate or deactivate the mod/component
				; if we were unable to make a change, just keep going through other active connections (give up on automatically solving this one)
				$change_within_subgroup = 1
				$Return[0][0]+=1; else, the change succeeded -> record the change we just made
				$Return[$Return[0][0]][0]=$g_CentralArray[$g_ActiveConnections[$a][2]][0]; record mod setup-name
				$Return[$Return[0][0]][2]=$g_CentralArray[$g_ActiveConnections[$a][2]][4]; record mod name
				If $g_CentralArray[$g_ActiveConnections[$a][2]][2] <> '-' Then
					$Return[$Return[0][0]][1]=$g_CentralArray[$g_ActiveConnections[$a][2]][2]; record component type (MUC +, SUB ?)
					$Return[$Return[0][0]][3]=$g_CentralArray[$g_ActiveConnections[$a][2]][3]; record component description
				EndIf
				$Restart=1; we made a change, so we will need to rebuild $g_ActiveConnections and loop around again
				$SubGroup=$g_ActiveConnections[$a][3]; save the changed connection's 'sub-group' number for skipping purposes
				If $p_Debug Then FileWrite($g_LogFile, 'inner loop did not skip'&@CRLF)
			WEnd; INNER LOOP
		Next; OUTER LOOP
		; CHECK FOR COMPLETION
		If $Restart = 0 Then ExitLoop; we reached the end of the active connections array without making any changes -> jump to FINAL
;		For $r = 1 to $Return[0][0]; Prevent crashes... What crashes?
;			If $Return[$r][1] = '' Then
;				If $p_Debug Then FileWrite($g_LogFile, 'ERROR -- one of the recorded component types was blank ~ '&$Return[$r][0]&' ~ '&$Return[$r][2]&' ~ '&$Return[$r][1]&' ~ '&$Return[$r][3]&@CRLF&@CRLF)
;				ExitLoop; one of the recorded component types was blank -> jump to FINAL
;			EndIf
;		Next
		; else, loop around again
		_Depend_GetActiveConnections(0); clear and rebuild $g_ActiveConnections
	WEnd; restart loop
	; FINAL
	$g_Flags[23]=''; done with active connections count for progress bar
	GUICtrlSetData($g_UI_Static[9][2], '100 %'); update progress bar text to 100%
	If $p_Debug Then FileWrite($g_LogFile, 'ending _Depend_AutoSolve('&$p_Type&'_'&$p_State&'_'&$p_SkipWarnings&')'&@CRLF&@CRLF)
	ReDim $Return[$Return[0][0]+1][4]; trim any excess slots from the end of the return array
	If $Return[0][0] = 0 Then Return $Return; if we made no changes, return the empty array
	_Depend_CreateSortedOutput($Return); otherwise, sort the array of changes
	Return $Return
EndFunc   ;==>_Depend_AutoSolve

; ---------------------------------------------------------------------------------------------
; show the mods that would be removed. Reload saved settings if desired
;  p_Type =
;	3 - autosolve conflicts and dependencies
;	2 - autosolve dependencies
;	1 - autosolve conflicts
;  p_Force = whether to display 'this was forced' text
;  p_skipWarnings = whether to skip warning rules
; ---------------------------------------------------------------------------------------------
Func _Depend_AutoSolveWarning($p_Type, $p_Force=0, $p_skipWarnings=1)
	Local $Message = IniReadSection($g_TRAIni, 'DP-Msg')
	Local $Return, $Output = ''
	_Tree_GetCurrentSelection(1)
	; resolve conflicts before dependencies if resolving both
	If $p_Type = 1 or $p_Type = 3 Then; deactivate mods/components that conflict
		$Return=_Depend_AutoSolve('C', 2, $p_skipWarnings)
		If $Return[0][1] <> '' Then $Output &= _GetTR($Message, 'L3') & '|' & $Return[0][1] & '||'; => mod/component will be removed
	EndIf
	If $p_Type = 2 or $p_Type = 3 Then; activate mods/components that can satisfy missing dependencies
		;$Test = $g_Compilation
		;$g_Compilation = 'E'
		$Return=_Depend_AutoSolve('DM', 1, $p_skipWarnings)
		If $Return[0][1] <> '' Then $Output &= _GetTR($Message, 'L4') & '|' & $Return[0][1] & '||'; => mod/component will be added
		$Return=_Depend_AutoSolve('DO', 1, $p_skipWarnings)
		If $Return[0][1] <> '' Then $Output &= _GetTR($Message, 'L4') & '|' & $Return[0][1] & '||'; => mod/component will be added
		;$g_Compilation = $Test
	EndIf
	If $p_Type = 3 Then; deactivate any "in need of" mods/components that are still missing dependencies
		$Return=_Depend_AutoSolve('DS', 2, 1); never autosolve warning rules of this type
		If $Return[0][1] <> '' Then $Output &= _GetTR($Message, 'L3') & '|' & $Return[0][1] & '||'; => mod/component will be removed
	EndIf
	If $Output <> '' Then
		If $p_Force = 1 Then
			$Output =  _GetTR($Message, 'L6') & '||' & $Output; => auto-solve forced
		Else
			$Output &= _GetTR($Message, 'L5'); => proceed or go back?
		EndIf
		Local $Answer = _Misc_MsgGUI(2, _GetTR($g_UI_Message, '0-T1'), $Output, 2, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2')); => ok to continue with this result?
		If $Answer = 1 Then
			_Misc_SetTab(9); view progress-bar
			_Tree_Reload(); reload saved settings
			_Depend_GetActiveConnections(); reset view
			_Misc_SetTab(10); view connections-screen
			Return
		Else
			_Depend_GetActiveConnections(); just update connections list after changes
		EndIf
	Else; $Output = ''
		_PrintDebug('AutoSolve did not change anything', 1)
	EndIf
EndFunc   ;==>_Depend_AutoSolveWarning

; ---------------------------------------------------------------------------------------------
; Creates a context menu to solve dependencies and conflicts
; ---------------------------------------------------------------------------------------------
Func _Depend_Contextmenu()
	Local $MenuItem[10], $Message = IniReadSection($g_TRAIni, 'DP-Msg')
	Local $ClickSetting = $g_Compilation; save current click-setting
	$g_Compilation = 'E'; temporarily set click-setting to Expert
	GUISetState(@SW_DISABLE); disable the GUI itself while selection is pending to avoid unwanted treeview-changes
	$g_UI_Menu[0][4] = GUICtrlCreateContextMenu($g_UI_Menu[0][6]); create a context-menu on the clicked item
	Local $MenuLabel = _GetTR($Message, 'L2'); => mod
	GUICtrlCreateMenuItem($g_CentralArray[$g_UI_Menu[0][9]][4] , $g_UI_Menu[0][4])
	GUICtrlSetState(-1, $GUI_DISABLE)
	If $g_CentralArray[$g_UI_Menu[0][9]][3] <> '-' Then
		$MenuLabel = _GetTR($Message, 'L1'); => component
		GUICtrlCreateMenuItem($g_CentralArray[$g_UI_Menu[0][9]][2]&': '&$g_CentralArray[$g_UI_Menu[0][9]][3] , $g_UI_Menu[0][4])
		GUICtrlSetState(-1, $GUI_DISABLE)
	EndIf
	GUICtrlCreateMenuItem('', $g_UI_Menu[0][4])
; ---------------------------------------------------------------------------------------------
; Create the menu items
; ---------------------------------------------------------------------------------------------
	If $g_UI_Menu[0][7] = 'C' Then; Conflict
		If $g_CentralArray[$g_UI_Menu[0][9]][2] <> '-' Then
			$MenuItem[0] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M1'), _GetTR($Message, 'L1'), _GetTR($Message, 'M6')), $g_UI_Menu[0][4]); => item: remove conflicts > others (local)
			$MenuItem[1] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M1'), _GetTR($Message, 'L1'), _GetTR($Message, 'M7')), $g_UI_Menu[0][4]); => item: remove conflicts > others (global)
			$MenuItem[2] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M4'), _GetTR($Message, 'L1')), $g_UI_Menu[0][4]); => item: remove conflicts > itself (local)
			GUICtrlCreateMenuItem('', $g_UI_Menu[0][4])
			$MenuItem[3] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M1'), _GetTR($Message, 'L2'), _GetTR($Message, 'M7')), $g_UI_Menu[0][4]); => mod: remove conflicts > others (global)
			$MenuItem[4] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M2'), _GetTR($Message, 'M7')), $g_UI_Menu[0][4]); => mod: remove conflicts > itself (global)
			$MenuItem[5] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M4'), _GetTR($Message, 'L2')), $g_UI_Menu[0][4]); => mod: remove conflicts > itself (local)
		Else
			$MenuItem[0] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M1'), _GetTR($Message, 'L2'), _GetTR($Message, 'M6')), $g_UI_Menu[0][4]); => mod: remove conflicts > others (local)
			$MenuItem[3] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M1'), _GetTR($Message, 'L2'), _GetTR($Message, 'M7')), $g_UI_Menu[0][4]); => mod: remove conflicts > others (global)
			$MenuItem[2] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M4'), _GetTR($Message, 'L2')), $g_UI_Menu[0][4]); => mod: remove conflicts > itself (local)
		EndIf
	ElseIf $g_UI_Menu[0][7] = 'DS' Then; selected items that have open dependencies
		$MenuItem[0] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M3'), $MenuLabel), $g_UI_Menu[0][4]); => solve open dependencies
		$MenuItem[1] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M4'), $MenuLabel), $g_UI_Menu[0][4]); => remove mod itself
	ElseIf StringRegExp($g_UI_Menu[0][7], 'D(M|O)') Then; missing dependencies
		$MenuItem[0] = GUICtrlCreateMenuItem(StringFormat(_GetTR($Message, 'M5'), $MenuLabel), $g_UI_Menu[0][4]); => install the item
	EndIf
	If $g_Connections[$g_UI_Menu[0][8]][4]=1 Or $g_UI_Menu[0][7] = 'C' Then; if this is a dependency/conflict warning or a normal conflict
		GUICtrlCreateMenuItem('', $g_UI_Menu[0][4])
		$MenuItem[6] = GUICtrlCreateMenuItem(_GetTR($Message, 'M8'), $g_UI_Menu[0][4]); => ignore this problem
	EndIf; we are not allowing users to ignore normal dependency rules (D without W)
	__ShowContextMenu($g_UI[0], $g_UI_Menu[0][6], $g_UI_Menu[0][4])
; ---------------------------------------------------------------------------------------------
; Create another Msg-loop, since the GUI is disabled and only the menuitems should be available
; ---------------------------------------------------------------------------------------------
	$g_Flags[9] = 1; window is locked
	Local $Msg
	While 1
		$Msg = GUIGetMsg()
		If $Msg = 	$MenuItem[0] And $MenuItem[0] <> '' Then
			If $g_UI_Menu[0][7] = 'C' Then
				_Depend_SetGroupByNumber($g_UI_Menu[0][8], 2, $g_UI_Menu[0][9]); item or mod: remove conflicts > others (local)
			ElseIf $g_UI_Menu[0][7] = 'DS' Then
				_Depend_SetGroupByNumber($g_UI_Menu[0][8], 1); solve open dependencies
			Else
				_Depend_SetModState($g_UI_Menu[0][9], 1); install the item
			EndIf
			_Depend_GetActiveConnections()
			ExitLoop
		ElseIf $Msg =  $MenuItem[1] And $MenuItem[1] <> '' Then
			If $g_UI_Menu[0][7] = 'C' Then
				_Depend_SolveConflict($g_UI_Menu[0][9], 1); item: remove conflicts > others (global)
			ElseIf $g_UI_Menu[0][7] = 'DS' Then
				_Depend_SetModState($g_UI_Menu[0][9], 2); item or mod: remove mod itself
			EndIf
			_Depend_GetActiveConnections()
			ExitLoop
		ElseIf $Msg =  $MenuItem[2] And $MenuItem[2] <> '' Then
			_Depend_SetModState($g_UI_Menu[0][9], 2); item or mod: remove conflicts > itself (local)
			_Depend_GetActiveConnections()
			ExitLoop
		ElseIf $Msg =  $MenuItem[3] And $MenuItem[3] <> '' Then
			_Depend_SolveConflict($g_CentralArray[$g_UI_Menu[0][9]][0], 1, 1); mod: remove conflicts > others (global)
			_Depend_GetActiveConnections()
			ExitLoop
		ElseIf $Msg =  $MenuItem[4] And $MenuItem[4] <> '' Then
			_Depend_SolveConflict($g_CentralArray[$g_UI_Menu[0][9]][0], 2, 1); mod: remove conflicts > itself (global)
			_Depend_GetActiveConnections()
			ExitLoop
		ElseIf $Msg =  $MenuItem[5] And $MenuItem[5] <> '' Then
			_Depend_SetModState(_AI_GetStart($g_UI_Menu[0][9], '-'), 2); mod: remove conflicts > itself (local)
			_Depend_GetActiveConnections()
		ElseIf $Msg =  $MenuItem[6] And $MenuItem[6] <> '' Then; user wants to ignore this warning
			If $g_Connections[$g_UI_Menu[0][8]][4] = 0 Then; rule is not a notice/warning
				Local $Answer = _Misc_MsgGUI(3, _GetTR($g_UI_Message, '0-T1'), _GetTR($Message, 'L7'), 2, _GetTR($g_UI_Message, '0-B1'), _GetTR($g_UI_Message, '0-B2')); => Warning icon / Warning title / You have chosen to ignore a rule that is NOT marked as notice/warning. This could break the game! Unless you know exactly what you are doing, you should not ignore this rule. Are you absolutely sure you want to ignore this rule? / No / Yes
				If $Answer = 1 Then ExitLoop; 1 = No, 2 = Yes
				If $ClickSetting <> 'E' Then
					_Misc_MsgGUI(4, _GetTR($g_UI_Message, '0-T1'), _GetTR($Message, 'L8'), 1, _GetTR($g_UI_Message, '8-B2')); => Error icon / Warning title / You must go back and change your click-properties to Expert before you can ignore rules that are not marked as notice/warning. / Cancel
					ExitLoop
				EndIf
			EndIf
			$g_Connections[$g_UI_Menu[0][8]][3]= 'W'&$g_Connections[$g_UI_Menu[0][8]][3]; mark the rule as ignored
			_Depend_GetActiveConnections(); rebuild active connections (this rule will be skipped)
			ExitLoop
		ElseIf _IsPressed('01', $g_UDll) Then; react to a left mouseclick outside of the menu
			While _IsPressed('01', $g_UDll)
				Sleep(10)
			WEnd
			ExitLoop
		ElseIf _IsPressed('02', $g_UDll) Then; react to a right mouseclick outside of the menu
			While _IsPressed('02', $g_UDll)
				Sleep(10)
			WEnd
			ExitLoop
		EndIf
		Sleep(10)
	WEnd
	$g_Compilation = $ClickSetting; restore saved click-setting
	GUISetState(@SW_ENABLE); enable the GUI again
	GUICtrlDelete($g_UI_Menu[0][4])
	$g_Flags[16] = 0; 16=admin-lv has focus/treeicon clicked
	$g_Flags[9] = 0; 9=window is locked
EndFunc   ;==>_Depend_Contextmenu

; ---------------------------------------------------------------------------------------------
; Create a sorted output for message-boxes and others
;  p_Array[][0] = setup-name
;  p_Array[][1] = component-type ('', '+' MUC, '?' SUB, '-' if a mod, not a component)
;  p_Array[][2] = mod name
;  p_Array[][3] = component description or '-' if a mod, not a component
; ---------------------------------------------------------------------------------------------
Func _Depend_CreateSortedOutput(ByRef $p_Array)
	Local $Complete='|'
	$p_Array[0][1]=''
	_ArraySort($p_Array, 0, 1, 0, 1)
	For $p=1 to $p_Array[0][0]
		If $p_Array[$p][1] <> '' Then
			If $p <> 1 Then _ArraySort($p_Array, 0, 1, $p-1)
			_ArraySort($p_Array, 0, $p, 0)
			ExitLoop
		EndIf
		$Complete &= $p_Array[$p][0]&'|'
	Next
	Local $Current=''
	For $p=1 to $p_Array[0][0]
		If $p_Array[$p][1] <> '' And StringInStr($Complete, '|'&$p_Array[$p][0]&'|') Then ContinueLoop; don't show component if mod is shown
		If $Current <> $p_Array[$p][0] Then
			$p_Array[0][1] &= @CRLF&$p_Array[$p][2]
			If $p_Array[$p][1] = '' Then
				$p_Array[0][1] &= @CRLF
				ContinueLoop
			Else
				$p_Array[0][1] &= ':'&@CRLF
			EndIf
			$Current = $p_Array[$p][0]
		EndIf
		$p_Array[0][1] &= _Tree_SetLength($p_Array[$p][1]) & ': '& $p_Array[$p][3] & @CRLF
	Next
EndFunc   ;==>_Depend_CreateSortedOutput

; ---------------------------------------------------------------------------------------------
; Handle dependency rules without a ':' delimiter
; This is usually for rules like D:modA(1|2)&modB(3)|modC(-)
;   We interpret these to mean that ALL parts are "needed" ONLY if at least one part is ACTIVE
;     The example is equivalent to D:modA(1|2):modB(3)|modC(-) and D:modB(3)|modC(-):modA(1|2)
;     Therefore, to avoid duplication of parsing logic, we reuse the advanced parsing method
; Another case is dependency rules without '&' that contain '|', like D:a|b
;   For these rules, we interpret the rule to mean that at least one part is ALWAYS "needed"
; The third case is dependency rules without '&' or '|' - a single mod/component
;   Such rules are not considered valid so we print an error and exit BWS in this case
; ---------------------------------------------------------------------------------------------
Func _Depend_GetActiveDependAll($p_String, $p_RuleID, $p_Show)
	;check for a special case - game type can also be a dependency satisfying an OR condition
	If StringRegExp($p_String, '\x7c('&$g_Flags[14]&')\b') Then Return; found OR '|' followed by current game type -> do nothing
	;FileWrite($g_LogFile, 'DependAll before = ' & $p_String & @CRLF)
	If Not StringRegExp($p_String, '\x7c|\x26') Then; rule has neither '|' nor '&' (we must check this before we remove purged mods/components)
		_PrintDebug('! Error ! Invalid rule (only one mod/component) in Connections section of '&$g_ConnectionsConfDir&'\Game.ini: '&$g_Connections[$p_RuleID][0]&'='&$g_Connections[$p_RuleID][1], 1)
		Exit
	EndIf
	;eliminate from the rule any mod/components that haven't been converted to IDs (i.e., purged/missing translation/invalid)
	$p_String=StringRegExpReplace($p_String, '(?i)(\A|\x7c|\x26)[[:alnum:]_]+\x28.*\x29|[[:alnum:]_]+\x28.*\x29(\x7c|\x26|\z)', ''); x7c = |, x26 = &, x28/29 = ()
	If $p_String = '' Then Return; rule was completely purged -> not applicable to this game type
	;FileWrite($g_LogFile, 'DependAll after = ' & $p_String & @CRLF)
	If Not StringInStr($p_String, '&') And StringInStr($p_String, '|') Then; rule has only '|' -> at least one part is ALWAYS "needed"
		Local $ModComps=StringSplit($p_String, '|'); get array of individual mods/components separated by '|'
		For $m = 1 to $ModComps[0]; we are looking for any ACTIVE mod
			Local $ModCompState=_Depend_ItemGetSelected($ModComps[$m])
			If $ModCompState[0][1] <> 0 Then Return; if we found an ACTIVE mod/component -> this rule is satisfied
		Next
		Local $Prefix = '', $Warning = ''
		If $g_Connections[$p_RuleID][4]=1 Then $Warning=' **'; the rule we are checking is a 'DW'
		For $m = 1 to $ModComps[0]; else, we found no ACTIVE mods, so we need to add all as 'optional' dependencies
			If $p_Show=1 Then GUICtrlCreateListViewItem($Prefix & $g_CentralArray[$ModComps[$m]][4] & $Warning & '|' & $g_CentralArray[$ModComps[$m]][3], $g_UI_Interact[10][1]); mod name, component description
			If $p_Show=1 Then GUICtrlSetBkColor(-1, 0xFFA500)
			$Prefix = '/ '
			_Depend_ActiveAddItem('DO', $p_RuleID, $ModComps[$m], 1); only one subgroup so autosolve will change first only
		Next
		Return; we are done with this rule type
	EndIf
	Local $Parts=StringSplit($p_String, '&'); split the rule into '&'-subsets
	If @error Then Return; if no '&' in the rule then do nothing
	If $Parts[0] = 1 Then Return; only one part left in the rule (other parts were purged) -> rule is not applicable
	Local $Return=_Depend_ItemGetSelected($p_String)
	If $Return[0][1] = 0 Then Return; no parts are active -> rule is not applicable
	If $Return[0][1] = $Return[0][0] Then Return; all selected -> rule is satisfied
	; rule has only '&' -> ALL parts are "needed" ONLY if at least one part is ACTIVE
	For $SubGroup = 1 to $Parts[0]; this $SubGroup number is also used for adding dependency connections
		Local $ThisPart=_Depend_ItemGetSelected($Parts[$SubGroup])
		If $ThisPart[0][1] > 0 Then; at least one active mod/component in this part -> call _Depend_GetActiveDependAdv
			; for each part that is active, we treat it like an advanced rule of the form D:ThisPart:OtherParts
			; 1&2&3&4 -> 1:2&3&4, 2:1&3&4, 3:1&2&4, 4:1&2&3
			Local $OtherParts=''
			For $p=1 to $Parts[0]
				If $p <> $SubGroup Then
					$OtherParts &= $Parts[$p]&'&'
				EndIf
			Next
			$OtherParts=StringTrimRight($OtherParts, 1); remove trailing '&'
			Local $SubRule=$Parts[$SubGroup]&':'&$OtherParts
			_Depend_GetActiveDependAdv($SubRule, $p_RuleID, $p_Show)
			;_PrintDebug('_Depend_GetActiveDependAll called _Depend_GetActiveDependAdv('&$SubRule&') for original rule '&$p_String)
		EndIf
	Next
	Return; disable all code after this line -- old implementation
	Local $Prefix = ''
	Local $Warning = ''
	If $g_Connections[$p_RuleID][4]=1 Then $Warning=' **'
	For $r=1 to $Return[0][0]; show selected items first
		If $Return[$r][1]=1 Then
			If $p_Show=1 Then GUICtrlCreateListViewItem($Prefix&$g_CentralArray[$Return[$r][0]][4]&$Warning & '|' & $g_CentralArray[$Return[$r][0]][3], $g_UI_Interact[10][1])
			_Depend_ActiveAddItem('DS', $p_RuleID, $Return[$r][0])
			If $Prefix='' Then $Prefix='+ '
		EndIf
	Next
	$Prefix = ''; reset prefix
	For $r=1 to $Return[0][0]; then show the missing ones
		If $Return[$r][1]=0 Then
			Local $CompDesc, $ModName=$g_CentralArray[$Return[$r][0]][4]
			If $ModName = '' Then
				$ModName=$Return[$r][0]; mod setup-name & component ID string
				$CompDesc=_GetTR($g_UI_Message, '10-L1'); => removed due to purge/translation/invalid
			Else
				$CompDesc=$g_CentralArray[$Return[$r][0]][3]
			EndIf
			If $p_Show=1 Then GUICtrlCreateListViewItem($Prefix&$ModName&'|'&$CompDesc, $g_UI_Interact[10][1])
			_Depend_ActiveAddItem('DM', $p_RuleID, $Return[$r][0])
			If $p_Show=1 Then GUICtrlSetBkColor(-1, 0xFFA500)
			If $Prefix='' Then $Prefix='+ '
		EndIf
	Next
EndFunc    ;==>_Depend_GetActiveDependAll

; ---------------------------------------------------------------------------------------------
; Check if currently active/selected mods/components satisfy a provided dependency rule or not
; If conditions on the LEFT side of the rule (mods/components "in need") are unmet, do nothing
; If any conditions on the RIGHT side of the rule (mods/components "needed") are not met, then:
;  Add all active "in need" mods and inactive "needed" mods in the rule to $g_ActiveConnections
;  If $p_Show is true, build text for 'resolve dependencies' screen (display handled elsewhere)
;
; How do we interpret rules that contain combinations of AND '&' and OR '|'?
;
; Examples:
;
;  D:DrizztSaga(0|1)&InfinityAnimations(0):IAContent08(-)&IAContent01(-)&IAContent04(-)&IAContent05(-)
;    rule only applies if InfinityAnimations 0 is active AND DrizztSaga 0 or 1 is active
;  D:DrizztIsNotStupid(0)&DrizztSaga(0|1):DrizztSaga(3)
;    rule only applies if Drizzt Saga 0 or 1 is active AND DrizztIsNotStupid 0 is active
;
; What if multiple '&' and '|' are alternated in the rule?
;
; Consider an alternate form of the first rule:
;   D:DrizztSaga(0)&InfinityAnimations(0)|DrizztSaga(1)&InfinityAnimations(0):IAContent08(-)&IAContent01(-)&IAContent04(-)&IAContent05(-)
;     This rule is improperly written because the InfinityAnimations 0 component is repeated
;     It will be interpreted by BWS as Drizzt Saga 0 AND (Infinity Animations 0 or Drizzt Saga 1) AND Infinity Animations 0
;     If only Drizzt Saga 1 and Infinity Animations 0 are active, BWS will NOT require the dependencies (contrary to intent)
;
; Examples of '&' and '|' combinations on left side of dependency rule ('in need'):
;  D:aa|bb&cc:zz 		means that zz is needed only if cc AND (aa or bb) aew active
;  D:aa&bb|cc:zz 		means that zz is needed only if aa AND (bb or cc) are active
;  D:aa&bb|cc&dd:zz 	means that zz is needed only if aa AND (bb or cc) AND dd are active
;  D:aa|bb&cc&dd|ee:zz 	means that zz is needed only if (aa or bb) AND cc AND (dd or ee) are active
;
; Examples of '&' and '|' combinations on right side of dependency rule ('needed'):
;  D:aa:zz&xx|yy 		means that zz AND (xx or yy) are needed
;  D:aa:zz|xx&yy 		means that (zz or xx) AND yy are needed
;  D:aa:zz|xx&yy|ww 	means that (zz or xx) AND yy or ww are needed
;  D:aa:zz|xx&yy|ww&uu 	means that (zz or xx) AND (yy or ww) AND uu are needed
;    note the above rule does NOT mean "zz OR both xx and yy OR both ww and uu"
;
; Therefore: we split rules into 'and-group' sub-sets and require at least one from each set
; ---------------------------------------------------------------------------------------------
Func _Depend_GetActiveDependAdv($p_String, $p_RuleID, $p_Show)
	Local $p_Debug=0
	If $p_Debug Then FileWrite($g_LogFile, '_Depend_GADA_'&$p_RuleID&': $p_String = '&$p_String&' for '&$g_Connections[$p_RuleID][0]&'=D:'&$g_Connections[$p_RuleID][1]&@CRLF)
	$p_String=StringSplit($p_String, ':'); p_String will be a dependency rule like "123&456:789" without the "D:" prefix
	Local $Left=_Depend_ItemGetSelected($p_String[1]); otherwise, check which mods/components from the LEFT side of the dependency rule are active
	If $Left[0][1] = 0 Then Return; NOTHING on the LEFT side of the rule is active/selected, so the RIGHT side does not matter -> do nothing
	Local $Right=_Depend_ItemGetSelected($p_String[2]); check which mods/components from the RIGHT side of the dependency rule are active
	If $Right[0][0] = $Right[0][1] Then Return; if ALL mods/components on the RIGHT side of the rule are active, the rule is satisfied -> do nothing
	;check for a special case - game type can also be a dependency satisfying an OR condition
	If StringRegExp($p_String[2], '\x7c('&$g_Flags[14]&')\b') Then Return; found OR '|' followed by game type in dependencies -> do nothing
	; at this point, we know at least one mod/component on the LEFT is active, but there could still be unsatisfied '&' rules on the LEFT side
	; at this point, we know at least one mod/component on the RIGHT is inactive, but not necessarily a needed dependency (it could be an '|' rule)
	; now we need to evaluate the rule to check which conditions on the LEFT are satisfied and which conditions on the RIGHT are not satisfied
	; we only have two operators (AND/OR) -- if we had more, we would need a parser (http://effbot.org/zone/simple-top-down-parsing.htm)
	; to handle rules with combinations of AND/OR, we will split each side of the rule into parts separated by '&' operators
	; we will do two passes through both sides of the rule because we need to check conditions on both sides before adding connections
	Local $Prefix = '', $Warning = '', $countMissingDependencies=0
	If $g_Connections[$p_RuleID][4]=1 Then $Warning=' **'; the rule we are checking is a 'CW' or 'DW'
	For $secondPass = 0 to 1
		; evaluate the rule to check if conditions on the LEFT are satisfied and conditions on the RIGHT are not satisfied
		If $secondPass And $countMissingDependencies = 0 Then Return; first pass did not find any missing dependencies -> do nothing
		For $s = 1 to 2; outer loop to check LEFT side (1) followed by RIGHT side (2)
			$Prefix = ''; we need to clear the prefix (only used if $p_Show = 1) when we switch from LEFT side to RIGHT side
			Local $Parts=StringSplit($p_String[$s], '&'); we split the rule into '&'-subsets (this also works on strings without '&')
			For $SubGroup = 1 to $Parts[0]; this $SubGroup number is also used for adding dependency connections
				Local $ThisPart=_Depend_ItemGetSelected($Parts[$SubGroup]); this is inefficient but simpler than reusing $Left/$Right
				If $s = 1 Then; on the left side, we need at least one active mod in EVERY '&'-subset, else the entire rule does not apply
					If $ThisPart[0][1] = 0 Then Return; left side, no active mods/components in this part (which needs at least one) -> do nothing
					If $secondPass = 0 And $ThisPart[0][0] = $ThisPart[0][1] Then ContinueLoop; all mods/components are active -> check next part
					If $secondPass Then
						; if we reached this point, conditions on the LEFT side are met and there is at least one missing dependency on the RIGHT side
						$Prefix = ''
						For $t=1 to $ThisPart[0][0]; process mods/components "in need" (from the LEFT side of the rule)
							If $ThisPart[$t][1]=1 Then; only consider "in need" mods/components if they are ACTIVE
								If $p_Show=1 Then GUICtrlCreateListViewItem($Prefix & $g_CentralArray[$ThisPart[$t][0]][4] & $Warning & '|' & $g_CentralArray[$ThisPart[$t][0]][3], $g_UI_Interact[10][1]); mod name, component description
								_Depend_ActiveAddItem('DS', $p_RuleID, $ThisPart[$t][0]); add an "in need" connection from this mod/component
								$Prefix='+ '
							EndIf
						Next
					EndIf
				Else;If $s = 2 Then; on the right side, we need at least one inactive mod in ANY '&'-subset, else no missing dependencies
					If $ThisPart[0][1] > 0 Then ContinueLoop; at least one active mod/component in this part -> skip to next part
					Local $inActiveCount = $ThisPart[0][0]; - $ThisPart[0][1]; 'total in group' minus 'active in group' (we already checked none are active)
					$countMissingDependencies += $inActiveCount; we found at least one missing ('needed') dependency here
					For $t = 1 to $ThisPart[0][0]; iterate over inactive mods/components in this part
						If StringRegExp($ThisPart[$t][0], '\b(BG1EE|BG2EE)\b') Then ContinueLoop; don't add game type as a missing dependency!
						Local $InSelection=1, $Prefix = '', $CompDesc, $ModName=$g_CentralArray[$ThisPart[$t][0]][4]; mod long-name
						If $ModName = '' Then
							$InSelection=0
							$ModName=$ThisPart[$t][0]; mod setup-name & component ID string
							$CompDesc=_GetTR($g_UI_Message, '10-L1'); => removed due to purge/translation/invalid
							If $inActiveCount > 1 Or $Warning = ' **' Then $countMissingDependencies -= 1; don't count this one as a missing dependency
						Else
							$CompDesc=$g_CentralArray[$ThisPart[$t][0]][3]; component description
						EndIf
						If $secondPass Then
							If $inActiveCount = 1 Then; if it is the only missing dependency in this '&'-subset, it is MANDATORY
								If Not $InSelection And $Warning = ' **' Then ContinueLoop; skip if warning and not available due to purge/translation/invalid
								_Depend_ActiveAddItem('DM', $p_RuleID, $ThisPart[$t][0], $SubGroup); add MANDATORY dependency for this mod/component
								If $p_Show = 1 Then
									$Prefix='+ '
									GUICtrlCreateListViewItem($Prefix&$ModName&'|'&$CompDesc, $g_UI_Interact[10][1])
									GUICtrlSetBkColor(-1, 0xFFA500)
								EndIf
							ElseIf $inActiveCount > 1 Then; if it is one of multiple missing dependencies in this '&'-subset, it is OPTIONAL
								If $InSelection Then; for OPTIONAL connections, skip if not available for selection due to purge/translation/invalid
									_Depend_ActiveAddItem('DO', $p_RuleID, $ThisPart[$t][0], $SubGroup); add OPTIONAL dependency for this mod/component
									If $p_Show = 1 Then
										GUICtrlCreateListViewItem($Prefix&$ModName&'|'&$CompDesc, $g_UI_Interact[10][1])
										GUICtrlSetBkColor(-1, 0xFFA500)
										$Prefix='/ '
									EndIf
								EndIf
							EndIf; else $inActiveCount is 0 (we never encounter this case because we check earlier and skip)
						EndIf; secondPass
					Next; LOOP: check next mod/component
				Endif; left/right side
			Next; LOOP: check next '&'-subset 
		Next; LOOP: left side -> right side
	Next; LOOP: first pass -> second pass
EndFunc    ;==>_Depend_GetActiveDependAdv

; ---------------------------------------------------------------------------------------------
; See if a component is installed that has a conflict with a combination of other listed components
; ---------------------------------------------------------------------------------------------
Func _Depend_GetActiveConflictAdv($p_String, $p_RuleID, $p_Show)
	Local $p_Debug=0
	If $p_Debug Then FileWrite($g_LogFile, '_Depend_GACA_'&$p_RuleID&': $p_String = '&$p_String&' for '&$g_Connections[$p_RuleID][0]&'=C:'&$g_Connections[$p_RuleID][1]&@CRLF)
	If StringInStr($p_String, '>') Then
		_PrintDebug("! Error ! Invalid conflict rule (contains both '>' and ':') in Connections section of "&$g_ConnectionsConfDir&'\Game.ini: '&$Return[$r][0]&'='&$Return[$r][1], 1)
		Exit
	EndIf
	$p_String=StringSplit($p_String, ':')
	Local $Active, $Test[$p_String[0]+1][250]
	For $s=1 to $p_String[0]
		$Active=_Depend_ItemGetSelected($p_String[$s])
		For $r=1 to $Active[0][0]
			If StringInStr($p_String[$s], '&') And $Active[0][1] <> $Active[0][0] Then $r=$Active[0][0]; skip if all are required and not all are active
			If $Active[$r][1] = 1 Then
				$Test[$s][0]+=1
				$Test[$s][$Test[$s][0]]=$Active[$r][0]
			EndIf
		Next
		If $Test[$s][0] <> 0 Then $Test[0][0] += 1
	Next
	If $Test[0][0] <= 1 Then Return; no multiple conflicts were selected
	Local $IsConflict = 0
	Local $Warning = ''
	If $g_Connections[$p_RuleID][4]=1 Then $Warning=' **'
	For $s=1 to $p_String[0]
		If $Test[$s][0] <> 0 Then
			Local $Prefix = ''
			For $r=1 to $Test[$s][0]
				If $p_Show=1 Then GUICtrlCreateListViewItem($Prefix&$g_CentralArray[$Test[$s][$r]][4]&$Warning & '|' & $g_CentralArray[$Test[$s][$r]][3], $g_UI_Interact[10][1])
				_Depend_ActiveAddItem('C', $p_RuleID, $Test[$s][$r], $s)
				$Prefix='+ '
				If $p_Show=1 And $IsConflict = 1 Then GUICtrlSetBkColor(-1, 0xFF0000)
			Next
			$IsConflict = 1
			$Warning = ''
		EndIf
	Next
EndFunc    ;==>_Depend_GetActiveConflictAdv

; ---------------------------------------------------------------------------------------------
; See if a component is installed that has a conflict with other listed components
; ---------------------------------------------------------------------------------------------
Func _Depend_GetActiveConflictStd($p_String, $p_RuleID, $p_Show)
	Local $IsConflict = 0
	Local $Active=_Depend_ItemGetSelected($p_String)
	If $Active[0][1] = 0 or $Active[0][1] = 1 Then Return
	Local $Warning = ''
	If $g_Connections[$p_RuleID][4]=1 Then $Warning=' **'
	For $r=1 to $Active[0][0]
		If $Active[$r][1]=1 Then
			If $p_Show=1 Then GUICtrlCreateListViewItem($g_CentralArray[$Active[$r][0]][4]&$Warning & '|' & $g_CentralArray[$Active[$r][0]][3], $g_UI_Interact[10][1])
			_Depend_ActiveAddItem('C', $p_RuleID, $Active[$r][0])
			If $IsConflict = 0 Then
				$IsConflict=1
				$Warning=''
			Else
				If $p_Show=1 Then GUICtrlSetBkColor(-1, 0xFF0000)
			EndIf
		EndIf
	Next
EndFunc    ;==>_Depend_GetActiveConflictStd

; ---------------------------------------------------------------------------------------------
; Gather the mods and components that will not be able to be installed / are missing (used during download, extraction, installation)
; ---------------------------------------------------------------------------------------------
Func _Depend_GetUnsolved($p_Setup='', $p_Comp='')
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Depend_GetUnsolved')
	Local $Output, $Return[1][4], $String = '|'
	Local $Tmp[$g_CentralArray[0][0]-$g_CentralArray[0][1]+2][2]; fetch all the current selection-numbers and put them into an array
	For $a=$g_CentralArray[0][1] to $g_CentralArray[0][0]
		$Tmp[0][0]+=1
		$Tmp[$Tmp[0][0]][0]=$a
		$Tmp[$Tmp[0][0]][1]=$g_CentralArray[$a][9]
	Next
	; disable the mods that are listed as faults
	Local $Fault=IniReadSection($g_BWSIni, 'Faults')
	If IsArray($Fault) Then
		For $f=1 to $Fault[0][0]
			For $a=$g_CentralArray[0][1] to $g_CentralArray[0][0]
				If $g_CentralArray[$a][2] <> '-' Then ContinueLoop
				If $g_CentralArray[$a][0] = $Fault[$f][0] Then
					$String &= $g_CentralArray[$a][0]&'|'
					$Fault[$f][1]=$a
					_Depend_SetModState($a, 2)
					ExitLoop
				EndIf
			Next
		Next
	EndIf
	; also disable setups component if defined
	If $p_Setup <> '' Then
		For $a=$g_CentralArray[0][1] to $g_CentralArray[0][0]
			If $p_Setup = $g_CentralArray[$a][0] And $p_Comp = $g_CentralArray[$a][2] Then _AI_SetClicked($a, 2)
		Next
	EndIf
	; only list unsolved mods in the array & create some formatted output
	_Depend_GetActiveConnections(0); rebuild currently active connections
	If $g_ActiveConnections[0][0] <> 0 Then
		$Return=_Depend_AutoSolve('DS', 2, 1); remove all mods and components that have an open dependency (skip ignorable rules)
		If $Return[0][1] <> '' Then
			For $r =1 to $Return[0][0]
				If StringInStr($String, '|'&$Return[$r][0]&'|') Then
					$Return[$r][0]=''; don't show those that are missing - have already been displayed as they are in the faults-section
				Else
					$Return[0][2]+=1; increase counter for unsolved components/mods that depend on mods from faults-section
					For $s=0 to 3; re-arrange array
						$Return[$Return[0][2]][$s]=$Return[$r][$s]
					Next
				EndIf
			Next
		EndIf
		$Return[0][0]=$Return[0][2]; set new number of items in the array
		ReDim $Return[$Return[0][0]+1][4]
	EndIf
	If IsArray($Fault) Then $Return[0][2]+=$Fault[0][0]; set number of total "faulty" components/mods
	If $Return[0][1] <> '' Then _Depend_CreateSortedOutput($Return)
; reset the selection before the testing was done
	For $t=1 to $Tmp[0][0]
		$g_CentralArray[$Tmp[$t][0]][9]=$Tmp[$t][1]
	Next
	Return $Return; $Return[0][unsolved, output, missing + unsolved]
EndFunc   ;==>_Depend_GetUnsolved

; ---------------------------------------------------------------------------------------------
; Expects a rule 
; Just return an array of mod/component IDs and whether they are selected (active) or not
;  Return[0][0] = total number of mod/component IDs in the array
;  Return[0][1] = number of active mod/component IDs in the array
;  Return[N][0] = mod/component ID
;  Return[N][1] = 0/1 active/inactive
; ---------------------------------------------------------------------------------------------
Func _Depend_ItemGetSelected($p_String, $p_Debug=0)
	Local $Array
	If Not IsArray($p_String) Then
		$Array=StringSplit($p_String, ':|&>')
	Else
		$Array = $p_String
	EndIf
	Local $Return[$Array[0]+1][3]; create a return array with three values for each element in the split array
	$Return[0][0]=$Array[0]; set number of elements in return array equal to number of elements in split array
	$Return[0][1]=0; will be used to count the total number of active mods/components in the return array
	If $Array[0] = 0 Then Return $Return; array is empty
	For $a=1 to $Array[0]; loop
		$Return[$a][0]=$Array[$a]; copy next mod/component ID from split array into return array
		If $p_Debug Then FileWrite($g_LogFile, '_Depend_ItemGetSelected:  Array['&$a&'] = ' & $Array[$a] & '#active: '&$g_CentralArray[$Array[$a]][9]&' ~ modname: '&$g_CentralArray[$Array[$a]][4]&' ~ component? '&$g_CentralArray[$Array[$a]][3]&' ~ multi-install? '&$g_CentralArray[$Array[$a]][13]&@CRLF)
		If StringInStr($Array[$a], ')') Then; if item is not a number, it does not exist/is not available in this selection (might have been purged)
			$Return[$a][1]=0; so just mark this element in the return array as not-active and continue
		ElseIf $g_CentralArray[$Array[$a]][2] <> '-' Then; ID points to a single component (not a mod)
			$Return[$a][1]=$g_CentralArray[$Array[$a]][9]; 0 if component not active, 1 if active 
			$Return[0][1]+=$g_CentralArray[$Array[$a]][9]; add to count of active mods/components found
		Else;If $g_CentralArray[$Array[$a]][2] = '-' Then; ID points to a mod heading, not a component
			If $g_CentralArray[$Array[$a]][9] > 0 Then; at least one component of the mod is active, so no other tests are needed here
				$Return[$a][1]=1; 0 if not active, 1 if active - the mod is active, so 1
				$Return[0][1]+=1; add to count of active mods/components found
			ElseIf $g_CentralArray[$Array[$a]][13] <> '' Then; it is not active here, but components might be installed later in the installation
				Local $Splitted=StringSplit($g_CentralArray[$Array[$a]][13], ','); get the other possible selections and check them, too
				For $s=1 to $Splitted[0]
					If $g_CentralArray[$Splitted[$s]][9] > 0 Then; we found an active selection
						$Return[$a][1]=1
						$Return[0][1]+=1
						ExitLoop
					EndIf
				Next
			EndIf
		EndIf
		If $p_Debug Then ConsoleWrite('>'&$g_CentralArray[$Return[$a][0]][4] & ' - ' & $g_CentralArray[$Return[$a][0]][3] & @CRLF)
		If $p_Debug Then ConsoleWrite('-'&$Return[$a][0]& ' => ' & $Return[$a][1] & @CRLF)
	Next
	Return $Return
EndFunc   ;==>_Depend_ItemGetSelected

; ---------------------------------------------------------------------------------------------
; Returns a description-string
; ---------------------------------------------------------------------------------------------
Func _Depend_ListInstallAddItem($p_Setup, $p_Comp='-', $p_Num = 1)
	Local $Return = IniRead($g_MODIni, $p_Setup, 'Name', $p_Setup)
	If $p_Comp <> '-' Then $Return &= @CRLF & _Tree_SetLength($p_Comp) & ': '& _GetTra($p_Setup, $p_Comp)
	If $p_Num = 1 Then $Return &= ' ' & Chr(0xB9)
	If $p_Num = 2 Then $Return &= ' ' & Chr(0xB2)
	$Return &= @CRLF & @CRLF
	Return $Return
EndFunc   ;==>_Depend_AddDescription

; ---------------------------------------------------------------------------------------------
; Display all conflicts of a mods component, just for safety reasons if someone installed mods on his own (used during installation)
; ---------------------------------------------------------------------------------------------
Func _Depend_ListInstallConflicts($p_Setup, $p_Comp)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Depend_ListInstallConflicts')
	Local $Return
	If $g_ActiveConnections[0][0] = 0 Then Return
	For $g=1 to $g_ActiveConnections[0][0]
		If $g_ActiveConnections[$g][0] <> 'C' Then ContinueLoop; skip other stuff
		If $g_CentralArray[$g_ActiveConnections[$g][2]][0] <> $p_Setup Then ContinueLoop
		If $g_CentralArray[$g_ActiveConnections[$g][2]][2] <> $p_Comp Then ContinueLoop
		$Return &= $g_Connections[$g_ActiveConnections[$g][1]][2] & @CRLF
		Local $Current = $g, $Prefix = ''
		While $g_ActiveConnections[$g-1][1] = $g_ActiveConnections[$Current][1]; get to the starting-point
			$g -= 1
		WEnd
		While $g_ActiveConnections[$g+1][1] = $g_ActiveConnections[$Current][1]
			$g += 1
			If $g > $g_ActiveConnections[0][0] Then Return $Return
			If $g_CentralArray[$g_ActiveConnections[$g][2]][0] = $p_Setup And $g_CentralArray[$g_ActiveConnections[$g][2]][2] = $p_Comp Then ContinueLoop; don't display own component
			$Return &= $Prefix&_Depend_ListInstallAddItem($g_CentralArray[$g_ActiveConnections[$g][2]][0], $g_CentralArray[$g_ActiveConnections[$g][2]][2], 2)
			If $Prefix='' Then $Prefix='+ '
		WEnd
	Next
	Return $Return
EndFunc   ;==>_Depend_ListInstallConflicts

; ---------------------------------------------------------------------------------------------
; Display all unsolved dependencies, can be set to a mods component (used during installation)
; ---------------------------------------------------------------------------------------------
Func _Depend_ListInstallUnsolved($p_Setup, $p_Comp)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Depend_ListInstallUnsolved')
	Local $Return
	If $g_ActiveConnections[0][0] = 0 Then Return
	For $g=1 to $g_ActiveConnections[0][0]
		If $g_ActiveConnections[$g][0] <> 'DS' Then ContinueLoop; skip other stuff
		If $g_CentralArray[$g_ActiveConnections[$g][2]][0] <> $p_Setup Then ContinueLoop
		If $g_CentralArray[$g_ActiveConnections[$g][2]][2] <> '-' Then
			If $g_CentralArray[$g_ActiveConnections[$g][2]][2] <> $p_Comp Then ContinueLoop
		EndIf
		$Return &= $g_Connections[$g_ActiveConnections[$g][1]][2] & @CRLF
		Local $Current = $g, $Prefix = ''
		While $g_ActiveConnections[$g+1][1] = $g_ActiveConnections[$Current][1]
			$g += 1
			If $g > $g_ActiveConnections[0][0] Then Return $Return
			$Return &= $Prefix&_Depend_ListInstallAddItem($g_CentralArray[$g_ActiveConnections[$g][2]][0], $g_CentralArray[$g_ActiveConnections[$g][2]][2], 1)
			If $Prefix='' Then $Prefix='+ '
		WEnd
	Next
	Return $Return
EndFunc   ;==>_Depend_ListInstallUnsolved

; ---------------------------------------------------------------------------------------------
; Remove some mods or components from the current-section
; ---------------------------------------------------------------------------------------------
Func _Depend_RemoveFromCurrent($p_Array, $p_Comp=1)
	Local $String
	If Not IsArray($p_Array) Then Return
	For $a=1 to $p_Array[0][0]
		If $p_Array[$a][0]=''  Then ContinueLoop
		$p_Array[$a][1]=String($p_Array[$a][1])
		If $p_Comp = 0 Then $p_Array[$a][1]=''; force to remove the whole mod
		FileWrite($g_LogFile, 'Removing ' & $p_Array[$a][0] &' #' & $p_Array[$a][1] & @CRLF)
		If $p_Array[$a][1] = '' Then
			$Return=IniRead($g_UsrIni, 'RemovedFromCurrent', $p_Array[$a][0], '')
			IniWrite($g_UsrIni, 'RemovedFromCurrent', $p_Array[$a][0], $Return&' '&IniRead($g_UsrIni, 'Current', $p_Array[$a][0], '')); add to mods that are listed as not installed
			IniDelete($g_UsrIni, 'Current', $p_Array[$a][0]); remove from current list of mods to install
			IniDelete($g_BWSIni, 'Faults', $p_Array[$a][0]); remove faults
			$String &= '|'&$p_Array[$a][0]
			$File=_Test_GetCustomTP2($p_Array[$a][0]); remove mods that are uninstallable
			If FileExists($File) Then FileMove($File, $File&'.dlt', 1)
		Else
			$Return=IniRead($g_UsrIni, 'RemovedFromCurrent', $p_Array[$a][0], '')
			If StringRegExp($Return, '(\A|\s)'&$p_Array[$a][1]&'(\s|\z)', ' ') = 0 Then $Return &= ' '&$p_Array[$a][1]; add component if not included
			IniWrite($g_UsrIni, 'RemovedFromCurrent', $p_Array[$a][0], $Return)
			$Return=IniRead($g_UsrIni, 'Current', $p_Array[$a][0], '')
			$Return=StringStripWS(StringRegExpReplace($Return, '(\A|\s)'&$p_Array[$a][1]&'(\s|\z)', ' '), 3)
			If $Return = '' Then; remove entry or write new value of mod
				IniDelete($g_UsrIni, 'Current', $p_Array[$a][0])
				$String &= '|'&$p_Array[$a][0]
			Else
				IniWrite($g_UsrIni, 'Current', $p_Array[$a][0], $Return)
				_Tree_Purge(0, $p_Array[$a][0], $p_Array[$a][1])
			EndIf
		EndIf
	Next
	_Tree_Purge(0, StringTrimLeft($String, 1)); remove entire pending mods
EndFunc   ;==>_Depend_RemoveFromCurrent

; ---------------------------------------------------------------------------------------------
; this function displays and handles the UI for the 'resolve conflicts and dependencies' screen
; checks the mods from the connections-array (Select-GUILoop calls this when leaving tree-view)
; ---------------------------------------------------------------------------------------------
Func _Depend_ResolveGui($p_Solve=0)
	_PrintDebug('+' & @ScriptLineNumber & ' Calling _Depend_ResolveGui')
	_Depend_GetActiveConnections()
	If $g_ActiveConnections[0][0] <> 0 Then _Misc_SetTab(10); dependencies-tab
	$g_Flags[16] = 0; 16=admin-lv has focus/treeicon clicked
	While 1
		If $g_ActiveConnections[0][0] = 0 Then
			_Misc_SetTab(2); back to folder-tab
			Return 1
		EndIf
		Local $aMsg = GUIGetMsg()
		If $g_Flags[16]=1 Then _Depend_Contextmenu()
		Switch $aMsg
			Case $g_UI_Button[0][3]; exit
				Exit
			Case $Gui_Event_Close
				Exit
			Case $g_UI_Button[10][1]; "basis..." button
				_Depend_AutoSolveWarning(3, 0, 1); autosolve conflicts and dependencies, skip warning rules
			Case $g_UI_Button[10][2]; "... has conflict with" button
				_Depend_AutoSolveWarning(1, 0, 0); autosolve conflicts, don't skip warning rules
			Case $g_UI_Button[10][3]; "... is in need of" button
				_Depend_AutoSolveWarning(2, 0, 0); autosolve dependencies, don't skip warning rules
			Case $g_UI_Button[10][4]; help on/off toggle ('>' / '<')
				_Depend_ToggleHelp()
			Case $g_UI_Button[0][2]; continue button
				_Depend_AutoSolveWarning(3, 1, 0); "force" autosolve dependencies and conflicts, don't skip warning rules
			Case $g_UI_Button[0][1]; back button
				_Misc_SetTab(4); return to tree-view (advanced selection tab)
				Return 0
		EndSwitch
		Sleep(10)
	WEnd
EndFunc   ;==>_Depend_ResolveGui

; ---------------------------------------------------------------------------------------------
; Force a state on items in a certain "connection-group" $p_State: 1=select, 2=deselect
; ---------------------------------------------------------------------------------------------
Func _Depend_SetGroupByNumber($p_Num, $p_State, $p_Skip='')
	Local $GroupID
	If $p_Skip <> '' Then
		For $a=1 to $g_ActiveConnections[0][0]
			If $g_ActiveConnections[$a][2] <> $p_Skip Then ContinueLoop
			$GroupID = $g_ActiveConnections[$a][3]; look if item is part of a group
			ExitLoop
		Next
	EndIf
	For $a=1 to $g_ActiveConnections[0][0]
		If $g_ActiveConnections[$a][1] <> $p_Num Then ContinueLoop
		If $GroupID <> '' And $GroupID = $g_ActiveConnections[$a][3] Then ContinueLoop; keep items of the same group
		If $p_Skip <> '' And $p_Skip = $g_ActiveConnections[$a][2] Then ContinueLoop
		If $g_ActiveConnections[$a][0] = 'DO' And $g_ActiveConnections[$a][3] = 1 Then ContinueLoop
		_Depend_SetModState($g_ActiveConnections[$a][2], $p_State)
		;ConsoleWrite(@ScriptLineNumber & ': '&$g_CentralArray[$g_ActiveConnections[$a][2]][0] & ' - ' & $g_CentralArray[$g_ActiveConnections[$a][2]][2] & ' - ' & $p_State & @CRLF)
		;ConsoleWrite($g_ActiveConnections[$a][0] & ' - ' &$g_ActiveConnections[$a][1] & ' - ' &$g_ActiveConnections[$a][2] & ' - ' &$g_ActiveConnections[$a][3] &  @CRLF)
	Next
EndFunc   ;==>_Depend_SetGroupByNumber

; ---------------------------------------------------------------------------------------------
; Activate or deactivate all parts of a mod (returns 1 if success, 0 if state change failed)
;   p_State = 1 (enable) or 2 (disable)
; ---------------------------------------------------------------------------------------------
Func _Depend_SetModState($p_ControlID, $p_State)
	_AI_SetClicked($p_ControlID, $p_State)
	;ConsoleWrite(@ScriptLineNumber & ': '&$g_CentralArray[$p_ControlID][0] & ' - ' & $g_CentralArray[$p_ControlID][2] & ' - ' & $p_State & @CRLF)
	If $g_CentralArray[$p_ControlID][2] = '-' Then
		If $g_CentralArray[$p_ControlID][13] <> '' Then
			Local $Splitted=StringSplit($g_CentralArray[$p_ControlID][13], ',')
			For $s=1 to $Splitted[0]
				_AI_SetClicked($Splitted[$s], $p_State)
				;ConsoleWrite(@ScriptLineNumber & ': '&$g_CentralArray[$Splitted[$s]][0] & ' - ' & $g_CentralArray[$Splitted[$s]][2] & ' - ' & $p_State & @CRLF)
			Next
		EndIf
	EndIf
	If $p_State = 1 And $g_CentralArray[$p_ControlID][9] = 0 Then; failed to activate
		_PrintDebug('_Depend_SetModState could not activate ' & $p_ControlID & ' = ' & $g_CentralArray[$p_ControlID][0] & ' = ' & $g_CentralArray[$p_ControlID][4] & '(' & $g_CentralArray[$p_ControlID][3] & ')' & @CRLF, 1); mod name(component name or - for entire mod)
		Return 0
	ElseIf $p_State = 2 And $g_CentralArray[$p_ControlID][9] <> 0 Then; failed to deactivate
		_PrintDebug('_Depend_SetModState could not deactivate ' & $p_ControlID & ' = ' & $g_CentralArray[$p_ControlID][0] & ' = ' & $g_CentralArray[$p_ControlID][4] & '(' & $g_CentralArray[$p_ControlID][3] & ')' & @CRLF, 1); mod name(component name or - for entire mod)
		Return 0
	EndIf
	Return 1
EndFunc   ;==>_Depend_SetModState

; ---------------------------------------------------------------------------------------------
; Remove all items that have problems with a specific item or setup. Invert is possible.
; ---------------------------------------------------------------------------------------------
Func _Depend_SolveConflict($p_Setup, $p_State, $p_Type=0)
	Local $GroupID, $Test
	For $a=1 to $g_ActiveConnections[0][0]
		If $p_Type = 0 Then $Test = $g_ActiveConnections[$a][2]
		If $p_Type = 1 Then $Test = $g_CentralArray[$g_ActiveConnections[$a][2]][0]; setup-name
		If $Test = $p_Setup Then
			If $g_ActiveConnections[$a][0] <> 'C' Then ContinueLoop
			$GroupID = $g_ActiveConnections[$a][3]
			Local $n=$a
			While $g_ActiveConnections[$n][1]=$g_ActiveConnections[$a][1]; get the beginning of the conflict
				$n-=1
			WEnd
			While 1
				$n+=1
				If $g_ActiveConnections[$n][1]<>$g_ActiveConnections[$a][1] Then ExitLoop; continue to the next possible step or exit
				If $p_Type = 0 Then $Test = $g_ActiveConnections[$n][2]
				If $p_Type = 1 Then $Test = $g_CentralArray[$g_ActiveConnections[$n][2]][0]; setup-name
				If $p_State = 1 Then
					If $GroupID <> '' And $GroupID = $g_ActiveConnections[$n][3] Then ContinueLoop
					If $Test <> $p_Setup Then _Depend_SetModState($g_ActiveConnections[$n][2], 2); remove the item if it is not the setup itself
					;If $Test <> $p_Setup Then ConsoleWrite(@ScriptLineNumber & ': '&$g_CentralArray[$g_ActiveConnections[$n][2]][0] & ' - ' & $g_CentralArray[$g_ActiveConnections[$n][2]][2] & ' - ' & $p_State & @CRLF)
				Else
					If $Test = $p_Setup Then _Depend_SetModState($g_ActiveConnections[$n][2], 2); remove the item if it is the setup itself
					;If $Test = $p_Setup Then ConsoleWrite(@ScriptLineNumber & ': '&$g_CentralArray[$g_ActiveConnections[$n][2]][0] & ' - ' & $g_CentralArray[$g_ActiveConnections[$n][2]][2] & ' - ' & $p_State & @CRLF)
				EndIf
			WEnd
		EndIf
	Next
EndFunc   ;==>_Depend_SolveConflict

; ---------------------------------------------------------------------------------------------
; Switch help on / off on depend tab
; ---------------------------------------------------------------------------------------------
Func _Depend_ToggleHelp()
	Local $Pos=ControlGetPos($g_UI[0], '', $g_UI_Interact[10][1])
	Local $State=GUICtrlGetState($g_UI_Interact[10][2])
	If BitAND($State, $GUI_HIDE) Then
		GUICtrlSetPos($g_UI_Interact[10][1], 15, 100, $Pos[2]-305, $Pos[3])
		GUICtrlSetPos($g_UI_Button[10][4], $Pos[2]-290, 100, 15, $Pos[3])
		GUICtrlSetState($g_UI_Interact[10][2], $GUI_SHOW)
		GUICtrlSetData($g_UI_Button[10][4], '>')
	Else
		GUICtrlSetPos($g_UI_Interact[10][1], 15, 100, $Pos[2]+305, $Pos[3])
		GUICtrlSetPos($g_UI_Button[10][4], $Pos[2]+320, 100, 15, $Pos[3])
		GUICtrlSetState($g_UI_Interact[10][2], $GUI_HIDE)
		GUICtrlSetData($g_UI_Button[10][4], '<')
	EndIf
	$Pos=ControlGetPos($g_UI[0], '', $g_UI_Interact[10][1])
	_GUICtrlListView_SetColumnWidth($g_UI_Handle[1], 0, Floor($Pos[2]/2)-5)
	_GUICtrlListView_SetColumnWidth($g_UI_Handle[1], 1, Floor($Pos[2]/2))
EndFunc   ;==>_Depend_ToggleHelp

; ---------------------------------------------------------------------------------------------
; Removes lines which contain component-numbers / which are only used in BWS-installs
;	p_Array is the output of _IniReadSection($g_ConnectionsConfDir&'\Game.ini', 'Connections')
;		i.e. a two-dimensional array of inikey=inivalue pairs
; ---------------------------------------------------------------------------------------------
Func _Depend_TrimBWSConnections($p_Array)
	Local $Return[$p_Array[0][0]+1][2]
	For $c=1 to $p_Array[0][0]; copy lines without component numbers from p_Array to RuleLines
		If StringRegExp($p_Array[$c][1], '\x28[\d\x7c\x26]+\x29') Then ContinueLoop
		$Return[0][0]+=1; we found a rule without component numbers
		$Return[$Return[0][0]][0]=$p_Array[$c][0]; rule description (inikey, left of =)
		$Return[$Return[0][0]][1]=$p_Array[$c][1]; the rule itself (inivalue, right of =)
	Next
	ReDim $Return[$Return[0][0]+1][2]; trim the array because we (probably) removed entries
	Return $Return
EndFunc   ;==>_Depend_TrimBWSConnections

; ---------------------------------------------------------------------------------------------
; Create a contextmenu for the selected listview-item (got it from the helpfile)
; ---------------------------------------------------------------------------------------------
Func _Depend_WM_Notify($p_Handle, $iMsg, $iwParam, $ilParam)
	#forceref $p_Handle, $iMsg, $iwParam
	Local $HandleFrom, $iIDFrom, $iCode, $tNMHDR, $tInfo, $Index, $String
	$tNMHDR = DllStructCreate($tagNMHDR, $ilParam)
	$HandleFrom = HWnd(DllStructGetData($tNMHDR, "hWndFrom"))
	$iIDFrom = DllStructGetData($tNMHDR, "IDFrom")
	$iCode = DllStructGetData($tNMHDR, "Code")
	Switch $HandleFrom
		Case $g_UI_Handle[1]
			Switch $iCode
				Case $NM_RCLICK ; Sent by a list-view control when the user clicks an item with the right mouse button
					$g_Flags[16] = 1; enable the building of menu-entries now	($g_Flags[16]=admin-lv has focus/treeicon clicked)
					$tInfo = DllStructCreate($tagNMITEMACTIVATE, $ilParam)
					$Index = DllStructGetData($tInfo, "Index"); get the zero-based index
					$g_UI_Menu[0][6] = GUICtrlRead($g_UI_Interact[10][1], $Index); get the handle
					$g_UI_Menu[0][7] = $g_ActiveConnections[$Index + 1][0]; type
					$g_UI_Menu[0][8] = $g_ActiveConnections[$Index + 1][1]; num
					$g_UI_Menu[0][9] = $g_ActiveConnections[$Index + 1][2]; setup
					$String=$g_Connections[$g_UI_Menu[0][8]][0]&': '&$g_Connections[$g_UI_Menu[0][8]][2]
					If $g_Connections[$g_UI_Menu[0][8]][4]=1 Then $String=_GetTR($g_UI_Message, '10-L2')&': '&$String; => notice
					GUICtrlSetData($g_UI_Interact[10][3], $String)
				Case $NM_CLICK ; Sent by a list-view control when the user clicks an item with the left mouse button
					$tInfo = DllStructCreate($tagNMITEMACTIVATE, $ilParam)
					$Index = DllStructGetData($tInfo, "Index"); get the zero-based index
					$Index = $g_ActiveConnections[$Index + 1][1]; num
					$String=$g_Connections[$Index][0]&': '&$g_Connections[$Index][2]
					If $g_Connections[$Index][4]=1 Then $String=_GetTR($g_UI_Message, '10-L2')&': '&$String; => notice
					GUICtrlSetData($g_UI_Interact[10][3], $String)
				Case $LVN_KEYDOWN ; A key has been pressed
					Local $Diff = '-'
					$tInfo = DllStructCreate($tagNMLVKEYDOWN, $ilParam)
					If DllStructGetData($tInfo, "VKey") = '21495846' Then; Up was pressed
						$Diff = ''
					ElseIf DllStructGetData($tInfo, "VKey") = '22020136' Then; Down was pressed
						$Diff = 2
					ElseIf DllStructGetData($tInfo, "VKey") = '22151213' Then; Insert was pressed
						$Index = ControlListView($g_UI[0], '', $g_UI_Interact[10][1], 'GetSelected')+1
						_Depend_SetModState($g_ActiveConnections[$Index][2], 1); item or mod: remove
						_Depend_GetActiveConnections()
					ElseIf DllStructGetData($tInfo, "VKey") = '22216750' Then; Delete was pressed
						$Index = ControlListView($g_UI[0], '', $g_UI_Interact[10][1], 'GetSelected')+1
						_Depend_SetModState($g_ActiveConnections[$Index][2], 2); item or mod: remove
						_Depend_GetActiveConnections()
					EndIf
					If $Diff = '-' Then Return $GUI_RUNDEFMSG; no up/down
					$Index = ControlListView($g_UI[0], '', $g_UI_Interact[10][1], 'GetSelected')+$Diff
					If $Index = '' Then Return $GUI_RUNDEFMSG; nothing selected
					If $Index >  $g_ActiveConnections[0][0] Then Return $GUI_RUNDEFMSG; down @ last item = no update
					$Index = $g_ActiveConnections[$Index][1]; num
					$String=$g_Connections[$Index][0]&': '&$g_Connections[$Index][2]
					If $g_Connections[$Index][4]=1 Then $String=_GetTR($g_UI_Message, '10-L2')&': '& $String; => notice
					GUICtrlSetData($g_UI_Interact[10][3], $String)
			EndSwitch
	EndSwitch
	Return $GUI_RUNDEFMSG
EndFunc   ;==>_Depend_WM_Notify

; ---------------------------------------------------------------------------------------------
; Write dummy WeiDU components to a tp2 file so they will appear in users' WeiDU.log
; ---------------------------------------------------------------------------------------------
Func _Depend_LogToWeiDU($p_File)
	Local $c = 0
	For $r = 1 to $g_Connections[0][0]; process all rules for the current game type
		If StringLeft($g_Connections[$r][3], 1) = 'W' Then; this rule was ignored by the user
			FileWriteLine($p_File, 'BEGIN ~User Ignored Rule: '&$g_Connections[$r][1]&'~')
			$c += 1; count number of components added to TP2 file
		EndIf
	Next
	Return $c; return number of components added to TP2 file
EndFunc   ;==>_Depend_IgnoredRulesList