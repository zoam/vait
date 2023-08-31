clear all;
close all;
clc;

addpath("./commons");

%% Set up simulation parameters.
snr = 5;
nc = 128;
bw = 150e6;
f0 = 9e9;
tc = 102.4e-6;
tr = 120e-6;
fs = 40e6;
r0 = [80 60 20];
v0 = [25 -20 10];
a0 = [600 600 600];
rcs = [1 1 1];

figInd = 0;

%% Collect the samples of the beat signals.
generator = Generator(snr, nc, bw, f0, tc, tr, fs, r0, v0, a0, rcs);
[sig] = generator.perform();

%% Peform the RFT method.
startVel = round(v0(1) / generator.mMaxVel / 2) * generator.mMaxVel * 2  - ...
    generator.mMaxVel;
endVel = startVel + generator.mMaxVel * 2;
rftEstimator = RftEstimator(generator.mTr, generator.mTs, generator.mF0, ...
    generator.mNs, generator.mNc, generator.mGamma, startVel, endVel);

[rftEstimator, ~] = rftEstimator.perform(sig);
[figInd] = rftEstimator.visualize(figInd, 0, 100);

%% Peform the RDP method.
rdpEstimator = RdpEstimator(generator.mTr, generator.mTs, generator.mF0, ...
    generator.mNs, generator.mNc, generator.mGamma);

[rdpEstimator, ~] = rdpEstimator.perform(sig);
[figInd] = rdpEstimator.visualize(figInd, 0, 100);

%% Perform the VAIT method.
vaitEstimator = VaitEstimator(generator.mTr, generator.mTs, generator.mF0, ...
    generator.mNs, generator.mNc, generator.mGamma);

[vaitEstimator, ~] = vaitEstimator.perform(sig);
[figInd] = vaitEstimator.visualize(figInd, 0, 100);
