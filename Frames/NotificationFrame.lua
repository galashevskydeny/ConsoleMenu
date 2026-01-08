local ConsoleMenu = _G.ConsoleMenu

local frameWidth = 304
local frameHeight = 56
local captionPadding = 4

local titleFontSize = 24
local fontSize = 20
local captionFontSize = 16

local animationDuration = 0.3
local delay = 0.5

local notificationUpdateTimer = nil

local NotificationEventPriority = {
    UI_ERROR_MESSAGE = 1,

    CHAT_MSG_MONEY = 3,
    CHAT_MSG_COMBAT_FACTION_CHANGE = 3,
    CURRENCY_DISPLAY_UPDATE = 3,
    PERKS_PROGRAM_CURRENCY_AWARDED = 3,
    UPDATE_PENDING_MAIL = 2,

    ZONE_CHANGED_NEW_AREA = 2,
    ZONE_CHANGED = 2,
    ZONE_CHANGED_INDOORS = 2,
    UI_INFO_MESSAGE = 2,
}

local NotificationDuration = {
    UI_ERROR_MESSAGE = 3,

    CHAT_MSG_MONEY = 5,
    CHAT_MSG_COMBAT_FACTION_CHANGE = 5,
    CURRENCY_DISPLAY_UPDATE = 5,
    PERKS_PROGRAM_CURRENCY_AWARDED = 5,
    UPDATE_PENDING_MAIL = 10,

    ZONE_CHANGED_NEW_AREA = 5,
    ZONE_CHANGED = 5,
    ZONE_CHANGED_INDOORS = 5,
    UI_INFO_MESSAGE = 5,
}

