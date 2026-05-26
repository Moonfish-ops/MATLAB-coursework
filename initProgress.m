function progress = initProgress(game)
% initProgress 初始化进度结构

    nMaps = numel(game.levelCache);
    nRooms = 3;
    nW = numel(game.weapons);
    nS = numel(game.skins);

    progress = struct();
    progress.unlockedWeapons = false(1, nW);
    progress.ownedSkins = false(1, nS);
    progress.equippedSkinByWeapon = zeros(1, nW);

    progress.roomUnlocked = false(nMaps, nRooms);
    progress.roomUnlocked(1,1) = true;
    progress.roomCleared = false(nMaps, nRooms);
    progress.bestScore = nan(nMaps, nRooms);
    progress.mapCleared = false(1, nMaps);

    progress.lastCheckpoint = [1 1];

    if isfield(game,'unlockRules') && isfield(game.unlockRules,'startingWeapons')
        idx = game.unlockRules.startingWeapons;
    else
        idx = 1;
    end
    idx = idx(idx >= 1 & idx <= nW);
    progress.unlockedWeapons(idx) = true;
end
