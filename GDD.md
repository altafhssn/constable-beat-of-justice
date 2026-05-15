# CONSTABLE: BEAT OF JUSTICE
## Game Design Document

**Version:** 1.0
**Engine:** Godot 4.6.2
**Target:** Mobile-only (Android/iOS)
**Genre:** Action Roguelike — Indian Police Procedural
**Est. Timeline:** 10 Weeks (MVP), 14 Weeks (Full)
**Budget:** ₹62K – ₹1.02L

---

## 1. CONCEPT & ELEVATOR PITCH

**Elevator Pitch:** *Hades meets Singham — a turn-based roguelike where you play a small-town police constable climbing through 25 floors of corruption, rescuing civilians and collecting warrants to take down the Commissioner.*

**Core Fantasy:** You're not a superhero. You're a beat cop with a lathi, a revolver, and your wits. Each run, you descend deeper into the underworld — from the chaotic Basti to the marble halls of the Commissioner's estate. Rescue civilians, seize illegal weapons, and serve warrants. Die, and you're back at the station, stronger and wiser.

**Market Gap:** Zero Indian-culture action roguelites on the market. The audience is 1.5B+ Indians hungry for representation + global roguelike fans seeking fresh setting.

---

## 2. CORE GAME LOOP

```
┌─────────────────────────────────────────────────────────┐
│                  POLICE STATION (HUB)                    │
│  • Upgrade weapons, spend Seva Points, read diary       │
│  • Select district difficulty / floor range              │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────┐
│              FLOOR (1 of 25)                             │
│  • BSP-generated dungeon rooms                           │
│  • Enemies patrol, civilians trapped                     │
│  • Player explores, fights, rescues                      │
│  • Find stairs → descend                                 │
└──────────────────────┬──────────────────────────────────┘
                       │
          ┌────────────┴────────────┐
          ▼                         ▼
    FLOOR 5/10/15/20/25       DEATH
    (BOSS FLOOR)              │
          │                   ▼
          ▼           POLICE STATION
    ┌─────────┐      (spend Seva
    │ DEFEAT  │      Points, weep,
    │ BOSS ✓  │      try again)
    └────┬────┘
         │
         ▼
    Continue or Win
```

**Per-Floor Loop:**
1. Enter floor → room-by-room exploration
2. Clear enemies in each room
3. Optional: rescue civilian → earn Seva Points
4. Optional: find hidden Warrant upgrade
5. Reach stairs → descend
6. Every 5th floor: BOSS FIGHT

---

## 3. FLOOR THEMES & PROGRESSION

| Floors | Theme | Visual Style | Enemies | Boss |
|--------|-------|-------------|---------|------|
| 1–5 | **BASTI** | Narrow alleys, corrugated roofs, open drains | Street thugs, pickpockets | *Chacha Bhatija* (uncle-nephew duo) |
| 6–10 | **BAZAAR** | Market stalls, cloth awnings, narrow lanes | Goons, extortionists, chain snatchers | *Munnabhai* (muscle + connections) |
| 11–15 | **NAKA** | Police checkpost, barricades, abandoned vehicles | Corrupt cops, smugglers, gunrunners | *Inspector Ghatak* (dirty cop) |
| 16–20 | **KOTHI** | Wealthy enclave, iron gates, guarded compounds | Bodyguards, mercenaries, gang lieutenants | *Don Sr.* (kingpin) |
| 21–25 | **COMMISSIONER** | Government offices, marble halls, secret vault | Elite guards, special forces, personal assassins | *Commissioner Saxena* (final boss) |

---

## 4. PLAYER SYSTEMS

### 4.1 STATS

| Stat | Base | Per Level | Notes |
|------|------|-----------|-------|
| HP | 100 | +15 | Max HP |
| Melee Dmg | 10 | +2 | Lathi base |
| Ranged Dmg | 15 | +3 | Pistol base |
| Speed | 3.0 | +0.1 | Tiles/sec |
| Dash Charges | 3 | +1 (at lvl 5, 10) | Cooldown: 3s per charge |
| Armour | 0 | +1 (at lvl 3, 7, 12) | Flat damage reduction |

