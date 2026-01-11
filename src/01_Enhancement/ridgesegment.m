function [normim, mask, maskind] = ridgesegment(im, blksze, thresh)
% RIDGESEGMENT - גרסה מואצת (Vectorized Block Processing)
% מבצעת סגמנטציה מבוססת בלוקים (כמו במקור) אך ללא לולאות איטיות.
% כוללת שיפורי דיוק מורפולוגיים.

    im = double(im);
    [rows, cols] = size(im);  
    
    % 1. נרמול ראשוני
    im = (im - mean(im(:))) / std(im(:));
    
    % --- אופטימיזציה למהירות: חישוב שונות בבלוקים ללא לולאות ---
    
    % חישוב ריפוד (Padding) כדי שהתמונה תתחלק בדיוק בגודל הבלוק
    pad_r = ceil(rows/blksze)*blksze - rows;
    pad_c = ceil(cols/blksze)*blksze - cols;
    
    % ריפוד התמונה (תוספת אפסים בצדדים כדי לא לאבד מידע בקצה)
    im_padded = padarray(im, [pad_r, pad_c], 0, 'post');
    [rows_pad, cols_pad] = size(im_padded);
    
    % הטריק הוקטורי: המרת כל הבלוקים לעמודות במטריצה אחת.
    % הפקודה im2col עם 'distinct' לוקחת כל בלוק והופכת אותו לעמודה.
    B = im2col(im_padded, [blksze blksze], 'distinct');
    
    % כעת פקודת std אחת מחשבת את הסטייה לכל הבלוקים בבת אחת!
    std_vals = std(B);
    
    % המרת התוצאה (וקטור שורה) חזרה למטריצה של בלוקים קטנים
    mask_small = reshape(std_vals, [rows_pad/blksze, cols_pad/blksze]) > thresh;
    
    % הגדלת המסיכה הקטנה חזרה לגודל התמונה המקורית
    % (כל פיקסל בתמונה מקבל את הערך של הבלוק שלו)
    mask = kron(mask_small, ones(blksze));
    
    % חיתוך הריפוד המיותר שהוספנו בהתחלה
    mask = mask(1:rows, 1:cols);
    
    % --- אופטימיזציה לדיוק: ניקוי מורפולוגי ---
    % (מונע "רעש" של קוביות בודדות וסוגר חורים בתוך האצבע)
    
    mask = imfill(mask, 'holes');        % מילוי חורים שחורים בתוך האצבע
    mask = bwareaopen(mask, 100);        % מחיקת "איים" קטנים של רעש רקע
    
    % חיבור שברים קרובים (חשוב אם האצבע יבשה)
    se = strel('square', 3);
    mask = imclose(mask, se);

    % --- חיתוך וטיפול סופי (כמו בקוד המקורי) ---
    [r, c] = find(mask);
    if ~isempty(r)
        % הוספת שוליים קטנים (Padding) של 2 פיקסלים
        r1 = max(1, min(r) - 2); 
        r2 = min(rows, max(r) + 2);
        c1 = max(1, min(c) - 2); 
        c2 = min(cols, max(c) + 2);
        
        normim = im(r1:r2, c1:c2);
        mask = mask(r1:r2, c1:c2);
    else
        normim = im;
    end
    
    % נרמול סופי מבוסס רק על אזור האצבע
    maskind = find(mask);
    if ~isempty(maskind)
        normim = (normim - mean(normim(maskind))) / std(normim(maskind));
    end
end