-- Constants.lua
-- Постоянные размеры и правила полосы навигации.

local ConsoleMenu = _G.ConsoleMenu

-- Состояние и функции полосы навигации.
local Compass = {}
ConsoleMenu.Compass = Compass
-- Набор точек «поблизости», гаснущие после выхода из него, значки за радиусом, которые ещё доигрывают скрытие, и скрытие выбранной цели.
Compass.arrivalMarkers, Compass.arrivalKeys, Compass.arrivalLeaving, Compass.nearbyFading, Compass.rangeLeaving =
    {}, {}, {}, {}, {}
Compass.hideNavigationOnBar = false

-- Числа внешнего вида и работы полосы.
Compass.Constants = {
    WIDTH = 640,
    HEIGHT = 18, -- Высота совпадает с полосой опыта.
    DEFAULT_Y = -48, -- Верх совпадает с полосой опыта.
    MACBOOK_OFFSET = 10,
    FONT_SIZE = 15, -- Стороны света и второстепенная подпись.
    TITLE_FONT_SIZE = 16, -- Название выбранной точки.
    ICON_SIZE = 32, -- Запасной размер, если игра не сообщила ширину и высоту.
    RANGE_WALK = 219,
    RANGE_MOUNT = 437,
    RANGE_FLYING = 875,
    VIEW_ANGLE = 90,
    METERS_PER_YARD = 0.9144,
    NEARBY_METERS = 20,
    NEARBY_MAX = 3, -- Сколько точек держать в режиме «поблизости».
    NEARBY_SLOT_GAP = 8, -- Зазор между подписями соседних слотов.
    NEARBY_BAND_FRACTION = 0.8, -- Доля длины полосы, которую делят слоты.
    NEARBY_MOTION_DURATION = 0.15, -- Сдвиг слотов и смена ширины подписи.
    LINE_THICKNESS = 4,
    LINE_ALPHA = 0.6,
    LINE_FADE_FRACTION = 0.18,
    LINE_COLOR = { r = 0xF3 / 255, g = 0xE8 / 255, b = 0xA1 / 255 },
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
    MARKER_APPEAR_DURATION = 0.2, -- Появление и скрытие значка целиком.
    ARRIVAL_BLEND_DURATION = 0.15,
    MARKER_SMOOTH_TIME = 0.05,
    MARKER_SMOOTH_SNAP = 80,
    MARKER_OUTLINE = 1,
    MARKER_OUTLINE_ALPHA = 0.9,
    MARKER_ICON_SUBLEVEL = 2,
    MARKER_BACKGROUND_SUBLEVEL = 1, -- Круг под символом.
    MARKER_SHADOW_SUBLEVEL = 0, -- Обводка по внешнему силуэту.
    QUEST_PROGRESS_ATLAS = "Quest-In-Progress-Icon-yellow",
    QUEST_PROGRESS_FOCUSED_ATLAS = "Quest-In-Progress-Icon-Brown", -- Точки выбранного задания в процессе.
    QUEST_PIN_BACKGROUND = "UI-QuestPoi-QuestNumber", -- Обычный круг точки на карте.
    QUEST_PIN_BACKGROUND_FOCUSED = "UI-QuestPoi-QuestNumber-SuperTracked", -- Жёлтый круг выбранного задания.
    BONUS_OBJECTIVE_BACKGROUND = "worldquest-questmarker-epic", -- Пышный круг дополнительной цели.
    ELITE_WORLD_QUEST_UNDERLAY = "worldquest-questmarker-dragon", -- Рамка элитного мирового задания.
    TRACKED_GLOW_ATLAS = "housing-basic-panel-gradient-header-bg",
    TRACKED_GLOW_WIDTH_SCALE = 9, -- Ширина подсветки относительно запасного размера значка.
    TRACKED_GLOW_HEIGHT_SCALE = 2.5, -- Высота подсветки относительно запасного размера значка.
    TRACKED_GLOW_DROP = 5, -- На сколько пикселей опустить подсветку, чтобы её линия совпала с полосой.
    TICK_WIDTH = 1,
    TICK_HEIGHT = 2,
    LABEL_GAP = 4,
    LABEL_CAPTION_GAP = 8, -- Отступ между названием и второстепенной подписью.
    LABEL_CAPTION_ALPHA = 0.6,
    LABEL_SHOW_ALPHA = 0.8, -- Подпись появляется, когда значок уже хорошо виден.
    LABEL_HIDE_ALPHA = 0.35, -- Подпись гаснет, когда значок снова становится тусклым.
    LABEL_FADE_DURATION = 0.2, -- То же время, что у появления значка.
    LABEL_SHADOW_TEXTURE = "Interface\\AddOns\\ConsoleMenu\\Assets\\HalfShadow.png",
    LABEL_SHADOW_FADE = 128, -- Запас высоты, чтобы мягкий край рисунка ушёл ниже текста.
    LABEL_SHADOW_OFFSET_Y = 0, -- Сдвиг нижней подложки от края полоски.
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
    "iconWidth",
    "iconHeight",
    "backgroundAtlas",
    "backgroundWidth",
    "backgroundHeight",
    "underlayAtlas",
    "underlayWidth",
    "underlayHeight",
    "questProgress",
    "questClassification",
}

-- Круг точки на карте по классу задания.
Compass.Constants.QUEST_PIN_BACKGROUNDS = {
    [Enum.QuestClassification.Legendary] = "UI-QuestPoiLegendary-QuestNumber",
    [Enum.QuestClassification.Campaign] = "UI-QuestPoiCampaign-QuestNumber",
    [Enum.QuestClassification.Calling] = "UI-QuestPoiCampaign-QuestNumber",
    [Enum.QuestClassification.Recurring] = "UI-QuestPoiRecurring-QuestNumber",
    [Enum.QuestClassification.Important] = "UI-QuestPoiImportant-QuestNumber",
    [Enum.QuestClassification.Meta] = "UI-QuestPoiWrapper-QuestNumber",
}

-- Жёлтый круг выбранного задания в процессе по классу.
Compass.Constants.QUEST_PIN_BACKGROUNDS_FOCUSED = {
    [Enum.QuestClassification.Legendary] = "UI-QuestPoiLegendary-QuestNumber-SuperTracked",
    [Enum.QuestClassification.Campaign] = "UI-QuestPoiCampaign-QuestNumber-SuperTracked",
    [Enum.QuestClassification.Calling] = "UI-QuestPoiCampaign-QuestNumber-SuperTracked",
    [Enum.QuestClassification.Recurring] = "UI-QuestPoiRecurring-QuestNumber-SuperTracked",
    [Enum.QuestClassification.Important] = "UI-QuestPoiImportant-QuestNumber-SuperTracked",
    [Enum.QuestClassification.Meta] = "UI-QuestPoiWrapper-QuestNumber-SuperTracked",
}

-- Размер значка по имени атласа, если родной рисунок не подходит для полосы.
Compass.Constants.MARKER_ATLAS_SIZES = {}

-- Квадрат дальности прибытия в ярдах, чтобы не извлекать корень на каждом кадре.
do
    local C = Compass.Constants
    local yards = C.NEARBY_METERS / C.METERS_PER_YARD
    C.NEARBY_YARDS_SQUARED = yards * yards
end
