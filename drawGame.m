function drawGame(game)
% drawGame frame render (performance-focused)

    if ~isfield(game,'ax') || ~ishandle(game.ax), return; end
    if ~isfield(game,'scene') || isempty(game.scene), return; end

    persistent prevBulletDrawCount prevPopupDrawCount lastHudTextFrame
    if isempty(prevBulletDrawCount), prevBulletDrawCount = 0; end
    if isempty(prevPopupDrawCount), prevPopupDrawCount = 0; end
    if isempty(lastHudTextFrame), lastHudTextFrame = -1e9; end
    if game.stateTimer < lastHudTextFrame
        % 新开一局时 stateTimer 会回到 0，这里重置节流计时避免 HUD 文本长期不刷新
        lastHudTextFrame = -1e9;
        prevBulletDrawCount = 0;
        prevPopupDrawCount = 0;
    end

    s = game.scene;
    p = game.player;
    r = game.room;

    % player
    renderY = p.y + p.z;
    [bx,by] = rectsToPatches([p.x, renderY, p.w, p.h]);
    set(s.playerBody,'XData',bx,'YData',by);

    bodyCol = [0.2 0.55 0.95];
    if p.hitFlash > 0
        bodyCol = [1 1 1];
    elseif p.invincible > 0 && mod(p.invincible,6) >= 3
        bodyCol = [0.95 0.95 0.95];
    elseif p.dashTimer > 0
        bodyCol = [0.6 1 1];
    end
    set(s.playerBody,'FaceColor',bodyCol);

    [hx,hy] = circlePoly(p.x+p.w/2, renderY+p.h-6, 8);
    set(s.playerHead,'XData',hx,'YData',hy);

    [sx,sy] = ellipsePoly(p.x+p.w/2, p.y, 14, 5);
    set(s.playerShadow,'XData',sx,'YData',sy);

    gx1 = p.x + p.w/2;
    gx2 = gx1 + p.facing*18;
    gy = renderY + p.h*0.55;
    set(s.playerGun,'XData',[gx1 gx2],'YData',[gy gy]);

    % dog
    if p.dog.alive
        dx = p.dog.x;
        dy = p.dog.y;
        [dbx,dby] = rectsToPatches([dx-10, dy+2, 20, 12]);
        set(s.dogBody,'XData',dbx,'YData',dby,'Visible','on');
        [dhx,dhy] = circlePoly(dx+8*p.facing, dy+15, 5);
        set(s.dogHead,'XData',dhx,'YData',dhy,'Visible','on');
        [dsx,dsy] = ellipsePoly(dx, dy, 12, 4);
        set(s.dogShadow,'XData',dsx,'YData',dsy,'Visible','on');
        set(s.dogTail,'XData',[dx-9*p.facing dx-15*p.facing], ...
            'YData',[dy+11 dy+15+2*sin(game.stateTimer/5)],'Visible','on');
        if isfield(s,'dogName') && isgraphics(s.dogName)
            set(s.dogName,'Position',[dx dy+26 0],'String','CXY','Visible','on');
        end
    else
        set(s.dogBody,'Visible','off');
        set(s.dogHead,'Visible','off');
        set(s.dogShadow,'Visible','off');
        set(s.dogTail,'Visible','off');
        if isfield(s,'dogName') && isgraphics(s.dogName)
            set(s.dogName,'Visible','off');
        end
    end

    % enemies
    for i = 1:numel(r.enemies)
        e = r.enemies(i);
        ry = e.y + e.z;
        if e.alive
            col = enemyColor(e);
            if e.hit > 0
                col = [1 1 1];
            end
            [ebx,eby] = rectsToPatches([e.x, ry, e.w, e.h]);
            set(s.enemyBody(i),'XData',ebx,'YData',eby,'FaceColor',col,'Visible','on');
            [ehx,ehy] = circlePoly(e.x+e.w/2, ry+e.h-6, headRadius(e));
            set(s.enemyHead(i),'XData',ehx,'YData',ehy,'Visible','on');
            [esx,esy] = ellipsePoly(e.x+e.w/2, e.y, shadowRx(e), 4);
            set(s.enemyShadow(i),'XData',esx,'YData',esy,'Visible','on');
            set(s.enemyGun(i),'XData',[e.x+e.w/2 e.x+e.w/2+e.dir*12], ...
                'YData',[ry+e.h*0.55 ry+e.h*0.55],'Visible','on');
        elseif e.deathAnim > 0
            t = e.deathAnim / 15;
            sw = e.w * t;
            sh = e.h * t;
            [ebx,eby] = rectsToPatches([e.x+(e.w-sw)/2, ry, sw, sh]);
            set(s.enemyBody(i),'XData',ebx,'YData',eby,'FaceColor',[0.55 0.55 0.55],'Visible','on');
            set(s.enemyHead(i),'Visible','off');
            set(s.enemyShadow(i),'Visible','off');
            set(s.enemyGun(i),'Visible','off');
        else
            set(s.enemyBody(i),'Visible','off');
            set(s.enemyHead(i),'Visible','off');
            set(s.enemyShadow(i),'Visible','off');
            set(s.enemyGun(i),'Visible','off');
        end
    end

    % pickups
    nPool = numel(s.pickups);
    for i = 1:numel(r.pickups)
        if i > nPool, break; end
        pk = r.pickups(i);
        if pk.alive
            rad = 7;
            if strcmp(pk.type,'star') || strcmp(pk.type,'skin')
                rad = 9;
            end
            [x,y] = circlePoly(pk.x, pk.y, rad);
            set(s.pickups(i),'XData',x,'YData',y,'FaceColor',pickupColor(pk.type),'Visible','on');
        else
            set(s.pickups(i),'Visible','off');
        end
    end
    for i = (numel(r.pickups)+1):nPool
        set(s.pickups(i),'Visible','off');
    end

    if r.doorOpen
        set(s.rightDoorOpen,'Visible','on');
    else
        set(s.rightDoorOpen,'Visible','off');
    end

    % bullets
    nB = min(numel(game.bullets), numel(s.bulletPool));
    loopB = max(nB, prevBulletDrawCount);
    for i = 1:loopB
        if i <= nB
            b = game.bullets(i);
            rad = 3;
            if b.crit
                rad = 4.5;
            end
            [x,y] = circlePoly(b.x, b.y+b.z, rad);
            set(s.bulletPool(i),'XData',x,'YData',y,'FaceColor',b.color,'Visible','on');
        else
            set(s.bulletPool(i),'Visible','off');
        end
    end
    prevBulletDrawCount = nB;

    % popups
    nP = min(numel(game.popups), numel(s.popupPool));
    loopP = max(nP, prevPopupDrawCount);
    for i = 1:loopP
        if i <= nP
            pp = game.popups(i);
            set(s.popupPool(i),'Position',[pp.x pp.y 0],'String',pp.text,'Color',pp.color,'Visible','on');
        else
            set(s.popupPool(i),'Visible','off');
        end
    end
    prevPopupDrawCount = nP;

    h = game.hud;
    SH = game.screenH;

    hpFrac = max(0, min(1, p.hp/max(1,p.hpMax)));
    [x,y] = rectsToPatches([91 SH-51 218*hpFrac 12]);
    set(h.hp,'XData',x,'YData',y);

    mpFrac = max(0, min(1, p.mp/max(1,p.mpMax)));
    [x,y] = rectsToPatches([91 SH-73 218*mpFrac 10]);
    set(h.mp,'XData',x,'YData',y);

    if p.expNext > 0
        expFrac = max(0, min(1, p.exp/p.expNext));
    else
        expFrac = 1;
    end
    [x,y] = rectsToPatches([91 SH-87 218*expFrac 5]);
    set(h.exp,'XData',x,'YData',y);

    eFrac = max(0, min(1, p.ultEnergy/p.ultEnergyMax));
    [x,y] = rectsToPatches([351 41 148*eFrac 8]);
    set(h.ultFill,'XData',x,'YData',y);

    updateHudText = (game.stateTimer - lastHudTextFrame) >= 3;
    if updateHudText
        lastHudTextFrame = game.stateTimer;
        set(h.hpText,'String',sprintf('HP %d / %d', round(max(0,p.hp)), p.hpMax));
        set(h.mpText,'String',sprintf('MP %d / %d', round(max(0,p.mp)), p.mpMax));
        if p.expNext > 0
            set(h.expText,'String',sprintf('Lv%d  %d/%d', p.level, p.exp, p.expNext));
        else
            set(h.expText,'String',sprintf('Lv%d  MAX', p.level));
        end

        W = game.weapons(p.weaponIdx);
        set(h.weaponText,'String',sprintf('武器: %s', W.name));

        eqIdx = 0;
        if p.weaponIdx <= numel(game.progress.equippedSkinByWeapon)
            eqIdx = game.progress.equippedSkinByWeapon(p.weaponIdx);
        end
        if eqIdx > 0
            skinName = game.skins(eqIdx).nameCN;
        else
            skinName = '无';
        end
        set(h.skinText,'String',sprintf('皮肤: %s', skinName));
        set(h.mapText,'String',sprintf('%s  第%d关', r.mapName, game.currentRoom));

        nAlive = 0;
        for ai = 1:numel(r.enemies)
            if r.enemies(ai).alive
                nAlive = nAlive + 1;
            end
        end
        set(h.roomText,'String',sprintf('房间类型: %s  剩余敌人: %d', roomTypeCN(r.type), nAlive));
        set(h.info,'String',sprintf('金币 %d   星星 %d   已拥有皮肤 %d', p.coins, p.stars, nnz(game.progress.ownedSkins)));
        set(h.skillText,'String',sprintf('技能 C[%s] Q[%s] E[%s] X[%s]   仓库[L] 切枪[O/P]', ...
            cdText(p.cdC,p.buffLetsGo), cdText(p.cdQ,p.buffNice), cdText(p.cdE,p.dogTimer), cdText(p.cdX,p.buffUlt)));
        set(h.ultText,'String',sprintf('X能量 %d/%d', round(p.ultEnergy), p.ultEnergyMax));
    end

    if r.doorOpen && strcmp(game.state,'playing')
        set(h.doorHint,'String','门已开启，前往右侧进入下一关','Visible','on');
    else
        set(h.doorHint,'Visible','off');
    end

    [bossAlive,bossE] = findBoss(r);
    if bossAlive
        frac = max(0, min(1, bossE.hp / max(1,bossE.hpMax)));
        SW = game.screenW;
        bossW = 420; bossH = 16;
        bossX = (SW - bossW) / 2; bossY = SH - 26;
        [x,y] = rectsToPatches([bossX bossY bossW*frac bossH]);
        set(h.bossHpFill,'XData',x,'YData',y,'Visible','on');
        set(h.bossHpBg,'Visible','on');
        if updateHudText
            set(h.roomText,'String',sprintf('Boss生命: %d / %d', round(bossE.hp), bossE.hpMax));
            set(h.bossHpText,'String',sprintf('Boss %d / %d', round(bossE.hp), bossE.hpMax),'Visible','on');
        else
            set(h.bossHpText,'Visible','on');
        end
    else
        if isfield(h,'bossHpFill'), set(h.bossHpFill,'Visible','off'); end
        if isfield(h,'bossHpBg'), set(h.bossHpBg,'Visible','off'); end
        if isfield(h,'bossHpText'), set(h.bossHpText,'Visible','off'); end
    end

    switch game.state
        case 'playing'
            set([h.overlayBg h.overlayTitle h.overlaySub],'Visible','off');
        case 'dead'
            set(h.overlayBg,'Visible','on');
            set(h.overlayTitle,'String','战斗失败','Color',[0.95 0.25 0.25],'Visible','on');
            set(h.overlaySub,'String','按重开键重新挑战，或按退出键返回主菜单','Visible','on');
        case 'roomClear'
            set(h.overlayBg,'Visible','on');
            set(h.overlayTitle,'String','房间清理完成','Color',[0.35 0.9 1],'Visible','on');
            set(h.overlaySub,'String','正在进入下一关...','Visible','on');
        case 'levelComplete'
            set(h.overlayBg,'Visible','on');
            set(h.overlayTitle,'String',sprintf('%s 已通关', r.mapName), ...
                'Color',[0.25 0.9 0.45],'Visible','on');
            set(h.overlaySub,'String','正在进入下一地图...','Visible','on');
        case 'win'
            set(h.overlayBg,'Visible','on');
            set(h.overlayTitle,'String','全地图通关','Color',[0.25 0.95 0.4],'Visible','on');
            set(h.overlaySub,'String','按退出键返回主菜单，可在仓库整理收藏','Visible','on');
    end

    drawnow limitrate nocallbacks;
