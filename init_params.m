function params = init_params()
    params.Nfft = 64;              % 子载波总数
    params.cpLen = 16;             % 循环前缀长度
    params.bitsPerSym = 2;         % QPSK每个符号2比特

    params.pilotSpacing = 8;      % 稀疏导频，让插值更难
    params.pilotValue = (1 + 1j) / sqrt(2); % 导频归一化
end