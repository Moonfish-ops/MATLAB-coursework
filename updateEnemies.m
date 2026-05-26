function game = updateEnemies(game)
% updateEnemies diverse patterns with low-overhead scheduling
    r = game.room;
    p = game.player;

    enemyBulletsLeft = 80;
    if ~isempty(game.bullets)
        for bi = 1:numel(game.bullets)
            if strcmp(game.bullets(bi).owner, 'enemy')
                enemyBulletsLeft = enemyBulletsLeft - 1;
                if enemyBulletsLeft <= 0
                    break;
                end
            end
        end
    end

    for i = 1:numel(r.enemies)
        e = r.enemies(i);
        e = ensureEnemyRuntimeFields(e);

        if ~e.alive
            if e.deathAnim > 0
                e.deathAnim = e.deathAnim - 1;
            end
            r.enemies(i) = e;
            continue;
        end

        dx = (p.x + p.w/2) - (e.x + e.w/2);
        dy = p.y - e.y;
        dist = max(1, sqrt(dx*dx + dy*dy));
        ang = atan2(dy, dx);

        if e.castTimer > 0
            e.castTimer = e.castTimer - 1;
        end
        if e.recoverTimer > 0
            e.recoverTimer = e.recoverTimer - 1;
        end

        switch e.type
            case 'melee'
                if strcmp(e.archetype,'defender')
                    e = moveToward(e, dx, dy, dist, 0.85, 0.78);
                    e.shootTimer = e.shootTimer - 1;
                    if dist < 175 && e.shootTimer <= 0 && e.castTimer <= 0
                        e.castTimer = 12; % clear wind-up
                        e.shootTimer = 92;
                    end
                    if e.castTimer == 6
                        [game, enemyBulletsLeft] = spawnFan(game, e, ang, 5, 0.9, 2.8, 7.2, [1 0.55 0.25], enemyBulletsLeft);
                    end
                else
                    % rusher: chase + occasional short dash
                    e = moveToward(e, dx, dy, dist, 1.0, 1.15);
                    if e.aiTimer > 0
                        e.aiTimer = e.aiTimer - 1;
                    elseif dist > 110 && e.castTimer <= 0
                        e.castTimer = 8;
                        e.aiTimer = 80;
                    end
                    if e.castTimer == 4
                        e.chargeVx = (dx/dist) * 3.4;
                        e.chargeVy = (dy/dist) * 3.4;
                        e.recoverTimer = 8;
                    end
                    if e.recoverTimer > 0
                        [cx, cy] = clampStep(e.chargeVx, e.chargeVy, 1.7);
                        e.x = e.x + cx;
                        e.y = e.y + cy;
                    end
                end

            case 'ranged'
                e = keepRangeMove(e, dx, dy, dist, 150, 240, 0.70, 0.78, 0.60, 0.66);
                e.shootTimer = e.shootTimer - 1;

                if strcmp(e.archetype,'bomber')
                    if e.shootTimer <= 0 && e.castTimer <= 0
                        e.castTimer = 12;
                        e.shootTimer = 100;
                    end
                    if e.castTimer == 6
                        [game, enemyBulletsLeft] = spawnFan(game, e, ang, 3, 0.70, 2.9, 7.4, [1 0.45 0.22], enemyBulletsLeft);
                    end
                else
                    if e.shootTimer <= 0
                        [game, enemyBulletsLeft] = spawnEnemyBullet(game, e, ang-0.06, 5.0, 6.6, [1 0.3 0.3], enemyBulletsLeft);
                        [game, enemyBulletsLeft] = spawnEnemyBullet(game, e, ang+0.06, 5.0, 6.6, [1 0.3 0.3], enemyBulletsLeft);
                        e.shootTimer = 82;
                    end
                end

            case 'eliteMelee'
                e = moveToward(e, dx, dy, dist, 1.0, 1.35);

                if e.aiTimer > 0
                    [cx, cy] = clampStep(e.chargeVx, e.chargeVy, 1.55);
                    e.x = e.x + cx;
                    e.y = e.y + cy;
                    e.aiTimer = e.aiTimer - 1;
                elseif dist > 120 && e.castTimer <= 0
                    e.castTimer = 10;
                end

                if e.castTimer == 5
                    e.chargeVx = (dx/dist) * 3.0;
                    e.chargeVy = (dy/dist) * 3.0;
                    e.aiTimer = 10;
                end

                e.shootTimer = e.shootTimer - 1;
                if e.shootTimer <= 0
                    if mod(game.stateTimer + i, 2) == 0
                        [game, enemyBulletsLeft] = spawnFan(game, e, ang, 3, 0.45, 3.3, 8.8, [1 0.62 0.22], enemyBulletsLeft);
                    else
                        [game, enemyBulletsLeft] = spawnRing(game, e, 6, 3.0, 8.0, [1 0.50 0.18], enemyBulletsLeft);
                    end
                    e.shootTimer = 95;
                end

            case 'eliteRanged'
                e = keepRangeMove(e, dx, dy, dist, 170, 260, 0.74, 0.88, 0.62, 0.72);
                e.shootTimer = e.shootTimer - 1;
                if e.shootTimer <= 0
                    e.attackMode = mod(e.attackMode, 3) + 1;
                    switch e.attackMode
                        case 1
                            [game, enemyBulletsLeft] = spawnFan(game, e, ang, 3, 0.32, 5.2, 9.0, [1 0.52 0.20], enemyBulletsLeft);
                            e.shootTimer = 78;
                        case 2
                            [game, enemyBulletsLeft] = spawnFan(game, e, ang, 5, 0.72, 4.1, 8.6, [1 0.46 0.24], enemyBulletsLeft);
                            e.shootTimer = 92;
                        otherwise
                            lead = atan2(dy + p.vy*7, dx + p.vx*7);
                            [game, enemyBulletsLeft] = spawnEnemyBullet(game, e, lead, 5.8, 10.8, [1 0.68 0.22], enemyBulletsLeft);
                            e.shootTimer = 72;
                    end
                end

            case 'boss'
                if e.hp <= 0.55 * max(1, e.hpMax)
                    e.phase = 2;
                else
                    e.phase = 1;
                end

                e.modeTimer = e.modeTimer - 1;
                maxMode = 4;
                if e.phase >= 2
                    maxMode = 5;
                end
                if e.modeTimer <= 0
                    e.attackMode = mod(e.attackMode, maxMode) + 1;
                    e.modeTimer = 130;
                    e.shootTimer = 20;
                end

                speedMul = 1.0;
                if e.phase >= 2
                    speedMul = 1.08;
                end
                e = moveToward(e, dx, dy, dist, 0.34*speedMul, 0.50);

                e.shootTimer = e.shootTimer - 1;
                if e.shootTimer <= 0
                    switch e.attackMode
                        case 1 % aimed shot
                            [game, enemyBulletsLeft] = spawnEnemyBullet(game, e, ang, 3.7, 12.0, [1 0.25 0.25], enemyBulletsLeft);
                            e.shootTimer = 28;
                        case 2 % fan burst
                            [game, enemyBulletsLeft] = spawnFan(game, e, ang, 3, 0.48, 3.3, 9.8, [1 0.22 0.58], enemyBulletsLeft);
                            e.shootTimer = 84;
                        case 3 % radial pressure
                            [game, enemyBulletsLeft] = spawnRing(game, e, 6, 3.0, 8.6, [1 0.16 0.16], enemyBulletsLeft);
                            e.shootTimer = 100;
                        case 4 % predictive double
                            lead = atan2(dy + p.vy*6, dx + p.vx*6);
                            [game, enemyBulletsLeft] = spawnEnemyBullet(game, e, lead-0.18, 3.7, 10.2, [0.96 0.25 0.25], enemyBulletsLeft);
                            [game, enemyBulletsLeft] = spawnEnemyBullet(game, e, lead+0.18, 3.7, 10.2, [0.96 0.25 0.25], enemyBulletsLeft);
                            e.shootTimer = 88;
                        otherwise % phase-2 extra: rotating cross
                            [game, enemyBulletsLeft] = spawnRing(game, e, 4, 3.2, 10.0, [0.95 0.35 0.70], enemyBulletsLeft);
                            [game, enemyBulletsLeft] = spawnRing(game, e, 4, 3.2, 10.0, [0.95 0.35 0.70], enemyBulletsLeft, pi/4);
                            e.shootTimer = 108;
                    end
                end
        end

        if e.x < 20, e.x = 20; end
        if e.x > r.w - 20 - e.w, e.x = r.w - 20 - e.w; end
        if e.y < r.yMin, e.y = r.yMin; end
        if e.y > r.yMax, e.y = r.yMax; end

        if (e.x + e.w/2) < (p.x + p.w/2)
            e.dir = 1;
        else
            e.dir = -1;
        end
        e.facing = e.dir;

        if e.hit > 0
            e.hit = e.hit - 1;
        end

        r.enemies(i) = e;
    end

    game.room = r;
