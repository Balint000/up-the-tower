# Up The Tower 🗼

Platformer játék készítve Godot 4.6-ban egyetemi projekthez (Modern szoftverfejlesztési eszközök tárgy, 2025/2026 tavaszi félév).

## Projekt Struktúra

```
up-the-tower/
├── assets/                 # Vizuális és audio asset-ek
│   ├── audio/             # Hangok és zenék
│   ├── fonts/             # Betűtípusok
│   ├── sprites/           # 2D sprite-ok és animációk
│   ├── textures/          # Textúrák és tilesetek
│   └── shaders/           # Shader fájlok
│
├── scenes/                # Godot scene fájlok
│   ├── main/              # Főmenü és scene kezelés
│   ├── levels/            # Játékpályák
│   ├── entities/          # Játékos, ellenségek, tárgyak
│   ├── environment/       # Környezeti elemek
│   └── ui/                # Felhasználói felület
│
├── scripts/               # GDScript fájlok
│   ├── autoload/          # Singleton scriptek
│   ├── entities/          # Entitás logika
│   ├── ui/                # UI scriptek
│   └── utils/             # Segédfüggvények
│
├── resources/             # Godot resource fájlok
│   ├── themes/            # UI témák
│   └── materials/         # Anyagok és shader materials
│
└── docs/                  # Dokumentáció
```

## Fejlesztési Irányelvek

### Mappastruktúra Használata

- **assets/**: Minden nyers asset (kép, hang, font) ide kerül
- **scenes/**: Scene-eket funkció szerint csoportosítsd (entities, levels, ui)
- **scripts/**: Ugyanolyan struktúrát követ mint a scenes/, könnyű párosítás
- **autoload/**: Globális manager-ek (GameManager, AudioManager, stb.)

### Elnevezési Konvenciók

- **Fájlok**: snake_case (pl. `player_controller.gd`, `level_01.tscn`)
- **Class-ok**: PascalCase (pl. `class_name PlayerController`)
- **Változók/függvények**: snake_case (pl. `var jump_speed`, `func handle_input()`)
- **Konstansok**: UPPER_SNAKE_CASE (pl. `const MAX_SPEED = 300`)

### Scene Struktúra

Minden komplex entitásnak legyen saját scene-je:
- `scenes/entities/player/player.tscn` + `scripts/entities/player/player.gd`
- `scenes/entities/enemies/flying_enemy.tscn` + `scripts/entities/enemies/flying_enemy.gd`

## Technológia

- **Engine**: Godot 4.6
- **Rendering**: D3D12 (Windows)
- **Scripting**: GDScript

## Csapat

Egyetemi projekt - [Erdei Bálint], [Tóth Gábor], [Mogyorósi István]
