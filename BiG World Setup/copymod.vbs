Set wshshell = WScript.CreateObject ("wscript.shell")
wshshell.run """AutoIt3.exe""" &" " & """CopyMod.au3""", 6, True
set wshshell = nothing