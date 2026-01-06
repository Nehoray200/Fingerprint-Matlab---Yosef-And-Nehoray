function [skeletonImg, binaryImg, enhancedImg] = process_fingerprint_gabor(img)
    % process_fingerprint_gabor - עיבוד מלא כולל שיפור גאבור
    % מחזיר את השלד, הבינארי והתמונה המשופרת
    
    cfg = get_config();
    
    % 1. המרה לאפור ונרמול
    if size(img, 3) == 3
        img = rgb2gray(img);
    end
    img = im2double(img);
    
    % 2. סגמנטציה
    [normim, mask, ~] = ridgesegment(img, cfg.gabor.blk_sze, cfg.gabor.thresh);
    
    % 3. חישוב כיוונים
    orientim = ridgeorient(normim, cfg.gabor.grad_sigma, cfg.gabor.block_sigma, cfg.gabor.smooth_sigma);
    
    % 4. חישוב תדרים
    [freqim, ~] = ridgefreq(normim, mask, orientim, cfg.gabor.freq_blk, ...
                            cfg.gabor.freq_wind, cfg.gabor.min_wl, cfg.gabor.max_wl);
    
    % 5. סינון גאבור (שיפור)
    enhancedImg = ridgefilter(normim, orientim, freqim, cfg.gabor.kx, cfg.gabor.ky, 0);
    
    % 6. בינאריזציה וניקוי
    % פלט גאבור הוא סביב ה-0. גדול מ-0 זה רכס (או להיפך, תלוי במימוש, כאן זה >0)
    binaryImg = enhancedImg > 0;
    binaryImg = binaryImg & mask; % חיתוך לפי המסכה המקורית
    
    % 7. יצירת שלד (Skeletonization)
    skeletonImg = bwmorph(binaryImg, 'thin', Inf);
    skeletonImg = bwmorph(skeletonImg, 'clean');
    skeletonImg = bwmorph(skeletonImg, 'diag');
    skeletonImg = bwmorph(skeletonImg, 'spur', 5); % ניקוי זיפים
    
    % היפוך צבעים (שחור על לבן) אם צריך, או השארת לוגי (1=רכס)
    % בד"כ בויזואליזציה רוצים שחור=רכס, אבל לאלגוריתם צריך 1=רכס.
    % כאן נחזיר 1=רכס. במידת הצורך נהפוך בסקריפט הראשי.
end