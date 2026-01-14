function [normim, mask, maskind] = ridgesegment(im, blksze, thresh)
% RIDGESEGMENT - גרסה מתוקנת (ללא חיתוך מימדים)
% מבצעת סגמנטציה ונרמול, אך שומרת על גודל התמונה המקורי
% כדי למנוע קריסות של אי-תאימות בגדלים (Incompatible sizes).

    im = double(im);
    [rows, cols] = size(im);  
    
    % 1. נרמול ראשוני
    im = (im - mean(im(:))) / std(im(:));
    
    % --- אופטימיזציה למהירות: חישוב שונות בבלוקים ---
    
    % חישוב ריפוד (Padding)
    pad_r = ceil(rows/blksze)*blksze - rows;
    pad_c = ceil(cols/blksze)*blksze - cols;
    
    % ריפוד התמונה
    im_padded = padarray(im, [pad_r, pad_c], 0, 'post');
    [rows_pad, cols_pad] = size(im_padded);
    
    % המרת הבלוקים לעמודות
    B = im2col(im_padded, [blksze blksze], 'distinct');
    
    % חישוב סטיית תקן לכל בלוק
    std_vals = std(B);
    
    % המרת התוצאה למסיכה
    mask_small = reshape(std_vals, [rows_pad/blksze, cols_pad/blksze]) > thresh;
    
    % הגדלת המסיכה חזרה לגודל התמונה המקורית
    mask = kron(mask_small, ones(blksze));
    
    % חיתוך הריפוד המיותר (חזרה לגודל המקורי)
    mask = mask(1:rows, 1:cols);
    
    % --- ניקוי מורפולוגי ---
    mask = imfill(mask, 'holes');        
    mask = bwareaopen(mask, 100);        
    
    % חיבור שברים
    se = strel('square', 3);
    mask = imclose(mask, se);

    % --- שינוי קריטי: ביטול החיתוך (Cropping) ---
    % הקוד שהיה כאן וחתך את התמונה (im(r1:r2...)) נמחק.
    % כעת normim נשארת באותו גודל כמו im המקורית.
    
    normim = im;
    
    % נרמול סופי מבוסס רק על אזור האצבע
    maskind = find(mask);
    if ~isempty(maskind)
        meanVal = mean(normim(maskind));
        stdVal = std(normim(maskind));
        
        % הגנה מפני חלוקה באפס (אם הסטייה היא 0)
        if stdVal > 0
            normim = (normim - meanVal) / stdVal;
        else
            normim = normim - meanVal;
        end
    else
        % אם המסיכה יצאה ריקה (בגלל סף גבוה מדי)
        normim = zeros(size(im));
    end
end