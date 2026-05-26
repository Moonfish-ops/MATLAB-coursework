function game = initScene(game)
% initScene 构建场景句柄（只在换房间时创建）

    ax = game.ax;
    r = game.room;

    cla(ax);
    hold(ax,'on');
    set(ax,'Color',[0 0 0]);
    set(ax,'XLim',[0 r.w],'YLim',[0 r.h]);
    set(ax,'XTick',[],'YTick',[]);

    s = struct();

    % 背景与地板
    s.bgImage = gobjects(0);
    hasBgImage = false;
    bgPath = findMapBackgroundPath(r.mapName);
    if ~isempty(bgPath) && isfile(bgPath)
        try
            img = getMapBackgroundCached(bgPath, r.h, r.w);
            s.bgImage = image(ax, [0 r.w], [0 r.h], img);
            set(s.bgImage, 'AlphaData', 1.0, 'HitTest','off', 'PickableParts','none');
            set(ax,'YDir','normal');
            hasBgImage = true;
        catch
            s.bgImage = gobjects(0);
        end
    end

    s.backWall = patch(ax,[0 r.w r.w 0],[r.yMax r.yMax r.h r.h],r.bgColor,'EdgeColor','none');
    if hasBgImage
        set(s.backWall, 'FaceAlpha', 0.08);
    end

    floorCol = r.bgColor * 0.75 + [0.18 0.14 0.10];
    s.floor = patch(ax,[0 r.w r.w 0],[r.yMin r.yMin r.yMax r.yMax],floorCol,'EdgeColor','none');
    if hasBgImage
        set(s.floor, 'FaceAlpha', 0.12);
    end

    nFloorLines = 6;
    s.floorLines = gobjects(1,nFloorLines);
    for i = 1:nFloorLines
        fy = r.yMin + (r.yMax-r.yMin) * i/7;
        s.floorLines(i) = line(ax,[0 r.w],[fy fy],'Color',floorCol*0.75,'LineStyle',':');
        if hasBgImage
            set(s.floorLines(i), 'Color', [1 1 1] * 0.55);
        end
    end

    % 地图特色装饰（MATLAB原生建模）
    if hasBgImage
        s.themeObjects = gobjects(0);
    else
        s.themeObjects = drawThemeDecor(ax, r);
    end

    % 陷阱
    if isempty(r.hazards)
        s.hazards = gobjects(0);
    else
        [hx,hy] = rectsToPatches(r.hazards);
        s.hazards = patch(ax,'XData',hx,'YData',hy, ...
            'FaceColor',[0.85 0.16 0.16],'EdgeColor',[0.1 0.1 0.1],'FaceAlpha',0.72);
    end

    % 门
    doorH = 90;
    s.leftDoor = patch(ax,[0 14 14 0],[r.yMax-10 r.yMax-10 r.yMax-10+doorH r.yMax-10+doorH], ...
        [0.2 0.2 0.25],'EdgeColor','k');
    s.rightDoorClosed = patch(ax,[r.w-14 r.w r.w r.w-14], ...
        [r.yMax-10 r.yMax-10 r.yMax-10+doorH r.yMax-10+doorH], ...
        [0.45 0.3 0.2],'EdgeColor','k');
    s.rightDoorOpen = patch(ax,[r.w-14 r.w r.w r.w-14], ...
        [r.yMax-10 r.yMax-10 r.yMax-10+doorH r.yMax-10+doorH], ...
        [0.1 0.75 0.3],'EdgeColor','k','FaceAlpha',0.55,'Visible','off');

    % 拾取物池
    nP = numel(r.pickups) + 60;
    s.pickups = gobjects(1,nP);
    [px,py] = circlePoly(0,0,7);
    for i = 1:nP
        s.pickups(i) = patch(ax,'XData',px,'YData',py, ...
            'FaceColor',[1 0.8 0.2],'EdgeColor','k','Visible','off');
    end

    % 玩家（简化初始模型）
    [sx,sy] = ellipsePoly(0,0,14,5);
    s.playerShadow = patch(ax,sx,sy,[0 0 0],'FaceAlpha',0.35,'EdgeColor','none');
    [bx,by] = rectsToPatches([0 0 1 1]);
    s.playerBody = patch(ax,'XData',bx,'YData',by,'FaceColor',[0.2 0.55 0.95],'EdgeColor','k');
    [hx,hy] = circlePoly(0,0,8);
    s.playerHead = patch(ax,'XData',hx,'YData',hy,'FaceColor',[1 0.85 0.7],'EdgeColor','k');
    s.playerGun = line(ax,[0 0],[0 0],'Color','k','LineWidth',4);

    % 小狗模型（协战犬）
    [dsx,dsy] = ellipsePoly(0,0,12,4);
    s.dogShadow = patch(ax,dsx,dsy,[0 0 0],'FaceAlpha',0.25,'EdgeColor','none','Visible','off');
    [dbx,dby] = rectsToPatches([0 0 1 1]);
    s.dogBody = patch(ax,'XData',dbx,'YData',dby,'FaceColor',[0.95 0.85 0.45], ...
        'EdgeColor',[0.3 0.2 0.1],'Visible','off');
    [dhx,dhy] = circlePoly(0,0,5);
    s.dogHead = patch(ax,'XData',dhx,'YData',dhy,'FaceColor',[0.98 0.9 0.55], ...
        'EdgeColor',[0.3 0.2 0.1],'Visible','off');
    s.dogTail = line(ax,[0 0],[0 0],'Color',[0.35 0.22 0.1],'LineWidth',2,'Visible','off');
    s.dogName = text(ax,0,0,'CXY', ...
        'Color',[1 0.95 0.65], ...
        'FontSize',9, ...
        'FontWeight','bold', ...
        'HorizontalAlignment','center', ...
        'Visible','off');

    % 敌人
    nE = numel(r.enemies);
    s.enemyShadow = gobjects(1,nE);
    s.enemyBody = gobjects(1,nE);
    s.enemyHead = gobjects(1,nE);
    s.enemyGun = gobjects(1,nE);
    for i = 1:nE
        [esx,esy] = ellipsePoly(0,0,12,4);
        s.enemyShadow(i) = patch(ax,esx,esy,[0 0 0],'FaceAlpha',0.35,'EdgeColor','none','Visible','off');
        [ebx,eby] = rectsToPatches([0 0 1 1]);
        s.enemyBody(i) = patch(ax,'XData',ebx,'YData',eby,'FaceColor',[0.75 0.2 0.2], ...
            'EdgeColor','k','Visible','off');
        [ehx,ehy] = circlePoly(0,0,7);
        s.enemyHead(i) = patch(ax,'XData',ehx,'YData',ehy,'FaceColor',[0.6 0.5 0.4], ...
            'EdgeColor','k','Visible','off');
        s.enemyGun(i) = line(ax,[0 0],[0 0],'Color','k','LineWidth',3,'Visible','off');
    end

    % 子弹池
    nB = 110;
    s.bulletPool = gobjects(1,nB);
    [cx,cy] = circlePoly(0,0,3);
    for i = 1:nB
        s.bulletPool(i) = patch(ax,'XData',cx,'YData',cy,'FaceColor',[1 1 0.2], ...
            'EdgeColor','none','Visible','off');
    end

    % 浮动文本
    s.popupPool = gobjects(1,18);
    for i = 1:18
        s.popupPool(i) = text(ax,0,0,'','Color',[1 1 1],'FontSize',11, ...
            'FontWeight','bold','HorizontalAlignment','center','Visible','off');
    end

    game.scene = s;

    % ---------------- HUD ----------------
    if isfield(game,'hudAx') && ~isempty(game.hudAx) && ishandle(game.hudAx)
        delete(game.hudAx);
    end

    game.hudAx = axes('Parent',game.fig,'Units','pixels', ...
        'Position',[0 0 game.screenW game.screenH], ...
        'XLim',[0 game.screenW],'YLim',[0 game.screenH], ...
        'Color','none','XTick',[],'YTick',[],'HitTest','off','PickableParts','none');
    hold(game.hudAx,'on');
    uistack(game.hudAx,'top');

    h = struct();
    SW = game.screenW;
    SH = game.screenH;

    h.panel = patch(game.hudAx,[10 330 330 10],[SH-130 SH-130 SH-10 SH-10], ...
        [0.05 0.05 0.10],'FaceAlpha',0.78,'EdgeColor',[0.5 0.45 0.2]);

    % 左上角主角头像
    avatarX = 18; avatarY = SH - 100; avatarW = 64; avatarH = 64;
    [x,y] = rectsToPatches([avatarX-2 avatarY-2 avatarW+4 avatarH+4]);
    h.avatarFrame = patch(game.hudAx,'XData',x,'YData',y, ...
        'FaceColor',[0.12 0.14 0.20],'EdgeColor',[0.95 0.85 0.4], ...
        'LineWidth',1.1,'FaceAlpha',0.95);

    avatarPath = fullfile(fileparts(mfilename('fullpath')), '人物', 'kk战斗图.jpg');
    img = getHudAvatarCached(avatarPath);
    if ~isempty(img)
        h.avatar = image(game.hudAx, [avatarX avatarX+avatarW], [avatarY+avatarH avatarY], img);
        set(game.hudAx, 'YDir', 'normal');
    else
        h.avatar = text(game.hudAx, avatarX + avatarW/2, avatarY + avatarH/2, 'KK', ...
            'HorizontalAlignment','center','Color',[1 1 1], ...
            'FontSize',12,'FontWeight','bold');
    end

    [x,y] = rectsToPatches([90 SH-52 220 14]);
    h.hpBg = patch(game.hudAx,'XData',x,'YData',y,'FaceColor',[0.2 0.06 0.06],'EdgeColor','none');
    h.hp = patch(game.hudAx,'XData',x,'YData',y,'FaceColor',[0.95 0.20 0.24],'EdgeColor','none');
    h.hpText = text(game.hudAx,200,SH-45,'HP','Color','w','HorizontalAlignment','center','FontWeight','bold');

    [x,y] = rectsToPatches([90 SH-74 220 12]);
    h.mpBg = patch(game.hudAx,'XData',x,'YData',y,'FaceColor',[0.05 0.10 0.25],'EdgeColor','none');
    h.mp = patch(game.hudAx,'XData',x,'YData',y,'FaceColor',[0.2 0.55 1.0],'EdgeColor','none');
    h.mpText = text(game.hudAx,200,SH-68,'MP','Color','w','HorizontalAlignment','center','FontSize',9,'FontWeight','bold');

    [x,y] = rectsToPatches([90 SH-88 220 7]);
    h.expBg = patch(game.hudAx,'XData',x,'YData',y,'FaceColor',[0.16 0.14 0.04],'EdgeColor','none');
    h.exp = patch(game.hudAx,'XData',x,'YData',y,'FaceColor',[1.0 0.84 0.2],'EdgeColor','none');
    h.expText = text(game.hudAx,200,SH-84,'EXP','Color',[0.1 0.1 0.1],'HorizontalAlignment','center','FontSize',8,'FontWeight','bold');

    h.weaponText = text(game.hudAx,18,SH-104,'', ...
        'Color',[0.65 1 1],'FontSize',10,'FontWeight','bold');
    h.skinText = text(game.hudAx,18,SH-120,'', ...
        'Color',[1 0.85 0.95],'FontSize',9);

    h.mapText = text(game.hudAx,SW-20,SH-30,'', ...
        'HorizontalAlignment','right','Color',[1 0.95 0.6],'FontSize',11,'FontWeight','bold');
    h.roomText = text(game.hudAx,SW-20,SH-50,'', ...
        'HorizontalAlignment','right','Color',[0.85 0.9 1],'FontSize',10);

    h.info = text(game.hudAx,18,18,'', ...
        'Color',[1 0.95 0.6],'FontSize',10,'FontWeight','bold');
    h.skillText = text(game.hudAx,350,18,'', ...
        'Color',[0.85 0.92 1],'FontSize',10);

    [x,y] = rectsToPatches([350 40 150 10]);
    h.ultBg = patch(game.hudAx,'XData',x,'YData',y,'FaceColor',[0.16 0.08 0.2],'EdgeColor',[0.7 0.35 0.9]);
    h.ultFill = patch(game.hudAx,'XData',x,'YData',y,'FaceColor',[0.92 0.3 0.95],'EdgeColor','none');
    h.ultText = text(game.hudAx,425,53,'X能量', ...
        'HorizontalAlignment','center','Color',[1 0.8 1],'FontSize',9,'FontWeight','bold');

    h.doorHint = text(game.hudAx,SW/2,108,'', ...
        'HorizontalAlignment','center','Color',[0.4 1 0.4],'FontSize',13,'FontWeight','bold','Visible','off');

    h.overlayBg = patch(game.hudAx,[0 SW SW 0],[0 0 SH SH],[0 0 0], ...
        'FaceAlpha',0.55,'EdgeColor','none','Visible','off');
    h.overlayTitle = text(game.hudAx,SW/2,SH/2+18,'', ...
        'HorizontalAlignment','center','FontSize',36,'FontWeight','bold','Visible','off');
    h.overlaySub = text(game.hudAx,SW/2,SH/2-26,'', ...
        'HorizontalAlignment','center','Color','w','FontSize',13,'Visible','off');

    % Boss 居中红色血条
    bossW = 420; bossH = 16;
    bossX = (SW - bossW) / 2; bossY = SH - 26;
    [x,y] = rectsToPatches([bossX bossY bossW bossH]);
    h.bossHpBg = patch(game.hudAx,'XData',x,'YData',y, ...
        'FaceColor',[0.22 0.05 0.05],'EdgeColor',[0.45 0.1 0.1], ...
        'LineWidth',1.1,'Visible','off');
    h.bossHpFill = patch(game.hudAx,'XData',x,'YData',y, ...
        'FaceColor',[0.92 0.10 0.10],'EdgeColor','none','Visible','off');
    h.bossHpText = text(game.hudAx,SW/2,bossY+bossH/2+1,'', ...
        'HorizontalAlignment','center','Color',[1 0.95 0.95], ...
        'FontSize',10,'FontWeight','bold','Visible','off');

    game.hud = h;