end

function t = cdText(cd, buff)
    if buff > 0
        t = sprintf('生效%.1fs', buff/60);
    elseif cd > 0
        t = sprintf('CD%.1fs', cd/60);
    else
        t = '就绪';
    end
end

function [found,bossE] = findBoss(r)
    found = false;
    bossE = [];
    for i = 1:numel(r.enemies)
        e = r.enemies(i);
        if strcmp(e.type,'boss') && e.alive
            found = true;
            bossE = e;
            return;
        end
    end
end

function c = pickupColor(type)
    switch type
        case 'coin', c = [1.00 0.85 0.10];
        case 'heart', c = [0.95 0.20 0.30];
        case 'mana', c = [0.30 0.60 1.00];
        case 'star', c = [1.00 1.00 0.50];
        case 'skin', c = [1.00 0.40 1.00];
        otherwise, c = [0.80 0.80 0.80];
    end
end

function c = enemyColor(e)
    switch e.type
        case 'melee', c = [0.75 0.20 0.20];
        case 'ranged', c = [0.60 0.30 0.85];
        case 'eliteMelee', c = [0.95 0.35 0.15];
        case 'eliteRanged', c = [0.50 0.10 0.95];
        case 'boss', c = [0.95 0.15 0.55];
        otherwise, c = [0.70 0.30 0.30];
    end