local ignoredCurrencies = {
    [3372] = true, -- Бронза (получаемая при полетах)
    [395] = true, -- Очки справедливости
    [396] = true, -- Очки доблести
    [1171] = true, -- Знания об артефакте
    [1191] = true, -- Доблесть
    [1324] = true, -- Киражский знак признания Орды
    [1325] = true, -- Киражский знак признания Альянса
    [1347] = true, -- Legionfall Building - Personal Tracker - Mage Tower (Hidden)
    [1349] = true, -- Legionfall Building - Personal Tracker - Command Tower (Hidden)
    [1350] = true, -- Legionfall Building - Personal Tracker - Nether Tower (Hidden)
    [1501] = true, -- Извивающаяся сущность
    [1506] = true, -- Путевой камень Аргуса
    [1540] = true, -- Древесина
    [1541] = true, -- Железо
    [1559] = true, -- Эссенция бури
    [1579] = true, -- Защитники Азерот
    [1592] = true, -- Орден Пылающих Углей
    [1593] = true, -- Адмиралтейство Праудмуров
    [1594] = true, -- Орден Возрождения Шторма
    [1595] = true, -- Экспедиция Таланджи
    [1596] = true, -- Жители Вол'дуна
    [1597] = true, -- Империя Зандалари
    [1598] = true, -- Тортолланские искатели
    [1599] = true, -- 7-й легион
    [1600] = true, -- Армия Чести
    [1703] = true, -- Валюта за участие в сезоне рейтинговых PvP-игр
    [1705] = true, -- Warfronts - Personal Tracker - Iron in Chest (Hidden)
    [1714] = true, -- Warfronts - Personal Tracker - Wood in Chest (Hidden)
    [1757] = true, -- Ульдумский союз
    [1722] = true, -- Азеритовая руда
    [1723] = true, -- Древесина
    [1728] = true, -- Фантазма
    [1738] = true, -- Освобожденные
    [1739] = true, -- Анкоа
    [1740] = true, -- Ржавоболтское сопротивление (скрыто)
    [1742] = true, -- Ржавоболтское сопротивление
    [1744] = true, -- Зараженная реликвия
    [1745] = true, -- Назжатарский союзник: Нери Остроерш
    [1746] = true, -- Назжатарский союзник: Вим Соленодух
    [1747] = true, -- Назжатарский союзник: Поэн Солежабрик
    [1748] = true, -- Назжатарский союзник: мастер клинка Иновари
    [1749] = true, -- Назжатарский союзник: мастер охоты Акана
    [1750] = true, -- Назжатарский союзник: оракул Ори
    [1752] = true, -- Улей Медокрылов
    [1758] = true, -- Раджани
    [1761] = true, -- Урон противников
    [1762] = true, -- Здоровье противников
    [1763] = true, -- Смерти
    [1769] = true, -- Опыт за задания (стандартный, скрытое)
    [1794] = true, -- Анима искупления
    [1804] = true, -- Перерожденные
    [1805] = true, -- Неумирающая армия
    [1806] = true, -- Дикая Охота
    [1807] = true, -- Двор Жнецов
    [1808] = true, -- Направленная анима
    [1810] = true, -- Очищенная душа
    [1822] = true, -- Известность
    [1837] = true, -- Пепельный двор
    [1838] = true, -- Графиня
    [1839] = true, -- Рендл и Дуборыл
    [1840] = true, -- Камнелоб
    [1841] = true, -- Хранитель склепа Каззир
    [1842] = true, -- Баронесса Вайш
    [1843] = true, -- Изобретатель чумы Марилет
    [1844] = true, -- Великий мастер Воул
    [1845] = true, -- Александрос Могрейн
    [1846] = true, -- Сика
    [1847] = true, -- Клейя и Пелагий
    [1848] = true, -- Полемарх Адрест
    [1849] = true, -- Миканикос
    [1850] = true, -- Чуфа
    [1851] = true, -- Дроман Алиот
    [1852] = true, -- Капитан-егерь Корейн
    [1853] = true, -- Леди Лунная Ягода
    [1877] = true, -- Бонус к опыту
    [1878] = true, -- Штопальщики
    [1880] = true, -- Ве'нари
    [1883] = true, -- Энергия проводника медиума
    [1884] = true, -- Нераскаявшиеся
    [1887] = true, -- Двор Ночи
    [1888] = true, -- Чесночник
    [1889] = true, -- Прогресс кампании приключений
    [1891] = true, -- Честь (рейтинговые бои)
    [1902] = true, -- 9.1 - Torghast XP - Prototype - LJS
    [1903] = true, -- Невидимая награда
    [1907] = true, -- Легион Смерти
    [1947] = true, -- Дополнительная доблесть
    [1982] = true, -- Просветленные
    [1986] = true, -- Оставшиеся игроки
    [1997] = true, -- Кодекс архивариуса
    [2000] = true, -- Частицы судьбы
    [2002] = true, -- Известность – кентавры Маруук
    [2021] = true, -- Известность – драконья экспедиция
    [2023] = true, -- Знание кузнечного дела Драконьих островов
    [2024] = true, -- Знание алхимии Драконьих островов
    [2025] = true, -- Знание кожевничества Драконьих островов
    [2026] = true, -- Знание портняжного дела Драконьих островов
    [2027] = true, -- Знание инженерного дела Драконьих островов
    [2028] = true, -- Знание начертания Драконьих островов
    [2029] = true, -- Знание ювелирного дела Драконьих островов
    [2030] = true, -- Знание наложения чар Драконьих островов
    [2031] = true, -- Драконья экспедиция
    [2033] = true, -- Знание снятия шкур Драконьих островов
    [2034] = true, -- Знание травничества Драконьих островов
    [2035] = true, -- Знание горного дела Драконьих островов
    [2036] = true, -- Энергия древних путевых врат
    [2087] = true, -- Известность: искарские клыкарры
    [2088] = true, -- Известность в Вальдраккене
    [2094] = true, -- [DNT] AC Major Faction Test Renown
    [2106] = true, -- Союз Вальдраккена
    [2107] = true, -- Консорциум ремесленников – филиал на Драконьих островах
    [2108] = true, -- Кентавры Маруук
    [2109] = true, -- Искарские клыкарры
    [2148] = true, -- Красный дракончик (Залп огня)
    [2149] = true, -- Красный дракончик (Летящее кольцо огня)
    [2150] = true, -- Красный дракончик (Исцеляющее дуновение)
    [2151] = true, -- Красный дракончик (Исцеляющее дыхание)
    [2152] = true, -- Красный дракончик (Усыпляющее рубиновое тепло)
    [2153] = true, -- Красный дракончик (Под красными крыльями)
    [2165] = true, -- Профессия – количество заказов – кузнечное дело
    [2166] = true, -- Жизненная сила возрождения
    [2167] = true, -- Заряды катализатора
    [2169] = true, -- Профессия – количество заказов – кожевничество
    [2170] = true, -- Профессия – количество заказов – алхимия
    [2171] = true, -- Профессия – количество заказов – портняжное дело
    [2172] = true, -- Профессия – количество заказов – инженерное дело
    [2173] = true, -- Профессия – количество заказов – наложение чар
    [2174] = true, -- Профессия – количество заказов – ювелирное дело
    [2175] = true, -- Профессия – количество заказов – начертание
    [2419] = true, -- Test Currency Main [DNT]
    [2231] = true, -- Игроки
    [2244] = true, -- Возвращение в Запретный край – ежедневные задания на известность выполнены
    [2264] = true, -- Account HWM - Helm [DNT]
    [2265] = true, -- Account HWM - Neck [DNT]
    [2266] = true, -- Account HWM - Shoulders [DNT]
    [2267] = true, -- Account HWM - Chest [DNT]
    [2268] = true, -- Account HWM - Waist [DNT]
    [2269] = true, -- Account HWM - Legs [DNT]
    [2270] = true, -- Account HWM - Feet [DNT]
    [2271] = true, -- Account HWM - Wrist [DNT]
    [2272] = true, -- Account HWM - Hands [DNT]
    [2273] = true, -- Account HWM - Ring [DNT]
    [2274] = true, -- Account HWM - Trinket [DNT]
    [2275] = true, -- Account HWM - Cloak [DNT]
    [2276] = true, -- Account HWM - Two Hand [DNT]
    [2277] = true, -- Account HWM - Main Hand [DNT]
    [2278] = true, -- Account HWM - One Hand [DNT]
    [2279] = true, -- Account HWM - One Hand (Second) [DNT]
    [2280] = true, -- Account HWM - Off Hand [DNT]
    [2869] = true, -- 10.2.7 Timewalking Season - Artifact - Head - Undead
    [2402] = true, -- Известность среди лоаммских ниффов
    [2408] = true, -- Дополнительные драконьи камни
    [2409] = true, -- Whelpling Crest Fragment Tracker [DNT]
    [2410] = true, -- Drake Crest Fragment Tracker [DNT]
    [2411] = true, -- Wyrm Crest Fragment Tracker [DNT]
    [2412] = true, -- Aspect Crest Fragment Tracker [DNT]
    [2413] = true, -- 10.1 Professions - Personal Tracker - S2 Spark Drops (Hidden)
    [2420] = true, -- Лоаммские ниффы
    [2533] = true, -- Возрождающееся пламя Тьмы
    [2710] = true, -- Изучение пламени Тьмы
    [2645] = true, -- Признание Соридорми
    [2649] = true, -- [DNT] The Currency Formerly Named Dream Ephemera
    [2652] = true, -- Стражи Сна
    [2653] = true, -- Известность – Стражи Сна
    [2655] = true, -- Воскрешения
    [2706] = true, -- Гребень дракончика из Сна
    [2707] = true, -- Гребень дракона из Сна
    [2708] = true, -- Гребень змея из Сна
    [2709] = true, -- Гребень Аспекта из Сна
    [2715] = true, -- Гребни дракончика из Сна
    [2716] = true, -- Гребни дракона из Сна
    [2717] = true, -- Гребни змея из Сна
    [2718] = true, -- Гребни Аспекта из Сна
    [2774] = true, -- 10.2 Professions - Personal Tracker - S3 Spark Drops (Hidden)
    [2780] = true, -- Echoed Ephemera Tracker [DNT]
    [2784] = true, -- 10.2 Legendary - Progressive Advance - Tracker
    [2785] = true, -- Знание алхимии Каз Алгара
    [2786] = true, -- Знание кузнечного дела Каз Алгара
    [2787] = true, -- Знание наложения чар Каз Алгара
    [2788] = true, -- Знание инженерного дела Каз Алгара
    [2789] = true, -- Знание травничества Каз Алгара
    [2790] = true, -- Знание начертания Каз Алгара
    [2791] = true, -- Знание ювелирного дела Каз Алгара
    [2792] = true, -- Знание кожевничества Каз Алгара
    [2793] = true, -- Знание горного дела Каз Алгара
    [2794] = true, -- Знание снятия шкур Каз Алгара
    [2795] = true, -- Знание портняжного дела Каз Алгара
    [2796] = true, -- Возрождающий сон
    [2799] = true, -- [DNT] Beetle Ranch Invisible Currency
    [2800] = true, -- 10.2.6 Professions - Personal Tracker - S4 Spark Drops (Hidden)
    [2805] = true, -- Пробужденный гребень дракончика
    [2808] = true, -- Пробужденный гребень дракона
    [2810] = true, -- Пробужденный гребень змея
    [2811] = true, -- Пробужденный гребень Аспекта
    [2813] = true, -- Гармонизированный шелк
    [2814] = true, -- Известность – команда Бочконога
    [2819] = true, -- Азеротские Архивы
    [2853] = true, -- 10.2.7 Timewalking Season - Artifact - Cloak - Primary
    [2854] = true, -- 10.2.7 Timewalking Season - Artifact - Cloak - Stamina
    [2855] = true, -- 10.2.7 Timewalking Season - Artifact - Cloak - Critical Strike
    [2856] = true, -- 10.2.7 Timewalking Season - Artifact - Cloak - Haste
    [2857] = true, -- 10.2.7 Timewalking Season - Artifact - Cloak - Leech
    [2858] = true, -- 10.2.7 Timewalking Season - Artifact - Cloak - Mastery
    [2859] = true, -- 10.2.7 Timewalking Season - Artifact - Cloak - Speed
    [2860] = true, -- 10.2.7 Timewalking Season - Artifact - Cloak - Versatility
    [2861] = true, -- 10.2.7 Timewalking Season - Artifact - Head - Aberration
    [2862] = true, -- 10.2.7 Timewalking Season - Artifact - Head - Beast
    [2863] = true, -- 10.2.7 Timewalking Season - Artifact - Head - Demon
    [2864] = true, -- 10.2.7 Timewalking Season - Artifact - Head - Dragonkin
    [2865] = true, -- 10.2.7 Timewalking Season - Artifact - Head - Elemental
    [2866] = true, -- 10.2.7 Timewalking Season - Artifact - Head - Giant
    [2867] = true, -- 10.2.7 Timewalking Season - Artifact - Head - Humanoid
    [2868] = true, -- 10.2.7 Timewalking Season - Artifact - Head - Mechanical
    [2870] = true, -- 10.2.7 Timewalking Season - Artifact - Waist - Physical
    [2871] = true, -- 10.2.7 Timewalking Season - Artifact - Waist - Arcane
    [2872] = true, -- 10.2.7 Timewalking Season - Artifact - Waist - Fire
    [2873] = true, -- 10.2.7 Timewalking Season - Artifact - Waist - Frost
    [2874] = true, -- 10.2.7 Timewalking Season - Artifact - Waist - Holy
    [2875] = true, -- 10.2.7 Timewalking Season - Artifact - Waist - Shadow
    [2876] = true, -- 10.2.7 Timewalking Season - Artifact - Waist - Nature
    [2878] = true, -- Профессии 10.2 – Личный счетчик – Легендарное – Оживленный лист
    [2897] = true, -- Совет Дорногала
    [2898] = true, -- Известность – Ассамблея глубин
    [2899] = true, -- Арати Тайносводья
    [2900] = true, -- Известность – совет Дорногала
    [2901] = true, -- Известность – Арати Тайносводья
    [2902] = true, -- Ассамблея глубин
    [2903] = true, -- Отрезанные нити
    [2904] = true, -- Известность – Отрезанные нити
    [2906] = true, -- Награбленное
    [2907] = true, -- Pirate Booty Visual
    [2908] = true, -- Армия Покорителей
    [2909] = true, -- Операция "Заслон"
    [2910] = true, -- Клакси
    [2911] = true, -- Орден Облачного Змея
    [2912] = true, -- Возрождающееся пробуждение
    [2913] = true, -- Шадо-Пан
    [2914] = true, -- Истертый герб Предвестницы
    [2915] = true, -- Резной герб Предвестницы
    [2916] = true, -- Рунический герб Предвестницы
    [2917] = true, -- Позолоченный герб Предвестницы
    [2918] = true, -- Истертый герб Предвестницы
    [2919] = true, -- Резной герб Предвестницы
    [2920] = true, -- Рунический герб Предвестницы
    [2921] = true, -- Позолоченный герб Предвестницы
    [2922] = true, -- Награбленное
    [3000] = true, -- 10.2.7 Timewalking Season - Random Gem Counter
    [3001] = true, -- 10.2.7 Timewalking Season - Artifact - Cloak - Experience Gain
    [3002] = true, -- Прядильщица (дурная слава)
    [3003] = true, -- Генерал (дурная слава)
    [3004] = true, -- Визирь (дурная слава)
    [3005] = true, -- Генерал (дурная слава)
    [3006] = true, -- Визирь (дурная слава)
    [3007] = true, -- Прядильщица (дурная слава)
    [3009] = true, -- Дополнительные камни доблести
    [3010] = true, -- 10.2.6 Rewards - Personal Tracker - S4 Dinar Drops (Hidden)
    [3011] = true, -- Награбленное
    [3013] = true, -- Концентрация – ювелирное дело
    [3022] = true, -- Известность – вылазки 1-го сезона
    [3023] = true, -- 11.0 Professions - Personal Tracker - S1 Spark Drops (Hidden)
    [3024] = true, -- Декоративный эффект
    [3040] = true, -- Концентрация – кузнечное дело
    [3041] = true, -- Концентрация – портняжное дело
    [3042] = true, -- Концентрация – кожевничество
    [3043] = true, -- Концентрация – начертание
    [3044] = true, -- Концентрация – инженерное дело
    [3045] = true, -- Концентрация – алхимия
    [3046] = true, -- Концентрация – наложение чар
    [3057] = true, -- 11.0 Professions - Tracker - Weekly Alchemy Knowledge
    [3058] = true, -- 11.0 Professions - Tracker - Weekly Blacksmithing Knowledge
    [3059] = true, -- 11.0 Professions - Tracker - Weekly Enchanting Knowledge
    [3060] = true, -- 11.0 Professions - Tracker - Weekly Engineering Knowledge
    [3061] = true, -- 11.0 Professions - Tracker - Weekly Herbalism Knowledge
    [3062] = true, -- 11.0 Professions - Tracker - Weekly Inscription Knowledge
    [3063] = true, -- 11.0 Professions - Tracker - Weekly Jewelcrafting Knowledge
    [3064] = true, -- 11.0 Professions - Tracker - Weekly Leatherworking Knowledge
    [3065] = true, -- 11.0 Professions - Tracker - Weekly Mining Knowledge
    [3066] = true, -- 11.0 Professions - Tracker - Weekly Skinning Knowledge
    [3067] = true, -- 11.0 Professions - Tracker - Weekly Tailoring Knowledge
    [3068] = true, -- Путь участника вылазки
    [3069] = true, -- 11.0 Профессии – Портняжное дело – Рыбная ловля – Каз Алгар – Навык
    [3070] = true, -- 11.0 Профессии – Рыбная ловля – Алгарийская паутинная нить – Внимательность
    [3071] = true, -- 11.0 Профессии – Рыбная ловля – Алгарийская паутинная нить – Навык
    [3072] = true, -- Возврат "Вечного воспламенения"
    [3073] = true, -- 11.0 профессии – Отслеживание – Книга начертания – Знание портняжного дела
    [3074] = true, -- 11.0 профессии – Отслеживание – Книга начертания – Знание снятия шкур
    [3075] = true, -- 11.0 профессии – Отслеживание – Книга начертания – Знание горного дела
    [3076] = true, -- 11.0 профессии – Отслеживание – Книга начертания – Знание кожевничества
    [3077] = true, -- 11.0 профессии – Отслеживание – Книга начертания – Знание ювелирного дела
    [3078] = true, -- 11.0 профессии – Отслеживание – Книга начертания – Знание начертания
    [3079] = true, -- 11.0 профессии – Отслеживание – Книга начертания – Знание травничества
    [3080] = true, -- 11.0 профессии – Отслеживание – Книга начертания – Знание инженерного дела
    [3081] = true, -- 11.0 профессии – Отслеживание – Книга начертания – Знание наложения чар
    [3082] = true, -- 11.0 профессии – Отслеживание – Книга начертания – Знание кузнечного дела
    [3083] = true, -- 11.0 профессии – Отслеживание – Книга начертания – Знание алхимии
    [3085] = true, -- 11.0 Вылазки – персональный счетчик – ежедневное задание Элизы, 1-й сезон (скрыто)
    [3086] = true, -- Боец
    [3087] = true, -- Танк
    [3088] = true, -- Лекарь
    [3094] = true, -- 11.0 Raid - Nerubian - Account Quest Complete Tracker (Hidden)
    [3099] = true, -- 11.0 Рейд – нерубы – валюта: нерубарское убранство (скрыто)
    [3102] = true, -- Жетон торжества бронзовых драконов
    [3103] = true, -- 11.0 Вылазки – система – сезонное свойство – активные события
    [3104] = true, -- 11.0 Вылазки – система – сезонное свойство – максимально возможное количество событий
    [3107] = true, -- Истертый герб Нижней Шахты
    [3108] = true, -- Резной герб Нижней Шахты
    [3109] = true, -- Рунический герб Нижней Шахты
    [3110] = true, -- Позолоченный герб Нижней Шахты
    [3111] = true, -- Истертый герб Нижней Шахты
    [3112] = true, -- Резной герб Нижней Шахты
    [3113] = true, -- Рунический герб Нижней Шахты
    [3114] = true, -- Позолоченный герб Нижней Шахты
    [3115] = true, -- [DNT] Worldsoul Memory Score
    [3116] = true, -- Сущность каджамита
    [3118] = true, -- Картели Нижней Шахты
    [3120] = true, -- Картели Нижней Шахты
    [3128] = true, -- Известность – концерн К'ареша
    [3129] = true, -- Концерн К'ареша
    [3130] = true, -- Renown - Season 2 Delves
    [3131] = true, -- Путь участника вылазки
    [3132] = true, -- 11.1 Professions - Personal Tracker - S2 Spark Drops (Hidden)
    [3135] = true, -- 11.1 Delves - Personal Tracker - S2 Weekly Elise Turn-In(Hidden)
    [3136] = true, -- Клуб лояльности Галаджио
    [3137] = true, -- Renown - Gallagio Loyalty Rewards Club
    [3139] = true, -- Награбленное
    [3140] = true, -- 11.1.5 Arathi - Renown Rank
    [3141] = true, -- Пыль искры звездного света
    [3142] = true, -- EVERGREEN Delves - Tracker - EoD Account Rewards - Weekly Cap
    [3143] = true, -- 11.0 Delves - Bountiful Tracker - Delver's Journey Cap
    [3144] = true, -- 11.0.5 20th Anniversary - Tracker
    [3145] = true, -- 11.0.5 20th Anniversary - Tracker
    [3146] = true, -- 11.0.5 20th Anniversary - Tracker
    [3147] = true, -- 11.0 Delves - Vendor - Bountiful Key Tracker - Cap
    [3173] = true, -- Картель Хитрой Шестеренки
    [3150] = true, -- Знание полуночной алхимии
    [3151] = true, -- Знание полуночного кузнечного дела
    [3152] = true, -- Знание полуночного наложения чар
    [3153] = true, -- Знание полуночного инженерного дела
    [3154] = true, -- Знание полуночного травничества
    [3155] = true, -- Знание полуночного начертания
    [3156] = true, -- Знание полуночного ювелирного дела
    [3157] = true, -- Знание полуночного кожевничества
    [3158] = true, -- Знание полуночного горного дела
    [3159] = true, -- Знание полуночного снятия шкур
    [3160] = true, -- Знание полуночного портняжного дела
    [3169] = true, -- Картель Трюмных Вод
    [3170] = true, -- Картель Трюмных Вод
    [3171] = true, -- Картель Черноводья
    [3172] = true, -- Картель Черноводья
    [3174] = true, -- Картель Хитрой Шестеренки
    [3175] = true, -- Торговая компания
    [3176] = true, -- Торговая компания
    [3177] = true, -- Мрачные Решалы
    [3178] = true, -- Мрачные Решалы
    [3189] = true, -- 12.x Professions - Tracker - Weekly Alchemy Knowledge
    [3190] = true, -- 12.x Professions - Tracker - Weekly Tailoring Knowledge
    [3191] = true, -- 12.x Professions - Tracker - Weekly Skinning Knowledge
    [3192] = true, -- 12.x Professions - Tracker - Weekly Mining Knowledge
    [3193] = true, -- 12.x Professions - Tracker - Weekly Leatherworking Knowledge
    [3194] = true, -- 12.x Professions - Tracker - Weekly Jewelcrafting Knowledge
    [3195] = true, -- 12.x Professions - Tracker - Weekly Inscription Knowledge
    [3196] = true, -- 12.x Professions - Tracker - Weekly Herbalism Knowledge
    [3197] = true, -- 12.x Professions - Tracker - Weekly Engineering Knowledge
    [3198] = true, -- 12.x Professions - Tracker - Weekly Enchanting Knowledge
    [3199] = true, -- 12.x Professions - Tracker - Weekly Blacksmithing Knowledge
    [3200] = true, -- 12.x Professions - Tracker - Insc Book - Tailoring Knowledge
    [3201] = true, -- 12.x Professions - Tracker - Insc Book - Skinning Knowledge
    [3202] = true, -- 12.x Professions - Tracker - Insc Book - Mining Knowledge
    [3203] = true, -- 12.x Professions - Tracker - Insc Book - Leatherworking Know.
    [3204] = true, -- 12.x Professions - Tracker - Insc Book - Jewelcrafting Knowledge
    [3205] = true, -- 12.x Professions - Tracker - Insc Book - Inscription Knowledge
    [3207] = true, -- 12.x Professions - Tracker - Insc Book - Herbalism Knowledge
    [3208] = true, -- 12.x Professions - Tracker - Insc Book - Engineering Knowledge
    [3209] = true, -- 12.x Professions - Tracker - Insc Book - Enchanting Knowledge
    [3210] = true, -- 12.x Professions - Tracker - Insc Book - Blacksmithing Knowledge
    [3211] = true, -- 12.x Professions - Tracker - Insc Book - Alchemy Knowledge
    [3221] = true, -- Репутация у картелей гоблинов
    [3224] = true, -- [DNT] NAK Test Currency
    [3225] = true, -- Сброс специализации кузнечного дела
    [3227] = true, -- Сброс специализации алхимии
    [3228] = true, -- Сброс специализации наложения чар
    [3229] = true, -- Сброс специализации инженерного дела
    [3230] = true, -- Сброс специализации травничества
    [3231] = true, -- Сброс специализации начертания
    [3232] = true, -- Сброс специализации ювелирного дела
    [3233] = true, -- Сброс специализации кожевничества
    [3234] = true, -- Сброс специализации горного дела
    [3235] = true, -- Сброс специализации снятия шкур
    [3236] = true, -- Сброс специализации портняжного дела
    [3250] = true, -- Ограненный кристалл Скверны
    [3253] = true, -- EVERGREEN Delves - Tracker - Mislaid Curiosity - Weekly Cap
    [3254] = true, -- Chase's Test Currency [DNT]
    [3307] = true, -- 11.2 Raid Renown - Manaforge - Raid Buff Acct Tracker
    [3267] = true, -- Закаленная Скверной бронза
    [3269] = true, -- Астральный осколок Бездны
    [3270] = true, -- 11.2 Delves - Personal Tracker - S3 Weekly Elise Turn-In(Hidden)
    [3271] = true, -- Известность – вылазки 3-го сезона
    [3272] = true, -- Путь участника вылазки
    [3278] = true, -- Астральные нити
    [3279] = true, -- 11. Известность (рейд) – Галаджио – отслеживатель усилений для учетной записи в рейде
    [3280] = true, -- 11. Известность (рейд) – Галаджио – отслеживатель ускорения для учетной записи
    [3282] = true, -- Клуб лояльности Галаджио
    [3283] = true, -- Сияние Пламени
    [3285] = true, -- Истертый герб эфириалов
    [3287] = true, -- Резной герб эфириалов
    [3289] = true, -- Рунический герб эфириалов
    [3291] = true, -- Позолоченный герб эфириалов
    [3304] = true, -- Крушители манагорнов
    [3305] = true, -- Известность – Крушители манагорнов
    [3306] = true, -- Крушители манагорнов
    [3308] = true, -- 11.2 Raid Renown - Manaforge Speed Buff Acct Tracker
    [3315] = true, -- Известность – клуб лояльности Галаджио
    [3318] = true, -- Путь участника вылазки
    [3342] = true, -- Герб зари ветерана
    [3344] = true, -- Герб зари защитника
    [3372] = true, -- Бронза
    [3346] = true, -- Герб зари героя
    [3348] = true, -- Герб зари эпохи
    [3354] = true, -- Племя Амани
    [3355] = true, -- Известность – племя Амани
    [3360] = true, -- [DNT] 11.1.5 Midseason - Turbo-Boost Quest Turn-In Tracker
    [3364] = true, -- [DNT] 11.2.5 Midseason - Turbo-Boost Quest Turn-In Tracker
    [3365] = true, -- Двор Луносвета
    [3369] = true, -- Известность – хара'ти
    [3370] = true, -- Хара'ти
    [3371] = true, -- Известность – двор Луносвета
    [3375] = true, -- [DNT] Moth Hunt Tracking Currency
    [3378] = true, -- Светозарный поток маны
    [3386] = true, -- Известность – Охота
    [3387] = true, -- Путь охотника
    [3388] = true, -- Известность – Сингулярность
    [3389] = true, -- Сингулярность
    [3390] = true, -- Странники
    [3391] = true, -- Герб зари искателя приключений
    [3396] = true, -- Тени Закоулка
    [3397] = true, -- Магистры
    [3398] = true, -- Рыцари крови
    [3401] = true, -- 12.0 Delves - Personal Tracker - S1 Weekly Turn-In (Hidden)
    [3409] = true, -- [DNT] 12.0 Midseason - Voidforge Unlock - Turn-In Tracker
    [3410] = true, -- Дуэлянты Зубца убийцы
    [3047] = true, -- Концентрация – ювелирное дело
    [3166] = true, -- Концентрация – ювелирное дело
    [3317] = true, -- Известность – вылазки 1-го сезона
    [3025] = true, -- Декоративный эффект
    [3026] = true, -- Декоративный эффект
    [3027] = true, -- Декоративный эффект
    [3050] = true, -- Концентрация – кузнечное дело
    [3162] = true, -- Концентрация – кузнечное дело
    [3048] = true, -- Концентрация – портняжное дело
    [3168] = true, -- Концентрация – портняжное дело
    [3049] = true, -- Концентрация – кожевничество
    [3167] = true, -- Концентрация – кожевничество
    [3053] = true, -- Концентрация – начертание
    [3165] = true, -- Концентрация – начертание
    [3052] = true, -- Концентрация – инженерное дело
    [3164] = true, -- Концентрация – инженерное дело
    [3054] = true, -- Концентрация – алхимия
    [3161] = true, -- Концентрация – алхимия
    [3051] = true, -- Концентрация – наложение чар
    [3163] = true, -- Концентрация – наложение чар
    [3084] = true, -- 11.0 профессии – Отслеживание – Книга начертания – Знание начертания
    [3206] = true, -- 12.x Professions - Tracker - Insc Book - Inscription Knowledge
    [3248] = true, -- Сброс специализации кузнечного дела
    [3238] = true, -- Сброс специализации алхимии
    [3239] = true, -- Сброс специализации наложения чар
    [3240] = true, -- Сброс специализации инженерного дела
    [3241] = true, -- Сброс специализации травничества
    [3242] = true, -- Сброс специализации начертания
    [3243] = true, -- Сброс специализации ювелирного дела
    [3244] = true, -- Сброс специализации кожевничества
    [3245] = true, -- Сброс специализации горного дела
    [3246] = true, -- Сброс специализации снятия шкур
    [3247] = true, -- Сброс специализации портняжного дела
    [3313] = true, -- 11. Известность (рейд) – Галаджио – отслеживатель усилений для учетной записи в рейде
    [3314] = true, -- 11. Известность (рейд) – Галаджио – отслеживатель ускорения для учетной записи
}

