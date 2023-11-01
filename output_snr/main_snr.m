clear all;
close all;
clc;

addpath("../commons");

%% Set up simulation parameters.
inputSnr = -25 : 5 : 15;
nc = 128;
bw = 150e6;
f0 = 9e9;
tc = 102.4e-6;
tr = 120e-6;
fs = 40e6;
r0 = 80.42;
v0 = 800.2;
a0 = 600;
rcs = 1;
monNum = 100;

%% Find the peaks of the obtained range-velocity maps with noise-free signal.
generator = Generator(Inf, nc, bw, f0, tc, tr, fs, r0, v0, a0, rcs);
[noiseFreeSig] = generator.perform();

rdpEstimator = RdpEstimator(generator.mTr, generator.mTs, generator.mF0, ...
    generator.mNs, generator.mNc, generator.mGamma);
[~, rdpMap, ~] = rdpEstimator.perform(noiseFreeSig);
[~, ind] = max(rdpMap(:));
[rdpIv, rdpIr] = ind2sub(size(rdpMap), ind);

vaitEstimator = VaitEstimator(generator.mTr, generator.mTs, generator.mF0, ...
    generator.mNs, generator.mNc, generator.mGamma);
[~, vaitMap, ~] = vaitEstimator.perform(noiseFreeSig);
[~, ind] = max(vaitMap(:));
[vaitIv, vaitIr] = ind2sub(size(vaitMap), ind);

startVel = round(v0 / generator.mMaxVel / 2) * generator.mMaxVel * 2  - ...
    generator.mMaxVel;
endVel = startVel + generator.mMaxVel * 2;
rftEstimator = RftEstimator(generator.mTr, generator.mTs, generator.mF0, ...
    generator.mNs, generator.mNc, generator.mGamma, startVel, endVel);
[~, rftMap, ~] = rftEstimator.perform(noiseFreeSig);
[~, ind] = max(rftMap(:));
[rftIv, rftIr] = ind2sub(size(rftMap), ind);

%% Run the Monte Carlo simulation.
snrNum = length(inputSnr);
rdpOutputSnr = zeros(1, snrNum);
vaitOutputSnr = zeros(1, snrNum);
rftOutputSnr = zeros(1, snrNum);
parfor i = 1 : snrNum
    disp(i / snrNum)
    rftEstimator = RftEstimator(generator.mTr, generator.mTs, generator.mF0, ...
        generator.mNs, generator.mNc, generator.mGamma, startVel, endVel);
    rdpEstimator = RdpEstimator(generator.mTr, generator.mTs, generator.mF0, ...
        generator.mNs, generator.mNc, generator.mGamma);
    vaitEstimator = VaitEstimator(generator.mTr, generator.mTs, ...
        generator.mF0, generator.mNs, generator.mNc, generator.mGamma);

    generatorNew = generator.resetSnr(inputSnr(i));

    rdpOutputSnrTmp = zeros(1, monNum);
    vaitOutputSnrTmp = zeros(1, monNum);
    rftOutputSnrTmp = zeros(1, monNum);
    for j = 1 : monNum

        [sig] = generatorNew.perform();

        % Caluculate the output SNRs of the peaks.

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

figure();

plot(inputSnr, theoOutputSnr, 'DisplayName', 'Theoretical');
hold on
plot(inputSnr, rdpOutputSnr, 'DisplayName', 'RDP');
plot(inputSnr, vaitOutputSnr, 'DisplayName', 'VAIT');
plot(inputSnr, rftOutputSnr, 'DisplayName', 'RFT');
legend;
