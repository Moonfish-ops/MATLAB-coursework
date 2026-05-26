function game = checkCollision(game)
% checkCollision 统一碰撞处理

    p = game.player;
    r = game.room;

    invincible = (p.invincible > 0) || (p.dashTimer > 0);

    % 1) 玩家 vs 陷阱
    for i = 1:size(r.hazards,1)
        hz = r.hazards(i,:);
        if p.z < 10 && rectsOverlap(p.x, p.y-8, p.w, 16, hz(1), hz(2), hz(3), hz(4))
            if ~invincible
                p.hp = p.hp - 6;
                p.invincible = 45;
                p.hitFlash = 10;
                p.vz = 7;
                p.onGround = false;
                p.vx = -p.facing * 3;
            end
        end
    end

    % 2) 玩家 vs 拾取物
    for i = 1:numel(r.pickups)
        pk = r.pickups(i);
        if ~pk.alive
            continue;
        end

        if rectsOverlap(p.x, p.y-12, p.w, 24, pk.x-12, pk.y-12, 24, 24)
            switch pk.type
                case 'coin'
                    p.coins = p.coins + 1;
                case 'heart'
                    p.hp = min(p.hpMax, p.hp + 25);
                case 'mana'
                    p.mp = min(p.mpMax, p.mp + 20);
                case 'star'
                    p.stars = p.stars + 1;
                case 'skin'
                    if pk.skinIdx > 0 && pk.skinIdx <= numel(game.skins)
                        if ~game.progress.ownedSkins(pk.skinIdx)
                            game.progress.ownedSkins(pk.skinIdx) = true;
                            game = addPopup(game, p.x+p.w/2, p.y+p.h+22, ...
                                ['获得皮肤: ' game.skins(pk.skinIdx).nameCN], [1 0.6 1]);
                        else
                            p.stars = p.stars + 1;
                            game = addPopup(game, p.x+p.w/2, p.y+p.h+22, ...
                                '重复皮肤已转化为星星+1', [1 1 0.5]);
                        end
                    end
            end
            pk.alive = false;
        end
        r.pickups(i) = pk;
    end

    % 3) 玩家 vs 敌人身体
    for i = 1:numel(r.enemies)
        e = r.enemies(i);
        if ~e.alive
            continue;
        end
        if p.z < 20 && rectsOverlap(p.x, p.y-12, p.w, 24, e.x, e.y-12, e.w, 24)
            if ~invincible
                p.hp = p.hp - e.dmg;
                p.invincible = 45;
                p.hitFlash = 10;
                p.vz = 8;
                p.onGround = false;
                p.vx = -sign((e.x+e.w/2) - (p.x+p.w/2)) * 4;
            end
        end
    end

    game.player = p;

    % 4/5) 子弹碰撞
    if ~isempty(game.bullets)
        keep = true(1, numel(game.bullets));
        for i = 1:numel(game.bullets)
            b = game.bullets(i);

            if strcmp(b.owner,'player')
                [hit, hitIdx] = hitEnemyBySweep(r, b);
                if hit
                    e = r.enemies(hitIdx);
                    [game, r, e] = applyHit(game, r, e, hitIdx, b, b.dmg);

                    if b.explode && b.aoeR > 0
                        for k = 1:numel(r.enemies)
                            if k == hitIdx, continue; end
                            ek = r.enemies(k);
                            if ~ek.alive, continue; end
                            cx = ek.x + ek.w/2;
                            cy = ek.y + ek.h/2;
                            if (cx-b.x)^2 + (cy-b.y)^2 <= b.aoeR^2
                                aoeDmg = b.dmg * b.aoeDmgMul;
                                [game, r, ek] = applyHit(game, r, ek, k, b, aoeDmg);
                                r.enemies(k) = ek;
                            end
                        end
                        game = addPopup(game, b.x, b.y+20, 'BOOM!', [1 0.6 0.2]);
                    end

                    r.enemies(hitIdx) = e;
                    if ~b.pierce
                        keep(i) = false;
                    end
                end
            else
                p = game.player;
                [hitPlayer,~] = hitPlayerBySweep(p, b);
                if hitPlayer
                    if ~(p.invincible > 0 || p.dashTimer > 0)
                        p.hp = p.hp - b.dmg;
                        p.invincible = 30;
                        p.hitFlash = 10;
                    end
                    game.player = p;
                    keep(i) = false;
                end
            end
        end
        game.bullets = game.bullets(keep);
    end

    % 玩家死亡
    p = game.player;
    if p.hp <= 0 && strcmp(game.state,'playing')
        game.state = 'dead';
        game.stateTimer = 0;
    end

    game.player = p;
    game.room = r;
