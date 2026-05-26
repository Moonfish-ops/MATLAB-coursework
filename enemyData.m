function E = enemyData()
% enemyData 5 章节敌人原型表
% 章节基准数值沿用 NRG 模板；运行期通过 scaleEnemy 按 chapterMul × roomMul 缩放。

    E = repmat(mkChapter('','','',0,1.0,mkNormal('','melee',0,0,0,0,0,[0 0 0]),mkElite('','','',0,0,0,[0 0 0],emptySkillArray())),0,0);

    E(1) = mkChapter('NRG','NRG 2025','brawk',1,1.00, nrgNormals(), nrgElites());
    E(2) = mkChapter('SEN','Sentinels','tenz',2,1.20, senNormals(), senElites());
    E(3) = mkChapter('LOUD','LOUD','aspas',3,1.44, loudNormals(), loudElites());
    E(4) = mkChapter('FNC','Fnatic','derke',4,1.73, fncNormals(), fncElites());
    E(5) = mkChapter('PRX','Paper Rex','forsaken',5,2.07, prxNormals(), prxElites());
end

% ---------------- constructors ----------------

function c = mkChapter(teamId,teamName,bossId,mapId,mul,normals,elites)
    c = struct('teamId',teamId,'teamName',teamName,'bossId',bossId, ...
        'mapId',mapId,'chapterMul',mul, ...
        'normals',normals,'elites',elites);
end

function n = mkNormal(id,role,hp,dmg,spd,bspd,fireCd,color)
    n = struct('id',id,'displayName',id,'sourceRole',role, ...
        'hpBase',hp,'dmgBase',dmg,'speedBase',spd, ...
        'bulletSpdBase',bspd,'fireCdBase',fireCd, ...
        'w',26,'h',40,'color',color);
end

function e = mkElite(id,disp,kind,hp,dmg,spd,color,skills)
    e = struct('id',id,'displayName',disp,'kind',kind, ...
        'hpBase',hp,'dmgBase',dmg,'speedBase',spd, ...
        'w',30,'h',46,'color',color,'skills',skills);
end

function s = mkSkill(id,name,kind,dmg,cd,rng,bspd,aoeR,effect)
    s = struct('id',id,'name',name,'kind',kind, ...
        'dmgBase',dmg,'cdBase',cd,'rangeBase',rng, ...
        'bulletSpdBase',bspd,'aoeR',aoeR,'effect',effect);
end

function A = emptySkillArray()
    A = repmat(mkSkill('','','projectile',0,60,0,0,0,''),0,0);
end

% ---------------- NRG ----------------

function N = nrgNormals()
    N(1) = mkNormal('s0m','melee',40,10,2.4,0,0,[0.95 0.75 0.20]);
    N(2) = mkNormal('skuba','ranged',48,12,2.3,5,100,[0.85 0.65 0.15]);
    N(3) = mkNormal('bot','melee',40,10,2.4,0,0,[0.65 0.65 0.70]);
end

function E = nrgElites()
    ethan = [ ...
        mkSkill('scanPulse','侦测脉冲','projectile',12,180,360,6,0,'reveal'), ...
        mkSkill('suppressKnife','压制匕首','projectile',16,220,280,7,0,'silence'), ...
        mkSkill('shockFrag','震荡破片','aoe',14,260,280,5,56,'slow')];
    mada = [ ...
        mkSkill('rushDash','疾冲突脸','dash',18,200,220,0,0,''), ...
        mkSkill('burstTriple','爆发三连射','projectile_multi',14,220,360,7,0,''), ...
        mkSkill('phantomRoll','残影翻滚','evade',0,260,0,0,0,'')];
    E(1) = mkElite('ethan','Ethan','infoSuppress',180,18,2.6,[0.95 0.80 0.30],ethan);
    E(2) = mkElite('mada','mada','burstRush',210,20,2.5,[1.00 0.60 0.25],mada);
end

% ---------------- Sentinels ----------------

function N = senNormals()
    N(1) = mkNormal('bot_sen_a','melee',40,10,2.4,0,0,[0.80 0.80 0.85]);
    N(2) = mkNormal('bot_sen_b','ranged',48,12,2.3,5,100,[0.85 0.90 0.95]);
end

