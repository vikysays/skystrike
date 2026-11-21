import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

ApplicationWindow {
    id: win
    width: 1024
    height: 720
    minimumWidth: 800
    minimumHeight: 600
    visible: true
    title: qsTr("Sky Strike")
    color: "#0a0c16"

    Material.theme: Material.Dark
    Material.accent: theme.accent
    Material.roundedScale: theme.radius

    property bool helpVisible: false

    Shortcut { sequence: "?"; context: Qt.ApplicationShortcut; onActivated: win.helpVisible = !win.helpVisible }
    Shortcut { sequence: "Q"; context: Qt.ApplicationShortcut; onActivated: Qt.quit() }
    Shortcut { sequence: "Space"; context: Qt.ApplicationShortcut; onActivated: root.firePlayerMissiles() }
    Shortcut { sequence: "P"; context: Qt.ApplicationShortcut; onActivated: backend.togglePause() }

    // Connect backend primary action (e.g. from tests or external trigger)
    Connections {
        target: backend
        function onFireTriggerChanged() {
            root.firePlayerMissiles();
        }
    }

    Item {
        id: root
        anchors.fill: parent
        LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
        LayoutMirroring.childrenInherit: true

        // --- GAME STATE ---
        property real playerX: 160
        property real playerY: 360
        property real targetX: 160
        property real targetY: 360
        property real playerTilt: 0
        property real shieldEnergy: 100
        property bool shieldActive: false
        property int invulnerableTicks: 0

        // Mothership (Giant Airplane)
        property real bossX: win.width + 100
        property real bossY: 140
        property real bossVx: -1.2
        property real bossHealth: 100
        property real bossMaxHealth: 100
        property bool bossHangarOpen: false
        property int bossSpawnTimer: 0
        property bool bossActive: true

        // Entities arrays
        property var smallPlanes: []
        property var paratroopers: []
        property var missiles: []
        property var particles: []
        property var floatingTexts: []

        // Cityscape building generation
        property var cityscapeFar: []
        property var cityscapeNear: []
        property var clouds: []

        function initBackground() {
            var far = [];
            var near = [];
            var w = 0;
            // Generate far skyline
            while (w < 1600) {
                var bw = 40 + Math.random() * 50;
                var bh = 140 + Math.random() * 160;
                far.push({ x: w, w: bw, h: bh, color: "#161b30" });
                w += bw - 2;
            }
            cityscapeFar = far;

            // Generate near skyline with glowing windows
            w = 0;
            while (w < 1600) {
                var bw2 = 50 + Math.random() * 70;
                var bh2 = 90 + Math.random() * 140;
                var windows = [];
                for (var r = 10; r < bh2 - 20; r += 18) {
                    for (var c = 8; c < bw2 - 12; c += 14) {
                        if (Math.random() > 0.35) {
                            windows.push({ rx: c, ry: r, on: Math.random() > 0.4 });
                        }
                    }
                }
                near.push({ x: w, w: bw2, h: bh2, color: "#20263f", windows: windows, antenna: Math.random() > 0.5 });
                w += bw2 + 4;
            }
            cityscapeNear = near;

            // Floating clouds
            clouds = [
                { x: 100, y: 80, s: 1.0, speed: 0.6 },
                { x: 450, y: 150, s: 0.8, speed: 0.4 },
                { x: 800, y: 60, s: 1.2, speed: 0.7 },
                { x: 1200, y: 110, s: 0.9, speed: 0.5 }
            ];
        }

        Component.onCompleted: {
            initBackground();
        }

        function spawnSmallPlane(originX, originY) {
            smallPlanes.push({
                x: originX,
                y: originY,
                vx: -(2.5 + Math.random() * 2.0),
                vy: (Math.random() - 0.5) * 1.5,
                angle: 0,
                hp: 1,
                timer: 0
            });
        }

        function spawnParatrooper(originX, originY) {
            paratroopers.push({
                x: originX,
                y: originY,
                vy: 0.9 + Math.random() * 0.5,
                sway: Math.random() * 6.28,
                color: ["#f7768e", "#7aa2f7", "#e0af68", "#9ece6a", "#bb9af7"][Math.floor(Math.random() * 5)]
            });
        }

        function spawnExplosion(x, y, big) {
            var count = big ? 28 : 14;
            for (var i = 0; i < count; ++i) {
                var spd = (big ? 3.0 : 2.0) * (0.5 + Math.random());
                var ang = Math.random() * 6.283;
                particles.push({
                    x: x,
                    y: y,
                    vx: Math.cos(ang) * spd,
                    vy: Math.sin(ang) * spd,
                    life: 1.0,
                    decay: 0.03 + Math.random() * 0.04,
                    color: ["#ff9e64", "#f7768e", "#ffd60a", "#7aa2f7"][Math.floor(Math.random() * 4)],
                    size: (big ? 6 : 3) + Math.random() * 4
                });
            }
        }

        function addFloatingText(text, x, y, color) {
            floatingTexts.push({
                text: text,
                x: x,
                y: y,
                vy: -1.2,
                alpha: 1.0,
                color: color || theme.accent
            });
        }

        function firePlayerMissiles() {
            if (backend.paused) return;

            // Dual wing missiles
            missiles.push({
                x: playerX + 30,
                y: playerY - 12,
                vx: 8.5,
                vy: -0.4,
                life: 120
            });
            missiles.push({
                x: playerX + 30,
                y: playerY + 12,
                vx: 8.5,
                vy: 0.4,
                life: 120
            });

            // Thruster fire spark
            for (var i = 0; i < 4; ++i) {
                particles.push({
                    x: playerX - 25,
                    y: playerY + (Math.random() - 0.5) * 8,
                    vx: -(3 + Math.random() * 3),
                    vy: (Math.random() - 0.5) * 1.5,
                    life: 1.0,
                    decay: 0.08,
                    color: "#ff9e64",
                    size: 4
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
                // 1. Player movement toward target with smooth easing
                var dx = root.targetX - root.playerX;
                var dy = root.targetY - root.playerY;
                root.playerX += dx * 0.15;
                root.playerY += dy * 0.15;
                // Tilt based on vertical velocity
                root.playerTilt = Math.max(-0.4, Math.min(0.4, dy * 0.02));

                if (root.invulnerableTicks > 0)
                    root.invulnerableTicks--;

                // 2. Cityscape scroll
                for (var ci = 0; ci < root.cityscapeFar.length; ++ci) {
                    root.cityscapeFar[ci].x -= 0.4;
                    if (root.cityscapeFar[ci].x + root.cityscapeFar[ci].w < 0) {
                        root.cityscapeFar[ci].x = win.width + Math.random() * 20;
                    }
                }
                for (var ni = 0; ni < root.cityscapeNear.length; ++ni) {
                    root.cityscapeNear[ni].x -= 0.8;
                    if (root.cityscapeNear[ni].x + root.cityscapeNear[ni].w < 0) {
                        root.cityscapeNear[ni].x = win.width + Math.random() * 20;
                    }
                }
                // Clouds scroll
                for (var cli = 0; cli < root.clouds.length; ++cli) {
                    root.clouds[cli].x -= root.clouds[cli].speed;
                    if (root.clouds[cli].x < -200)
                        root.clouds[cli].x = win.width + 50;
                }

                // 3. Giant Mothership logic
                if (root.bossActive) {
                    root.bossX += root.bossVx;
                    root.bossY += Math.sin(Date.now() / 800) * 0.4;

                    // Reverse direction when crossing
                    if (root.bossX < win.width * 0.55 && root.bossVx < 0) {
                        root.bossVx = 0.8;
                    } else if (root.bossX > win.width - 150 && root.bossVx > 0) {
                        root.bossVx = -0.8;
                    }

                    // Open hangar bay and spawn small planes
                    root.bossSpawnTimer++;
                    if (root.bossSpawnTimer % 90 === 0) {
                        root.bossHangarOpen = true;
                        root.spawnSmallPlane(root.bossX + 20, root.bossY + 25);
                        // Chance to drop soldiers
                        if (Math.random() > 0.4) {
                            root.spawnParatrooper(root.bossX + 40, root.bossY + 30);
                            root.spawnParatrooper(root.bossX + 60, root.bossY + 30);
                        }
                    } else if (root.bossSpawnTimer % 90 === 30) {
                        root.bossHangarOpen = false;
                    }
                } else {
                    // Respawn a new wave of boss
                    if (Math.random() < 0.008) {
                        root.bossActive = true;
                        root.bossX = win.width + 120;
                        root.bossY = 120 + Math.random() * 80;
                        root.bossVx = -1.2;
                        root.bossMaxHealth = 100 + backend.wave * 30;
                        root.bossHealth = root.bossMaxHealth;
                        backend.setStatusMessage(qsTr("Big Mothership Detected!"));
                    }
                }

                // 4. Small planes update
                var nextPlanes = [];
                for (var spi = 0; spi < root.smallPlanes.length; ++spi) {
                    var sp = root.smallPlanes[spi];
                    sp.x += sp.vx;
                    sp.y += sp.vy + Math.sin((sp.timer += 0.08)) * 0.9;

                    // Drop paratroopers occasionally
                    if (Math.random() < 0.012 && sp.x > 150 && sp.x < win.width - 50) {
                        root.spawnParatrooper(sp.x, sp.y + 10);
                    }

                    // Hit check with player
                    var distP = Math.hypot(sp.x - root.playerX, sp.y - root.playerY);
                    if (distP < 38) {
                        root.spawnExplosion(sp.x, sp.y, false);
                        backend.recordPlaneDestroyed();
                        root.addFloatingText("BOOM!", sp.x, sp.y, "#ff9e64");
                        root.invulnerableTicks = 45;
                        continue;
                    }

                    if (sp.x > -60)
                        nextPlanes.push(sp);
                }
                root.smallPlanes = nextPlanes;

                // 5. Paratroopers update (Float down to city, player can rescue them!)
                var nextTroopers = [];
                for (var pti = 0; pti < root.paratroopers.length; ++pti) {
                    var pt = root.paratroopers[pti];
                    pt.y += pt.vy;
                    pt.sway += 0.05;
                    pt.x += Math.sin(pt.sway) * 0.6;

                    // Rescue check by player airplane
                    var distRes = Math.hypot(pt.x - root.playerX, pt.y - root.playerY);
                    if (distRes < 45) {
                        backend.recordRescue();
                        root.addFloatingText("SAVED! ⭐", pt.x, pt.y - 20, theme.accent);
                        for (var starI = 0; starI < 8; ++starI) {
                            var sang = Math.random() * 6.28;
                            root.particles.push({
                                x: pt.x, y: pt.y,
                                vx: Math.cos(sang) * 2, vy: Math.sin(sang) * 2,
                                life: 1.0, decay: 0.04, color: "#ffd60a", size: 4
                            });
                        }
                        continue;
                    }

                    // Reached ground / cityscape safely
                    if (pt.y > win.height - 70) {
                        root.addFloatingText("TOUCHDOWN!", pt.x, win.height - 70, "#9ece6a");
                        continue;
                    }

                    nextTroopers.push(pt);
                }
                root.paratroopers = nextTroopers;

                // 6. Missiles update & collision
                var nextMissiles = [];
                for (var mi = 0; mi < root.missiles.length; ++mi) {
                    var m = root.missiles[mi];
                    m.x += m.vx;
                    m.y += m.vy;
                    m.life--;

                    // Missile smoke particles
                    if (Math.random() < 0.5) {
                        root.particles.push({
                            x: m.x - 10, y: m.y + (Math.random() - 0.5) * 3,
                            vx: -1.0, vy: (Math.random() - 0.5) * 0.5,
                            life: 0.7, decay: 0.04, color: "#e0af68", size: 3
                        });
                    }

                    var missileHit = false;

                    // Check hit with small planes
                    for (var pi = 0; pi < root.smallPlanes.length; ++pi) {
                        var spl = root.smallPlanes[pi];
                        if (Math.hypot(m.x - spl.x, m.y - spl.y) < 24) {
                            root.spawnExplosion(spl.x, spl.y, false);
                            backend.recordPlaneDestroyed();
                            root.addFloatingText("+100", spl.x, spl.y - 10, "#9ece6a");
                            root.smallPlanes.splice(pi, 1);
                            missileHit = true;
                            break;
                        }
                    }

                    // Check hit with mothership
                    if (!missileHit && root.bossActive) {
                        if (m.x > root.bossX - 80 && m.x < root.bossX + 80 &&
                            m.y > root.bossY - 35 && m.y < root.bossY + 35) {
                            root.bossHealth -= 4;
                            root.spawnExplosion(m.x, m.y, false);
                            missileHit = true;

                            if (root.bossHealth <= 0) {
                                root.bossActive = false;
                                root.spawnExplosion(root.bossX, root.bossY, true);
                                root.spawnExplosion(root.bossX - 40, root.bossY + 10, true);
                                root.spawnExplosion(root.bossX + 40, root.bossY - 10, true);
                                backend.recordMothershipDefeated();
                                root.addFloatingText("MEGA BOOM! 💥", root.bossX, root.bossY, "#ff7a93");
                            }
                        }
                    }

                    if (!missileHit && m.x < win.width + 50 && m.life > 0)
                        nextMissiles.push(m);
                }
                root.missiles = nextMissiles;

                // 7. Particles update
                var nextParticles = [];
                for (var pri = 0; pri < root.particles.length; ++pri) {
                    var p = root.particles[pri];
                    p.x += p.vx;
                    p.y += p.vy;
                    p.life -= p.decay;
                    if (p.life > 0)
                        nextParticles.push(p);
                }
                root.particles = nextParticles;

                // 8. Floating texts update
                var nextTexts = [];
                for (var ti = 0; ti < root.floatingTexts.length; ++ti) {
                    var ft = root.floatingTexts[ti];
                    ft.y += ft.vy;
                    ft.alpha -= 0.02;
                    if (ft.alpha > 0)
                        nextTexts.push(ft);
                }
                root.floatingTexts = nextTexts;

                gameCanvas.requestPaint();
            }
        }

        // --- DRAWING CANVAS ---
        Canvas {
            id: gameCanvas
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                // 1. SKY GRADIENT
                var skyGrad = ctx.createLinearGradient(0, 0, 0, height);
                skyGrad.addColorStop(0.0, "#0b0d1b");
                skyGrad.addColorStop(0.45, "#151930");
                skyGrad.addColorStop(0.75, "#1e223d");
                skyGrad.addColorStop(1.0, "#2c2642");
                ctx.fillStyle = skyGrad;
                ctx.fillRect(0, 0, width, height);

                // Stars
                ctx.fillStyle = "#ffffff";
                for (var si = 0; si < 40; ++si) {
                    var sx = ((si * 137.5) % width);
                    var sy = ((si * 93.1) % (height * 0.55));
                    ctx.fillRect(sx, sy, 1.5, 1.5);
                }

                // 2. CLOUDS
                ctx.fillStyle = "rgba(255, 255, 255, 0.08)";
                for (var ci = 0; ci < root.clouds.length; ++ci) {
                    var c = root.clouds[ci];
                    ctx.beginPath();
                    ctx.arc(c.x, c.y, 35 * c.s, 0, 6.28);
                    ctx.arc(c.x + 30 * c.s, c.y - 10 * c.s, 40 * c.s, 0, 6.28);
                    ctx.arc(c.x + 70 * c.s, c.y, 30 * c.s, 0, 6.28);
                    ctx.fill();
                }

                // 3. FAR CITYSCAPE
                for (var fi = 0; fi < root.cityscapeFar.length; ++fi) {
                    var fb = root.cityscapeFar[fi];
                    ctx.fillStyle = fb.color;
                    ctx.fillRect(fb.x, height - fb.h, fb.w, fb.h);
                }

                // 4. NEAR CITYSCAPE WITH GLOWING WINDOWS
                for (var ni = 0; ni < root.cityscapeNear.length; ++ni) {
                    var nb = root.cityscapeNear[ni];
                    ctx.fillStyle = nb.color;
                    ctx.fillRect(nb.x, height - nb.h, nb.w, nb.h);

                    // Antenna on roof
                    if (nb.antenna) {
                        ctx.strokeStyle = "#565f89";
                        ctx.lineWidth = 2;
                        ctx.beginPath();
                        ctx.moveTo(nb.x + nb.w * 0.5, height - nb.h);
                        ctx.lineTo(nb.x + nb.w * 0.5, height - nb.h - 18);
                        ctx.stroke();

                        // Blinking red beacon
                        ctx.fillStyle = (Math.floor(Date.now() / 400) % 2 === 0) ? "#f7768e" : "#565f89";
                        ctx.beginPath();
                        ctx.arc(nb.x + nb.w * 0.5, height - nb.h - 18, 3, 0, 6.28);
                        ctx.fill();
                    }

                    // Windows
                    for (var wi = 0; wi < nb.windows.length; ++wi) {
                        var winObj = nb.windows[wi];
                        ctx.fillStyle = winObj.on ? "#ffd60a" : "rgba(255,255,255,0.06)";
                        ctx.fillRect(nb.x + winObj.rx, height - nb.h + winObj.ry, 6, 9);
                    }
                }

                // 5. GIANT MOTHERSHIP AIRPLANE
                if (root.bossActive) {
                    ctx.save();
                    ctx.translate(root.bossX, root.bossY);

                    // Main fuselage (Facing Left)
                    ctx.fillStyle = "#343b58";
                    ctx.beginPath();
                    ctx.ellipse(0, 0, 95, 30, 0, 0, 6.28);
                    ctx.fill();

                    // Wings
                    ctx.fillStyle = "#24283b";
                    ctx.beginPath();
                    ctx.moveTo(20, -5);
                    ctx.lineTo(40, -55);
                    ctx.lineTo(-20, -55);
                    ctx.lineTo(-10, -5);
                    ctx.closePath();
                    ctx.fill();

                    // Lower wing
                    ctx.beginPath();
                    ctx.moveTo(20, 5);
                    ctx.lineTo(40, 48);
                    ctx.lineTo(-20, 48);
                    ctx.lineTo(-10, 5);
                    ctx.closePath();
                    ctx.fill();

                    // Engines with jet glow
                    ctx.fillStyle = "#1a1b26";
                    ctx.fillRect(10, -45, 30, 10);
                    ctx.fillRect(10, 38, 30, 10);
                    ctx.fillStyle = "#ff9e64";
                    ctx.fillRect(40, -43, 8 + Math.random() * 6, 6);
                    ctx.fillRect(40, 40, 8 + Math.random() * 6, 6);

                    // Cockpit windshield (Left side)
                    ctx.fillStyle = "#7dcfff";
                    ctx.beginPath();
                    ctx.ellipse(-65, -6, 16, 8, -0.2, 0, 6.28);
                    ctx.fill();

                    // Hangar Bay door at rear (Flashing yellow when releasing small planes!)
                    ctx.fillStyle = root.bossHangarOpen ? "#ff9e64" : "#1a1b26";
                    ctx.fillRect(50, -8, 22, 16);

                    // Boss Health Bar
                    ctx.fillStyle = "rgba(0,0,0,0.6)";
                    ctx.fillRect(-60, -65, 120, 8);
                    ctx.fillStyle = theme.accent;
                    var hpFrac = Math.max(0, root.bossHealth / root.bossMaxHealth);
                    ctx.fillRect(-60, -65, 120 * hpFrac, 8);

                    ctx.restore();
                }

                // 6. SMALL ENEMY PLANES
                for (var spi = 0; spi < root.smallPlanes.length; ++spi) {
                    var sp = root.smallPlanes[spi];
                    ctx.save();
                    ctx.translate(sp.x, sp.y);

                    // Small Jet (Facing Left)
                    ctx.fillStyle = "#f7768e";
                    ctx.beginPath();
                    ctx.moveTo(-18, 0);
                    ctx.lineTo(12, -10);
                    ctx.lineTo(8, 0);
                    ctx.lineTo(12, 10);
                    ctx.closePath();
                    ctx.fill();

                    // Cockpit
                    ctx.fillStyle = "#c0caf5";
                    ctx.beginPath();
                    ctx.arc(-4, -1, 3, 0, 6.28);
                    ctx.fill();

                    // Jet flame
                    ctx.fillStyle = "#ff9e64";
                    ctx.fillRect(10, -2, 5 + Math.random() * 4, 4);

                    ctx.restore();
                }

                // 7. PARATROOPERS JUMPING OUT
                for (var pti = 0; pti < root.paratroopers.length; ++pti) {
                    var pt = root.paratroopers[pti];
                    ctx.save();
                    ctx.translate(pt.x, pt.y);

                    // Parachute canopy
                    ctx.fillStyle = pt.color;
                    ctx.beginPath();
                    ctx.arc(0, -18, 16, 3.14, 0);
                    ctx.closePath();
                    ctx.fill();

                    // Suspension lines
                    ctx.strokeStyle = "rgba(255,255,255,0.5)";
                    ctx.lineWidth = 1;
                    ctx.beginPath();
                    ctx.moveTo(-14, -18); ctx.lineTo(0, 0);
                    ctx.moveTo(-7, -18);  ctx.lineTo(0, 0);
                    ctx.moveTo(7, -18);   ctx.lineTo(0, 0);
                    ctx.moveTo(14, -18);  ctx.lineTo(0, 0);
                    ctx.stroke();

                    // Soldier figure
                    ctx.fillStyle = "#c0caf5";
                    ctx.beginPath();
                    ctx.arc(0, 3, 3.5, 0, 6.28); // Head
                    ctx.fill();
                    ctx.fillStyle = "#414868";
                    ctx.fillRect(-2.5, 6, 5, 7); // Body

                    ctx.restore();
                }

                // 8. MISSILES
                for (var mi = 0; mi < root.missiles.length; ++mi) {
                    var m = root.missiles[mi];
                    ctx.save();
                    ctx.translate(m.x, m.y);

                    // Missile body
                    ctx.fillStyle = "#ffffff";
                    ctx.fillRect(-10, -2.5, 16, 5);
                    // Nose cone
                    ctx.fillStyle = "#f7768e";
                    ctx.beginPath();
                    ctx.moveTo(6, -2.5);
                    ctx.lineTo(13, 0);
                    ctx.lineTo(6, 2.5);
                    ctx.closePath();
                    ctx.fill();
                    // Thruster flame
                    ctx.fillStyle = "#ff9e64";
                    ctx.fillRect(-16, -1.5, 6, 3);

                    ctx.restore();
                }

                // 9. HERO PLAYER AEROPLANE
                ctx.save();
                ctx.translate(root.playerX, root.playerY);
                ctx.rotate(root.playerTilt);

                // Thruster Flames
                var flm = 8 + Math.random() * 8;
                ctx.fillStyle = "#ff9e64";
                ctx.beginPath();
                ctx.moveTo(-28, -5); ctx.lineTo(-28 - flm, 0); ctx.lineTo(-28, 5);
                ctx.closePath();
                ctx.fill();
                ctx.fillStyle = "#ffd60a";
                ctx.beginPath();
                ctx.moveTo(-28, -2.5); ctx.lineTo(-28 - flm * 0.6, 0); ctx.lineTo(-28, 2.5);
                ctx.closePath();
                ctx.fill();

                // Wings
                ctx.fillStyle = "#414868";
                ctx.beginPath();
                ctx.moveTo(-10, -28);
                ctx.lineTo(14, 0);
                ctx.lineTo(-10, 28);
                ctx.lineTo(-18, 22);
                ctx.lineTo(-12, 0);
                ctx.lineTo(-18, -22);
                ctx.closePath();
                ctx.fill();

                // Fuselage
                ctx.fillStyle = theme.accent;
                ctx.beginPath();
                ctx.moveTo(34, 0);
                ctx.lineTo(-26, -9);
                ctx.lineTo(-24, 0);
                ctx.lineTo(-26, 9);
                ctx.closePath();
                ctx.fill();

                // Cockpit Canopy Glass
                ctx.fillStyle = "#7dcfff";
                ctx.beginPath();
                ctx.ellipse(4, 0, 10, 4, 0, 0, 6.28);
                ctx.fill();

                // Wing Missiles Ready
                ctx.fillStyle = "#f7768e";
                ctx.fillRect(-4, -18, 12, 3);
                ctx.fillRect(-4, 15, 12, 3);

                // Invulnerability / Shield bubble
                if (root.invulnerableTicks > 0) {
                    ctx.strokeStyle = (root.invulnerableTicks % 4 < 2) ? "#7dcfff" : theme.accent;
                    ctx.lineWidth = 2.5;
                    ctx.beginPath();
                    ctx.arc(0, 0, 42, 0, 6.28);
                    ctx.stroke();
                }

                ctx.restore();

                // 10. PARTICLES & EXPLOSIONS
                for (var pri = 0; pri < root.particles.length; ++pri) {
                    var p = root.particles[pri];
                    ctx.fillStyle = p.color;
                    ctx.globalAlpha = Math.max(0, p.life);
                    ctx.beginPath();
                    ctx.arc(p.x, p.y, p.size * p.life, 0, 6.28);
                    ctx.fill();
                }
                ctx.globalAlpha = 1.0;

                // 11. FLOATING TEXTS ("SAVED!", "BOOM!")
                ctx.font = "bold 18px sans-serif";
                for (var ti = 0; ti < root.floatingTexts.length; ++ti) {
                    var ft = root.floatingTexts[ti];
                    ctx.fillStyle = ft.color;
                    ctx.globalAlpha = Math.max(0, ft.alpha);
                    ctx.fillText(ft.text, ft.x - 25, ft.y);
                }
                ctx.globalAlpha = 1.0;
            }
        }

        // --- MOUSE INPUT (PRIMARY FOR 6-YEAR-OLD) ---
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onPositionChanged: function(mouse) {
                root.targetX = mouse.x;
                root.targetY = mouse.y;
            }

            onPressed: function(mouse) {
                root.targetX = mouse.x;
                root.targetY = mouse.y;
                root.firePlayerMissiles();
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
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 20

                // Title
                Label {
                    text: qsTr("Sky Strike")
                    font.bold: true
                    font.pixelSize: 20
                    color: theme.accent
                }

                // Wave Badge
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

                // Score Badge
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

                // Rescues Badge
                Rectangle {
                    color: "#14ffffff"
                    radius: Math.min(4, theme.radius)
                    implicitWidth: rescueLabel.implicitWidth + 16
                    implicitHeight: 32
                    Label {
                        id: rescueLabel
                        anchors.centerIn: parent
                        text: qsTr("Rescued: %1").arg(backend.rescues)
                        font.bold: true
                        font.pixelSize: 13
                        color: "#9ece6a"
                    }
                }

                Item { Layout.fillWidth: true }

                // Status cheer text
                Label {
                    text: backend.statusMessage
                    font.bold: true
                    font.pixelSize: 14
                    color: theme.accent
                    visible: text.length > 0
                }

                // Fire Missiles Button (big touch/mouse target)
                Button {
                    text: "🚀 " + qsTr("Click or Space: Launch Missiles")
                    Material.background: theme.accent
                    Material.foreground: theme.accentForeground
                    font.bold: true
                    onClicked: root.firePlayerMissiles()
                }

                // Help Button
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
            width: Math.min(620, parent.width - 40)
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
                    text: qsTr("City Defense Aeroplane Action")
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
                        text: "🖱️ " + qsTr("Mouse: Fly Aeroplane") + " — " + qsTr("Move to fly anywhere!")
                        font.pixelSize: 14
                        color: "#c0caf5"
                    }

                    Label {
                        text: "🚀 " + qsTr("Click or Space: Launch Missiles") + " — " + qsTr("Blast small planes and mothership!")
                        font.pixelSize: 14
                        color: "#c0caf5"
                    }

                    Label {
                        text: "🪂 " + qsTr("Save the Paratroopers!") + " — " + qsTr("Fly close to jumping soldiers to rescue them!")
                        font.pixelSize: 14
                        color: "#9ece6a"
                    }

                    Label {
                        text: "👾 " + qsTr("Big Mothership Detected!") + " — " + qsTr("Watch the hangar open and launch small planes!")
                        font.pixelSize: 14
                        color: "#f7768e"
                    }

                    Label {
                        text: "⌨️ Shortcuts: [Space] Fire Missiles | [P] Pause | [?] Toggle Help | [Q] Quit"
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
