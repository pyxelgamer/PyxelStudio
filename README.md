# 🎨 Pyxel Studio

**The pixel art editor built for Godot workflows.**

Pyxel Studio is a full-featured pixel art editor for Windows, designed specifically for game developers using the Godot game engine. Create sprites, tilesets, and images — then export directly to Godot-compatible formats.

---

## ⬇️ Download

**[→ Download PyxelStudio_Setup_v1.0.0.0.exe](https://github.com/pyxelgamer/PyxelStudio/releases/latest)**

> Requires Windows 10 (1809 or later), 64-bit. The installer will prompt you to download the .NET 10 runtime if not already installed.

---

## ✨ Features

### Three Editor Modes
- **Image Mode** — Draw and paint pixel art with a full layer stack and non-destructive effects
- **Sprite Mode** — Animate sprites with a full timeline, named animations, onion skinning, and live playback
- **Tileset Mode** — Build tile libraries with dynamic sync, multi-layer cell maps, and bleed extrusion for GPU-safe atlases

### Drawing Tools
Pencil, Eraser, Fill, Eyedropper, Color Replace, Shape (rectangle/ellipse/line), Box Select, and Transform — all with keyboard shortcuts.

### Layer System
Full non-destructive layer stack with visibility, locking, blend modes, and per-layer effects including Hue Shift.

### Godot Export
- Export spritesheets as PNG + `.pyxelsprite` metadata for use with `AnimatedSprite2D`
- Export tilesets as atlas PNG + `.gmap` / `.tsj` for use with `TileMapLayer`
- Per-tile physics/collision metadata in the tileset export wizard
- Bleed extrusion with live preview to prevent GPU texture seam artifacts

### File Format
Projects save as `.pyxel` files — ZIP archives containing structured JSON metadata and RGBA PNG layer data. Double-click to open from Windows Explorer.

### Quality of Life
- Recent files on the welcome screen
- Save / Save As with full path tracking
- Undo / Redo (50 steps)
- Customisable checker background
- Help menu with built-in User Manual (PDF)
- Auto-associates `.pyxel` files on install

---

## 🎮 Godot Plugin

The Godot importer plugin is located in the [`addons/pyxelstudio/`](addons/pyxelstudio/) folder of this repo.

Copy it into your Godot project's `addons/` folder and enable it in **Project → Project Settings → Plugins**.

Once enabled:
- `.pyxelsprite` files are imported automatically as `AnimatedSprite2D`-ready resources
- `.gmap` files are imported as `TileMapLayer`-ready resources

---

## 🖥️ System Requirements

| | |
|---|---|
| **OS** | Windows 10 version 1809 or later (64-bit) |
| **Runtime** | .NET 10 Desktop Runtime (installer will prompt if missing) |
| **RAM** | 1 GB minimum, 2 GB recommended |
| **GPU** | DirectX 11 or later |

---

## ⌨️ Keyboard Shortcuts

| Key | Tool |
|-----|------|
| `P` | Pencil |
| `E` | Eraser |
| `F` | Fill |
| `I` | Eyedropper |
| `O` | Color Replace |
| `U` | Shape |
| `S` | Select |
| `W` | Transform |
| `B` | Box Select |
| `C` | Capture tile to panel *(Tileset mode)* |
| `Shift+Space` | Play / Stop animation *(Sprite mode)* |
| `Ctrl+G` | Toggle grid |
| `Ctrl+Z / Y` | Undo / Redo |

---

## 📖 User Manual

The full User Manual (PDF) is included in the installation folder at:
```
C:\Program Files\Pyxel Studio\PyxelStudio_UserManual.pdf
```
It is also accessible from within the app via **Help → User Manual**.

---

## 📁 File Format

Pyxel Studio saves projects as `.pyxel` files. These are standard ZIP archives — rename to `.zip` to inspect layer PNGs and JSON metadata directly.

```
project.pyxel
├── manifest.json          ← mode, canvas size, version, palette, FPS
└── blocks/
    ├── image/layer_N/     ← pixels.png + meta.json  (Image mode)
    ├── AnimName_0/        ← frames + layers          (Sprite mode)
    └── Canvas/layer_N/    ← pixels + cellmap.json    (Tileset mode)
```

---

## 📄 License

Pyxel Studio uses a **dual licensing model**:

* **Pyxel Studio Application (Editor)**
  Licensed under a proprietary license.
  You may use it freely for personal, educational, and commercial projects, but redistribution, resale, or modification for competing products is not permitted.

* **Godot Importer Plugin (`addons/pyxelstudio/`)**
  Licensed under the **MIT License**.
  You are free to use, modify, and distribute the plugin within your Godot projects.

This separation ensures the editor remains protected while the Godot integration remains fully open and developer-friendly.

For full details, see the [LICENSE](LICENSE) file in this repository and the LICENSE file inside the plugin directory.


---

*Pyxel Studio v1.0.0.0 — made for Godot game developers.*
