function main()
% main 入口：主菜单 -> 战斗（单本地存档）

    game = initGame();
    game = tryLoadProfile(game);

    quitApp = false;
    while ~quitApp
        action = mainMenu(game);

        switch action
            case 'start'
                oldBindings = game.keybinds.bindings;
                oldOptions = game.options;

                game = initGame();
                game.keybinds = keybindData(oldBindings);
                game.options = oldOptions;
                game = tryLoadProfile(game);

                cp = getCheckpoint(game);
                [game, quitApp] = runBattle(game, cp(1), cp(2));

            case 'continue'
                [ok, data] = loadGameData(game.saveFile);
                if ok
                    oldBindings = game.keybinds.bindings;
                    oldOptions = game.options;

                    game = initGame();
                    game = mergeSavedData(game, data);

                    if ~isfield(data,'keybinds') || ~isstruct(data.keybinds)
                        game.keybinds = keybindData(oldBindings);
                    end
                    if ~isfield(data,'options') || ~isstruct(data.options)
                        game.options = oldOptions;
                    end

                    cp = getCheckpoint(game);
                    [game, quitApp] = runBattle(game, cp(1), cp(2));
                end

            case 'select'
                [ok, lv, rm] = levelSelect(game);
                if ok
                    [game, quitApp] = runBattle(game, lv, rm);
                end

            case 'warehouse'
                game = warehouseMenu(game);
                saveGameData(game);

            case 'settings'
                game = settingsMenu(game);
                saveGameData(game);

            otherwise
                quitApp = true;
        end
    end
end

function [game, quitApp] = runBattle(game, levelIdx, roomIdx)
    quitApp = false;

    game.running = true;
    game.returnToMenu = false;
    game.quitApp = false;

    fig = figure('Name','枪神快跑', ...
        'NumberTitle','off', ...
        'MenuBar','none', ...
        'ToolBar','none', ...
        'Color',[0.05 0.05 0.1], ...
        'Position',[200 120 game.screenW game.screenH], ...
        'Resize','off');

    ax = axes('Parent',fig, ...
        'Units','pixels', ...
        'Position',[0 0 game.screenW game.screenH], ...
        'XLim',[0 game.screenW], ...
        'YLim',[0 game.screenH], ...
        'Color',[0.2 0.2 0.25], ...
        'XTick',[],'YTick',[]);
    hold(ax,'on');
    axis(ax,'manual');

    game.fig = fig;
    game.ax = ax;

    guidata(fig, game);
    set(fig,'KeyPressFcn',@(s,e) onKeyPress(s,e));
    set(fig,'KeyReleaseFcn',@(s,e) onKeyRelease(s,e));
    set(fig,'CloseRequestFcn',@(s,~) onClose(s));

    game = loadLevel(game, levelIdx, roomIdx);
    guidata(fig, game);
    startBattleBgm(fig, game);

    frameTime = 1 / game.fps;
    nextFrameT = tic;

    while ishandle(fig)
        game = guidata(fig);
        if ~game.running
            break;
        end

        game = handleInput(game);

        if strcmp(game.state,'playing')
            game = updatePlayer(game);
            game = updateBullets(game);
            game = updateEnemies(game);
            game = checkCollision(game);
            game = checkRoomClear(game);
        else
            game = tickState(game);
        end

        guidata(fig, game);
        drawGame(game);

        elapsedToNext = toc(nextFrameT);
        waitT = frameTime - elapsedToNext;
        if waitT > 0
            pause(waitT);
        end
        nextFrameT = tic;
    end

    if ishandle(fig)
        stopBattleBgm(fig);
        game = guidata(fig);
        delete(fig);
    end

    saveGameData(game);

    if game.quitApp
        quitApp = true;
    end
end

function game = tickState(game)
    game.stateTimer = game.stateTimer + 1;

    switch game.state
        case {'roomClear','levelComplete'}
            if game.stateTimer > 60
                pt = game.pendingTransition;
                game = loadLevel(game, pt.level, pt.room);
            end

        case 'dead'
            if game.stateTimer > 180
                game = loadLevel(game, game.currentLevel, 1);
            end

        case 'win'
            % 等待玩家按退出键返回主菜单
    end
end

function onKeyPress(src, event)
    game = guidata(src);
    key = lower(event.Key);

    acts = keyToActions(game.keybinds, key);
    for i = 1:numel(acts)
        a = acts{i};
        wasHeld = false;
        if isfield(game.inputHeld, a)
            wasHeld = game.inputHeld.(a);
        end
        game.inputHeld.(a) = true;
        if ~wasHeld
            game.inputPulse.(a) = true;
        end
    end

    guidata(src, game);
