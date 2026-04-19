function Hest = channel_interp_linear(Hpilot, pilotIdx, Nfft)

    allIdx = 1:Nfft;

    Hest = interp1(pilotIdx, Hpilot, allIdx, 'linear', 'extrap').';

end