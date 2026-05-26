function game = warehouseMenu(game, fastMode)
% warehouseMenu 仓库/收藏界面

    if nargin < 2
        fastMode = false;
    end

    if fastMode
        allIdx = find(game.progress.ownedSkins);
    else
        allIdx = 1:numel(game.skins);
    end

    f = figure('Name','仓库 / 收藏', ...
        'NumberTitle','off', ...
        'MenuBar','none', ...
        'ToolBar','none', ...
        'Resize','off', ...
        'Color',[0.09 0.10 0.14], ...
        'Position',[180 120 1000 600], ...
        'KeyPressFcn',@onKeyPress, ...
        'CloseRequestFcn',@(~,~) closeWarehouse());

    % 顶部信息
    topText = uicontrol(f,'Style','text', ...
        'BackgroundColor',get(f,'Color'), ...
        'ForegroundColor',[1 0.92 0.5], ...
        'FontSize',12, ...
        'FontWeight','bold', ...
        'HorizontalAlignment','left', ...
        'Position',[20 560 960 28]);

    % 左侧列表
    listData = {'暂无皮肤'};
    if ~isempty(allIdx)
        listData = cell(numel(allIdx),1);
        for i = 1:numel(allIdx)
            sk = game.skins(allIdx(i));
            ownTag = ternary(game.progress.ownedSkins(allIdx(i)), '已拥有', '未拥有');
            imgTag = '';
            if isfield(sk,'imagePath') && ~isempty(sk.imagePath)
                imgTag = ' [图]';
            end
            listData{i} = sprintf('[%s][%s]%s %s - %s', sk.tier, ownTag, imgTag, sk.nameCN, weaponNameById(game, skinWeaponId(sk)));
        end
    end

    lb = uicontrol(f,'Style','listbox', ...
        'String',listData, ...
        'FontSize',11, ...
        'Position',[20 90 300 460], ...
        'Callback',@(~,~) refreshDetail());

    % 中间预览（战斗轻量模式禁用图片，减少卡顿）
    ax = [];
    if ~fastMode
        ax = axes('Parent',f, 'Units','pixels', 'Position',[350 200 280 280], ...
            'XLim',[0 1], 'YLim',[0 1], 'XTick',[],'YTick',[], 'Color',[0.12 0.14 0.18]);
        hold(ax,'on');
        box(ax,'on');
    end

    % 右侧属性
    detail = uicontrol(f,'Style','text', ...
        'BackgroundColor',[0.12 0.14 0.18], ...
        'ForegroundColor',[0.90 0.92 0.95], ...
        'FontSize',11, ...
        'HorizontalAlignment','left', ...
        'Position',[650 120 320 430]);

    equipBtn = uicontrol(f,'Style','pushbutton', ...
        'String','装备皮肤', ...
        'Position',[350 90 120 40], ...
        'FontSize',11, ...
        'Callback',@(~,~) onEquip());

    unequipBtn = uicontrol(f,'Style','pushbutton', ...
        'String','卸下皮肤', ...
        'Position',[490 90 120 40], ...
        'FontSize',11, ...
        'Callback',@(~,~) onUnequip());

    uicontrol(f,'Style','pushbutton', ...
        'String','关闭仓库', ...
        'Position',[830 30 140 46], ...
        'FontSize',12, ...
        'Callback',@(~,~) closeWarehouse());

    if isempty(allIdx)
        set([equipBtn unequipBtn],'Enable','off');
        set(detail,'String','暂无皮肤数据。');
        if ~fastMode
            showPreview([], [0.5 0.5 0.5], '暂无皮肤');
        end
    else
        set(lb,'Value',1);
        refreshDetail();
    end

    updateTopText();

    uiwait(f);

    function updateTopText()
        curW = game.weapons(game.player.weaponIdx);
        eqIdx = game.progress.equippedSkinByWeapon(game.player.weaponIdx);
        if eqIdx > 0
            eqName = game.skins(eqIdx).nameCN;
        else
            eqName = '未装备';
        end
        set(topText,'String',sprintf('已拥有皮肤: %d  |  当前武器: %s  |  当前装备皮肤: %s', ...
            nnz(game.progress.ownedSkins), curW.name, eqName));
    end

    function refreshDetail()
        if isempty(allIdx)
            return;
        end
        idx = get(lb,'Value');
        idx = max(1, min(numel(allIdx), idx));
        skinIdx = allIdx(idx);
        sk = game.skins(skinIdx);

        wId = skinWeaponId(sk);
        wName = weaponNameById(game, wId);
        eqWeaponIdx = findWeaponIdxById(game, wId);
        eqSkin = 0;
        if eqWeaponIdx > 0
            eqSkin = game.progress.equippedSkinByWeapon(eqWeaponIdx);
        end

        eqState = '未装备';
        if eqWeaponIdx == 0
            eqState = '当前版本未实装该枪';
        elseif eqSkin == skinIdx
            eqState = '已装备';
        elseif eqSkin > 0
            eqState = ['该武器已装备: ' game.skins(eqSkin).nameCN];
        end

        lines = {
            ['皮肤名称: ' sk.nameCN], ...
            ['对应武器: ' wName], ...
            ['品质等级: ' sk.tier], ...
            ['属性类型: ' bonusTypeCN(skinBonusType(sk))], ...
            ['属性数值: ' bonusValueText(skinBonusType(sk), skinBonusValue(sk))], ...
            ['拥有状态: ' ternary(game.progress.ownedSkins(skinIdx), '已拥有', '未拥有')], ...
            ['装备状态: ' eqState], ...
            '------------------------', ...
            '左键点击列表项可查看属性', ...
            '同一把武器同一时间仅可装备一个皮肤属性'};

        if isfield(sk,'imagePath') && ~isempty(sk.imagePath)
            lines{end+1} = ['图片来源: ' sk.imagePath];
        end

        set(detail,'String',strjoin(lines, newline));
        if ~fastMode
            showPreview(sk, sk.color, sk.nameCN);
        end
        updateTopText();
    end

    function onEquip()
        if isempty(allIdx)
            return;
        end
        idx = get(lb,'Value');
        idx = max(1, min(numel(allIdx), idx));
        skinIdx = allIdx(idx);
        if ~game.progress.ownedSkins(skinIdx)
            refreshDetail();
            return;
        end
        sk = game.skins(skinIdx);
        wIdx = findWeaponIdxById(game, skinWeaponId(sk));
        if wIdx < 1
            return;
        end
        game.progress.equippedSkinByWeapon(wIdx) = skinIdx;
        if game.player.weaponIdx == wIdx
            game.player.skinIdx = skinIdx;
        end
        refreshDetail();
    end

    function onUnequip()
        if isempty(allIdx)
            return;
        end
        idx = get(lb,'Value');
        idx = max(1, min(numel(allIdx), idx));
        skinIdx = allIdx(idx);
        sk = game.skins(skinIdx);
        wIdx = findWeaponIdxById(game, skinWeaponId(sk));
        if wIdx < 1
            return;
        end
        if game.progress.equippedSkinByWeapon(wIdx) == skinIdx
            game.progress.equippedSkinByWeapon(wIdx) = 0;
            if game.player.weaponIdx == wIdx
                game.player.skinIdx = 0;
            end
        end
        refreshDetail();
    end

    function onKeyPress(~, evt)
        closeKey = game.keybinds.bindings.openWarehouse;
        if strcmpi(evt.Key, closeKey)
            closeWarehouse();
        end
    end

    function closeWarehouse()
        if isvalid(f)
            delete(f);
        end
    end

    function showPreview(sk, fallbackColor, label)
        if isempty(ax) || ~ishandle(ax)
            return;
        end
        % 清理旧图层，保留坐标轴
        cla(ax);
        set(ax,'Color',[0.12 0.14 0.18], 'XTick',[],'YTick',[]);
        hold(ax,'on');
        box(ax,'on');

        hasImg = false;
        if ~isempty(sk) && isfield(sk,'imagePath') && ~isempty(sk.imagePath) && isfile(sk.imagePath)
            try
                img = getPreviewCached(sk.imagePath);
                image(ax, img);
                axis(ax,'image');
                axis(ax,'off');
                hasImg = true;
            catch
                hasImg = false;
            end
        end

        if ~hasImg
            patch(ax, [0.2 0.8 0.8 0.2], [0.2 0.2 0.8 0.8], fallbackColor, 'EdgeColor',[1 1 1]);
            text(ax, 0.5, 0.5, '无图片预览', 'HorizontalAlignment','center', ...
                'Color',[0.9 0.95 1], 'FontSize',11, 'FontWeight','bold');
            set(ax,'XLim',[0 1], 'YLim',[0 1], 'XTick',[],'YTick',[]);
        end

        text(ax, 0.5, 0.06, label, 'HorizontalAlignment','center', ...
            'Color',[0.9 0.95 1], 'FontSize',12, 'FontWeight','bold');
    end