end

function rad = headRadius(e)
    if strcmp(e.type,'boss')
        rad = 12;
    elseif startsWith(e.type,'elite')
        rad = 9;
    else
        rad = 7;
    end
end

function rx = shadowRx(e)
    if strcmp(e.type,'boss')
        rx = 22;
    elseif startsWith(e.type,'elite')
        rx = 15;
    else
        rx = 12;
    end
end

function t = roomTypeCN(ty)
    switch ty
        case 'normal'
            t = '普通';
        case 'elite'
            t = '精英';
        case 'reward'
            t = '奖励';
        case 'boss'
            t = 'Boss';
        otherwise
            t = ty;
    end
end

function [xs,ys] = circlePoly(cx,cy,r)
    th = linspace(0,2*pi,10);
    xs = cx + r*cos(th);
    ys = cy + r*sin(th);
end

function [xs,ys] = ellipsePoly(cx,cy,rx,ry)
    th = linspace(0,2*pi,10);
    xs = cx + rx*cos(th);
    ys = cy + ry*sin(th);
end

function [X,Y] = rectsToPatches(rects)
    n = size(rects,1);
    X = zeros(4,n);
    Y = zeros(4,n);
    for i = 1:n
        rr = rects(i,:);
        X(:,i) = [rr(1); rr(1)+rr(3); rr(1)+rr(3); rr(1)];
        Y(:,i) = [rr(2); rr(2); rr(2)+rr(4); rr(2)+rr(4)];
    end
end
