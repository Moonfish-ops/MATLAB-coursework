function S = createSkills()
% createSkills 兼容旧L技能系统（当前主要使用C/Q/E/X）

    i = 0;

    i=i+1;
    S(i).id = 'spread';
    S(i).name = '散射弹';
    S(i).mpCost = 15;
    S(i).cd = 60;
    S(i).nShot = 7;
    S(i).spread = 1.0;
    S(i).dmg = 8;
    S(i).bulletSpd = 12;
    S(i).range = 380;
    S(i).color = [1.0 0.4 1.0];
    S(i).type = 'normal';
    S(i).aoeR = 0;
    S(i).aoeDmgMul = 0;

    i=i+1;
    S(i).id = 'pierce';
    S(i).name = '穿透弹';
    S(i).mpCost = 20;
    S(i).cd = 90;
    S(i).nShot = 1;
    S(i).spread = 0;
    S(i).dmg = 18;
    S(i).bulletSpd = 18;
    S(i).range = 760;
    S(i).color = [0.4 1.0 0.6];
    S(i).type = 'pierce';
    S(i).aoeR = 0;
    S(i).aoeDmgMul = 0;

    i=i+1;
    S(i).id = 'explode';
    S(i).name = '爆炸弹';
    S(i).mpCost = 30;
    S(i).cd = 120;
    S(i).nShot = 1;
    S(i).spread = 0;
    S(i).dmg = 22;
    S(i).bulletSpd = 11;
    S(i).range = 520;
    S(i).color = [1.0 0.55 0.2];
    S(i).type = 'explode';
    S(i).aoeR = 85;
    S(i).aoeDmgMul = 0.7;
end
