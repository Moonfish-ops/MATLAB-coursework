function game = handleInput(game)
% handleInput 输入处理：移动、技能、切枪、仓库、重开与退出

    p = game.player;
    if ~isfield(p,'shootFx'), p.shootFx = 0; end
    if ~isfield(p,'swapFx'), p.swapFx = 0; end
    if ~isfield(p,'castFx'), p.castFx = 0; end
    held = game.inputHeld;
    pulse = game.inputPulse;
    AS = game.activeSkills;
    idxC = findSkillIdx(AS,'letsgo');
    idxQ = findSkillIdx(AS,'nice');
    idxE = findSkillIdx(AS,'summondog');
    idxX = findSkillIdx(AS,'ultimate');

    if pulse.exitGame
        game.returnToMenu = true;
        game.running = false;
        game.inputPulse = clearPulse(pulse);
        return;
    end

    if pulse.restartLevel && strcmp(game.state,'playing')
        game = loadLevel(game, game.currentLevel, 1);
        game.inputPulse = clearPulse(pulse);
        return;
    end

    if ~isfield(game,'warehouseCooldown')
        game.warehouseCooldown = 0;
    end
    if game.warehouseCooldown > 0
        game.warehouseCooldown = game.warehouseCooldown - 1;
    end

    if pulse.openWarehouse && game.warehouseCooldown <= 0
        game.inputPulse.openWarehouse = false;
        pauseBattleBgm(game);
        game = warehouseMenu(game, true);
        resumeBattleBgm(game);
        % 防止仓库关闭后按键状态残留导致“无法移动”或反复开仓
        game.inputHeld = resetHeld(game.inputHeld);
        game.inputPulse = clearPulse(game.inputPulse);
        game.warehouseCooldown = 45; % 防抖：吞掉关闭瞬间的按键重复事件
        if isfield(game,'fig') && ~isempty(game.fig) && ishandle(game.fig)
            figure(game.fig); % 关闭仓库后立刻把焦点还给战斗窗口
            drawnow limitrate nocallbacks;
        end
        p = game.player;
        game.currentSkin = game.progress.equippedSkinByWeapon;
        [~,~,~,~,skinIdx] = skinModifiers(game, p.weaponIdx);
        p.skinIdx = skinIdx;
    end

    if ~strcmp(game.state,'playing')
        game.player = p;
        game.inputPulse = clearPulse(pulse);
        return;
    end

    % 键盘瞄准：面向右=0，左=pi
    if p.facing >= 0
        game.aimAng = 0;
    else
        game.aimAng = pi;
    end

    % --------------- 移动与冲刺 ---------------
    if p.dashTimer > 0
        dashSpd = 6.0;
        p.vx = p.dashDirX * dashSpd;
        p.vy = p.dashDirY * dashSpd;
    else
        dx = 0;
        if held.left, dx = dx - 1; end
        if held.right, dx = dx + 1; end

        dy = 0;
        if held.up, dy = dy + 1; end
        if held.down, dy = dy - 1; end

        speed = 3.5;
        if p.buffLetsGo > 0
            % C技能保留加速，但给上限，避免技能期间速度/负载异常
            speed = speed * (1 + min(AS(idxC).bonusValue, 0.20));
        end

        if dx ~= 0 && dy ~= 0
            scale = 1/sqrt(2);
        else
            scale = 1;
        end

        p.vx = dx * speed * scale;
        p.vy = dy * speed * scale;

        if dx > 0
            p.facing = 1;
        elseif dx < 0
            p.facing = -1;
        end

        moving = (dx ~= 0 || dy ~= 0);
        if (pulse.dash || held.dash) && p.dashCd <= 0 && moving
            p.dashTimer = 10;
            p.dashCd = 60;
            n = sqrt(dx^2 + dy^2);
            p.dashDirX = dx / n;
            p.dashDirY = dy / n;
        end
    end

    % --------------- O/P切武器（已解锁） ---------------
    unlockedIdx = find(game.progress.unlockedWeapons);
    if isempty(unlockedIdx)
        unlockedIdx = 1;
        game.progress.unlockedWeapons(1) = true;
    end
    if pulse.prevWeapon
        p.weaponIdx = cycleUnlocked(p.weaponIdx, unlockedIdx, -1);
        p.weaponCd = 0;
        p.swapFx = 10;
    end
    if pulse.nextWeapon
        p.weaponIdx = cycleUnlocked(p.weaponIdx, unlockedIdx, +1);
        p.weaponCd = 0;
        p.swapFx = 10;
    end
    if ~ismember(p.weaponIdx, unlockedIdx)
        p.weaponIdx = unlockedIdx(1);
    end

    % 当前武器皮肤同步
    [mulDmg, mulFireRate, critBonus, mpReduce, skinIdx] = skinModifiers(game, p.weaponIdx);
    p.skinIdx = skinIdx;

    % --------------- 跳跃 ---------------
    if pulse.jump && p.onGround
        p.vz = 14;
        p.onGround = false;
    end

    % --------------- C/Q/E/X技能 ---------------
    if pulse.skillC && p.cdC <= 0 && p.mp >= AS(idxC).mpCost && p.buffLetsGo <= 0
        p.buffLetsGo = AS(idxC).duration;
        p.cdC = AS(idxC).cd;
        p.mp = p.mp - AS(idxC).mpCost;
        game = addPopup(game, p.x+p.w/2, p.y+p.h+26, 'Let''s够！', [0.4 1 0.6]);
        game = playSfx(game, 'skillC');
        p.castFx = 12;
    end

    if pulse.skillQ && p.cdQ <= 0 && p.mp >= AS(idxQ).mpCost && p.buffNice <= 0
        p.buffNice = AS(idxQ).duration;
        p.cdQ = AS(idxQ).cd;
        p.mp = p.mp - AS(idxQ).mpCost;
        game = addPopup(game, p.x+p.w/2, p.y+p.h+26, 'Niceeee', [1 0.85 0.3]);
        game = playSfx(game, 'skillQ');
        p.castFx = 12;
    end

    if pulse.skillE && p.cdE <= 0 && p.mp >= AS(idxE).mpCost
        p.cdE = AS(idxE).cd;
        p.mp = p.mp - AS(idxE).mpCost;
        p.dogTimer = AS(idxE).duration;
        p.dog.alive = true;
        p.dog.name = 'CXY';
        p.dog.x = p.x - 24;
        p.dog.y = p.y;
        p.dog.cd = 10;
        game = addPopup(game, p.x+p.w/2, p.y+p.h+30, 'CXY出击：这么能杀你杀完呗', [0.75 0.9 1]);
        game = playSfx(game, 'skillE');
        p.castFx = 14;
    end

    if pulse.skillX && p.cdX <= 0
        isBossRoom = isfield(game.room,'hasBoss') && game.room.hasBoss;
        if ~isBossRoom
            game = addPopup(game, p.x+p.w/2, p.y+p.h+24, 'X仅限Boss关', [1 0.55 0.55]);
            p.cdX = 30;
        elseif p.ultEnergy < p.ultEnergyMax
            game = addPopup(game, p.x+p.w/2, p.y+p.h+24, ...
                sprintf('X能量不足 %d/%d', round(p.ultEnergy), p.ultEnergyMax), [1 0.8 0.3]);
            p.cdX = 30;
        else
            p.buffUlt = AS(idxX).duration;
            p.cdX = AS(idxX).cd;
            p.ultEnergy = 0;
            game = addPopup(game, p.x+p.w/2, p.y+p.h+30, pickUltForm(game), [1 0.5 0.95]);
            game = playSfx(game, 'skillX');
            p.castFx = 18;
        end
    end

    % --------------- 协战犬行为（建模+攻击） ---------------
    if p.dog.alive && p.dogTimer > 0
        followX = p.x - p.facing * 26;
        followY = p.y - 8;
        p.dog.x = p.dog.x + (followX - p.dog.x) * 0.25;
        p.dog.y = p.dog.y + (followY - p.dog.y) * 0.25;

        if p.dog.cd > 0
            p.dog.cd = p.dog.cd - 1;
        else
            [ok, tx, ty] = nearestEnemyCenter(game.room, p.dog.x, p.dog.y, 240);
            if ok
                ang = atan2(ty - p.dog.y, tx - p.dog.x);
                b = makeDogBullet(p, ang);
                game = spawnBullet(game, b);
                p.dog.cd = 18;
            end
        end

        p.dogTimer = p.dogTimer - 1;
        if p.dogTimer <= 0
            p.dog.alive = false;
        end
    else
        p.dog.alive = false;
    end

    % --------------- 射击 ---------------
    W = game.weapons(p.weaponIdx);

    if p.buffLetsGo > 0
        % C技能保留射速提升，但限制上限避免触发大规模卡顿
        mulFireRate = mulFireRate * (1 + min(AS(idxC).bonusValue, 0.22));
    end
    if p.buffNice > 0
        mulDmg = mulDmg * (1 + AS(idxQ).bonusValue);
    end
    if p.buffUlt > 0
        mulDmg = mulDmg * (1 + AS(idxX).bonusValue);
    end

    minCd = 2;
    if p.buffLetsGo > 0
        minCd = 3; % C技能期间限制最小射击间隔，降低卡顿峰值
    end
    effectiveCd = max(minCd, round(W.cd / mulFireRate));
    effectiveMpCost = W.mpCost * (1 - mpReduce);

    wantShoot = held.shoot || pulse.shoot;
    canAffordMp = (W.mpCost == 0) || (p.mp >= effectiveMpCost);

    if wantShoot && p.weaponCd <= 0 && canAffordMp
        ang0 = game.aimAng;
        for s = 1:W.nShot

            if W.nShot > 1
                t = (s - (W.nShot+1)/2) / max(1,(W.nShot-1)/2);
                ang = ang0 + t * (W.spread/2);
            else
                ang = ang0 + (rand - 0.5) * W.spread;
            end

            muzX = p.x + p.w/2 + cos(ang0) * 18;
            muzY = p.y + p.h/2 + sin(ang0) * 14;

            b.x = muzX;
            b.y = muzY;
            b.z = p.z;
            b.vx = W.bulletSpd * cos(ang);
            b.vy = W.bulletSpd * sin(ang);
            b.vz = 0;
            b.owner = 'player';
            b.life = max(20, round(W.range / W.bulletSpd));

            critRate = W.critRate + critBonus;
            isCrit = rand < critRate;
            baseDmg = W.dmg * (1 + p.dmgBonus);
            finalDmg = baseDmg * mulDmg;
            if isCrit
                finalDmg = finalDmg * 2;
            end

            b.dmg = finalDmg;
            b.color = W.color;
            if skinIdx > 0
                b.color = game.skins(skinIdx).color;
            end
            b.crit = isCrit;
            b.pierce = false;
            b.explode = false;
            b.aoeR = 0;
            b.aoeDmgMul = 0;

            game = spawnBullet(game, b);
        end

        % 长按射击时降低音频触发频率，避免音频造成主线程卡顿
        if pulse.shoot || mod(game.stateTimer, 6) == 0
            game = playSfx(game, 'shoot');
        end
        p.shootFx = 5;
        p.weaponCd = effectiveCd;
        if W.mpCost > 0
            p.mp = max(0, p.mp - effectiveMpCost);
        end
    end

    % --------------- 冷却与回蓝 ---------------
    if p.weaponCd > 0, p.weaponCd = p.weaponCd - 1; end
    if p.skillCd > 0, p.skillCd = p.skillCd - 1; end
    if p.dashCd > 0, p.dashCd = p.dashCd - 1; end
    if p.dashTimer > 0, p.dashTimer = p.dashTimer - 1; end

    if p.cdC > 0, p.cdC = p.cdC - 1; end
    if p.cdQ > 0, p.cdQ = p.cdQ - 1; end
    if p.cdE > 0, p.cdE = p.cdE - 1; end
    if p.cdX > 0, p.cdX = p.cdX - 1; end

    if p.buffLetsGo > 0, p.buffLetsGo = p.buffLetsGo - 1; end
    if p.buffNice > 0, p.buffNice = p.buffNice - 1; end
    if p.buffUlt > 0, p.buffUlt = p.buffUlt - 1; end
    if p.shootFx > 0, p.shootFx = p.shootFx - 1; end
    if p.swapFx > 0, p.swapFx = p.swapFx - 1; end
    if p.castFx > 0, p.castFx = p.castFx - 1; end

    if mod(max(0, game.stateTimer), 15) == 0 && p.mp < p.mpMax
        p.mp = p.mp + 1;
    end

    game.player = p;
    game.inputPulse = clearPulse(pulse);
