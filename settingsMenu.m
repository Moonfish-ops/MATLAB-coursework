function game = settingsMenu(game)
% settingsMenu 设置界面

    cfg = game.keybinds;
    bindings = cfg.bindings;

    if ~isfield(game,'options') || ~isstruct(game.options)
        game.options = struct('volume',0.8,'uiScale',1.0);
    end
    if ~isfield(game.options,'volume'), game.options.volume = 0.8; end
    if ~isfield(game.options,'uiScale'), game.options.uiScale = 1.0; end

    f = figure('Name','设置 / Options', ...
        'NumberTitle','off', ...
        'MenuBar','none', ...
        'ToolBar','none', ...
        'Resize','off', ...
        'Color',[0.08 0.10 0.14], ...
        'Position',[330 110 700 600], ...
        'WindowStyle','modal');

    uicontrol(f,'Style','text','String','设置 / Options', ...
        'BackgroundColor',get(f,'Color'),'ForegroundColor',[1 0.92 0.5], ...
        'FontSize',16,'FontWeight','bold','Position',[250 560 200 28]);

    lb = uicontrol(f,'Style','listbox', ...
        'FontName','Consolas', ...
        'FontSize',11, ...
        'Position',[40 170 620 360]);

    msg = uicontrol(f,'Style','text', ...
        'String','', ...
        'BackgroundColor',get(f,'Color'), ...
        'ForegroundColor',[0.9 0.95 1], ...
        'HorizontalAlignment','left', ...
        'Position',[40 140 620 24]);

    uicontrol(f,'Style','pushbutton','String','修改键位', ...
        'Position',[40 95 130 34], ...
        'FontSize',11, ...
        'Callback',@onEditBind);

    uicontrol(f,'Style','pushbutton','String','恢复默认键位', ...
        'Position',[190 95 130 34], ...
        'FontSize',11, ...
        'Callback',@onResetDefault);

    uicontrol(f,'Style','text','String','音量', ...
        'BackgroundColor',get(f,'Color'),'ForegroundColor',[0.9 0.95 1], ...
        'Position',[360 96 60 22]);

    volumeSlider = uicontrol(f,'Style','slider', ...
        'Min',0,'Max',1,'Value',game.options.volume, ...
        'Position',[410 102 180 18]);

    uicontrol(f,'Style','text','String','界面缩放', ...
        'BackgroundColor',get(f,'Color'),'ForegroundColor',[0.9 0.95 1], ...
        'Position',[360 70 60 22]);

    scalePopup = uicontrol(f,'Style','popupmenu', ...
        'String',{'100%','110%','125%','150%'}, ...
        'Value',scaleToValue(game.options.uiScale), ...
        'Position',[430 72 90 22]);

    uicontrol(f,'Style','pushbutton','String','保存并返回', ...
        'Position',[230 24 120 40], ...
        'FontSize',12, ...
        'Callback',@onSave);

    uicontrol(f,'Style','pushbutton','String','取消', ...
        'Position',[380 24 90 40], ...
        'FontSize',12, ...
        'Callback',@(~,~) closeFigure());

    refreshList();
    uiwait(f);
    if isvalid(f)
        delete(f);
    end

    function refreshList()
        lines = cell(numel(cfg.actions),1);
        for i = 1:numel(cfg.actions)
            a = cfg.actions{i};
            lines{i} = sprintf('%-12s : %s', cfg.actionCN{i}, bindings.(a));
        end
        set(lb,'String',lines,'Value',1);
    end

    function onEditBind(~,~)
        idx = get(lb,'Value');
        action = cfg.actions{idx};
        label = cfg.actionCN{idx};

        answ = inputdlg(sprintf('为“%s”输入按键（MATLAB Key 名）:', label), ...
            '修改键位', 1, {bindings.(action)});
        if isempty(answ)
            return;
        end
        newKey = lower(strtrim(answ{1}));
        if isempty(newKey)
            set(msg,'String','键位不能为空');
            return;
        end

        % 去重：如果被其他动作使用，先清空旧动作
        for j = 1:numel(cfg.actions)
            a = cfg.actions{j};
            if strcmp(bindings.(a), newKey)
                bindings.(a) = '';
            end
        end
        bindings.(action) = newKey;
        set(msg,'String',sprintf('已修改：%s -> %s', label, newKey));
        refreshList();
        set(lb,'Value',idx);
    end

    function onResetDefault(~,~)
        d = keybindData();
        bindings = d.defaults;
        set(msg,'String','已恢复默认键位');
        refreshList();
    end

    function onSave(~,~)
        game.keybinds = keybindData(bindings);
        game.options.volume = get(volumeSlider,'Value');
        game.options.uiScale = valueToScale(get(scalePopup,'Value'));
        closeFigure();
    end

    function closeFigure()
        if isvalid(f)
            uiresume(f);
        end
    end
end

function v = scaleToValue(s)
    vals = [1.0 1.1 1.25 1.5];
    [~,v] = min(abs(vals - s));
end

function s = valueToScale(v)
    vals = [1.0 1.1 1.25 1.5];
    v = max(1,min(numel(vals),v));
    s = vals(v);
end
