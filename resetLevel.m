function game = resetLevel(game)
% resetLevel - 失败或按 R 时, 从当前关卡的第 1 房间重开
    game = loadLevel(game, game.currentLevel, 1);
end
