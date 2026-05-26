function K = skinData()
% skinData 枪械皮肤总表（严格按配置表）
% 字段：gun_name | skin_name | tier | bonus_type | bonus_value

    K = repmat(blankSkin(), 0, 0);

    % 冥驹
    K(end+1) = mk('冥驹','离子武器','T0','manaCostReduction',0.08);
    K(end+1) = mk('冥驹','千灵华绽','T1','critRate',0.06);
    K(end+1) = mk('冥驹','鲜天遗武','T2','damage',0.04);

    % 判官
    K(end+1) = mk('判官','天界神兵/2.0','T0','reloadSpeed',0.08);
    K(end+1) = mk('判官','上古龙炎','T2','damage',0.04);

    % 幻影
    K(end+1) = mk('幻影','侦察力量','T0','fireRate',0.08);
    K(end+1) = mk('幻影','幽夜怪谈','T1','damage',0.06);
    K(end+1) = mk('幻影','异界魔蛇','T2','critRate',0.04);
    K(end+1) = mk('幻影','末日泡泡','T2','fireRate',0.04);
    K(end+1) = mk('幻影','千灵华绽','T1','critRate',0.06);

    % 戍卫
    K(end+1) = mk('戍卫','天界神兵','T0','damage',0.08);
    K(end+1) = mk('戍卫','紫阙金煌','T1','reloadSpeed',0.06);

    % 标配
    K(end+1) = mk('标配','VCT x EDG','T3','damage',0.02);
    K(end+1) = mk('标配','VCT x AG','T3','fireRate',0.02);

    % 正义
    K(end+1) = mk('正义','离子武器','T0','manaCostReduction',0.08);
    K(end+1) = mk('正义','奇点','T2','critRate',0.04);
    K(end+1) = mk('正义','千灵华绽','T1','critRate',0.06);
    K(end+1) = mk('正义','塑水宗','T1','damage',0.06);

    % 狂徒
    K(end+1) = mk('狂徒','塑水宗','T1','damage',0.06);
    K(end+1) = mk('狂徒','盖亚的复仇','T1','critRate',0.06);
    K(end+1) = mk('狂徒','紫阙金煌','T1','reloadSpeed',0.06);
    K(end+1) = mk('狂徒','艾沃莉的梦之翼','T1','critRate',0.06);
    K(end+1) = mk('狂徒','ORA战影','T2','damage',0.04);
    K(end+1) = mk('狂徒','混沌序曲','T0','damage',0.08);

    % 獠犬
    K(end+1) = mk('獠犬','电音光谱','T2','fireRate',0.04);
    K(end+1) = mk('獠犬','般若假面/2.0','T2','damage',0.04);

    % 莽侠
    K(end+1) = mk('莽侠','RGX 11z Pro/3.0','T0','reloadSpeed',0.08);
    K(end+1) = mk('莽侠','神中神罚','T3','damage',0.02);

    % 蜂刺
    K(end+1) = mk('蜂刺','混沌序曲','T0','fireRate',0.08);
    K(end+1) = mk('蜂刺','幽影者','T2','reloadSpeed',0.04);

    % 雄鹿
    K(end+1) = mk('雄鹿','紫阙金煌/2.0','T1','damage',0.06);

    % 飞将
    K(end+1) = mk('飞将','天界神兵','T0','damage',0.08);
    K(end+1) = mk('飞将','塑水宗','T1','critRate',0.06);

    % 骇灵
    K(end+1) = mk('骇灵','混沌序曲/2.0','T0','fireRate',0.08);
    K(end+1) = mk('骇灵','神中神罚','T3','damage',0.02);

    % 鬼魅
    K(end+1) = mk('鬼魅','艾沃莉的梦之翼','T1','critRate',0.06);
    K(end+1) = mk('鬼魅','辐螭威虎','T2','damage',0.04);
    K(end+1) = mk('鬼魅','天界神兵','T0','damage',0.08);
    K(end+1) = mk('鬼魅','盖亚的复仇','T1','critRate',0.06);

    % 衍生字段
    for i = 1:numel(K)
        K(i).weaponId = mapGunNameToWeaponId(K(i).gun_name);
        K(i).weapon = K(i).weaponId; % 兼容旧逻辑字段
        K(i).bonusType = K(i).bonus_type; % 兼容旧逻辑字段
        K(i).bonusValue = K(i).bonus_value;
        K(i).tierWeight = tierWeight(K(i).tier);
        K(i).nameCN = K(i).skin_name;
        K(i).name = K(i).skin_name;
        K(i).id = sprintf('skin_%03d', i);
        K(i).color = colorByTier(K(i).tier);
        K(i).imagePath = '';
        K(i).imageCount = 0;
    end
end

function s = blankSkin()
    s = struct('gun_name','','skin_name','','tier','T3','bonus_type','damage','bonus_value',0.02, ...
        'weaponId','','weapon','','bonusType','','bonusValue',0, ...
        'tierWeight',1,'nameCN','','name','','id','', ...
        'color',[0.7 0.7 0.7],'imagePath','','imageCount',0);
end

function s = mk(gunName, skinName, tier, bonusType, bonusValue)
    s = blankSkin();
    s.gun_name = gunName;
    s.skin_name = skinName;
    s.tier = tier;
    s.bonus_type = bonusType;
    s.bonus_value = bonusValue;
end

function id = mapGunNameToWeaponId(gunName)
    switch gunName
        case '标配', id = 'standard';
        case '鬼魅', id = 'ghost';
        case '蜂刺', id = 'stinger';
        case '飞将', id = 'sheriff';
        case '骇灵', id = 'spectre';
        case '雄鹿', id = 'bucky';
        case '獠犬', id = 'bulldog';
        case '戍卫', id = 'guardian';
        case '幻影', id = 'phantom';
        case '狂徒', id = 'vandal';
        case '冥驹', id = 'operator';
        case '战术小刀', id = 'knife';
        case '小刀', id = 'knife';
        otherwise
            % 当前武器池尚无：判官/正义/莽侠 等
            id = '';
    end
end

function w = tierWeight(t)
    switch t
        case 'T0', w = 4;
        case 'T1', w = 3;
        case 'T2', w = 2;
        otherwise, w = 1;
    end
end

function c = colorByTier(t)
    switch t
        case 'T0', c = [1.00 0.62 0.18];
        case 'T1', c = [0.90 0.45 0.95];
        case 'T2', c = [0.30 0.78 1.00];
        otherwise, c = [0.72 0.78 0.82];
    end
end
