function [mulDmg, mulFireRate, critBonus, mpReduce, skinIdx] = skinModifiers(game, weaponIdx)
% skinModifiers 根据当前武器已装备皮肤返回属性修正

    mulDmg = 1;
    mulFireRate = 1;
    critBonus = 0;
    mpReduce = 0;
    skinIdx = 0;

    if weaponIdx < 1 || weaponIdx > numel(game.weapons)
        return;
    end

    if ~isfield(game,'progress') || ~isfield(game.progress,'equippedSkinByWeapon')
        return;
    end

    skinIdx = game.progress.equippedSkinByWeapon(weaponIdx);
    if skinIdx < 1 || skinIdx > numel(game.skins)
        skinIdx = 0;
        return;
    end

    W = game.weapons(weaponIdx);
    sk = game.skins(skinIdx);
    weaponId = '';
    if isfield(sk,'weaponId') && ~isempty(sk.weaponId)
        weaponId = sk.weaponId;
    elseif isfield(sk,'weapon')
        weaponId = sk.weapon;
    end

    if ~strcmp(weaponId, W.id)
        skinIdx = 0;
        return;
    end

    bonusType = '';
    if isfield(sk,'bonus_type')
        bonusType = sk.bonus_type;
    elseif isfield(sk,'bonusType')
        bonusType = sk.bonusType;
    end

    bonusValue = 0;
    if isfield(sk,'bonus_value')
        bonusValue = sk.bonus_value;
    elseif isfield(sk,'bonusValue')
        bonusValue = sk.bonusValue;
    end

    switch bonusType
        case {'damage','dmg'}
            mulDmg = 1 + bonusValue;
        case 'fireRate'
            mulFireRate = 1 + bonusValue;
        case {'critRate','crit'}
            critBonus = bonusValue;
        case {'manaCostReduction','mp'}
            mpReduce = bonusValue;
        case {'reloadSpeed','reload'}
            % 暂未实装换弹，保留字段
    end
end
