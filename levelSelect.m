function [ok, levelIdx, roomIdx] = levelSelect(game)
% levelSelect 关卡选择界面（5图 x 3关）

    ok = false;
    levelIdx = 1;
    roomIdx = 1;

    nMaps = numel(game.unlockRules.mapNames);
    nRooms = size(game.progress.roomUnlocked,2);

    rows = cell(nMaps*nRooms, 1);
    meta = zeros(nMaps*nRooms, 2);
    r = 0;
    for m = 1:nMaps
        for k = 1:nRooms
            r = r + 1;
            unlocked = game.progress.roomUnlocked(m,k);
            cleared = game.progress.roomCleared(m,k);
            best = game.progress.bestScore(m,k);
            if isnan(best)
                bestText = '-';
            else
                bestText = sprintf('%.0f', best);
            end
            rows{r} = sprintf('%s  第%d关  [%s]  通关:%s  最佳:%s', ...
                game.unlockRules.mapNames{m}, k, lockText(unlocked), yesNo(cleared), bestText);
            meta(r,:) = [m k];
        end
    end

    f = figure('Name','关卡选择', ...
        'NumberTitle','off', ...
        'MenuBar','none', ...
        'ToolBar','none', ...
        'Resize','off', ...
        'Color',[0.08 0.10 0.14], ...
        'Position',[300 120 760 560], ...
        'WindowStyle','modal');

    uicontrol(f,'Style','text','String','关卡选择（已解锁可进入）', ...
        'BackgroundColor',get(f,'Color'),'ForegroundColor',[1 0.92 0.5], ...
        'FontSize',16,'FontWeight','bold','Position',[220 510 320 32]);

    lb = uicontrol(f,'Style','listbox', ...
        'String',rows, ...
        'FontName','Consolas', ...
        'FontSize',11, ...
        'Position',[30 120 700 380], ...
        'Value',1);

    detail = uicontrol(f,'Style','text', ...
        'String','', ...
        'HorizontalAlignment','left', ...
        'BackgroundColor',[0.12 0.14 0.18], ...
        'ForegroundColor',[0.90 0.92 0.95], ...
        'FontSize',11, ...
        'Position',[30 70 700 40]);

    uicontrol(f,'Style','pushbutton','String','进入关卡', ...
        'Position',[200 18 150 40], ...
        'FontSize',12, ...
        'Callback',@onEnter);

    uicontrol(f,'Style','pushbutton','String','返回', ...
        'Position',[410 18 150 40], ...
        'FontSize',12, ...
        'Callback',@(~,~) closeFigure());

    set(lb,'Callback',@(~,~) updateDetail());
    updateDetail();

    uiwait(f);
    if isvalid(f)
        delete(f);
    end

    function updateDetail()
        idx = get(lb,'Value');
        m = meta(idx,1);
        k = meta(idx,2);
        unlocked = game.progress.roomUnlocked(m,k);
        cleared = game.progress.roomCleared(m,k);
        set(detail,'String',sprintf('地图：%s   关卡：第%d关   状态：%s   通关：%s', ...
            game.unlockRules.mapNames{m}, k, lockText(unlocked), yesNo(cleared)));
    end

    function onEnter(~,~)
        idx = get(lb,'Value');
        m = meta(idx,1);
        k = meta(idx,2);
        if ~game.progress.roomUnlocked(m,k)
            set(detail,'String','该关卡尚未解锁');
            return;
        end
        ok = true;
        levelIdx = m;
        roomIdx = k;
        closeFigure();
    end

    function closeFigure()
        if isvalid(f)
            uiresume(f);
        end
    end
end

function t = lockText(unlocked)
    if unlocked
        t = '已解锁';
    else
        t = '锁定';
    end
end

function t = yesNo(v)
    if v
        t = '是';
    else
        t = '否';
    end
end
