Set wshshell = WScript.CreateObject ("wscript.shell")
wshshell.run """BiG World Setup\AutoIt3.exe""" &" " & """BiG World Setup\Debug.au3""" & " 1", 6, True
set wshshell = nothing