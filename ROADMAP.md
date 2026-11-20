# ROADMAP.md — Карта файлов и навигация проекта iorg

> **Обязательно для агента**: Используй этот файл как единственный источник правды о структуре проекта. Всегда проверяй его перед созданием, изменением или поиском файлов, и обновляй при добавлении/удалении любых модулей.

## Корень проекта (`res://`)
| Файл / Папка | Назначение |
| --- | --- |
| `project.godot` | Конфигурация Godot 4.7 (`GL Compatibility`, `1280x720` landscape, `InputMap`, Autoloads, главная сцена) |
| `.gitignore` | Игнорируемые файлы Godot (`.godot/`, `/android/`, временные файлы) |
| `.editorconfig` | Настройки кодировки UTF-8 |
| `.gitattributes` | Нормализация переводов строк LF |
| `CLAUDE.md` | Обязательные правила разработки, код-стайл GDScript и ограничения стека |
| `ROADMAP.md` | Данная карта файлов для быстрой навигации |
| `CHANGELOG.md` | Лог прогрессии изменений проекта (Keep a Changelog) |
| `TZ.md` | Пользовательское ТЗ и критические ограничения (не модифицируется агентом) |
| `icon.svg` / `icon.svg.import` | Иконка приложения |
| `package.json` | Минимальная заглушка (без зависимостей) только для запуска превью-сервера среды на порту 3000 (по запросу пользователя; не используется Godot) |
| `.preview/` | Изолированная `.gdignore` заглушка HTTP-сервера на порту 3000 для подавления ошибки среды |

## Сцены (`res://scenes/`)
| Путь | Корневой узел / Роль |
| --- | --- |
| `scenes/main_menu/main_menu.tscn` | `Control` — стартовый экран: Новая игра, Продолжить, Настройки, Выход |
| `scenes/game/game_arena.tscn` | `Node2D` — игровая 2D-арена стратегии: сетка, логистический слой, постройки, враги, камера, HUD и модалки |
| `scenes/ui/hud.tscn` | `CanvasLayer` — игровой интерфейс: день/ночь, кристаллы, База, панель постройки, инспектор, тач-зум |
| `scenes/ui/pause_menu.tscn` | `Control` (`PROCESS_MODE_ALWAYS`) — меню паузы (продолжить, сохранить, сбросить сейв, настройки, в меню) |
| `scenes/ui/settings_modal.tscn` | `Control` (`PROCESS_MODE_ALWAYS`) — окно настроек (громкость Master/SFX, режим тач-кнопок, полный экран) |
| `scenes/ui/skill_tree_modal.tscn` | `Control` (`PROCESS_MODE_ALWAYS`) — ветвящееся 3-колоночное древо талантов (Экономика, Логистика, Оборона) |
| `scenes/ui/sanctuary_modal.tscn` | `Control` (`PROCESS_MODE_ALWAYS`) — межзабеговое окно «Сад и Артефакты» (грядки, растения, слоты и коллекция артефактов) |
| `scenes/ui/game_over_modal.tscn` | `Control` (`PROCESS_MODE_ALWAYS`) — экран поражения с трофеями забега и переходом в Сад |

## Скрипты (`res://scripts/`)
### Autoload-синглтоны (`res://scripts/autoload/`)
| Путь | Глобальное имя | Ответственность |
| --- | --- | --- |
| `scripts/autoload/event_bus.gd` | `EventBus` | Шина глобальных сигналов экономики, цикла день/ночь, построек, навыков, камеры и сохранений |
| `scripts/autoload/game_state.gd` | `GameState` | Состояние сессии: зерно карты, день/фаза, кристаллы, уровень/HP Базы, древо талантов (9 узлов), постройки |
| `scripts/autoload/save_manager.gd` | `SaveManager` | Чтение/запись/удаление сохранений (`SAVE_VERSION = 2`) в `user://saves/save.json` |
| `scripts/autoload/settings_manager.gd` | `SettingsManager` | Загрузка/сохранение настроек в `user://settings.cfg` (`ConfigFile`), экран и тач-режим |
| `scripts/autoload/audio_manager.gd` | `AudioManager` | Инициализация аудиошин (`Master`, `SFX`, `Music`) и управление громкостью |
| `scripts/autoload/meta_progression.gd` | `MetaProgression` | Пост-забеговые награды (Эссенция, Семена, дроп Артефактов), Сад и Артефакты (`user://saves/meta.json`) |

