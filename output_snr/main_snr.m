clear all;
close all;
clc;

addpath("../commons");

%% Set up simulation parameters.
inputSnr = -25 : 5 : 15;
nc = 512;
bw = 150e6;
f0 = 9e9;
tc = 500e-6;
tr = 520e-6;
fs = 5e5;
r0 = 80.7;
v0 = 30.02;
a0 = 10;
rcs = 1;
monNum = 1000;

generator = Generator(Inf, nc, bw, f0, tc, tr, fs, r0, v0, a0, rcs);
[noiseFreeSig] = generator.perform();

%% Calculate the indexs of the peak for RDP.
rdpEstimator = RdpEstimator(generator.mTr, generator.mTs, generator.mF0, ...
    generator.mNs, generator.mNc, generator.mGamma);
rdpIr = round(r0 / generator.mDr) + 1;
rdpIv = mod(round(v0 / generator.mDv) - nc / 2, nc) + 1;
rdpCutIdx = [rdpIv, rdpIr]';

%% Calculate the indexs of the peak for VAIT.
vaitEstimator = VaitEstimator(generator.mTr, generator.mTs, generator.mF1, ...
    generator.mNs, generator.mNc, generator.mGamma);
vaitIr = mod(round((r0  + v0 * generator.mF0 / generator.mGamma) / ...
    vaitEstimator.mDr), generator.mNs) + 1;
vaitIv = mod(round(v0 / vaitEstimator.mDv) - nc / 2, nc) + 1;
vaitCutIdx = [vaitIv, vaitIr]';

%% Calculate the indexs of the peak for RFT.
startVel = round(v0 / generator.mMaxVel / 2) * generator.mMaxVel * 2  - ...
    generator.mMaxVel;
endVel = startVel + generator.mMaxVel * 2;
rftEstimator = RftEstimator(generator.mTr, generator.mTs, generator.mF1, ...
    generator.mNs, generator.mNc, generator.mGamma, startVel, endVel);
rftIr = mod(round((r0 - v0 * nc * tr + v0 * generator.mF0 / ...
    generator.mGamma) / generator.mDr), generator.mNs) + 1;
rftIv = mod(round((v0 - startVel) / rftEstimator.mDv), rftEstimator.mNv) + 1;
rftCutIdx = [rftIv, rftIr]';

%% Run the Monte Carlo simulation.
snrNum = length(inputSnr);
rdpOutputSnr = zeros(1, snrNum);
vaitOutputSnr = zeros(1, snrNum);
rftOutputSnr = zeros(1, snrNum);
parfor i = 1 : snrNum
    disp(i / snrNum)
    rftEstimator = RftEstimator(generator.mTr, generator.mTs, generator.mF1, ...
        generator.mNs, generator.mNc, generator.mGamma, startVel, endVel);
    rdpEstimator = RdpEstimator(generator.mTr, generator.mTs, generator.mF1, ...
        generator.mNs, generator.mNc, generator.mGamma);
    vaitEstimator = VaitEstimator(generator.mTr, generator.mTs, ...
        generator.mF0, generator.mNs, generator.mNc, generator.mGamma);

    generatorNew = generator.resetSnr(inputSnr(i));

    rdpOutputSnrTmp = zeros(1, monNum);
    vaitOutputSnrTmp = zeros(1, monNum);
    rftOutputSnrTmp = zeros(1, monNum);
    for j = 1 : monNum

        [sig] = generatorNew.perform();

        % RFT
        [~, rftMap] = rftEstimator.perform(sig);
        [~, rftMapNoNoise] = rftEstimator.perform(noiseFreeSig * ...
            db2mag(inputSnr(i)));
        rftDiffMap = rftMap - rftMapNoNoise;
        signalPower = abs(rftMap(rftIv, rftIr))^2;
        noisePower = var(reshape(rftMap - rftMapNoNoise, 1, []));
        rftOutputSnrTmp(j) = pow2db(signalPower / noisePower);

        % RDP
        [~, rdpMap, ~] = rdpEstimator.perform(sig);
        [~, rdpMapNoNoise, ~] = rdpEstimator.perform(noiseFreeSig * ...
            db2mag(inputSnr(i)));
        rdpDiffMap = rdpMap - rdpMapNoNoise;
        signalPower = abs(rdpMap(rdpIv, rdpIr))^2;
        noisePower = var(rdpDiffMap(:));
        rdpOutputSnrTmp(j) = pow2db(signalPower / noisePower);

        % VAIT
        [~, vaitMap, ~] = vaitEstimator.perform(sig);
        [~, arMapNoNoise, ~] = vaitEstimator.perform(noiseFreeSig * ...
            db2mag(inputSnr(i)));
        arDiffMap = vaitMap - arMapNoNoise;
        signalPower = abs(vaitMap(vaitIv, vaitIr))^2;
        noisePower = var(arDiffMap(:));
        vaitOutputSnrTmp(j) = pow2db(signalPower / noisePower);
    end

    rdpOutputSnr(i) = mean(rdpOutputSnrTmp);
    vaitOutputSnr(i) = mean(vaitOutputSnrTmp);
    rftOutputSnr(i) = mean(rftOutputSnrTmp);
end

theoOutputSnr = pow2db(generator.mNs * nc * db2pow(inputSnr) ./ ...
    (2 + 1 ./ db2pow(inputSnr)));

%% Show the simulations results.
figure();

plot(inputSnr, theoOutputSnr, 'DisplayName', 'Theoretical');
hold on
plot(inputSnr, rdpOutputSnr, 'DisplayName', 'RDP');
plot(inputSnr, vaitOutputSnr, 'DisplayName', 'VAIT');
plot(inputSnr, rftOutputSnr, 'DisplayName', 'RFT');
legend;
