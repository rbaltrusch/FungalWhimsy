# Fungal Whimsy

This is my game jam entry for the LÖVE game jam 2024.

## How to run

To run, download lua and the love framework, then run love.exe in the current folder:

```
love .
```

Note: you may have to specify the full path to the love executable if it is not on your path.

## How to package

Detailed packaging instructions for Windows are documented [here](https://love2d.org/wiki/Game_Distribution).

Essentially, select all files required to run the game, zip them, rename .zip to .love, then concatenate it with love.exe and distribute it will all .dll's (including license) found in the love installation folder:

```batch
::zip game code and assets by hand
copy SuperGame.zip SuperGame.love
copy /b love.exe+SuperGame.love SuperGame.exe
::copy dlls into folder
```