### 4.2 DASH ROLL

- 3 charges per floor, recharged over time (3s per charge)
- I-frames during roll
- Levels up at character level 5 → 4 charges, level 10 → 5 charges

### 4.3 POLICE POWER (Ultimate)

Resource bar fills as you fight and rescue civilians.

| Power | Effect | Charge Required |
|-------|--------|----------------|
| *Whistle Charge* | Stun all enemies in room for 2s | 25% |
| *Backup Call* | Summon 2 AI constables for 10s | 50% |
| *Lathi Charge* | Massive AoE spin attack | 75% |
| *Halla Bol* | Full-screen fear, enemies flee to adjacent rooms | 100% |

---

## 5. WEAPONS

### 5.1 BASE WEAPONS

| # | Weapon | Type | Damage | Range | Speed | Special | Unlock |
|---|--------|------|--------|-------|-------|---------|--------|
| 0 | **LATHI** | Melee | 10 | 1 tile | Fast | 3-hit combo (10→12→18), stagger on 3rd hit | Default |
| 1 | **KATTA** | Ranged | 15 | 4 tiles | Slow | 6 bullets per floor, reload at stairs | Floor 2+ drop |
| 2 | **SHIELD** | Defensive | 5 (bash) | 1 tile | Medium | Block 50% frontal damage, taunt enemies | Floor 5 (Bastil boss) |
| 3 | **DANGAL** | Melee (heavy) | 25 | 1.5 tiles | Very Slow | Knockback, 2x vs armour, breaks barricades | Floor 8+ drop |
| 4 | **TRISHUL** | Melee (fast) | 8 | 1 tile | Very Fast | 5-hit combo, bleed (3 dmg/2s), stacking crit | Floor 12+ drop |
| 5 | **INSAS** | Ranged (auto) | 8 | 5 tiles | Auto | 30 bullets per floor, spread shot | Floor 15 (Naka boss) |

### 5.2 WEAPON UPGRADES

| Base | Upgrade | Effect | Found |
|------|---------|--------|-------|
| LATHI | *Bamboo Reinforced* | +5 dmg, break destructible walls | Floor 3 |
| LATHI | *Lathi Charged* | 3rd hit stuns 1.5s | Floor 7 |
| KATTA | *Silencer* | +2 tiles range, no alert sound | Floor 6 |
| KATTA | *Extended Mag* | 12 bullets per floor | Floor 10 |
| SHIELD | *Spiked Shield* | Bash does 10 + returns 30% damage | Floor 9 |
| DANGAL | *Wrestler's Grip* | +10 dmg, pull enemies toward you | Floor 14 |
| TRISHUL | *Serrated Edge* | Bleed stacks to 5, bleed ticks do 5 | Floor 16 |
| INSAS | *Underbarrel* | Every 10th shot is explosive (AoE 2 tiles) | Floor 18 |

---

## 6. ENEMIES

### 6.1 STANDARD ENEMIES (10 Types)

| # | Name | HP | Speed | Behaviour | First Seen |
|---|------|----|-------|-----------|------------|
| 0 | **Chhota Goon** | 20 | Fast | Charges straight at player, basic punch | Basti |
| 1 | **Pakoda Thief** | 15 | Very Fast | Runs around, steals gold on contact, flees | Basti |
| 2 | **Bada Goon** | 50 | Slow | Heavy punch (2x dmg), blocks occasionally | Bazaar |
| 3 | **Extortionist** | 30 | Medium | Ranged attack (throws brick), runs if low HP | Bazaar |
| 4 | **Chain Snatcher** | 25 | Fast | Dashes past player, steals weapon, disarms for 3s | Bazaar |
| 5 | **Corrupt Constable** | 40 | Medium | Same moves as player (lathi combo), radios for backup | Naka |
| 6 | **Smuggler** | 35 | Medium | Throws molotov (fire stays 3s, AoE 2 tiles) | Naka |
| 7 | **Bodyguard** | 60 | Slow | Shield charge, protects nearby enemies | Kothi |
| 8 | **Mercenary** | 45 | Fast | Katta pistol, rolls to evade | Kothi |
| 9 | **Elite Guard** | 70 | Medium | Insas rifle, grenade toss, armoured (50% reduction) | Commissioner |