end

function onKeyRelease(src, event)
    game = guidata(src);
    key = lower(event.Key);

    acts = keyToActions(game.keybinds, key);
    for i = 1:numel(acts)
        a = acts{i};
        game.inputHeld.(a) = false;
    end

    guidata(src, game);
end

function onClose(src)
    stopBattleBgm(src);
    game = guidata(src);
    game.running = false;
    game.returnToMenu = true;
    guidata(src, game);
    delete(src);
end

function startBattleBgm(fig, game)
    if ~ishandle(fig)
        return;
    end

    bgmPath = fullfile(fileparts(mfilename('fullpath')), '背景音乐', '兰花草.mp3');
    if ~isfile(bgmPath)
        return;
    end

    try
        [y, fs] = audioread(bgmPath);
        if isempty(y) || fs <= 0
            return;
        end
        if size(y,2) > 1
            y = mean(y,2);
        end

        userVol = 0.8;
        if isfield(game,'options') && isfield(game.options,'volume')
            userVol = max(0, min(1, game.options.volume));
        end
        bgmVol = 0.16 * userVol; % 背景音乐低于技能音效
        y = double(y) * bgmVol;

        p = audioplayer(y, fs);
        setappdata(fig, 'bgm_stop', false);
        setappdata(fig, 'bgm_player', p);
        p.StopFcn = @(src,evt) onBgmStop(src, evt, fig);
        play(p);
    catch
    end
end

function onBgmStop(src, ~, fig)
    if ~ishandle(fig)
        return;
    end
    if isappdata(fig, 'bgm_stop') && getappdata(fig, 'bgm_stop')
        return;
    end
    try
        play(src);
    catch
    end
end

function stopBattleBgm(fig)
    if ~ishandle(fig)
        return;
    end
    try
        setappdata(fig, 'bgm_stop', true);
        if isappdata(fig, 'bgm_player')
            p = getappdata(fig, 'bgm_player');
            if ~isempty(p) && isvalid(p) && strcmp(p.Running,'on')
                stop(p);
            end
        end
    catch
    end
end

function acts = keyToActions(cfg, key)
    acts = {};
    for i = 1:numel(cfg.actions)
        a = cfg.actions{i};
        bindKey = '';
        if isfield(cfg.bindings, a)
            bindKey = lower(strtrim(cfg.bindings.(a)));
        end
        if ~isempty(bindKey) && strcmp(bindKey, key)
            acts{end+1} = a; %#ok<AGROW>
        end
    end
end

function out = mergeProgress(base, incoming)
    out = base;
    fns = fieldnames(base);
    for i = 1:numel(fns)
        fn = fns{i};
        if isfield(incoming, fn)
            try
                if isequal(size(base.(fn)), size(incoming.(fn)))
                    out.(fn) = incoming.(fn);
                end
            catch
            end
        end
    end
end

function game = tryLoadProfile(game)
    [ok, data] = loadGameData(game.saveFile);
    if ok
        game = mergeSavedData(game, data);
    end
end

function game = mergeSavedData(game, data)
    if isfield(data,'progress')
        game.progress = mergeProgress(game.progress, data.progress);
    end
    if isfield(data,'keybinds') && isstruct(data.keybinds)
        game.keybinds = keybindData(data.keybinds);
    end
    if isfield(data,'options') && isstruct(data.options)
        game.options = data.options;
    end
    if isfield(data,'playerLevel') && isnumeric(data.playerLevel)
        lv = max(1, min(5, round(data.playerLevel)));
        game.player.level = lv;
        game.player.hpMax = 100 + (lv-1)*15;
        game.player.mpMax = 60 + (lv-1)*10;
    end
    if isfield(data,'playerDmgBonus') && isnumeric(data.playerDmgBonus)
        game.player.dmgBonus = max(0, data.playerDmgBonus);
    end
end

function cp = getCheckpoint(game)
    cp = [1 1];
    if isfield(game.progress,'lastCheckpoint') && numel(game.progress.lastCheckpoint) >= 2
        cp = game.progress.lastCheckpoint;
    end
    cp(1) = max(1, min(numel(game.levelCache), round(cp(1))));
    cp(2) = max(1, min(3, round(cp(2))));
end
