% =========================================================================
% RIDGESEGMENT - הפרדת טביעת האצבע מהרקע (Segmentation)
% =========================================================================
% תפקיד הפונקציה בפועל:
% 1. נרמול התמונה: מאזנת את הבהירות והניגודיות כדי שהחישובים יהיו אחידים.
% 2. חישוב שונות (Variance): מחלקת את התמונה לבלוקים (למשל 16x16).
%    - אם השונות בבלוק גבוהה -> יש שם קווים (רכסים) -> זה חלק מהאצבע.
%    - אם השונות נמוכה -> האזור חלק -> זה רקע ריק.
% 3. יצירת מסכה (Mask): מחזירה מפה של 0 ו-1 שאומרת לנו איפה האצבע נמצאת.
%
% קלט: תמונה גולמית.
% פלט: תמונה מנורמלת + מסכה (Mask) שמחקה את הרקע המיותר.
% =========================================================================



function [normim, mask, maskind] = ridgesegment(im, blksze, thresh)
% RIDGESEGMENT - Normalises fingerprint image and segments ridge region
%
% Function identifies the ridge regions of a fingerprint image and returns a
% mask identifying this region.  It also normalises the intesity values of
% the image so that the ridge regions have zero mean, unit standard
% deviation.
%
% Usage: [normim, mask, maskind] = ridgesegment(im, blksze, thresh)
%
% Arguments:   im     - Fingerprint image to be segmented.
%              blksze - Block size for variance calculation (suggest 16).
%              thresh - Threshold for variance (suggest 0.1 - 0.2).

    im = double(im);
    [rows, cols] = size(im);  
    
    % Nomalise to have zero mean, unit std dev
    im = (im - mean(im(:))) / std(im(:));
    
    % Break into blocks, compute std dev of each block
    stddevim = zeros(rows,cols);
    
    for r = 1:blksze:rows-blksze+1
        for c = 1:blksze:cols-blksze+1
            block = im(r:r+blksze-1, c:c+blksze-1);
            stddevim(r:r+blksze-1, c:c+blksze-1) = std(block(:));
        end
    end
    
    % Threshold the std dev image to get the mask
    mask = stddevim > thresh;
    
    % Renormalise image so that the *ridge regions* have zero mean, unit
    % standard deviation.
    maskind = find(mask);
    im = (im - mean(im(maskind))) / std(im(maskind));
    
    normim = im;
end