### 6.2 BOSSES (5 Types)

#### Boss 1: Chacha Bhatija (Basti — Floor 5)
> An elderly goon and his hyperactive nephew. Classic duo fight.

**Phase 1 (100–60% HP):** Chacha slowly advances with a lathi, Bhatija zips around throwing firecrackers (1 dmg, 1s stun).
**Phase 2 (60–30%):** When one is hit 5 times, the other enrages — Chacha swings faster, Bhatija throws 3 firecrackers at once.
**Phase 3 (30–0%):** Both enrage. Chacha does wide sweeps, Bhatija goes full taser (melee 3s stun).
**Reward:** SHIELD weapon unlock

#### Boss 2: Munnabhai (Bazaar — Floor 10)
> Muscle-heavy gangster with a network of goons.

**Phase 1:** Munnabhai charges with a Dangal, slow but devastating. Spawns 1 Chhota Goon every 8s.
**Phase 2:** Enrages — 2x speed, spawns goons every 5s. Knocks down stalls for cover.
**Phase 3:** Throws goons at you, body-slams, ground pounds (AoE).
**Reward:** DANGAL weapon unlock, Weapon Upgrade choice

#### Boss 3: Inspector Ghatak (Naka — Floor 15)
> Dirty cop with the same arsenal as you. Mirror match.

**Phase 1:** Uses Katta + Shield. Covers behind barricades, fires from cover.
**Phase 2:** Drops shield, dual-wields Kattas. Runs and guns. Calls 1 Corrupt Constable.
**Phase 3:** Goes full INSAS rifle. Drops smoke grenades (obscures vision). Radio calls backup every 10s.
**Reward:** INSAS weapon unlock, Weapon Upgrade choice

#### Boss 4: Don Sr. (Kothi — Floor 20)
> Elegant, calculating kingpin in a penthouse office.

**Phase 1:** Doesn't fight directly. Sends waves of Bodyguards + Mercenaries while seated, sipping chai.
**Phase 2:** Stands up, uses a hidden Katta. Moves around desk for cover. Spikes in floor (avoid zones).
**Phase 3:** Personal gauntlet — removes jacket, unarmed combat (fast, precise). Throws furniture. Drops chandelier (AoE hazard).
**Reward:** Final Weapon Upgrade, max HP boost

#### Boss 5: Commissioner Saxena (Commissioner — Floor 25)
> The big one. Corrupt top cop with access to the full state arsenal.

**Phase 1:** Full INSAS + grenades. Moves slow but relentless. Bullets ricochet off walls.
**Phase 2:** Calls Elite Guards (2 at a time) while retreating to reload. Armoured vest (75% reduction).
**Phase 3:** Removes vest, injects something. Super speed. Melee + gun mix. Charges grab attack (1-hit kill if not dodged). Desperate — uses everything.
**Victory:** Game clear. Credits roll. Unlock New Game+ (harder, final "true ending" boss variant).

---

## 7. CIVILIAN RESCUE SYSTEM

### 7.1 CIVILIAN TYPES

| Type | Location | Rescue Bonus (Seva Points) | Dialogue Trigger | Unique Reward |
|------|----------|---------------------------|-----------------|---------------|
| **Chai Wala** | Room with fire/barricade | 10 SP | "Constable sahab! Yeh log mera thela leke bhage!" | Temporary speed boost for floor |
| **Newspaper Boy** | Open room with patrolling enemies | 5 SP | "Uncle! Mere papers chew doon gaye!" | Reveals 3 unexplored rooms on minimap |
| **Teacher** | Locked room, needs key | 15 SP | "Thank goodness! These goons took over our school!" | +10% XP for current floor |
| **Nurse** | Near medbay/hazard room | 12 SP | "Patients need me! Let me through!" | Heals 30 HP on rescue |
| **Auto Driver** | Blocked path (destructible wall) | 8 SP | "Saala! Mera auto bhi le liya!" | Opens shortcut to next floor (skips 2 floors, no boss) |

