clear all;
close all;
clc;

addpath("../commons");

%% Set up simulation parameters.
snr = 5;
nc = 512;
bw = 150e6;
f0 = 9e9;
tc = 500e-6;
tr = 520e-6;
fs = 5e5;
r0 = [80 60 20];
v0 = [7 -7 5];
a0 = [10 10 10];

rcs = [1 1 1];
figInd = 0;

%% Collect the samples of the beat signals.
generator = Generator(snr, nc, bw, f0, tc, tr, fs, r0, v0, a0, rcs);
[sig] = generator.perform();

%% Perform the proposed AR method.
mvaitEstimator = MvaitEstimator(generator.mTr, generator.mTs, generator.mF1, ...
    generator.mNs, generator.mNc, generator.mGamma);

[mvaitEstimator, ~] = mvaitEstimator.perform(sig);
[figInd] = mvaitEstimator.visualize(figInd);
