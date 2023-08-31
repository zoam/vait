classdef MvaitEstimator < Estimator
    properties
        mKappa; % phase correction term
        mEta; % phase correction term
        mNs;
        mNc;
        mGamma;
        mTs;
        mF0;
        mTr;
        mRngProfile;
    end

    methods
        function obj = MvaitEstimator(tr, ts, f0, ns, nc, gamma)
            obj.mMaxVel = obj.mC / (8 * tr * f0);
            obj.mMaxRng = obj.mC / (4 * ts * gamma);
            obj.mDv = obj.mC / (4 * tr * nc * f0);
            obj.mDr = obj.mC / (4 * ts * ns * gamma);
            obj.mRng = unigrid(0, obj.mDr, obj.mMaxRng, '[)');
            obj.mVel = unigrid(-obj.mMaxVel, obj.mDv, obj.mMaxVel, '[)');
            [obj.mXAxis, obj.mYAxis] = meshgrid(obj.mRng, obj.mVel);
            obj.mKappa = exp(-1i * 8 * pi / obj.mC * f0 * ...
                ((0 : nc - 1).' * obj.mDv) * (0 : ns - 1) * ts);
            obj.mEta = exp(-1i * 4 * pi / obj.mC * f0 * ...
                ((0 : nc - 1).' * obj.mDv) * (0 : ns - 1) * ts);
            obj.mNc = nc;
            obj.mNs = ns;
            obj.mGamma = gamma;
            obj.mTs = ts;
            obj.mF0 = f0;
            obj.mTr = tr;
        end

        function [obj, map, timeCost] = perform(obj, sig)

            startTime = clock; % start time

            h = rft(sig, obj.mNc, obj.mNs, obj.mTs * obj.mGamma, obj.mF0, ...
                obj.mTr, obj.mDv * 2, -2 * obj.mMaxVel, obj.mNc, obj.mC);

            y = ifft(h, [], 2) .* obj.mEta;

            h = ifft(fft(y, obj.mNs * 2, 2), [], 1);

            obj.mRngProfile = h / max(h(:));

            map = zeros(obj.mNc, obj.mNs);

            for i = 1 : obj.mNs

                hi = zeros(obj.mNc, obj.mNs);
                hi(: , i) = h(: , i);
                xi = ifft(hi, [], 2);

                yi = fftshift(fft2(xi .* conj(flip(flip(xi, 1), 2))), 1);

                map(: , i) = yi(: , mod(2 * (i - 1), obj.mNs) + 1);
            end

            stopTime = clock; % stop time
            timeCost = etime(stopTime, startTime); % computational cost
            obj.mMap = map / abs(max(map(:)));
        end
    end
end