end

function [game, r, e] = applyHit(game, r, e, enemyIdx, b, dmg)
    e.hp = e.hp - dmg;
    showPopup = (e.hit <= 0) || b.crit || strcmp(e.type,'boss');
    e.hit = 6;

    txt = sprintf('-%.0f', round(dmg));
    col = [1 1 1];
    if b.crit
        txt = ['暴击 ' txt];
        col = [1 0.6 0.2];
    end
    if showPopup
        game = addPopup(game, b.x, b.y + e.h*0.6, txt, col);
    end

    game.player.ultEnergy = min(game.player.ultEnergyMax, ...
        game.player.ultEnergy + hitEnergyByEnemyType(e.type));

    if e.hp <= 0
        e.alive = false;
        e.deathAnim = 15;

        expVal = 8;
        if strcmp(e.type,'eliteMelee') || strcmp(e.type,'eliteRanged')
            expVal = 30;
        elseif strcmp(e.type,'boss')
            expVal = 160;
        end

        r.enemies(enemyIdx) = e;
        game.room = r;
        game = spawnDrop(game, e);
        game = gainExp(game, expVal);
        r = game.room;
    else
        r.enemies(enemyIdx) = e;
    end
end

function v = hitEnergyByEnemyType(type)
    switch type
        case {'melee','ranged'}
            v = 2;
        case {'eliteMelee','eliteRanged'}
            v = 4;
        case 'boss'
            v = 6;
        otherwise
            v = 2;
    end
end

function [hit, hitIdx] = hitEnemyBySweep(r, b)
    hit = false;
    hitIdx = 0;

    bx0 = b.x - b.vx;
    by0 = b.y - b.vy;
    xPad = max(6, abs(b.vx)*0.5);
    yPad = max(6, abs(b.vy)*0.5);
    sx1 = min(bx0, b.x) - xPad;
    sx2 = max(bx0, b.x) + xPad;
    sy1 = min(by0, b.y) - yPad;
    sy2 = max(by0, b.y) + yPad;

    for j = 1:numel(r.enemies)
        e = r.enemies(j);
        if ~e.alive
            continue;
        end
        ex1 = e.x - 4; ex2 = e.x + e.w + 4;
        ey1 = e.y - 8; ey2 = e.y + e.h + 8;
        if sx2 >= ex1 && sx1 <= ex2 && sy2 >= ey1 && sy1 <= ey2 && b.z >= -4 && b.z <= e.h + 14
            hit = true;
            hitIdx = j;
            return;
        end
    end
end

function [hit, idx] = hitPlayerBySweep(p, b)
    hit = false;
    idx = 0;

    bx0 = b.x - b.vx;
    by0 = b.y - b.vy;
    sx1 = min(bx0, b.x);
    sx2 = max(bx0, b.x);
    sy1 = min(by0, b.y);
    sy2 = max(by0, b.y);

    px1 = p.x - 2; px2 = p.x + p.w + 2;
    py1 = p.y - 4; py2 = p.y + p.h + 4;

    if sx2 >= px1 && sx1 <= px2 && sy2 >= py1 && sy1 <= py2 && b.z >= p.z - 4 && b.z <= p.z + p.h + 4
        hit = true;
    end
end

function t = rectsOverlap(x1,y1,w1,h1,x2,y2,w2,h2)
    t = ~(x1+w1 <= x2 || x2+w2 <= x1 || y1+h1 <= y2 || y2+h2 <= y1);
end

function game = addPopup(game, x, y, text, color)
    pop = struct('x',x,'y',y,'life',45,'text',text,'color',color);
    maxPopups = 24;
    if isempty(game.popups)
        game.popups = pop;
        return;
    end
    if numel(game.popups) >= maxPopups
        game.popups = game.popups(2:end);
    end
    game.popups(end+1) = pop;
end

