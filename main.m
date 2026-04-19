clear; clc;
load('tiny_nn_model.mat', 'net');
params = init_params();

% ===== 仿真参数 =====
snrList = 4:2:26;      % 你也可以改成 10:2:20
numFrames = 300;       % 先保证能跑，后面可加到500或1000

% ===== BER数组 =====
berLinear   = zeros(size(snrList));
berSpline   = zeros(size(snrList));
berAdaptive = zeros(size(snrList));
berPerfect  = zeros(size(snrList));
berNN       = zeros(size(snrList));

for i = 1:length(snrList)

    snr = snrList(i);
    disp(['Running SNR = ', num2str(snr), ' dB']);

    totalErrLinear   = 0;
    totalErrSpline   = 0;
    totalErrAdaptive = 0;
    totalErrPerfect  = 0;
    totalErrNN       = 0;
    totalBits        = 0;

    for frame = 1:numFrames

        % ===== 1. 生成数据 =====
        pilotIdx = 1:params.pilotSpacing:params.Nfft;
        dataIdx = setdiff(1:params.Nfft, pilotIdx);
        numDataSymbols = length(dataIdx);

        numBits = numDataSymbols * params.bitsPerSym;
        txBits = randi([0 1], numBits, 1);

        % ===== 2. 调制 =====
        txSymbols = qpsk_mod(txBits);

        % ===== 3. 插入导频 =====
        [txFreq, pilotIdx, dataIdx] = insert_pilots(txSymbols, params);

        % ===== 4. IFFT =====
        txTime = ifft(txFreq, params.Nfft);

        % ===== 5. 加 CP =====
        txWithCp = [txTime(end-params.cpLen+1:end); txTime];

        % ===== 6. 复杂多径信道 =====
        h = [0.9, ...
             0.6*exp(1j*pi/6), ...
             0.4*exp(-1j*pi/4), ...
             0.25*exp(1j*pi/3), ...
             0.15*exp(-1j*pi/5), ...
             0.08];
        h = h / norm(h);

        rxChannel = filter(h, 1, txWithCp);
        rxWithCp = awgn(rxChannel, snr, 'measured');

        % ===== 7. 去 CP，只保留一个 OFDM 符号长度 =====
        rxTime = rxWithCp(params.cpLen+1 : params.cpLen+params.Nfft);

        % ===== 8. FFT =====
        rxFreq = fft(rxTime, params.Nfft);

        % ===== 9. 导频位置 LS 估计 =====
        rxPilot = rxFreq(pilotIdx);
        Hpilot = ls_channel_estimation(rxPilot, params.pilotValue);

        % ===== 10. 各种信道估计 =====
        HestLinear = channel_interp_linear(Hpilot, pilotIdx, params.Nfft);
        HestSpline = channel_interp_spline(Hpilot, pilotIdx, params.Nfft);
        [HestAdaptive, ~, ~] = channel_denoise_adaptive(HestLinear);
        HestNN = apply_nn_refinement(HestLinear, snr, net);

        % ===== 真实信道频响（Perfect CSI） =====
        Htrue = fft([h zeros(1, params.Nfft - length(h))], params.Nfft).';

        % ===== 11. 均衡 =====
        eqFreqLinear   = one_tap_equalizer(rxFreq, HestLinear);
        eqFreqSpline   = one_tap_equalizer(rxFreq, HestSpline);
        eqFreqAdaptive = one_tap_equalizer(rxFreq, HestAdaptive);
        eqFreqPerfect  = one_tap_equalizer(rxFreq, Htrue);
        eqFreqNN       = one_tap_equalizer(rxFreq, HestNN);

        % ===== 12. 提取数据子载波 =====
        rxDataLinear   = eqFreqLinear(dataIdx);
        rxDataSpline   = eqFreqSpline(dataIdx);
        rxDataAdaptive = eqFreqAdaptive(dataIdx);
        rxDataPerfect  = eqFreqPerfect(dataIdx);
        rxDataNN       = eqFreqNN(dataIdx);

        % ===== 13. 解调 =====
        rxBitsLinear   = qpsk_demod(rxDataLinear);
        rxBitsSpline   = qpsk_demod(rxDataSpline);
        rxBitsAdaptive = qpsk_demod(rxDataAdaptive);
        rxBitsPerfect  = qpsk_demod(rxDataPerfect);
        rxBitsNN       = qpsk_demod(rxDataNN);

        % ===== 14. 统计误码 =====
        totalErrLinear   = totalErrLinear   + sum(txBits ~= rxBitsLinear);
        totalErrSpline   = totalErrSpline   + sum(txBits ~= rxBitsSpline);
        totalErrAdaptive = totalErrAdaptive + sum(txBits ~= rxBitsAdaptive);
        totalErrPerfect  = totalErrPerfect  + sum(txBits ~= rxBitsPerfect);
        totalErrNN       = totalErrNN       + sum(txBits ~= rxBitsNN);

        totalBits = totalBits + length(txBits);
    end

    berLinear(i)   = totalErrLinear   / totalBits;
    berSpline(i)   = totalErrSpline   / totalBits;
    berAdaptive(i) = totalErrAdaptive / totalBits;
    berPerfect(i)  = totalErrPerfect  / totalBits;
    berNN(i)       = totalErrNN       / totalBits;
