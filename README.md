# 四足机器人 PPO 强化学习

## 项目介绍

本项目使用强化学习算法（PPO，Proximal Policy Optimization，近端策略优化）训练四足机器人行走。机器人使用 Simscape™ Multibody™ 建模，目标是在直线方向上以最小的控制力矩实现稳定行走。

- **观测空间**：44 个观测值（包括躯干位置、姿态、关节角度/速度、地面接触力等），归一化到 [-1, 1]
- **动作空间**：8 个动作值（对应 8 个关节的力矩信号），归一化到 [-1, 1]，实际输出 ±10 N·m
- **奖励函数**：鼓励前进速度 + 存活奖励 - 高度偏差惩罚 - 俯仰角惩罚 - 力矩惩罚

## 与原 DDPG 版本的区别

本项目基于 MathWorks 官方示例 "Quadruped Robot Locomotion Using DDPG Agent" 改进，主要区别如下：

| 特性 | DDPG 版本 | PPO 版本 |
|------|-----------|----------|
| 算法类型 | Off-policy（确定性策略） | On-policy（随机策略） |
| Actor 输出 | 确定性动作值 | 动作分布的均值和标准差 |
| 经验回放 | 需要 ExperienceBuffer（1e6） | 不需要，使用当前策略收集的经验 |
| 探索方式 | 添加高斯噪声 | 通过随机策略自然探索 |
| 关键参数 | NoiseOptions、ExperienceBufferLength | ExperienceHorizon、ClipFactor、EntropyLossWeight |
| 网络结构 | Actor（确定性）+ Critic（Q值） | Actor（随机策略）+ Critic（V值） |

### 主要改动

1. **Agent 类型**：`rlDDPGAgent` → `rlPPOAgent`
2. **Agent 选项**：`rlDDPGAgentOptions` → `rlPPOAgentOptions`
3. **新增 PPO 参数**：
   - `ExperienceHorizon = 2048`：每次收集的经验步数
   - `MiniBatchSize = 64`：小批量梯度更新大小
   - `ClipFactor = 0.2`：策略裁剪因子，限制更新幅度
   - `EntropyLossWeight = 0.01`：熵正则化权重，鼓励探索
4. **学习率**：`1e-3` → `3e-4`
5. **移除 DDPG 特有参数**：`ExperienceBufferLength`、`NoiseOptions`

## 运行方法

### 前置要求

- MATLAB R2022a 或更高版本（支持 `rlPPOAgent`）
- Reinforcement Learning Toolbox™
- Simscape™ Multibody™
- Parallel Computing Toolbox™（可选，用于并行训练加速）

### 快速开始

#### 方式一：使用 Live Script

1. 在 MATLAB 中切换到项目目录：
   ```matlab
   cd('path\to\QuadrupedRL-PPO')
   ```
2. 打开 `RLQuadrupedRobotExample.mlx`
3. 在 MATLAB Live Editor 中逐个运行代码段

#### 方式二：使用训练脚本（推荐）

```matlab
% 切换到项目目录
cd('path\to\QuadrupedRL-PPO')

% 开始新训练（可视化已关闭，速度更快）
trainPPO

% 查看训练状态
trainPPO('status')

% 从检查点续训（中断后恢复）
trainPPO('resume')
```

### 训练说明

- **命令行进度输出**：每 10 回合打印一行进度，包含奖励、耗时和预计剩余时间
- **3D 可视化已关闭**：Multibody Explorer 3D 窗口自动关闭，训练窗口已关闭以最大化训练速度
- **断点续训**：每 10 回合保存检查点，中断后可从断点继续
- **断点续训**：每 50 回合自动保存检查点，中断后可从断点继续
- **训练时间**：串行训练约数小时，建议分多次完成（利用断点续训）
- **训练完成后**：参数保存到 `rlQuadrupedPPOAgentParams_final.mat`

### 断点续训工作流程

```
第 1 次运行：trainPPO          → 训练 100 回合后手动停止（Ctrl+C）
第  2 次运行：trainPPO          → 从第 101 回合继续
...
完成后：参数自动保存到 rlQuadrupedPPOAgentParams_final.mat
```

> 注：续训与一次性训练效果基本一致。唯一差异是优化器动量状态会重新初始化，对最终性能影响可忽略。

## PPO Agent 参数配置

| 参数 | 值 | 说明 |
|------|-----|------|
| ExperienceHorizon | 2048 | 每次收集的经验步数 |
| MiniBatchSize | 64 | 小批量梯度更新大小 |
| ClipFactor | 0.2 | 策略裁剪因子，限制更新幅度 |
| EntropyLossWeight | 0.01 | 熵正则化权重，鼓励探索 |
| Actor 学习率 | 3e-4 | Actor 网络优化器学习率 |
| Critic 学习率 | 3e-4 | Critic 网络优化器学习率 |
| 梯度阈值 | 1.0 | 梯度裁剪阈值 |
| 隐藏单元数 | 256 | 每层隐藏单元数量 |

## 项目文件

```
QuadrupedRL-PPO/
├── RLQuadrupedRobotExample.mlx   % 主脚本（Live Script）
├── trainPPO.m                    % PPO 训练脚本
├── initializeRobotParameters.m   % 机器人参数初始化
├── quadrupedResetFcn.m           % 仿真重置函数
├── quadrupedInverseKinematics.m  % 逆运动学计算
├── Extr_Data_LinkEndHole.m       % 连杆数据
├── Extr_Data_Mesh.m              % 网格数据
├── rlQuadrupedAgentParams.mat    % DDPG 预训练参数（参考用）
├── rlQuadrupedRobot.slx          % Simulink 模型（未修改）
└── README.md                     % 项目说明
```

## 注意事项

- **DDPG 预训练参数不兼容**：`rlQuadrupedAgentParams.mat` 是 DDPG 版本的预训练参数，由于网络结构不同，无法直接用于 PPO。需要训练新的 PPO Agent。
- **训练时间较长**：四足机器人 Simulink 模型仿真计算量大，已关闭可视化窗口加速。
- **Simulink 模型未修改**：`rlQuadrupedRobot.slx` 保持原样，仅 Agent 算法从 DDPG 替换为 PPO。
- **检查点文件已加入 `.gitignore`**：训练产生的中间文件（`checkpoints/`、`*.mat`）不会被提交到 GitHub。

## 参考资料

- [MathWorks 原始 DDPG 示例](https://www.mathworks.com/help/reinforcement-learning/ug/train-quadruped-robot-to-walk-using-agents.html)
- [PPO Agent 文档](https://www.mathworks.com/help/reinforcement-learning/ug/proximal-policy-optimization-agents.html)

## 许可

基于 MathWorks 示例改进，版权归 MathWorks 所有。
