-- Constants.lua
-- Постоянные размеры и правила полосы навигации.

local ConsoleMenu = _G.ConsoleMenu

-- Состояние и функции полосы навигации.
local Compass = {}
ConsoleMenu.Compass = Compass
-- Набор точек «поблизости», гаснущие после выхода и слоты, которые ещё доигрывают уход.
Compass.arrivalMarkers, Compass.arrivalKeys, Compass.arrivalLeaving, Compass.nearbyFading = {}, {}, {}, {}

-- Числа внешнего вида и работы полосы.
Compass.Constants = {
    WIDTH = 640,
    HEIGHT = 18, -- Высота совпадает с полосой опыта.
    DEFAULT_Y = -48, -- Верх совпадает с полосой опыта.
    MACBOOK_OFFSET = 16,
    FONT_SIZE = 14, -- Стороны света и второстепенная подпись.
    TITLE_FONT_SIZE = 16, -- Название выбранной точки.
    ICON_SIZE = 30,
    RANGE_WALK = 219,
    RANGE_MOUNT = 437,
    RANGE_FLYING = 875,
    VIEW_ANGLE = 90,
    METERS_PER_YARD = 0.9144,
    NEARBY_METERS = 20,
    NEARBY_MAX = 3, -- Сколько точек держать в режиме «поблизости».
    NEARBY_SLOT_GAP = 8, -- Зазор между подписями соседних слотов.
    NEARBY_BAND_FRACTION = 0.8, -- Доля длины полосы, которую делят слоты.
    NEARBY_MOTION_DURATION = 0.15, -- Появление, уход и сдвиг слотов.
    LINE_THICKNESS = 3,
    LINE_ALPHA = 0.6,
    LINE_FADE_FRACTION = 0.18,
    LINE_COLOR = { r = 1.0, g = 0.960784, b = 0.772549 },
    POINTER_HEIGHT = 6,
    POINTER_GAP = 2,
    POINTER_ALPHA = 0.4,
    HEADING_GAP = 12,
    HEADING_ALPHA = 1,
    MINOR_TICK_ALPHA = 0.1,
    DISCOVERY_INTERVAL = 2,
    DISCOVERY_BUDGET_MS = 0.75,
    DISCOVERY_STEPS = 32,
    DISCOVERY_MIN_INTERVAL = 0.2,
    SORT_INTERVAL = 0.1,
    BEARING_REFRESH_INTERVAL = 0.05,
    BEARING_RESET_DISTANCE = 64,
    POSITION_SYNC_INTERVAL = 1,
    TICK_STEP = 15,
    CARDINAL_STEP = 90,
    FULL_TURN = 360,
    HALF_TURN = 180,
    MAX_MARKERS = 24,
    MARKER_BASE_LEVEL = 1,
    EDGE_INSET = 12,
    EDGE_FADE_FRACTION = 0.25,
    EDGE_CLIP_FRACTION = 0.18,
    MARKER_RETAINED_DISTANCE_SQUARED = 0.64,
    MARKER_REVEAL_DELAY = 0.08,
    MARKER_APPEAR_DURATION = 0.2,
    ARRIVAL_BLEND_DURATION = 0.15,
    MARKER_SMOOTH_TIME = 0.05,
    MARKER_SMOOTH_SNAP = 80,
    MARKER_RANGE_FADE_FRACTION = 0.05,
    MARKER_RANGE_FADE_YARDS = 100,
    MARKER_OUTLINE = 1,
    MARKER_OUTLINE_ALPHA = 0.9,
    MARKER_ICON_SUBLEVEL = 2,
    MARKER_SYMBOL_SUBLEVEL = 3,
    MARKER_SHADOW_SUBLEVEL = 1,
    BASIC_CHEST_ATLAS = "vignetteloot",
    BASIC_CHEST_SCALE = 0.9,
    DECOR_VENDOR_ATLAS = "housing-decor-vendor_32",
    DECOR_VENDOR_SCALE = 0.8, -- Родной рисунок рассчитан на 24 пикселя из 32.
    TRACKED_GLOW_ATLAS = "housing-basic-panel-gradient-header-bg",
    TRACKED_GLOW_WIDTH_SCALE = 9,
    TRACKED_GLOW_HEIGHT_SCALE = 2.5,
    TRACKED_GLOW_DROP = 2, -- На сколько пикселей опустить подсветку, чтобы её линия совпала с полосой.
    SELECTION_MARKER_SCALE = 0.78125,
    SELECTION_MARKER_ATLAS = "Waypoint-MapPin-Tracked",
    SELECTION_MARKER_SUBLEVEL = 4,
    TICK_WIDTH = 1,
    TICK_HEIGHT = 2,
    LABEL_GAP = 4,
    LABEL_CAPTION_ALPHA = 0.6,
    LINE_Y_FRACTION = -0.22,
    DETAIL_ANGLE = 12,
    WAYPOINT_PRIORITY = 1,
    TRACKED_QUEST_PRIORITY = 2,
    VIGNETTE_PRIORITY = 3,
    QUEST_PRIORITY = 4,
    WORLD_QUEST_PRIORITY = 5,
    POI_PRIORITY = 6,
    FALLBACK_ATLAS = "Waypoint-MapPin-Untracked",
    SHADOW_OFFSET = 1,
    WAYPOINT_MATCH_EPSILON = 0.00001,
    PEEK_DESTINATION_EPSILON = 0.00001,
}

-- Масштаб значка по атласу, если родной рисунок крупнее остальных.
do
    local C = Compass.Constants
    C.MARKER_ATLAS_SCALES = {
        [C.BASIC_CHEST_ATLAS] = C.BASIC_CHEST_SCALE,
        [C.DECOR_VENDOR_ATLAS] = C.DECOR_VENDOR_SCALE,
    }
end

-- Поля оформления значка, которые переносятся с исходной точки на путевую.
Compass.Constants.MARKER_ART_FIELDS = {
    "texture",
    "texLeft",
    "texRight",
    "texTop",
    "texBottom",
    "colorR",
    "colorG",
    "colorB",
    "sourceAlpha",
    "sizeScale",
}

-- Квадрат дальности прибытия в ярдах, чтобы не извлекать корень на каждом кадре.
do
    local C = Compass.Constants
    local yards = C.NEARBY_METERS / C.METERS_PER_YARD
    C.NEARBY_YARDS_SQUARED = yards * yards
end
