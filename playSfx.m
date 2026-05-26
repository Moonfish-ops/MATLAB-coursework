function game = playSfx(game, cueName)
% playSfx play skill/weapon voice with low-stutter path
    if ~isfield(game, 'audio') || ~isstruct(game.audio)
        return;
    end
    if ~isfield(game.audio, 'enabled') || ~game.audio.enabled
        return;
    end
    if ~isfield(game.audio, 'cache') || ~isfield(game.audio.cache, cueName)
        return;
    end

    c = game.audio.cache.(cueName);
    if ~c.ok || isempty(c.y) || c.fs <= 0
        return;
    end

    vol = 1.0;
    if isfield(game, 'options') && isfield(game.options, 'volume')
        vol = max(0, min(1, game.options.volume));
    end
    if vol < 0.01
        vol = 0.8;
    end

    % light debounce to avoid rapid retrigger hitches
    if ~isfield(game.audio, 'lastPlayFrame') || ~isstruct(game.audio.lastPlayFrame)
        game.audio.lastPlayFrame = struct();
    end
    nowFrame = 0;
    if isfield(game, 'stateTimer')
        nowFrame = game.stateTimer;
    end
    minGap = 6;
    if isfield(game.audio, 'cueMinGap') && isstruct(game.audio.cueMinGap) ...
            && isfield(game.audio.cueMinGap, cueName)
        minGap = game.audio.cueMinGap.(cueName);
    end

    if isfield(game.audio.lastPlayFrame, cueName)
        if (nowFrame - game.audio.lastPlayFrame.(cueName)) < minGap
            return;
        end
    end
    game.audio.lastPlayFrame.(cueName) = nowFrame;

    try
        if ~isfield(game.audio, 'players') || ~isstruct(game.audio.players)
            game.audio.players = struct();
        end
        if ~isfield(game.audio, 'playerVol') || ~isstruct(game.audio.playerVol)
            game.audio.playerVol = struct();
        end

        needCreate = ~isfield(game.audio.players, cueName) || ...
                     isempty(game.audio.players.(cueName)) || ...
                     ~isvalid(game.audio.players.(cueName));
        if ~needCreate
            if ~isfield(game.audio.playerVol, cueName)
                needCreate = true;
            else
                needCreate = abs(game.audio.playerVol.(cueName) - vol) > 1e-3;
            end
        end

        if needCreate
            game.audio.players.(cueName) = audioplayer(double(c.y) * vol, c.fs);
            game.audio.playerVol.(cueName) = vol;
        end

        ap = game.audio.players.(cueName);
        if strcmp(ap.Running, 'on')
            stop(ap);
        end
        ap.CurrentSample = 1;
        play(ap);
    catch
        try
            sound(double(c.y) * vol, c.fs);
        catch
        end
    end
end
