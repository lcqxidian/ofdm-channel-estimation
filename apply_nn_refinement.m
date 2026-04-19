function Hnn = apply_nn_refinement(Hcoarse, snr, net)
    N = length(Hcoarse);
    Hnn = Hcoarse;   % 边界先保留原值

    numPts = N - 8;  % 9点窗口，中心点从5到N-4
    Xtest = zeros(numPts, 19);

    for k = 5:N-4
        localWin = Hcoarse(k-4:k+4);
        Xtest(k-4, :) = [real(localWin).', imag(localWin).', snr/30];
    end

    Ypred = predict(net, Xtest);

    for k = 5:N-4
        idx = k - 4;
        deltaHpred = Ypred(idx, 1) + 1j * Ypred(idx, 2);
        Hnn(k) = Hcoarse(k) + deltaHpred;
    end
end