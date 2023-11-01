% Written by: Maozhong Fu (maozhongfu@gmail.com)
%
% Distributed under the LGPL3 License.
classdef RdpEstimator < Estimator
    methods
        % Initialize the corresponding parameters.
        function obj = RdpEstimator(tr, ts, f0, ns, nc, gamma)
            obj.mMaxVel = obj.mC / (4 * tr * f0);
            obj.mMaxRng = obj.mC / (2 * ts * gamma);
            obj.mDv = obj.mC / (2 * tr * nc * f0);
            obj.mDr = obj.mC / (2 * ts * ns * gamma);
            obj.mRng = unigrid(0, obj.mDr, obj.mMaxRng, '[)');
            obj.mVel = unigrid(-obj.mMaxVel, obj.mDv, obj.mMaxVel, '[)');
            [obj.mXAxis, obj.mYAxis] = meshgrid(obj.mRng, obj.mVel);
        end

        % Perform RDP on the given signal.
        function [obj, map, timeCost] = perform(obj, sig)
            startTime = clock; % start time

            map = fftshift(fft2(sig), 1);

            stopTime = clock; % stop time
            timeCost = etime(stopTime, startTime); % computational cost
            obj.mMap = map / max(map(:));
        end
    end
end
