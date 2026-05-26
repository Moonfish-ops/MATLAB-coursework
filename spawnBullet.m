function game = spawnBullet(game, b)
% spawnBullet 兼容接口：直接追加子弹（原始逻辑）

    if ~isfield(game,'bullets') || isempty(game.bullets)
        game.bullets = repmat(struct( ...
            'x',0,'y',0,'z',0,'vx',0,'vy',0,'vz',0, ...
            'owner','','life',0,'dmg',0,'color',[1 1 1],'crit',false, ...
            'pierce',false,'explode',false,'aoeR',0,'aoeDmgMul',0), 0, 0);
    end
    if numel(game.bullets) >= game.maxBullets
        return;
    end
    if isfield(b,'active')
        b = rmfield(b,'active');
    end
    game.bullets(end+1) = b;
end
