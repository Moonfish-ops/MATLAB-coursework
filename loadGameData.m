function [ok, data] = loadGameData(saveFile)
% loadGameData 读取存档

    ok = false;
    data = struct();

    if nargin < 1 || isempty(saveFile) || ~isfile(saveFile)
        return;
    end

    try
        S = load(saveFile, 'data');
        if isfield(S, 'data')
            data = S.data;
            ok = true;
        end
    catch
        ok = false;
    end
end