end

function pauseBattleBgm(game)
    if ~isfield(game,'fig') || isempty(game.fig) || ~ishandle(game.fig)
        return;
    end
    try
        if isappdata(game.fig,'bgm_player')
            p = getappdata(game.fig,'bgm_player');
            if ~isempty(p) && isvalid(p) && strcmp(p.Running,'on')
                pause(p);
            end
        end
    catch
    end
end

function resumeBattleBgm(game)
    if ~isfield(game,'fig') || isempty(game.fig) || ~ishandle(game.fig)
        return;
    end
    try
        if isappdata(game.fig,'bgm_player')
            p = getappdata(game.fig,'bgm_player');
            if ~isempty(p) && isvalid(p) && ~strcmp(p.Running,'on')
                resume(p);
            end
        end
    catch
    end
end

function b = makeDogBullet(p, ang)
    b = struct();
    b.x = p.dog.x;
    b.y = p.dog.y + 14;
    b.z = 0;
    b.vx = 11 * cos(ang);
    b.vy = 11 * sin(ang);
    b.vz = 0;
    b.owner = 'player';
    b.life = 28;
    b.dmg = 10 * (1 + p.dmgBonus);
    b.color = [1.00 0.90 0.45];
    b.crit = false;
    b.pierce = false;
    b.explode = false;
    b.aoeR = 0;
    b.aoeDmgMul = 0;
