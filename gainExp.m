function game = gainExp(game, amount)
% gainExp - 玩家获得经验, 到达阈值自动升级 (最高 5 级)
%
% 经验曲线 (与武器/皮肤系统解耦, 想改只改 nextThreshold):
%   Lv1 -> Lv2 : 100 EXP
%   Lv2 -> Lv3 : 180 EXP
%   Lv3 -> Lv4 : 300 EXP
%   Lv4 -> Lv5 : 450 EXP
%
% 每次升级 (与武器无关, 只改玩家):
%   HP 上限 +15
%   MP 上限 +10
%   所有武器伤害系数 +5% (累乘在 dmgBonus 上)
%   回满 HP / MP

    p = game.player;
    if p.level >= 5
        return;
    end

    p.exp = p.exp + amount;
    while p.level < 5 && p.exp >= p.expNext
        p.exp      = p.exp - p.expNext;
        p.level    = p.level + 1;
        p.hpMax    = p.hpMax + 15;
        p.mpMax    = p.mpMax + 10;
        p.dmgBonus = p.dmgBonus + 0.05;
        p.hp       = p.hpMax;
        p.mp       = p.mpMax;
        p.expNext  = nextThreshold(p.level);

        pop = struct('x',p.x+p.w/2,'y',p.y+p.h+20,'life',60, ...
                     'text',sprintf('LEVEL UP! Lv %d', p.level), ...
                     'color',[1 0.95 0.3]);
        if isempty(game.popups)
            game.popups = pop;
        else
            game.popups(end+1) = pop;
        end
    end
    if p.level >= 5
        p.expNext = 0;
    end

    game.player = p;
end

function n = nextThreshold(newLevel)
    switch newLevel
        case 2, n = 180;   % 2 级已打, 下一档需要再攒 180 经验
        case 3, n = 300;
        case 4, n = 450;
        case 5, n = 0;
        otherwise, n = 9999;
    end
end