### 7.2 SEVA POINTS (Meta Progression)

Earned through:
- Rescue civilian: 5–15 SP
- Clear room without taking damage: 3 SP
- Defeat boss: 20 SP
- Complete floor: 2 SP
- Find hidden Warrant: 5 SP

**Spent at Police Station:**
- Permanent HP increase: 5 SP / +10 HP (max 5 upgrades)
- Starting weapon unlock: 15 SP each
- Warrant slot unlock: 10 SP (start with 2 slots, max 6)
- Dash charge upgrade: 20 SP
- New Game+ unlock: 50 SP (post-game)
- Cosmetic: different uniform colours: 3 SP each

---

## 8. WARRANT SYSTEM (Boons)

20 Warrants findable across 25 floors. Each is a meaningful upgrade chosen per-run.

| # | Name | Effect |
|---|------|--------|
| 1 | **FIR Copy** | +10% dmg vs enemies you've already hit |
| 2 | **Search Warrant** | Reveal all enemies on minimap |
| 3 | **Arrest Warrant** | Stun enemies below 20% HP automatically |
| 4 | **Beat Book** | All attacks 5% chance to deal 3x damage |
| 5 | **Handcuffs** | 3rd melee hit roots enemy for 1.5s |
| 6 | **Walkie-Talkie** | Enemies within 3 tiles of each other share damage |
| 7 | **Torch** | +1 tile vision radius (dark floors) |
| 8 | **First Aid Kit** | Heal 5 HP per cleared room |
| 9 | **Chai Thermos** | Every 60s, heal 10 HP |
| 10 | **Notebook** | Enemies have 50% less accuracy for 2s after hit |
| 11 | **Whistle** | +1 Police Power charge on killing an enemy |
| 12 | **Lathi Permit** | Lathi combo hits have 20% larger hitbox |
| 13 | **ID Card** | Bribe? 30% chance to skip 1 fight per floor |
| 14 | **Map of Tunnels** | Reveal stairs location on floor start |
| 15 | **Ration Pack** | +20 max HP (one-time per run) |
| 16 | **Old Case File** | 10% chance to deal bonus 15 dmg (justice proc) |
| 17 | **Evidence Bag** | +1 gold per enemy killed |
| 18 | **Constable's Cap** | Taunt enemies within 4 tiles to target you (not civilians) |
| 19 | **Squad Photo** | +5% dmg per civilian rescued this run (max +50%) |
| 20 | **Commissioner's Seal** | Once per floor: survive lethal hit with 1 HP + 2s invulnerability |

---

## 9. HUB: POLICE STATION

Between runs, the player returns to the Police Station.

**Rooms:**
1. **Duty Room** — Select floor range to descend (1–5, 6–10, etc.) or start fresh
2. **Armoury** — Unlock/upgrade weapons using Seva Points
3. **Warrant Board** — View collected Warrants, equip up to slot limit
4. **Records Room** — Run history, stats, achievements
5. **Diary** — Story entry unlocked per boss defeated
6. **Canteen** — Talk to rescued civilians (flavour dialogue, worldbuilding)

**NPCs in Station:**
- *Senior Inspector* — Gives mission briefings, assigns floor target
- *Head Constable* — Runs training room (tutorial)
- *Mamta Didi (Canteen)* — Serves chai, dispenses rumours about next district

---

## 10. STORY FRAMEWORK

### Central Premise
You are Constable Arjun Rathore, posted to the Sadarpur police station. The city is in the grip of a silent takeover — from the streets to the Commissioner's office. Each boss you defeat reveals another layer of the conspiracy.

### Story Beat Progression

