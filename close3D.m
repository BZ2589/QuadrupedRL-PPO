function close3D()
% close3D - 关闭 Simscape Multibody 3D 可视化窗口
    try
        f = findall(0, 'Type', 'figure');
        for k = 1:numel(f)
            nm = get(f(k), 'Name');
            if ~isempty(nm) && contains(nm, 'Multibody')
                close(f(k));
            end
        end
    catch
    end
end
