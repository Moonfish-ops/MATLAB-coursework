function game = nextLevel(game)
% nextLevel 进入下一房间/下一地图，并处理解锁进度

    lv = game.currentLevel;
    rm = game.currentRoom;

    % 记录通关与最佳成绩
    game.progress.roomCleared(lv,rm) = true;
    score = calcScore(game);
    oldBest = game.progress.bestScore(lv,rm);
    if isnan(oldBest) || score > oldBest
        game.progress.bestScore(lv,rm) = score;
    end

    L = game.levelCache{lv};
    nRooms = numel(L.rooms);

    if rm < nRooms
        game.progress.roomUnlocked(lv, rm+1) = true;
        game.pendingTransition = struct('type','room','level',lv,'room',rm+1);
        game.state = 'roomClear';
        game.stateTimer = 0;
        return;
    end

    % 地图完成奖励
    [game, unlockMsg] = applyMapClearRewards(game, lv);
    if ~isempty(unlockMsg)
        game = addPopup(game, game.player.x + game.player.w/2, game.player.y + game.player.h + 24, unlockMsg, [1 0.9 0.4]);
    end
    saveGameData(game);

    if lv < game.totalLevels
        game.pendingTransition = struct('type','level','level',lv+1,'room',1);
        game.state = 'levelComplete';
        game.stateTimer = 0;
    else
        game.state = 'win';
        game.stateTimer = 0;
    end
end

function s = calcScore(game)
    p = game.player;
    s = p.coins + p.stars * 10 + p.level * 20 + p.hp * 0.5;
end

function game = addPopup(game, x, y, text, color)
    pop = struct('x',x,'y',y,'life',90,'text',text,'color',color);
    maxPopups = 24;
    if isempty(game.popups)
        game.popups = pop;
        return;
    end
    if numel(game.popups) >= maxPopups
        game.popups = game.popups(2:end);
    end
    game.popups(end+1) = pop;
end
