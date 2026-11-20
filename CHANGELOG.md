# Changelog

Все заметные изменения проекта **iorg** фиксируются в этом файле.
Формат основан на [Keep a Changelog](https://keepachangelog.com/ru/1.1.0/).

## [0.1.0] - 2026-11-20

### Added
- Базовая структура нативного проекта **Godot 4.6.x** (`scenes/`, `scripts/`, `resources/`, `assets/`).
- Обязательная проектная документация: `CLAUDE.md`, `ROADMAP.md`, `CHANGELOG.md` (с сохранением ограничений из `TZ.md`).
- Конфигурация `project.godot`: рендерер `GL Compatibility`, горизонтальное окно `1280x720` (`canvas_items` + `expand`), `InputMap` (`WASD`, стрелки, `Space`, `Shift`, `Esc`, `E`) и 5 Autoload-синглтонов.
- Autoload-синглтоны: `EventBus`, `GameState`, `SaveManager` (`user://saves/save.json` с `save_version`), `SettingsManager` (`user://settings.cfg`) и `AudioManager`.
- Ресурсы баланса (`PlayerConfig`, `ArenaConfig`) в `resources/balance/`.
- Рабочий 2D-прототип:
  - Главное меню («Новая игра», «Продолжить», «Настройки», «Выход»).
  - Игровая 2D-арена с персонажем (`CharacterBody2D`), камерой (`Camera2D` со smoothing), препятствиями и собираемыми сферами (`Area2D`).
  - Кроссплатформенное управление: клавиатура на ПК + виртуальный джойстик и кнопка рывка для сенсорных экранов (авто-детект и переключатель в настройках).
  - HUD, меню паузы, окно настроек и система автосохранения/загрузки/сброса прогресса.

### Removed
- Остаточные пустые директории веб-шаблона (`.vite/`, `public/`, `src/`).
