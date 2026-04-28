# Up The Tower 🗼

A vertical platformer game where players climb an ever-rising tower, facing increasing challenges and obstacles. Built with Godot 4.6 as a university project for the Modern Software Development Tools course (Spring Semester 2025/2026).

## 🎮 About The Game

**Up The Tower** is a 2D platformer focused on vertical progression. Players navigate through challenging levels filled with enemies, hazards, and puzzles while ascending a mysterious tower. The game emphasizes precise movement, quick reflexes, and strategic progression.

### Key Features (Planned)

- 🧗 Vertical platformer gameplay with climbing mechanics
- 🎯 Multiple levels with increasing difficulty
- 👾 Various enemy types and environmental hazards
- 💎 Collectibles
- 💾 Checkpoint system
- 🎨 Pixel art style
- 🎵 Audio system

## 📋 Table of Contents

- [About The Game](#-about-the-game)
- [Prerequisites](#-prerequisites)
- [Installation](#-installation)
- [Project Structure](#-project-structure)
- [Development Guidelines](#-development-guidelines)
- [Development Environment](#️-development-environment)
- [Controls](#-controls)
- [Roadmap](#️-roadmap)
- [Contributing](#-contributing)
- [Team](#-team)

## 🔧 Prerequisites

### Required Software

- **Godot Engine 4.6** or later
  - Download from [godotengine.org](https://godotengine.org/download)
  - Choose version 4.6 or higher
- **Git** for version control
  - Download from [git-scm.com](https://git-scm.com)

### Recommended Tools

- **Visual Studio Code** with GDScript extension (optional, for external editing)
- **Aseprite** or **GIMP** for sprite editing (if contributing art assets)
- **Audacity** or **Reaper** or **Bandlab** for audio editing (if contributing sound assets)

### Supported Operating Systems

- **Windows 11** (Primary development platform)
- **Fedora 43 Wayland** (Primary development platform)
- **macOS** (should work, but not actively tested)
- **Other Linux distributions** (should work with Godot installed)

## 📦 Installation

### For Players (Coming Soon)

*Game releases will be available on the [Releases](https://github.com/Balint000/up-the-tower/releases) page when ready.*

### For Developers

1. **Clone the repository:**

   ```bash
   git clone https://github.com/Balint000/up-the-tower.git
   cd up-the-tower

2. **Open the project in Godot:**

		Launch Godot Engine 4.6
		Click Import
		Navigate to the cloned repository folder
		Select the project.godot file
		Click Import & Edit

4. **Install Git integration (optional):**
- The project uses the GitGodot plugin for version control integration within the editor. It should be automatically enabled when you open the project.
4. **Run the game:**
- Press F5 in the Godot editor to run the project
- Or click the Play button in the top-right corner

**Scene Organization Philosophy**

We follow a modular approach where each major entity has its own scene file:

	scenes/entities/player/player.tscn + scripts/entities/player/player.gd
	scenes/entities/enemies/flying_enemy.tscn + scripts/entities/enemies/flying_enemy.gd

This structure makes it easy for multiple team members to work on different features simultaneously without conflicts.

🛠️ **Development Guidelines**
Folder Structure Usage

	assets/: All raw assets (images, sounds, fonts) go here
	scenes/: Organize scenes by function (entities, levels, ui)
	scripts/: Mirror the structure of scenes/ for easy pairing
	autoload/: Global managers (GameManager, AudioManager, etc.)

🖥️ **Development Environment**

This project is actively developed on:
Windows 11

	Godot 4.6 with D3D12 renderer (configured in project.godot)
	Git for Windows
	Visual Studio Code with GDScript syntax highlighting

Fedora 43 Wayland

	Godot 4.6 running natively on Wayland
	Git for version control
	Native Wayland support for smooth editor experience

🎮 **Controls**

Controls will be finalized during development. Planned default controls:

	Move Left: A / Left Arrow
	Move Right: D / Right Arrow
	Jump: Space / W / Up Arrow
	Attack: Z
	Interact: E
	Pause: Escape

👥 **Team**

This game is being developed as a university project for the Modern Software Development Tools course at the University of Győr.
Development Team

	Erdei Bálint - @Balint000
	Tóth Gábor - @gabortoth55
	Mogyorósi István - @Mogyi13

Course Information

	Institution: University of Győr (Széchenyi István University)
	Course: Modern Software Development Tools (Modern szoftverfejlesztési eszközök)
	Semester: Spring 2025/2026
