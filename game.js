/* --- RESOURCE LOADER --- */
const assets = {
    images: {},
    load(name, src) {
        return new Promise((resolve) => {
            const img = new Image();
            img.src = src;
            img.onload = () => {
                this.images[name] = img;
                resolve(img);
            };
            img.onerror = () => {
                console.warn('Image load failed:', src);
                resolve(null);
            };
        });
    }
};

// Game Configuration & Stats Manager (Player and Enemy stats)
const GameStats = {
    player: {
        maxHp: 100,
        speed: 180,
        attack: 25,
        attackRate: 0.8,
        magnet: 110
    },
    mobs: {
        slime: { name: 'Slime', hp: 30, speed: 70, atk: 6, exp: 1, sprite: 'slime_walk', frames: 6 },
        bat: { name: 'Bat', hp: 20, speed: 135, atk: 8, exp: 2, sprite: 'bat_fly', frames: 6 },
        skeleton: { name: 'Skeleton', hp: 75, speed: 80, atk: 15, exp: 3, sprite: 'skel_walk', frames: 8, attackSprite: 'skel_attack', attackFrames: 6, attackRange: 65, attackInterval: 1.0 },
        orc: { name: 'Orc', hp: 150, speed: 60, atk: 24, exp: 6, sprite: 'orc_walk', frames: 8 },
        werewolf: { name: 'Werewolf', hp: 260, speed: 105, atk: 32, exp: 12, sprite: 'werewolf_walk', frames: 8 },
        elite_orc: { name: 'Elite Orc', hp: 450, speed: 65, atk: 45, exp: 25, sprite: 'elite_orc_walk', frames: 8 }
    }
};

function initStatConfigUI() {
    const toggle = document.getElementById('stat-panel-toggle');
    const panel = document.getElementById('stat-panel');
    const closeBtn = document.getElementById('stat-close-btn');

    toggle.onclick = () => panel.classList.toggle('hidden');
    closeBtn.onclick = () => panel.classList.add('hidden');

    const bindInput = (id, obj, key) => {
        const el = document.getElementById(id);
        if (el) {
            el.addEventListener('input', (e) => {
                const val = parseFloat(e.target.value);
                if (!isNaN(val)) {
                    obj[key] = val;
                    if (game && game.player && key === 'maxHp') {
                        const diff = val - game.player.maxHp;
                        game.player.maxHp = val;
                        game.player.hp = Math.min(game.player.maxHp, game.player.hp + Math.max(0, diff));
                    }
                }
            });
        }
    };

    bindInput('cfg-player-hp', GameStats.player, 'maxHp');
    bindInput('cfg-player-speed', GameStats.player, 'speed');
    bindInput('cfg-player-atk', GameStats.player, 'attack');
    bindInput('cfg-player-rate', GameStats.player, 'attackRate');
    bindInput('cfg-player-magnet', GameStats.player, 'magnet');

    // 슬라임 (첫 웨이브 기본 스탯 유지)
    bindInput('cfg-mob-slime-hp', GameStats.mobs.slime, 'hp');
    bindInput('cfg-mob-slime-speed', GameStats.mobs.slime, 'speed');
    bindInput('cfg-mob-slime-atk', GameStats.mobs.slime, 'atk');
    bindInput('cfg-mob-slime-exp', GameStats.mobs.slime, 'exp');

    // 박쥐 (Wave 2)
    bindInput('cfg-mob-bat-hp', GameStats.mobs.bat, 'hp');
    bindInput('cfg-mob-bat-speed', GameStats.mobs.bat, 'speed');
    bindInput('cfg-mob-bat-atk', GameStats.mobs.bat, 'atk');
    bindInput('cfg-mob-bat-exp', GameStats.mobs.bat, 'exp');

    // 스켈레톤 (Wave 3)
    bindInput('cfg-mob-skel-hp', GameStats.mobs.skeleton, 'hp');
    bindInput('cfg-mob-skel-speed', GameStats.mobs.skeleton, 'speed');
    bindInput('cfg-mob-skel-atk', GameStats.mobs.skeleton, 'atk');
    bindInput('cfg-mob-skel-exp', GameStats.mobs.skeleton, 'exp');

    // 오크 (Wave 4)
    bindInput('cfg-mob-orc-hp', GameStats.mobs.orc, 'hp');
    bindInput('cfg-mob-orc-speed', GameStats.mobs.orc, 'speed');
    bindInput('cfg-mob-orc-atk', GameStats.mobs.orc, 'atk');
    bindInput('cfg-mob-orc-exp', GameStats.mobs.orc, 'exp');

    // 늑대인간 (Wave 5)
    bindInput('cfg-mob-werewolf-hp', GameStats.mobs.werewolf, 'hp');
    bindInput('cfg-mob-werewolf-speed', GameStats.mobs.werewolf, 'speed');
    bindInput('cfg-mob-werewolf-atk', GameStats.mobs.werewolf, 'atk');
    bindInput('cfg-mob-werewolf-exp', GameStats.mobs.werewolf, 'exp');

    // 엘리트 오크 (Wave 6+)
    bindInput('cfg-mob-elite-hp', GameStats.mobs.elite_orc, 'hp');
    bindInput('cfg-mob-elite-speed', GameStats.mobs.elite_orc, 'speed');
    bindInput('cfg-mob-elite-atk', GameStats.mobs.elite_orc, 'atk');
    bindInput('cfg-mob-elite-exp', GameStats.mobs.elite_orc, 'exp');
}

