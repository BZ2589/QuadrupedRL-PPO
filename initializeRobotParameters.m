%% 四足机器人参数

% Copyright 2019-2022 The MathWorks Inc.

% 躯干和腿部几何参数
L = 1;        % 前后髋关节间距 (m)
L_back = 1.5; % 躯干长度 (m)
l1 = 0.5517;  % 连杆 #1 长度 (m)
l2 = 0.5517;  % 连杆 #2 长度 (m)

% 机器人质量
M = 2;      % 躯干质量 (kg)
m1 = 0.2;   % 腿部连杆 #1 质量 (kg)
m2 = 0.2;   % 腿部连杆 #2 质量 (kg)

% 转动惯量 (kg-m^2)
Ixx = 1/12 * M * ((0.1*L_back)^2 + (0.1*L_back)^2);
Iyy = 1/12 * M * (L_back^2 + (0.1*L_back)^2);
Izz = 1/12 * M * (L_back^2 + (0.1*L_back)^2);
torso_MOI = [Ixx, Iyy, Izz];

% 重力加速度 (m/s^2)
g = -9.81;

% 采样时间 (s)
Ts = 0.025;

% 仿真时间 (s)
Tf = 10;

% 期望躯干高度 (m)
h_final = 0.75;

% 初始躯干高度和足部位移 (m)
init_foot_disp_x = 0;
init_body_height = h_final;

% 初始关节角度 (rad) 和角速度 (rad/s)
d2r = pi/180;
init_ang_FL = d2r * quadrupedInverseKinematics(init_foot_disp_x,-init_body_height,l1,l2);
init_ang_FR = init_ang_FL;
init_ang_RL = init_ang_FL;
init_ang_RR = init_ang_FL;
init_whip_FL = 0;
init_whip_FR = 0;
init_whip_RL = 0;
init_whip_RR = 0;

% 初始高度 (m)
foot_height = 0.05*l2*(1-sin(2*pi-(3*pi/2+init_ang_FL(1)+init_ang_FL(2))));
y_init = init_body_height + foot_height;

% 初始躯干速度 x,y (m/s)
vx_init = 0;
vy_init = 0;

% 接触摩擦属性
mu_kinetic = 0.88;
mu_static = 0.9;
v_thres = 0.001;

% 地面属性
ground.stiffness = 1e3;
ground.damping = 1e2;
ground.length = 100;
ground.width = 1;
ground.depth = 0.05;

% 髋关节和膝关节属性
joint.stiffness = 0;
joint.damping = 8;
joint.limitStiffness = 500;
joint.limitDamping = 50;
joint.transitionWidth = 2 * d2r;
hip_eq_angle = 0;
knee_eq_angle = 0;

% 变量限制
u_max = 10;                        % 最大关节力矩 = +/- u_max
y_min = 0.5;                       % 躯干距地面最小高度
z_max = 0.5;                       % z 方向最大位移
vx_max = 2.5;                      % 躯干水平速度最大值
vy_max = 2.5;                      % 躯干垂直速度最大值
vz_max = 2.5;                      % 躯干横向速度最大值
roll_max = 10 * d2r;               % 躯干横滚角最大值
pitch_max = 10 * d2r;              % 躯干俯仰角最大值
yaw_max = 20 * d2r;                % 躯干偏航角最大值
omega_x_max = pi/2;                % 绕 x 轴最大角速度
omega_y_max = pi/2;                % 绕 y 轴最大角速度
omega_z_max = pi/2;                % 绕 z 轴最大角速度
q_hip_min = -120 * d2r;            % 髋关节和膝关节角度限制
q_hip_max = -30 * d2r;
q_knee_min = 60 * d2r;
q_knee_max = 140 * d2r;
w_max = 2*pi*60/60;                % 髋关节和膝关节角速度限制
y_max = l1*cos(q_hip_max) + l2*cos(q_hip_max+q_knee_min);  % 躯干距地面最大高度
normal_force_max = ((M+4*m1+4*m2)*abs(g))/4;
friction_force_max = mu_static * normal_force_max;