| Milestone | Unlock | Summary |
|-----------|--------|---------|
| Defeat Chacha Bhatija | Diary entry: "Basti Nights" | These small-time goons were paid in new notes — from where? |
| Defeat Munnabhai | Diary entry: "Market Rates" | The protection money trail leads to the Naka checkpost |
| Defeat Inspector Ghatak | Diary entry: "Blue Shield" | Your own department is compromised. Who's above Ghatak? |
| Defeat Don Sr. | Diary entry: "Silk Route" | The Don answers to someone in government. A "Saxena" keeps appearing in ledgers |
| Defeat Commissioner Saxena | Diary entry: "The Sentence" | The Commissioner was building a private police force. His files implicate politicians, businessmen, and... your own Senior Inspector |
| New Game+ | Diary entry: "Appeal" | New evidence suggests Saxena was a patsy. The real mastermind is still out there. New dialogue, harder enemies, true ending. |

---

## 11. AUDIO

### Music
| Layer | Style | Inspiration |
|-------|-------|-------------|
| Floor 1–5 (Basti) | Dhol + tabla, street energy | Garba/folk percussion |
| Floor 6–10 (Bazaar) | Shehnai + harmonium, marketplace chaos | Bollywood market scene |
| Floor 11–15 (Naka) | Distorted guitar + police siren drone | Gritty noir |
| Floor 16–20 (Kothi) | Veena + silent tension | Lounge/crime thriller |
| Floor 21–25 (Comm.) | Orchestra + chanting drums | Final boss epic |
| Hub (Station) | Sitar, relaxed, diurnal | Slice of life |
| Boss theme | Percussion builds, traditional alaap transitions into heavy rock | Rages against corruption |

### SFX
- Lathi swoosh (fast whoosh, pitch varies per combo hit)
- Katta bang (sharp crack, echoes in rooms)
- Dash roll (cloth rustle + slight whoosh)
- Civilian rescue (sigh of relief + "Thank you, constable!")
- Pickup/item (metal cling or paper rustle)
- Enemy hit (varied: thud for melee, crack for gun)
- Stairs (stone grinding sound)
- Warrant pickup (stamp sound + "Approved!")
- Death (fade out, heart flatline)

---

## 12. CONTENT ROADMAP

### Phase 1 — Foundation (Weeks 1–2)
- Dev environment, Godot project structure
- Player controller (movement, dash, 3-step lathi combo)
- BSP dungeon generation (25 floors)
- Enemy AI (patrol, chase, attack, stun — 8 types coded)
- Tilemap rendering with 5 themed atlases
- Room-to-room camera transitions
- HUD (HP bar, floor counter, weapon label, gold)
- Touch input (MobileUI)
- **Status:** ✅ Done

### Phase A — Polish (Week 3)
- Particles: dash dust, hit sparks, footstep puffs
- Screen shake on damage/heavy hits
- Damage numbers
- Minimap overlay
- Stair interaction (E key)
- Procedural wall/floor tile variation
- **Status:** 🟡 Built partially

### Phase 2 — Content (Weeks 4–6)
- 6 weapons fully implemented (Lathi, Katta, Shield, Dangal, Trishul, Insas)
- 5 weapon upgrades
- 10 enemy types with distinct behaviours
- 5 civilians (rescue mechanics)
- 5 bosses with 3-phase patterns
- Warrant system (20 warrants)
- Damage numbers polish

### Phase 3 — Meta (Week 7–8)
- Police Station hub scene
- Seva Points meta progression
- Weapon unlock/unlock screen
- Story diary system
- Run history/stats screen

### Phase 4 — Polish & Launch (Weeks 9–10)
- Full pixel art sprites (replacing programmer art)
- Animations (walk cycles, attack frames, death)
- SFX pack
- Music composition (5 floor themes, boss theme, hub)
- Mobile optimization
- Android build test

---

## 13. TECHNICAL SPECIFICATIONS

