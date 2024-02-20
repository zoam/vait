classdef VaitEstimator < Estimator

    methods
        % Initialize the corresponding parameters.
        function obj = VaitEstimator(tr, ts, f1, ns, nc, gamma)
            obj.mMaxVel = obj.mC / (8 * tr * f1);
            obj.mMaxRng = obj.mC / (4 * ts * gamma);
            obj.mDv = obj.mC / (4 * tr * nc * f1);
            obj.mDr = obj.mC / (4 * ts * ns * gamma);
            obj.mRng = unigrid(0, obj.mDr, obj.mMaxRng, '[)');
            obj.mVel = unigrid(-obj.mMaxVel, obj.mDv, obj.mMaxVel, '[)');
            [obj.mXAxis, obj.mYAxis] = meshgrid(obj.mRng, obj.mVel);
        end

        % Perform VAIT on the given signal.
        function [obj, map, timeCost] = perform(obj, sig)

            startTime = clock; % start time

            y = sig .* conj(flip(flip(sig), 2));
            map = fftshift(fft(fft(y, [], 1), [], 2), 1);

            stopTime = clock; % stop time
            timeCost = etime(stopTime, startTime); % computational cost
            obj.mMap = map / max(map(:));
        end
    end
end
