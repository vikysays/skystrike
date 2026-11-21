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

    Connections {
        target: backend
        function onFireTriggerChanged() {
            root.fireAllOrdnance();
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

        // --- GIANT AIRBORNE CARRIER / MOTHERSHIP ---
        property real bossX: win.width - 220
        property real bossY: 165
        property real bossVx: -1.1
        property real bossHealth: 140
        property real bossMaxHealth: 140
        property bool bossHangarOpen: false
        property int bossSpawnTimer: 0
        property bool bossActive: true

        // --- DYNAMIC ENTITIES ---
        property var smallPlanes: []
        property var warships: []
        property var paratroopers: []
        property var missiles: []
        property var bombs: []
        property var particles: []
        property var shockwaves: []
        property var splashes: []
        property var floatingTexts: []
        property var clouds: []

        readonly property real seaLevel: win.height - 105

        function initEnvironment() {
            clouds = [
                { x: 120, y: 115, s: 1.1, speed: 0.45, dark: true },
                { x: 460, y: 175, s: 0.9, speed: 0.35, dark: false },
                { x: 780, y: 105, s: 1.3, speed: 0.55, dark: true },
                { x: 1080, y: 150, s: 1.0, speed: 0.40, dark: false }
            ];

            // Initial enemy warships on the sea (including one right below the bombing path)
            warships = [];
            spawnWarship(340, "destroyer");
            spawnWarship(640, "carrier");
            spawnWarship(940, "cruiser");

            // Initial enemy fighter planes & paratroopers so action starts immediately
            smallPlanes = [];
            spawnSmallPlane(580, 270);
            spawnSmallPlane(760, 230);
            spawnSmallPlane(880, 320);
            spawnParatrooper(520, 240);
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

        // Fires both a big Cruise Missile forward AND drops a heavy gravity bomb downward
        function fireAllOrdnance() {
            if (backend.paused) return;
            root.bombBayOpenTicks = 24;

            // 1. Heavy Cruise Missile (forward)
            missiles.push({
                x: playerX + 26,
                y: playerY + 4,
                vx: 5.5,
                ax: 0.35,
                vy: 0,
                life: 140
            });

            // 2. Heavy Gravity Bomb (drops from B-2 Spirit internal bomb bay onto planes & ships below)
            bombs.push({
                x: playerX - 4,
                y: playerY + 14,
                vx: 2.2,
                vy: 1.8,
                gravity: 0.22,
                angle: 0.4,
                life: 200
            });

            // Launch flash particles under bomb bay
            for (var i = 0; i < 6; ++i) {
                particles.push({
                    x: playerX + 10,
                    y: playerY + 10,
                    vx: -(2 + Math.random() * 3),
                    vy: (Math.random() - 0.5) * 2,
                    life: 0.9,
                    decay: 0.08,
                    color: "#ffd60a",
                    size: 5,
                    smoke: false
                });
            }
        }

        // Drops a dramatic 4-bomb carpet bombing salvo from the B-2 Spirit
        function dropCarpetBombs() {
            if (backend.paused) return;
            root.bombBayOpenTicks = 38;
            for (var b = 0; b < 4; ++b) {
                bombs.push({
                    x: playerX - 16 + b * 12,
                    y: playerY + 14 + b * 4,
                    vx: 1.6 + b * 0.45,
                    vy: 1.5 + b * 0.35,
                    gravity: 0.22,
                    angle: 0.4,
                    life: 220
                });
            }
            addFloatingText("BOMBS AWAY!", playerX, playerY - 30, "#ff9e64");
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

                // 3. Giant Mothership logic
                if (root.bossActive) {
                    root.bossX += root.bossVx;
                    root.bossY = 165 + Math.sin(root.seaTime * 0.7) * 18;

                    if (root.bossX < win.width * 0.48 && root.bossVx < 0)
                        root.bossVx = 0.85;
                    else if (root.bossX > win.width - 170 && root.bossVx > 0)
                        root.bossVx = -0.85;

                    root.bossSpawnTimer++;
                    if (root.bossSpawnTimer % 85 === 0) {
                        root.bossHangarOpen = true;
                        root.spawnSmallPlane(root.bossX - 20, root.bossY + 24);
                        if (Math.random() > 0.35) {
                            root.spawnParatrooper(root.bossX + 25, root.bossY + 28);
                            root.spawnParatrooper(root.bossX + 50, root.bossY + 28);
                        }
                    } else if (root.bossSpawnTimer % 85 === 30) {
                        root.bossHangarOpen = false;
                    }
                } else {
                    if (Math.random() < 0.009) {
                        root.bossActive = true;
                        root.bossX = win.width + 130;
                        root.bossY = 125;
                        root.bossVx = -1.1;
                        root.bossMaxHealth = 140 + backend.wave * 35;
                        root.bossHealth = root.bossMaxHealth;
                        backend.setStatusMessage(qsTr("Big Mothership Detected!"));
                    }
                }

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

                // 7. Heavy Cruise Missiles update & collision
                var nextMissiles = [];
                for (var mi = 0; mi < root.missiles.length; ++mi) {
                    var m = root.missiles[mi];
                    m.vx = Math.min(13.5, m.vx + m.ax);
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
                        color: (Math.random() > 0.35) ? "#8892a8" : "#ff9e64",
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

                    // Hit check against giant mothership
                    if (!missileHit && root.bossActive) {
                        if (m.x > root.bossX - 90 && m.x < root.bossX + 90 &&
                            m.y > root.bossY - 38 && m.y < root.bossY + 38) {
                            root.bossHealth -= 14;
                            root.spawnDramaticExplosion(m.x, m.y, 1.35, false);
                            missileHit = true;

                            if (root.bossHealth <= 0) {
                                root.bossActive = false;
                                root.spawnDramaticExplosion(root.bossX, root.bossY, 2.4, false);
                                root.spawnDramaticExplosion(root.bossX - 55, root.bossY + 12, 1.8, false);
                                root.spawnDramaticExplosion(root.bossX + 55, root.bossY - 12, 1.8, false);
                                backend.recordMothershipDefeated();
                                root.addFloatingText("MOTHERSHIP OBLITERATED! 💥", root.bossX - 40, root.bossY, "#ff4d4d");
                            }
                        }
                    }

                    if (!missileHit && m.x < win.width + 80 && m.life > 0)
                        nextMissiles.push(m);
                }
                root.missiles = nextMissiles;

                // 8. Gravity Bombs update & collision with Planes and Enemy Warships below!
                var nextBombs = [];
                for (var bi = 0; bi < root.bombs.length; ++bi) {
                    var bmb = root.bombs[bi];
                    bmb.vy += bmb.gravity;
                    bmb.x += bmb.vx;
                    bmb.y += bmb.vy;
                    bmb.angle = Math.atan2(bmb.vy, bmb.vx);
                    bmb.life--;

                    var bombHit = false;

                    // Bombs can hit enemy planes flying below the B-2 Spirit!
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

                    // Bombs hit enemy warships on the sea!
                    if (!bombHit) {
                        for (var si = 0; si < root.warships.length; ++si) {
                            var ship = root.warships[si];
                            if (ship.sinking) continue;
                            if (bmb.x > ship.x - ship.w * 0.5 && bmb.x < ship.x + ship.w * 0.5 &&
                                bmb.y >= root.seaLevel - ship.h && bmb.y <= root.seaLevel + 15) {
                                ship.hp -= 2;
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

                // 1. WARTIME STORMY SKY GRADIENT
                var skyGrad = ctx.createLinearGradient(0, 0, 0, root.seaLevel);
                skyGrad.addColorStop(0.0, "#080b12");
                skyGrad.addColorStop(0.45, "#121a2a");
                skyGrad.addColorStop(0.80, "#1d2b44");
                skyGrad.addColorStop(1.0, "#2b3a55");
                ctx.fillStyle = skyGrad;
                ctx.fillRect(0, 0, width, root.seaLevel);

                // Distant wartime horizon glow (artillery / burning fleet glow on horizon)
                var horizonGlow = ctx.createRadialGradient(width * 0.65, root.seaLevel, 10, width * 0.65, root.seaLevel, 380);
                horizonGlow.addColorStop(0.0, "rgba(255, 110, 50, 0.22)");
                horizonGlow.addColorStop(0.5, "rgba(247, 118, 142, 0.08)");
                horizonGlow.addColorStop(1.0, "rgba(0, 0, 0, 0)");
                ctx.fillStyle = horizonGlow;
                ctx.fillRect(0, root.seaLevel - 320, width, 320);

                // Searchlight beams sweeping from distant naval horizon
                ctx.save();
                ctx.fillStyle = "rgba(180, 210, 255, 0.04)";
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

                // 2. STORM CLOUDS
                for (var ci = 0; ci < root.clouds.length; ++ci) {
                    var c = root.clouds[ci];
                    ctx.fillStyle = c.dark ? "rgba(18, 24, 38, 0.55)" : "rgba(180, 195, 220, 0.08)";
                    ctx.beginPath();
                    ctx.arc(c.x, c.y, 38 * c.s, 0, 6.28);
                    ctx.arc(c.x + 34 * c.s, c.y - 12 * c.s, 45 * c.s, 0, 6.28);
                    ctx.arc(c.x + 76 * c.s, c.y, 34 * c.s, 0, 6.28);
                    ctx.fill();
                }

                // 3. BACKGROUND OCEAN SWELLS (Behind Ships)
                var seaGrad = ctx.createLinearGradient(0, root.seaLevel - 15, 0, height);
                seaGrad.addColorStop(0.0, "#13314c");
                seaGrad.addColorStop(0.4, "#0d253a");
                seaGrad.addColorStop(1.0, "#071521");
                ctx.fillStyle = seaGrad;
                ctx.fillRect(0, root.seaLevel - 8, width, height - root.seaLevel + 16);

                // Rolling back wave layer
                ctx.fillStyle = "#173c5e";
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
                ctx.fillStyle = "rgba(18, 55, 88, 0.82)";
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
                ctx.strokeStyle = "rgba(210, 235, 255, 0.28)";
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

                // 7. GIANT AIRBORNE CARRIER / MOTHERSHIP
                if (root.bossActive) {
                    ctx.save();
                    ctx.translate(root.bossX, root.bossY);

                    // Swept Heavy Wings
                    ctx.fillStyle = "#252b3b";
                    ctx.beginPath();
                    ctx.moveTo(15, -6);
                    ctx.lineTo(45, -58);
                    ctx.lineTo(-22, -58);
                    ctx.lineTo(-14, -6);
                    ctx.closePath();
                    ctx.fill();

                    ctx.beginPath();
                    ctx.moveTo(15, 6);
                    ctx.lineTo(45, 52);
                    ctx.lineTo(-22, 52);
                    ctx.lineTo(-14, 6);
                    ctx.closePath();
                    ctx.fill();

                    // Heavy Fuselage
                    ctx.fillStyle = "#363e52";
                    ctx.beginPath();
                    ctx.ellipse(0, 0, 98, 28, 0, 0, 6.28);
                    ctx.fill();

                    // 4 Heavy Turbine Nacelles + Afterburners
                    ctx.fillStyle = "#1a1e29";
                    ctx.fillRect(12, -46, 32, 10);
                    ctx.fillRect(12, 38, 32, 10);
                    ctx.fillStyle = "#ff9e64";
                    ctx.fillRect(44, -44, 10 + Math.random() * 7, 6);
                    ctx.fillRect(44, 40, 10 + Math.random() * 7, 6);

                    // Armored Cockpit Glass
                    ctx.fillStyle = "#7dcfff";
                    ctx.beginPath();
                    ctx.ellipse(-68, -5, 16, 7, -0.18, 0, 6.28);
                    ctx.fill();

                    // Illuminated Drop Hangar Bay
                    ctx.fillStyle = root.bossHangarOpen ? "#ff9e64" : "#161922";
                    ctx.fillRect(46, -9, 26, 18);

                    // Boss Health Bar
                    ctx.fillStyle = "rgba(0,0,0,0.65)";
                    ctx.fillRect(-65, -70, 130, 8);
                    ctx.fillStyle = "#ff4d4d";
                    var hpFrac = Math.max(0, root.bossHealth / root.bossMaxHealth);
                    ctx.fillRect(-65, -70, 130 * hpFrac, 8);

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

                // 12. REALISTIC B-2 SPIRIT STEALTH BOMBER (HERO PLANE)
                ctx.save();
                ctx.translate(root.playerX, root.playerY);
                ctx.rotate(root.playerTilt);

                // Concealed Dorsal Stealth Exhaust Glow (Twin recessed vents on top deck)
                var jetGlow = 12 + Math.random() * 8;
                ctx.fillStyle = "rgba(255, 158, 100, 0.85)";
                ctx.beginPath();
                ctx.moveTo(-22, -13); ctx.lineTo(-22 - jetGlow, -10); ctx.lineTo(-22, -7);
                ctx.moveTo(-22, 7);   ctx.lineTo(-22 - jetGlow, 10);  ctx.lineTo(-22, 13);
                ctx.fill();

                // Open Internal Bomb Bay Glow when releasing missiles/bombs
                if (root.bombBayOpenTicks > 0) {
                    ctx.fillStyle = "rgba(255, 180, 90, 0.55)";
                    ctx.beginPath();
                    ctx.ellipse(2, 8, 20, 9, 0, 0, 6.28);
                    ctx.fill();
                }

                // B-2 Spirit Iconic Flying-Wing Silhouette with Sawtooth "W" Trailing Edge
                var b2Grad = ctx.createLinearGradient(-40, -58, 52, 58);
                b2Grad.addColorStop(0.0, "#505a6e");
                b2Grad.addColorStop(0.45, "#373f4f");
                b2Grad.addColorStop(1.0, "#232834");
                ctx.fillStyle = b2Grad;
                ctx.strokeStyle = "#7c8aa6";
                ctx.lineWidth = 1.6;

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
                ctx.strokeStyle = "#9ab0d6";
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

                // Shield bubble when brushing past enemy planes
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
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                spacing: 14

                Label {
                    text: "B-2 " + qsTr("Sky Strike")
                    font.bold: true
                    font.pixelSize: 20
                    color: theme.accent
                }

                Rectangle {
                    color: "#14ffffff"
                    radius: Math.min(4, theme.radius)
                    implicitWidth: waveLabel.implicitWidth + 16
                    implicitHeight: 32
                    Label {
                        id: waveLabel
                        anchors.centerIn: parent
                        text: qsTr("Wave %1").arg(backend.wave)
                        font.bold: true
                        font.pixelSize: 13
                        color: "#c0caf5"
                    }
                }

                Rectangle {
                    color: "#14ffffff"
                    radius: Math.min(4, theme.radius)
                    implicitWidth: scoreLabel.implicitWidth + 16
                    implicitHeight: 32
                    Label {
                        id: scoreLabel
                        anchors.centerIn: parent
                        text: qsTr("Score: %1").arg(backend.score)
                        font.bold: true
                        font.pixelSize: 14
                        color: "#ffd60a"
                    }
                }

                Rectangle {
                    color: "#14ffffff"
                    radius: Math.min(4, theme.radius)
                    implicitWidth: shipsLabel.implicitWidth + 16
                    implicitHeight: 32
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
                    implicitWidth: rescueLabel.implicitWidth + 16
                    implicitHeight: 32
                    Label {
                        id: rescueLabel
                        anchors.centerIn: parent
                        text: "🪂 " + qsTr("Rescued: %1").arg(backend.rescues)
                        font.bold: true
                        font.pixelSize: 13
                        color: "#9ece6a"
                    }
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: backend.statusMessage
                    font.bold: true
                    font.pixelSize: 14
                    color: theme.accent
                    visible: text.length > 0
                }

                Button {
                    text: "🚀 " + qsTr("Fire Missile + Bomb")
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
                        text: "⌨️ Shortcuts: [Space] Missile+Bomb | [B] Carpet Bomb | [P] Pause | [?] Help | [Q] Quit"
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
