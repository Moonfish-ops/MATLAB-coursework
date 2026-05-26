function P = initPopupPool(maxPopups)
% initPopupPool 初始化固定容量弹窗池

    if nargin < 1 || isempty(maxPopups)
        maxPopups = 24;
    end
    proto = struct('active',false,'x',0,'y',0,'life',0,'text','','color',[1 1 1]);
    P = repmat(proto, 1, maxPopups);
end

