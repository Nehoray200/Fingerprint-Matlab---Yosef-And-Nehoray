% =========================================================================
% RIDGEORIENT - חישוב מפת כיוונים (Orientation Map)
% =========================================================================
% תפקיד הפונקציה בפועל:
% הפונקציה עוברת על כל נקודה בתמונה ומחשבת את ה"זווית" של הרכס באותו מקום.
% היא משתמשת בנגזרות (Gradients) כדי להבין לאן הקו "זורם".
%
% למה זה קריטי?
% מסנן גאבור (בשלב הבא) חייב לדעת את הזווית הזו כדי להחליק את התמונה
% *עם* כיוון הקו (כדי לחבר שברים) ולא *נגד* כיוון הקו (שזה ימרח אותו).
%
% קלט: תמונה מנורמלת (מ-ridgesegment).
% פלט: מטריצה באותו גודל כמו התמונה, המכילה זוויות (ברדיאנים) לכל פיקסל.
% =========================================================================



function [orientim] = ridgeorient(im, gradientsigma, blocksigma, orientsmoothsigma)
% RIDGEORIENT - Estimates the local orientation of ridges in a fingerprint
%
% Usage:  [orientim] = ridgeorient(im, gradientsigma, blocksigma, ...
%                                    orientsmoothsigma)
%
% Arguments:  im                - A normalised input image.
%             gradientsigma     - Sigma of the derivative of Gaussian
%                                 used to compute image gradients.
%             blocksigma        - Sigma of the Gaussian weighting used to
%                                 sum the gradient moments.
%             orientsmoothsigma - Sigma of the Gaussian used to smooth
%                                 the final orientation vector field.
% 
% Returns:    orientim          - The orientation image in radians.
%                                 Orientation values are between 0 and pi.

    [rows, cols] = size(im);
    
    % Calculate image gradients.
    sze = fix(6*gradientsigma);   if ~mod(sze,2); sze = sze+1; end
    f = fspecial('gaussian', sze, gradientsigma); % Generate Gaussian filter.
    [fx, fy] = gradient(f);                       % Gradient of Gausian.
    
    Gx = imfilter(im, fx, 'symmetric', 'conv');
    Gy = imfilter(im, fy, 'symmetric', 'conv');
    
    % Estimate the local ridge orientation at each point by finding the
    % principal axis of variation in the image gradients.
    Gxx = Gx.^2;       % Covariance data for the image gradients
    Gxy = Gx.*Gy;
    Gyy = Gy.^2;
    
    % Now smooth the covariance data to perform a weighted summation of the
    % data.
    sze = fix(6*blocksigma);   if ~mod(sze,2); sze = sze+1; end
    f = fspecial('gaussian', sze, blocksigma);
    Gxx = imfilter(Gxx, f, 'symmetric', 'conv');
    Gxy = 2*imfilter(Gxy, f, 'symmetric', 'conv');
    Gyy = imfilter(Gyy, f, 'symmetric', 'conv');
    
    % Analytic solution of principal direction
    denom = sqrt(Gxy.^2 + (Gxx - Gyy).^2) + eps;
    sin2theta = Gxy./denom;            % Sine and cosine of doubled angles
    cos2theta = (Gxx - Gyy)./denom;
    
    % Smooth the orientation vector field using a low pass filter
    if orientsmoothsigma
        sze = fix(6*orientsmoothsigma);   if ~mod(sze,2); sze = sze+1; end
        f = fspecial('gaussian', sze, orientsmoothsigma);
        cos2theta = imfilter(cos2theta, f, 'symmetric', 'conv');
        sin2theta = imfilter(sin2theta, f, 'symmetric', 'conv');
    end
    
    % Calculate the orientation angle
    orientim = pi/2 + atan2(sin2theta, cos2theta)/2;
end