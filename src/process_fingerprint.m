function [template, roiMask, rawMinutiae, descriptors] = process_fingerprint(img, do_viz)
    % process_fingerprint - לוגיקה ראשית (Ultra-Lite) עם אופציה לוויזואליזציה
    % קלט:
    %   img - התמונה
    %   do_viz - (אופציונלי) בוליאני, true כדי לפתוח חלון גרפים. ברירת מחדל: false.
    
    if nargin < 2
        do_viz = false;
    end

    cfg = get_config();
    
    % מבנה נתונים לאגירת מידע לתצוגה (אם נדרש)
    debug = struct();
    
    % 1. המרה לאפור ונרמול
    if size(img, 3) == 3, img = rgb2gray(img); end
    img = im2double(img);
    debug.imgGray = img; % שמירת תמונת המקור לאפור לתצוגה
    
    % 2. חישוב מסיכה (ROI)
    roiMask = get_roi_mask(img);
    debug.roiMask = roiMask;
    
    % 3. בינאריזציה ישירה (Ultra-Lite)
    binaryImg = img < 0.5; 
    
    % 4. ניקוי בסיסי
    binaryImg = bwareaopen(binaryImg, 3);
    debug.binaryRaw = binaryImg; % לפני חיתוך ROI
    
    % חיתוך לפי המסיכה
    binaryImg = binaryImg & roiMask;
    debug.binaryMasked = binaryImg;
    
    % 5. יצירת שלד (Skeletonization)
    skeletonImg = bwmorph(binaryImg, 'thin', Inf);
    
    % ניקוי השלד
    skeletonImg = bwmorph(skeletonImg, 'clean');
    skeletonImg = bwmorph(skeletonImg, 'diag');
    % בגרסת Ultra-Lite אין Spur כדי לשמור על דיוק
    
    debug.skeletonImg = skeletonImg;
    
    % 6. חילוץ נקודות
    rawMinutiae = extract_minutiae_features(skeletonImg, cfg);
    debug.rawMinutiae = rawMinutiae;
    
    % 7. סינון סופי
    template = filter_minutiae(rawMinutiae, roiMask, cfg);
    debug.finalTemplate = template;
    
    % 8. חישוב מתארים
    descriptors = compute_descriptors(template, cfg);
    
    % === קריאה לוויזואליזציה אם נדרש ===
    if do_viz
        % בניית מבנה הנתונים לתצוגה
        debug.imgGray = img;
        debug.roiMask = roiMask;
        debug.binaryMasked = binaryImg;
        debug.skeletonImg = skeletonImg;
        debug.rawMinutiae = rawMinutiae;
        debug.finalTemplate = template;
        
        % שליחה לפונקציית התצוגה
        visualize_pipeline(debug, cfg);
    end
end