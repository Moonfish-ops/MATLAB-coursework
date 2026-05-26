function map = weaponSkinMap(skins)
% weaponSkinMap 武器 -> 可用皮肤索引映射

    map = struct();
    for i = 1:numel(skins)
        wid = '';
        if isfield(skins(i),'weaponId')
            wid = skins(i).weaponId;
        elseif isfield(skins(i),'weapon')
            wid = skins(i).weapon;
        end

        if isempty(wid)
            continue;
        end

        fn = matlab.lang.makeValidName(wid);
        if ~isfield(map, fn)
            map.(fn) = i;
        else
            map.(fn)(end+1) = i;
        end
    end
end