| Aspect | Detail |
|--------|--------|
| Engine | Godot 4.6.2 |
| Rendering | Forward+ (compatibility for mobile) |
| Resolution | 640×640 game, scalable UI |
| Tile Size | 24×24 px (scaled from 32×32 source) |
| Input | Touch (mobile) |
| Platforms | Android, iOS |
| Door System | Instant transitions between rooms |
| Save System | ConfigFile-based run persistence |
| Procedural Gen | BSP dungeon, seed-based |
| Font | Indian-friendly: Noto Sans Devanagari (or custom) |

### Optimization Targets
- 30 FPS on mid-range Android (2019+, 4GB RAM)
- APK < 50MB (excluding optional HD asset pack)
- Load time < 3s

---

## 14. MONETIZATION & MARKETING

### Model: Free + IAA (In-App Advertising) — with optional IAP

**Primary Revenue:** Rewarded video ads + interstitials at natural game breakpoints.

**Why IAA over premium for mobile:**
- Indian mobile market is conditioned for free — 95%+ of installs come from free games
- Roguelike loop has perfect ad insertion points (death, between floors, run end)
- Free download = 10-50x more installs vs premium in India
- Lower eCPM ($0.50–$2.00 India) is offset by volume
- Ad mechanics (revive, bonus, boost) feel native to roguelikes — not tacked-on

### Ad Touchpoints

| Touchpoint | Ad Type | Player Incentive | Placement |
|------------|---------|-----------------|-----------|
| On Death | Rewarded Video | Revive and continue run (once per floor) | Death screen, "Watch to Continue?" |
| Floor Transition | Interstitial | None (forced, 5s skippable) | Between floors, during loading |
| Run End | Rewarded Video | 2x Seva Points earned this run | Run summary screen |
| Floor Start | Rewarded Video | Free random Warrant for this floor | Floor start prompt |
| Police Station Hub | Banner | None | Bottom strip, non-intrusive |

### Optional IAP (for ad-free + support)

| Item | Price | Effect |
|------|-------|--------|
| Remove Ads | ₹149 one-time | Removes all interstitials + banners, rewarded ads become optional |
| Constable Pack | ₹99 | 3 exclusive uniform colours, "donation" badge on profile |
| Supporter Badge | ₹49 | Name in credits + small icon next to name in leaderboards |

### Marketing Angles

1. **"First Indian police roguelike"** — PR hook, gaming press India
2. **Cultural authenticity** — Real Indian weapons, real locations
3. **Hindi/regional language support** — Hindi, Tamil, Telugu, Bengali, Marathi
4. **Google Play featuring** — Free game with Indian theme = Play Store editorial potential
5. **Influencer outreach** — Indian gaming YouTubers (Triggered Insaan, Techno Gamerz, carryminati-style) for gameplay videos
6. **Play Pass** — If free-to-play IAA hits traction, Play Pass inclusion adds another revenue stream

### Budget Breakdown (₹)

| Item | Cost (₹) |
|------|----------|
| SFX pack (royalty-free) | 2,000 |
| Music composer (freelance) | 15,000–25,000 |
| Pixel artist (sprite work) | 20,000–40,000 |
| Playtester honorarium (10 testers) | 5,000 |
| Marketing (influencer + social) | 10,000–20,000 |
| Miscellaneous (fonts, licenses) | 2,000 |
| **Total** | **₹54,000 – ₹94,000** |

---

## 15. APPENDIX: KEY DESIGN DECISIONS

| Decision | Why |
|----------|-----|
| Real-time not turn-based | Better mobile feel, more action-oriented, competitive with Hades-like market |
| 25 floors not infinite | Finite run = satisfying closure, easier to balance, traditional roguelike structure |
| 5 themes not 1 | Progression feel, visual variety, storytelling device |
| Seva Points not gold | Diegetic to police theme, emotionally resonant (service vs wealth) |
| No permadeath of upgrades | Hades-style meta progression keeps玩家 motivated through failure |
| Mobile-only | India is mobile-dominant (95% of gamers). No desktop/Steam. |
| Warrant naming | Police terminology grounds the theme. "Warrant" > "Boon" or "Relic" |
| Hindi words throughout | Authenticity + educational value. Non-Hindi speakers learn through context |

---

*Document prepared May 2026. Subject to revision.*
