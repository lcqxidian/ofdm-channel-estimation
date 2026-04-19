clear; clc;

params = init_params();

[XTrain, YTrain] = build_nn_dataset(params, 50000);
net = train_tiny_nn(XTrain, YTrain);

save('tiny_nn_model.mat', 'net');
disp('Tiny NN model saved to tiny_nn_model.mat');