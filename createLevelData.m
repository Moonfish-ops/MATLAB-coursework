function levels = createLevelData()
% createLevelData 5张地图 x 每图3关卡（房间）

    unlock = weaponUnlockData();
    mapNames = unlock.mapNames;
    bosses = bossData();

    levels = cell(1,5);
    levels{1} = buildMap(1, mapNames{1}, bosses(1));
    levels{2} = buildMap(2, mapNames{2}, bosses(2));
    levels{3} = buildMap(3, mapNames{3}, bosses(3));
    levels{4} = buildMap(4, mapNames{4}, bosses(4));
    levels{5} = buildMap(5, mapNames{5}, bosses(5));
end

function L = buildMap(mapId, mapName, bossInfo)
    yPlane = [100 380];
    base = palette(mapId);

    rooms = cell(1,3);

    switch mapId
        case 1
            rooms{1} = makeRoom(mapId,mapName,1,yPlane,base.bg,'normal', ...
                zeros(0,4), ...
                {pk(280,220,'coin'),pk(340,220,'coin'),pk(520,260,'mana')}, ...
                {enemy(560,210,'melee'),enemy(740,290,'melee')}, ...
                false,bossInfo.bossType);
            rooms{2} = makeRoom(mapId,mapName,2,yPlane,base.mid,'normal', ...
                [420 210 80 60], ...
                {pk(250,180,'coin'),pk(680,300,'heart')}, ...
                {enemy(520,180,'melee'),enemy(680,300,'ranged'),enemy(820,260,'melee')}, ...
                false,bossInfo.bossType);

        case 2
            rooms{1} = makeRoom(mapId,mapName,1,yPlane,base.bg,'normal', ...
                [400 170 100 100], ...
                {pk(260,260,'coin'),pk(620,280,'mana')}, ...
                {enemy(540,200,'melee'),enemy(720,320,'ranged'),enemy(820,220,'melee')}, ...
                false,bossInfo.bossType);
            rooms{2} = makeRoom(mapId,mapName,2,yPlane,base.mid,'elite', ...
                [170 160 90 90; 700 300 80 70], ...
                {pk(460,220,'heart'),pk(540,220,'mana')}, ...
                {enemy(520,200,'eliteMelee'),enemy(780,300,'eliteRanged')}, ...
                false,bossInfo.bossType);

        case 3
            rooms{1} = makeRoom(mapId,mapName,1,yPlane,base.bg,'reward', ...
                zeros(0,4), ...
                {pk(280,200,'heart'),pk(340,200,'mana'),pk(420,260,'coin'),pk(480,260,'coin'),pk(620,220,'star')}, ...
                {}, ...
                false,bossInfo.bossType);
            rooms{2} = makeRoom(mapId,mapName,2,yPlane,base.mid,'elite', ...
                [360 240 120 70], ...
                {pk(260,160,'mana')}, ...
                {enemy(460,180,'eliteMelee'),enemy(740,200,'eliteRanged'),enemy(820,320,'eliteMelee')}, ...
                false,bossInfo.bossType);

        case 4
            rooms{1} = makeRoom(mapId,mapName,1,yPlane,base.bg,'normal', ...
                [300 160 120 80; 620 280 120 80], ...
                {pk(240,220,'coin'),pk(700,300,'heart')}, ...
                {enemy(520,180,'eliteMelee'),enemy(760,300,'ranged'),enemy(840,220,'eliteRanged')}, ...
                false,bossInfo.bossType);
            rooms{2} = makeRoom(mapId,mapName,2,yPlane,base.mid,'elite', ...
                [180 280 100 70; 700 170 100 70], ...
                {pk(500,240,'mana')}, ...
                {enemy(420,160,'eliteMelee'),enemy(650,300,'eliteRanged'),enemy(820,240,'eliteMelee')}, ...
                false,bossInfo.bossType);

        otherwise % map 5
            rooms{1} = makeRoom(mapId,mapName,1,yPlane,base.bg,'elite', ...
                [250 180 120 100; 620 220 120 100], ...
                {pk(330,160,'mana'),pk(660,300,'heart')}, ...
                {enemy(450,170,'eliteMelee'),enemy(700,300,'eliteRanged'),enemy(820,210,'eliteMelee')}, ...
                false,bossInfo.bossType);
            rooms{2} = makeRoom(mapId,mapName,2,yPlane,base.mid,'reward', ...
                zeros(0,4), ...
                {pk(260,200,'star'),pk(320,200,'coin'),pk(380,200,'coin'),pk(560,260,'mana'),pk(640,260,'heart')}, ...
                {}, ...
                false,bossInfo.bossType);
    end

    rooms{3} = makeBossRoom(mapId,mapName,yPlane,base.dark,bossInfo);

    L.name = mapName;
    L.mapId = mapId;
    L.rooms = rooms;
end

function R = makeBossRoom(mapId,mapName,yPlane,bg,bossInfo)
    hz = bossHazardsByMap(mapId);
    R = makeRoom(mapId,mapName,3,yPlane,bg,'boss', ...
        hz, ...
        {pk(240,230,'heart'),pk(300,230,'mana'),pk(360,230,'coin')}, ...
        {enemy(720,240,'boss')}, ...
        true,bossInfo.bossType);
