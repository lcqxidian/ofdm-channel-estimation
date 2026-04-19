function symbols = qpsk_mod(bits)
    bits = bits(:);
    if mod(length(bits), 2) ~= 0
        error('比特数必须是偶数');
    end
    bitPairs = reshape(bits, 2, []).';
    symbols = zeros(size(bitPairs,1),1);
    for k = 1 : size(bitPairs,1)
        b1 = bitPairs(k,1);
        b2 = bitPairs(k,2);
        if b1 == 0 && b2 == 0
            symbols(k) = 1 + 1j;
        elseif b1 == 0 && b2 == 1
            symbols(k) = -1 + 1j;
        elseif b1 == 1 && b2 == 1
            symbols(k) = -1 - 1j;
        elseif b1 == 1 && b2 == 0
            symbols(k) = 1 - 1j;
        end
    end
    symbols = symbols /sqrt(2);
end