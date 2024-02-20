clear all;
close all;
clc;

addpath("../commons");

%% Set up simulation parameters.
snr = 5;
nc = 512 : 128 : 2048; % various chirp numbers
bw = 150e6;
f0 = 9e9;
tc = 500e-6;
tr = 520e-6;
fs = 5e5;
r0 = 80.7;
v0 = 30.02;
a0 = 10;
rcs = 1;
ncNum = length(nc);
monNum = 100;
rdpTime = zeros(1, ncNum);
vaitTime = zeros(1, ncNum);
rftTime = zeros(1, ncNum);

%% Run the simulation.
for i = 1 : ncNum
    generator = Generator(snr, nc(i), bw, f0, tc, tr, fs, r0, v0, a0, rcs);
    [sig] = generator.perform();

    startVel = -80;
    endVel = 80;
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

%% Show the simulations results.
figure();

semilogy(nc, rdpTime, 'DisplayName', 'RDP');
hold on
semilogy(nc, vaitTime, 'DisplayName', 'VAIT');
semilogy(nc, rftTime, 'DisplayName', 'RFT');
legend;

saveplot2d('computational_cost_chirp_number_rdp', nc, rdpTime);
saveplot2d('computational_cost_chirp_number_vait', nc, vaitTime);
saveplot2d('computational_cost_chirp_number_rft', nc, rftTime);