end

function objs = drawThemeDecor(ax, r)
    objs = gobjects(0);
    switch r.theme
        case 1 % 隐世修所
            objs(end+1) = patch(ax,[80 220 200],[r.yMax+10 r.yMax+10 r.h-20],[0.6 0.75 0.9],'EdgeColor','none','FaceAlpha',0.35); %#ok<AGROW>
            objs(end+1) = patch(ax,[730 910 860],[r.yMax+15 r.yMax+15 r.h-10],[0.55 0.72 0.88],'EdgeColor','none','FaceAlpha',0.35); %#ok<AGROW>
        case 2 % 日落之城
            [x,y] = circlePoly(860, r.h-35, 42);
            objs(end+1) = patch(ax,x,y,[0.98 0.62 0.24],'EdgeColor','none','FaceAlpha',0.8); %#ok<AGROW>
            objs(end+1) = patch(ax,[0 r.w r.w 0],[r.yMax r.yMax r.yMax+28 r.yMax+15],[0.7 0.3 0.2],'EdgeColor','none','FaceAlpha',0.55); %#ok<AGROW>
        case 3 % 莲华古城
            for i = 1:4
                x0 = 90 + (i-1)*210;
                objs(end+1) = patch(ax,[x0 x0+40 x0+80],[r.yMax+8 r.h-24 r.yMax+8], ...
                    [0.65 0.45 0.72],'EdgeColor','none','FaceAlpha',0.45); %#ok<AGROW>
            end
        case 4 % 源工重镇
            for i = 1:6
                x0 = 40 + (i-1)*150;
                objs(end+1) = rectangle('Parent',ax,'Position',[x0 r.yMax+12 70 20], ...
                    'FaceColor',[0.42 0.45 0.4],'EdgeColor','none'); %#ok<AGROW>
            end
        otherwise % 幽邃地窟
            for i = 1:5
                [x,y] = circlePoly(120 + (i-1)*190, r.h-30-randi([0 10]), 24+randi([0 12]));
                objs(end+1) = patch(ax,x,y,[0.22 0.36 0.48],'EdgeColor','none','FaceAlpha',0.35); %#ok<AGROW>
            end
    end