local deduplicationDuration = 45

-- Функция для добавления уведомлений
function ConsoleMenu:AddNotification(event, message, caption, identifier, value)
    if not ConsoleMenu or not ConsoleMenu.Notifications then
        return
    end

    local priority = NotificationEventPriority[event] or 1

    -- Создаем таблицу субтитра
    local notificationData = {
        event = event,
        text = message,
        caption = caption,
        identifier = identifier,
        value = value,
        startTime = GetTime(),
    }

    table.insert(ConsoleMenu.Notifications, notificationData)

    if not notificationUpdateTimer then
        ConsoleMenu:NotificationFrameUpdate()
    elseif notificationUpdateTimer and NotificationEventPriority[event] == 1 then
        ConsoleMenu:NotificationFrameUpdate()
    end

    return
end

-- Функция для очистки Deduplication
local function RemoveOldDeduplication()
    if not ConsoleMenu or not ConsoleMenu.Deduplication then return end
    local currentTime = GetTime()
    for key in pairs(ConsoleMenu.Deduplication) do
        if ConsoleMenu.Deduplication[key] <= currentTime then
            ConsoleMenu.Deduplication[key] = nil
        end
    end
end

-- Функция для получения уведомления с наивысшим приоритетом
local function GetTopPriorityNotification()
    -- Обходим таблицу ConsoleMenu.Notifications с конца
    if not ConsoleMenu or not ConsoleMenu.Notifications or #ConsoleMenu.Notifications == 0 then
        return nil
    end

    local minPriority = nil
    local minNotification = nil

    for i = #ConsoleMenu.Notifications, 1, -1 do
        
        local notification = ConsoleMenu.Notifications[i]

        local duration = NotificationDuration and NotificationDuration[notification.event] or 5

        local priority = NotificationEventPriority and NotificationEventPriority[notification.event] or 1

        if not minPriority or priority < minPriority then
            minPriority = priority
            minNotification = notification
        end
    end

    return minNotification

