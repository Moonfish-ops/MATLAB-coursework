function game = useSkill(game)
% useSkill 兼容旧系统（当前主流程不再绑定L）

    p = game.player;
    if p.skillIdx < 1 || p.skillIdx > numel(game.skills)
        return;
    end

    S = game.skills(p.skillIdx);
    [~,~,~,mpReduce] = skinModifiers(game, p.weaponIdx);
    mpCost = max(0, S.mpCost * (1 - mpReduce));
    if p.mp < mpCost || p.skillCd > 0
        return;
    end

    ang0 = game.aimAng;
    switch S.id
        case 'spread'
            half = S.spread / 2;
            for s = 1:S.nShot
                if S.nShot > 1
                    t = (s - (S.nShot+1)/2) / max(1,(S.nShot-1)/2);
                else
                    t = 0;
                end
                ang = ang0 + t * half;
                game = spawnBullet(game, makeSkillBullet(p,S,ang,false,false));
            end
        case 'pierce'
            game = spawnBullet(game, makeSkillBullet(p,S,ang0,true,false));
        case 'explode'
            game = spawnBullet(game, makeSkillBullet(p,S,ang0,false,true));
    end

    p.mp = p.mp - mpCost;
    p.skillCd = S.cd;
    game.player = p;
end

function b = makeSkillBullet(p,S,ang,pierce,explode)
    b.x  = p.x + p.w/2 + cos(ang)*18;
    b.y  = p.y + p.h/2 + sin(ang)*14;
    b.z  = p.z;
    b.vx = S.bulletSpd * cos(ang);
    b.vy = S.bulletSpd * sin(ang);
    b.vz = 0;
    b.owner = 'player';
    b.life = max(20, round(S.range / S.bulletSpd));
    b.dmg = S.dmg * (1 + p.dmgBonus);
    b.color = S.color;
    b.crit = false;
    b.pierce = pierce;
    b.explode = explode;
    b.aoeR = S.aoeR;
    b.aoeDmgMul = S.aoeDmgMul;
end
