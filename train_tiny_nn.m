function net = train_tiny_nn(XTrain, YTrain)
    layers = [
        featureInputLayer(19)
        fullyConnectedLayer(64)
        reluLayer
        fullyConnectedLayer(32)
        reluLayer
        fullyConnectedLayer(2)
        regressionLayer
    ];

    options = trainingOptions('adam', ...
        'MaxEpochs', 40, ...
        'MiniBatchSize', 256, ...
        'InitialLearnRate', 1e-3, ...
        'Shuffle', 'every-epoch', ...
        'Verbose', false, ...
        'Plots', 'training-progress');

    net = trainNetwork(XTrain, YTrain, layers, options);
end