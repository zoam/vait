clear all;
close all;
clc;

addpath("../commons");

%% Set up simulation parameters.
snrStart = -30;
snrStep = 1;
snrEnd = max(0, snrStart);
snrList = snrStart : snrStep : snrEnd;
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
pfa = 1e-9;
thr = sqrt(-2 * log(pfa));
monNum = 1000;

p = @(z, a, var) (z ./ var .* exp(-1 * (z.^2 + a^2) / 2 / var) .* ...
    besseli(0, z * a / var));

generator = Generator(Inf, nc, bw, f0, tc, tr, fs, r0, v0, a0, rcs);

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

    cfar2D = phased.CFARDetector2D('GuardBandSize', 3, 'TrainingBandSize', ...
        6, 'ProbabilityFalseAlarm', pfa);

    rftEstimator = RftEstimator(generator.mTr, generator.mTs, generator.mF1, ...
        generator.mNs, generator.mNc, generator.mGamma, startVel, endVel);
    rdpEstimator = RdpEstimator(generator.mTr, generator.mTs, generator.mF1, ...
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
        rdpHypo(j) = cfar2D(abs(mtdMap).^2, rdpCutIdx);

        % VAIT
        [vaitEstimator, vaitMap] = vaitEstimator.perform(sig);
        vaitHypo(j) = cfar2D(abs(vaitMap).^2, vaitCutIdx);
    end

    rdpDetProb(i) = sum(rdpHypo) / monNum;
    vaitDetProb(i) = sum(vaitHypo) / monNum;
    rftDetProb(i) = sum(rftHypo) / monNum;
end

%% Show the simulations results.
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
