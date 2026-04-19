function Hest = channel_interp_spline(Hpilot, pilotIdx, Nfft)
    allIdx = 1:Nfft;
    Hest = interp1(pilotIdx, Hpilot, allIdx, 'spline', 'extrap').';
end