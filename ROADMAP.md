# ROADMAP.md — Карта файлов и навигация проекта iorg

> **Обязательно для агента**: Используй этот файл как единственный источник правды о структуре проекта. Всегда проверяй его перед созданием, изменением или поиском файлов, и обновляй при добавлении/удалении любых модулей.

## Корень проекта (`res://`)
| Файл / Папка | Назначение |
| --- | --- |
| `project.godot` | Конфигурация Godot 4.6 (`GL Compatibility`, `1280x720` landscape, `InputMap`, Autoloads, главная сцена) |
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
| `scenes/game/game_arena.tscn` | `Node2D` — основная 2D-арена прототипа (мир, стены, препятствия, сферы, игрок, HUD, пауза) |
| `scenes/game/player.tscn` | `CharacterBody2D` — управляемый 2D-персонаж с камерой `Camera2D` и рывком |
| `scenes/game/energy_orb.tscn` | `Area2D` — собираемый объект с уникальным ID и анимацией подбора |
| `scenes/game/obstacle_block.tscn` | `StaticBody2D` — базовое препятствие на арене |
| `scenes/ui/hud.tscn` | `CanvasLayer` — игровой интерфейс (счёт, кнопка паузы, уведомление о сохранении, слой тач-управления) |
| `scenes/ui/pause_menu.tscn` | `Control` (`PROCESS_MODE_ALWAYS`) — меню паузы (продолжить, сохранить, сбросить сейв, настройки, в меню) |
| `scenes/ui/settings_modal.tscn` | `Control` (`PROCESS_MODE_ALWAYS`) — окно настроек (громкость Master/SFX, режим тач-ввода, полный экран) |
| `scenes/ui/touch_controls.tscn` | `Control` — контейнер кроссплатформенного сенсорного управления (джойстик + кнопка рывка) |
| `scenes/ui/virtual_joystick.tscn` | `Control` — виртуальный аналоговый джойстик с поддержкой мультитача и мыши для тестов |

## Скрипты (`res://scripts/`)
### Autoload-синглтоны (`res://scripts/autoload/`)
| Путь | Глобальное имя | Ответственность |
| --- | --- | --- |
| `scripts/autoload/event_bus.gd` | `EventBus` | Шина глобальных сигналов (`orb_collected`, `score_changed`, `save_completed`, `touch_mode_changed` и др.) |
| `scripts/autoload/game_state.gd` | `GameState` | Хранение текущего состояния игровой сессии (счёт, позиция игрока, собранные ID, время) |
| `scripts/autoload/save_manager.gd` | `SaveManager` | Чтение/запись/удаление сохранений в `user://saves/save.json` через `FileAccess` (`save_version`) |
| `scripts/autoload/settings_manager.gd` | `SettingsManager` | Загрузка/сохранение настроек в `user://settings.cfg` (`ConfigFile`), режим экрана и тач-ввода |
| `scripts/autoload/audio_manager.gd` | `AudioManager` | Инициализация аудиошин (`Master`, `SFX`, `Music`) и управление громкостью / проигрыванием |

### Ресурсные классы (`res://scripts/resources/`)
| Путь | Класс | Ответственность |
| --- | --- | --- |
| `scripts/resources/player_config.gd` | `PlayerConfig` | Типизированные параметры движения, рывка и отката игрока |
| `scripts/resources/arena_config.gd` | `ArenaConfig` | Размеры арены, очки за сферу и параметры камеры |

### Игрок и мир (`res://scripts/player/`, `res://scripts/world/`)
| Путь | Ответственность |
| --- | --- |
| `scripts/player/player.gd` | Физика перемещения (`move_and_slide`), рывок, считывание клавиатуры + виртуального джойстика |
| `scripts/world/game_arena.gd` | Инициализация арены, восстановление состояния из `GameState`, автосейв при паузе/выходе |
| `scripts/world/energy_orb.gd` | Логика подбора сферы, защита от повторного спавна уже собранных ID, tween-анимация |
| `scripts/world/obstacle_block.gd` | Визуальная и коллизионная настройка препятствия |

### Интерфейс (`res://scripts/ui/`)
| Путь | Ответственность |
| --- | --- |
| `scripts/ui/main_menu.gd` | Логика главного меню, проверка наличия сейва для кнопки «Продолжить», переходы |
| `scripts/ui/hud.gd` | Обновление счёта, индикатор сохранения, вызов паузы |
| `scripts/ui/pause_menu.gd` | Постановка/снятие паузы, ручное сохранение, сброс прогресса, выход в главное меню |
| `scripts/ui/settings_modal.gd` | Регулировка громкости, переключение режима тач-управления и полноэкранного режима |
| `scripts/ui/touch_controls.gd` | Авто-видимость тач-элементов (`DisplayServer.is_touchscreen_available()` / настройка) |
| `scripts/ui/virtual_joystick.gd` | Вычисление нормализованного вектора отклонения джойстика по касанию/мыши |

## Ресурсы баланса (`res://resources/`)
| Путь | Назначение |
| --- | --- |
| `resources/balance/default_player_config.tres` | Базовый конфиг игрока (`PlayerConfig`) |
| `resources/balance/default_arena_config.tres` | Базовый конфиг арены (`ArenaConfig`) |
| `resources/buildings/` | Резерв под `.tres`-конфиги построек/объектов |
| `resources/enemies/` | Резерв под `.tres`-конфиги врагов |

## Ассеты (`res://assets/`)
| Путь | Назначение |
| --- | --- |
| `assets/sprites/` | 2D-спрайты (`.png`, `.svg`) — заготовка под расширение |
| `assets/audio/` | Звуковые эффекты и музыка (`.ogg`, `.wav`) — заготовка под расширение |
| `assets/fonts/` | Шрифты (`.ttf`, `.otf`) — заготовка под расширение |
