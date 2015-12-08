param([Parameter(Position=0)]$modPath,$Name=$null,$Type='S',$Version,$Download=$null,$HomePage='http://www.shsforums.net',$Category='99',$iniPath=$null)
function Grant-Elevation {  
if ( $script:MyInvocation.MyCommand.Path ) { Set-Location ( Split-Path $script:MyInvocation.MyCommand.Path )} else { Set-Location ( Split-Path -parent $psISE.CurrentFile.Fullpath )}

$myWindowsID = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal( $myWindowsID )
$adminRole = [System.Security.Principal.WindowsBuiltInRole]::Administrator

if ( !$myWindowsPrincipal.IsInRole( $adminRole )) {

# This fixes error wen script is located at mapped network drive
$private:scriptFullPath = $script:MyInvocation.MyCommand.Path
if ( $scriptFullPath.Contains([io.path]::VolumeSeparatorChar )) { # check for a drive letter
$private:psDrive = Get-PSDrive -Name $scriptFullPath.Substring(0,1) -PSProvider 'FileSystem'
if ( $psDrive.DisplayRoot ) { # check if it's a mapped network drive
$scriptFullPath = $scriptFullPath.Replace( $psdrive.Name + [io.path]::VolumeSeparatorChar, $psDrive.DisplayRoot )
}

}
[string[]]$argList = @( '-NoLogo', '-NoProfile', '-NoExit', '-File', "`"$scriptFullPath`"" )

$argList += $MyInvocation.BoundParameters.GetEnumerator() | % { "-$( $_.Key )", "$( $_.Value )" }
$argList += $MyInvocation.UnboundArguments

Start-Process powershell.exe -Verb Runas -WorkingDirectory $PWD -ArgumentList $argList -PassThru
Stop-Process $PID
}
}
Grant-Elevation

try {
Invoke-WebRequest 'https://bitbucket.org/BigWorldSetup/bigworldsetup/raw/master/BiG%20World%20Setup-Create-Mod-Template.ps1' -UseBasicParsing -OutFile $script:MyInvocation.MyCommand.Name | Out-Null
} catch { $_.Exception.Response.StatusCode.Value__ }

$comWeiDU = $langWeiDU = $tp2data = $tp2dataRaw = $tp2dataRegex = $tp2File = $tp2FullPath = $weidu = $null

$Game = 'EET'
$Type = 'S'
$Category = '99'

if ( $modPath -eq $null ) {
    if ( (Get-ChildItem -Path $g_ScriptPath -Filter *.tp2 -Recurse) -ne $null ) {
    $tp2File = (Get-ChildItem -Path $g_ScriptPath -Filter *.tp2 -Recurse)[0]
    $tp2Path = $tp2File.Directory
    $tp2FullPath = $tp2File.FullName
    } else {
        Write-Warning "Put this script inside mod directory or provide path to it."
        Write-Warning 'Example: .\BWS.ps1 -Path "D:\Downloads\ModDirectory"'
        break  }
} else {
    if ( !( Test-Path $modPath )) { Write-Warning "Wrong path: $modPath" 
exit }
    Set-Location $modPath

    $tp2File = ( Get-ChildItem -Path $modPath -Filter *.tp2 -Recurse )[0]
    $tp2FullPath = $tp2File.FullName
}
$tp2FileNoSetup = $tp2File.BaseName -replace 'setup-'
if ( $iniPath -eq $null ) { $iniPath = Split-Path $tp2FullPath -Parent }

$weidu = Get-ChildItem -Path $modPath -Filter setup-*.exe -Recurse -EA 0 | Select-Object -First 1 -EA 0
#$weidu = Get-Item 'D:\Gry\BG\Tools\setup-weidu.exe'
if ( !$weidu ) { $weidu = Get-ChildItem -Path ( Split-Path ( Split-Path $tp2FullPath -Parent ) -Parent ) -Filter "setup-$tp2FileNoSetup.exe" -Recurse -EA 0 | Select-Object -First 1 -EA 0
}
if ( !$weidu ) {
    Write-Warning "Missing:"
    ( $tp2FullPath -replace 'setup-' ) -replace 'tp2','exe'
    exit
}
$weidu = Get-Item $weidu.FullName
Set-Location $weidu.Directory

$tp2dataRaw = ( Get-Content $tp2FullPath -Raw ) -replace '/\*(?>(?:(?>[^*]+)|\*(?!/))*)\*/'
$tp2data = $tp2dataRaw -split "`r`n|`r|`n"

if ( !$Name ) { $Name  = $tp2FileNoSetup }

if ( !$version ) {
    $version = (($tp2data | Select-String -Pattern 'VERSION ~') -split '~')[1]
    if ( !$version ) {
    Write-Warning "Missing VERSION inside $($tp2File.FullName) - manuall edit of $tp2FileNoSetup.ini required."
    #Write-Host "Please provide version of the mod"
    #$Version = Read-Host -Prompt Version
    }
}

if ( !$Category ) {
    if ( $game -match 'bg1ee' -or $game -match 'bg2' -or $game -match 'bg2ee' -or $game -match 'bgt' -or $game -match 'eet' ) {
    Write-Host "Please provide Category for the mod"
    "
    01 Corrections
    02 The Big BG1 Mods
    03 BG1 Quest Mods
    04 BG1 NPC Mods
    05 BG1 NPC-Related Mods
    06 BG1 Tactical Encounters
    07 BG1 Rules And Tweaks
    08 BG1 Stores And Items
    09 The Big BG2 Mods
    10 BG2 Quest Mods
    11 Mini-Mods
    12 BG2 NPC Mods
    13 Smaller BG2 NPCS
    14 BG2 NPC-Related Mods
    15 BG2 Tactical Encounters
    16 BG2 Rules, Tweaks And Spells
    17 BG2 Stores And Items
    18 Artificial Intelligence
    19 Character-Kits
    20 Graphic, Portrait And Sound Mods"
    [string]$Category = Read-Host -Prompt Number
    if ( $Category -eq "" ) { $Category = '00' }
    if ( $Category.Length -lt 2 ) { $Category = '0' + $Category }
    } else {
    Write-Host "Please provide Category for the mod"
    "
    01 Corrections
    02 Big Mods
    03 Quest Mods
    04 Mini-Mods
    05 NPC Mods
    06 Smaller NPCS
    07 NPC-Related Mods
    08 Tactical Encounters
    09 Rules and Tweaks
    10 Stores And Items
    11 Artificial Intelligence
    12 Character-Kits
    13 Graphic, Portrait And Sound Mods"
    [string]$Category = Read-Host -Prompt Number
    if ( $Category -eq "" ) { $Category = '00' }
    if ( $Category.Length -lt 2 ) { $Category = '0' + $Category}
    }
}

$langFileName = "$tp2FileNoSetup-languages.ini"
$langFilePath = $iniPath + '\' + $langFileName
& $weidu --no-exit-pause --noautoupdate --nogame --list-languages "$tp2FullPath" --out "$langFilePath" | Out-Null

$translations = ( Get-Content "$iniPath\$langFileName" ) # | Select-String -Pattern '[0-9]:'

$defaultLanguage = $translations | Select-String '0:'
if ( $defaultLanguage -eq $null ) {
$defaultLanguage = '0:--'
$defaultLanguageNumber = $defaultLanguage.ToString()[0]
$tra = $defaultLanguage
$langWeiDU = '0:EN'
} else {
$langWeiDU = $translations | % { ( $_ -split ' ' )[0] -replace 'Portuguese','PT' } 
$langWeiDU = ($langWeiDU | % { (((( $_[0..3] -join '' ) -replace 'am','EN') -replace 'de','GE' ) -replace 'ca','SP' ) -replace 'es','SP' }).ToUpper()
$tra = ( $langWeiDU | % {( ( $_[2..3] ) -join '' ) + ':' + ( $_[0] ) }) -join ','
}

#Mod data
$Property = @{
'Name'=$Name
 'tp2'=$tp2File.BaseName -replace 'setup-'
'Type'=$Type
 'Rev'=$version
'Link'=$HomePage
'Down'=$Download
'Save'="$tp2FileNoSetup.zip"
'Size'=$Size
 'Tra'=$Tra
 'Cat'=$Category
}

$mod = New-Object -TypeName PSObject -Property $Property

[array]$languages = @()

$langWeiDU | % {
    $Property = @{
    'LanguageNumber'= $_[0]
    'LanguageCode'= ($_ -split ':')[1]
    'LanguageData'= $null
    }
    $singleLanguage = New-Object -TypeName PSObject -Property $Property
    
    #& $weidu --no-exit-pause --noautoupdate --nogame --list-components "$tp2FullPath" $_[0] | Out-File -FilePath "$iniPath\list-components.ini" -Encoding default -Force | Out-Null
    $comFileName = "$tp2FileNoSetup-components-$($singleLanguage.LanguageNumber)-$($singleLanguage.LanguageCode).ini"
    $comFilePath = $iniPath + '\' + $comFileName
    $weidu
    Write-Output "& $weidu --no-exit-pause --noautoupdate --nogame --list-components $tp2FullPath $($singleLanguage.LanguageNumber) --out $comFilePath"
    & $weidu --no-exit-pause --noautoupdate --nogame --list-components "$tp2FullPath" $singleLanguage.LanguageNumber --out "$comFilePath"
    $comWeiDU = Get-Content "$iniPath\$comFileName" #| Select-String -Pattern '~.'

	#$comWeiDU
	[array]$components = @()
	$comWeiDU | % {
	if ( $_ -notmatch '->') {
		[int]$componentNumber = ((((( $_ -split '\/\/' )[0]) -split '~ ') -split '#')[-1]) -replace '\s+'
		[string]$componentName = (( $_ -split '\/\/' )[1] -split ' -> ')[0]
        if ( $componentName -match ':') { $componentName = ($componentName -split ($componentName -split ':')[-1]).TrimEnd(':')}
		$componentName = $componentName.TrimEnd().TrimStart()
		#Write-Host $componentNumber`t$componentName
		$singleComponent = New-Object -TypeName PSObject
		$singleComponent | Add-Member -MemberType NoteProperty -Name 'Number' -Value $componentNumber
		$singleComponent | Add-Member -MemberType NoteProperty -Name 'Name' -Value $componentName
		$components += $singleComponent
	}

	if ( $_ -match '->') {
		[int]$componentNumber = ((((( $_ -split '\/\/' )[0]) -split '~ ') -split '#')[-1]) -replace '\s+'
		[string]$componentName = (( $_ -split '\/\/' )[1] -split ' -> ')[0]
		[string]$componentName = $componentName.TrimEnd(' ').TrimStart()
		[string]$subcomponent = (( $_ -split '\/\/' )[1] -split ' -> ')[1]
		[string]$subcomponent = ($subcomponent -split ($subcomponent -split ':')[-1]).trimend(':')
		[string]$subcomponent = $subcomponent.TrimEnd().TrimStart()
		#Write-Host "$componentNumber`t$componentName -> $subcomponent"
		$singleComponent = New-Object -TypeName PSObject
		$singleComponent | Add-Member -MemberType NoteProperty -Name 'Number' -Value $componentNumber
		$singleComponent | Add-Member -MemberType NoteProperty -Name 'Name' -Value $componentName
		$singleComponent | Add-Member -MemberType NoteProperty -Name 'Subcomponent' -Value $subcomponent
		$components += $singleComponent
	}
	}

	$components = $components | Sort-Object -Property Number |  Group-Object -Property Name

	#$components | FL
	#$components | Select-Object Number, Name, Subcomponent

	[array]$iniComponents = @()
	[array]$iniSelect = @()

    $components | % {
	if ( $_.Count -eq 1 ) {
		$_.Group | % {
			#Write-Host "STD;$($_.Name);$($_.Number);$($mod.category);0000;"
			$iniComponents += "@$($_.Number)=" + ($_.Name).trimstart()#.trimend(" ")
			}
		}
	if ( $_.Count -ge 2 ) {
		$_.Group | % {
			#Write-Host "MUC;$($mod.name);$($_.Number);$($mod.category);0000;"
			$iniComponents += "@$($_.Number)=" + ($_.Name).trimstart() + ' -> ' + ($_.Subcomponent)#.trimend(" ")
			}
		}
    $iniComponents# = $iniComponents | Sort-Object
	}
    $singleLanguage.LanguageData = $iniComponents
    $languages += $singleLanguage
} #| Out-Null

