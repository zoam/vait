clear all;
close all;
clc;

addpath("../commons");

%% Set up simulation parameters.
snrStart = -45;
% snrStart = -10;
snrStep = 1;
snrEnd = max(0, snrStart);
snrList = snrStart : snrStep : snrEnd;
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
pfa = 1e-6;
thr = sqrt(-2 * log(pfa));
monNum = 100;

p = @(z, a, var) (z ./ var .* exp(-1 * (z.^2 + a^2) / 2 / var) .* ...
    besseli(0, z * a / var));

%% Find the peaks of the obtained range-velocity maps with noise-free signal.
generator = Generator(Inf, nc, bw, f0, tc, tr, fs, r0, v0, a0, rcs);
[noNoiseSig] = generator.perform();

rdpEstimator = RdpEstimator(generator.mTr, generator.mTs, generator.mF0, ...
    generator.mNs, generator.mNc, generator.mGamma);
[~, rdpMap, ~] = rdpEstimator.perform(noNoiseSig);
[~, ind] = max(rdpMap(:));
[rdpIv, rdpIr] = ind2sub(size(rdpMap), ind);
mtdCutIdx = [rdpIv, rdpIr]';

vaitEstimator = VaitEstimator(generator.mTr, generator.mTs, generator.mF0, ...
    generator.mNs, generator.mNc, generator.mGamma);
[~, vaitMap, ~] = vaitEstimator.perform(noNoiseSig);
[~, ind] = max(vaitMap(:));
[vaitIv, vaitIr] = ind2sub(size(vaitMap), ind);
vaitCutIdx = [vaitIv, vaitIr]';

startVel = round(v0 / generator.mMaxVel / 2) * generator.mMaxVel * 2  - ...
    generator.mMaxVel;
endVel = startVel + generator.mMaxVel * 2;
rftEstimator = RftEstimator(generator.mTr, generator.mTs, generator.mF0, ...
    generator.mNs, generator.mNc, generator.mGamma, startVel, endVel);
[~, rftMap, ~] = rftEstimator.perform(noNoiseSig);
[~, ind] = max(rftMap(:));
[rftIv, rftIr] = ind2sub(size(rftMap), ind);
rftCutIdx = [rftIv, rftIr]';

%% Run the Monte Carlo simulation.
snrNum = length(snrList);
rdpDetProb = zeros(1, snrNum);
vaitDetProb = zeros(1, snrNum);
rftDetProb = zeros(1, snrNum);
lowSnrDetProb = zeros(1, snrNum);
highSnrDetProb = zeros(1, snrNum);
parfor i = 1 : snrNum
    i / snrNum
    inputSnr = snrList(i);
    generator = Generator(inputSnr, nc, bw, f0, tc, tr, fs, r0, v0, a0, rcs);
    alpha = db2pow(inputSnr) * sqrt(nc * generator.mNs);

    cfar2D = phased.CFARDetector2D('GuardBandSize', 4, 'TrainingBandSize', ...
        10, 'ProbabilityFalseAlarm', pfa);

    rftEstimator = RftEstimator(generator.mTr, generator.mTs, generator.mF0, ...
        generator.mNs, generator.mNc, generator.mGamma, startVel, endVel);
    rdpEstimator = RdpEstimator(generator.mTr, generator.mTs, generator.mF0, ...
        generator.mNs, generator.mNc, generator.mGamma);
    vaitEstimator = VaitEstimator(generator.mTr, generator.mTs, ...
        generator.mF0, generator.mNs, generator.mNc, generator.mGamma);

    lowSnrVar = 1;
    lowSnrDetProb(i) = 1 - integral(@(z) p(z, alpha, lowSnrVar), 0, thr);

    highSnrVar = 2 * alpha;
    highSnrDetProb(i) = 1 - integral(@(z) p(z, alpha, highSnrVar), 0, thr);

    rdpHypo = zeros(1, monNum);
    vaitHypo = zeros(1, monNum);
    rftHypo = zeros(1, monNum);
    for j = 1 : monNum
        [sig] = generator.perform();

        % RFT
        [rftEstimator, rftMap] = rftEstimator.perform(sig);
        rftHypo(j) = cfar2D(abs(rftMap).^2, rftCutIdx);

        % RDP
        [rdpEstimator, mtdMap] = rdpEstimator.perform(sig);
        rdpHypo(j) = cfar2D(abs(mtdMap).^2, mtdCutIdx);

        % VAIT
        [vaitEstimator, vaitMap] = vaitEstimator.perform(sig);
        vaitHypo(j) = cfar2D(abs(vaitMap).^2, vaitCutIdx);
    end

    rdpDetProb(i) = sum(rdpHypo) / monNum;
    vaitDetProb(i) = sum(vaitHypo) / monNum;
    rftDetProb(i) = sum(rftHypo) / monNum;
end

lowSnrDetProb(isnan(lowSnrDetProb)) = 1;
highSnrDetProb(isnan(highSnrDetProb)) = 1;
figure();
plot(snrList, lowSnrDetProb, 'DisplayName', 'Low');
hold on
plot(snrList, highSnrDetProb, 'DisplayName', 'High');
plot(snrList, rftDetProb, 'DisplayName', 'RFT');
plot(snrList, rdpDetProb, 'DisplayName', 'RDP');
plot(snrList, vaitDetProb, 'DisplayName', 'VAIT');
legend;