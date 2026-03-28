# Sprint 1 – Összefoglaló

**Projekt:** Up The Tower
**Csapat:** BoMoGa Games 
**Sprint időtartama:** 2026. február – 2026. március 28. 
**Sprint célja:** Dokumentáció elkészítése, GitHub repository beüzemelése, projekt alapstruktúra felállítása

---

## Elvégzett feladatok

### Dokumentáció

| Feladat | Státusz | Felelős |
|---------|---------|---------|
| Projekt specifikáció (PDF) | Kész | Közös |
| README.md | Kész | Közös |
| CHANGELOG.md | Kész | Közös |
| ARCHITECTURE.md (Mermaid diagramok) | Kész | Közös |
| Sprint1.md | Kész | Közös |

### GitHub és infrastruktúra

| Feladat | Státusz |
|---------|---------|
| Repository létrehozása | Kész |
| `.gitignore`, `.gitattributes` konfigurálása | Kész |
| GitHub Actions CI/CD pipeline | Folyamatban |

### Godot projekt

| Feladat | Státusz |
|---------|---------|
| Projekt inicializálása (Godot 4.6) | Kész |
| Scene struktúra kialakítása | Kész |
| Autoload singleton vázak | Kész |
| Főmenü navigáció (Play → LevelSelect → Back) | Kész |
| Játékos scene placeholder assetekkel | Kész |
| Ellenség scene placeholder assetekkel | Kész |
| GUT teszt framework integráció | Folyamatban |

---

## Egyéni kontribúciók

### Erdei Bálint (KG7367) – @Balint000

- GitHub repository létrehozása és adminisztrálása
- Godot projekt inicializálása és konfigurálása (`project.godot`)
- Scene struktúra tervezése és kialakítása
- LevelManager fejlesztése
- GUT teszt framework integrálása
- GitHub Actions CI/CD pipeline konfigurálása
- Tesztelési stratégia meghatározása
- Tesztpálya létrehozása

### Tóth Gábor (AL40F3) – @gabortoth55

- Játékkoncepció és történetvázlat megírása
- Játékos scene és ellenség scene összeállítása placeholder animációkkal
- Projekt specifikáció dokumentum elkészítése (tartalomjegyzék, technológiai háttér, osztálystruktúra)
- Use-case diagramok és táblázatok
- Viselkedésmodellek (player állapotgép, teljes játék állapotgép) tervezése
- Glossary (szójegyzék) összeállítása

### Mogyorósi István (EJ8F5H) – @Mogyi13

- Fájlformátum és mentési rendszer specifikálása
- Ötletgyűjtés koordinálása (mindmap)
- Funkcionális és nem-funkcionális követelmények definiálása
- Adatfolyam diagramok készítése
- GameManager és SaveManager fejlesztése

---

## Sprint eredmények

### Ami jól ment

- Összeszokott csapat -> gyors feladatmegbeszélések
- A csapat gyorsan megállapodott a játékkoncepción (fantasy, vertikális platformer, pixel-art stílus)
- A Godot Engine alapstruktúrája gyorsan felállt, a scene-based architektúra jól illeszkedik a tervezett felépítéshez
- A specifikáció dokumentum átfogóan lefedi a rendszer tervezett viselkedését

### Akadályok

- **Asetek hiánya:** A végleges, saját készítésű grafikai elemek még nem állnak rendelkezésre; jelenleg placeholder asset csomagokat (Tiny RPG Character Pack, Legacy Collection) használunk/fogunk használni. A saját assetek készítése a következő sprintek feladata.
- **Godot verziókompatibilitás:** A fejlesztők különböző operációs rendszereken (Windows 11 és Fedora 43 Wayland) dolgoznak, ami néhány konfigurációs különbséget eredményezett (D3D12 vs. Vulkan renderer). Ez a `project.godot`-ban kezelve lett.
- **GUT verzió:** A CI pipeline-ban a megfelelő Godot + GUT verzió párosítás beállítása több iterációt igényelt.
- **Időbeosztás:** A dokumentáció terjedelme (specifikáció, diagramok, több markdown fájl) a tervezettnél több időt vett igénybe, ami a kódolási munkát némileg hátráltatta.

### Tanulságok

- A részletes specifikáció elkészítése előre megkönnyíti az implementációs döntéseket
- A CI/CD korai beállítása megéri a befektetett időt
- Érdemes lenne a következő sprintben a feature branch stratégiát pontosabban definiálni

---

## Amit a következő sprintbe viszünk

### Sprint 2 fő céljai

1. **Játékos mozgás implementálása** – WASD/nyíl billentyű kezelés, gravitáció, `CharacterBody2D` fizika
2. **Ugrás mechanika** – egyszeri és dupla ugrás, jump arc
3. **Animáció rendszer** – állapothoz kötött animációk (idle, walk, jump, fall, hurt, death)
4. **Első pálya (Level_01)** – TileMap alapú alappálya, platformok, akadályok
5. **Alap ellenség AI** – patrol mozgás fix útvonalon, játékos detektálás
6. **HUD alapok** – életpont megjelenítés
7. **Saját asset-ek megkezdése** – legalább a főkarakter sprite sheet-je

### Szükséges erőforrások

- LibreSprite a saját sprite-ok elkészítéséhez
- Referencia pályatervek (vázlatos szintrajzok) a pályaépítés megkezdéséhez
- Döntés a 4 karakter közül az első fejlesztési sorrendjéről