/* --- SKILL DEFINITIONS --- */
const SKILLS_DB = {
    sword_slash: {
        id: 'sword_slash',
        name: '기사 검기 (Slash)',
        icon: '⚔️',
        desc: '전방으로 강력한 검기를 날려 적들을 관통합니다.',
        maxLevel: 5,
        level: 1,
        cooldown: 0.8,
        timer: 0
    },
    holy_orbit: {
        id: 'holy_orbit',
        name: '수호 방패 (Orbit)',
        icon: '🛡️',
        desc: '기사 주변을 회전하는 방패가 근접한 적에게 피해를 줍니다.',
        maxLevel: 5,
        level: 0,
        count: 1
    },
    lightning: {
        id: 'lightning',
        name: '낙뢰 폭격 (Lightning)',
        icon: '⚡',
        desc: '주변 무작위 적에게 강력한 벼락을 내리꽂습니다.',
        maxLevel: 5,
        level: 0,
        cooldown: 2.0,
        timer: 0
    },
    arrow_rain: {
        id: 'arrow_rain',
        name: '화살 폭풍 (Arrows)',
        icon: '🏹',
        desc: '전방향으로 화살을 일제히 난사합니다.',
        maxLevel: 5,
        level: 0,
        cooldown: 1.6,
        timer: 0
    },
    speed_up: {
        id: 'speed_up',
        name: '신속의 장화 (Speed)',
        icon: '👢',
        desc: '이동 속도가 15% 증가합니다.',
        maxLevel: 5,
        level: 0
    },
    max_hp_up: {
        id: 'max_hp_up',
        name: '거인의 심장 (Health)',
        icon: '💖',
        desc: '최대 체력이 +25 증가하며 즉시 35의 체력을 회복합니다.',
        maxLevel: 5,
        level: 0
    },
    heal_aura: {
        id: 'heal_aura',
        name: '성스러운 재생 (Regen)',
        icon: '✨',
        desc: '1초마다 체력을 3씩 지속적으로 회복합니다.',
        maxLevel: 5,
        level: 0,
        timer: 0
    }
};

