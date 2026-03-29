# Up The Tower

*BoMoGa Games*

Tóth Gábor *(AL40F3)*, Mogyorósi István *(EJ8F5H)*, Erdei Bálint *(KG7367)*

Modern szoftverfejlesztési eszközök *(GKNB_INTM129)*

2026. március 28. *(Eredeti: 2026. március 10.)*

---

## Tartalomjegyzék

1. [Bevezetés](#1-bevezetés)
   - 1.1 [Játék alapkoncepció](#11-játék-alapkoncepció)
   - 1.2 [Játék célja és játékmenet](#12-játék-célja-és-játékmenet)
   - 1.3 [Tecnológiai háttér](#13-tecnológiai-háttér)
2. [Történetvázlat](#2-történetvázlat)
3. [Követelmények](#3-követelmények)
4. [Használati esetek (Use-cases)](#4-használati-esetek-use-cases)
5. [Rendszer struktúra](#5-rendszer-struktúra)
   - 5.1 [Scene Hierarchia](#51-scene-hierarchia)
   - 5.2 [Node Architektúra Példa (Player)](#52-node-architektúra-példa-player)
   - 5.3 [Kompnens kapcsolati diagram](#53-kompnens-kapcsolati-diagram)
   - 5.4 [Játéktér előállítása (Godot Engine-ben)](#54-játéktér-előállítása-godot-engine-ben)
6. [Viselkedés modellezés](#6-viselkedés-modellezés)
   - 6.1 [Player állapotgép](#61-player-állapotgép)
   - 6.2 [Teljes játék állapotgépe](#62-teljes-játék-állapotgépe)
7. [Fájlformátum és tárolás](#7-fájlformátum-és-tárolás)
   - 7.1 [Projekt fájlszerkezete](#71-projekt-fájlszerkezete)
   - 7.2 [Fájltípusok és funkciók](#72-fájltípusok-és-funkciók)
   - 7.3 [Mentési rendszer](#73-mentési-rendszer)
   - 7.4 [A mentett adatok logikai szerkezete](#74-a-mentett-adatok-logikai-szerkezete)
   - 7.5 [Statisztikai alstruktúra](#75-statisztikai-alstruktúra)
   - 7.6 [Futás idejű (nem mentett) adatok](#76-futás-idejű-nem-mentett-adatok)
   - 7.7 [Resource alapú adatmodell (.tres)](#77-resource-alapú-adatmodell-tres)
   - 7.8 [Karakter Resource struktúra](#78-karakter-resource-struktúra)
   - 7.9 [Enemy Resource struktúra](#79-enemy-resource-struktúra)
   - 7.10 [Állapotkezelési modell](#710-állapotkezelési-modell)
8. [Adatfolyam](#8-adatfolyam)
   - 8.1 [Játék indítása](#81-játék-indítása)
   - 8.2 [Mentés adatfolyama (binárisan)](#82-mentés-adatfolyama-binárisan)
   - 8.3 [Betöltés adatfolyama](#83-betöltés-adatfolyama)
9. [Ötletgyűjtés](#9-ötletgyűjtés)
10. [Tesztelés](#10-tesztelés)
    - 10.1 [Teszt példa](#101-teszt-példa)
11. [Osztálystruktúra és felelősségi körök](#11-osztálystruktúra-és-felelősségi-körök)
    - 11.1 [Fő osztályok felsorolással](#111-fő-osztályok-felsorolással)
12. [Glossary (szójegyzék)](#12-glossary-szójegyzék)
13. [Összegzés](#13-összegzés)

### Táblázatok

- [Funkcionális követelmények](#table-1-funkcionális-követelmények)
- [Nem-funkcionális követelmények](#table-2-nem-funkcionális-követelmények)
- [Használati esetek](#table-3-használati-esetek)
- [Fájltípusok](#table-4-fájltípusok)
- [Glossary](#table-5-glossary)

### Ábrajegyzék

- [Használati esetek](#figure-1-használati-esetek)
- [Player state machine](#figure-2-player-state-machine)
- [Full game state machine](#figure-3-full-game-state-machine)
- [Mindmap](#figure-4-mindmap)
- [Class diagram](#figure-5-class-diagram)

---

## 1. Bevezetés

Ez a specifikáció az ,,Up The Tower" vertikális platformer játékhoz készült, amely a Godot Engine 4 fejlesztőkörnyezetben valósul meg. A projekt a Modern Szoftverfejlesztési Eszközök tantárgy keretein belül készül, melynek célja egy komplett, játszható platformer játék létrehozása a félév során.

### 1.1 Játék alapkoncepció

Az ,,Up The Tower" egy 2D vertikális platformer játék, ahol a játékos célja egy titokzatos torony legtetejére való eljutás. A játékmenet középpontjában a felfelé haladás áll: a játékosnak platformokról platformra kell ugrálnia, ellenfelekkel kell megküzdenie vagy azokat kikerülnie, puzzle-okat kell megoldania, és felvehető tárgyakat gyűjtenie a siker érdekében. A játék különböző karakterek közötti választási lehetőséget is kínál, amelyek eltérő képességekkel rendelkeznek, így változatos játékélményt nyújtanak.

### 1.2 Játék célja és játékmenet

A játék fő célja a torony tetejének elérése, ahol a végső kihívás és egy történeti lezárás várja a játékost. A torony több szintből áll, mindegyik egyedi kihívásokkal, ellenségekkel és akadályokkal. A játékos billentyűzetről irányítja karakterét (WASD vagy nyíl billentyűk mozgásra, Space ugrásra, Shift speciális képességre).

### 1.3 Tecnológiai háttér

A játék fejlesztése a Godot Engine 4 nyílt forráskódú játékfejlesztő motorban történik, amely ideális választás 2D platformer játékokhoz. A Godot beépített fizikai motorja (CharacterBody2D, Area2D), scene-alapú architektúrája és a GDScript szkriptnyelv lehetővé teszi a gyors prototípus-készítést és iteratív fejlesztést.

Fejlesztői környezet és eszközök:

- **Godot Engine 4:** Fő fejlesztői platform
- **GDScript:** Játéklogika implementálása
- **Git/GitHub:** Verziókezelés, projekt repository: https://github.com/Balint000/up-the-tower
- **Operációs rendszerek:** Fedora 43 (Wayland) és Windows 11
- **Cél platformok:** Linux és Windows x64 architektúra
- **Asset formátumok:** .png sprite-ok, .tscn scene fájlok, .tres resource fájlok

---

## 2. Történetvázlat

A történet egy mágikus világban játszódik, ami tele van élettel és kalandokkal. Legalábbis egykor így volt… Már több évtizede következett be a tragédia. A hatalmas eretnek háború után már semmi sem a régi. A hajdani hangos városok többnyire romokban és üresen, az emberek nagy része elvészett a pusztító háborúban, aki megmaradt, pedig elszigetelődött életet él, Néhányan próbálják újraépíteni a régi rendet és újrakezdeni életüket a harc tépázta földeken.

A főhősünk erdőkkel és hó borította hegyekkel körbezárt völgybe vágtat és egy magányos várhoz érkezik, mely egykor fontos szerepet játszhatott a háborúban. Egyesek azt suttogják, hogy a véres háború alatt ezen a helyen egy zsarnok uralkodott és csak egy dolog járt a fejében: olyan fegyvert, eszközt, mágiát létrehozni, ami minél halálosabb és így segítheti az ő félelmen alapuló uralkodását.

Ki ez a rejtélyes alak, aki épp most érkezett és ki küldte ide? Milyen szörnyűségeket készíthettek e robosztus falak között? Mi a végső küldetés? Ezekre a kérdésekre egyelőre nem tudni a választ. Az egy biztos dolog, hogy valamit tennie kell a rejtélyes embernek, feladata van itt.

A vár vastag, romos falai közül sikolyok és vérfagyasztó üvöltések hallatszódnak, törött ablakok és tűz okozta korom nyomok mindenütt. Továbbá ott van az az ominózus torony is, a tetejét nem is látni a felhőktől. A hős leszáll lováról és az óriási kapu felé lép.

Most már rajta múlik a vár és lakosainak sorsa. Kell segítség nekik, vagy csak elvégzi a rábízott a feladatot? Nem tudni mi vár rá odabent, de látszik a magányos hős arcán, hogy felkészült a legrosszabbra is. Vajon mit rejthet a sötét torony?

---

## 3. Követelmények

A következő követelmények határozzák meg a játék funkcionális és nem-funkcionális jellemzőit, prioritási szintekkel ellátva.

#### Table 1: Funkcionális követelmények

| ID | Megnevezés | Leírás | Prioritás |
|----|-----------|--------|-----------|
| K01 | Vertikális platformer struktúra | A játéktér felfelé épül, pályák vertikális elrendezésben | Magas |
| K02 | Karakterválasztás | 4 játszható karakter (lovag, mágus, íjász, tolvaj) eltérő képességekkel | Közepes |
| K03 | Ellenség AI rendszer | Ellenfelek reagálnak a játékosra (patrol, attack, aggro) | Magas |
| K04 | Legalább 3 pálya | Minimum három különböző szint növekvő nehézséggel | Magas |
| K05 | Billentyűzet irányítás | WASD/nyilak: mozgás, Space: ugrás, Shift: speciális képesség, ESC: pause | Magas |
| K06 | Játék vége feltétel | Win/Lose állapotok: torony teteje elérése vagy HP=0 | Magas |
| K07 | Checkpoint rendszer | Mentési pontok, respawn mechanizmus | Közepes |
| K08 | Power-up rendszer | Gyűjthető tárgyak (életerő, speciális képességek) | Közepes |
| K09 | Fizikai szimuláció | Gravitáció, ütközésdetektálás, platformon állás (CharacterBody2D) | Magas |
| K10 | Saját assetek használata | Egyedi grafikai elemek, nem stock sprite-ok | Magas |
| K11 | Linux/Windows kompatibilitás | x64 build mindkét platformra | Magas |
| K12 | Mentési rendszer | Játékállás mentése és betöltése (binárisan) | Alacsony |

#### Table 2: Nem-funkcionális követelmények

| ID | Megnevezés | Leírás | Prioritás |
|----|-----------|--------|-----------|
| N01 | Teljesítmény | Minimum 60 FPS fenntartása gameplay során | Magas |
| N02 | Válaszidő | Input késleltetés maximum 50ms | Magas |
| N03 | Karbantarthatóság | Dokumentált kód (kommentek), scene-alapú struktúra | Magas |
| N04 | Tesztelhetőség | Unit tesztek (GUT framework) kritikus komponensekre | Közepes |
| N05 | Felhasználói élmény | Intuitív kontrollok, vizuális visszajelzések (damage flash, jump arc) | Közepes |

---

## 4. Használati esetek (Use-cases)

A használati esetek a játékos (Actor) és a játékrendszer közötti interakciókat írják le. Az UML usecase diagram szemlélteti a főbb funkciókat és azok kapcsolatait.

#### Table 3: Használati esetek

| ID | Megnevezés | Leírás | Prioritás |
|----|-----------|--------|-----------|
| UC01 | Mozgás | Játékos balra/jobbra mozog billentyű lenyomásra | Magas |
| UC02 | Ugrás | Játékos Space billentyűre ugrik, gravitáció hat rá | Magas |
| UC03 | Támadás | A játékos sebezni tudja az ellenfeleket | Közepes |
| UC04 | Sebződés | Játékos HP csökken ellenség érintésekor | Magas |
| UC05 | Halál | Játékos HP = 0 esetén meghal és újrakezdődik a level | Magas |
| UC06 | Szint teljesítése | Játékos eléri a Goal objectet és következő level töltődik | Magas |
| UC07 | Pause Game | Játékos ESC-re pause menü nyílik | Alacsony |
| UC08 | Enemy Patrol | Ellenség automatikusan mozog fix útvonalon | Magas |
| UC09 | Enemy Attack | Ellenség támad ha játékos közel kerül | Közepes |
| UC10 | Speciális képesség | Karakter specifikus képesség használata (Shift): dash, double jump, block, fireball | Közepes |
| UC11 | Tárgy használat | Játékos egyszer használatos tárgyakat használ | Alacsony |
| UC12 | Interact | Játékos interakciót kezdeményez egy objektummal | Alacsony |

## 5. Rendszer struktúra

A rendszer struktúra scene-alapú architektúráján alapul. A játék fő építőelemei a Node-ok és Scene-ek, amelyek hierarchikus rendszert alkotnak.

### 5.1 Scene Hierarchia

A Godot-ban minden játékelem egy Scene, amely Node-okból épül fel. Az alábbi főbb scene-ek alkotják a játékot:

- **MainMenu.tscn:** Főmenü, karakterválasztás, beállítások
- **Level_X.tscn:** Pályák (Level_01, Level_02, Level_03)
- **Player.tscn:** Játszható karakter (CharacterBody2D alapú)
- **Enemy.tscn:** Ellenség karakter
- **UI/HUD.tscn:** Felhasználói interfész (életerő, pontok)

### 5.2 Node Architektúra Példa (Player)

```
Player (CharacterBody2D)
├── CollisionShape2D
├── AnimatedSprite2D
├── HealthComponent (Node)
├── InputHandler (Node)
├── AbilityManager (Node)
```

### 5.3 Kompnens kapcsolati diagram

```
┌─────────────────┐
│   GameManager   │ (Singleton, autoload)
└────────┬────────┘
         │ manages
         ├──────> LevelManager (autoload)
         ├──────> SaveSystem (autoload)
         └──────> StatisticsTracker (autoload)

┌─────────────────┐         ┌─────────────────┐
│     Player      │◄───────►│     Enemy       │
│ (CharacterBody2D) │ detects │ (CharacterBody2D) │
└────────┬────────┘         └────────┬────────┘
         │ uses                      │ uses
         ▼                           ▼
┌─────────────────┐         ┌─────────────────┐
│CharacterResource │         │  EnemyResource  │
│    (.tres)      │         │    (.tres)      │
└─────────────────┘         └─────────────────┘
```

### 5.4 Játéktér előállítása (Godot Engine-ben)

A játék pályáinak tervezése és előállítása manuálisan történik a Godot Engine 4 beépített szerkesztőeszközeivel. A pályák scene-ekként (.tscn fájlok) kerülnek tárolásra, amelyek Node-ok hierarchikus gyűjteményei.

#### 5.4.1 Pályatervezési munkafolyamat

A pályák létrehozása a következő lépésekben történik:

1. **Új Scene létrehozása:** Minden pálya egy külön scene (pl. Level01.tscn, Level02.tscn)
2. **Root node kiválasztása:** Node2D vagy CanvasLayer a pálya gyökéreleme
3. **TileMap beállítása:** TileSet erőforrás importálása, amely tartalmazza a platformok, falak textúráit
4. **Manuális pályaszerkesztés:** A Godot TileMap Paint eszközével kézzel rajzolva helyezzük el:
   - Platformokat (CollisionShape2D-vel ellátott TileMap cellák)
   - Falakat és akadályokat
   - Háttér elemeket (dekoráció, parallax layers)
5. **Entitások elhelyezése:** Scene instance-ok használatával:
   - Enemy.tscn példányok pozícionálása
   - Checkpoint.tscn pickup objektumok
   - Goal.tscn pályavég marker
6. **Lighting és effektek:** Light2D node-ok, particle rendszerek hozzáadása

#### 5.4.2 TileMap alapú pályaépítés

A platformok és felületek TileMap node-dal kerülnek definiálásra:

- **TileSet Resource:** Tartalmazza a tile textúrákat és fizikai tulajdonságokat
- **Collision Layers:** Physics layer 1 = platforms, layer 2 = walls
- **Terrain Setup:** Autotiling szabályokkal gyorsítva a rajzolást

#### 5.4.3 Prefab alapú objektum elhelyezés

Az ellenségek, gyűjthető tárgyak és interaktív objektumok előre elkészített scene-ek példányaiként (prefab) kerülnek a pályára:

- **Enemy placement:** Enemy.tscn instance-ok manuális drag-and-drop
- **Patrol path setup:** Path2D node-ok rajzolása az ellenség járőrútvonalához
- **Pickup spawning:** PowerUp.tscn, Coin.tscn pozícionálás
- **Checkpoint positioning:** Checkpoint.tscn stratégiai pontokra helyezés

---

## 6. Viselkedés modellezés

A viselkedés modellezés állapotgép (state machine) diagramokkal történik, amelyek a játékos, ellenségek és a teljes játék állapotait és átmeneteit ábrázolják.

### 6.1 Player állapotgép

A játékos karakternek több állapota van, amelyek között a bemenet és események alapján vált át.

### 6.2 Teljes játék állapotgépe

A komplett játékfolyamat állapotgépe minden menüpontot és játékállapotot tartalmaz.

Ez a diagram tartalmazza:

- **Összes menüállapot:** SessionStart, LevelSelection, Settings (Video/Audio/Controls/Gameplay)
- **Gameplay loop részletezése:** LevelLoad → LevelPlay → LevelSuccess/LevelPause/LevelFail
- **Játék befejezési útvonalak:** EndingSequence → CreditsRoll → SessionEnd
- **Hibaállapotok:** ErrorScreen (fatal error esetén)

## 7. Fájlformátum és tárolás

A játék adatstruktúráját és tárolási mechanizmusát a Godot Engine beépített rendszerei határozzák meg.

### 7.1 Projekt fájlszerkezete

```
.
├── assets
├── docs
├── README.md
├── scenes
│   ├── entities
│   │   ├── items
│   │   ├── enemies
│   │   │   └── knightEnemy.tscn
│   │   └── player
│   │       └── MainCharacter.tscn
│   ├── environment
│   ├── ui
│   ├── inventory
│   │   └── inventory.tscn
│   ├── levels
│   │   └── levels.tscn
│   └── main
│       └── main.tscn
├── scripts
│   ├── entities
│   │   ├── items
│   │   ├── enemies
│   │   └── player
│   ├── utils
│   ├── ui
│   ├── autoload
│   │   ├── Level_Manager.gd.uid
│   │   └── Level_Manager.gd
│   ├── main
│   │   ├── main.gd
│   │   └── main.gd.uid
│   ├── inventory
│   │   ├── inventory.gd
│   │   └── inventory.gd.uid
│   └── levels
│       ├── levels.gd.uid
│       └── levels.gd
├── project.godot
├── resources
│   ├── materials
│   ├── themes
│   ├── characters
│   ├── items
│   └── enemies
└── data
    ├── characters
    ├── enemies
    └── items
```

### 7.2 Fájltípusok és funkciók

#### Table 4: Fájltípusok

| Fájltípus | Funkció | Példa |
|-----------|---------|-------|
| .tscn | Scene fájl (pályák, UI, karakterek) | Level_01.tscn |
| .tres | Resource fájl (karakter & enemy statok) | knight.tres |
| .gd | GDScript állomány (logika) | Player.gd |
| .save | Bináris mentési fájl | user://game.save |

### 7.3 Mentési rendszer

A mentési rendszer a Godot beépített bináris szerializációját használja. A mentési fájl a `user://game.save` útvonalon kerül tárolásra.

**Mentési filozófia**

- **Perzisztens adatok:** Pályaprogreszsó, feloldott szintek, karakter választás, statisztikák
- **Nem mentett (runtime) adatok:** Aktuális életerő, pozíció, cooldown-ok, power-up állapotok

Minden pálya betöltésekor a játékos maximális életerővel indul, így egyszerűbb és stabilabb az állapotkezelés.

### 7.4 A mentett adatok logikai szerkezete

A mentési fájl egy összetett Dictionary struktúrát tartalmaz, amely a játék globális állapotát és statisztikáit tárolja. A mentési objektum logikai felépítése az alábbi:

**SaveData struktúra (példa):**

```
current_level: String
selected_character: String
unlocked_levels: Array
statistics: Dictionary
timestamp: Unix time
```

A `current_level` mező a következő betöltendő pálya scene fájljának azonosítóját tárolja. A `selected_character` a kiválasztott karakter típusát jelöli.

A mentési struktúra nem tartalmazza a játékos aktuális életerejét vagy pozícióját, mivel ezek minden pálya indításakor újrainicializálódnak a karakter alapértékei alapján.

### 7.5 Statisztikai alstruktúra

A `statistics` mező egy külön Dictionary, amely a játékos globális teljesítményadatait tartalmazza. Ennek célja a hosszú távú játékosi viselkedés mérése és későbbi rendszerbővítések (achievement, leaderboard, balanszolás) támogatása. A statisztikai mezők kumulatív jellegűek, és minden mentési eseménynél frissítésre kerülnek.

A struktúra például a következő mezőket tartalmazza:

```
total_deaths: int
total_kills: int
total_gold_collected: int
levels_completed: int
total_playtime: float
```

A struktúra bővíthető további mezőkkel a fejlesztés későbbi fázisában anélkül, hogy a rendszer architekturálisan módosulna.

### 7.6 Futás idejű (nem mentett) adatok

Ahogy a mentési filozófiánál említve lett, a `player_data` struktúrában, amely pozíciót és cooldown állapotokat tartalmaz nem került be a perzisztens mentési modellbe.

**Tervezett szerkezet:**

```
health: int
position: Vector2
cooldown_states: Dictionary
```

Ezek az adatok kizárólag a szint futása alatt léteznek a memóriában, és a pálya újratöltésekor újrainicializálódnak a karakter maximális értékei alapján. Ez a megoldás csökkenti a mentési komplexitást és stabilabb állapotkezelést biztosít.

### 7.7 Resource alapú adatmodell (.tres)

A játék karakterei és ellenfelei nem a mentési fájlban kerülnek tárolásra, hanem külön Resource objektumként léteznek. A Godot engine lehetővé teszi az egyedi erőforrás osztályok létrehozását, amelyek „.tres" formátumban menthetők.

Ez a megközelítés tiszta adat–logika szétválasztást biztosít, a statikus karakterparaméterek nem keverednek a dinamikus játékállapottal.

### 7.8 Karakter Resource struktúra

Minden játszható karakter egy egyedi Resource objektumként van definiálva:

- knight.tres
- mage.tres
- archer.tres
- thief.tres

Ezek egy közös alaposztályból származnak (`character_resource.gd`).

**A karakter resource logikai mezői (példa):**

```
character_name: String
max_health: int
base_damage: int
movement_speed: float
abilities: Array
```

A `max_health` mező biztosítja, hogy minden pálya betöltésekor a játékos életereje a karakter alapértékére álljon vissza.

### 7.9 Enemy Resource struktúra

Az ellenfelek hasonló módon kerülnek definiálásra egy külön `enemy_resource.gd` osztály segítségével.

**Tipikus mezők:**

```
enemy_name: String
max_health: int
damage: int
speed: float
behavior_type: String
attack_cooldown: float
```

Ez a struktúra lehetővé teszi az ellenfelek paraméterezett példányosítását külön logikai módosítás nélkül.

### 7.10 Állapotkezelési modell

A rendszer implicit módon stateless pályakezdési modellt alkalmaz. A perzisztens mentés kizárólag metaállapotot tárol (progresszió és statisztikák), míg a játékmenet-állapot minden szint betöltésekor determinisztikusan újrainicializálódik. Ez csökkenti az állapotinkonzisztencia és sérült mentések kockázatát.

---

## 8. Adatfolyam

Az adatfolyam diagramok szemléltetik a rendszer működését, különös tekintettel a fájlműveletekre (mentés/betöltés).

### 8.1 Játék indítása

```
[Felhasználó]
      ↓
[Main Menu]
      ↓
[GameManager]
      ↓
Scene betöltés (.tscn)
      ↓
Karakter resource betöltés (.tres)
      ↓
Játék inicializálás
```

### 8.2 Mentés adatfolyama (binárisan)

```
[Player Event]
      ↓
[GameManager]
      ↓
[SaveSystem]
      ↓
Dictionary létrehozás
      ↓
FileAccess.open("user://game.save", WRITE)
      ↓
store_var(save_data)
      ↓
Fájl lezárása
```

### 8.3 Betöltés adatfolyama

```
[Main Menu – Load]
      ↓
[SaveSystem]
      ↓
FileAccess.open("user://game.save", READ)
      ↓
get_var()
      ↓
SaveData visszaállítása
      ↓
GameManager frissítése
      ↓
Level betöltés
```

---

## 9. Ötletgyűjtés

A projekt tervezése során készült egy részletes mindmap, amely a játék különböző aspektusait gyűjtötte össze és strukturálta.

Főbb kategóriák a mindmap-en:

1. **Fejlesztőkörnyezet:** Godot Engine
2. **Téma:** Horror, Fantasy, Sci-fi opciók → végül Fantasy választva
3. **Dizájn/Környezet:** Középkori falu, torony, erdő
4. **Szint nézet:** Vertikális vs. Horizontális → Vertikális választva
5. **Cél:** Rejtély megoldás, Megmászni a tornyot, Bolygó kolonizálás → Torony megmászása választva
6. **Grafika:** Pixel-art, Vektorgrafikus, Rajz → Pixel-art választva

Ez a diagram segített a csapatnak konszenzusra jutni a játék alapkoncepcióját illetően, és dokumentálja a döntéshozatali folyamatot.

## 10. Tesztelés

A tesztelési stratégia biztosítja a kód minőségét és a funkcionalitás helyességét. A Godot-hoz a GUT (Godot Unit Test) framework-öt használjuk. Emellett a Github Actions segítségével automatizáltan le tudjuk futtatni ezeket a teszteket minden commit után. Ennek segítségével meg fogjuk tudni akadályozni, hogy hibás kód kerüljön a master ágra.

### 10.1 Teszt példa

```gdscript
extends GutTest

func test_player_movement_speed():
    var player = Player.new()
    player.movement_speed = 200.0
    # Szimulált input
    player.move_direction = Vector2.RIGHT
    player._physics_process(0.016) # ~60 FPS
    assert_gt(player.velocity.x, 0, "Player should move right")
    assert_eq(player.velocity.x, 200.0, "Speed should match")
```

---

## 11. Osztálystruktúra és felelősségi körök

A `GameManager` felel a globális játékállapot kezeléséért, a pályabetöltésért és a statisztikák frissítéséért.

A `SaveSystem` kizárólag a mentési és betöltési műveletekért felelős. A rendszer egyetlen Dictionary objektumot szerializál binárisan, amely a SaveData struktúrát reprezentálja.

A Resource osztályok (`CharacterResource`, `EnemyResource`) kizárólag konfigurációs adatokat tartalmaznak, és nem kezelnek játékmeneti logikát. Ez a felelősségi szétválasztás biztosítja az alacsony csatolást és a könnyű karbantarthatóságot.

### 11.1 Fő osztályok felsorolással

**GameManager.gd (Singleton)**
- Globális játékállapot kezelése
- Statisztikák frissítése
- SaveSystem hívása
- Scene váltások

**SaveSystem.gd**
- Mentési/betöltési műveletek
- Bináris szerializáció kezelése
- Fájl I/O műveletek

**LevelManager.gd**
- Pályabetöltés koordinálása

**Enemy.gd (CharacterBody2D)**
- Ellenség logika (patrol, attack)
- Játékos detektálás (aggro range)
- Támadási mechanizmus

**CharacterResource.gd (Resource)**
- Karakter statikus paraméterei
- Konfigurációs adatok tárolása
- Fizikai mozgás (_physics_process)
- Életerő kezelés
- Animáció vezérlés

**EnemyResource.gd (Resource)**
- Ellenség statikus paraméterei
- Viselkedés típus definíció

## 12. Glossary (szójegyzék)

#### Table 5: Glossary

| Kifejezés | Magyarázat |
|-----------|-----------|
| Vertikális platformer | Olyan platformer játék, ahol a fő haladási irány felfelé történik |
| CharacterBody2D | Godot node típus, fizikai testet reprezentál mozgással és ütközéssel |
| Area2D | Godot node típus, területalapú ütközésdetektálásra |
| Scene | Godot alapegység, node-ok hierarchikus gyűjteménye, újrafelhasználható |
| Node | Godot alapelem, mindenféle játékentitás ősosztálya |
| Resource | Godot adat-tároló osztály, perzisztens konfiguráció (.tres fájl) |
| GDScript | Godot saját szkriptnyelve, Python-szerű szintaxissal |
| State Machine | Állapotgép, viselkedés modellezése diszkrét állapotokkal és átmenetekkel |
| Use-case | Használati eset, a rendszer és aktor közötti interakció leírása |
| Binális szerializáció | Adatstruktúra átalakítása bináris formátumba mentés céljából |
| Singleton | Tervezési minta, egyetlen példányú globális objektum (autoload Godotban) |
| TileMap | Godot node típus, csempe-alapú pályák építésére |
| Collision Shape | Ütközési alakzat, fizikai ütközésdetektáláshoz szükséges |
| Sprite | 2D grafikai elem, karakterek és objektumok vizuális reprezentációja |
| HUD | Heads-Up Display, játék közbeni felhasználói interfész |
| Respawn | Újjáéledés, játékos halála után új pozícióban való megjelenés |
| Checkpoint | Mentési pont, ahonnan újrakezdődik a játék halál esetén |
| Power-up | Ideiglenes vagy állandó erősítés (életerő, sebzés, sebesség) |
| Aggro | Aggression, ellenség figyelme a játékosra irányul |
| Patrol | Járőrözés, ellenség mozgása előre meghatározott útvonalon |
| Bundle | Lefordított és futtatható állomány, export után |
| CI/CD | Continuous Integration/Continuous Deployment, automatizált tesztelés és deploy |
| GUT | Godot Unit Test, unit teszt framework Godot-hoz |
| Pixel-art | Grafikai stílus, pixelekből épített alacsony felbontású művészet |

---

## 13. Összegzés

Ez a specifikáció részletesen bemutatja az "Up The Tower" vertikális platformer játék teljes tervezését a Godot Engine 4 platformon. A dokumentum tartalmazza:

- **Történetvázlat:** Fantasy mágikus világ, eretnek háború után, titokzatos torony felfedezése
- **Követelmények:** 12 funkcionális és 5 nem-funkcionális követelmény táblázatban
- **Használati esetek:** 12 use-case azonosítva, UML diagrammal
- **Rendszer struktúra:** Scene/Node hierarchia, Resource-alapú adatmodell
- **Viselkedés modellezés:** 3 állapotgép diagram (player, game flow, full game)
- **Fájlformátum és tárolás:** Godot-specifikus (.tscn, .tres, .save), mentési rendszer
- **Adatfolyam diagramok:** Indítás, mentés, betöltés, gameplay loop
- **Ötletgyűjtés:** Mindmap diagram a koncepció kialakításához
- **Tesztelés:** GUT framework, konkrét tesztesetek, GitHub Actions
- **Fejlesztési terv:** 3 fázis (specifikáció, szkeleton, teljes), eszközök, módszertan

**Következő lépés:** Szkeleton verzió implementálása alapmozgással és egy pályával.

**Csapat tagok:** Tóth Gábor, Mogyorósi István, Erdei Bálint

**Github Repository:** https://github.com/Balint000/up-the-tower

**Használt eszközök:** Visual Paradigm, Mermaid.live, Godot documentation