end

function [ok, tx, ty] = nearestEnemyCenter(room, x, y, maxR)
    ok = false;
    tx = 0; ty = 0;
    best = inf;
    for i = 1:numel(room.enemies)
        e = room.enemies(i);
        if ~e.alive
            continue;
        end
        cx = e.x + e.w/2;
        cy = e.y + e.h/2;
        d2 = (cx-x)^2 + (cy-y)^2;
        if d2 < best && d2 <= maxR^2
            best = d2;
            ok = true;
            tx = cx;
            ty = cy;
        end
    end
end

function idx = findSkillIdx(AS, id)
    idx = 1;
    for i = 1:numel(AS)
        if strcmp(AS(i).id, id)
            idx = i;
            return;
        end
    end
end

function idx = cycleUnlocked(cur, unlockedIdx, dir)
    if isempty(unlockedIdx)
        idx = cur;
        return;
    end
    pos = find(unlockedIdx == cur, 1);
    if isempty(pos)
        pos = 1;
    end
    newPos = mod(pos - 1 + dir, numel(unlockedIdx)) + 1;
    idx = unlockedIdx(newPos);
end

function game = addPopup(game, x, y, text, color)
    pop = struct('x',x,'y',y,'life',50,'text',text,'color',color);
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

function txt = pickUltForm(game)
    txt = '无双形态';
    if ~isfield(game.room,'bossType')
        return;
    end
    switch game.room.bossType
        case 'prodigy'
            txt = '流水的天才 铁打的康康';
        case 'peer'
            txt = '同龄对决 绝不降维';
        case 'legend'
            txt = '以下犯上';
    end
end

function pulse = clearPulse(pulse)
    fns = fieldnames(pulse);
    for i = 1:numel(fns)
        pulse.(fns{i}) = false;
    end
end

function held = resetHeld(held)
    fns = fieldnames(held);
    for i = 1:numel(fns)
        held.(fns{i}) = false;
    end
end