end

function e = ensureEnemyRuntimeFields(e)
    if ~isfield(e,'archetype') || isempty(e.archetype)
        e.archetype = '';
    end
    if ~isfield(e,'castTimer'), e.castTimer = 0; end
    if ~isfield(e,'recoverTimer'), e.recoverTimer = 0; end
    if ~isfield(e,'attackMode') || e.attackMode < 1, e.attackMode = 1; end
    if ~isfield(e,'modeTimer') || e.modeTimer <= 0, e.modeTimer = 150; end
    if ~isfield(e,'phase') || e.phase < 1, e.phase = 1; end
    if ~isfield(e,'shootTimer') || ~isfinite(e.shootTimer) || e.shootTimer < 0
        e.shootTimer = 45;
    end
    if ~isfield(e,'aiTimer') || ~isfinite(e.aiTimer)
        e.aiTimer = 30;
    end
end

function e = moveToward(e, dx, dy, dist, speedMul, clampMax)
    stepX = e.speed * speedMul * dx / dist;
    stepY = e.speed * speedMul * dy / dist;
    [stepX, stepY] = clampStep(stepX, stepY, clampMax);
    e.x = e.x + stepX;
    e.y = e.y + stepY;
end

function e = keepRangeMove(e, dx, dy, dist, nearR, farR, chaseMul, chaseClamp, backMul, backClamp)
    if dist > farR
        stepX = chaseMul * dx / dist;
        stepY = chaseMul * dy / dist;
        [stepX, stepY] = clampStep(stepX, stepY, chaseClamp);
        e.x = e.x + stepX;
        e.y = e.y + stepY;
    elseif dist < nearR
        stepX = -backMul * dx / dist;
        stepY = -backMul * dy / dist;
        [stepX, stepY] = clampStep(stepX, stepY, backClamp);
        e.x = e.x + stepX;
        e.y = e.y + stepY;
    end
