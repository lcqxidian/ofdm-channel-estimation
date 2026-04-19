function ber = calc_ber(txBits,rxBits)
    if length(txBits) ~= length(rxBits)
        error('发射比特数与接收比特数不一致');
    end
    numErr = sum(txBits ~= rxBits);
    ber = numErr / length(txBits);
end

