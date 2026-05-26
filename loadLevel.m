function game = loadLevel(game, levelIdx, roomIdx)
% loadLevel 加载关卡与房间

    nLevels = numel(game.levelCache);
    levelIdx = max(1, min(levelIdx, nLevels));

    L = game.levelCache{levelIdx};
    nRooms = numel(L.rooms);
    roomIdx = max(1, min(roomIdx, nRooms));

    game.totalLevels = nLevels;
    game.currentLevel = levelIdx;
    game.currentRoom = roomIdx;
    game.level = L;
    game.room = L.rooms{roomIdx};

    % 数值梯度：地图和关卡越靠后越难
    lvMul = 1 + 0.16 * (levelIdx - 1); % 小怪随地图提升
    roomMul = 1 + 0.08 * (roomIdx - 1); % 同图后续关卡再提升

    for i = 1:numel(game.room.enemies)
        e = game.room.enemies(i);
        if strcmp(e.type,'boss')
            b = game.bosses(levelIdx);
            bossHp = b.hpBase * (1 + 0.10 * (roomIdx - 1));
            e.hp = bossHp;
            e.hpMax = bossHp;
            e.dmg = e.dmg * (1.05 + 0.12 * (levelIdx - 1));
            e.speed = e.speed * (1.00 + 0.01 * (levelIdx - 1));
            e.modeTimer = randi([120 180]);
            e.shootTimer = 22;
        else
            e.hp = e.hp * lvMul * roomMul;
            e.hpMax = e.hp;
            e.dmg = e.dmg * (1 + 0.12 * (levelIdx - 1) + 0.05 * (roomIdx - 1));
            e.speed = e.speed * (1 + 0.008 * (levelIdx - 1));
            % 小怪射速放慢：地图越后期也不再加快过多
            e.shootTimer = max(32, round(e.shootTimer * (1 + 0.05 * (levelIdx - 1))));
        end
        game.room.enemies(i) = e;
    end

    p = game.player;
    p.x = 60;
    p.y = (game.room.yMin + game.room.yMax)/2;
    p.z = 0;
    p.vx = 0; p.vy = 0; p.vz = 0;
    p.onGround = true;
    p.invincible = 0;
    p.hitFlash = 0;
    p.facing = 1;

    p.hp = p.hpMax;
    p.mp = p.mpMax;

    if ~isUnlocked(game, p.weaponIdx)
        p.weaponIdx = firstUnlockedWeapon(game.progress.unlockedWeapons);
    end

    p.weaponCd = 0;
    p.skillCd = 0;
    p.dashTimer = 0;
    p.dashCd = 0;

    p.cdC = 0; p.cdQ = 0; p.cdE = 0; p.cdX = 0;
    p.buffLetsGo = 0; p.buffNice = 0; p.buffUlt = 0;
    p.dogTimer = 0; p.dog.alive = false; p.dog.cd = 0; p.dog.name = 'CXY';
    p.shootFx = 0; p.swapFx = 0; p.castFx = 0;

    eq = game.progress.equippedSkinByWeapon;
    if p.weaponIdx <= numel(eq)
        p.skinIdx = eq(p.weaponIdx);
    else
        p.skinIdx = 0;
    end

    game.player = p;

    game.bullets = repmat(struct( ...
        'x',0,'y',0,'z',0,'vx',0,'vy',0,'vz',0, ...
        'owner','','life',0,'dmg',0,'color',[1 1 1],'crit',false, ...
        'pierce',false,'explode',false,'aoeR',0,'aoeDmgMul',0), 0, 0);
    game.popups  = repmat(struct('x',0,'y',0,'life',0,'text','','color',[1 1 1]),0,0);

    game.camera = struct('x',0,'y',0);
    game.state = 'playing';
    game.stateTimer = 0;

    game.inputPulse = resetPulse(game.inputPulse);

    game.progress.lastCheckpoint = [levelIdx roomIdx];

    if isfield(game,'ax') && ~isempty(game.ax) && ishandle(game.ax)
        game = initScene(game);
    end
end

function tf = isUnlocked(game, weaponIdx)
    tf = weaponIdx >= 1 && weaponIdx <= numel(game.progress.unlockedWeapons) && game.progress.unlockedWeapons(weaponIdx);
end

function idx = firstUnlockedWeapon(flags)
    idx = find(flags,1);
    if isempty(idx)
        idx = 1;
    end
end

function s = resetPulse(s)
    fns = fieldnames(s);
    for i = 1:numel(fns)
        s.(fns{i}) = false;
    end
end
