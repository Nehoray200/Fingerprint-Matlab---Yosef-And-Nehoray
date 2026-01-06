function [normim, mask, maskind] = ridgesegment(im, blksze, thresh)
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

    
    im = double(im);
    [rows, cols] = size(im);  
    
    % 1. נרמול ראשוני
    im = (im - mean(im(:))) / std(im(:));
    
    % 2. חישוב שונות לכל בלוק (זיהוי אזורי האצבע)
    stddevim = zeros(rows,cols);
    for r = 1:blksze:rows-blksze+1
        for c = 1:blksze:cols-blksze+1
            block = im(r:r+blksze-1, c:c+blksze-1);
            stddevim(r:r+blksze-1, c:c+blksze-1) = std(block(:));
        end
    end
    
    % 3. יצירת מסיכה (1=אצבע, 0=רקע)
    mask = stddevim > thresh;
    
    % --- תוספת חדשה: חיתוך השוליים (Cropping) ---
    % אנו בודקים אלו שורות ועמודות מכילות מידע (1)
    rows_with_data = any(mask, 2);
    cols_with_data = any(mask, 1);
    
    % מציאת הגבולות (האינדקס הראשון והאחרון שיש בו אצבע)
    r1 = find(rows_with_data, 1, 'first');
    r2 = find(rows_with_data, 1, 'last');
    c1 = find(cols_with_data, 1, 'first');
    c2 = find(cols_with_data, 1, 'last');
    
    % ביצוע החיתוך בפועל (רק אם נמצא מידע)
    if ~isempty(r1) && ~isempty(c1)
        % הוספת "ריפוד" קטן של 2 פיקסלים שלא יהיה צפוף מדי (אופציונלי)
        padding = 2;
        r1 = max(1, r1 - padding); r2 = min(rows, r2 + padding);
        c1 = max(1, c1 - padding); c2 = min(cols, c2 + padding);
        
        % חיתוך התמונה והמסיכה
        im = im(r1:r2, c1:c2);
        mask = mask(r1:r2, c1:c2);
    end
    % ---------------------------------------------
    
    % 4. נרמול סופי (מבוסס רק על אזור האצבע החתוך)
    maskind = find(mask);
    if ~isempty(maskind)
        im = (im - mean(im(maskind))) / std(im(maskind));
    end
    
    normim = im;
end