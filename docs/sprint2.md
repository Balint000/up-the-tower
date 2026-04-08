# Sprint 2 – Összefoglaló

**Projekt:** Up The Tower  
**Csapat:** BoMoGa Games  
**Sprint időtartama:** 2026. március vége – 2026. április 7.  
**Sprint célja:**  
Első játszható „skeleton” vertikális pálya elkészítése lovag játékossal és lovag ellenséggel,  
valamint az alap gameplay loop (mozgás, ugrás, támadás, halál, pályaváltás) és unit tesztek
stabilizálása.

---

## Elvégzett feladatok

### Dokumentáció

| Feladat                     | Státusz | Felelős    |
|----------------------------|---------|-----------|
| sprint2.md (jelen fájl)   | Kész    | Közös     |
| changelog.md – 0.2.0 bejegyzés | Kész    | Közös     |

### GitHub és infrastruktúra

| Feladat                                    | Státusz |
|-------------------------------------------|---------|
| GUT unit tesztek bővítése (Level/Save)   | Kész    |
| Smoke test hozzáadása                     | Kész    |
| Godot + GUT GitHub Actions workflow finomhangolása | Kész    |

### Godot projekt – gameplay és pályák

| Feladat | Státusz |
|---------|---------|
| `playerKnight.gd` – lovag játékos állapotgéppel (idle, run, jump, fall, attack, hurt, dead) | Kész |
| Játékos mozgás és ugrás implementálása (CharacterBody2D, gravitáció) | Kész |
| Támadás input akció (pl. `attack` gomb) és sebzés logika | Kész |
| `knight_enemy.gd` – lovag ellenség AI (patrol → aggro → attack → hurt → dead) | Kész |
| Játékos–ellenség interakciók (sebzés, halál, kill counter) | Kész |
| `Game_Manager.gd` – `player_died` és `level_completed` szignálok, game-loop callbackek | Kész |
| `Level_Manager.gd` – szintbetöltés, reload, következő szintre léptetés | Kész |
| `goal.gd` – pályacél trigger, amely level complete-et jelez | Kész |
| `level0.tscn` – tesztpálya lovag játékossal és lovag ellenséggel | Kész |
| Főmenü → Level select → Level0 flow kialakítása | Kész |
| Level menü gombok (Level 2/3) scriptből történő bekötése és lock/unlock logika | Kész |
| HUD scene váz (`Hud` Node2D) | Folyamatban |
| Minimal grafikai asset-struktúra (sprites, textures, placeholder assets) | Kész |

### Tesztek

| Feladat                                      | Státusz |
|---------------------------------------------|---------|
| `tests/unit/test_level_manager.gd` – Level_Manager unit teszt | Kész |
| `tests/unit/test_save_manager.gd` – Save_Manager unit teszt   | Kész |
| `tests/unit/test_smoke.gd` – smoke test a projekt alap működésére | Kész |
| GUT integráció Godot projektbe (tesztek futtatása editorból és CI-ből) | Kész |

---

## Egyéni kontribúciók

### Erdei Bálint (KG7367) – @Balint000

- `playerKnight.gd` játékos logika és állapotgép kialakítása  
- Lovag játékos mozgás, ugrás, támadás és életkezelés implementálása  
- `knight_enemy.gd` ellenség AI újraírása (patrol/aggro/attack/hurt/dead state machine)  
- `Game_Manager.gd` bővítése: `player_died` és `level_completed` szignálok, on_player_death/on_level_complete callbackek  
- `Level_Manager.gd` funkciók bővítése (reload, load_next_level, level unlock logika)  
- `goal.gd` pályacél trigger implementálása és bekötése a GameManagerhez  
- `level0.tscn` tesztpálya felépítése lovag játékossal és lovag ellenséggel  
- Unit tesztek: `test_level_manager.gd`, `test_save_manager.gd`, `test_smoke.gd` létrehozása  
- Godot + GUT GitHub Actions workflow (godot-test.yml) finomhangolása

### Tóth Gábor (AL40F3) – @gabortoth55

- Szintválasztó logika korábbi verziójának (Level selection v1) alapjai, amelyekre a jelenlegi level menü épül  
- Review és visszajelzés a Level menü és flow kapcsán ebben a sprintben
- dijázn tervek a későbbi sprint-ekhez (pl. inventory kinézeti)
- tesztpálya fejlesztése

### Mogyorósi István (EJ8F5H) – @Mogyi13

- `main.tscn` és `level_menu.tscn` hibajavítások (scene-referenciák, gombok, layout finomhangolás)  
- Level menü flow stabilizálása (főmenü → szintválasztó → játék)  
- Közreműködés a skeleton pálya tesztelésében és a menük közötti navigáció ellenőrzésében
- GameManager fejlesztése

---

## Sprint eredmények

### Ami jól ment

- Elkészült az első játszható „skeleton” pálya (`level0.tscn`) lovag játékossal és lovag ellenséggel, így a mag gameplay loop (mozgás, ugrás, támadás, halál, pályaváltás) kipróbálható.  
- A játékos és az ellenség állapotgépei jól illeszkednek a korábban megtervezett viselkedésmodellekhez, a kód strukturáltan bővíthető.  
- A GameManager–LevelManager–SaveManager hármas révén a pályaváltás, halál és mentés logika átláthatóan központosítva lett.  
- A GUT unit tesztek és a GitHub Actions workflow már automatikusan futtatják a legfontosabb teszteket, ami csökkenti a regressziós hibák esélyét.

### Akadályok

- A játékos mozgás és ugrás finomhangolása (sebesség, gravitáció, jump arc) több iterációt igényel, hogy kellően „feszes” legyen platformerhez.  
- Az ellenség AI (aggro távolság, attack időzítés) balanszolása még folyamatban van, hogy fair, de kihívást adó legyen.  
- Játékos és ellenség támadásai finomhangolása.
- A HUD jelenleg csak váz, az életpont és egyéb státuszok vizuális visszajelzése hiányos.  
- A minimal grafikai assetek mellett a végleges saját assetek még nem kerültek implementálásra, így a vizuális stílus csak részben látszik.

### Tanulságok

- Megérte a játékos és ellenség logikát állapotgépben megvalósítani, így az új animációk és move-ok hozzáadása egyszerűbb lesz.  
- A GameManager és LevelManager központosított felelőssége nagyban egyszerűsíti a pályaváltás és a game loop kezelését.  
- A korai unit tesztek (Level/Save manager + smoke test) gyors visszajelzést adnak, ezért a következő sprintekben érdemes további kritikus rendszerekre is teszteket írni (enemy AI, player state gép).  

---

## Amit a következő sprintbe viszünk

### Sprint 3 fő céljai – javaslat

1. **Első „igazi” pálya (Level_01)**  
   – nagyobb, vertikális pálya több szinttel, csapdákkal és platform variációkkal.  

2. **HUD és UI kibővítése**  
   – életpont, sebződés visszajelzése, gyűjthető objektumok kijelzése.  

3. **További ellenségtípusok**  
   – új AI variánsok, eltérő támadásmintákkal és mozgással.  

4. **Mentés/betöltés felhasználói felület**  
   – „Continue” / „New Game” flow, mentett állások listázása.  

5. **Saját assetek bővítése**  
   – főkarakter és ellenségek saját sprite-jainak véglegesítése, környezeti tile set-ek készítése.  

