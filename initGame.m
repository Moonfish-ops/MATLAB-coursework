function game = initGame()
% initGame 初始化游戏状态

    game.screenW = 960;
    game.screenH = 540;
    game.fps = 60;
    game.gravity = 0.8;
    game.maxBullets = 180;
    game.maxPopups = 18;
    game.aiTickInterval = 1;
    game.perfMode = true;

    game.running = true;
    game.returnToMenu = false;
    game.quitApp = false;

    game.state = 'playing';
    game.stateTimer = 0;

    baseDir = fileparts(mfilename('fullpath'));

    game.weapons = createWeapons();
    game.skills = createSkills(); %#ok<NASGU>
    game.activeSkills = skillData();
    game.skins = skinData();
    game.skins = importSkinImages(game.skins, baseDir);
    game.weaponSkinMap = weaponSkinMap(game.skins);
    game.bosses = bossData();
    game.unlockRules = weaponUnlockData();
    game.levelCache = createLevelData();
    game.totalLevels = numel(game.levelCache);

    game.keybinds = keybindData();
    game.options = struct('volume',0.8,'uiScale',1.0);

    game.saveFile = fullfile(baseDir, 'savegame.mat');
    game.audio = initAudio(baseDir);

    game.progress = initProgress(game);
    game.currentSkin = game.progress.equippedSkinByWeapon;

    p = struct();
    p.name = '康康';
    p.age = 22;
    p.honorTier = 2;
    p.w = 28; p.h = 44;
    p.x = 60; p.y = 240; p.z = 0;
    p.vx = 0; p.vy = 0; p.vz = 0;
    p.facing = 1;
    p.onGround = true;
    p.hpMax = 100; p.hp = 100;
    p.mpMax = 60; p.mp = 60;
    p.coins = 0;
    p.stars = 0;
    p.invincible = 0;
    p.hitFlash = 0;

    p.weaponIdx = firstUnlockedWeapon(game.progress.unlockedWeapons);
    p.weaponCd = 0;

    p.skillIdx = 1;
    p.skillCd = 0;

    p.cdC = 0; p.cdQ = 0; p.cdE = 0; p.cdX = 0;
    p.buffLetsGo = 0;
    p.buffNice = 0;
    p.buffUlt = 0;

    p.dogTimer = 0;
    p.dog = struct('x',0,'y',0,'cd',0,'alive',false,'name','CXY');

    p.ultEnergy = 0;
    p.ultEnergyMax = 100;

    p.dashTimer = 0;
    p.dashCd = 0;
    p.dashDirX = 1;
    p.dashDirY = 0;

    p.level = 1;
    p.exp = 0;
    p.expNext = 100;
    p.dmgBonus = 0;

    p.skinIdx = 0;
    p.shootFx = 0;
    p.swapFx = 0;
    p.castFx = 0;
    p.playerSprite = '';
    p.playerParts = struct('head',[],'torso',[],'armL',[],'armR',[],'legL',[],'legR',[],'weapon',[]);
    p.playerAnimState = struct('state','idle','sprite','','parts','geom_v1');

    game.player = p;

    game.bullets = emptyBullet();
    game.popups = repmat(struct('x',0,'y',0,'life',0,'text','','color',[1 1 1]),0,0);

    game.inputHeld = emptyActionState(game.keybinds.actions);
    game.inputPulse = emptyActionState(game.keybinds.actions);

    game.mouseX = game.screenW/2;
    game.mouseY = game.screenH/2;
    game.aimAng = 0;

    game.camera = struct('x',0,'y',0);

    game.pendingTransition = struct('type','','level',1,'room',1);
    game.warehouseCooldown = 0;

    game.currentLevel = 1;
    game.currentRoom = 1;
    game.level = struct();
    game.room = struct();

    game.fig = [];
    game.ax = [];
    game.hudAx = [];
    game.scene = struct();
    game.hud = struct();
end

function A = emptyActionState(actions)
    A = struct();
    for i = 1:numel(actions)
        A.(actions{i}) = false;
    end
end

function idx = firstUnlockedWeapon(flags)
    idx = find(flags,1);
    if isempty(idx)
        idx = 1;
    end
end

function B = emptyBullet()
    B = repmat(struct( ...
        'x',0,'y',0,'z',0, ...
        'vx',0,'vy',0,'vz',0, ...
        'owner','','life',0, ...
        'dmg',0,'color',[1 1 1],'crit',false, ...
        'pierce',false,'explode',false, ...
        'aoeR',0,'aoeDmgMul',0), 0, 0);
end