### Ресурсные классы (`res://scripts/resources/`)
| Путь | Класс | Ответственность |
| --- | --- | --- |
| `scripts/resources/building_config.gd` | `BuildingConfig` | Параметры зданий, жил, производства, логистики и турелей |
| `scripts/resources/enemy_config.gd` | `EnemyConfig` | Характеристики типов зомби и босса волны |
| `scripts/resources/world_balance_config.gd` | `WorldBalanceConfig` | Размеры сетки, стартовые кристаллы, длительность дня/ночи, генерация жил и сверхлинейная формула волн |

### Мир и стратегия (`res://scripts/world/`)
| Путь | Класс / Роль | Ответственность |
| --- | --- | --- |
| `scripts/world/game_arena.gd` | Контроллер арены | Генерация жил, граф логистики BFS, тики добычи/заводов/башен, `AStarGrid2D` пути врагов, волны и боссы |
| `scripts/world/strategic_camera.gd` | `StrategicCamera` | Панорамирование (WASD, ПКМ/СКМ, свайп) и зум (колесо, щипок, кнопки), обработка тапов по сетке |
| `scripts/world/building_entity.gd` | `BuildingEntity` | Постройка на сетке, апгрейд/продажа, склады/очереди, отрисовка по категории и уровню |
| `scripts/world/enemy_entity.gd` | `EnemyEntity` | Сущность врага/босса ночной волны и отрисовка HP |
| `scripts/world/logistics_overlay.gd` | `LogisticsOverlay` | Быстрая отрисовка сетки, 4 типов жил, связей, призрака постройки, летящих грузов и выстрелов |

### Интерфейс (`res://scripts/ui/`)
| Путь | Ответственность |
| --- | --- |
| `scripts/ui/main_menu.gd` | Главное меню, проверка сейва, отображение Эссенции/Семян/Рекорда и вход в «Сад и Артефакты» |
| `scripts/ui/hud.gd` | Панель постройки с хоткеями, инспектор здания, день/ночь, пропуск дня, пауза симуляции, тач-зум |
| `scripts/ui/pause_menu.gd` | Меню паузы, ручное сохранение и удаление прогресса |
| `scripts/ui/settings_modal.gd` | Регулировка громкости, тач-режима и полноэкранного режима |
| `scripts/ui/skill_tree_modal.gd` | Логика ветвящегося древа талантов (3 ветки × 3 тира), инспектор выбранного таланта и покупка за кристаллы |
| `scripts/ui/talent_tree_canvas.gd` | Отрисовка соединительных линий и состояний (закрыто/доступно/изучено) между узлами древа талантов |
| `scripts/ui/sanctuary_modal.gd` | Логика межзабегового окна «Сад и Артефакты»: посадка/улучшение/выкапывание растений, крафт и экипировка артефактов |
| `scripts/ui/game_over_modal.gd` | Итоговая статистика поражения, награды после забега и перезапуск |

## Ресурсы баланса и контента (`res://resources/`)
| Путь | Назначение |
| --- | --- |
| `resources/balance/default_world_balance.tres` | Общий баланс мира (`WorldBalanceConfig`) |
| `resources/buildings/*.tres` | 13 конфигов построек (`base`, 4 шахты, `transporter`, 3 завода, 3 башни, `wall`) |
| `resources/enemies/*.tres` | 4 конфига врагов (`zombie_basic`, `zombie_fast`, `zombie_tank`, `zombie_boss`) |

## Ассеты (`res://assets/`)
| Путь | Назначение |
| --- | --- |
| `assets/sprites/` | 2D-спрайты (`.png`, `.svg`) — заготовка под замену геометрии |
| `assets/audio/` | Звуковые эффекты и музыка (`.ogg`, `.wav`) |
| `assets/fonts/` | Шрифты (`.ttf`, `.otf`) |