end

function [game, bulletsLeft] = spawnFan(game, e, centerAng, n, spread, spd, dmg, col, bulletsLeft)
    if nargin < 10
        bulletsLeft = 0;
        return;
    end
    if n <= 1
        [game, bulletsLeft] = spawnEnemyBullet(game, e, centerAng, spd, dmg, col, bulletsLeft);
        return;
    end
    half = (n - 1) / 2;
    for k = -half:half
        aa = centerAng + (k/half) * (spread/2);
        [game, bulletsLeft] = spawnEnemyBullet(game, e, aa, spd, dmg, col, bulletsLeft);
        if bulletsLeft <= 0
            return;
        end
    end
end

function [game, bulletsLeft] = spawnRing(game, e, n, spd, dmg, col, bulletsLeft, angOffset)
    if nargin < 8
        angOffset = 0;
    end
    if n <= 0
        return;
    end
    for k = 0:(n-1)
        aa = angOffset + k * (2*pi/n);
        [game, bulletsLeft] = spawnEnemyBullet(game, e, aa, spd, dmg, col, bulletsLeft);
        if bulletsLeft <= 0
            return;
        end
    end
end

function [sx, sy] = clampStep(sx, sy, maxLen)
    len = sqrt(sx*sx + sy*sy);
    if len > maxLen && len > 0
        k = maxLen / len;
        sx = sx * k;
        sy = sy * k;
    end
end

function [game, bulletsLeft] = spawnEnemyBullet(game, e, ang, spd, dmg, col, bulletsLeft)
    if bulletsLeft <= 0
        return;
    end

    b.x  = e.x + e.w/2;
    b.y  = e.y;
    b.z  = e.h * 0.55;
    b.vx = spd * cos(ang);
    b.vy = spd * sin(ang);
    b.vz = 0;
    b.owner = 'enemy';
    b.life  = 130;
    b.dmg   = dmg;
    b.color = enemyBulletColor(game.room.bgColor, col);
    b.crit  = false;
    b.pierce    = false;
    b.explode   = false;
    b.aoeR      = 0;
    b.aoeDmgMul = 0;
    game = spawnBullet(game, b);
    bulletsLeft = bulletsLeft - 1;
end

function c = enemyBulletColor(bg, baseCol)
    if nargin < 2 || isempty(baseCol)
        baseCol = [1 0.25 0.25];
    end
    if numel(bg) ~= 3
        bg = [0.25 0.25 0.25];
    end
    c = 0.78 * (1 - bg) + 0.22 * baseCol;
    if mean(c) < 0.50
        c = min(1, c + 0.30);
    end
    c = max(0, min(1, c));
end
