# Changelog

Az összes jelentős változás ebben a fájlban kerül dokumentálásra.

A formátum a [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) ajánlásain alapul,
a verziókezelés a [Semantic Versioning](https://semver.org/spec/v2.0.0.html) elveit követi.

---

## [Unreleased]

### Tervezett – Sprint 2
- Játékos mozgás és fizika (CharacterBody2D)
- Ugrás mechanika gravitációval
- Animáció vezérlő (idle, walk, jump, hurt, death)
- Első pálya (TileMap alapú) vázlatos felépítése
- Ellenség alap AI (patrol mozgás)
- Ütközésdetektálás játékos–ellenség között

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
- GUT unit teszt framework integrálása (`tests/unit/test_example.gd`)
- GitHub Actions CI/CD pipeline beállítása (`.github/workflows/godot-test.yml`)
- GitGodot és ToGoDot editor plugin-ok hozzáadása
- `.gitignore` és `.gitattributes` konfigurálása
- `docs/` mappa létrehozása a specifikáció tárolásához

### Dokumentáció
- Projekt specifikáció elkészítése (PDF): játékkoncepcó, történet, követelmények, use-case-ek,
  rendszerstruktúra, viselkedésmodellek, fájlformátumok, adatfolyam, tesztelési terv, osztálydiagram

### Infrastruktúra
- GitHub repository létrehozása: [github.com/Balint000/up-the-tower](https://github.com/Balint000/up-the-tower)
- Branch stratégia: `main` / `master` védett ág, feature branch-ek PR-on keresztül
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

[Unreleased]: https://github.com/Balint000/up-the-tower/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Balint000/up-the-tower/releases/tag/v0.1.0
