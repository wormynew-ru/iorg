## КРИТИЧЕСКИЕ ЗАПРЕТЫ (нарушение = провал задачи)

### Технологический стек — ТОЛЬКО Godot
- **Разрешено**: Godot 4.x, GDScript, .tscn, .tres, .gd, .godot, встроенные ноды и классы движка
- **ЗАПРЕЩЕНО создавать что-либо из этого списка**:
  - React, React Native, Next.js, Vue, Svelte, Angular, Solid, Preact — любые JS-фреймворки
  - HTML, CSS, JavaScript, TypeScript, JSX, TSX — файлы любого из этих типов
  - package.json, node_modules, vite.config, webpack, rollup, esbuild, bun, deno, pnpm, yarn
  - Electron, Tauri, Capacitor, Cordova, Ionic, Flutter, React Native — любые обёртки
  - Google AI Studio, Google AI Studio Build, Firebase, Supabase, Vercel, Netlify — любые хостинги/бэкенды
  - Web-версии, PWA, Service Worker, manifest.json, браузерные сборки
  - Python/Node.js/Go/Rust-серверы, Express, FastAPI, Flask — любой бэкенд
  - Docker, docker-compose, CI/CD для веба

### Почему
Проект — **нативная игра на Godot**, экспортируемая в APK (Android) и исполняемый файл (Windows/Linux/macOS). 
Она НЕ запускается в браузере. Она НЕ использует веб-технологии. Она НЕ хостится в облаке.

### Если агент не уверен
- Если кажется, что «нужно сделать веб-версию» — **НЕ делай**, спроси
- Если предлагаешь библиотеку — проверь, что она для Godot (Godot Asset Library / GitHub с тегом godot), а не для JS
- Если предлагаешь UI — используй Control-ноды Godot, а не HTML/CSS
- Если предлагаешь состояние — используй autoload-синглтоны GDScript, а не Redux/Zustand/Pinia

### Разрешённые внешние инструменты (только если реально нужны)
- Blender (экспорт .glb/.gltf) — для 3D-моделей
- Aseprite/Krita (экспорт .png) — для 2D-спрайтов
- Audacity (экспорт .ogg/.wav) — для звука
- Всё это — офлайн, ассеты кладутся в `res://assets/`

### Проверка перед каждым коммитом
Задай себе вопрос: «Запустится ли это через `godot --path .` без браузера и интернета?»
Если нет — переделай.