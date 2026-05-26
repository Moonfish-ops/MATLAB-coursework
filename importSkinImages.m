function K = importSkinImages(K, projectDir)
% importSkinImages 图片识别与枪械绑定
% 规则：枪名skin/xxx.png -> 提取枪名 -> 绑定到该枪的皮肤表项

    if nargin < 2 || isempty(projectDir)
        projectDir = fileparts(mfilename('fullpath'));
    end

    rootDir = fullfile(projectDir, '枪皮');

    for i = 1:numel(K)
        K(i).imagePath = '';
        K(i).imageCount = 0;
    end

    if ~isfolder(rootDir)
        return;
    end

    d = dir(rootDir);
    for i = 1:numel(d)
        if ~d(i).isdir || any(strcmp(d(i).name,{'.','..'}))
            continue;
        end

        folderName = d(i).name;
        gunName = extractGunName(folderName);
        if isempty(gunName)
            continue;
        end

        skinIdx = find(arrayfun(@(s) strcmp(s.gun_name, gunName), K));
        if isempty(skinIdx)
            continue;
        end

        imgs = listImages(fullfile(rootDir, folderName));
        if isempty(imgs)
            continue;
        end

        imgs = sort(imgs);
        % 文件名无语义时，采用稳定顺序分配：同枪皮肤表顺序 <-> 图片字典序
        for j = 1:numel(skinIdx)
            pick = mod(j - 1, numel(imgs)) + 1;
            idx = skinIdx(j);
            K(idx).imagePath = imgs{pick};
            K(idx).imageCount = numel(imgs);
        end
    end
end

function gunName = extractGunName(folderName)
    gunName = '';
    suffix = 'skin';
    if numel(folderName) >= numel(suffix) && strcmpi(folderName(end-numel(suffix)+1:end), suffix)
        gunName = folderName(1:end-numel(suffix));
    end
    gunName = strtrim(gunName);
end

function files = listImages(dirPath)
    exts = {'*.jpg','*.jpeg','*.png','*.bmp','*.webp'};
    files = {};
    for i = 1:numel(exts)
        s = dir(fullfile(dirPath, exts{i}));
        for k = 1:numel(s)
            files{end+1} = fullfile(s(k).folder, s(k).name); %#ok<AGROW>
        end
    end
end
