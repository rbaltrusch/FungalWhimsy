![Fungal Whimsy](media/banner_github.png)

This is a puzzle precision platformer and my game jam entry for the [LÖVE jam 2024](https://itch.io/jam/love2d-jam-2024), where you play as a small shroom exploring a dense mushroom forest filled with musky smells and humid spells.

![Gif showing gameplay](media/game_showcase_md.gif)

You can play my entry on itch.io [here](https://richardbaltrusch.itch.io/fungal-whimsy).

## How to run

To run, download lua and the love framework (LÖVE 11.4), then run love.exe in the current folder:

```
love .
```

Note: you may have to specify the full path to the love executable if it is not on your path.

## How to package

Detailed packaging instructions for Windows are documented [here](https://love2d.org/wiki/Game_Distribution).

Essentially, select all files required to run the game, zip them, rename .zip to .love, then concatenate it with love.exe and distribute it will all .dll's (including license) found in the love installation folder:

```batch
::zip game code and assets by hand to make FungalWhimsy.zip, then run:
copy FungalWhimsy.zip FungalWhimsy.love
copy /b love.exe+FungalWhimsy.love FungalWhimsy.exe
::finally, copy all love2d dlls into folder containing .exe (including license).
```
