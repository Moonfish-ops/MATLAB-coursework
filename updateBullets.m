function game = updateBullets(game)
% updateBullets 推进每颗子弹，越界或寿命结束则删除

    if isempty(game.bullets), return; end
    r = game.room;
    keep = true(1, numel(game.bullets));
    for i = 1:numel(game.bullets)
        b = game.bullets(i);
        b.x = b.x + b.vx;
        b.y = b.y + b.vy;
        b.z = b.z + b.vz;
        b.life = b.life - 1;
        if b.life <= 0 || ...
           b.x < -20 || b.x > r.w + 20 || ...
           b.y < r.yMin - 30 || b.y > r.yMax + 30
            keep(i) = false;
        end
        game.bullets(i) = b;
    end
    game.bullets = game.bullets(keep);
end
