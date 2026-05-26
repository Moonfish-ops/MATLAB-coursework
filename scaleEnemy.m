function e = scaleEnemy(proto, kind, chapterMul, roomMul, x, y)
% scaleEnemy 把原型 proto 实例化为 runtime 敌人 struct
% kind : 'normal' | 'elite' | 'boss'
% 所有敌人返回一致字段集合，便于拼接为 struct array。

    mul = chapterMul * roomMul;

    e = blankEnemy();
    e.x = x;
    e.y = y;
    e.enemyId     = proto.id;
    e.displayName = fieldOr(proto,'displayName', proto.id);
    e.color       = proto.color;
    e.w           = proto.w;
    e.h           = proto.h;

    e.chapterMul  = chapterMul;
    e.roomMul     = roomMul;

    e.hpMax = round(proto.hpBase * mul);
    e.hp    = e.hpMax;
    e.speed = proto.speedBase * sqrt(mul);
    e.dmg   = round(proto.dmgBase * mul);

    switch kind
        case 'normal'
            if strcmp(proto.sourceRole,'melee')
                e.type = 'melee';
            else
                e.type = 'ranged';
                e.bulletSpd = proto.bulletSpdBase * sqrt(mul);
                e.fireCd    = max(20, round(proto.fireCdBase / sqrt(mul)));
            end

        case 'elite'
            if strcmp(proto.kind,'burstRush')
                e.type = 'eliteMelee';
            else
                e.type = 'eliteRanged';
            end
            e.skills = scaleSkillArray(proto.skills, mul);
            e.cdTimers = initCdTimers(proto.skills, mul);

        case 'boss'
            e.type     = 'boss';
            e.shieldMax = round(proto.shieldBase * mul);
            e.shield    = e.shieldMax;
            e.skills    = scaleSkillArray(proto.phase1Skills, mul);
            e.cdTimers  = initCdTimers(proto.phase1Skills, mul);
            e.bossProto = proto;   % 留一份原型以便阶段切换
            e.phase     = 1;
    end
end

function e = blankEnemy()
    e = struct( ...
        'x',0,'y',0,'z',0, ...
        'vx',0,'vy',0,'vz',0, ...
        'w',26,'h',40, ...
        'hp',40,'hpMax',40,'alive',true, ...
        'type','melee', ...
        'dir',-1,'facing',-1, ...
        'speed',2.4,'dmg',10, ...
        'aiTimer',randi([30 90]),'shootTimer',randi([80 160]), ...
        'hit',0,'deathAnim',0, ...
        'attackMode',1,'modeTimer',180, ...
        'chargeVx',0,'chargeVy',0, ...
        'enemyId','','displayName','','color',[1 1 1], ...
        'bulletSpd',0,'fireCd',0, ...
        'skills',emptySkillArray(),'cdTimers',[], ...
        'phase',1,'shield',0,'shieldMax',0, ...
        'chapterMul',1,'roomMul',1, ...
        'bossProto',struct(), ...
        'slowTimer',0,'stunTimer',0,'buffTimer',0,'buffMul',1.0);
end

function out = scaleSkillArray(skills, mul)
    out = repmat(skills(1), 1, numel(skills));
    for i = 1:numel(skills)
        out(i) = scaleSkill(skills(i), mul);
    end
end

function cds = initCdTimers(skills, mul)
    n = numel(skills);
    cds = zeros(1,n);
    for i = 1:n
        base = max(24, round(skills(i).cdBase / sqrt(mul)));
        cds(i) = round(base * 0.4) + randi(max(1,round(base*0.3)));
    end
end

function A = emptySkillArray()
    A = repmat(struct('id','','name','','kind','projectile', ...
        'dmgBase',0,'cdBase',60,'rangeBase',0, ...
        'bulletSpdBase',0,'aoeR',0,'effect','', ...
        'dmg',0,'cd',60,'range',0,'bulletSpd',0), 0, 0);
end

function v = fieldOr(s, f, d)
    if isfield(s, f) && ~isempty(s.(f))
        v = s.(f);
    else
        v = d;
    end
end
