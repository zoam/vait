% Written by: Maozhong Fu (maozhongfu@gmail.com)
%
% Distributed under the LGPL3 License.
classdef Estimator
    properties(Constant)
        mC = 299792458; % the speed of light
    end

    properties
        mMaxRng; % the maximum unambiguous range [0, mMaxRng)
        mMaxVel; % the maximum unambiguous velocity [-mMaxVel, mMaxVel)
        mDr; % the range resolution
        mDv; % the velocity resolution
        mRng; % the range axis of the range-velocity map
        mVel; % the velocity axis of the range-velocity map
        mMap; % the estimated range-velocity map
        mXAxis; % the x axis of the range-velocity map
        mYAxis; % the y axis of the range-velocity map
    end
    
    methods
        
        % Visualize the obtained range-velocity map.
        function [figInd] = visualize(obj, figInd)
            figInd = figInd + 1;
            
            figure(figInd);
            mesh(obj.mXAxis, obj.mYAxis, abs(obj.mMap));

            view([-50.4123968117417, 52.6153847430363]);

            opt.LegendBox = 'Off';
            opt.XGrid = 'On';
            opt.YGrid = 'On';
            opt.XLim = [obj.mRng(1), obj.mRng(end)];
            opt.YLim = [obj.mVel(1), obj.mVel(end)];
            opt.XLabel = 'Range (m)';
            opt.YLabel = 'Velocity (m/s)';
            opt.ZLabel = 'Amplitude';
            opt.BoxDim = [9, 6];
            opt.Dim = 3;
            opt.ColorBar = 0;
            setplot(opt);
        end
    end
end

