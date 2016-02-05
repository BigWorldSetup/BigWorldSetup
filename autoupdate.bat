@ECHO OFF
echo Checking for BWS updates...
"BiG World Setup\Tools\Git\bin\git.exe" remote update
FOR /F "delims=" %%A in ('"BiG World Setup\Tools\Git\bin\git.exe" rev-list @{0}..@{u} --count') DO SET _num_upstream_commits=%%A

IF %_num_upstream_commits% GTR 0 (
  echo %_num_upstream_commits% updates found:
  "BiG World Setup\Tools\Git\bin\git.exe" rev-list @{0}..@{u} --oneline
  echo Press Enter to proceed with auto-update...
  pause > nul
  echo Saving any local changes...
  "BiG World Setup\Tools\Git\bin\git.exe" stash
  echo Downloading BWS updates...
  "BiG World Setup\Tools\Git\bin\git.exe" fetch
  "BiG World Setup\Tools\Git\bin\git.exe" pull --rebase
  echo Merging any local changes...
  "BiG World Setup\Tools\Git\bin\git.exe" stash pop
  echo Done with BWS auto-update!
  echo If you see a MERGE CONFLICT above, resolve it if you know how or else use the full update
  pause
) ELSE (
  echo BWS is up to date!
)