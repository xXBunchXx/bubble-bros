# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**BubbleBros** is a Godot 4.6 game project using GDScript. It uses Jolt Physics and Direct3D 12 rendering (Windows).

## Running the Project

Godot projects have no build step — the engine interprets GDScript directly.

- **Open editor**: `godot --path .` or double-click `project.godot`
- **Run game from CLI**: `godot --path . --play`
- **Run a specific scene**: `godot --path . res://path/to/scene.tscn`

There is no test framework configured. Godot's built-in scene runner is used for manual testing.

## Project Configuration

Key settings in `project.godot`:
- Physics engine: Jolt Physics (not the default Godot physics)
- Rendering driver: D3D12 (Windows-only; use Vulkan or OpenGL flags on other platforms)
- Godot version: 4.6

## Architecture Notes

This project is in early development — no scenes or scripts exist yet. As the project grows, Godot 4 conventions to follow:

- **Scenes** (`.tscn`): composable scene trees; each scene is a reusable unit (character, level, UI)
- **Scripts** (`.gd`): GDScript files attached to nodes; one script per node type is standard
- **Autoloads**: global singletons declared in `project.godot` under `[autoload]` — use for game state, audio bus, event bus
- **Signals**: preferred over direct node references for loose coupling between scenes
- **Resources** (`.tres`, `.res`): data containers (stats, config); prefer resources over raw dictionaries for structured data

The `.godot/` directory is auto-generated cache — never edit it manually, it is gitignored.