end

function [xs, ys] = circlePoly(cx, cy, rr)
    th = linspace(0, 2*pi, 18);
    xs = cx + rr * cos(th);
    ys = cy + rr * sin(th);
end

function [xs, ys] = ellipsePoly(cx, cy, rx, ry)
    th = linspace(0, 2*pi, 18);
    xs = cx + rx * cos(th);
    ys = cy + ry * sin(th);
end

function [X, Y] = rectsToPatches(rects)
    n = size(rects,1);
    X = zeros(4,n);
    Y = zeros(4,n);
    for i = 1:n
        rr = rects(i,:);
        X(:,i) = [rr(1); rr(1)+rr(3); rr(1)+rr(3); rr(1)];
        Y(:,i) = [rr(2); rr(2); rr(2)+rr(4); rr(2)+rr(4)];
    end
end

function path = findMapBackgroundPath(mapName)
    baseDir = fileparts(mfilename('fullpath'));
    mapDir = fullfile(baseDir, '地图');
    path = '';
    if ~isfolder(mapDir)
        return;
    end

    exts = {'*.png','*.jpg','*.jpeg','*.bmp','*.webp'};
    files = [];
    for i = 1:numel(exts)
        files = [files; dir(fullfile(mapDir, exts{i}))]; %#ok<AGROW>
    end
    if isempty(files)
        return;
    end

    target = normalizeCN(mapName);
    names = cell(numel(files),1);
    for i = 1:numel(files)
        [~,nm,~] = fileparts(files(i).name);
        names{i} = normalizeCN(nm);
        if strcmp(names{i}, target)
            path = fullfile(files(i).folder, files(i).name);
            return;
        end
    end

    for i = 1:numel(files)
        if contains(names{i}, target) || contains(target, names{i})
            path = fullfile(files(i).folder, files(i).name);
            return;
        end
    end

    % 针对“隐世修所/隐士修所”这类常见字形差异做兜底
    if contains(target, '隐修所')
        for i = 1:numel(files)
            if contains(names{i}, '隐修所')
                path = fullfile(files(i).folder, files(i).name);
                return;
            end
        end
    end
