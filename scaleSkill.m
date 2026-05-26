function sk = scaleSkill(proto, mul)
% scaleSkill 按难度倍率缩放技能数值，返回字段集与 blankEnemy 的 skills 模板一致
%   dmg     : 线性 ×mul
%   cd      : 反向开方 /sqrt(mul)（难度越高 CD 越短）
%   range   : 线性 ×mul
%   bulletSpd / aoeR : 开方 sqrt(mul)

    sk.id            = proto.id;
    sk.name          = proto.name;
    sk.kind          = proto.kind;
    sk.dmgBase       = proto.dmgBase;
    sk.cdBase        = proto.cdBase;
    sk.rangeBase     = proto.rangeBase;
    sk.bulletSpdBase = proto.bulletSpdBase;
    sk.effect        = proto.effect;
    sk.dmg           = round(proto.dmgBase * mul);
    sk.cd            = max(24, round(proto.cdBase / sqrt(mul)));
    sk.range         = proto.rangeBase * mul;
    sk.bulletSpd     = proto.bulletSpdBase * sqrt(mul);
    sk.aoeR          = proto.aoeR * sqrt(mul);
end
