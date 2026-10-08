function closeViewer()
% closeViewer - 关闭 Simscape Multibody 3D 可视化窗口
% 用于在训练期间自动关闭 Multibody Explorer 窗口

    figs = findall(0, 'Type', 'figure');
    for j = 1:length(figs)
        try
            name = get(figs(j), 'Name');
            if ~isempty(name) && (contains(name, 'Multibody Explorer') || contains(name, 'Simscape Multibody'))
                close(figs(j));
            end
        catch
            % 忽略错误
        end
    end
end
