# Changelog

Az összes jelentős változás ebben a fájlban kerül dokumentálásra.

A formátum a [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) ajánlásain alapul,
a verziókezelés a [Semantic Versioning](https://semver.org/spec/v2.0.0.html) elveit követi.

---

## [Unreleased]

Jelenleg nincs dokumentált változás.

---

## [0.2.0] – 2026-04-07 — Sprint 2: Játékos, ellenség és Level0 skeleton

### Hozzáadva

- `scripts/entities/player/player.gd` – univerzális játékos alaposztály, amelyből a konkrét karakterek (pl. lovag) öröklődnek.  
- `scripts/entities/player/playerKnight.gd` – lovag játékos állapotgéppel (IDLE, RUN, JUMP, FALL, ATTACK, HURT, DEAD), mozgással, ugrással, támadás és életkezeléssel.  
- `scripts/entities/enemies/knight_enemy.gd` – lovag ellenség AI state machine-nel (PATROL → AGGRO → ATTACK → HURT → DEAD), távolság alapú aggro és támadás időzítéssel.  
- `scripts/autoload/Game_Manager.gd` – `player_died` és `level_completed` szignálok, `on_player_death()` és `on_level_complete()` callbackek; halálkor a jelenlegi pálya reload, level complete után a következő szint betöltése.  
- `scripts/autoload/Level_Manager.gd` – szintbetöltés, reload, következő szintre léptetés és szint unlock logika (pl. Level2/3 gombok engedélyezése a level menüben).  
- `scripts/environment/goal.gd` – pályacél trigger, amely játékos ütközéskor jelzi a GameManager felé a szint teljesítését.  
- `scenes/levels/level0.tscn` – első játszható tesztpálya lovag játékossal és lovag ellenséggel, TileMap alapú elrendezéssel.  
- `assets/` bővítése – sprite-ok, texture-ök és placeholder assetek szervezett mappastruktúrája (`assets/sprites`, `assets/textures`, `assets/placeholder assets`, stb.).  
- HUD scene váz: `scenes/hud/hud.tscn` – `Hud` Node2D, a későbbi élet- és státuszkijelzés alapja.  

### Tesztelés

- `tests/unit/test_level_manager.gd` – Level_Manager viselkedésének unit tesztje (level betöltés, léptetés, unlock logika).  
- `tests/unit/test_save_manager.gd` – Save_Manager mentési/betöltési logikájának unit tesztje.  
- `tests/unit/test_smoke.gd` – smoke test, amely ellenőrzi, hogy a projekt alap szinten betölthető és futtatható.  
- GitHub Actions workflow: `.github/workflows/godot-test.yml` – GUT unit tesztek automatikus futtatása push/PR eseményeknél.  

### Módosítva

- Level menü script: `scripts/level_menu/level_menu.gd` – Level2 és Level3 gombok bekötése scriptből, lock/unlock logika a Level_Manager alapján.  
- Level menü scene: `scenes/level_menu/level_menu.tscn` – kisebb fixek a gombokhoz és layout-hoz a skeleton flow támogatására.  
- Főmenü scene: `scenes/main/main.tscn` – navigáció finomhangolása a Level menü és a játék között (Play → Level select → Level0).  

---

## [0.1.0] – 2026-03-10 — Sprint 1: Projekt alapok és dokumentáció

### Hozzáadva
- `README.md` – projekt leírás, telepítési útmutató, irányítás, csapatinformációk
- `CHANGELOG.md` – változásnapló (ez a fájl)
- `ARCHITECTURE.md` – rendszerarchitektúra leírása Mermaid diagramokkal
- `Sprint1.md` – sprint összefoglaló, kontribúciók, akadályok
- Godot Engine 4.6 projekt inicializálása (`project.godot`)
- Scene struktúra kialakítása:
  - `scenes/main/main.tscn` – főmenü (Play, Inventory, Exit gombok)
  - `scenes/level_menu/levels.tscn` – pályaválasztó (3 pályagomb)
  - `scenes/inventory/invertory.tscn` – inventory képernyő
  - `scenes/pause_menu/pause_menu.tscn` – pause menü váz
  - `scenes/hud/hud.tscn` – HUD váz
  - `scenes/entities/player/MainCharacter.tscn` – játékos karakter (animált sprite-okkal)
  - `scenes/entities/enemies/knightEnemy.tscn` – lovag ellenség (animált sprite-okkal)
- Script struktúra kialakítása (autoload singleton-ok: `Game_Manager`, `Save_Manager`, `Audio_Manager`)
- Placeholder asset-ek integrálása (Tiny RPG Character Pack, Legacy Collection)
- GUT unit teszt framework integrálása (beta) (`tests/unit/test_example.gd`)
- GitHub Actions CI/CD pipeline beállítása (`.github/workflows/godot-test.yml`)
- GitGodot plugin-ok hozzáadása
- `.gitignore` és `.gitattributes` konfigurálása
- `docs/` mappa létrehozása a specifikáció tárolásához

### Dokumentáció
- Projekt specifikáció elkészítése (PDF): játékkoncepcó, történet, követelmények, use-case-ek,
  rendszerstruktúra, viselkedésmodellek, fájlformátumok, adatfolyam, tesztelési terv, osztálydiagram

### Infrastruktúra
- GitHub repository létrehozása: [github.com/Balint000/up-the-tower](https://github.com/Balint000/up-the-tower)
- Branch stratégia: `master` védett ág, feature branch-ek PR-on keresztül
- Fejlesztői környezetek: Windows 11 (D3D12) és Fedora 43 (Wayland)

---

## Verzióstratégia

| Verzió | Leírás |
|--------|--------|
| 0.x.x | Fejlesztési fázis (sprint-ek) |
| 1.0.0 | Első kiadható verzió (végleges leadás) |

A verziószámok jelentése: `MAJOR.MINOR.PATCH`
- **MAJOR** – játszható verziók, nagyobb mérföldkövek
- **MINOR** – új funkciók, pályák, rendszerek
- **PATCH** – hibajavítások, kisebb módosítások

---
