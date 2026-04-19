function [X, Y] = build_nn_dataset(params, numSamples)
    % X: [numSamples, 19]
    % Y: [numSamples, 2]  -> 预测残差的实部和虚部

    X = zeros(numSamples, 19);
    Y = zeros(numSamples, 2);

    count = 0;

    while count < numSamples
        % ===== 随机SNR =====
        snr = 8 + 22 * rand();   % 8~30 dB

        % ===== 更丰富的随机多径信道 =====
        L = randi([4, 7]);  % 随机抽头数
        amp = exp(-0.5*(0:L-1)); % 指数衰减
        phase = exp(1j * 2*pi*rand(1, L));
        h = amp .* phase;
        h = h / norm(h);

        % ===== 一帧数据 =====
        pilotIdx = 1:params.pilotSpacing:params.Nfft;
        dataIdx = setdiff(1:params.Nfft, pilotIdx);
        numDataSymbols = length(dataIdx);

        numBits = numDataSymbols * params.bitsPerSym;
        txBits = randi([0 1], numBits, 1);

        txSymbols = qpsk_mod(txBits);
        [txFreq, pilotIdx, ~] = insert_pilots(txSymbols, params);

        txTime = ifft(txFreq, params.Nfft);
        txWithCp = [txTime(end-params.cpLen+1:end); txTime];

        rxChannel = filter(h, 1, txWithCp);
        rxWithCp = awgn(rxChannel, snr, 'measured');

        rxTime = rxWithCp(params.cpLen+1 : params.cpLen+params.Nfft);
        rxFreq = fft(rxTime, params.Nfft);

        % ===== 粗估计 =====
        rxPilot = rxFreq(pilotIdx);
        Hpilot = ls_channel_estimation(rxPilot, params.pilotValue);
        Hcoarse = channel_interp_linear(Hpilot, pilotIdx, params.Nfft);

        % ===== 真实频响 =====
        Htrue = fft([h zeros(1, params.Nfft - length(h))], params.Nfft).';

        % ===== 构造9点窗口样本 =====
        for k = 5:params.Nfft-4
            if count >= numSamples
                break;
            end

            localWin = Hcoarse(k-4:k+4);
            count = count + 1;

            % 输入：9个复数窗口 -> 18维 + 1维SNR
            X(count, :) = [real(localWin).', imag(localWin).', snr/30];

            % 标签：残差 = 真实值 - 粗估计值
            deltaH = Htrue(k) - Hcoarse(k);
            Y(count, :) = [real(deltaH), imag(deltaH)];
        end
    end
end