$components | % {
if ( $_.Count -eq 1 ) {
	$_.Group | % {
		#Write-Host "STD;$($mod.Name);$($_.Number);$($mod.Cat);0000;"
		$iniSelect += "STD;$($mod.tp2);$($_.Number);$($mod.Cat);0000;"
		}
	}
if ( $_.Count -ge 2 ) {
	#Write-Host "MUC;$($mod.tp2);Init;$($mod.category);0000;"
	$iniSelect += "MUC;$($mod.tp2);Init;$($mod.category);0000;"
	$_.Group | % {
		#Write-Host "MUC;$($mod.tp2);$($_.Number);$($mod.Cat);0000;"
		$iniSelect += "MUC;$($mod.tp2);$($_.Number);$($mod.Cat);0000;"
		}
	}
} | Out-Null

($languages | Group-Object -Property LanguageCode) | % {
    if ($_.Count -gt 1 ) {
    $multiple = $_.Values
    Write-Warning "Mod has multiple language numbers for the same translation: $( $langWeiDU | ? { $_ -match $multiple }) - manuall edit of $tp2FileNoSetup.ini required."
    }
}

$iniLanguage = @()
$languages | % {
$iniLanguage += "[WeiDU-$($_.LanguageCode)]"
$iniLanguage += $_.LanguageData
$iniLanguage += "Tra=$($_.LanguageNumber)`r`n" 
}

