function [game, unlockMsg] = applyMapClearRewards(game, mapIdx)
% applyMapClearRewards 地图通关后奖励

    unlockMsg = '';

    if mapIdx < 1 || mapIdx > numel(game.progress.mapCleared)
        return;
    end

    firstClear = ~game.progress.mapCleared(mapIdx);
    game.progress.mapCleared(mapIdx) = true;

    % 首次通关解锁本图奖励的武器（前4图；地图4奖励为空表示无新武器）
    if mapIdx <= 4 && firstClear
        idx = game.unlockRules.mapUnlockWeapons{mapIdx};
        if ~isempty(idx)
            idx = idx(idx >= 1 & idx <= numel(game.progress.unlockedWeapons));
            newIdx = idx(~game.progress.unlockedWeapons(idx));
            game.progress.unlockedWeapons(idx) = true;
            if ~isempty(newIdx)
                names = arrayfun(@(w) w.name, game.weapons(newIdx), 'UniformOutput', false);
                unlockMsg = sprintf('解锁武器：%s', strjoin(names, '、'));
            end
        end
    end

    % 解锁下一图首关
    if mapIdx < size(game.progress.roomUnlocked,1)
        game.progress.roomUnlocked(mapIdx+1,1) = true;
    end

    % 第5图首次通关送高品质收藏
    if mapIdx == 5 && firstClear
        [game, gotSkinName] = grantHighTierSkin(game, {'T0','T1'});
        if ~isempty(gotSkinName)
            unlockMsg = sprintf('终极收藏奖励：%s', gotSkinName);
        else
            unlockMsg = '终极收藏奖励：高品质皮肤碎片（已拥有全套）';
            game.player.stars = game.player.stars + 3;
        end
    end
end

function [game, skinName] = grantHighTierSkin(game, tiers)
    skinName = '';
    pool = [];
    for i = 1:numel(game.skins)
        if any(strcmp(game.skins(i).tier, tiers)) && ~game.progress.ownedSkins(i)
            pool(end+1) = i; %#ok<AGROW>
        end
    end

    if isempty(pool)
        return;
    end

    idx = pool(randi(numel(pool)));
    game.progress.ownedSkins(idx) = true;
    skinName = game.skins(idx).nameCN;
end
