function [ofdmFreq,pilotIdx,dataIdx] = insert_pilots(datasymbols,params)
pilotIdx = 1 : params.pilotSpacing :params.Nfft;
dataIdx = setdiff(1:params.Nfft,pilotIdx);
ofdmFreq = zeros(params.Nfft,1);
if length(datasymbols) ~= length(dataIdx);
    error('数据符与数据子载波数不匹配');
end
ofdmFreq(pilotIdx) = params.pilotValue;
ofdmFreq(dataIdx) = datasymbols;
end