end

function hz = bossHazardsByMap(mapId)
    switch mapId
        case 1
            hz = [300 150 120 40; 560 300 120 40];
        case 2
            hz = [250 180 110 70; 610 230 110 70];
        case 3
            hz = [430 130 100 60; 430 300 100 60];
        case 4
            hz = [210 150 90 90; 430 240 90 90; 650 150 90 90];
        otherwise
            % 最终图：交错封路，明显偏向Boss机动压制
            hz = [220 150 120 70; 430 245 120 70; 640 150 120 70];
    end
end

function R = makeRoom(mapId,mapName,roomIndex,yPlane,bg,labelType,hazards,pickups,enemies,isFinal,bossType)
    R.w = 960;
    R.h = 540;
    R.yMin = yPlane(1);
    R.yMax = yPlane(2);
    R.bgColor = bg;
    R.mapId = mapId;
    R.mapName = mapName;
    R.roomIndex = roomIndex;
    R.label = sprintf('%s - 第%d关', mapName, roomIndex);
    R.type = labelType;
    R.theme = mapId;

    if isempty(hazards)
        R.hazards = zeros(0,4);
    else
        R.hazards = hazards;
    end

    protoP = struct('x',0,'y',0,'type','coin','alive',false,'skinIdx',0);
    if isempty(pickups)
        R.pickups = repmat(protoP,0,0);
    else
        arr = [pickups{:}];
        if ~isfield(arr,'skinIdx')
            for i = 1:numel(arr)
                arr(i).skinIdx = 0;
            end
        end
        R.pickups = arr;
    end

    protoE = enemy(0,0,'melee');
    if isempty(enemies)
        R.enemies = repmat(protoE,0,0);
    else
        R.enemies = [enemies{:}];
    end

    R.isFinal = isFinal;
    R.hasBoss = strcmp(labelType,'boss');
    R.bossType = bossType;
    R.cleared = isempty(R.enemies);
    R.doorOpen = R.cleared;
end

function c = palette(mapId)
    switch mapId
        case 1
            c.bg = [0.28 0.38 0.50];
            c.mid = [0.30 0.43 0.58];
            c.dark = [0.18 0.24 0.34];
        case 2
            c.bg = [0.52 0.34 0.26];
            c.mid = [0.60 0.40 0.30];
            c.dark = [0.34 0.20 0.15];
        case 3
            c.bg = [0.42 0.28 0.45];
            c.mid = [0.50 0.34 0.54];
            c.dark = [0.25 0.16 0.32];
        case 4
            c.bg = [0.30 0.34 0.30];
            c.mid = [0.36 0.40 0.36];
            c.dark = [0.18 0.22 0.18];
        otherwise
            c.bg = [0.18 0.24 0.30];
            c.mid = [0.22 0.30 0.38];
            c.dark = [0.10 0.14 0.20];
    end
end

function e = enemy(x,y,type)
    e = struct( ...
        'x',x,'y',y,'z',0, ...
        'vx',0,'vy',0,'vz',0, ...
        'w',26,'h',40, ...
        'hp',3,'hpMax',3,'alive',true, ...
        'type',type, ...
        'archetype','', ...
        'dir',-1,'facing',-1, ...
        'speed',1.6,'dmg',1, ...
        'aiTimer',randi([30 90]), ...
        'shootTimer',randi([80 160]), ...
        'castTimer',0,'recoverTimer',0, ...
        'phase',1, ...
        'hit',0,'deathAnim',0, ...
        'attackMode',1,'modeTimer',180, ...
        'chargeVx',0,'chargeVy',0);

    switch type
        case 'melee'
            e.hp=82; e.hpMax=82; e.speed=1.05; e.dmg=9;
            if mod(round(x/60),2)==0
                e.archetype = 'rusher';   % 突进型
            else
                e.archetype = 'defender'; % 防御型
                e.hp = e.hp * 1.22;
                e.hpMax = e.hp;
                e.speed = e.speed * 0.72;
            end
        case 'ranged'
            e.hp=66; e.hpMax=66; e.speed=0.75; e.dmg=7;
            if mod(round(y/30),2)==0
                e.archetype = 'gunner';   % 枪手型
            else
                e.archetype = 'bomber';   % 爆炸/抛射型（第一版以慢速散射实现）
                e.hp = e.hp * 1.08;
                e.hpMax = e.hp;
            end
        case 'eliteMelee'
            e.hp=360; e.hpMax=360; e.speed=1.45; e.dmg=15; e.w=30; e.h=46;
            e.archetype = 'eliteRusher';
        case 'eliteRanged'
            e.hp=300; e.hpMax=300; e.speed=1.0; e.dmg=12; e.w=28; e.h=44;
            e.archetype = 'eliteGunner';
        case 'boss'
            e.hp=1000; e.hpMax=1000; e.speed=1.0; e.dmg=20; e.w=56; e.h=72;
            e.archetype = 'boss';
    end
end

function p = pk(x,y,type)
    p = struct('x',x,'y',y,'type',type,'alive',true,'skinIdx',0);
end
