function W = createWeapons()
% createWeapons 将 weaponData 转换为战斗可用结构

    T = weaponData();
    N = numel(T);
    W = repmat(blankWeapon(), 1, N);

    for i = 1:N
        t = T(i);
        w = blankWeapon();

        w.id = t.id;
        w.cname = t.cname;
        w.name = t.cname;
        w.category = t.category;
        w.dmg = t.dmg;
        w.fireRate = t.fireRate;
        w.cd = max(1, round(60 / max(0.1, t.fireRate)));
        w.mpCost = t.mpCost;
        w.reload = t.reload;
        w.critRate = t.critRate;
        w.unlockLevel = 1;
        w.skinHint = t.skinHint;

        [w.bulletSpd, w.range, w.nShot, w.spread, w.color] = visualByCategory(t.category);

        W(i) = w;
    end
end

function w = blankWeapon()
    w = struct( ...
        'id','','cname','','name','','category','', ...
        'dmg',0,'fireRate',0,'cd',10,'mpCost',0,'reload',0,'critRate',0, ...
        'unlockLevel',1,'bulletSpd',12,'range',480,'nShot',1,'spread',0, ...
        'color',[1 1 1],'skinHint','');
end

function [bulletSpd, range, nShot, spread, color] = visualByCategory(cat)
    switch cat
        case 'knife'
            bulletSpd = 18; range = 110; nShot = 1; spread = 0.00; color = [0.85 0.90 1.00];
        case 'pistol'
            bulletSpd = 13; range = 460; nShot = 1; spread = 0.02; color = [1.00 1.00 0.30];
        case 'smg'
            bulletSpd = 14; range = 400; nShot = 1; spread = 0.06; color = [0.40 1.00 1.00];
        case 'shotgun'
            bulletSpd = 12; range = 260; nShot = 1; spread = 0.00; color = [1.00 0.55 0.20];
        case 'rifle'
            bulletSpd = 15; range = 540; nShot = 1; spread = 0.035; color = [0.70 0.90 1.00];
        case 'sniper'
            bulletSpd = 22; range = 720; nShot = 1; spread = 0.00; color = [1.00 0.30 0.60];
        case 'heavy'
            bulletSpd = 15; range = 560; nShot = 1; spread = 0.08; color = [1.00 0.35 0.35];
        otherwise
            bulletSpd = 12; range = 420; nShot = 1; spread = 0.02; color = [1 1 1];
    end
end
