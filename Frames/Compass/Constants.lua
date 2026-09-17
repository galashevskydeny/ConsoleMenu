-- Constants.lua
-- Постоянные размеры и правила полосы навигации.

local ConsoleMenu = _G.ConsoleMenu

-- Состояние и функции полосы навигации.
local Compass = {}
ConsoleMenu.Compass = Compass
-- Набор точек «поблизости», гаснущие после выхода из него, значки за радиусом, которые ещё доигрывают скрытие, и скрытие выбранной цели.
Compass.arrivalMarkers, Compass.arrivalKeys, Compass.arrivalLeaving, Compass.nearbyFading, Compass.rangeLeaving =
    {}, {}, {}, {}, {}
-- Зафиксированные места и ещё не показанные точки на время перестроения ряда.
Compass.nearbyFrozenPositions, Compass.nearbyDeferredKeys, Compass.nearbyLiveKeys = {}, {}, {}
Compass.hideNavigationOnBar = false
-- Устойчивый признак области задания: не меняется от разового сбоя на границе.
Compass.questAreaState = {}

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
    NEARBY_METERS = 10,
    NEARBY_LEAVE_METERS = 12, -- Дальше этого радиуса точка покидает уже открытый ряд.
    NEARBY_MAX = 3, -- Сколько точек держать в режиме «поблизости».
    NEARBY_SLOT_GAP = 8, -- Зазор между подписями соседних слотов.
    NEARBY_BAND_FRACTION = 0.8, -- Доля длины полосы, которую делят слоты.
    NEARBY_MOTION_DURATION = 0.24, -- Сдвиг слотов внутри уже открытого ряда.
    NEARBY_RELAYOUT_DURATION = 0.24, -- Разъезд значков, пока подписи скрыты.
    NEARBY_LABEL_HIDE_DURATION = 0.08, -- Скрытие подписи перед перестановкой точек.
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
    BEARING_HOLD_YARDS = 2, -- Ближе этого расстояния азимут держим, чтобы значок не скакал.
    NAVIGATION_HIDE_HOLD = 0.15, -- Пауза перед скрытием или возвратом выбранной цели.
    QUEST_AREA_HOLD = 0.15, -- Пауза перед сменой признака области задания.
    NEARBY_NAME_SWAP_METERS = 2, -- Запас, с которым одноимённая точка занимает чужой слот.
    POSITION_SYNC_INTERVAL = 1,
    TICK_STEP = 15,
    CARDINAL_STEP = 90,
    FULL_TURN = 360,
    HALF_TURN = 180,
    MAX_MARKERS = 24,
    MARKER_BASE_LEVEL = 2, -- Выше рамки линии, чтобы значок не уходил под полоску.
    EDGE_INSET = 12,
    EDGE_FADE_FRACTION = 0.25,
    EDGE_CLIP_FRACTION = 0.18,
    MARKER_RETAINED_DISTANCE_SQUARED = 0.64,
    MARKER_REVEAL_DELAY = 0.08,
    MARKER_BATCH_STAGGER = 0.05, -- Пауза между значками одной пачки.
    MARKER_APPEAR_DURATION = 0.2, -- Появление и скрытие значка целиком.
    MARKER_ICON_START_SCALE = 0.75, -- Начальный размер значка при появлении.
    MARKER_ICON_PEAK_SCALE = 1.06, -- Лёгкое превышение размера перед посадкой.
    MARKER_ICON_END_SCALE = 0.75, -- Размер значка в конце скрытия.
    MARKER_ICON_GROW_DURATION = 0.18, -- Рост значка при появлении.
    MARKER_LABEL_DELAY = 0.08, -- Пауза перед проявлением подписи.
    MARKER_LABEL_DURATION = 0.2, -- Проявление и скрытие подписи.
    MARKER_MOTION_DURATION = 0.24, -- Переезд значка к новому месту.
    MAX_ANIMATION_STEP = 0.04, -- Верхняя граница шага времени, чтобы при задержке кадра не было скачка.
    ARRIVAL_BLEND_DURATION = 0.24,
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
    BONUS_OBJECTIVE_BACKGROUND_FOCUSED = "worldquest-questmarker-epic-supertracked", -- Пышный круг выбранной дополнительной цели.
    EVENT_PIN_BACKGROUND = "worldquest-questmarker-epic", -- Круг события на карте.
    EVENT_PIN_BACKGROUND_FOCUSED = "worldquest-questmarker-epic-supertracked", -- Круг выбранного события.
    EVENT_PIN_ATLAS = "UI-EventPoi-Horn-big", -- Запасной символ события.
    EVENT_PIN_ICON_SCALE = 0.72, -- Символ события чуть меньше круга, как на карте.
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
    LABEL_FADE_DURATION = 0.2, -- Скрытие и проявление подписи.
    LABEL_SHADOW_HOLD = 0.2, -- Пауза, в которую тень не гаснет, если уже подходит новая точка.
    LABEL_SHADOW_TEXTURE = "Interface\\AddOns\\ConsoleMenu\\Assets\\HalfShadow.png",
    LABEL_SHADOW_FADE = 128, -- Запас высоты, чтобы мягкий край рисунка ушёл ниже текста.
    LABEL_SHADOW_OFFSET_Y = 0, -- Сдвиг нижней подложки от края полоски.
    LINE_Y_FRACTION = -0.22,
    DETAIL_ANGLE = 12, -- Появление центральной подписи.
    DETAIL_HIDE_ANGLE = 18, -- Пока точка в этом конусе, центральная подпись не пропадает.
    DETAIL_SWITCH_HOLD = 0.12, -- Новая точка должна побыть ближе, прежде чем сменить надпись.
    DETAIL_EMPTY_HOLD = 0.1, -- Пауза без точки в центре, прежде чем полностью скрыть подпись.
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
    "backgroundAtlasFocused",
    "backgroundWidthFocused",
    "backgroundHeightFocused",
    "iconWidthFocused",
    "iconHeightFocused",
    "underlayAtlas",
    "underlayWidth",
    "underlayHeight",
    "questProgress",
    "questComplete",
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

-- Квадраты дальности входа и выхода в ярдах, чтобы не извлекать корень на каждом кадре.
do
    local C = Compass.Constants
    local enterYards = C.NEARBY_METERS / C.METERS_PER_YARD
    local leaveYards = C.NEARBY_LEAVE_METERS / C.METERS_PER_YARD
    local swapYards = C.NEARBY_NAME_SWAP_METERS / C.METERS_PER_YARD
    C.NEARBY_YARDS_SQUARED = enterYards * enterYards
    C.NEARBY_LEAVE_YARDS_SQUARED = leaveYards * leaveYards
    C.NEARBY_NAME_SWAP_YARDS_SQUARED = swapYards * swapYards
    C.BEARING_HOLD_YARDS_SQUARED = C.BEARING_HOLD_YARDS * C.BEARING_HOLD_YARDS
end
