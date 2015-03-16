Set wshshell = WScript.CreateObject ("wscript.shell")
wshshell.run """AutoIt3.exe""" &" " & """URL-Check.au3""", 6, True
set wshshell = nothing