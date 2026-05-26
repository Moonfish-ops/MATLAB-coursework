function ok = saveGameData(game)
% saveGameData 保存进度与设置

    ok = false;
    if ~isfield(game,'saveFile') || isempty(game.saveFile)
        return;
    end

    data = struct();
    data.progress = game.progress;
    data.keybinds = game.keybinds.bindings;
    data.options = game.options;
    data.playerLevel = game.player.level;
    data.playerDmgBonus = game.player.dmgBonus;

    try
        saveDir = fileparts(game.saveFile);
        if ~isfolder(saveDir)
            mkdir(saveDir);
        end
        save(game.saveFile, 'data');
        if ~isfile(game.saveFile)
            ok = false;
            return;
        end
        ok = true;
    catch
        ok = false;
    end
end