end

-- Функция для группировки уведомлений
local function GetGroupedNotification(notification)

    if not notification then return end

    if notification.event == "UI_ERROR_MESSAGE" then
        -- Удаляем все уведомления с таким же текстом или просроченные ошибки
        for i = #ConsoleMenu.Notifications, 1, -1 do
            if ConsoleMenu.Notifications[i].text == notification.text or (GetTime() - ConsoleMenu.Notifications[i].startTime > NotificationDuration[notification.event]) then
                table.remove(ConsoleMenu.Notifications, i)
            end
        end

        -- Если уведомление просрочено, не игнорируем
        if GetTime() - notification.startTime > NotificationDuration[notification.event] then return end

        
    elseif notification.event == "CHAT_MSG_MONEY" then
        -- Удаляем отображаемое уведомление
        for i = #ConsoleMenu.Notifications, 1, -1 do
            if ConsoleMenu.Notifications[i] == notification then
                table.remove(ConsoleMenu.Notifications, i)
            end
        end
    elseif notification.event == "CHAT_MSG_COMBAT_FACTION_CHANGE" then
        -- Используем подход из WeakAura: паттерн с %D (не-цифра) для правильного разделения
        -- %D гарантирует, что мы находим число, окруженное не-цифрами, что игнорирует числа в форматировании WoW
        local previousText, value, nextText = notification.text:match("^(.*%D)([%+%-]?%d+)(%D*)$")
        
        if not previousText or not value or not nextText then
            return notification
        end
        
        local sum = 0
        for i = #ConsoleMenu.Notifications, 1, -1 do
            local n = ConsoleMenu.Notifications[i]
            if n.event == notification.event then
                local nPreviousText, nValue, nNextText = n.text:match("^(.*%D)([%+%-]?%d+)(%D*)$")
                if nPreviousText == previousText and nNextText == nextText and nValue then
                    sum = sum + (tonumber(nValue) or 0)
                    table.remove(ConsoleMenu.Notifications, i)
                end
            end
        end
        notification.value = sum
        notification.text = previousText .. sum .. nextText

    elseif notification.event == "CURRENCY_DISPLAY_UPDATE" then
        -- Просуммировать value всех записей с notification.identifier и удалить
        if not notification.identifier then return end

        local sum = 0
        for i = #ConsoleMenu.Notifications, 1, -1 do
            local n = ConsoleMenu.Notifications[i]
            if n.event == notification.event and n.identifier == notification.identifier and n.value then
                sum = sum + n.value
                table.remove(ConsoleMenu.Notifications, i)
            end
        end
        notification.value = sum
        
        local info = C_CurrencyInfo.GetCurrencyInfo(notification.identifier)
        
        if info and info.name then
            local title = _G["PROFESSIONS_CRAFT_OUTPUT_TITLE"]
            local msg = string.format("%s %s x%d.", title, info.name, sum)
            notification.text = msg
        end

    elseif notification.event == "PERKS_PROGRAM_CURRENCY_AWARDED" then

        -- Удаляем отображаемое уведомление
        for i = #ConsoleMenu.Notifications, 1, -1 do
            if ConsoleMenu.Notifications[i] == notification then
                table.remove(ConsoleMenu.Notifications, i)
            end
        end
        
        local info = C_CurrencyInfo.GetBasicCurrencyInfo(notification.identifier)
        local title = _G["PROFESSIONS_CRAFT_OUTPUT_TITLE"]
        notification.text = string.format("%s %s x%d.", title, info.name, notification.value)

    elseif notification.event == "UPDATE_PENDING_MAIL" then

        -- Удаляем все уведомления с таким же событием
        for i = #ConsoleMenu.Notifications, 1, -1 do
            if ConsoleMenu.Notifications[i].event == notification.event then
                table.remove(ConsoleMenu.Notifications, i)
            end
        end
    elseif notification.event == "ZONE_CHANGED_NEW_AREA" or notification.event == "ZONE_CHANGED" or notification.event == "ZONE_CHANGED_INDOORS" then
        local zoneText = GetMinimapZoneText()
        notification.text = zoneText

        -- Удаляем все уведомления о смене области или изучении новой области
        for i = #ConsoleMenu.Notifications, 1, -1 do
            if ConsoleMenu.Notifications[i].event == "ZONE_CHANGED_NEW_AREA" or ConsoleMenu.Notifications[i].event == "ZONE_CHANGED" or ConsoleMenu.Notifications[i].event == "ZONE_CHANGED_INDOORS" or (ConsoleMenu.Notifications[i].event == "UI_INFO_MESSAGE" and ConsoleMenu.Notifications[i].identifier == 408 and ConsoleMenu.Notifications[i].text == zoneText) then
                if ConsoleMenu.Notifications[i].event == "UI_INFO_MESSAGE" and ConsoleMenu.Notifications[i].identifier == 408 and ConsoleMenu.Notifications[i].text == zoneText then
                    notification.caption = ConsoleMenu.Notifications[i].caption
                end

                table.remove(ConsoleMenu.Notifications, i)
            end
        end

        if ConsoleMenu.Deduplication[zoneText] and GetTime() <= ConsoleMenu.Deduplication[zoneText] then return end

    elseif notification.event == "UI_INFO_MESSAGE" then

        -- Удаляем отображаемое уведомление
        for i = #ConsoleMenu.Notifications, 1, -1 do
            if ConsoleMenu.Notifications[i] == notification then
                table.remove(ConsoleMenu.Notifications, i)
            end
        end

    end

    return notification
