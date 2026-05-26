function cfg = keybindData(customBindings)
% keybindData  可重绑定键位配置
% customBindings 可传入已有绑定结构体，缺失字段会自动补齐默认值

    cfg.actions = { ...
        'left','right','up','down', ...
        'jump','shoot','dash', ...
        'skillC','skillQ','skillE','skillX', ...
        'openWarehouse','nextWeapon','prevWeapon', ...
        'restartLevel','exitGame'};

    cfg.actionCN = { ...
        '左移','右移','上移','下移', ...
        '跳跃','普通射击','冲刺/闪避', ...
        'C技能','Q技能','E技能','X技能', ...
        '打开仓库','下一个武器','上一个武器', ...
        '重开关卡','退出战斗'};

    cfg.holdActions = {'left','right','up','down','shoot','dash'};

    defaults = struct();
    defaults.left = 'a';
    defaults.right = 'd';
    defaults.up = 'w';
    defaults.down = 's';
    defaults.jump = 'k';
    defaults.shoot = 'j';
    defaults.dash = 'shift';
    defaults.skillC = 'c';
    defaults.skillQ = 'q';
    defaults.skillE = 'e';
    defaults.skillX = 'x';
    defaults.openWarehouse = 'l';
    defaults.nextWeapon = 'o';
    defaults.prevWeapon = 'p';
    defaults.restartLevel = 'r';
    defaults.exitGame = 'escape';

    cfg.defaults = defaults;

    if nargin < 1 || ~isstruct(customBindings)
        cfg.bindings = defaults;
    else
        cfg.bindings = defaults;
        acts = cfg.actions;
        for i = 1:numel(acts)
            a = acts{i};
            if isfield(customBindings, a) && ischar(customBindings.(a)) && ~isempty(customBindings.(a))
                cfg.bindings.(a) = lower(strtrim(customBindings.(a)));
            end
        end
    end

    % 关键约束：L 键只保留给仓库，修复旧存档/异常配置的双绑定
    cfg.bindings.openWarehouse = 'l';
    for i = 1:numel(cfg.actions)
        a = cfg.actions{i};
        if strcmp(a, 'openWarehouse')
            continue;
        end
        if strcmp(cfg.bindings.(a), 'l')
            cfg.bindings.(a) = cfg.defaults.(a);
        end
    end
end
