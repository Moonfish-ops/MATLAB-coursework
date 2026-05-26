function [ok, account] = loginMenu(projectDir)
% loginMenu 账号密码登录/注册

    ok = false;
    account = struct('username','');

    if nargin < 1 || isempty(projectDir)
        projectDir = fileparts(mfilename('fullpath'));
    end

    dbDir = fullfile(projectDir, 'accounts');
    if ~isfolder(dbDir)
        mkdir(dbDir);
    end
    dbFile = fullfile(dbDir, 'users.mat');

    users = loadUsers(dbFile);

    f = figure('Name','账号登录', ...
        'NumberTitle','off', ...
        'MenuBar','none', ...
        'ToolBar','none', ...
        'Resize','off', ...
        'Color',[0.08 0.10 0.14], ...
        'Position',[430 220 420 290], ...
        'WindowStyle','modal', ...
        'CloseRequestFcn',@(~,~) onExit());

    uicontrol(f,'Style','text','String','账号登录 / 注册', ...
        'BackgroundColor',get(f,'Color'),'ForegroundColor',[1 0.92 0.5], ...
        'FontSize',16,'FontWeight','bold','Position',[120 240 180 30]);

    uicontrol(f,'Style','text','String','账号', ...
        'BackgroundColor',get(f,'Color'),'ForegroundColor',[0.9 0.95 1], ...
        'HorizontalAlignment','left','Position',[58 188 48 22]);
    edtUser = uicontrol(f,'Style','edit','Position',[110 190 250 26], ...
        'FontSize',11,'HorizontalAlignment','left');

    uicontrol(f,'Style','text','String','密码', ...
        'BackgroundColor',get(f,'Color'),'ForegroundColor',[0.9 0.95 1], ...
        'HorizontalAlignment','left','Position',[58 148 48 22]);
    edtPwd = uicontrol(f,'Style','edit','Position',[110 150 250 26], ...
        'FontSize',11,'HorizontalAlignment','left', ...
        'KeyPressFcn',@onPwdKeyPress);

    msg = uicontrol(f,'Style','text','String','', ...
        'BackgroundColor',get(f,'Color'),'ForegroundColor',[1 0.7 0.4], ...
        'HorizontalAlignment','left','Position',[40 118 340 22]);

    uicontrol(f,'Style','pushbutton','String','登录', ...
        'Position',[52 58 90 36],'FontSize',11, ...
        'Callback',@(~,~) onLogin());

    uicontrol(f,'Style','pushbutton','String','注册', ...
        'Position',[162 58 90 36],'FontSize',11, ...
        'Callback',@(~,~) onRegister());

    uicontrol(f,'Style','pushbutton','String','游客登录', ...
        'Position',[272 58 90 36],'FontSize',11, ...
        'Callback',@(~,~) onGuest());

    uicontrol(f,'Style','pushbutton','String','退出游戏', ...
        'Position',[138 16 140 30],'FontSize',10, ...
        'Callback',@(~,~) onExit());

    uiwait(f);
    if isvalid(f)
        delete(f);
    end

    function onLogin()
        u = strtrim(get(edtUser,'String'));
        p = get(edtPwd,'String');
        if isempty(u) || isempty(p)
            set(msg,'String','账号和密码不能为空');
            return;
        end

        idx = find(strcmp({users.username}, u), 1);
        if isempty(idx)
            set(msg,'String','账号不存在，请先注册');
            return;
        end

        if strcmp(users(idx).passwordHash, hashPassword(p))
            ok = true;
            account.username = u;
            uiresume(f);
        else
            set(msg,'String','密码错误');
        end
    end

    function onRegister()
        u = strtrim(get(edtUser,'String'));
        p = get(edtPwd,'String');
        if isempty(u) || isempty(p)
            set(msg,'String','账号和密码不能为空');
            return;
        end

        [okUser, reason] = validateUsername(u);
        if ~okUser
            set(msg,'String',reason);
            return;
        end

        if numel(p) < 4
            set(msg,'String','密码至少 4 位');
            return;
        end

        if any(strcmp({users.username}, u))
            set(msg,'String','账号已存在，请直接登录');
            return;
        end

        users(end+1).username = u; %#ok<AGROW>
        users(end).passwordHash = hashPassword(p);
        if saveUsers(dbFile, users)
            users = loadUsers(dbFile);  % 立即刷新内存，避免当前会话找不到新账号
            set(msg,'String','注册成功，请点击登录');
        else
            set(msg,'String','注册失败：无法写入本地账号库');
        end
    end

    function onGuest()
        ok = true;
        account.username = 'guest';
        uiresume(f);
    end

    function onExit()
        ok = false;
        account.username = '';
        if isvalid(f)
            uiresume(f);
        end
    end

    function onPwdKeyPress(~, evt)
        if strcmp(evt.Key, 'return') || strcmp(evt.Key, 'enter')
            onLogin();
        end
    end
end

function users = loadUsers(dbFile)
    users = repmat(struct('username','','passwordHash',''), 0, 0);
    if ~isfile(dbFile)
        return;
    end
    try
        S = load(dbFile, 'users');
        if isfield(S,'users') && isstruct(S.users)
            users = S.users;
        end
    catch
        users = repmat(struct('username','','passwordHash',''), 0, 0);
    end
end

function ok = saveUsers(dbFile, users)
    ok = false;
    try
        parentDir = fileparts(dbFile);
        if ~isfolder(parentDir)
            mkdir(parentDir);
        end
        save(dbFile, 'users');
        if ~isfile(dbFile)
            return;
        end
        ok = true;
    catch
        ok = false;
    end
end

function [ok, reason] = validateUsername(u)
    ok = false;
    reason = '';
    if isempty(u)
        reason = '账号不能为空';
        return;
    end
    if strlength(string(u)) < 2 || strlength(string(u)) > 24
        reason = '账号长度需在 2-24 个字符';
        return;
    end
    % Windows 文件名非法字符过滤（用于后续本地存档文件名）
    if ~isempty(regexp(u, '[\\/:*?"<>|]', 'once'))
        reason = '账号不能包含 \\ / : * ? \" < > |';
        return;
    end
    ok = true;
end

function h = hashPassword(pwd)
    try
        md = java.security.MessageDigest.getInstance('SHA-256');
        md.update(uint8(unicode2native(pwd, 'UTF-8')));
        d = typecast(md.digest(), 'uint8');
        h = lower(reshape(dec2hex(d,2).',1,[]));
    catch
        % 回退简易哈希（仅本地用途）
        u = double(pwd);
        h = sprintf('F%u', mod(sum(u .* (1:numel(u))), 4294967291));
    end
end