$iniMod = @()
$iniMod += '[Mod]'
$iniMod += "Name=$($mod.Name)"
$iniMod += " Rev=$($mod.Rev)"
$iniMod += "Type=$($mod.Type -join ',')"
$iniMod += "Link=$($mod.Link)"
$iniMod += "Down=$($mod.Down)"
$iniMod += "Save=$($mod.Save)"
$iniMod += "Size=$($mod.Size)"
$iniMod += " Tra=$($mod.Tra)`r`n"
$iniMod += $iniLanguage
$iniMod += '[Description]'
$iniMod += "Mod-EN=$($mod.Name)"
$iniMod += "Mod-GE=$($mod.Name)"
$iniMod += "Mod-RU=$($mod.Name)"

Write-Host "Mod information:" -ForegroundColor Green
$mod

$iniMod | Out-File -FilePath ("$iniPath\$($mod.tp2 -replace 'setup-').ini") -Encoding default -Force | Out-Null
#[System.IO.File]::WriteAllLines( ("$iniPath\$($mod.Name -replace 'setup-').ini") , $iniMod )
$iniSelect | Out-File -FilePath "$iniPath\$($mod.tp2)-select-$game.ini" -Encoding default -Force | Out-Null

# ACTION_READLN, only simple report
[Regex]$regex0 = '(ACTION_READLN ~..*?~)'
$tp2dataRegex = [Regex]::Matches($tp2dataRaw,$regex0, [System.Text.RegularExpressions.RegexOptions]::Singleline) | select -Unique

if ( $tp2dataRegex -ne $null ) {
Write-Warning "ACTION_READLN detected inside $tp2FullPath, $($mod.tp2 -replace 'setup-').ini file is not complete."
}
$tp2dataRegex | % {
    $optionName = ( $_.groups[1].value -split '~' )[1]
    $possibleInput = ( $tp2data | Select-String $optionName) | ? { $_ -like "*$optionName*=*" } | % { ((($_ -replace '\s+') -split '=') -split '\)')[1] }
    $possibleInput | % {
        if ( [System.Int32]::TryParse($_, [ref]0) ) { Write-Host "User input required: $optionName $_" }
    }
}