end

function img = getPreviewCached(path)
    persistent cache;
    if isempty(cache)
        cache = containers.Map('KeyType','char','ValueType','any');
    end
    if isKey(cache, path)
        img = cache(path);
        return;
    end

    img = imread(path);
    img = flipud(img);
    [h,w,~] = size(img);
    maxSide = max(h,w);
    if maxSide > 700
        step = ceil(maxSide / 700);
        img = img(1:step:end, 1:step:end, :);
    end
    cache(path) = img;
end

function out = ternary(cond, a, b)
    if cond
        out = a;
    else
        out = b;
    end
end

function idx = findWeaponIdxById(game, weaponId)
    idx = find(arrayfun(@(w) strcmp(w.id, weaponId), game.weapons), 1);
    if isempty(idx)
        idx = 0;
    end
end

function name = weaponNameById(game, weaponId)
    idx = findWeaponIdxById(game, weaponId);
    if idx > 0
        name = game.weapons(idx).name;
    else
        name = weaponId;
    end
end

function t = bonusTypeCN(bt)
    switch bt
        case {'damage','dmg'}
            t = '伤害加成';
        case 'fireRate'
            t = '射速加成';
        case {'critRate','crit'}
            t = '暴击率加成';
        case {'reloadSpeed','reload'}
            t = '换弹效率';
        case {'manaCostReduction','mp'}
            t = '蓝耗减免';
        otherwise
            t = bt;
    end
end

function t = bonusValueText(bt, v)
    if strcmp(bt,'manaCostReduction') || strcmp(bt,'mp')
        t = sprintf('-%.0f%%', v*100);
    else
        t = sprintf('+%.0f%%', v*100);
    end
end

function wid = skinWeaponId(sk)
    wid = '';
    if isfield(sk,'weaponId') && ~isempty(sk.weaponId)
        wid = sk.weaponId;
    elseif isfield(sk,'weapon')
        wid = sk.weapon;
    end
end

function bt = skinBonusType(sk)
    bt = '';
    if isfield(sk,'bonus_type')
        bt = sk.bonus_type;
    elseif isfield(sk,'bonusType')
        bt = sk.bonusType;
    end
end

function v = skinBonusValue(sk)
    v = 0;
    if isfield(sk,'bonus_value')
        v = sk.bonus_value;
    elseif isfield(sk,'bonusValue')
        v = sk.bonusValue;
    end
end

