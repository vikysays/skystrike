import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 1100
    height: 740
    minimumWidth: 840
    minimumHeight: 600
    visible: true
    title: qsTr("Sky Strike")
    color: "#090d16"

    Material.theme: Material.Dark
    Material.accent: theme.accent
    Material.roundedScale: theme.radius

    property bool helpVisible: false

    Shortcut { sequence: "?"; context: Qt.ApplicationShortcut; onActivated: win.helpVisible = !win.helpVisible }
    Shortcut { sequence: "Q"; context: Qt.ApplicationShortcut; onActivated: Qt.quit() }
    Shortcut { sequence: "Space"; context: Qt.ApplicationShortcut; onActivated: root.fireAllOrdnance() }
    Shortcut { sequence: "B"; context: Qt.ApplicationShortcut; onActivated: root.dropCarpetBombs() }
    Shortcut { sequence: "P"; context: Qt.ApplicationShortcut; onActivated: backend.togglePause() }
    Shortcut { sequence: "1"; context: Qt.ApplicationShortcut; onActivated: backend.selectLevel(1) }
    Shortcut { sequence: "2"; context: Qt.ApplicationShortcut; onActivated: backend.selectLevel(2) }
    Shortcut { sequence: "3"; context: Qt.ApplicationShortcut; onActivated: backend.selectLevel(3) }

    Connections {
        target: backend
        function onFireTriggerChanged() {
            root.fireAllOrdnance();
        }
        function onResetTriggerChanged() {
            root.setupLevel(backend.level);
        }
    }

    Item {
        id: root
        anchors.fill: parent
        LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
        LayoutMirroring.childrenInherit: true

        // --- PLAYER B-2 SPIRIT STATE ---
        property real playerX: 220
        property real playerY: 270
        property real targetX: 220
        property real targetY: 270
        property real playerTilt: 0
        property real playerBank: 0
        property int bombBayOpenTicks: 0
        property int invulnerableTicks: 0
        property real shakeIntensity: 0
        property real seaTime: 0
        property int levelBannerTicks: 150

        // --- BOSS AEROPLANE STATE (LEVELS 1, 2, 3) ---
        property real bossX: win.width - 230
        property real bossY: 170
        property real bossVx: -1.1
        property real bossVy: 0.6
        property real bossHealth: 360
        property real bossMaxHealth: 360
        property bool bossHangarOpen: false
        property bool bossEnraged: false
        property int bossSpawnTimer: 0
        property int bossFireTimer: 0
        property bool bossActive: true
        property bool bossShieldActive: false
        property int levelTransitionTicks: 0
        property int autoCannonTimer: 0
        property int lightningFlashTicks: 0

        // --- DYNAMIC ENTITIES ---
        property var smallPlanes: []
        property var warships: []
        property var paratroopers: []
        property var missiles: []
        property var bombs: []
        property var cannonBolts: []
        property var laserBeams: []
        property var bossBullets: []
        property var particles: []
        property var shockwaves: []
        property var splashes: []
        property var floatingTexts: []
        property var clouds: []

        readonly property real seaLevel: win.height - 105

        // Substantial multi-phase boss endurance so each level is a proper boss battle
        function bossMaxHpForLevel(lvl) {
            if (lvl === 1) return 380;
            if (lvl === 2) return 720;
            return 1150;
        }

        function setupLevel(lvl) {
            bossActive = true;
            bossX = win.width - 230;
            bossY = 170;
            bossVx = -(1.0 + lvl * 0.25);
            bossVy = 0.6 + lvl * 0.25;
            bossMaxHealth = bossMaxHpForLevel(lvl);
            bossHealth = bossMaxHealth;
            bossHangarOpen = false;
            bossEnraged = false;
            bossSpawnTimer = 0;
            bossFireTimer = 0;
            bossShieldActive = false;
            levelTransitionTicks = 0;
            levelBannerTicks = 190;
            bossBullets = [];
            cannonBolts = [];
            laserBeams = [];

            // Enemy warships on the sea scaled by level complexity
            warships = [];
            spawnWarship(340, "destroyer");
            spawnWarship(640, "carrier");
            spawnWarship(940, "cruiser");
            if (lvl >= 2)
                spawnWarship(500, "cruiser");
            if (lvl >= 3)
                spawnWarship(800, "carrier");

            // Enemy fighter squadron scaled by level complexity
            smallPlanes = [];
            spawnSmallPlane(580, 270);
            spawnSmallPlane(760, 230);
            spawnSmallPlane(880, 320);
            if (lvl >= 2)
                spawnSmallPlane(670, 195);
            if (lvl >= 3) {
                spawnSmallPlane(720, 360);
                spawnSmallPlane(940, 250);
            }
            spawnParatrooper(520, 240);
        }

        function initEnvironment() {
            clouds = [
                { x: 120, y: 115, s: 1.1, speed: 0.45, dark: true },
                { x: 460, y: 175, s: 0.9, speed: 0.35, dark: false },
                { x: 780, y: 105, s: 1.3, speed: 0.55, dark: true },
                { x: 1080, y: 150, s: 1.0, speed: 0.40, dark: false }
            ];
            setupLevel(backend.level);
        }

        Component.onCompleted: {
            initEnvironment();
        }

        function spawnWarship(startX, type) {
            var isCarrier = (type === "carrier");
            var isCruiser = (type === "cruiser");
            warships.push({
                x: startX,
                y: root.seaLevel,
                vx: -(0.55 + Math.random() * 0.45),
                type: type || (Math.random() > 0.6 ? "carrier" : (Math.random() > 0.5 ? "cruiser" : "destroyer")),
                w: isCarrier ? 190 : (isCruiser ? 150 : 125),
                h: isCarrier ? 44 : (isCruiser ? 38 : 32),
                hp: isCarrier ? 6 : (isCruiser ? 4 : 3),
                maxHp: isCarrier ? 6 : (isCruiser ? 4 : 3),
                sinking: false,
                sinkDepth: 0,
                sinkAngle: 0,
                aaTimer: Math.floor(Math.random() * 100)
            });
        }

        function spawnSmallPlane(originX, originY) {
            smallPlanes.push({
                x: originX,
                y: originY,
                vx: -(2.8 + Math.random() * 2.0),
                vy: (Math.random() - 0.5) * 1.6,
                timer: Math.random() * 6.28
            });
        }

        function spawnParatrooper(originX, originY) {
            paratroopers.push({
                x: originX,
                y: originY,
                vy: 0.85 + Math.random() * 0.45,
                sway: Math.random() * 6.28,
                color: ["#e0af68", "#9ece6a", "#7aa2f7", "#f7768e", "#ff9e64"][Math.floor(Math.random() * 5)]
            });
        }

        // Dramatic multi-stage explosion with shockwave ring, white-hot flash, fireballs, dark smoke, and screen shake
        function spawnDramaticExplosion(x, y, scale, isNaval) {
            root.shakeIntensity = Math.min(22, root.shakeIntensity + 7 * scale);

            // Supersonic shockwave ring
            shockwaves.push({
                x: x,
                y: y,
                radius: 6,
                maxRadius: 65 * scale,
                alpha: 0.95,
                width: 4.5 * scale,
                color: isNaval ? "#ffd60a" : "#ffffff"
            });

            // Secondary outer blast wave for huge explosions
            if (scale >= 1.4) {
                shockwaves.push({
                    x: x,
                    y: y,
                    radius: 2,
                    maxRadius: 95 * scale,
                    alpha: 0.75,
                    width: 2.5 * scale,
                    color: "#ff9e64"
                });
            }

            // White-hot core flash
            particles.push({
                x: x,
                y: y,
                vx: 0,
                vy: 0,
                life: 1.0,
                decay: 0.12,
                color: "#ffffff",
                size: 28 * scale,
                smoke: false
            });

            // Rolling fireballs & dark war smoke
            var count = Math.floor(26 * scale);
            for (var i = 0; i < count; ++i) {
                var spd = (1.5 + Math.random() * 4.5) * scale;
                var ang = Math.random() * 6.283;
                var isSmoke = (i % 3 === 0);
                particles.push({
                    x: x + (Math.random() - 0.5) * 12 * scale,
                    y: y + (Math.random() - 0.5) * 12 * scale,
                    vx: Math.cos(ang) * (isSmoke ? spd * 0.55 : spd),
                    vy: Math.sin(ang) * (isSmoke ? spd * 0.55 : spd) - (isSmoke ? 0.6 : 0),
                    life: 1.0,
                    decay: isSmoke ? (0.015 + Math.random() * 0.015) : (0.028 + Math.random() * 0.03),
                    color: isSmoke ? "#262b36" : ["#ffd60a", "#ff9e64", "#ff4d4d", "#f7768e"][Math.floor(Math.random() * 4)],
                    size: (isSmoke ? 12 : 7) * scale * (0.6 + Math.random() * 0.7),
                    smoke: isSmoke
                });
            }

            if (isNaval) {
                spawnWaterSplash(x, root.seaLevel, 1.5 * scale);
            }
        }

        function spawnWaterSplash(x, y, scale) {
            var drops = Math.floor(18 * scale);
            for (var i = 0; i < drops; ++i) {
                splashes.push({
                    x: x + (Math.random() - 0.5) * 24 * scale,
                    y: y,
                    vx: (Math.random() - 0.5) * 3.5 * scale,
                    vy: -(3.5 + Math.random() * 5.5) * scale,
                    life: 1.0,
                    size: (3 + Math.random() * 4.5) * scale
                });
            }
        }

        function addFloatingText(text, x, y, color) {
            floatingTexts.push({
                text: text,
                x: x,
                y: y,
                vy: -1.4,
                alpha: 1.0,
                color: color || theme.accent
            });
        }

        // Fires incremental B-2 Spirit offensive capabilities scaled by Level / Weapon Tier (1, 2, 3)!
        function fireAllOrdnance() {
            if (backend.paused || backend.victory) return;
            root.bombBayOpenTicks = 24;
            var tier = backend.weaponTier;

            if (tier === 1) {
                // LEVEL 1 (TIER 1): 1 Heavy Cruise Missile + Nose Rotary Gatling Burst + 1 Heavy Gravity Bomb
                missiles.push({
                    x: playerX + 26, y: playerY + 4,
                    vx: 5.8, ax: 0.35, vy: 0,
                    homing: false, dmg: 15, life: 145
                });
                cannonBolts.push({
                    x: playerX + 50, y: playerY,
                    vx: 14.5, vy: 0, dmg: 4, color: "#ffd60a", life: 75
                });
                bombs.push({
                    x: playerX - 4, y: playerY + 14,
                    vx: 2.2, vy: 1.8, gravity: 0.22, angle: 0.4, dmg: 2, life: 200
                });
            } else if (tier === 2) {
                // LEVEL 2 (TIER 2): Twin Supersonic Homing Missiles + Twin Wing Rotary Autocannons + Dual Cluster Bombs
                missiles.push({
                    x: playerX + 24, y: playerY - 12,
                    vx: 6.5, ax: 0.40, vy: -0.35,
                    homing: true, dmg: 16, life: 150
                });
                missiles.push({
                    x: playerX + 24, y: playerY + 14,
                    vx: 6.5, ax: 0.40, vy: 0.35,
                    homing: true, dmg: 16, life: 150
                });
                cannonBolts.push({
                    x: playerX + 12, y: playerY - 42,
                    vx: 15.5, vy: -0.25, dmg: 5, color: "#7dcfff", life: 80
                });
                cannonBolts.push({
                    x: playerX + 12, y: playerY + 42,
                    vx: 15.5, vy: 0.25, dmg: 5, color: "#7dcfff", life: 80
                });
                bombs.push({
                    x: playerX - 8, y: playerY + 14,
                    vx: 1.8, vy: 1.6, gravity: 0.23, angle: 0.4, dmg: 2, life: 200
                });
                bombs.push({
                    x: playerX + 8, y: playerY + 16,
                    vx: 2.7, vy: 1.9, gravity: 0.23, angle: 0.4, dmg: 2, life: 200
                });
            } else {
                // LEVEL 3 (TIER 3): Triple Homing Missiles + Plasma Nose Laser Beam + Twin Wingman Stealth Drones + 3 Mega Bombs!
                for (var mIdx = -1; mIdx <= 1; ++mIdx) {
                    missiles.push({
                        x: playerX + 26, y: playerY + mIdx * 13,
                        vx: 7.2, ax: 0.45, vy: mIdx * 0.9,
                        homing: true, dmg: 18, life: 160
                    });
                }
                // Wingman Drone Plasma Bolts
                var droneOffset = Math.sin(root.seaTime * 2.2) * 8;
                cannonBolts.push({
                    x: playerX - 18, y: playerY - 74 + droneOffset,
                    vx: 16.5, vy: 0, dmg: 7, color: "#bb9af7", life: 85
                });
                cannonBolts.push({
                    x: playerX - 18, y: playerY + 74 - droneOffset,
                    vx: 16.5, vy: 0, dmg: 7, color: "#bb9af7", life: 85
                });
                for (var bIdx = 0; bIdx < 3; ++bIdx) {
                    bombs.push({
                        x: playerX - 12 + bIdx * 12, y: playerY + 14 + bIdx * 3,
                        vx: 1.7 + bIdx * 0.65, vy: 1.6 + bIdx * 0.3, gravity: 0.24, angle: 0.4, dmg: 3, life: 210
                    });
                }
                // High-energy nose plasma laser pulse that strikes targets ahead!
                var beamEndX = win.width;
                if (root.bossActive && Math.abs(root.bossY - root.playerY) < 62 && root.bossX > root.playerX) {
                    beamEndX = root.bossX - 30;
                    var laserDmg = root.bossShieldActive ? 5 : 14;
                    root.bossHealth -= laserDmg;
                    root.spawnDramaticExplosion(beamEndX, root.playerY, 0.9, false);
                    root.checkBossDefeated();
                }
                laserBeams.push({
                    x1: playerX + 46, y1: playerY,
                    x2: beamEndX, y2: playerY,
                    alpha: 1.0
                });
            }

            // Launch flash particles under bomb bay
            for (var i = 0; i < 6 + tier * 2; ++i) {
                particles.push({
                    x: playerX + 12,
                    y: playerY + 8,
                    vx: -(2 + Math.random() * 3),
                    vy: (Math.random() - 0.5) * 2.5,
                    life: 0.9,
                    decay: 0.08,
                    color: tier === 3 ? "#7dcfff" : "#ffd60a",
                    size: 5,
                    smoke: false
                });
            }
        }

        // Drops a dramatic carpet bombing salvo scaled by Weapon Tier (4 / 6 / 8 bombs)
        function dropCarpetBombs() {
            if (backend.paused || backend.victory) return;
            root.bombBayOpenTicks = 42;
            var tier = backend.weaponTier;
            var count = 2 + tier * 2; // Level 1: 4 bombs, Level 2: 6 bombs, Level 3: 8 bombs
            for (var b = 0; b < count; ++b) {
                bombs.push({
                    x: playerX - 18 + b * 10,
                    y: playerY + 14 + b * 3,
                    vx: 1.4 + b * 0.42,
                    vy: 1.4 + b * 0.32,
                    gravity: 0.22,
                    angle: 0.4,
                    dmg: tier >= 3 ? 3 : 2,
                    life: 220
                });
            }
            addFloatingText(tier >= 3 ? "MEGA CARPET SALVO!" : "BOMBS AWAY!", playerX, playerY - 30, "#ff9e64");
        }

        function checkBossDefeated() {
            if (!root.bossActive || root.bossHealth > 0)
                return;
            root.bossActive = false;
            root.bossBullets = [];
            var completedLevel = backend.level;
            root.spawnDramaticExplosion(root.bossX, root.bossY, 2.6, false);
            root.spawnDramaticExplosion(root.bossX - 60, root.bossY + 14, 1.9, false);
            root.spawnDramaticExplosion(root.bossX + 60, root.bossY - 14, 1.9, false);
            root.spawnDramaticExplosion(root.bossX, root.bossY - 35, 1.7, false);

            backend.recordMothershipDefeated();

            if (completedLevel < backend.maxLevels) {
                root.addFloatingText("LEVEL " + completedLevel + " BOSS DEFEATED! 💥", root.bossX - 80, root.bossY, "#9ece6a");
                root.levelTransitionTicks = 110;
            } else {
                root.addFloatingText("SKY TITAN OBLITERATED! 🏆 VICTORY!", root.bossX - 110, root.bossY, "#ffd60a");
            }
        }

        function fireBossSpread(lvl) {
            var count = (lvl === 1) ? 1 : (lvl === 2 ? 3 : 5);
            for (var i = 0; i < count; ++i) {
                var offsetAngle = (i - (count - 1) * 0.5) * 0.22;
                var aimAngle = Math.atan2(root.playerY - root.bossY, root.playerX - root.bossX) + offsetAngle;
                var speed = 4.2 + lvl * 0.65;
                root.bossBullets.push({
                    x: root.bossX - 75,
                    y: root.bossY + (i - (count - 1) * 0.5) * 10,
                    vx: Math.cos(aimAngle) * speed,
                    vy: Math.sin(aimAngle) * speed,
                    color: lvl === 3 ? "#bb9af7" : (lvl === 2 ? "#ff9e64" : "#ff4d4d"),
                    radius: lvl === 3 ? 6.5 : 5.5
                });
            }
        }

        // --- MAIN 60FPS GAME LOOP ---
        Timer {
            id: gameLoop
            interval: 16
            running: !backend.paused
            repeat: true
            onTriggered: {
                root.seaTime += 0.045;
                if (root.shakeIntensity > 0.2)
                    root.shakeIntensity *= 0.86;
                else
                    root.shakeIntensity = 0;

                if (root.bombBayOpenTicks > 0)
                    root.bombBayOpenTicks--;
                if (root.invulnerableTicks > 0)
                    root.invulnerableTicks--;
                if (root.levelBannerTicks > 0)
                    root.levelBannerTicks--;
                if (root.lightningFlashTicks > 0)
                    root.lightningFlashTicks--;

                // Continuous automatic nose/wing/drone gunfire so the B-2 Spirit feels progressively deadlier each level!
                root.autoCannonTimer++;
                var pTierLoop = backend.weaponTier;
                var autoInterval = (pTierLoop === 1) ? 28 : (pTierLoop === 2 ? 20 : 15);
                if (!backend.victory && root.autoCannonTimer % autoInterval === 0) {
                    if (pTierLoop === 1) {
                        root.cannonBolts.push({
                            x: root.playerX + 50, y: root.playerY,
                            vx: 14.0, vy: 0, dmg: 3, color: "#ffd60a", life: 70
                        });
                    } else if (pTierLoop === 2) {
                        root.cannonBolts.push({
                            x: root.playerX + 12, y: root.playerY - 42,
                            vx: 15.0, vy: -0.15, dmg: 4, color: "#7dcfff", life: 75
                        });
                        root.cannonBolts.push({
                            x: root.playerX + 12, y: root.playerY + 42,
                            vx: 15.0, vy: 0.15, dmg: 4, color: "#7dcfff", life: 75
                        });
                    } else {
                        var dOff = Math.sin(root.seaTime * 2.2) * 8;
                        root.cannonBolts.push({
                            x: root.playerX + 50, y: root.playerY,
                            vx: 16.0, vy: 0, dmg: 5, color: "#ffd60a", life: 80
                        });
                        root.cannonBolts.push({
                            x: root.playerX - 18, y: root.playerY - 74 + dOff,
                            vx: 16.0, vy: -0.1, dmg: 5, color: "#bb9af7", life: 80
                        });
                        root.cannonBolts.push({
                            x: root.playerX - 18, y: root.playerY + 74 - dOff,
                            vx: 16.0, vy: 0.1, dmg: 5, color: "#bb9af7", life: 80
                        });
                    }
                }

                // 1. B-2 Spirit smooth flight clamped between HUD and sea level
                var clampedTargetX = Math.max(65, Math.min(win.width - 65, root.targetX));
                var clampedTargetY = Math.max(110, Math.min(root.targetY, root.seaLevel - 75));
                var dx = clampedTargetX - root.playerX;
                var dy = clampedTargetY - root.playerY;
                root.playerX += dx * 0.14;
                root.playerY += dy * 0.14;
                root.playerTilt = Math.max(-0.32, Math.min(0.32, dy * 0.015));
                root.playerBank = Math.max(-0.25, Math.min(0.25, dx * 0.01));

                // 2. Clouds scroll
                for (var cli = 0; cli < root.clouds.length; ++cli) {
                    root.clouds[cli].x -= root.clouds[cli].speed;
                    if (root.clouds[cli].x < -220)
                        root.clouds[cli].x = win.width + 80;
                }

                // 3. Multi-Phase Boss Aeroplane logic across 3 complexity levels
                var lvl = backend.level;
                if (root.bossActive) {
                    // Check Phase 2 Enraged Overdrive below 50% HP!
                    if (!root.bossEnraged && root.bossHealth <= root.bossMaxHealth * 0.5) {
                        root.bossEnraged = true;
                        root.spawnDramaticExplosion(root.bossX, root.bossY, 1.8, false);
                        root.addFloatingText("⚠️ BOSS ENRAGED! PHASE 2 OVERDRIVE!", root.bossX - 110, root.bossY - 50, "#ff4d4d");
                        backend.setStatusMessage("PHASE 2: " + backend.bossName.toUpperCase() + " ENRAGED!");
                    }

                    // Damaged boss emits heavy war smoke and sparks in Phase 2
                    if (root.bossEnraged && Math.random() < 0.45) {
                        root.particles.push({
                            x: root.bossX + (Math.random() - 0.5) * 90,
                            y: root.bossY + (Math.random() - 0.5) * 30,
                            vx: -1.2,
                            vy: -(0.8 + Math.random() * 1.4),
                            life: 0.9,
                            decay: 0.025,
                            color: (Math.random() > 0.35) ? "#222630" : "#ff4d4d",
                            size: 8 + Math.random() * 6,
                            smoke: true
                        });
                    }

                    var rageMult = root.bossEnraged ? 1.35 : 1.0;
                    root.bossX += root.bossVx * rageMult;
                    if (lvl === 1) {
                        // Level 1 Boss: Iron Vulture Bomber (Coral Sea patrol)
                        root.bossY = 170 + Math.sin(root.seaTime * 0.75 * rageMult) * (root.bossEnraged ? 55 : 28);
                    } else if (lvl === 2) {
                        // Level 2 Boss: Storm Valkyrie Gunship (Arctic swooping flight + tactical shield in Phase 2)
                        root.bossY = 215 + Math.sin(root.seaTime * 1.15 * rageMult) * 95;
                        root.bossShieldActive = root.bossEnraged && (Math.floor(root.seaTime * 1.1) % 5 === 4);
                    } else {
                        // Level 3 Boss: Sky Titan Dreadnought (Volcanic Red Sea aerial dominance + energy shield pulses)
                        root.bossY = 235 + Math.sin(root.seaTime * 1.35 * rageMult) * 115;
                        root.bossShieldActive = (Math.floor(root.seaTime * 1.25) % 4 === 3);
                        if (Math.random() < 0.008)
                            root.lightningFlashTicks = 8;
                    }

                    var minBossX = (lvl === 3) ? win.width * 0.42 : win.width * 0.48;
                    var spdX = 0.85 + lvl * 0.35;
                    if (root.bossX < minBossX && root.bossVx < 0)
                        root.bossVx = spdX;
                    else if (root.bossX > win.width - 165 && root.bossVx > 0)
                        root.bossVx = -spdX;

                    // Boss launches fighter escorts & paratroopers
                    root.bossSpawnTimer++;
                    var spawnInterval = Math.max(38, (root.bossEnraged ? 72 : 95) - lvl * 14);
                    if (root.bossSpawnTimer % spawnInterval === 0) {
                        root.bossHangarOpen = true;
                        root.spawnSmallPlane(root.bossX - 24, root.bossY + 24);
                        if (lvl >= 2 || root.bossEnraged)
                            root.spawnSmallPlane(root.bossX - 10, root.bossY - 22);
                        if (Math.random() > 0.30) {
                            root.spawnParatrooper(root.bossX + 25, root.bossY + 28);
                            if (lvl >= 2)
                                root.spawnParatrooper(root.bossX + 52, root.bossY + 28);
                        }
                    } else if (root.bossSpawnTimer % spawnInterval === 28) {
                        root.bossHangarOpen = false;
                    }

                    // Boss fires aerial plasma/cannon spreads based on level complexity & Phase 2 rage
                    root.bossFireTimer++;
                    var baseFire = (lvl === 1) ? 90 : (lvl === 2 ? 68 : 50);
                    var fireInterval = root.bossEnraged ? Math.floor(baseFire * 0.72) : baseFire;
                    if (root.bossFireTimer % fireInterval === 0) {
                        root.fireBossSpread(lvl);
                    }
                } else if (!backend.victory) {
                    // Transition countdown to spawn the newly unlocked Level Boss Aeroplane!
                    if (root.levelTransitionTicks > 0) {
                        root.levelTransitionTicks--;
                        if (root.levelTransitionTicks === 0) {
                            root.setupLevel(backend.level);
                        }
                    }
                }

                // 3a. Player Autocannon / Wingman Drone Bolts update & hit checks
                var nextBolts = [];
                for (var cbi = 0; cbi < root.cannonBolts.length; ++cbi) {
                    var cb = root.cannonBolts[cbi];
                    cb.x += cb.vx;
                    cb.y += cb.vy;
                    cb.life--;
                    var boltHit = false;

                    for (var cpi = 0; cpi < root.smallPlanes.length; ++cpi) {
                        var cpl = root.smallPlanes[cpi];
                        if (Math.hypot(cb.x - cpl.x, cb.y - cpl.y) < 24) {
                            root.spawnDramaticExplosion(cpl.x, cpl.y, 1.0, false);
                            backend.recordPlaneDestroyed();
                            root.addFloatingText("GUN KILL! +150", cpl.x, cpl.y - 12, cb.color);
                            root.smallPlanes.splice(cpi, 1);
                            boltHit = true;
                            break;
                        }
                    }

                    if (!boltHit && root.bossActive) {
                        if (cb.x > root.bossX - 95 && cb.x < root.bossX + 95 &&
                            cb.y > root.bossY - 42 && cb.y < root.bossY + 42) {
                            var bDmg = root.bossShieldActive ? Math.ceil(cb.dmg * 0.4) : cb.dmg;
                            root.bossHealth -= bDmg;
                            root.particles.push({
                                x: cb.x, y: cb.y,
                                vx: -2, vy: (Math.random() - 0.5) * 3,
                                life: 0.7, decay: 0.08, color: cb.color, size: 4.5, smoke: false
                            });
                            backend.addScore(25);
                            boltHit = true;
                            root.checkBossDefeated();
                        }
                    }

                    if (!boltHit && cb.x < win.width + 40 && cb.life > 0)
                        nextBolts.push(cb);
                }
                root.cannonBolts = nextBolts;

                // 3b. Boss Aeroplane cannon/plasma projectiles update
                var nextBossBullets = [];
                for (var bbi = 0; bbi < root.bossBullets.length; ++bbi) {
                    var bb = root.bossBullets[bbi];
                    bb.x += bb.vx;
                    bb.y += bb.vy;
                    var distPlayer = Math.hypot(bb.x - root.playerX, bb.y - root.playerY);
                    if (distPlayer < 38) {
                        // Kid-friendly energy shield deflects boss shots with sparks!
                        root.invulnerableTicks = 35;
                        root.shakeIntensity = Math.min(12, root.shakeIntensity + 4);
                        root.addFloatingText("SHIELD DEFLECT!", root.playerX - 20, root.playerY - 35, "#7dcfff");
                        for (var spk = 0; spk < 8; ++spk) {
                            var spAng = Math.random() * 6.28;
                            root.particles.push({
                                x: bb.x, y: bb.y,
                                vx: Math.cos(spAng) * 3.2, vy: Math.sin(spAng) * 3.2,
                                life: 0.8, decay: 0.06, color: "#7dcfff", size: 4, smoke: false
                            });
                        }
                        continue;
                    }
                    if (bb.x > -40 && bb.x < win.width + 40 && bb.y > 40 && bb.y < root.seaLevel)
                        nextBossBullets.push(bb);
                }
                root.bossBullets = nextBossBullets;

                // 3c. Player Level 3 Plasma Nose Laser beams fade
                var nextBeams = [];
                for (var lbi = 0; lbi < root.laserBeams.length; ++lbi) {
                    var lb = root.laserBeams[lbi];
                    lb.alpha -= 0.08;
                    if (lb.alpha > 0.04)
                        nextBeams.push(lb);
                }
                root.laserBeams = nextBeams;

                // 4. Enemy Warships in the sea below
                var nextShips = [];
                for (var wsi = 0; wsi < root.warships.length; ++wsi) {
                    var sh = root.warships[wsi];
                    sh.x += sh.vx;

                    if (sh.sinking) {
                        sh.sinkDepth += 0.75;
                        sh.sinkAngle += (sh.type === "carrier" ? 0.006 : -0.008);
                        if (Math.random() < 0.35) {
                            root.particles.push({
                                x: sh.x + (Math.random() - 0.5) * sh.w * 0.5,
                                y: root.seaLevel - 5,
                                vx: (Math.random() - 0.5) * 0.8,
                                vy: -(0.8 + Math.random() * 1.2),
                                life: 0.9,
                                decay: 0.02,
                                color: "#262b36",
                                size: 9 + Math.random() * 6,
                                smoke: true
                            });
                        }
                        if (sh.sinkDepth < 65)
                            nextShips.push(sh);
                        continue;
                    }

                    // Damaged ships emit burning fire and dark smoke
                    if (sh.hp < sh.maxHp && Math.random() < 0.3) {
                        root.particles.push({
                            x: sh.x + (Math.random() - 0.5) * sh.w * 0.4,
                            y: root.seaLevel - sh.h * 0.6,
                            vx: -0.4,
                            vy: -(1.0 + Math.random() * 1.2),
                            life: 0.85,
                            decay: 0.025,
                            color: (Math.random() > 0.4) ? "#222630" : "#ff6b35",
                            size: 7 + Math.random() * 5,
                            smoke: true
                        });
                    }

                    if (sh.x > -sh.w - 40)
                        nextShips.push(sh);
                }
                root.warships = nextShips;

                // Keep fleet populated on the wartime sea
                if (root.warships.length < 3 && Math.random() < 0.02) {
                    var types = ["destroyer", "cruiser", "carrier"];
                    root.spawnWarship(win.width + 140, types[Math.floor(Math.random() * 3)]);
                }

                // 5. Small enemy planes update
                var nextPlanes = [];
                for (var spi = 0; spi < root.smallPlanes.length; ++spi) {
                    var sp = root.smallPlanes[spi];
                    sp.x += sp.vx;
                    sp.timer += 0.07;
                    sp.y += sp.vy + Math.sin(sp.timer) * 0.9;
                    sp.y = Math.max(70, Math.min(root.seaLevel - 65, sp.y));

                    if (Math.random() < 0.012 && sp.x > 160 && sp.x < win.width - 60) {
                        root.spawnParatrooper(sp.x, sp.y + 12);
                    }

                    var distP = Math.hypot(sp.x - root.playerX, sp.y - root.playerY);
                    if (distP < 42) {
                        root.spawnDramaticExplosion(sp.x, sp.y, 1.0, false);
                        backend.recordPlaneDestroyed();
                        root.addFloatingText("SPLASHED! +150", sp.x, sp.y, "#ff9e64");
                        root.invulnerableTicks = 40;
                        continue;
                    }

                    if (sp.x > -60)
                        nextPlanes.push(sp);
                }
                root.smallPlanes = nextPlanes;

                // 6. Paratroopers update
                var nextTroopers = [];
                for (var pti = 0; pti < root.paratroopers.length; ++pti) {
                    var pt = root.paratroopers[pti];
                    pt.y += pt.vy;
                    pt.sway += 0.05;
                    pt.x += Math.sin(pt.sway) * 0.65;

                    var distRes = Math.hypot(pt.x - root.playerX, pt.y - root.playerY);
                    if (distRes < 48) {
                        backend.recordRescue();
                        root.addFloatingText("RESCUED! ⭐ +500", pt.x, pt.y - 20, "#9ece6a");
                        for (var starI = 0; starI < 10; ++starI) {
                            var sang = Math.random() * 6.28;
                            root.particles.push({
                                x: pt.x, y: pt.y,
                                vx: Math.cos(sang) * 2.5, vy: Math.sin(sang) * 2.5,
                                life: 1.0, decay: 0.04, color: "#ffd60a", size: 4.5, smoke: false
                            });
                        }
                        continue;
                    }

                    if (pt.y > root.seaLevel - 6) {
                        root.spawnWaterSplash(pt.x, root.seaLevel, 0.6);
                        continue;
                    }

                    nextTroopers.push(pt);
                }
                root.paratroopers = nextTroopers;

                // 7. Heavy Cruise Missiles update & collision (with Level 2 & 3 target homing!)
                var nextMissiles = [];
                for (var mi = 0; mi < root.missiles.length; ++mi) {
                    var m = root.missiles[mi];
                    m.vx = Math.min(14.5, m.vx + m.ax);

                    // Upgraded Homing Guidance in Level 2 & Level 3 locks onto the Boss Aeroplane or nearest fighter!
                    if (m.homing) {
                        var targetY = root.bossActive ? root.bossY : m.y;
                        var dyTarget = targetY - m.y;
                        m.vy += Math.max(-0.35, Math.min(0.35, dyTarget * 0.012));
                        m.vy = Math.max(-4.5, Math.min(4.5, m.vy));
                    }

                    m.x += m.vx;
                    m.y += m.vy;
                    m.life--;

                    // Dense rocket exhaust trail
                    root.particles.push({
                        x: m.x - 18,
                        y: m.y + (Math.random() - 0.5) * 3,
                        vx: -1.6,
                        vy: (Math.random() - 0.5) * 0.6,
                        life: 0.85,
                        decay: 0.035,
                        color: (Math.random() > 0.35) ? "#8892a8" : (m.homing ? "#7dcfff" : "#ff9e64"),
                        size: 5 + Math.random() * 3,
                        smoke: true
                    });

                    var missileHit = false;

                    // Hit check against small planes
                    for (var pi = 0; pi < root.smallPlanes.length; ++pi) {
                        var spl = root.smallPlanes[pi];
                        if (Math.hypot(m.x - spl.x, m.y - spl.y) < 30) {
                            root.spawnDramaticExplosion(spl.x, spl.y, 1.25, false);
                            backend.recordPlaneDestroyed();
                            root.addFloatingText("DIRECT HIT! +150", spl.x, spl.y - 14, "#ffd60a");
                            root.smallPlanes.splice(pi, 1);
                            missileHit = true;
                            break;
                        }
                    }

                    // Hit check against Boss Aeroplane
                    if (!missileHit && root.bossActive) {
                        var hitW = (backend.level === 3) ? 105 : 92;
                        var hitH = (backend.level === 3) ? 46 : 40;
                        if (m.x > root.bossX - hitW && m.x < root.bossX + hitW &&
                            m.y > root.bossY - hitH && m.y < root.bossY + hitH) {
                            var actualDmg = root.bossShieldActive ? Math.ceil((m.dmg || 16) * 0.45) : (m.dmg || 16);
                            root.bossHealth -= actualDmg;
                            root.spawnDramaticExplosion(m.x, m.y, 1.35, false);
                            backend.addScore(100);
                            missileHit = true;
                            root.checkBossDefeated();
                        }
                    }

                    if (!missileHit && m.x < win.width + 80 && m.life > 0)
                        nextMissiles.push(m);
                }
                root.missiles = nextMissiles;

                // 8. Gravity Bombs update & collision with Boss, Planes, and Enemy Warships below!
                var nextBombs = [];
                for (var bi = 0; bi < root.bombs.length; ++bi) {
                    var bmb = root.bombs[bi];
                    bmb.vy += bmb.gravity;
                    bmb.x += bmb.vx;
                    bmb.y += bmb.vy;
                    bmb.angle = Math.atan2(bmb.vy, bmb.vx);
                    bmb.life--;

                    var bombHit = false;

                    // Bombs dropped from above can also strike the Boss Aeroplane!
                    if (root.bossActive &&
                        bmb.x > root.bossX - 90 && bmb.x < root.bossX + 90 &&
                        bmb.y > root.bossY - 38 && bmb.y < root.bossY + 38) {
                        root.bossHealth -= (bmb.dmg || 2) * 9;
                        root.spawnDramaticExplosion(bmb.x, bmb.y, 1.45, false);
                        backend.addScore(150);
                        root.addFloatingText("BOMB HIT BOSS! +150", bmb.x, bmb.y - 16, "#ff9e64");
                        bombHit = true;
                        root.checkBossDefeated();
                    }

                    // Bombs can hit enemy planes flying below the B-2 Spirit!
                    if (!bombHit) {
                        for (var bpi = 0; bpi < root.smallPlanes.length; ++bpi) {
                            var bpl = root.smallPlanes[bpi];
                            if (Math.hypot(bmb.x - bpl.x, bmb.y - bpl.y) < 30) {
                                root.spawnDramaticExplosion(bpl.x, bpl.y, 1.35, false);
                                backend.recordPlaneDestroyed();
                                root.addFloatingText("AIR BOMB HIT! +150", bpl.x, bpl.y - 12, "#ff9e64");
                                root.smallPlanes.splice(bpi, 1);
                                bombHit = true;
                                break;
                            }
                        }
                    }

                    // Bombs hit enemy warships on the sea!
                    if (!bombHit) {
                        for (var si = 0; si < root.warships.length; ++si) {
                            var ship = root.warships[si];
                            if (ship.sinking) continue;
                            if (bmb.x > ship.x - ship.w * 0.5 && bmb.x < ship.x + ship.w * 0.5 &&
                                bmb.y >= root.seaLevel - ship.h && bmb.y <= root.seaLevel + 15) {
                                ship.hp -= (bmb.dmg || 2);
                                bombHit = true;
                                if (ship.hp <= 0) {
                                    ship.sinking = true;
                                    root.spawnDramaticExplosion(ship.x, root.seaLevel - ship.h * 0.4, 2.2, true);
                                    root.spawnDramaticExplosion(ship.x - 30, root.seaLevel - 10, 1.5, true);
                                    backend.recordShipDestroyed();
                                    root.addFloatingText("WARSHIP SUNK! 💥 +800", ship.x - 30, root.seaLevel - 50, "#ff4d4d");
                                } else {
                                    root.spawnDramaticExplosion(bmb.x, bmb.y, 1.3, true);
                                    backend.addScore(200);
                                    root.addFloatingText("DECK HIT! +200", bmb.x, bmb.y - 20, "#ffd60a");
                                }
                                break;
                            }
                        }
                    }

                    // Bomb hits the sea water directly
                    if (!bombHit && bmb.y >= root.seaLevel) {
                        root.spawnWaterSplash(bmb.x, root.seaLevel, 1.3);
                        root.shockwaves.push({
                            x: bmb.x, y: root.seaLevel,
                            radius: 4, maxRadius: 38, alpha: 0.7, width: 2.5, color: "#7dcfff"
                        });
                        bombHit = true;
                    }

                    if (!bombHit && bmb.life > 0)
                        nextBombs.push(bmb);
                }
                root.bombs = nextBombs;

                // 9. Shockwaves update
                var nextWaves = [];
                for (var swi = 0; swi < root.shockwaves.length; ++swi) {
                    var sw = root.shockwaves[swi];
                    sw.radius += (sw.maxRadius - sw.radius) * 0.16 + 1.5;
                    sw.alpha -= 0.045;
                    if (sw.alpha > 0.02)
                        nextWaves.push(sw);
                }
                root.shockwaves = nextWaves;

                // 10. Water splashes update
                var nextSplashes = [];
                for (var spli = 0; spli < root.splashes.length; ++spli) {
                    var spDrop = root.splashes[spli];
                    spDrop.x += spDrop.vx;
                    spDrop.y += spDrop.vy;
                    spDrop.vy += 0.28;
                    spDrop.life -= 0.03;
                    if (spDrop.life > 0 && spDrop.y <= root.seaLevel + 12)
                        nextSplashes.push(spDrop);
                }
                root.splashes = nextSplashes;

                // 11. Particles update
                var nextParticles = [];
                for (var pri = 0; pri < root.particles.length; ++pri) {
                    var p = root.particles[pri];
                    p.x += p.vx;
                    p.y += p.vy;
                    if (p.smoke)
                        p.size += 0.18;
                    p.life -= p.decay;
                    if (p.life > 0)
                        nextParticles.push(p);
                }
                root.particles = nextParticles;

                // 12. Floating texts update
                var nextTexts = [];
                for (var ti = 0; ti < root.floatingTexts.length; ++ti) {
                    var ft = root.floatingTexts[ti];
                    ft.y += ft.vy;
                    ft.alpha -= 0.018;
                    if (ft.alpha > 0)
                        nextTexts.push(ft);
                }
                root.floatingTexts = nextTexts;

                gameCanvas.requestPaint();
            }
        }

        // --- WARTIME SEASCAPE & COMBAT RENDERING CANVAS ---
        Canvas {
            id: gameCanvas
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                ctx.save();
                // Screen shake offset on dramatic impacts
                if (root.shakeIntensity > 0.5) {
                    var sx = (Math.random() - 0.5) * root.shakeIntensity;
                    var sy = (Math.random() - 0.5) * root.shakeIntensity;
                    ctx.translate(sx, sy);
                }

                var envLvl = backend.level;

                // 1. DISTINCT LEVEL THEATER SKY & HORIZON SCENERY (LEVELS 1, 2, 3)
                var skyGrad = ctx.createLinearGradient(0, 0, 0, root.seaLevel);
                if (envLvl === 1) {
                    // LEVEL 1: CORAL SEA SUNSET ARCHIPELAGO (Golden-Crimson Sunset & Tropical Volcanic Islands)
                    skyGrad.addColorStop(0.0, "#120c24");
                    skyGrad.addColorStop(0.42, "#3b1d4a");
                    skyGrad.addColorStop(0.75, "#873348");
                    skyGrad.addColorStop(1.0, "#d96b43");
                } else if (envLvl === 2) {
                    // LEVEL 2: ARCTIC AURORA GLACIER STRAIT (Deep Polar Midnight & Emerald Borealis Sky)
                    skyGrad.addColorStop(0.0, "#040b18");
                    skyGrad.addColorStop(0.45, "#091d36");
                    skyGrad.addColorStop(0.80, "#113758");
                    skyGrad.addColorStop(1.0, "#1d587a");
                } else {
                    // LEVEL 3: VOLCANIC LIGHTNING RED SEA (Obsidian-Ash Storm Sky & Magma Horizon)
                    skyGrad.addColorStop(0.0, "#09060c");
                    skyGrad.addColorStop(0.45, "#1f0d1d");
                    skyGrad.addColorStop(0.80, "#471222");
                    skyGrad.addColorStop(1.0, "#7a1c1c");
                }
                ctx.fillStyle = skyGrad;
                ctx.fillRect(0, 0, width, root.seaLevel);

                // Level-Specific Atmospheric & Horizon Landmarks
                if (envLvl === 1) {
                    // Glowing Golden Setting Sun on the Coral Sea Horizon
                    var sunGrad = ctx.createRadialGradient(width * 0.72, root.seaLevel - 35, 12, width * 0.72, root.seaLevel - 35, 195);
                    sunGrad.addColorStop(0.0, "rgba(255, 225, 120, 0.85)");
                    sunGrad.addColorStop(0.35, "rgba(255, 135, 65, 0.40)");
                    sunGrad.addColorStop(1.0, "rgba(255, 90, 50, 0)");
                    ctx.fillStyle = sunGrad;
                    ctx.fillRect(0, root.seaLevel - 260, width, 260);

                    // Distant Tropical Archipelago Islands & Radar Tower Silhouette
                    ctx.fillStyle = "#22152e";
                    ctx.beginPath();
                    ctx.moveTo(70, root.seaLevel);
                    ctx.lineTo(145, root.seaLevel - 68);
                    ctx.lineTo(225, root.seaLevel - 42);
                    ctx.lineTo(310, root.seaLevel);
                    ctx.closePath();
                    ctx.fill();

                    ctx.beginPath();
                    ctx.moveTo(width * 0.54, root.seaLevel);
                    ctx.lineTo(width * 0.61, root.seaLevel - 92);
                    ctx.lineTo(width * 0.67, root.seaLevel - 55);
                    ctx.lineTo(width * 0.74, root.seaLevel - 82);
                    ctx.lineTo(width * 0.84, root.seaLevel);
                    ctx.closePath();
                    ctx.fill();
                } else if (envLvl === 2) {
                    // Shimmering Emerald & Cyan Aurora Borealis Ribbons in the Upper Sky
                    ctx.save();
                    for (var ab = 0; ab < 2; ++ab) {
                        ctx.strokeStyle = (ab === 0) ? "rgba(158, 206, 106, 0.22)" : "rgba(125, 207, 255, 0.18)";
                        ctx.lineWidth = 34 - ab * 10;
                        ctx.beginPath();
                        for (var ax = 0; ax <= width; ax += 45) {
                            var ay = 135 + ab * 38 + Math.sin(ax * 0.008 + root.seaTime * 0.7 + ab) * 28;
                            if (ax === 0) ctx.moveTo(ax, ay);
                            else ctx.lineTo(ax, ay);
                        }
                        ctx.stroke();
                    }
                    ctx.restore();

                    // Towering Jagged Polar Glaciers & Icebergs on the Horizon
                    ctx.fillStyle = "#183e5c";
                    ctx.beginPath();
                    ctx.moveTo(90, root.seaLevel);
                    ctx.lineTo(135, root.seaLevel - 108);
                    ctx.lineTo(175, root.seaLevel - 72);
                    ctx.lineTo(220, root.seaLevel - 122);
                    ctx.lineTo(295, root.seaLevel);
                    ctx.closePath();
                    ctx.fill();

                    ctx.fillStyle = "#2b648c";
                    ctx.beginPath();
                    ctx.moveTo(width * 0.62, root.seaLevel);
                    ctx.lineTo(width * 0.68, root.seaLevel - 130);
                    ctx.lineTo(width * 0.73, root.seaLevel - 85);
                    ctx.lineTo(width * 0.79, root.seaLevel - 115);
                    ctx.lineTo(width * 0.87, root.seaLevel);
                    ctx.closePath();
                    ctx.fill();
                } else {
                    // Level 3: Erupting Volcanic Cones, Magma Rivers & Crimson Lightning Flashes
                    var magmaGlow = ctx.createRadialGradient(width * 0.68, root.seaLevel, 15, width * 0.68, root.seaLevel, 420);
                    magmaGlow.addColorStop(0.0, "rgba(255, 77, 77, 0.45)");
                    magmaGlow.addColorStop(0.5, "rgba(255, 158, 100, 0.16)");
                    magmaGlow.addColorStop(1.0, "rgba(0, 0, 0, 0)");
                    ctx.fillStyle = magmaGlow;
                    ctx.fillRect(0, root.seaLevel - 350, width, 350);

                    // Twin Erupting Volcanoes on the Horizon
                    ctx.fillStyle = "#1a0a12";
                    ctx.beginPath();
                    ctx.moveTo(width * 0.52, root.seaLevel);
                    ctx.lineTo(width * 0.64, root.seaLevel - 138);
                    ctx.lineTo(width * 0.70, root.seaLevel - 138);
                    ctx.lineTo(width * 0.83, root.seaLevel);
                    ctx.closePath();
                    ctx.fill();

                    // Glowing Lava Crater & Magma Streams
                    ctx.strokeStyle = "#ff4d4d";
                    ctx.lineWidth = 3.5;
                    ctx.beginPath();
                    ctx.moveTo(width * 0.65, root.seaLevel - 136);
                    ctx.lineTo(width * 0.63, root.seaLevel - 65);
                    ctx.moveTo(width * 0.68, root.seaLevel - 136);
                    ctx.lineTo(width * 0.72, root.seaLevel - 50);
                    ctx.stroke();

                    // Periodic Red-Violet Storm Lightning Bolt in Level 3
                    if (root.lightningFlashTicks > 0) {
                        ctx.fillStyle = "rgba(255, 200, 220, 0.14)";
                        ctx.fillRect(0, 0, width, root.seaLevel);
                        ctx.strokeStyle = "#ffd60a";
                        ctx.lineWidth = 3;
                        ctx.beginPath();
                        ctx.moveTo(width * 0.45, 64);
                        ctx.lineTo(width * 0.42, 165);
                        ctx.lineTo(width * 0.47, 185);
                        ctx.lineTo(width * 0.41, 310);
                        ctx.stroke();
                    }
                }

                // Searchlight beams sweeping from distant naval horizon
                ctx.save();
                ctx.fillStyle = (envLvl === 3) ? "rgba(255, 120, 120, 0.05)" : (envLvl === 2 ? "rgba(125, 240, 255, 0.05)" : "rgba(255, 220, 160, 0.05)");
                for (var sbi = 0; sbi < 2; ++sbi) {
                    var bx = width * (0.3 + sbi * 0.45);
                    var swing = Math.sin(root.seaTime * 0.5 + sbi * 2.1) * 180;
                    ctx.beginPath();
                    ctx.moveTo(bx, root.seaLevel);
                    ctx.lineTo(bx + swing - 70, 0);
                    ctx.lineTo(bx + swing + 70, 0);
                    ctx.closePath();
                    ctx.fill();
                }
                ctx.restore();

                // 2. STORM CLOUDS TINTED BY LEVEL THEATER
                for (var ci = 0; ci < root.clouds.length; ++ci) {
                    var c = root.clouds[ci];
                    if (envLvl === 1)
                        ctx.fillStyle = c.dark ? "rgba(65, 28, 58, 0.55)" : "rgba(255, 185, 145, 0.14)";
                    else if (envLvl === 2)
                        ctx.fillStyle = c.dark ? "rgba(12, 36, 58, 0.55)" : "rgba(175, 235, 255, 0.12)";
                    else
                        ctx.fillStyle = c.dark ? "rgba(38, 12, 22, 0.65)" : "rgba(255, 110, 95, 0.12)";
                    ctx.beginPath();
                    ctx.arc(c.x, c.y, 38 * c.s, 0, 6.28);
                    ctx.arc(c.x + 34 * c.s, c.y - 12 * c.s, 45 * c.s, 0, 6.28);
                    ctx.arc(c.x + 76 * c.s, c.y, 34 * c.s, 0, 6.28);
                    ctx.fill();
                }

                // 3. BACKGROUND OCEAN SWELLS (Tinted for Coral Sea / Arctic Strait / Volcanic Red Sea)
                var seaGrad = ctx.createLinearGradient(0, root.seaLevel - 15, 0, height);
                if (envLvl === 1) {
                    seaGrad.addColorStop(0.0, "#1c4e63");
                    seaGrad.addColorStop(0.4, "#12354a");
                    seaGrad.addColorStop(1.0, "#081c29");
                } else if (envLvl === 2) {
                    seaGrad.addColorStop(0.0, "#15496e");
                    seaGrad.addColorStop(0.4, "#0c2f4d");
                    seaGrad.addColorStop(1.0, "#051829");
                } else {
                    seaGrad.addColorStop(0.0, "#3d1626");
                    seaGrad.addColorStop(0.4, "#260d18");
                    seaGrad.addColorStop(1.0, "#12050b");
                }
                ctx.fillStyle = seaGrad;
                ctx.fillRect(0, root.seaLevel - 8, width, height - root.seaLevel + 16);

                // Rolling back wave layer
                ctx.fillStyle = (envLvl === 3) ? "#4f1c2e" : (envLvl === 2 ? "#1c5d87" : "#225a73");
                ctx.beginPath();
                ctx.moveTo(0, height);
                for (var wx = 0; wx <= width + 40; wx += 40) {
                    var wy = root.seaLevel - 6 + Math.sin(wx * 0.015 + root.seaTime) * 5;
                    ctx.lineTo(wx, wy);
                }
                ctx.lineTo(width, height);
                ctx.closePath();
                ctx.fill();

                // 4. ENEMY WARSHIPS STEAMING ON THE SEA
                for (var wsi = 0; wsi < root.warships.length; ++wsi) {
                    var sh = root.warships[wsi];
                    ctx.save();
                    var bobY = Math.sin(root.seaTime * 1.4 + wsi) * 2.5;
                    ctx.translate(sh.x, root.seaLevel + bobY + sh.sinkDepth);
                    ctx.rotate(sh.sinkAngle + Math.sin(root.seaTime + wsi) * 0.015);

                    var hw = sh.w * 0.5;
                    // Armored Naval Hull
                    ctx.fillStyle = "#3b4354";
                    ctx.beginPath();
                    ctx.moveTo(-hw, -sh.h * 0.45);        // Sharp naval bow (pointing left)
                    ctx.lineTo(hw, -sh.h * 0.42);         // Stern deck
                    ctx.lineTo(hw - 10, 6);               // Stern waterline
                    ctx.lineTo(-hw + 14, 6);              // Bow waterline
                    ctx.closePath();
                    ctx.fill();

                    // Hull stripe / armor belt
                    ctx.fillStyle = "#282e3a";
                    ctx.fillRect(-hw + 14, -6, sh.w - 24, 5);

                    if (sh.type === "carrier") {
                        // Flight deck overhang
                        ctx.fillStyle = "#2b303c";
                        ctx.fillRect(-hw - 4, -sh.h * 0.55, sh.w + 8, 7);
                        // White runway markings
                        ctx.fillStyle = "#d8dee9";
                        for (var rmk = -hw + 10; rmk < hw - 15; rmk += 22) {
                            ctx.fillRect(rmk, -sh.h * 0.52, 12, 2);
                        }
                        // Carrier Island Superstructure
                        ctx.fillStyle = "#4c566a";
                        ctx.fillRect(10, -sh.h, 34, sh.h * 0.5);
                        // Radar mast
                        ctx.strokeStyle = "#8892a8";
                        ctx.lineWidth = 2;
                        ctx.beginPath();
                        ctx.moveTo(27, -sh.h);
                        ctx.lineTo(27, -sh.h - 14);
                        ctx.stroke();
                    } else {
                        // Bridge Superstructure (Destroyer / Cruiser)
                        ctx.fillStyle = "#4c566a";
                        ctx.fillRect(-16, -sh.h * 0.85, 38, sh.h * 0.42);
                        ctx.fillStyle = "#2e3440";
                        ctx.fillRect(-12, -sh.h * 0.78, 14, 5); // Bridge windows

                        // Radar & Mast tower
                        ctx.fillStyle = "#5e6a82";
                        ctx.fillRect(4, -sh.h - 6, 8, sh.h * 0.3);

                        // Forward Naval Gun Turret + Twin Barrels
                        ctx.fillStyle = "#2e3440";
                        ctx.beginPath();
                        ctx.arc(-hw + 32, -sh.h * 0.45, 8, 3.14, 0);
                        ctx.fill();
                        ctx.strokeStyle = "#8892a8";
                        ctx.lineWidth = 2.5;
                        ctx.beginPath();
                        ctx.moveTo(-hw + 26, -sh.h * 0.52);
                        ctx.lineTo(-hw + 8, -sh.h * 0.68);
                        ctx.stroke();

                        // Rear turret for cruiser
                        if (sh.type === "cruiser") {
                            ctx.beginPath();
                            ctx.arc(hw - 28, -sh.h * 0.45, 7, 3.14, 0);
                            ctx.fill();
                        }
                    }

                    // Bow wake white foam
                    if (!sh.sinking) {
                        ctx.fillStyle = "rgba(235, 245, 255, 0.75)";
                        ctx.beginPath();
                        ctx.ellipse(-hw + 6, 4, 14, 3.5, 0, 0, 6.28);
                        ctx.fill();

                        // Ship health bar when damaged
                        if (sh.hp < sh.maxHp) {
                            ctx.fillStyle = "rgba(0,0,0,0.65)";
                            ctx.fillRect(-28, -sh.h - 18, 56, 5);
                            ctx.fillStyle = "#ff4d4d";
                            ctx.fillRect(-28, -sh.h - 18, 56 * (sh.hp / sh.maxHp), 5);
                        }
                    }

                    ctx.restore();
                }

                // 5. FOREGROUND ROLLING SEA WAVES & FOAM CRESTS (Covers ship waterlines)
                ctx.fillStyle = (envLvl === 3) ? "rgba(68, 20, 36, 0.84)" : (envLvl === 2 ? "rgba(18, 68, 102, 0.82)" : "rgba(22, 65, 88, 0.82)");
                ctx.beginPath();
                ctx.moveTo(0, height);
                for (var fwx = 0; fwx <= width + 30; fwx += 30) {
                    var fwy = root.seaLevel + 2 + Math.sin(fwx * 0.022 + root.seaTime * 1.6) * 5.5;
                    ctx.lineTo(fwx, fwy);
                }
                ctx.lineTo(width, height);
                ctx.closePath();
                ctx.fill();

                // Whitecap wave crests
                ctx.strokeStyle = (envLvl === 3) ? "rgba(255, 150, 120, 0.32)" : "rgba(210, 235, 255, 0.30)";
                ctx.lineWidth = 2;
                ctx.beginPath();
                for (var cwx = 0; cwx <= width; cwx += 30) {
                    var cwy = root.seaLevel + 2 + Math.sin(cwx * 0.022 + root.seaTime * 1.6) * 5.5;
                    if (cwx === 0) ctx.moveTo(cwx, cwy);
                    else ctx.lineTo(cwx, cwy);
                }
                ctx.stroke();

                // 6. WATER SPLASH GEYSERS
                ctx.fillStyle = "rgba(230, 245, 255, 0.85)";
                for (var spli = 0; spli < root.splashes.length; ++spli) {
                    var spD = root.splashes[spli];
                    ctx.globalAlpha = Math.max(0, spD.life);
                    ctx.beginPath();
                    ctx.arc(spD.x, spD.y, spD.size, 0, 6.28);
                    ctx.fill();
                }
                ctx.globalAlpha = 1.0;

                // 7. BOSS AEROPLANE (LEVELS 1, 2, 3 DISTINCT ARCHITECTURES)
                if (root.bossActive) {
                    ctx.save();
                    ctx.translate(root.bossX, root.bossY);
                    var bLvl = backend.level;

                    if (bLvl === 1) {
                        // LEVEL 1 BOSS: IRON VULTURE BOMBER (Gunmetal Twin-Wing Heavy Carrier)
                        ctx.fillStyle = "#252b3b";
                        ctx.beginPath();
                        ctx.moveTo(15, -6); ctx.lineTo(45, -58); ctx.lineTo(-22, -58); ctx.lineTo(-14, -6);
                        ctx.closePath();
                        ctx.fill();
                        ctx.beginPath();
                        ctx.moveTo(15, 6); ctx.lineTo(45, 52); ctx.lineTo(-22, 52); ctx.lineTo(-14, 6);
                        ctx.closePath();
                        ctx.fill();

                        ctx.fillStyle = "#363e52";
                        ctx.beginPath();
                        ctx.ellipse(0, 0, 98, 28, 0, 0, 6.28);
                        ctx.fill();

                        ctx.fillStyle = "#1a1e29";
                        ctx.fillRect(12, -46, 32, 10);
                        ctx.fillRect(12, 38, 32, 10);
                        ctx.fillStyle = "#ff9e64";
                        ctx.fillRect(44, -44, 10 + Math.random() * 7, 6);
                        ctx.fillRect(44, 40, 10 + Math.random() * 7, 6);

                        ctx.fillStyle = "#7dcfff";
                        ctx.beginPath();
                        ctx.ellipse(-68, -5, 16, 7, -0.18, 0, 6.28);
                        ctx.fill();
                    } else if (bLvl === 2) {
                        // LEVEL 2 BOSS: STORM VALKYRIE GUNSHIP (Crimson Forward-Swept Assault Fortress)
                        ctx.fillStyle = "#5a1e2d";
                        ctx.beginPath();
                        ctx.moveTo(-25, -8); ctx.lineTo(-55, -72); ctx.lineTo(20, -64); ctx.lineTo(25, -8);
                        ctx.closePath();
                        ctx.fill();
                        ctx.beginPath();
                        ctx.moveTo(-25, 8); ctx.lineTo(-55, 72); ctx.lineTo(20, 64); ctx.lineTo(25, 8);
                        ctx.closePath();
                        ctx.fill();

                        // Crimson Armored Fuselage
                        ctx.fillStyle = "#7a283b";
                        ctx.beginPath();
                        ctx.ellipse(0, 0, 106, 32, 0, 0, 6.28);
                        ctx.fill();

                        // Forward Rotary Cannon Pods
                        ctx.fillStyle = "#e0af68";
                        ctx.fillRect(-95, -18, 22, 6);
                        ctx.fillRect(-95, 12, 22, 6);

                        // 4 Supersonic Afterburners
                        ctx.fillStyle = "#ff4d4d";
                        ctx.fillRect(22, -56, 16 + Math.random() * 9, 8);
                        ctx.fillRect(22, 48, 16 + Math.random() * 9, 8);

                        ctx.fillStyle = "#ffd60a";
                        ctx.beginPath();
                        ctx.ellipse(-72, -4, 18, 8, -0.12, 0, 6.28);
                        ctx.fill();
                    } else {
                        // LEVEL 3 FINAL BOSS: SKY TITAN DREADNOUGHT (Obsidian & Gold Tri-Hull Aerial Super-Boss)
                        ctx.fillStyle = "#1e1b2e";
                        ctx.strokeStyle = "#bb9af7";
                        ctx.lineWidth = 2;
                        ctx.beginPath();
                        ctx.moveTo(-40, 0);
                        ctx.lineTo(35, -84);
                        ctx.lineTo(80, -72);
                        ctx.lineTo(48, 0);
                        ctx.lineTo(80, 72);
                        ctx.lineTo(35, 84);
                        ctx.closePath();
                        ctx.fill();
                        ctx.stroke();

                        // Twin Outrigger Hulls
                        ctx.fillStyle = "#2d2747";
                        ctx.fillRect(-45, -62, 95, 16);
                        ctx.fillRect(-45, 46, 95, 16);

                        // Central Command Dreadnought Hull
                        ctx.fillStyle = "#3b335e";
                        ctx.beginPath();
                        ctx.ellipse(0, 0, 114, 36, 0, 0, 6.28);
                        ctx.fill();

                        // Gold Armor Trim & Plasma Core
                        ctx.strokeStyle = "#ffd60a";
                        ctx.lineWidth = 2.2;
                        ctx.beginPath();
                        ctx.moveTo(-90, 0); ctx.lineTo(65, -24);
                        ctx.moveTo(-90, 0); ctx.lineTo(65, 24);
                        ctx.stroke();

                        ctx.fillStyle = "#bb9af7";
                        ctx.beginPath();
                        ctx.arc(-25, 0, 14, 0, 6.28);
                        ctx.fill();

                        // 6 Violet Plasma Thrusters
                        ctx.fillStyle = "#7dcfff";
                        ctx.fillRect(52, -58, 18 + Math.random() * 10, 10);
                        ctx.fillRect(52, 48, 18 + Math.random() * 10, 10);
                        ctx.fillRect(108, -8, 22 + Math.random() * 12, 16);

                        // Pulsing Energy Shield Dome
                        if (root.bossShieldActive) {
                            ctx.strokeStyle = "rgba(187, 154, 247, 0.85)";
                            ctx.fillStyle = "rgba(125, 207, 255, 0.14)";
                            ctx.lineWidth = 3.5;
                            ctx.beginPath();
                            ctx.ellipse(0, 0, 128, 92, 0, 0, 6.28);
                            ctx.fill();
                            ctx.stroke();
                        }
                    }

                    // Illuminated Drop Hangar Bay
                    ctx.fillStyle = root.bossHangarOpen ? "#ff9e64" : "#161922";
                    ctx.fillRect(46, -9, 26, 18);

                    // Boss Name Tag & Health Bar above Boss Aeroplane (Shows Phase 2 Enraged state!)
                    ctx.font = "bold 12px sans-serif";
                    ctx.fillStyle = root.bossEnraged ? "#ff4d4d" : "#ffd60a";
                    var phaseTag = root.bossEnraged ? " [PHASE 2 ENRAGED!]" : "";
                    ctx.fillText("LVL " + bLvl + " BOSS: " + backend.bossName.toUpperCase() + phaseTag, -88, -86);

                    ctx.fillStyle = "rgba(0,0,0,0.75)";
                    ctx.fillRect(-88, -80, 176, 9);
                    ctx.fillStyle = root.bossShieldActive ? "#bb9af7" : (root.bossEnraged ? "#ff9e64" : "#ff4d4d");
                    var hpFrac = Math.max(0, root.bossHealth / root.bossMaxHealth);
                    ctx.fillRect(-88, -80, 176 * hpFrac, 9);

                    ctx.restore();
                }

                // 7a. PLAYER AUTOCANNON & WINGMAN DRONE PLASMA BOLTS
                for (var cbi = 0; cbi < root.cannonBolts.length; ++cbi) {
                    var cb = root.cannonBolts[cbi];
                    ctx.save();
                    ctx.fillStyle = cb.color;
                    ctx.fillRect(cb.x - 10, cb.y - 2, 18, 4);
                    ctx.fillStyle = "#ffffff";
                    ctx.fillRect(cb.x - 4, cb.y - 1, 10, 2);
                    ctx.restore();
                }

                // 7b. BOSS AEROPLANE CANNON / PLASMA ORBS
                for (var bbi = 0; bbi < root.bossBullets.length; ++bbi) {
                    var bb = root.bossBullets[bbi];
                    ctx.save();
                    ctx.fillStyle = bb.color;
                    ctx.beginPath();
                    ctx.arc(bb.x, bb.y, bb.radius, 0, 6.28);
                    ctx.fill();
                    ctx.fillStyle = "#ffffff";
                    ctx.beginPath();
                    ctx.arc(bb.x - 1.5, bb.y - 1.5, bb.radius * 0.45, 0, 6.28);
                    ctx.fill();
                    ctx.restore();
                }

                // 7c. LEVEL 3 PLAYER PLASMA NOSE LASER BEAMS
                for (var lbi = 0; lbi < root.laserBeams.length; ++lbi) {
                    var lb = root.laserBeams[lbi];
                    ctx.save();
                    ctx.globalAlpha = Math.max(0, lb.alpha);
                    ctx.strokeStyle = "#7dcfff";
                    ctx.lineWidth = 8;
                    ctx.beginPath();
                    ctx.moveTo(lb.x1, lb.y1);
                    ctx.lineTo(lb.x2, lb.y2);
                    ctx.stroke();
                    ctx.strokeStyle = "#ffffff";
                    ctx.lineWidth = 3;
                    ctx.beginPath();
                    ctx.moveTo(lb.x1, lb.y1);
                    ctx.lineTo(lb.x2, lb.y2);
                    ctx.stroke();
                    ctx.restore();
                }

                // 8. SMALL ENEMY FIGHTER PLANES
                for (var spi = 0; spi < root.smallPlanes.length; ++spi) {
                    var sp = root.smallPlanes[spi];
                    ctx.save();
                    ctx.translate(sp.x, sp.y);

                    // Swept enemy fighter silhouette
                    ctx.fillStyle = "#d24d57";
                    ctx.beginPath();
                    ctx.moveTo(-22, 0);
                    ctx.lineTo(14, -12);
                    ctx.lineTo(7, -2);
                    ctx.lineTo(16, 0);
                    ctx.lineTo(7, 2);
                    ctx.lineTo(14, 12);
                    ctx.closePath();
                    ctx.fill();

                    // Canopy
                    ctx.fillStyle = "#a9b1d6";
                    ctx.beginPath();
                    ctx.ellipse(-6, -1, 5, 2.5, 0, 0, 6.28);
                    ctx.fill();

                    // Afterburner
                    ctx.fillStyle = "#ff9e64";
                    ctx.fillRect(14, -2, 6 + Math.random() * 5, 4);

                    ctx.restore();
                }

                // 9. PARATROOPERS JUMPING OUT
                for (var pti = 0; pti < root.paratroopers.length; ++pti) {
                    var pt = root.paratroopers[pti];
                    ctx.save();
                    ctx.translate(pt.x, pt.y);

                    ctx.fillStyle = pt.color;
                    ctx.beginPath();
                    ctx.arc(0, -18, 16, 3.14, 0);
                    ctx.closePath();
                    ctx.fill();

                    ctx.strokeStyle = "rgba(255,255,255,0.55)";
                    ctx.lineWidth = 1;
                    ctx.beginPath();
                    ctx.moveTo(-14, -18); ctx.lineTo(0, 0);
                    ctx.moveTo(-6, -18);  ctx.lineTo(0, 0);
                    ctx.moveTo(6, -18);   ctx.lineTo(0, 0);
                    ctx.moveTo(14, -18);  ctx.lineTo(0, 0);
                    ctx.stroke();

                    ctx.fillStyle = "#d8dee9";
                    ctx.beginPath();
                    ctx.arc(0, 3, 3.5, 0, 6.28);
                    ctx.fill();
                    ctx.fillStyle = "#4c566a";
                    ctx.fillRect(-2.5, 6, 5, 7);

                    ctx.restore();
                }

                // 10. HEAVY GRAVITY BOMBS DROPPING ON PLANES & SHIPS
                for (var bi = 0; bi < root.bombs.length; ++bi) {
                    var bmb = root.bombs[bi];
                    ctx.save();
                    ctx.translate(bmb.x, bmb.y);
                    ctx.rotate(bmb.angle);

                    // Tail stabilizer fins
                    ctx.fillStyle = "#2b303c";
                    ctx.beginPath();
                    ctx.moveTo(-13, -6);
                    ctx.lineTo(-7, -3);
                    ctx.lineTo(-7, 3);
                    ctx.lineTo(-13, 6);
                    ctx.closePath();
                    ctx.fill();

                    // Heavy olive-steel bomb casing
                    ctx.fillStyle = "#4b5340";
                    ctx.beginPath();
                    ctx.ellipse(0, 0, 11, 4.5, 0, 0, 6.28);
                    ctx.fill();

                    // High-explosive yellow warhead stripe
                    ctx.fillStyle = "#ffd60a";
                    ctx.fillRect(4, -3.8, 3, 7.6);

                    ctx.restore();
                }

                // 11. BIG HEAVY CRUISE MISSILES
                for (var mi = 0; mi < root.missiles.length; ++mi) {
                    var m = root.missiles[mi];
                    ctx.save();
                    ctx.translate(m.x, m.y);

                    // Roaring multi-layer rocket flame plume
                    var plumeLen = 18 + Math.random() * 14;
                    ctx.fillStyle = "#ff4d4d";
                    ctx.beginPath();
                    ctx.moveTo(-16, -5);
                    ctx.lineTo(-16 - plumeLen, 0);
                    ctx.lineTo(-16, 5);
                    ctx.closePath();
                    ctx.fill();

                    ctx.fillStyle = "#ffd60a";
                    ctx.beginPath();
                    ctx.moveTo(-16, -2.8);
                    ctx.lineTo(-16 - plumeLen * 0.65, 0);
                    ctx.lineTo(-16, 2.8);
                    ctx.closePath();
                    ctx.fill();

                    // Swept mid-body cruise wings
                    ctx.fillStyle = "#6c768a";
                    ctx.beginPath();
                    ctx.moveTo(2, -4);
                    ctx.lineTo(-6, -13);
                    ctx.lineTo(-10, -13);
                    ctx.lineTo(-5, -4);
                    ctx.closePath();
                    ctx.fill();

                    ctx.beginPath();
                    ctx.moveTo(2, 4);
                    ctx.lineTo(-6, 13);
                    ctx.lineTo(-10, 13);
                    ctx.lineTo(-5, 4);
                    ctx.closePath();
                    ctx.fill();

                    // Tail fins
                    ctx.fillStyle = "#4c566a";
                    ctx.beginPath();
                    ctx.moveTo(-10, -4);
                    ctx.lineTo(-16, -9);
                    ctx.lineTo(-16, 9);
                    ctx.lineTo(-10, 4);
                    ctx.closePath();
                    ctx.fill();

                    // Heavy cylindrical missile body
                    ctx.fillStyle = "#e5e9f0";
                    ctx.fillRect(-16, -4, 28, 8);

                    // Warhead hazard band
                    ctx.fillStyle = "#ffd60a";
                    ctx.fillRect(6, -4, 4, 8);

                    // Armored nose cone
                    ctx.fillStyle = "#d24d57";
                    ctx.beginPath();
                    ctx.moveTo(12, -4);
                    ctx.lineTo(24, 0);
                    ctx.lineTo(12, 4);
                    ctx.closePath();
                    ctx.fill();

                    ctx.restore();
                }

                // 12. REALISTIC B-2 SPIRIT STEALTH BOMBER (HERO PLANE WITH LEVEL 1/2/3 UPGRADES)
                ctx.save();
                ctx.translate(root.playerX, root.playerY);
                ctx.rotate(root.playerTilt);
                var pTier = backend.weaponTier;

                // Concealed Dorsal Stealth Exhaust Glow (Twin recessed vents on top deck; Plasma Blue in Tier 3)
                var jetGlow = 12 + pTier * 3 + Math.random() * 8;
                ctx.fillStyle = (pTier === 3) ? "rgba(125, 207, 255, 0.9)" : "rgba(255, 158, 100, 0.85)";
                ctx.beginPath();
                ctx.moveTo(-22, -13); ctx.lineTo(-22 - jetGlow, -10); ctx.lineTo(-22, -7);
                ctx.moveTo(-22, 7);   ctx.lineTo(-22 - jetGlow, 10);  ctx.lineTo(-22, 13);
                ctx.fill();

                // Open Internal Bomb Bay Glow when releasing missiles/bombs
                if (root.bombBayOpenTicks > 0) {
                    ctx.fillStyle = (pTier === 3) ? "rgba(125, 207, 255, 0.65)" : "rgba(255, 180, 90, 0.55)";
                    ctx.beginPath();
                    ctx.ellipse(2, 8, 20, 9, 0, 0, 6.28);
                    ctx.fill();
                }

                // Level 2 & 3 Wingtip Supersonic Hardpoint Pods
                if (pTier >= 2) {
                    ctx.fillStyle = (pTier === 3) ? "#ffd60a" : "#ff9e64";
                    ctx.fillRect(-16, -46, 22, 4);
                    ctx.fillRect(-16, 42, 22, 4);
                }

                // B-2 Spirit Iconic Flying-Wing Silhouette with Sawtooth "W" Trailing Edge
                var b2Grad = ctx.createLinearGradient(-40, -58, 52, 58);
                b2Grad.addColorStop(0.0, "#505a6e");
                b2Grad.addColorStop(0.45, "#373f4f");
                b2Grad.addColorStop(1.0, "#232834");
                ctx.fillStyle = b2Grad;
                ctx.strokeStyle = (pTier === 3) ? "#ffd60a" : (pTier === 2 ? "#7dcfff" : "#7c8aa6");
                ctx.lineWidth = (pTier >= 2) ? 2.0 : 1.6;

                ctx.beginPath();
                ctx.moveTo(50, 0);      // Sharp stealth hawk-beak nose
                ctx.lineTo(-14, -62);   // Upper straight swept leading edge
                ctx.lineTo(-30, -52);   // Upper raked stealth wingtip
                ctx.lineTo(-16, -28);   // Upper outer sawtooth notch
                ctx.lineTo(-32, -14);   // Upper inner sawtooth peak
                ctx.lineTo(-20, 0);     // Center beaver-tail trailing tip
                ctx.lineTo(-32, 14);    // Lower inner sawtooth peak
                ctx.lineTo(-16, 28);    // Lower outer sawtooth notch
                ctx.lineTo(-30, 52);    // Lower raked stealth wingtip
                ctx.lineTo(-14, 62);    // Lower straight swept leading edge
                ctx.closePath();
                ctx.fill();
                ctx.stroke();

                // Leading-edge radar-absorbent metallic sheen
                ctx.strokeStyle = (pTier === 3) ? "#7dcfff" : "#9ab0d6";
                ctx.lineWidth = 1.8;
                ctx.beginPath();
                ctx.moveTo(-14, -62);
                ctx.lineTo(50, 0);
                ctx.lineTo(-14, 62);
                ctx.stroke();

                // Center Fuselage Blended Spine Highlight
                ctx.fillStyle = "#434d61";
                ctx.beginPath();
                ctx.moveTo(45, 0);
                ctx.lineTo(4, -18);
                ctx.lineTo(-24, -11);
                ctx.lineTo(-18, 0);
                ctx.lineTo(-24, 11);
                ctx.lineTo(4, 18);
                ctx.closePath();
                ctx.fill();

                // Level 3 Nose Plasma Laser Emitter Core
                if (pTier === 3) {
                    ctx.fillStyle = "#7dcfff";
                    ctx.beginPath();
                    ctx.arc(46, 0, 4.5, 0, 6.28);
                    ctx.fill();
                }

                // Radar-Absorbent Stealth Panel Seam Lines
                ctx.strokeStyle = "rgba(175, 195, 225, 0.28)";
                ctx.lineWidth = 1;
                ctx.beginPath();
                ctx.moveTo(18, -15); ctx.lineTo(-16, -50);
                ctx.moveTo(18, 15);  ctx.lineTo(-16, 50);
                ctx.moveTo(-7, -14); ctx.lineTo(-7, 14);
                ctx.stroke();

                // Twin Recessed Stealth Engine Intakes (S-duct serrated intakes)
                ctx.fillStyle = "#161922";
                ctx.beginPath();
                ctx.moveTo(5, -13); ctx.lineTo(-7, -17); ctx.lineTo(-10, -9); ctx.closePath();
                ctx.moveTo(5, 13);  ctx.lineTo(-7, 17);  ctx.lineTo(-10, 9);  ctx.closePath();
                ctx.fill();

                // B-2 Spirit Flush Wrap-Around Metallic Cockpit Windscreens (4 angled panes)
                ctx.fillStyle = "#7dcfff";
                ctx.beginPath();
                ctx.moveTo(36, -2); ctx.lineTo(24, -10); ctx.lineTo(20, -3); ctx.closePath();
                ctx.moveTo(36, 2);  ctx.lineTo(24, 10);  ctx.lineTo(20, 3);  ctx.closePath();
                ctx.fill();

                ctx.fillStyle = "#e0af68"; // Gold radar-reflective side pane tint
                ctx.beginPath();
                ctx.moveTo(23, -11); ctx.lineTo(15, -15); ctx.lineTo(16, -7); ctx.closePath();
                ctx.moveTo(23, 11);  ctx.lineTo(15, 15);  ctx.lineTo(16, 7);  ctx.closePath();
                ctx.fill();

                // Level 3 Twin Autonomous Wingman Stealth Drones flying in formation beside the B-2 Spirit!
                if (pTier === 3) {
                    var droneBob = Math.sin(root.seaTime * 2.2) * 8;
                    for (var dSide = -1; dSide <= 1; dSide += 2) {
                        var dyDrone = dSide * 74 + (dSide === -1 ? droneBob : -droneBob);
                        ctx.save();
                        ctx.translate(-22, dyDrone);
                        // Drone plasma thruster
                        ctx.fillStyle = "#bb9af7";
                        ctx.fillRect(-16, -2, 8 + Math.random() * 5, 4);
                        // Mini stealth flying-wing silhouette
                        ctx.fillStyle = "#363e52";
                        ctx.strokeStyle = "#7dcfff";
                        ctx.lineWidth = 1.4;
                        ctx.beginPath();
                        ctx.moveTo(16, 0);
                        ctx.lineTo(-8, -20);
                        ctx.lineTo(-14, -15);
                        ctx.lineTo(-9, 0);
                        ctx.lineTo(-14, 15);
                        ctx.lineTo(-8, 20);
                        ctx.closePath();
                        ctx.fill();
                        ctx.stroke();
                        ctx.restore();
                    }
                }

                // Shield bubble when brushing past enemy planes or deflecting boss shots
                if (root.invulnerableTicks > 0) {
                    ctx.strokeStyle = (root.invulnerableTicks % 4 < 2) ? "#7dcfff" : theme.accent;
                    ctx.lineWidth = 2.5;
                    ctx.beginPath();
                    ctx.arc(0, 0, 56, 0, 6.28);
                    ctx.stroke();
                }

                ctx.restore();

                // 13. SUPERSONIC SHOCKWAVE RINGS
                for (var swi = 0; swi < root.shockwaves.length; ++swi) {
                    var sw = root.shockwaves[swi];
                    ctx.save();
                    ctx.strokeStyle = sw.color;
                    ctx.globalAlpha = Math.max(0, sw.alpha);
                    ctx.lineWidth = sw.width;
                    ctx.beginPath();
                    ctx.arc(sw.x, sw.y, sw.radius, 0, 6.28);
                    ctx.stroke();
                    ctx.restore();
                }

                // 14. DRAMATIC EXPLOSION FIREBALLS & SMOKE CLOUDS
                for (var pri = 0; pri < root.particles.length; ++pri) {
                    var p = root.particles[pri];
                    ctx.fillStyle = p.color;
                    ctx.globalAlpha = Math.max(0, p.life);
                    ctx.beginPath();
                    var rad = p.smoke ? p.size : (p.size * p.life);
                    ctx.arc(p.x, p.y, Math.max(1, rad), 0, 6.28);
                    ctx.fill();
                }
                ctx.globalAlpha = 1.0;

                // 15. FLOATING COMBAT POPUPS
                ctx.font = "bold 18px sans-serif";
                for (var ti = 0; ti < root.floatingTexts.length; ++ti) {
                    var ft = root.floatingTexts[ti];
                    ctx.fillStyle = ft.color;
                    ctx.globalAlpha = Math.max(0, ft.alpha);
                    ctx.fillText(ft.text, ft.x - 35, ft.y);
                }
                ctx.globalAlpha = 1.0;

                ctx.restore();
            }
        }

        // --- MOUSE INPUT (LEFT CLICK: MISSILE + BOMB, RIGHT CLICK: CARPET BOMB) ---
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onPositionChanged: function(mouse) {
                if (mouse.x <= 1 && mouse.y <= 1)
                    return;
                root.targetX = mouse.x;
                root.targetY = mouse.y;
            }

            onPressed: function(mouse) {
                if (mouse.x > 1 || mouse.y > 1) {
                    root.targetX = mouse.x;
                    root.targetY = mouse.y;
                }
                if (mouse.button === Qt.RightButton)
                    root.dropCarpetBombs();
                else
                    root.fireAllOrdnance();
            }
        }

        // --- HUD / HEADER BAR ---
        Rectangle {
            id: hud
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 64
            color: "#d90e101a"
            border.color: "#14ffffff"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 10

                Label {
                    text: "B-2 " + qsTr("Sky Strike")
                    font.bold: true
                    font.pixelSize: 19
                    color: theme.accent
                }

                Rectangle {
                    color: "#14ffffff"
                    radius: Math.min(4, theme.radius)
                    implicitWidth: waveLabel.implicitWidth + 14
                    implicitHeight: 30
                    Label {
                        id: waveLabel
                        anchors.centerIn: parent
                        text: qsTr("Level %1 / %2").arg(backend.level).arg(backend.maxLevels)
                        font.bold: true
                        font.pixelSize: 13
                        color: "#7dcfff"
                    }
                }

                Rectangle {
                    color: "#14ffffff"
                    radius: Math.min(4, theme.radius)
                    implicitWidth: tierLabel.implicitWidth + 14
                    implicitHeight: 30
                    Label {
                        id: tierLabel
                        anchors.centerIn: parent
                        text: "⚡ " + qsTr("Tier %1").arg(backend.weaponTier)
                        font.bold: true
                        font.pixelSize: 13
                        color: "#bb9af7"
                    }
                }

                Rectangle {
                    color: "#14ffffff"
                    radius: Math.min(4, theme.radius)
                    implicitWidth: scoreLabel.implicitWidth + 14
                    implicitHeight: 30
                    Label {
                        id: scoreLabel
                        anchors.centerIn: parent
                        text: qsTr("Score: %1").arg(backend.score)
                        font.bold: true
                        font.pixelSize: 13
                        color: "#ffd60a"
                    }
                }

                Rectangle {
                    color: "#14ffffff"
                    radius: Math.min(4, theme.radius)
                    implicitWidth: shipsLabel.implicitWidth + 14
                    implicitHeight: 30
                    Label {
                        id: shipsLabel
                        anchors.centerIn: parent
                        text: "🚢 " + qsTr("Ships: %1").arg(backend.shipsDestroyed)
                        font.bold: true
                        font.pixelSize: 13
                        color: "#ff9e64"
                    }
                }

                Rectangle {
                    color: "#14ffffff"
                    radius: Math.min(4, theme.radius)
                    implicitWidth: rescueLabel.implicitWidth + 14
                    implicitHeight: 30
                    Label {
                        id: rescueLabel
                        anchors.centerIn: parent
                        text: "🪂 " + qsTr("Rescued: %1").arg(backend.rescues)
                        font.bold: true
                        font.pixelSize: 13
                        color: "#9ece6a"
                    }
                }

                Label {
                    text: backend.statusMessage
                    font.bold: true
                    font.pixelSize: 13
                    color: theme.accent
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                }

                Button {
                    text: "🚀 " + qsTr("Fire")
                    font.bold: true
                    onClicked: root.fireAllOrdnance()
                }

                Button {
                    text: "💣 " + qsTr("Carpet Bomb")
                    font.bold: true
                    onClicked: root.dropCarpetBombs()
                }

                ToolButton {
                    text: "?"
                    font.bold: true
                    onClicked: win.helpVisible = !win.helpVisible
                }
            }
        }

        // --- LEVEL INTRO BANNER (SHOWS DISTINCT THEATER, BOSS AEROPLANE & WEAPON CAPABILITY) ---
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 80
            width: 640
            height: 94
            color: "#d916161e"
            border.color: theme.accent
            border.width: 2
            radius: theme.radius
            visible: root.levelBannerTicks > 0 && !backend.victory && !win.helpVisible
            opacity: Math.min(1.0, root.levelBannerTicks / 25.0)

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 3

                Label {
                    text: "🌍 " + qsTr("THEATER %1: %2").arg(backend.level).arg(backend.theaterName)
                    font.bold: true
                    font.pixelSize: 13
                    color: "#9ece6a"
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text: "🎯 " + qsTr("LEVEL %1 BOSS: %2 (%3 HP)").arg(backend.level).arg(backend.bossName).arg(root.bossMaxHealth)
                    font.bold: true
                    font.pixelSize: 18
                    color: "#ffd60a"
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text: "⚡ " + backend.weaponName
                    font.bold: true
                    font.pixelSize: 13
                    color: "#7dcfff"
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // --- 3-LEVEL CAMPAIGN VICTORY OVERLAY ---
        Rectangle {
            anchors.centerIn: parent
            width: 480
            height: 310
            color: "#f216161e"
            border.color: "#ffd60a"
            border.width: 3
            radius: theme.radius
            visible: backend.victory

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 14

                Label {
                    text: "🏆 " + qsTr("VICTORY! ALL 3 BOSSES DEFEATED!")
                    font.bold: true
                    font.pixelSize: 22
                    color: "#ffd60a"
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text: qsTr("Your B-2 Spirit destroyed Iron Vulture, Storm Valkyrie, and Sky Titan!")
                    font.pixelSize: 13
                    color: "#c0caf5"
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text: qsTr("Final Score: %1").arg(backend.score)
                    font.bold: true
                    font.pixelSize: 20
                    color: "#9ece6a"
                    Layout.alignment: Qt.AlignHCenter
                }

                RowLayout {
                    spacing: 18
                    Layout.alignment: Qt.AlignHCenter
                    Label { text: "✈️ " + qsTr("Bosses: %1").arg(backend.mothershipsDefeated); color: "#ff9e64"; font.bold: true }
                    Label { text: "🚢 " + qsTr("Ships: %1").arg(backend.shipsDestroyed); color: "#7dcfff"; font.bold: true }
                    Label { text: "🪂 " + qsTr("Rescued: %1").arg(backend.rescues); color: "#9ece6a"; font.bold: true }
                }

                Button {
                    text: "🚀 " + qsTr("Play 3-Level Campaign Again")
                    Material.background: theme.accent
                    Material.foreground: theme.accentForeground
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: backend.resetGame()
                }
            }
        }

        // --- PAUSE OVERLAY ---
        Rectangle {
            anchors.centerIn: parent
            width: 300
            height: 160
            color: "#1a1b26"
            border.color: theme.accent
            border.width: 2
            radius: theme.radius
            visible: backend.paused

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 16

                Label {
                    text: qsTr("Pause")
                    font.bold: true
                    font.pixelSize: 22
                    color: "#c0caf5"
                    Layout.alignment: Qt.AlignHCenter
                }

                Button {
                    text: qsTr("Resume")
                    Material.background: theme.accent
                    Material.foreground: theme.accentForeground
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: backend.togglePause()
                }
            }
        }

        // --- HELP OVERLAY (?) ---
        Rectangle {
            id: helpOverlay
            anchors.centerIn: parent
            width: Math.min(640, parent.width - 40)
            height: Math.min(480, parent.height - 40)
            color: "#16161e"
            border.color: theme.accent
            border.width: 2
            radius: theme.radius
            visible: win.helpVisible

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 16

                Label {
                    text: "✈️ " + qsTr("Sky Strike")
                    font.bold: true
                    font.pixelSize: 22
                    color: theme.accent
                    Layout.alignment: Qt.AlignHCenter
                }

                Label {
                    text: qsTr("B-2 Spirit Air & Naval Combat")
                    font.pixelSize: 14
                    color: "#a9b1d6"
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#1affffff"
                }

                ColumnLayout {
                    spacing: 12
                    Layout.fillWidth: true

                    Label {
                        text: "🖱️ " + qsTr("Mouse: Fly B-2 Spirit")
                        font.pixelSize: 14
                        color: "#c0caf5"
                    }

                    Label {
                        text: "🚀 " + qsTr("Left Click / Space: Heavy Cruise Missile + Bomb")
                        font.pixelSize: 14
                        color: "#ffd60a"
                    }

                    Label {
                        text: "💣 " + qsTr("Right Click / B: Carpet Bomb Enemy Warships!")
                        font.pixelSize: 14
                        color: "#ff9e64"
                    }

                    Label {
                        text: "🪂 " + qsTr("Save the Paratroopers!")
                        font.pixelSize: 14
                        color: "#9ece6a"
                    }

                    Label {
                        text: "🎯 " + qsTr("3 Boss Aeroplane Levels: Defeat the Boss to advance & upgrade weapons!")
                        font.pixelSize: 14
                        color: "#bb9af7"
                    }

                    Label {
                        text: "⚡ " + qsTr("Lvl 1: Heavy Missile | Lvl 2: Twin Homing Missiles | Lvl 3: Triple Missiles + Laser!")
                        font.pixelSize: 13
                        color: "#7dcfff"
                    }

                    Label {
                        text: "⌨️ Shortcuts: [Space] Fire | [B] Carpet Bomb | [1/2/3] Jump Level | [P] Pause | [?] Help | [Q] Quit"
                        font.pixelSize: 12
                        color: "#565f89"
                    }
                }

                Item { Layout.fillHeight: true }

                Button {
                    text: "LET'S FLY!"
                    Material.background: theme.accent
                    Material.foreground: theme.accentForeground
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: win.helpVisible = false
                }
            }
        }
    }
}
