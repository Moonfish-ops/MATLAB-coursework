function T = weaponData()
% weaponData 12把武器配置（展示名中文）

    i = 0;

    i=i+1; T(i)=mk('standard','标配','pistol',12,4.0,0,1.5,0.05);
    i=i+1; T(i)=mk('ghost','鬼魅','pistol',20,3.5,0,1.7,0.08);
    i=i+1; T(i)=mk('stinger','蜂刺','smg',9,12.0,0,2.0,0.03);

    i=i+1; T(i)=mk('sheriff','飞将','pistol',42,1.4,0,2.2,0.15);
    i=i+1; T(i)=mk('spectre','骇灵','smg',11,9.5,0,2.2,0.05);
    i=i+1; T(i)=mk('bucky','雄鹿','shotgun',48,1.0,0,2.4,0.06);

    i=i+1; T(i)=mk('bulldog','獠犬','rifle',18,7.0,0,2.4,0.07);
    i=i+1; T(i)=mk('guardian','戍卫','rifle',34,2.3,0,2.5,0.12);
    i=i+1; T(i)=mk('phantom','幻影','rifle',16,8.8,0,2.4,0.08);

    i=i+1; T(i)=mk('vandal','狂徒','rifle',20,8.0,0,2.5,0.10);
    i=i+1; T(i)=mk('operator','重狙','sniper',95,0.45,2,3.4,0.25);
    i=i+1; T(i)=mk('knife','小刀','knife',18,2.2,0,0,0.10);

    for k = 1:numel(T)
        T(k).unlockLevel = 1; % 解锁由 weaponUnlockData + progress 控制
        T(k).skinHint = '见仓库属性';
    end
end

function t = mk(id,cname,category,dmg,fireRate,mpCost,reload,critRate)
    t = struct('id',id,'cname',cname,'category',category, ...
        'dmg',dmg,'fireRate',fireRate,'mpCost',mpCost, ...
        'reload',reload,'critRate',critRate, ...
        'unlockLevel',1,'skinHint','');
end