end

-- Функция для обновления NotificationFrame
function ConsoleMenu:NotificationFrameUpdate()
    if not ConsoleMenu or not ConsoleMenu.Notifications then
        return
    end

    local notification = GetTopPriorityNotification()

    if ConsoleMenuFrame.NotificationFrame:IsShown() and notification and NotificationEventPriority[notification.event] ~= 1 then
        C_Timer.After(animationDuration + delay, function()
            ConsoleMenu:NotificationFrameUpdate()
        end)
        return
    end

    if ConsoleMenuFrame.NotificationFrame:IsShown() and ConsoleMenuFrame.NotificationFrame.notification and (GetTime() - ConsoleMenuFrame.NotificationFrame.notification.startTime >= NotificationDuration[ConsoleMenuFrame.NotificationFrame.notification.event]) then
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.NotificationFrame)
        ConsoleMenuFrame.NotificationFrame.notification = nil
    end

    notification = GetGroupedNotification(notification)

    if notification then
        ConsoleMenuFrame.NotificationFrame.Text:SetText(notification.text)

        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.QueueStatusToastFrame)
        
        C_Timer.After(animationDuration + delay, function()
            ConsoleMenu:AnimatedShow(ConsoleMenuFrame.NotificationFrame)
            ConsoleMenuFrame.NotificationFrame.notification = notification
        end)

        local event = notification.event

        if event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or (event == "UI_INFO_MESSAGE" and notification.identifier == 408) then
            ConsoleMenu.Deduplication[notification.text] = GetTime() + deduplicationDuration
        end

        local frame = ConsoleMenuFrame.NotificationFrame
        if event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" or (event == "UI_INFO_MESSAGE" and notification.identifier == 408) then
            frame.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", titleFontSize, "")
        else
            frame.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")
        end

        if notification.caption then
            frame.Caption:SetText(notification.caption)
            frame.Caption:Show()
        else
            frame.Caption:Hide()
        end

        local duration = NotificationDuration[notification.event] or 5
    
        if duration then
            if notificationUpdateTimer then
                notificationUpdateTimer:Cancel()
            end

            notificationUpdateTimer = C_Timer.NewTimer(duration, function()
                notificationUpdateTimer = nil
                -- Скрываем текущее уведомление с анимацией
                ConsoleMenu:AnimatedHide(ConsoleMenuFrame.NotificationFrame)
                ConsoleMenuFrame.NotificationFrame.notification = nil
                -- Ждем окончания анимации исчезновения перед проверкой следующего уведомления
                C_Timer.After(animationDuration + delay, function()
                    -- После отображения проверяем, есть ли еще уведомления в очереди
                    ConsoleMenu:NotificationFrameUpdate()
                end)
            end)
        end
    else
        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.NotificationFrame)
        ConsoleMenuFrame.NotificationFrame.notification = nil

        C_Timer.After(animationDuration + delay, function()
            ConsoleMenu:QueueStatusToastFrameUpdate()
        end)

        if notificationUpdateTimer then
            notificationUpdateTimer:Cancel()
            notificationUpdateTimer = nil
        end

    end

    return