end

% ===== 避免 semilogy 遇到0断线 =====
epsPlot = 1e-6;
berLinearPlot   = berLinear;   berLinearPlot(berLinearPlot==0)     = epsPlot;
berSplinePlot   = berSpline;   berSplinePlot(berSplinePlot==0)     = epsPlot;
berAdaptivePlot = berAdaptive; berAdaptivePlot(berAdaptivePlot==0) = epsPlot;
berPerfectPlot  = berPerfect;  berPerfectPlot(berPerfectPlot==0)   = epsPlot;
berNNPlot       = berNN;       berNNPlot(berNNPlot==0)             = epsPlot;

% ===== 15. 画图 =====
figure;
semilogy(snrList, berLinearPlot,   '-o', 'LineWidth', 1.8); hold on;
semilogy(snrList, berSplinePlot,   '-s', 'LineWidth', 1.8);
semilogy(snrList, berAdaptivePlot, '-d', 'LineWidth', 1.8);
semilogy(snrList, berNNPlot,       '-x', 'LineWidth', 1.8);
semilogy(snrList, berPerfectPlot,  '--k', 'LineWidth', 1.8);

grid on;
xlabel('SNR (dB)');
ylabel('BER');
title('OFDM BER: Linear vs Spline vs Adaptive vs Tiny NN');
legend('Linear', 'Spline', 'Adaptive Smooth', 'Tiny NN', 'Perfect CSI', ...
    'Location', 'southwest');
ylim([1e-6 1]);

save('ber_result_nn_spline.mat', ...
    'snrList', 'berLinear', 'berSpline', 'berAdaptive', 'berNN', 'berPerfect');
saveas(gcf, 'ber_compare_nn_spline.png');

disp('Simulation finished.');
disp('Figure saved as ber_compare_nn_spline.png');

% ===== 16. 量化性能提升 =====
disp(' ');
disp('===== Tiny NN 相对其他方法的性能提升 =====');

% 逐点提升百分比（相对 Linear / Adaptive / Spline）
improveVsLinear = (berLinear - berNN) ./ berLinear * 100;
improveVsAdaptive = (berAdaptive - berNN) ./ berAdaptive * 100;
improveVsSpline = (berSpline - berNN) ./ berSpline * 100;

disp('各SNR点下 Tiny NN 相对 Linear 的BER降低百分比(%)：');
disp([snrList(:), improveVsLinear(:)]);

disp('各SNR点下 Tiny NN 相对 Adaptive Smooth 的BER降低百分比(%)：');
disp([snrList(:), improveVsAdaptive(:)]);

disp('各SNR点下 Tiny NN 相对 Spline 的BER降低百分比(%)：');
disp([snrList(:), improveVsSpline(:)]);

% 平均提升
meanImproveLinear = mean(improveVsLinear);
meanImproveAdaptive = mean(improveVsAdaptive);
meanImproveSpline = mean(improveVsSpline);

disp(' ');
fprintf('Tiny NN 相对 Linear 的平均BER降低：%.2f%%\n', meanImproveLinear);
fprintf('Tiny NN 相对 Adaptive Smooth 的平均BER降低：%.2f%%\n', meanImproveAdaptive);
fprintf('Tiny NN 相对 Spline 的平均BER降低：%.2f%%\n', meanImproveSpline);

% 找一个最典型SNR点，比如最后一个SNR
idxBest = length(snrList);
fprintf('\n在 SNR = %d dB 时：\n', snrList(idxBest));
fprintf('Linear BER   = %.4e\n', berLinear(idxBest));
fprintf('Spline BER   = %.4e\n', berSpline(idxBest));
fprintf('Adaptive BER = %.4e\n', berAdaptive(idxBest));
fprintf('Tiny NN BER  = %.4e\n', berNN(idxBest));

fprintf('Tiny NN 相对 Linear 提升：%.2f%%\n', improveVsLinear(idxBest));
fprintf('Tiny NN 相对 Adaptive 提升：%.2f%%\n', improveVsAdaptive(idxBest));
fprintf('Tiny NN 相对 Spline 提升：%.2f%%\n', improveVsSpline(idxBest));