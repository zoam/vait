% Written by: Maozhong Fu (maozhongfu@gmail.com)
%
% Distributed under the LGPL3 License.
classdef RftEstimator < Estimator

    properties
        mNc; % chirp number
        mNs; % sample number
        mTs; % sample interval
        mGamma; % sweep slope
        mF0; % ramp start frequency
        mTr; % chirp repeating interval
        mNv;
        mStartVel;
    end

    methods
        % Initialize the corresponding parameters.
        function obj = RftEstimator(tr, ts, f0, ns, nc, gamma, startVel, endVel)
            obj.mMaxVel = obj.mC / (4 * tr * f0);
            obj.mMaxRng = obj.mC / (2 * ts * gamma);
            obj.mDv = obj.mC / (2 * tr * nc * f0);
            obj.mDr = obj.mC / (2 * ts * ns * gamma);
            obj.mRng = unigrid(0, obj.mDr, obj.mMaxRng, '[)');
            obj.mNc = nc;
            obj.mNs = ns;
            obj.mTs = ts;
            obj.mGamma = gamma;
            obj.mF0 = f0;
            obj.mTr = tr;
            obj.mStartVel = startVel;
            obj.mNv = round((endVel - startVel) / obj.mDv);
            obj.mVel = startVel + unigrid(0, obj.mDv, obj.mNv * obj.mDv, '[)');
            [obj.mXAxis, obj.mYAxis] = meshgrid(obj.mRng, obj.mVel);
        end

        % Perform RFT on the given signal.
        function [obj, map, timeCost] = perform(obj, sig)
            startTime = clock; % start time

            map = rft(sig, obj.mNc, obj.mNs, obj.mTs * obj.mGamma, obj.mF0, ...
                obj.mTr, obj.mDv, obj.mStartVel, obj.mNv, obj.mC);

            stopTime = clock; % stop time
            timeCost = etime(stopTime, startTime); % computational cost
            obj.mMap = map / max(map(:));
        end

    end
end
