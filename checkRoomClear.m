function game = checkRoomClear(game)
% checkRoomClear - 统计当前房间活着的敌人, 若全灭则开启右门

    r = game.room;
    if r.cleared
        game.room = r;
        return;
    end
    nAlive = 0;
    for i = 1:numel(r.enemies)
        if r.enemies(i).alive
            nAlive = nAlive + 1;
        end
    end
    if nAlive == 0
        r.cleared  = true;
        r.doorOpen = true;
    end
    game.room = r;
end
