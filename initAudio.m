function audio = initAudio(baseDir)
% initAudio 初始化音频资源（技能语音）

    if nargin < 1 || isempty(baseDir)
        baseDir = fileparts(mfilename('fullpath'));
    end

    audio = struct();
    audio.enabled = true;
    audio.maxDurationSec = 2.8;  % 只保留技能语音前段，降低技能触发卡顿
    audio.shootDurationSec = 0.10; % 枪声单次时长，短促且能稳定听见
    audio.baseDir = baseDir;
    audio.activePlayers = {};
    audio.players = struct();
    audio.cueMinGap = struct();
    audio.cueMinGap.skillC = 6;
    audio.cueMinGap.skillQ = 6;
    audio.cueMinGap.skillE = 6;
    audio.cueMinGap.skillX = 6;
    audio.cueMinGap.shoot = 3;
    audio.targetFs = 22050;

    seDir = fullfile(baseDir, '音效');
    % CQEX 按顺序一一绑定 + 射击音效
    audio.skillOrder = {'skillC','skillQ','skillE','skillX','shoot'};
    audio.skillMap = struct();
    audio.skillMap.skillC = fullfile(seDir, 'letsgo.mp3');
    audio.skillMap.skillQ = fullfile(seDir, 'niceeeeee.mp3');
    audio.skillMap.skillE = fullfile(seDir, '酱味大鸡.mp3');
    audio.skillMap.skillX = fullfile(seDir, '你才是挑战者.mp3');
    audio.skillMap.shoot = fullfile(seDir, '开枪音效.mp3');

    keys = audio.skillOrder;
    audio.cache = struct();
    for i = 1:numel(keys)
        k = keys{i};
        audio.cache.(k) = struct('ok', false, 'y', [], 'fs', 0, 'path', audio.skillMap.(k));
        p = audio.skillMap.(k);
        if isfile(p)
            try
                [y, fs] = audioread(p);
                maxSec = audio.maxDurationSec;
                if strcmp(k, 'shoot')
                    % 去掉开头静音，避免短裁剪后听不到枪声
                    if ~isempty(y)
                        env = max(abs(y), [], 2);
                        head = find(env > 0.01, 1, 'first');
                        if ~isempty(head) && head > 1
                            pre = round(0.01 * fs); % 保留10ms前导
                            st = max(1, head - pre);
                            y = y(st:end, :);
                        end
                    end
                    maxSec = audio.shootDurationSec;
                end
                maxN = round(maxSec * fs);
                if size(y,1) > maxN
                    y = y(1:maxN, :);
                end
                % 轻量化：统一转单声道并尽量降采样，减少播放瞬时开销
                if size(y,2) > 1
                    y = mean(y,2);
                end
                if fs > audio.targetFs
                    y = localResampleLinear(y, fs, audio.targetFs);
                    fs = audio.targetFs;
                end
                y = single(y);
                audio.cache.(k).ok = true;
                audio.cache.(k).y = y;
                audio.cache.(k).fs = fs;
            catch
                % 读取失败则保持 ok=false
            end
        end
    end
end

function y2 = localResampleLinear(y, fsIn, fsOut)
% localResampleLinear toolbox-free resample
    if fsIn == fsOut || isempty(y)
        y2 = y;
        return;
    end
    nIn = size(y,1);
    tIn = (0:nIn-1)' / fsIn;
    dur = (nIn-1) / fsIn;
    nOut = max(1, floor(dur * fsOut) + 1);
    tOut = (0:nOut-1)' / fsOut;
    y2 = interp1(tIn, y, tOut, 'linear', 'extrap');
end
