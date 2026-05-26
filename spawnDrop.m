function game = spawnDrop(game, enemy)
% spawnDrop 敌人死亡掉落

    r = game.room;
    t = enemy.type;

    px = enemy.x + enemy.w/2;
    py = enemy.y;

    kinds = {'coin','heart','mana'};

    switch t
        case {'melee','ranged'}
            if rand < 0.28
                r.pickups(end+1) = mkPickup(px, py, kinds{randi(numel(kinds))}, 0);
            end
            if rand < 0.22
                r.pickups(end+1) = mkPickup(px+10, py+6, 'coin', 0);
            end

        case {'eliteMelee','eliteRanged'}
            if rand < 0.65
                r.pickups(end+1) = mkPickup(px, py, kinds{randi(numel(kinds))}, 0);
            end
            if rand < 0.35
                r.pickups(end+1) = mkPickup(px-10, py, 'star', 0);
            end
            r.pickups(end+1) = mkPickup(px+12, py-6, 'coin', 0);

            if rand < 0.25
                idx = pickSkinByTier(game, {'T2'});
                if idx > 0
                    r.pickups(end+1) = mkPickup(px, py+14, 'skin', idx);
                end
            end

        case 'boss'
            r.pickups(end+1) = mkPickup(px, py, 'star', 0);
            r.pickups(end+1) = mkPickup(px+20, py+8, 'heart', 0);
            r.pickups(end+1) = mkPickup(px-20, py-8, 'mana', 0);

            if game.currentLevel == 5
                % 最终图：高品质收藏掉落权重更高
                idx = pickSkinByTier(game, {'T0','T1'});
                if idx == 0
                    idx = pickSkinByTier(game, {'T2'});
                end
                if idx > 0
                    r.pickups(end+1) = mkPickup(px, py+14, 'skin', idx);
                else
                    r.pickups(end+1) = mkPickup(px+28, py+12, 'star', 0);
                end
                r.pickups(end+1) = mkPickup(px-28, py+10, 'star', 0);
            else
                if rand < 0.60
                    idx = pickSkinByTier(game, {'T0'});
                else
                    idx = pickSkinByTier(game, {'T1'});
                end
                if idx == 0
                    idx = pickSkinByTier(game, {'T0','T1','T2'});
                end
                if idx > 0
                    r.pickups(end+1) = mkPickup(px, py+14, 'skin', idx);
                end
            end
    end

    game.room = r;
end

function pk = mkPickup(x, y, kind, skinIdx)
    pk = struct('x',x,'y',y,'type',kind,'alive',true,'skinIdx',skinIdx);
end

function idx = pickSkinByTier(game, tiers)
    K = game.skins;
    pool = [];
    for i = 1:numel(K)
        if any(strcmp(K(i).tier, tiers)) && ~game.progress.ownedSkins(i)
            pool(end+1) = i; %#ok<AGROW>
        end
    end

    if isempty(pool)
        idx = 0;
        return;
    end

    idx = pool(randi(numel(pool)));
end
