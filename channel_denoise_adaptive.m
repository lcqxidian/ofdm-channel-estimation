function [Hout, win, diffMetric] = channel_denoise_adaptive(Hin)
    diffMetric = mean(abs(diff(Hin)));

    if diffMetric < 0.04
        win = 9;
    elseif diffMetric < 0.08
        win = 7;
    elseif diffMetric < 0.14
        win = 5;
    else
        win = 3;
    end

    Hout = smoothdata(Hin, 'movmean', win);
end