function E = senElites()
    sick = [ ...
        mkSkill('flameRush','火焰突进','dash',20,220,260,0,0,'slow'), ...
        mkSkill('burstShot','爆发点射','projectile_multi',16,200,340,7,0,''), ...
        mkSkill('counterShift','逆压换位','evade',0,240,0,0,0,'')];
    shahzam = [ ...
        mkSkill('snipeBeam','高精度狙击线','projectile',24,280,520,10,0,''), ...
        mkSkill('flashBlock','闪光封路','aoe',8,300,260,4,64,'stun'), ...
        mkSkill('holdFire','定点压制射击','projectile',18,180,420,8,0,'')];
    E(1) = mkElite('sick','SicK','burstRush',180,18,2.6,[1.00 0.45 0.25],sick);
    E(2) = mkElite('shahzam','ShahZaM','anchor',210,20,2.5,[1.00 0.80 0.30],shahzam);
end

% ---------------- LOUD ----------------

function N = loudNormals()
    N(1) = mkNormal('bot_loud_a','melee',40,10,2.4,0,0,[0.35 0.85 0.45]);
    N(2) = mkNormal('bot_loud_b','ranged',48,12,2.3,5,100,[0.25 0.75 0.55]);
end

function E = loudElites()
    less = [ ...
        mkSkill('autoTurret','自动炮台','summon',0,340,0,0,0,'summonBot'), ...
        mkSkill('mineSlow','地雷减速区','aoe',16,260,280,4,72,'slow'), ...
        mkSkill('crossfire','交叉火力封锁','projectile_multi',18,220,380,7,0,'')];
    pancada = [ ...
        mkSkill('smokeBlock','烟幕封视野','aoe',10,260,280,4,80,'reveal'), ...
        mkSkill('darkMist','黑雾削弱区','aoe',14,280,280,4,72,'silence'), ...
        mkSkill('midSuppress','中距离稳定压枪','projectile',22,180,380,8,0,'')];
    E(1) = mkElite('less','Less','anchor',180,18,2.6,[0.30 0.80 0.55],less);
    E(2) = mkElite('pancada','pANcada','support',210,20,2.5,[0.45 0.90 0.65],pancada);
end

% ---------------- Fnatic ----------------

function N = fncNormals()
    N(1) = mkNormal('bot_fnc_a','melee',40,10,2.4,0,0,[1.00 0.50 0.35]);
    N(2) = mkNormal('bot_fnc_b','ranged',48,12,2.3,5,100,[1.00 0.65 0.40]);
end

function E = fncElites()
    leo = [ ...
        mkSkill('reconArrow','侦查箭','projectile',18,200,420,8,0,'reveal'), ...
        mkSkill('slowZone','减速区域','aoe',14,260,280,4,84,'slow'), ...
        mkSkill('suppressRound','范围压制弹','projectile_multi',20,220,360,7,0,'')];
    alfajer = [ ...
        mkSkill('turretLock','炮台封点','summon',0,360,0,0,0,'summonBot'), ...
        mkSkill('nanoZone','纳米伤害区','aoe',20,280,280,4,80,'debuff'), ...
        mkSkill('shieldBoost','护盾强化','buff',0,340,0,0,0,'speedUp')];
    E(1) = mkElite('leo','Leo','infoSuppress',180,18,2.6,[1.00 0.55 0.35],leo);
    E(2) = mkElite('alfajer','Alfajer','anchor',210,20,2.5,[1.00 0.75 0.45],alfajer);
end

% ---------------- Paper Rex ----------------

function N = prxNormals()
    N(1) = mkNormal('bot_prx_a','melee',40,10,2.4,0,0,[0.50 0.30 0.75]);
    N(2) = mkNormal('bot_prx_b','ranged',48,12,2.3,5,100,[0.75 0.45 0.90]);
end

function E = prxElites()
    jinggg = [ ...
        mkSkill('blastJump','爆裂跳跃','dash',24,220,260,0,0,''), ...
        mkSkill('grenadeBomb','榴弹轰炸','aoe',26,260,340,5,96,'slow'), ...
        mkSkill('closeBurst','近身喷射爆发','projectile_multi',22,200,300,7,0,'')];
    something = [ ...
        mkSkill('extremeShift','极限位移','dash',20,180,280,0,0,''), ...
        mkSkill('highSpeedTap','高速点射','projectile',24,160,400,9,0,''), ...
        mkSkill('airReposition','空中改位攻击','dash',18,220,260,0,0,'')];
    E(1) = mkElite('jinggg','Jinggg','burstRush',180,18,2.6,[0.95 0.45 0.85],jinggg);
    E(2) = mkElite('something','something','burstRush',210,20,2.5,[0.60 0.45 0.95],something);
end