end

function out = normalizeCN(s)
    s = string(s);
    s = erase(s, [" ", "_", "-", "　"]);
    s = replace(s, ["世","士"], ""); % 兼容隐世/隐士写法
    out = char(s);
end

function img = getMapBackgroundCached(path, targetH, targetW)
    persistent cache;
    if isempty(cache)
        cache = containers.Map('KeyType','char','ValueType','any');
    end
    key = path;
    if nargin >= 3
        key = sprintf('%s|%dx%d', path, round(targetH), round(targetW));
    end
    if isKey(cache, key)
        img = cache(key);
        return;
    end
    img = imread(path);
    % 游戏场景使用 YDir=normal，图像需要翻转一次避免上下颠倒
    img = flipud(img);
    if nargin >= 3 && ~isempty(targetH) && ~isempty(targetW)
        [h,w,~] = size(img);
        step = max(1, floor(min(h/max(1,targetH), w/max(1,targetW))));
        if step > 1
            img = img(1:step:end, 1:step:end, :);
        end
    end
    cache(key) = img;
end

function img = getHudAvatarCached(path)
    persistent cache;
    if isempty(cache)
        cache = containers.Map('KeyType','char','ValueType','any');
    end
    if isKey(cache, path)
        img = cache(path);
        return;
    end
    img = [];
    if ~isfile(path)
        return;
    end
    try
        img = imread(path);
        cache(path) = img;
    catch
        img = [];
    end
end