end

-- Функция для инициализации NotificationFrame
function ConsoleMenu:SetNotificationFrame()

    if not ConsoleMenu.Notifications then
        ConsoleMenu.Notifications = {}
    end

    if not ConsoleMenu.Deduplication then
        ConsoleMenu.Deduplication = {}
    end

    if not ConsoleMenuFrame.NotificationFrame then
        local frame = CreateFrame("Frame", "NotificationFrame", ConsoleMenuFrame)
        ConsoleMenuFrame.NotificationFrame = frame
    end

    local frame = ConsoleMenuFrame.NotificationFrame
    frame:SetSize(frameWidth, frameHeight)
    frame:SetPoint("TOPLEFT", ConsoleMenuFrame, "TOPLEFT", 48, -48)
    ConsoleMenu:InitFadeAnimations(frame, animationDuration)
    frame:Hide()

    -- Текст уведомления
    if not frame.Text then
        frame.Text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.Text:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
        frame.Text:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
        frame.Text:SetFont("Fonts\\FRIZQT___CYR.TTF", fontSize, "")
        frame.Text:SetTextColor(1.0, 0.960784, 0.772549, 1)
        frame.Text:SetJustifyH("LEFT")
        frame.Text:SetText("")
        frame.Text:SetNonSpaceWrap(true)
        frame.Text:Show()
        frame.Text:SetWordWrap(true)
    end

    -- Текст уведомления
    if not frame.Caption then
        frame.Caption = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        frame.Caption:SetPoint("TOPLEFT", frame.Text, "BOTTOMLEFT", 0, -captionPadding)
        frame.Caption:SetPoint("TOPRIGHT", frame.Text, "BOTTOMRIGHT", 0, -captionPadding)
        frame.Caption:SetFont("Fonts\\FRIZQT___CYR.TTF", captionFontSize, "")
        frame.Caption:SetTextColor(1.0, 0.960784, 0.772549, 0.6)
        frame.Caption:SetJustifyH("LEFT")
        frame.Caption:SetText("")
        frame.Caption:SetNonSpaceWrap(true)
        frame.Caption:Hide()
        frame.Caption:SetWordWrap(true)
    end

    frame:RegisterEvent("UI_ERROR_MESSAGE")

    frame:RegisterEvent("CHAT_MSG_MONEY")
    frame:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
    frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    frame:RegisterEvent("PERKS_PROGRAM_CURRENCY_AWARDED")
    frame:RegisterEvent("UPDATE_PENDING_MAIL")

    frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    frame:RegisterEvent("ZONE_CHANGED")
    frame:RegisterEvent("ZONE_CHANGED_INDOORS")
    frame:RegisterEvent("UI_INFO_MESSAGE")

    local function OnNotificationEvent(self, event, ...)

        if event == "UI_ERROR_MESSAGE" then

            -- Если выбран стандартный стиль ошибок интерфейса
            if ConsoleMenuDB.errorsFrameStyle == 1 then return end
            
            if InCombatLockdown() then return end

            local _, errorMessage = ...

            if ConsoleMenuFrame.NotificationFrame:IsShown() and errorMessage == ConsoleMenuFrame.NotificationFrame.Text:GetText() then return end
            
            ConsoleMenu:AddNotification(event, errorMessage)
        elseif event == "CURRENCY_DISPLAY_UPDATE" then

            -- Если выбран стандартный стиль оповещений о получении валюты
            if ConsoleMenuDB.currencyDisplayUpdateStyle == 1 then return end

            local currencyID, quantity, quantityChange, quantityGainSource, destroyReason = ...

            if ignoredCurrencies[currencyID] then return end

            if quantityChange and quantityChange > 0 then
                ConsoleMenu:AddNotification(event, nil, nil, currencyID, quantityChange)
            end
        elseif event == "PERKS_PROGRAM_CURRENCY_AWARDED" then

            -- Если выбран стандартный стиль оповещений о получении валюты
            if ConsoleMenuDB.currencyDisplayUpdateStyle == 1 then return end

            local value = ...
            ConsoleMenu:AddNotification(event, nil, nil, 2032, value)
        elseif event == "UPDATE_PENDING_MAIL" then

            -- Если выбран стандартный стиль оповещений о получении почты
            if ConsoleMenuDB.mailDisplayUpdateStyle == 1 then return end

            if HasNewMail() then
                C_Timer.After(2, function()
                    ConsoleMenu:AddNotification(event, HAVE_MAIL)
                end)
            end
        elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then

            -- Если выбран стандартный стиль оповещений о смене области
            if ConsoleMenuDB.zoneTextFrameStyle == 1 then return end

            local zoneText = GetMinimapZoneText()
            if ConsoleMenu.Deduplication[zoneText] and GetTime() <= ConsoleMenu.Deduplication[zoneText] then return end

            ConsoleMenu:AddNotification(event)
        elseif event == "UI_INFO_MESSAGE" then

            local messageType, message = ...

            if messageType == 408 then
                -- Если выбран стандартный стиль оповещений о смене области
                if ConsoleMenuDB.zoneTextFrameStyle == 1 then return end
            end

            if messageType ~= 408 then return end

            local zoneText = message:match(":%s*(.+)")
            local caption = message:match("^([^:]+):")

            if ConsoleMenuFrame.NotificationFrame:IsShown() and zoneText == ConsoleMenuFrame.NotificationFrame.Text:GetText() then

                -- Случай, когда уведомление о смене области уже отображается и во время отображения появляется новое уведомление об изучении этой области
                ConsoleMenuFrame.NotificationFrame.Caption:SetText(caption)
                ConsoleMenuFrame.NotificationFrame.Caption:Show()
                ConsoleMenuFrame.NotificationFrame.fadeOut:Stop()

                local duration = NotificationDuration[event] or 5
    
                if duration then
                    if notificationUpdateTimer then
                        notificationUpdateTimer:Cancel()
                    end
        
                    notificationUpdateTimer = C_Timer.NewTimer(duration, function()
                        notificationUpdateTimer = nil
                        -- Скрываем текущее уведомление с анимацией
                        ConsoleMenu:AnimatedHide(ConsoleMenuFrame.NotificationFrame)
                        ConsoleMenuFrame.NotificationFrame.notification = nil
                        -- Ждем окончания анимации исчезновения перед проверкой следующего уведомления
                        C_Timer.After(animationDuration + delay, function()
                            -- После отображения проверяем, есть ли еще уведомления в очереди
                            ConsoleMenu:NotificationFrameUpdate()
                        end)
                    end)
                end
            else
                ConsoleMenu:AddNotification(event, zoneText, caption, messageType)
            end
        
        else
            local msg = ...
            ConsoleMenu:AddNotification(event, msg)
        end

        RemoveOldDeduplication()
    end

    frame:SetScript("OnEvent", OnNotificationEvent)
end