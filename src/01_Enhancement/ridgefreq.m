% =========================================================================
% RIDGEFREQ - חישוב תדירות הרכסים (Ridge Frequency)
% =========================================================================
% תפקיד הפונקציה בפועל:
% הפונקציה מודדת כמה "צפופים" הקווים בטביעת האצבע.
% היא לוקחת בלוקים מהתמונה, מסובבת אותם כך שהקווים יהיו אנכיים,
% ואז סופרת כמה פיקסלים יש בין פס שחור אחד לשני (אורך גל).
%
% למה זה קריטי?
% כדי שמסנן גאבור יידע איזה "רוחב" של מכחול הוא צריך כדי לצייר מחדש את הקווים.
% אם המסנן יהיה רחב מדי - הוא יחבר שני קווים סמוכים.
% אם הוא יהיה צר מדי - הוא לא יצליח לסגור חורים בתוך הקו.
%
% קלט: תמונה, מסכה, ומפת כיוונים.
% פלט: מפה של תדרים (1 חלקי המרחק בין הרכסים).
% =========================================================================



function [freqim, medianfreq] = ridgefreq(im, mask, orientim, blksze, windsze, ...
                                             minWaveLength, maxWaveLength)
% RIDGEFREQ - Estimates the local ridge frequency across a fingerprint
%
% Usage: [freqim, medianfreq] = ridgefreq(im, mask, orientim, blksze, windsze, ...
%                                         minWaveLength, maxWaveLength)
%
% Arguments:  im       - Image to be processed.
%             mask     - Mask defining ridge regions.
%             orientim - Ridge orientation image.
%             blksze   - Size of image block to use (say 32).
%             windsze  - Window length used to identify peaks (say 5).
%             minWaveLength,  maxWaveLength - Minimum and maximum ridge
%                             wavelengths, in pixels (say 5 and 15).
%
% Returns:    freqim     - An image  the same size as im with  values set to
%                          the estimated ridge spatial frequency.
%             medianfreq - Median frequency value evaluated across the
%                          fingerprint.

    [rows, cols] = size(im);
    freqim = zeros(rows, cols);
    
    for r = 1:blksze:rows-blksze+1
        for c = 1:blksze:cols-blksze+1
            blkim = im(r:r+blksze-1, c:c+blksze-1);
            blkor = orientim(r:r+blksze-1, c:c+blksze-1);
            
            freq = freqest(blkim, blkor, windsze, minWaveLength, maxWaveLength);
            freqim(r:r+blksze-1, c:c+blksze-1) = freq;
        end
    end
    
    % Mask out frequencies calculated for non-ridge regions
    freqim = freqim .* mask;
    
    % Generate median frequency
    medianfreq = median(freqim(freqim > 0));
end

% פונקציית עזר פנימית לחישוב תדר בבלוק בודד
function freq = freqest(im, orientim, windsze, minWaveLength, maxWaveLength)
    [rows, cols] = size(im);
    
    % Find mean orientation within the block
    cosorient = mean(cos(2*orientim(:)));
    sinorient = mean(sin(2*orientim(:)));
    orient = atan2(sinorient, cosorient)/2;
    
    % Rotate the image block so that the ridges are vertical
    rotim = imrotate(im, orient/pi*180 + 90, 'bicubic', 'crop');
    
    % Sum down the columns to get a projection of the grey values
    proj = sum(rotim);
    
    % Find peaks in projected grey values
    dilation = ordfilt2(proj, windsze, ones(1,windsze));
    maxpts = (dilation == proj) & (proj > mean(proj));
    maxind = find(maxpts);
    
    % Determine spatial frequency of ridges
    if length(maxind) < 2
        freq = 0;
    else
        NoOfPeaks = length(maxind);
        waveLength = (maxind(end) - maxind(1)) / (NoOfPeaks - 1);
        if waveLength >= minWaveLength && waveLength <= maxWaveLength
            freq = 1/waveLength;
        else
            freq = 0;
        end
    end
end