/* --- WEB AUDIO SOUND EFFECTS --- */
const AudioSys = {
    ctx: null,
    init() {
        if (!this.ctx) {
            this.ctx = new (window.AudioContext || window.webkitAudioContext)();
        }
    },
    playHit() {
        if (!this.ctx) return;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(140, this.ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(40, this.ctx.currentTime + 0.1);
        gain.gain.setValueAtTime(0.12, this.ctx.currentTime);
        gain.gain.linearRampToValueAtTime(0.01, this.ctx.currentTime + 0.1);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start();
        osc.stop(this.ctx.currentTime + 0.1);
    },
    playSlash() {
        if (!this.ctx) return;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(450, this.ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(120, this.ctx.currentTime + 0.12);
        gain.gain.setValueAtTime(0.18, this.ctx.currentTime);
        gain.gain.linearRampToValueAtTime(0.01, this.ctx.currentTime + 0.12);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start();
        osc.stop(this.ctx.currentTime + 0.12);
    },
    playExp() {
        if (!this.ctx) return;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(600, this.ctx.currentTime);
        osc.frequency.setValueAtTime(900, this.ctx.currentTime + 0.05);
        gain.gain.setValueAtTime(0.08, this.ctx.currentTime);
        gain.gain.linearRampToValueAtTime(0.01, this.ctx.currentTime + 0.1);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start();
        osc.stop(this.ctx.currentTime + 0.1);
    },
    playLevelUp() {
        if (!this.ctx) return;
        const notes = [440, 554, 659, 880];
        notes.forEach((freq, idx) => {
            const osc = this.ctx.createOscillator();
            const gain = this.ctx.createGain();
            osc.type = 'triangle';
            osc.frequency.setValueAtTime(freq, this.ctx.currentTime + idx * 0.08);
            gain.gain.setValueAtTime(0.2, this.ctx.currentTime + idx * 0.08);
            gain.gain.linearRampToValueAtTime(0.01, this.ctx.currentTime + idx * 0.08 + 0.2);
            osc.connect(gain);
            gain.connect(this.ctx.destination);
            osc.start(this.ctx.currentTime + idx * 0.08);
            osc.stop(this.ctx.currentTime + idx * 0.08 + 0.2);
        });
    },
    playLightning() {
        if (!this.ctx) return;
        const osc = this.ctx.createOscillator();
        const gain = this.ctx.createGain();
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(320, this.ctx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(70, this.ctx.currentTime + 0.25);
        gain.gain.setValueAtTime(0.2, this.ctx.currentTime);
        gain.gain.linearRampToValueAtTime(0.01, this.ctx.currentTime + 0.25);
        osc.connect(gain);
        gain.connect(this.ctx.destination);
        osc.start();
        osc.stop(this.ctx.currentTime + 0.25);
    }
};

/* --- SURVIVOR GAME CORE --- */
class SurvivorGame {
    constructor() {
        this.canvas = document.getElementById('gameCanvas');
        this.ctx = this.canvas.getContext('2d');
        this.resize();
        window.addEventListener('resize', () => this.resize());

        this.keys = {};
        window.addEventListener('keydown', (e) => {
            AudioSys.init();
            const k = e.key.toLowerCase();
            this.keys[k] = true;
            if (['w', 'a', 's', 'd', 'arrowup', 'arrowleft', 'arrowdown', 'arrowright'].includes(k)) {
                e.preventDefault();
            }
        });
        window.addEventListener('keyup', (e) => {
            this.keys[e.key.toLowerCase()] = false;
        });

        this.mousePos = { x: 0, y: 0 };
        window.addEventListener('mousemove', (e) => {
            const rect = this.canvas.getBoundingClientRect();
            this.mousePos.x = e.clientX - rect.left;
            this.mousePos.y = e.clientY - rect.top;
        });

        document.getElementById('btn-restart').onclick = () => this.reset();

        this.reset();
    }

    resize() {
        const container = document.getElementById('game-container');
        this.canvas.width = container.clientWidth;
        this.canvas.height = container.clientHeight;
    }

    reset() {
        this.isPaused = false;
        this.isGameOver = false;
        this.gameTime = 0;
        this.killCount = 0;

        // Player State (Knight)
        this.player = {
            x: 0,
            y: 0,
            hp: GameStats.player.maxHp,
            maxHp: GameStats.player.maxHp,
            level: 1,
            exp: 0,
            nextExp: 10,
            facing: 1, // 1: right, -1: left
            lastMoveDir: { x: 1, y: 0 },
            state: 'idle',
            animTime: 0,
            invincibleTimer: 0
        };

        this.skills = JSON.parse(JSON.stringify(SKILLS_DB));

        this.mobs = [];
        this.gems = [];
        this.projectiles = [];
        this.particles = [];
        this.damageTexts = [];

        this.spawnTimer = 0;
        this.orbitAngle = 0;

        document.getElementById('levelup-modal').classList.add('hidden');
        document.getElementById('gameover-modal').classList.add('hidden');
        this.updateSkillsHUD();
        this.updateHUD();
    }

    update(dt) {
        if (this.isPaused || this.isGameOver) return;

        this.gameTime += dt;

        // 1. WASD & Arrow Key Movement (8 Directions)
        let dx = 0;
        let dy = 0;
        if (this.keys['w'] || this.keys['arrowup']) dy -= 1;
        if (this.keys['s'] || this.keys['arrowdown']) dy += 1;
        if (this.keys['a'] || this.keys['arrowleft']) dx -= 1;
        if (this.keys['d'] || this.keys['arrowright']) dx += 1;

        const isMoving = dx !== 0 || dy !== 0;
        if (isMoving) {
            const len = Math.hypot(dx, dy);
            const normX = dx / len;
            const normY = dy / len;
            this.player.lastMoveDir = { x: normX, y: normY };

            let spd = GameStats.player.speed;
            if (this.skills.speed_up.level > 0) {
                spd *= (1 + this.skills.speed_up.level * 0.15);
            }
            this.player.x += normX * spd * dt;
            this.player.y += normY * spd * dt;

            if (dx > 0) this.player.facing = 1;
            else if (dx < 0) this.player.facing = -1;

            this.player.state = 'walk';
        } else {
            this.player.state = 'idle';
        }

        this.player.animTime += dt;
        if (this.player.invincibleTimer > 0) this.player.invincibleTimer -= dt;

        // Passive Health Regen
        if (this.skills.heal_aura.level > 0) {
            this.skills.heal_aura.timer = (this.skills.heal_aura.timer || 0) + dt;
            if (this.skills.heal_aura.timer >= 1.0) {
                this.skills.heal_aura.timer = 0;
                const healAmt = this.skills.heal_aura.level * 3;
                if (this.player.hp < this.player.maxHp) {
                    this.player.hp = Math.min(this.player.maxHp, this.player.hp + healAmt);
                    this.addDamageText(this.player.x, this.player.y - 30, `+${healAmt}`, '#4ade80');
                }
            }
        }

        // 2. Active Skills Execution
        this.updateSkills(dt);

        // 3. Spawning Mobs
        this.spawnTimer += dt;
        const spawnInterval = Math.max(0.3, 1.8 - Math.min(1.4, this.gameTime / 60 * 0.35));
        if (this.spawnTimer >= spawnInterval) {
            this.spawnTimer = 0;
            this.spawnMonster();
        }

        // 4. Update Mobs Movement & Attack
        const p = this.player;
        for (let i = this.mobs.length - 1; i >= 0; i--) {
            const mob = this.mobs[i];
            mob.animTime += dt;
            if (mob.attackCooldown > 0) mob.attackCooldown -= dt;

            const mdx = p.x - mob.x;
            const mdy = p.y - mob.y;
            const dist = Math.hypot(mdx, mdy);
            if (dist > 0.001) {
                mob.facing = mdx >= 0 ? 1 : -1;
            }

            // 공격 모션 진입 체크 (스켈레톤 등)
            if (mob.attackSprite && dist <= mob.attackRange && mob.attackCooldown <= 0 && mob.state !== 'attack') {
                mob.state = 'attack';
                mob.attackTimer = 0;
                mob.hasDamaged = false;
            }

            if (mob.state === 'attack') {
                mob.attackTimer = (mob.attackTimer || 0) + dt;
                const curFrame = Math.floor(mob.attackTimer * 9);
                if (curFrame >= mob.attackFrames) {
                    mob.state = 'walk';
                    mob.attackCooldown = mob.attackInterval || 1.0;
                } else {
                    // 공격 타격 프레임 (3번째 프레임)에서 데미지 적용
                    if (curFrame >= 3 && !mob.hasDamaged) {
                        mob.hasDamaged = true;
                        if (dist <= mob.attackRange + 25 && p.invincibleTimer <= 0) {
                            p.hp -= mob.atk;
                            p.invincibleTimer = 0.5;
                            AudioSys.playHit();
                            this.addDamageText(p.x, p.y - 35, `-${mob.atk}`, '#ef4444');
                            this.createBloodParticles(p.x, p.y, '#dc2626');

                            if (p.hp <= 0) {
                                p.hp = 0;
                                this.triggerGameOver();
                                return;
                            }
                        }
                    }
                }
            } else {
                if (dist > 0.1) {
                    mob.x += (mdx / dist) * mob.speed * dt;
                    mob.y += (mdy / dist) * mob.speed * dt;
                }

                // Player Collision Check (일반 접촉 공격)
                if (dist < 30 && p.invincibleTimer <= 0) {
                    p.hp -= mob.atk;
                    p.invincibleTimer = 0.5;
                    AudioSys.playHit();
                    this.addDamageText(p.x, p.y - 35, `-${mob.atk}`, '#ef4444');
                    this.createBloodParticles(p.x, p.y, '#dc2626');

                    if (p.hp <= 0) {
                        p.hp = 0;
                        this.triggerGameOver();
                        return;
                    }
                }
            }
        }

        // 5. Update Projectiles & Hits
        for (let i = this.projectiles.length - 1; i >= 0; i--) {
            const proj = this.projectiles[i];
            proj.life -= dt;

            if (proj.type === 'orbit') {
                proj.x = p.x + Math.cos(proj.angle) * 75;
                proj.y = p.y + Math.sin(proj.angle) * 75;
            } else {
                proj.x += proj.vx * dt;
                proj.y += proj.vy * dt;
            }

            for (let j = this.mobs.length - 1; j >= 0; j--) {
                const mob = this.mobs[j];
                const dist = Math.hypot(proj.x - mob.x, proj.y - mob.y);
                if (dist < proj.radius + 20) {
                    if (!proj.hitMobs) proj.hitMobs = new Set();
                    if (!proj.hitMobs.has(mob)) {
                        proj.hitMobs.add(mob);
                        mob.hp -= proj.damage;
                        AudioSys.playHit();
                        this.addDamageText(mob.x, mob.y - 25, `${Math.round(proj.damage)}`, '#f59e0b');
                        this.createBloodParticles(mob.x, mob.y, '#f59e0b');

                        if (mob.hp <= 0) {
                            this.killMob(j);
                        }

                        if (proj.pierce !== undefined) {
                            proj.pierce--;
                            if (proj.pierce <= 0) {
                                proj.life = 0;
                                break;
                            }
                        }
                    }
                }
            }

            if (proj.life <= 0) {
                this.projectiles.splice(i, 1);
            }
        }

        // 6. EXP Magnet & Gem Collection
        const magnetDist = GameStats.player.magnet;
        for (let i = this.gems.length - 1; i >= 0; i--) {
            const gem = this.gems[i];
            const gdx = p.x - gem.x;
            const gdy = p.y - gem.y;
            const dist = Math.hypot(gdx, gdy);

            if (dist < magnetDist) {
                const pullSpeed = 400;
                gem.x += (gdx / dist) * pullSpeed * dt;
                gem.y += (gdy / dist) * pullSpeed * dt;
            }

            if (dist < 26) {
                p.exp += gem.value;
                AudioSys.playExp();
                this.gems.splice(i, 1);
                this.checkLevelUp();
            }
        }

        // 7. Particles & Floating Texts
        for (let i = this.particles.length - 1; i >= 0; i--) {
            const pt = this.particles[i];
            pt.x += pt.vx * dt;
            pt.y += pt.vy * dt;
            pt.life -= dt;
            if (pt.life <= 0) this.particles.splice(i, 1);
        }

        for (let i = this.damageTexts.length - 1; i >= 0; i--) {
            const dtItem = this.damageTexts[i];
            dtItem.y -= 25 * dt;
            dtItem.life -= dt;
            if (dtItem.life <= 0) this.damageTexts.splice(i, 1);
        }

        this.updateHUD();
    }

    updateSkills(dt) {
        const p = this.player;
        const slash = this.skills.sword_slash;
        if (slash.level > 0) {
            slash.timer = (slash.timer || 0) + dt;
            const rate = GameStats.player.attackRate / (1 + (slash.level - 1) * 0.18);
            if (slash.timer >= rate) {
                slash.timer = 0;
                this.fireSlash();
            }
        }

        const orbit = this.skills.holy_orbit;
        if (orbit.level > 0) {
            this.orbitAngle += dt * 3.8;
            this.projectiles = this.projectiles.filter(pr => pr.type !== 'orbit');
            const count = orbit.level + 1;
            for (let i = 0; i < count; i++) {
                const angle = this.orbitAngle + (i * Math.PI * 2 / count);
                this.projectiles.push({
                    type: 'orbit',
                    x: p.x + Math.cos(angle) * 75,
                    y: p.y + Math.sin(angle) * 75,
                    angle: angle,
                    radius: 14,
                    damage: GameStats.player.attack * 0.75 * (1 + orbit.level * 0.25),
                    life: 0.1
                });
            }
        }

        const lightning = this.skills.lightning;
        if (lightning.level > 0) {
            lightning.timer = (lightning.timer || 0) + dt;
            const interval = Math.max(0.6, 2.2 - lightning.level * 0.3);
            if (lightning.timer >= interval) {
                lightning.timer = 0;
                this.strikeLightning();
            }
        }

        const arrows = this.skills.arrow_rain;
        if (arrows.level > 0) {
            arrows.timer = (arrows.timer || 0) + dt;
            const interval = Math.max(0.7, 1.8 - arrows.level * 0.22);
            if (arrows.timer >= interval) {
                arrows.timer = 0;
                this.fireArrows();
            }
        }
    }

    fireSlash() {
        const p = this.player;
        AudioSys.playSlash();

        // Calculate aim direction towards mouse cursor in world space
        const cx = this.canvas.width / 2;
        const cy = this.canvas.height / 2;
        const targetWorldX = p.x + (this.mousePos.x - cx);
        const targetWorldY = p.y + (this.mousePos.y - cy);

        let dirX = targetWorldX - p.x;
        let dirY = targetWorldY - p.y;
        const dist = Math.hypot(dirX, dirY);

        if (dist > 0.001) {
            dirX /= dist;
            dirY /= dist;
        } else {
            dirX = p.lastMoveDir ? p.lastMoveDir.x : (p.facing >= 0 ? 1 : -1);
            dirY = p.lastMoveDir ? p.lastMoveDir.y : 0;
        }

        const angle = Math.atan2(dirY, dirX);
        const spd = 420;
        const lvl = this.skills.sword_slash.level;
        const dmg = GameStats.player.attack * (1 + (lvl - 1) * 0.35);

        this.projectiles.push({
            type: 'slash',
            x: p.x + dirX * 20,
            y: p.y + dirY * 20,
            vx: dirX * spd,
            vy: dirY * spd,
            angle: angle,
            radius: 28 + lvl * 4,
            damage: dmg,
            pierce: 2 + lvl,
            life: 0.75,
            facing: p.facing
        });
    }

    strikeLightning() {
        if (this.mobs.length === 0) return;
        const targetsCount = Math.min(this.mobs.length, this.skills.lightning.level);
        AudioSys.playLightning();

        const sorted = [...this.mobs].sort(() => 0.5 - Math.random());
        for (let i = 0; i < targetsCount; i++) {
            const mob = sorted[i];
            const dmg = GameStats.player.attack * 1.8 * (1 + this.skills.lightning.level * 0.3);
            mob.hp -= dmg;
            this.addDamageText(mob.x, mob.y - 30, `⚡${Math.round(dmg)}`, '#67e8f9');
            this.createLightningEffect(mob.x, mob.y);

            if (mob.hp <= 0) {
                const idx = this.mobs.indexOf(mob);
                if (idx !== -1) this.killMob(idx);
            }
        }
    }

    fireArrows() {
        const p = this.player;
        AudioSys.playSlash();
        const count = 4 + this.skills.arrow_rain.level * 2;
        const dmg = GameStats.player.attack * 0.65 * (1 + this.skills.arrow_rain.level * 0.2);
        for (let i = 0; i < count; i++) {
            const angle = (Math.PI * 2 / count) * i;
            this.projectiles.push({
                type: 'arrow',
                x: p.x,
                y: p.y,
                vx: Math.cos(angle) * 460,
                vy: Math.sin(angle) * 460,
                radius: 8,
                damage: dmg,
                pierce: 1,
                life: 1.2,
                angle: angle
            });
        }
    }

    spawnMonster() {
        const angle = Math.random() * Math.PI * 2;
        const dist = 500 + Math.random() * 80;
        const x = this.player.x + Math.cos(angle) * dist;
        const y = this.player.y + Math.sin(angle) * dist;

        const currentWave = Math.floor(this.gameTime / 20) + 1;
        let mobType = 'slime';
        const roll = Math.random() * 100;

        // 웨이브별 고유 몬스터 등장 로직 (슬라임은 초기 스탯 그대로 유지, 신규 웨이브마다 고유 스탯의 새 몬스터 출현)
        switch (currentWave) {
            case 1:
                // Wave 1 (0~20초): 슬라임 100%
                mobType = 'slime';
                break;
            case 2:
                // Wave 2 (20~40초): 박쥐(초고속, 낮은 체력) 70%, 슬라임 30%
                mobType = roll < 70 ? 'bat' : 'slime';
                break;
            case 3:
                // Wave 3 (40~60초): 스켈레톤(단단함) 50%, 박쥐 30%, 슬라임 20%
                if (roll < 50) mobType = 'skeleton';
                else if (roll < 80) mobType = 'bat';
                else mobType = 'slime';
                break;
            case 4:
                // Wave 4 (60~80초): 오크(높은 체력/공격력) 45%, 스켈레톤 30%, 박쥐 15%, 슬라임 10%
                if (roll < 45) mobType = 'orc';
                else if (roll < 75) mobType = 'skeleton';
                else if (roll < 90) mobType = 'bat';
                else mobType = 'slime';
                break;
            case 5:
                // Wave 5 (80~100초): 늑대인간(돌진 맹수) 40%, 오크 30%, 스켈레톤 20%, 박쥐 10%
                if (roll < 40) mobType = 'werewolf';
                else if (roll < 70) mobType = 'orc';
                else if (roll < 90) mobType = 'skeleton';
                else mobType = 'bat';
                break;
            default:
                // Wave 6+ (100초 이상): 엘리트 오크(보스급 체력) 25%, 늑대인간 35%, 오크 25%, 스켈레톤 15%
                if (roll < 25) mobType = 'elite_orc';
                else if (roll < 60) mobType = 'werewolf';
                else if (roll < 85) mobType = 'orc';
                else mobType = 'skeleton';
                break;
        }

        const proto = GameStats.mobs[mobType] || GameStats.mobs.slime;

        this.mobs.push({
            type: mobType,
            x: x,
            y: y,
            hp: proto.hp,
            maxHp: proto.hp,
            speed: proto.speed,
            atk: proto.atk,
            exp: proto.exp,
            sprite: proto.sprite,
            frames: proto.frames,
            attackSprite: proto.attackSprite || null,
            attackFrames: proto.attackFrames || 6,
            attackRange: proto.attackRange || 0,
            attackInterval: proto.attackInterval || 1.0,
            attackCooldown: 0,
            state: 'walk',
            animTime: Math.random(),
            facing: 1
        });
    }

    killMob(idx) {
        const mob = this.mobs[idx];
        this.killCount++;
        this.mobs.splice(idx, 1);

        this.gems.push({
            x: mob.x,
            y: mob.y,
            value: mob.exp
        });

        this.createBloodParticles(mob.x, mob.y, '#ef4444');
    }

    checkLevelUp() {
        const p = this.player;
        if (p.exp >= p.nextExp) {
            p.exp -= p.nextExp;
            p.level++;
            p.nextExp = Math.round(p.nextExp * 1.45 + 5);
            AudioSys.playLevelUp();
            this.showLevelUpModal();
        }
    }

    showLevelUpModal() {
        this.isPaused = true;
        const modal = document.getElementById('levelup-modal');
        const container = document.getElementById('cards-container');
        container.innerHTML = '';

        const available = Object.values(this.skills).filter(s => s.level < s.maxLevel);
        const chosen = [];
        const pool = [...available];
        while (chosen.length < 3 && pool.length > 0) {
            const randIdx = Math.floor(Math.random() * pool.length);
            chosen.push(pool.splice(randIdx, 1)[0]);
        }

        chosen.forEach(sk => {
            const card = document.createElement('div');
            card.className = 'skill-card';
            card.innerHTML = `
                <div class="skill-icon">${sk.icon}</div>
                <div class="skill-name">${sk.name}</div>
                <div class="skill-level">${sk.level === 0 ? '신규 획득 [LV 1]' : `레벨 업 [LV ${sk.level + 1}]`}</div>
                <div class="skill-desc">${sk.desc}</div>
            `;
            card.onclick = () => {
                this.selectSkill(sk.id);
                modal.classList.add('hidden');
                this.isPaused = false;
            };
            container.appendChild(card);
        });

        modal.classList.remove('hidden');
    }

    selectSkill(id) {
        const sk = this.skills[id];
        sk.level++;

        if (id === 'max_hp_up') {
            this.player.maxHp += 25;
            this.player.hp = Math.min(this.player.maxHp, this.player.hp + 35);
        }

        this.updateSkillsHUD();
        this.updateHUD();
        this.checkLevelUp();
    }

    triggerGameOver() {
        this.isGameOver = true;
        document.getElementById('final-time').innerText = this.formatTime(this.gameTime);
        document.getElementById('final-kills').innerText = this.killCount;
        document.getElementById('gameover-modal').classList.remove('hidden');
    }

    formatTime(sec) {
        const m = Math.floor(sec / 60);
        const s = Math.floor(sec % 60);
        return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
    }

    updateHUD() {
        const p = this.player;
        const currentWave = Math.floor(this.gameTime / 20) + 1;

        if (this.lastWave !== currentWave) {
            if (this.lastWave !== undefined && currentWave > this.lastWave) {
                const mobNames = {
                    2: '🦇 박쥐 (고속 이동)',
                    3: '💀 스켈레톤 (단단한 방어력)',
                    4: '👹 오크 (강력한 완력)',
                    5: '🐺 늑대인간 (돌진 맹수)',
                    6: '👑 엘리트 오크 (보스급 체력)'
                };
                const newMobDesc = mobNames[currentWave] || '신규 강적';
                this.addDamageText(p.x, p.y - 70, `🚨 WAVE ${currentWave} 진입! [${newMobDesc}]`, '#fbbf24');
            }
            this.lastWave = currentWave;
        }

        document.getElementById('hp-val').innerText = `${Math.max(0, Math.ceil(p.hp))} / ${Math.ceil(p.maxHp)}`;
        document.getElementById('lvl-val').innerText = p.level;
        document.getElementById('kill-val').innerText = this.killCount;
        document.getElementById('time-val').innerText = `${this.formatTime(this.gameTime)} [WAVE ${currentWave}]`;

        const pct = Math.min(100, (p.exp / p.nextExp) * 100);
        document.getElementById('exp-fill').style.width = `${pct}%`;
        document.getElementById('exp-text').innerText = `EXP ${Math.floor(p.exp)} / ${p.nextExp}`;
    }

    updateSkillsHUD() {
        const container = document.getElementById('active-skills');
        container.innerHTML = '';
        Object.values(this.skills).forEach(sk => {
            if (sk.level > 0) {
                const badge = document.createElement('div');
                badge.className = 'active-skill-badge';
                badge.innerHTML = `<span class="icon">${sk.icon}</span><span class="lvl">LV.${sk.level}</span>`;
                container.appendChild(badge);
            }
        });
    }

    addDamageText(x, y, text, color) {
        this.damageTexts.push({ x, y, text, color, life: 0.6 });
    }

    createBloodParticles(x, y, color) {
        for (let i = 0; i < 6; i++) {
            const angle = Math.random() * Math.PI * 2;
            const spd = 40 + Math.random() * 80;
            this.particles.push({
                x, y,
                vx: Math.cos(angle) * spd,
                vy: Math.sin(angle) * spd,
                life: 0.35,
                color,
                size: 3 + Math.random() * 3
            });
        }
    }

    createLightningEffect(x, y) {
        for (let i = 0; i < 12; i++) {
            const angle = Math.random() * Math.PI * 2;
            const spd = 80 + Math.random() * 120;
            this.particles.push({
                x, y,
                vx: Math.cos(angle) * spd,
                vy: Math.sin(angle) * spd,
                life: 0.25,
                color: '#67e8f9',
                size: 3
            });
        }
    }

    render() {
        const ctx = this.ctx;
        const w = this.canvas.width;
        const h = this.canvas.height;
        const cx = w / 2;
        const cy = h / 2;
        const p = this.player;

        ctx.clearRect(0, 0, w, h);

        ctx.save();
        ctx.translate(cx - p.x, cy - p.y);

        // 1. Grid Floor
        const gridSize = 64;
        const startX = Math.floor((p.x - cx) / gridSize) * gridSize;
        const endX = Math.ceil((p.x + cx) / gridSize) * gridSize;
        const startY = Math.floor((p.y - cy) / gridSize) * gridSize;
        const endY = Math.ceil((p.y + cy) / gridSize) * gridSize;

        ctx.strokeStyle = '#1e293b';
        ctx.lineWidth = 1;
        ctx.beginPath();
        for (let x = startX; x <= endX; x += gridSize) {
            ctx.moveTo(x, startY);
            ctx.lineTo(x, endY);
        }
        for (let y = startY; y <= endY; y += gridSize) {
            ctx.moveTo(startX, y);
            ctx.lineTo(endX, y);
        }
        ctx.stroke();

        // 2. EXP Gems
        for (const gem of this.gems) {
            ctx.fillStyle = '#38bdf8';
            ctx.shadowColor = '#38bdf8';
            ctx.shadowBlur = 8;
            ctx.beginPath();
            ctx.arc(gem.x, gem.y, 6, 0, Math.PI * 2);
            ctx.fill();
            ctx.shadowBlur = 0;
        }

        // 3. Monsters
        for (const mob of this.mobs) {
            const spr = (mob.state === 'attack' && mob.attackSprite) ? mob.attackSprite : mob.sprite;
            const fCount = (mob.state === 'attack' && mob.attackFrames) ? mob.attackFrames : mob.frames;
            const aTime = (mob.state === 'attack') ? (mob.attackTimer || 0) : mob.animTime;
            this.drawSprite(spr, mob.x, mob.y, mob.facing, aTime, fCount, 100, 100, 64);
            if (mob.hp < mob.maxHp) {
                const barW = 36;
                const barH = 5;
                const pct = Math.max(0, mob.hp / mob.maxHp);
                ctx.fillStyle = 'rgba(0,0,0,0.6)';
                ctx.fillRect(mob.x - barW / 2, mob.y - 38, barW, barH);
                ctx.fillStyle = '#ef4444';
                ctx.fillRect(mob.x - barW / 2, mob.y - 38, barW * pct, barH);
            }
        }

        // 4. Player (Knight)
        const pSprite = p.state === 'walk' ? 'knight_walk' : 'knight_idle';
        const pFrames = p.state === 'walk' ? 8 : 6;
        if (p.invincibleTimer <= 0 || Math.floor(p.invincibleTimer * 15) % 2 === 0) {
            this.drawSprite(pSprite, p.x, p.y, p.facing, p.animTime, pFrames, 100, 100, 80);
        }

        // 5. Projectiles
        for (const proj of this.projectiles) {
            if (proj.type === 'slash') {
                ctx.save();
                ctx.translate(proj.x, proj.y);
                ctx.rotate(proj.angle !== undefined ? proj.angle : (proj.facing === -1 ? Math.PI : 0));
                ctx.strokeStyle = '#60a5fa';
                ctx.lineWidth = 6;
                ctx.shadowColor = '#3b82f6';
                ctx.shadowBlur = 12;
                ctx.beginPath();
                ctx.arc(0, 0, proj.radius, -Math.PI / 3, Math.PI / 3);
                ctx.stroke();
                ctx.restore();
            } else if (proj.type === 'orbit') {
                ctx.fillStyle = '#fde047';
                ctx.shadowColor = '#facc15';
                ctx.shadowBlur = 12;
                ctx.beginPath();
                ctx.arc(proj.x, proj.y, proj.radius, 0, Math.PI * 2);
                ctx.fill();
                ctx.shadowBlur = 0;
            } else if (proj.type === 'arrow') {
                const arrowImg = assets.images['arrow'];
                if (arrowImg) {
                    ctx.save();
                    ctx.translate(proj.x, proj.y);
                    ctx.rotate(proj.angle);
                    ctx.drawImage(arrowImg, -16, -16, 32, 32);
                    ctx.restore();
                } else {
                    ctx.fillStyle = '#fbbf24';
                    ctx.beginPath();
                    ctx.arc(proj.x, proj.y, 4, 0, Math.PI * 2);
                    ctx.fill();
                }
            }
        }

        // 6. Particles
        for (const pt of this.particles) {
            ctx.fillStyle = pt.color;
            ctx.beginPath();
            ctx.arc(pt.x, pt.y, pt.size || 3, 0, Math.PI * 2);
            ctx.fill();
        }

        // 7. Floating Damage Texts
        ctx.font = 'bold 14px Segoe UI, sans-serif';
        ctx.textAlign = 'center';
        for (const dtItem of this.damageTexts) {
            ctx.fillStyle = dtItem.color;
            ctx.fillText(dtItem.text, dtItem.x, dtItem.y);
        }

        ctx.restore();
    }

    drawSprite(imgKey, x, y, facing, time, totalFrames, frameW, frameH, renderSize) {
        const img = assets.images[imgKey];
        const frameIdx = Math.floor(time * 10) % totalFrames;
        const ctx = this.ctx;

        if (img) {
            ctx.save();
            ctx.translate(x, y);
            if (facing === -1) ctx.scale(-1, 1);
            ctx.drawImage(
                img,
                frameIdx * frameW, 0, frameW, frameH,
                -renderSize / 2, -renderSize / 2, renderSize, renderSize
            );
            ctx.restore();
        } else {
            ctx.fillStyle = imgKey && imgKey.startsWith('knight') ? '#3b82f6' : '#dc2626';
            ctx.fillRect(x - 20, y - 20, 40, 40);
        }
    }
}

/* --- PRELOAD AND START --- */
let game = null;
async function start() {
    initStatConfigUI();

    // Preload Knight and Monster Sprites
    await Promise.all([
        assets.load('knight_idle', 'asset/Characters01/Characters(100x100 split)/Knight/Knight with shadows/Knight_Idle.png'),
        assets.load('knight_walk', 'asset/Characters01/Characters(100x100 split)/Knight/Knight with shadows/Knight_Walk.png'),
        assets.load('knight_attack', 'asset/Characters01/Characters(100x100 split)/Knight/Knight with shadows/Knight_Attack01.png'),
        assets.load('knight_death', 'asset/Characters01/Characters(100x100 split)/Knight/Knight with shadows/Knight_Death.png'),

        assets.load('slime_walk', 'asset/Characters01/Characters(100x100 split)/Slime/Slime with shadows/Slime_Walk.png'),
        assets.load('bat_fly', 'asset/Characters01/Characters(100x100 split)/Bat/Bat/Bat_Flying.png'),
        assets.load('skel_walk', 'asset/Characters01/Characters(100x100 split)/Skeleton/Skeleton/Skeleton_Walk.png'),
        assets.load('skel_attack', 'asset/Characters01/Characters(100x100 split)/Skeleton/Skeleton/Skeleton_Attack01.png'),
        assets.load('orc_walk', 'asset/Characters01/Characters(100x100 split)/Orc/Orc with shadows/Orc_Walk.png'),
        assets.load('werewolf_walk', 'asset/Characters01/Characters(100x100 split)/Werewolf/Werewolf with shadows/Werewolf_Walk.png'),
        assets.load('elite_orc_walk', 'asset/Characters01/Characters(100x100 split)/Elite Orc/Elite Orc with shadows/Elite Orc_Walk.png'),

        assets.load('arrow', 'asset/Characters01/Arrow(Projectile)/Arrow01(32x32).png')
    ]);

    game = new SurvivorGame();

    let lastTime = performance.now();
    function loop(now) {
        const dt = Math.min(0.1, (now - lastTime) / 1000);
        lastTime = now;

        game.update(dt);
        game.render();

        requestAnimationFrame(loop);
    }
    requestAnimationFrame(loop);
}

window.onload = start;