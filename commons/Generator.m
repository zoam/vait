classdef Generator
    properties(Constant)
        mC = 299792458; % the speed of light
    end

    properties
        mF0; % the ramp start frequency
        mBw; % the sweep bandwidth
        mFs; % the sampling frequency
        mTs; % the sampling interval
        mLambda; % the wavelength
        mFr; % the chirp repeating frequency
        mTc; % the chirp length
        mNs; % the sample number
        mNc; % the number of chirps in a coherent processing interval
        mTr; % the chirp repeating interval
        mMaxRng; % the maximum unambiguous range [0, mMaxRng)
        mMaxVel; % the maximum unambiguous velocity [-mMaxVel, mMaxVel)
        mDr; % the range resolution
        mDv; % the velocity resolution
        mFastTime; % the fast-time
        mSlowTime; % the slow-time
        mFullTime; % the full-time
        mGamma; % the sweep slope
        mR0; % the range between the targets and the radar
        mV0; % the velocity between the targets and the radar
        mA0; % the acceleration between the targets and the radar
        mRcs; % the radar cross section of the targets
        mTgtNum; % the number of the targets
        mSnr; % the signal-to-noise ratio
        mRng; % the range axis of the range-velocity map
        mVel; % the velocity axis of the range-velocity map
        mTxSig; % the transmitted signal
        mTauRm; % the trimmed time length
        mF1;
        mT0;
    end

    methods
        function obj = Generator(snr, nc, bw, f0, tc, tr, fs, r0, v0, a0, rcs)
            obj.mSnr = snr;
            obj.mNc = nc;
            obj.mBw = bw;
            obj.mF0 = f0;
            obj.mTc = tc;
            obj.mTr = tr;
            obj.mFs = fs;
            obj.mR0 = r0;
            obj.mV0 = v0;
            obj.mA0 = a0;
            obj.mRcs = rcs;

            [obj] = obj.calculateOtherParameters();
            rng(2026); % Setting up the noise seed.
        end

        function obj = calculateOtherParameters(obj)
            obj.mTauRm = obj.mTr - obj.mTc;
            obj.mFr = 1 / obj.mTr;
            obj.mGamma = obj.mBw / obj.mTc;
            
            obj.mNs = round(obj.mFs * (obj.mTr - 2 * obj.mTauRm));
            obj.mTs = 1 / obj.mFs;
            obj.mT0 = obj.mNs / 2 * obj.mTs;
            obj.mF0 = obj.mF0;
%             obj.mF1 = obj.mF0 + obj.mGamma * (obj.mT0 + obj.mTauRm);
            obj.mF1 = obj.mF0 + obj.mGamma * (obj.mT0 + obj.mTauRm) - ...
                obj.mGamma * (obj.mR0(1)) * 2 / obj.mC;
            obj.mLambda = obj.mC / obj.mF1;
            obj.mMaxVel = obj.mC / (4 * obj.mTr * obj.mF1); 
            obj.mMaxRng = obj.mC / (2 * obj.mTs * obj.mGamma);
            obj.mDv = obj.mC / (2 * obj.mTr * obj.mNc * obj.mF1);
            obj.mDr = obj.mC / (2 * obj.mTs * obj.mNs * obj.mGamma);
            obj.mRng = unigrid(0, obj.mDr, obj.mMaxRng, '[)');
            obj.mVel = unigrid(-obj.mMaxVel, obj.mDv, obj.mMaxVel, '[)');
            obj.mFastTime = (0 : obj.mNs - 1) * obj.mTs + obj.mTauRm; 
            obj.mSlowTime = ((0 : obj.mNc - 1).' - obj.mNc / 2) * obj.mTr;
            obj.mFullTime = obj.mSlowTime * ones(1, obj.mNs) + ...
                ones(obj.mNc, 1) * obj.mFastTime;
            obj.mTxSig = exp(1i * pi * obj.mGamma * obj.mFastTime.^2) .* ...
                exp(1i * 2 * pi * obj.mF0 * obj.mFastTime);
            obj.mTgtNum = length(obj.mRcs);
        end

        function [outputSig] = perform(obj)
            sumSig = zeros(obj.mNc, obj.mNs);
            for i = 1 : obj.mTgtNum
                time = obj.mFullTime - obj.mT0 - obj.mTauRm;
                distance = obj.mR0(i) + time * obj.mV0(i) + ...
                    0.5 * time.^2 * obj.mA0(i);
                
                tau = 2 * distance / obj.mC;
                rxSig = obj.mRcs(i) * ...
                    exp(1i * pi * obj.mGamma * (obj.mFastTime - tau).^2) .* ...
                    exp(1i * 2 * pi * obj.mF0 * (obj.mFastTime - tau));
                beatSig = obj.mTxSig .* conj(rxSig);

%                 beatSig = obj.mRcs(i) * exp(1i * 4 * pi /obj.mC * obj.mF1 * ((0 : obj.mNc - 1).'-obj.mNc/2) * obj.mTr * obj.mV0(i)) * ...
%                     (exp(1i * 4 * pi /obj.mC  * obj.mGamma * ((0 : obj.mNs - 1)-obj.mNs/2) * obj.mTs * obj.mR0(i)) .* ...
%                     exp(1i * 4 * pi /obj.mC  * obj.mF1 * ((0 : obj.mNs - 1)-obj.mNs/2) * obj.mTs * obj.mV0(i)));
            
                sumSig = sumSig + beatSig;
            end

            [outputSig] = obj.addNoise(sumSig, obj.mSnr);
        end

        function [outputSig] = addNoise(~, inputSig, snr)
            noise = wgn(size(inputSig, 1), size(inputSig, 2), 0, 'complex');
            if isinf(snr)
                outputSig = inputSig;
            else
                outputSig = 1 * inputSig * db2mag(snr) + 1 * noise;
            end
        end

        function [obj] = resetSnr(obj, snr)
            obj.mSnr = snr;
        end
    end
end
