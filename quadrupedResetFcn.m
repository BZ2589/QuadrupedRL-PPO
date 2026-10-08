function in = quadrupedResetFcn(in)
% 随机化初始条件

% 确保基础工作区有参数
if ~evalin('base', 'exist(''l1'',''var'')')
    evalin('base', 'initializeRobotParameters');
end
l1 = evalin('base','l1');
l2 = evalin('base','l2');

max_foot_disp_x = 0.1;   % 足部位移最大值 (m)
min_body_height = 0.7;   % 躯干最小高度 (m)
max_body_height = 0.8;   % 躯干最大高度 (m)
max_speed_x = 0.05;      % 水平速度最大值 (m/s)
max_speed_y = 0.025;     % 垂直速度最大值 (m/s)

if rand < 0.5
    % 随机初始条件
    b = min_body_height + (max_body_height - min_body_height) * rand;
    a = -max_foot_disp_x + 2 * max_foot_disp_x * rand(1,4);
    d2r = pi/180;
    th_FL = d2r * quadrupedInverseKinematics(a(1),-b,l1,l2);
    th_FR = d2r * quadrupedInverseKinematics(a(2),-b,l1,l2);
    th_RL = d2r * quadrupedInverseKinematics(a(3),-b,l1,l2);
    th_RR = d2r * quadrupedInverseKinematics(a(4),-b,l1,l2);
    foot_height = 0.05*l2*(1-sin(2*pi-(3*pi/2+sum([th_FL;th_FR;th_RL;th_RR],2))));
    y_body = max(b) + max(foot_height);
    vx = 2 * max_speed_x * (rand-0.5);
    vy = 2 * max_speed_y * (rand-0.5);
else
    % 固定初始条件
    y_body = 0.7588;
    th_FL = [-0.8234 1.6468];
    th_FR = th_FL;
    th_RL = th_FL;
    th_RR = th_FL;
    vx = 0;
    vy = 0;
end

% 设置环境变量
in = setVariable(in,'y_init',y_body);
in = setVariable(in,'init_ang_FL',th_FL);
in = setVariable(in,'init_ang_FR',th_FR);
in = setVariable(in,'init_ang_RL',th_RL);
in = setVariable(in,'init_ang_RR',th_RR);
in = setVariable(in,'vx_init',vx);
in = setVariable(in,'vy_init',vy);
end
