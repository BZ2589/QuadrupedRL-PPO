function trainPPO(varargin)
%trainPPO 四足机器人 PPO 训练（支持断点续训）
%   从空工作区运行: trainPPO
%   断点续训: trainPPO('resume')
%   查看状态: trainPPO('status')

clc;
clear all;

resume = false;
checkStatus = false;
if nargin > 0
    if strcmpi(varargin{1}, 'resume'), resume = true;
    elseif strcmpi(varargin{1}, 'status'), checkStatus = true; end
end

cd('D:\MATLAB_WS\QuadrupedRL-PPO');
addpath(pwd);

if checkStatus, checkTrainingStatus(); return; end

rng(0, "twister");
initializeRobotParameters;

mdl = "rlQuadrupedRobot";
load_system(mdl);

% 关闭 3D 可视化
set_param(mdl, 'SimulationMode', 'accelerator');
set_param(mdl, 'SimMechanicsOpenEditorOnUpdate', 'off');
set_param(mdl, 'ShowViewerIcons', 'off');
set_param(mdl, 'slexec_visualization_plugin', 'off');

fprintf('[1/5] 已加载模型 (Mode=%s)\n', get_param(mdl,'SimulationMode'));

obsInfo = rlNumericSpec([44 1], Name="observations");
actInfo = rlNumericSpec([8 1], LowerLimit=-1, UpperLimit=1, Name="torque");
blk = mdl + "/RL Agent";

opts = rlPPOAgentOptions();
opts.SampleTime = Ts;
opts.ExperienceHorizon = 1024;
opts.MiniBatchSize = 128;
opts.NumEpoch = 3;
opts.ClipFactor = 0.2;
opts.EntropyLossWeight = 0.1;
opts.ActorOptimizerOptions.LearnRate = 1e-3;
opts.ActorOptimizerOptions.GradientThreshold = 1;
opts.CriticOptimizerOptions.LearnRate = 1e-3;
opts.CriticOptimizerOptions.GradientThreshold = 1;

ckptFile = 'rlQuadrupedPPO_checkpoint.mat';

if resume && exist(ckptFile, 'file')
    d = load(ckptFile);
    agent = d.agent;
    startEp = 1;
    if isfield(d, 'chunkEnd'), startEp = d.chunkEnd + 1; end
    if isfield(d, 'allRew'), allRew = d.allRew; else, allRew = []; end
    if isfield(d, 'allAvg'), allAvg = d.allAvg; else, allAvg = []; end
    fprintf('[2/5] 从检查点继续 (回合 %d)\n', startEp);
else
    rng(0, "twister");
    agent = rlPPOAgent(obsInfo, actInfo, rlAgentInitializationOptions(NumHiddenUnit=256), opts);
    startEp = 1;
    allRew = [];
    allAvg = [];
    fprintf('[2/5] PPO Agent 已创建\n');
end

env = rlSimulinkEnv(mdl, blk, obsInfo, actInfo);
env.ResetFcn = @quadrupedResetFcn;

chunkSize = 10;
trainOpts = rlTrainingOptions(...
    'MaxEpisodes',chunkSize, ...
    'MaxStepsPerEpisode',floor(Tf/Ts), ...
    'ScoreAveragingWindowLength',250, ...
    'Plots','none', ...
    'Verbose',false);

evaluator = rlEvaluator(NumEpisodes=5, EvaluationFrequency=25);
fprintf('[3/5] 训练配置完成\n');

fprintf('[4/5] ========== 开始训练 ==========\n');
totalEp = 10000;
t0 = tic;

try
    for cStart = startEp:chunkSize:totalEp
        cEnd = min(cStart + chunkSize - 1, totalEp);
        cNum = cEnd - cStart + 1;
        trainOpts.MaxEpisodes = cNum;
        
        % 强制 accelerator 模式
        set_param(mdl, 'SimulationMode', 'accelerator');
        
        tChunk = tic;
        res = train(agent, env, trainOpts, Evaluator=evaluator);
        chunkT = toc(tChunk);
        
        if ~isempty(res.EpisodeReward)
            allRew = [allRew; res.EpisodeReward'];
            allAvg = [allAvg; res.AverageReward'];
        end
        
        epTime = chunkT / cNum;
        elSec = toc(t0);
        etaSec = epTime * (totalEp - cEnd);
        
        elStr = fmtTime(elSec);
        etStr = fmtTime(etaSec);
        
        fprintf('Ep %5d/%d | Reward: %8.2f | Avg: %8.2f | Time/Ep: %5.1fs | Elapsed: %s | ETA: %s\n', ...
            cEnd, totalEp, allRew(end), allAvg(end), epTime, elStr, etStr);
        
        save(ckptFile, 'agent', 'allRew', 'allAvg', 'cEnd');
        clear res
    end
    
    final.EpisodeReward = allRew';
    final.AverageReward = allAvg';
    save('rlQuadrupedPPO_final.mat', 'agent', 'final');
    save(ckptFile, 'agent', 'final', 'allRew', 'allAvg', 'cEnd');
    
    fprintf('[5/5] ========== 训练完成 ==========\n');
    disp('已保存最终参数 rlQuadrupedPPO_final.mat');
    
catch ME
    save(ckptFile, 'agent', 'allRew', 'allAvg', 'cEnd');
    if strcmp(ME.identifier,'MATLAB:interrupt')
        disp('训练已中断，检查点已保存');
        disp('运行 trainPPO("resume") 继续');
    else
        rethrow(ME);
    end
end

close_system(mdl, 0);

end

function s = fmtTime(sec)
    if sec < 60,        s = sprintf('%ds',round(sec));
    elseif sec < 3600,  s = sprintf('%dm%ds',floor(sec/60),mod(round(sec),60));
    else,               s = sprintf('%dh%dm',floor(sec/3600),floor(mod(sec,3600)/60));
    end
end

function checkTrainingStatus()
    ckpt = 'rlQuadrupedPPO_checkpoint.mat';
    fin  = 'rlQuadrupedPPO_final.mat';
    disp('========== 训练状态 ==========');
    if exist(fin,'file')
        d = load(fin);
        fprintf('训练已完成！最终奖励: %.4f\n', d.final.EpisodeReward(end));
    elseif exist(ckpt,'file')
        d = load(ckpt);
        fprintf('训练进行中，当前回合: %d\n', d.cEnd);
        if ~isempty(d.allRew), fprintf('最近奖励: %.4f\n', d.allRew(end)); end
    else
        disp('尚未开始训练');
    end
end
