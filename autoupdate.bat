@ECHO OFF
echo Checking for BWS updates...
git remote update
FOR /F "delims=" %%A in ('git rev-parse @{0}') DO SET _remote=%%A
FOR /F "delims=" %%A in ('git rev-parse HEAD') DO SET _locals=%%A

IF NOT %_locals% == %_remote% (
  echo Saving any local changes...
  git stash
  echo Downloading BWS updates...
  git pull --rebase
  echo Merging any local changes...
  git stash pop
  echo Done with BWS auto-update!
  echo If you see a MERGE WARNING above, resolve it if you know how or else use the full update
  pause
) ELSE (
  echo BWS is up to date!
)