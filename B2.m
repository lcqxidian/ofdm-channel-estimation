
clear; clc; close all;


set(0, 'DefaultAxesFontName', 'Microsoft YaHei');
set(0, 'DefaultTextFontName', 'Microsoft YaHei');

%% 1. 系统与滤波器参数设置
Fs = 1e6;             % 采样率设定为 1MHz
t = 0:1/Fs:0.01;      % 仿真时间设为 10ms
fc = 40e3;            % 低通滤波器截止频率为 40 kHz

% 使用 Butterworth（巴特沃斯）滤波器设计一个 4 阶低通滤波器
% 归一化截止频率 Wn = fc / (Fs/2)
[b, a] = butter(4, fc/(Fs/2), 'low');

%% 2. 准备输入信号
% 信号1：20kHz 单音正弦波
f1 = 20e3;
x1 = sin(2 * pi * f1 * t);

% 信号2：20kHz, 40kHz, 100kHz 三音正弦波
f2 = 40e3;
f3 = 100e3;
x2 = sin(2*pi*f1*t) + sin(2*pi*f2*t) + sin(2*pi*f3*t);

% 信号3：20kHz 方波
x3 = square(2 * pi * f1 * t);

%% 3. 调用绘图函数生成结果
analyze_and_plot(t, x1, b, a, Fs, '20kHz 单音正弦波', 1);
analyze_and_plot(t, x2, b, a, Fs, '20kHz+40kHz+100kHz 三音正弦波', 2);
analyze_and_plot(t, x3, b, a, Fs, '20kHz 方波', 3);

disp('仿真完成。');

%% ========================================================================
% 附加：绘图函数封装
% =========================================================================
function analyze_and_plot(t, x, b, a, Fs, title_str, fig_num)
    % 将信号通过滤波器
    y = filter(b, a, x);
    
    % 创建图形窗口
    figure(fig_num);
    set(gcf, 'Position', [100, 100, 1000, 800]); 
    
    % 显式指定 sgtitle 的字体，防止部分 MATLAB 版本的全局设置未覆盖此处
    sgtitle([title_str, ' 通过 40kHz 低通滤波器的仿真分析'], 'FontSize', 14, 'FontWeight', 'bold', 'FontName', 'Microsoft YaHei');
    
    % 提取画图需要的数据点（时域显示前150个点，保证波形清晰）
    N_plot = 150; 
    
    % (1) 时域波形
    subplot(4,2,1);
    plot(t(1:N_plot)*1000, x(1:N_plot), 'LineWidth', 1.5);
    title('输入信号时域波形'); xlabel('时间 (ms)'); ylabel('幅值'); grid on;
    
    subplot(4,2,2);
    plot(t(1:N_plot)*1000, y(1:N_plot), 'r', 'LineWidth', 1.5);
    title('输出信号时域波形'); xlabel('时间 (ms)'); ylabel('幅值'); grid on;
    
    % (2) 频域波形 (频谱)
    N = length(x);
    f = (0:N-1)*(Fs/N);
    X_fft = abs(fft(x))*2/N; % 归一化幅度
    Y_fft = abs(fft(y))*2/N;
    
    subplot(4,2,3);
    plot(f(1:floor(N/2))/1000, X_fft(1:floor(N/2)), 'LineWidth', 1.5);
    title('输入信号频谱图'); xlabel('频率 (kHz)'); ylabel('幅值'); 
    xlim([0, 150]); grid on;
    
    subplot(4,2,4);
    plot(f(1:floor(N/2))/1000, Y_fft(1:floor(N/2)), 'r', 'LineWidth', 1.5);
    title('输出信号频谱图'); xlabel('频率 (kHz)'); ylabel('幅值'); 
    xlim([0, 150]); grid on;
    
    % (3) 自相关函数
    [Rxx, lags_x] = xcorr(x, 'biased');
    [Ryy, lags_y] = xcorr(y, 'biased');
    tau_x = lags_x / Fs * 1000; % 转换成毫秒
    tau_y = lags_y / Fs * 1000;
    
    subplot(4,2,5);
    plot(tau_x, Rxx, 'LineWidth', 1.5);
    title('输入信号自相关函数'); xlabel('时延 \tau (ms)'); ylabel('相关幅值'); 
    xlim([-0.2, 0.2]); grid on;
    
    subplot(4,2,6);
    plot(tau_y, Ryy, 'r', 'LineWidth', 1.5);
    title('输出信号自相关函数'); xlabel('时延 \tau (ms)'); ylabel('相关幅值'); 
    xlim([-0.2, 0.2]); grid on;
    
    % (4) 功率谱密度 (PSD) - 使用 pwelch 方法
    [Pxx, f_pxx] = pwelch(x, [], [], [], Fs);
    [Pyy, f_pyy] = pwelch(y, [], [], [], Fs);
    
    subplot(4,2,7);
    plot(f_pxx/1000, 10*log10(Pxx), 'LineWidth', 1.5);
    title('输入信号功率谱密度 (PSD)'); xlabel('频率 (kHz)'); ylabel('dB/Hz'); 
    xlim([0, 150]); grid on;
    
    subplot(4,2,8);
    plot(f_pyy/1000, 10*log10(Pyy), 'r', 'LineWidth', 1.5);
    title('输出信号功率谱密度 (PSD)'); xlabel('频率 (kHz)'); ylabel('dB/Hz'); 
    xlim([0, 150]); grid on;
end