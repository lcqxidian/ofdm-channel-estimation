function bits = qpsk_demod(symbols)
    bits = zeros(2*length(symbols),1);
    for k = 1:length(symbols)
        re = real(symbols(k));
        im = imag(symbols(k));
        if re >= 0 && im >= 0
            bits(2*k - 1) = 0;
            bits(2*k) = 0;
        elseif re <= 0 && im >= 0
            bits(2*k - 1) = 0;
            bits(2*k) = 1;
        elseif re <= 0 && im <= 0
            bits(2*k - 1) = 1;
            bits(2*k) = 1;
        elseif re >= 0 && im <= 0
            bits(2*k - 1) = 1;
            bits(2*k) = 0;
        end
    end
end