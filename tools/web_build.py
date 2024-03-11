import subprocess
import sys
import pathlib
import shutil
from typing import List, Tuple
from build import main as build_game
from build import GAME

TITLE = "Myrkur"
WEB_BUILD_DIR = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "webbuild")
BACKGROUND_COLOUR = "#222034"
TEXT_COLOUR = "#df7126"


def replace_string(filepath: pathlib.Path, replacements: List[Tuple[str, str]]) -> None:
    content = filepath.read_text()
    for old, new in replacements:
        content = content.replace(old, new)
    filepath.write_text(content)


def main():
    try:
        replace_string(pathlib.Path("conf.lua"), [("IS_WEB = false", "IS_WEB = true")])
        build_game()
        subprocess.check_call(
            f"npx love.js.cmd {GAME}.love {WEB_BUILD_DIR} -t={TITLE} -c", shell=True
        )
        replace_string(
            WEB_BUILD_DIR / "index.html",
            [
                ("<h1>-&#x3D;</h1>", ""),
                ('loadingContext.fillStyle = "rgb(142, 195, 227)";', f'loadingContext.fillStyle = "{BACKGROUND_COLOUR}";'),
                (
                    'loadingContext.fillStyle = "rgb( 11, 86, 117 )";',
                    f'loadingContext.fillStyle = "{TEXT_COLOUR}";',
                ),
                (
                    '<canvas id="loadingCanvas" oncontextmenu="event.preventDefault()" width="800" height="600"></canvas>',
                    '<canvas id="loadingCanvas" oncontextmenu="event.preventDefault()" width="600" height="450"></canvas>',
                ),
                (
                    '<footer>\n      <p>Built with <a href="https://github.com/Davidobot/love.js">love.js</a> <button onclick="goFullScreen();">Go Fullscreen</button><br>Hint: Reload the page if screen is blank</p>\n    </footer>',
                    "",
                ),
            ],
        )
        replace_string(
            WEB_BUILD_DIR / "theme" / "love.css",
            [
                ("background-image: url(bg.png);", ""),
                (
                    "background-color: rgb( 154, 205, 237 );",
                    f"background-color: {BACKGROUND_COLOUR};",
                ),
            ],
        )
        shutil.make_archive(str(WEB_BUILD_DIR), "zip", WEB_BUILD_DIR)
    finally:
        replace_string(pathlib.Path("conf.lua"), [("IS_WEB = true", "IS_WEB = false")])


if __name__ == "__main__":
    main()
