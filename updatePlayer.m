function game = updatePlayer(game)
% updatePlayer 推进玩家物理

    p = game.player;
    r = game.room;

    p.x = p.x + p.vx;
    p.y = p.y + p.vy;

    if p.x < 20, p.x = 20; end
    rightWall = r.w - 20 - p.w;
    if ~r.doorOpen && p.x > rightWall
        p.x = rightWall;
    end
    if p.x > r.w - p.w, p.x = r.w - p.w; end

    if p.y < r.yMin, p.y = r.yMin; end
    if p.y > r.yMax, p.y = r.yMax; end

    p.vz = p.vz - game.gravity;
    if p.vz < -20, p.vz = -20; end
    p.z = p.z + p.vz;
    if p.z <= 0
        p.z = 0; p.vz = 0; p.onGround = true;
    else
        p.onGround = false;
    end

    if p.invincible > 0, p.invincible = p.invincible - 1; end
    if p.hitFlash > 0, p.hitFlash = p.hitFlash - 1; end

    game.stateTimer = game.stateTimer + 1;
    game.player = p;

    if ~isempty(game.popups)
        keep = true(1, numel(game.popups));
        for i = 1:numel(game.popups)
            game.popups(i).y = game.popups(i).y + 1.0;
            game.popups(i).life = game.popups(i).life - 1;
            if game.popups(i).life <= 0
                keep(i) = false;
            end
        end
        game.popups = game.popups(keep);
    end

    if r.doorOpen && p.x + p.w >= r.w - 5
        game = nextLevel(game);
    end
end

