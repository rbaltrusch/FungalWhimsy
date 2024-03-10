WIDTH, HEIGHT = 600, 450
TILE_SIZE = 16
DEBUG_ENABLED = false
NUKE_FPS = false
IS_WEB = true
DEFAULT_SCALING = 2
MAX_STARS = 9
JUMP_PAD = 21
PORTAL = 22
WIN_FLAG = 10
DASH_REFRESH = 23
STAR = 25
FLAT_SPIKES = 17

function love.conf(table_)
    table_.window.height = HEIGHT
    table_.window.width = WIDTH
    table_.window.title = "Fungal Whimsy"
    table_.window.fullscreen = not IS_WEB
    table_.window.vsync = 1
end
