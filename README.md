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

### 运行步骤

1. 克隆或下载本项目
2. 在 MATLAB 中切换到项目目录：
   ```matlab
   cd('path\to\QuadrupedRL-PPO')
   ```
3. 运行 `init` 或直接打开 `RLQuadrupedRobotExample.mlx`
4. 在 MATLAB Live Editor 中逐个运行代码段

### 训练说明

- 默认 `doTraining = false`，加载预训练参数进行仿真验证
- 将 `doTraining` 设置为 `true` 可从头开始训练（需要较长时间，建议启用并行训练）
- 训练时使用 `rlEvaluator` 每 25 个回合评估一次策略性能

## 结果说明

### 代码验证

PPO Agent 已成功创建并运行仿真。由于网络架构差异（PPO 的 Actor 输出动作分布参数，DDPG 的 Actor 输出确定性动作值），**原 DDPG 预训练参数无法直接用于 PPO**。

### 仿真对比

| Agent | 预训练参数 | 仿真结果 |
|-------|-----------|----------|
| DDPG | 可用 | 可正常行走（需使用参考项目中的模型） |
| PPO | 需重新训练 | 随机初始化时无法行走（预期行为） |

### 下一步

1. 训练 PPO Agent：将 `doTraining` 设为 `true`，训练约 1000 个回合
2. 保存训练好的 PPO 参数
3. 对比 DDPG 和 PPO 的行走性能

## 项目文件

```
QuadrupedRL-PPO/
├── RLQuadrupedRobotExample.mlx   % 主脚本（Live Script）
├── initializeRobotParameters.m   % 机器人参数初始化
├── quadrupedResetFcn.m           % 仿真重置函数
├── quadrupedInverseKinematics.m  % 逆运动学计算
├── Extr_Data_LinkEndHole.m       % 连杆数据
├── Extr_Data_Mesh.m              % 网格数据
├── rlQuadrupedAgentParams.mat    % 预训练参数（DDPG 版本）
├── rlQuadrupedRobot.slx          % Simulink 模型（未修改）
└── README.md                     % 项目说明
```

## 参考资料

- [MathWorks 原始 DDPG 示例](https://www.mathworks.com/help/reinforcement-learning/ug/train-quadruped-robot-to-walk-using-agents.html)
- [PPO Agent 文档](https://www.mathworks.com/help/reinforcement-learning/ug/proximal-policy-optimization-agents.html)

## 许可

基于 MathWorks 示例改进，版权归 MathWorks 所有。
