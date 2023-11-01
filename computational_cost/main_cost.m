clear all;
close all;
clc;

addpath("../commons");

%% Set up simulation parameters.
snr = 5;
nc = 512 : 128 : 2048;
bw = 150e6;
f0 = 9e9;
tc = 102.4e-6;
tr = 120e-6;
fs = 40e6;
r0 = 80.42;
v0 = 800.2;
a0 = 600;
rcs = 1;
ncNum = length(nc);
monNum = 100;
rdpTime = zeros(1, ncNum);
vaitTime = zeros(1, ncNum);
rftTime = zeros(1, ncNum);
for i = 1 : ncNum
    generator = Generator(snr, nc(i), bw, f0, tc, tr, fs, r0, v0, a0, rcs);
    [sig] = generator.perform();

    startVel = -800;
    endVel = 800;
    rftEstimator = RftEstimator(generator.mTr, generator.mTs, generator.mF0, ...
        generator.mNs, generator.mNc, generator.mGamma, startVel, endVel);

    rdpEstimator = RdpEstimator(generator.mTr, generator.mTs, generator.mF0, ...
        generator.mNs, generator.mNc, generator.mGamma);
    
    vaitEstimator = VaitEstimator(generator.mTr, generator.mTs, ...
        generator.mF0, generator.mNs, generator.mNc, generator.mGamma);
    
    rdpTimeTmp = zeros(1, monNum);
    vaitTimeTmp = zeros(1, monNum);
    rftTimeTmp = zeros(1, monNum);
    for j = 1 : monNum
        [rdpEstimator, ~, rdpTimeTmp(j)] = rdpEstimator.perform(sig);
        [vaitEstimator, ~, vaitTimeTmp(j)] = vaitEstimator.perform(sig);
        [rftEstimator, ~, rftTimeTmp(j)] = rftEstimator.perform(sig);
    end
    rdpTime(i) = mean(rdpTimeTmp);
    vaitTime(i) = mean(vaitTimeTmp);
    rftTime(i) = mean(rftTimeTmp);
end

figure();

semilogy(nc, rdpTime, 'DisplayName', 'RDP');
hold on
semilogy(nc, vaitTime, 'DisplayName', 'VAIT');
semilogy(nc, rftTime, 'DisplayName', 'RFT');
legend;
