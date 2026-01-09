function [template, roiMask, rawMinutiae, descriptors] = process_fingerprint(img, do_viz)
    % process_fingerprint - גרסה עם חיתוך חכם (Smart Crop)
    
    if nargin < 2, do_viz = false; end
    cfg = get_config();
    debug = struct();
    
    % 1. המרה לאפור ונרמול ראשוני
    if size(img, 3) == 3, img = rgb2gray(img); end
    img = im2double(img);
    
    % שיפור ניגודיות ראשוני (CLAHE) עוזר מאוד לזיהוי המסיכה
    img = adapthisteq(img, 'ClipLimit', 0.02);
    
    % --- שלב החיתוך החכם (Smart Crop) ---
    
    % א. חישוב מסיכה גסה על התמונה המלאה
    fullMask = get_roi_mask(img);
    
    % ב. מציאת גבולות המסיכה (Bounding Box)
    [r, c] = find(fullMask);
    if isempty(r)
        % מקרה חירום: לא נמצאה אצבע, משתמשים בכל התמונה
        r1=1; r2=size(img,1); c1=1; c2=size(img,2);
    else
        % הוספת ריפוד (Padding) של 15 פיקסלים כדי לא לחתוך את הגבול
        padding = 15;
        r1 = max(1, min(r) - padding);
        r2 = min(size(img,1), max(r) + padding);
        c1 = max(1, min(c) - padding);
        c2 = min(size(img,2), max(c) + padding);
    end
    
    % ג. חיתוך התמונה והמסיכה לאזור הרלוונטי בלבד
    img = img(r1:r2, c1:c2);
    roiMask = fullMask(r1:r2, c1:c2);
    
    debug.imgGray = img;
    debug.roiMask = roiMask;
    
    % -------------------------------------
    
    % 2. סגמנטציה וניקוי
    % כעת אנו שולחים ל-ridgesegment את התמונה החתוכה
    [normim, ~, ~] = ridgesegment(img, cfg.gabor.blk_sze, cfg.gabor.thresh);
    
    % 3. חישוב כיוונים (Orientation Map)
    orientim = ridgeorient(normim, cfg.gabor.grad_sigma, cfg.gabor.block_sigma, cfg.gabor.smooth_sigma);
    
    % 4. חישוב תדרים (Frequency Map)
    [freqim, ~] = ridgefreq(normim, roiMask, orientim, cfg.gabor.freq_blk, ...
                            cfg.gabor.freq_wind, cfg.gabor.min_wl, cfg.gabor.max_wl);
    
    % 5. שיפור תמונה (Gabor Filtering)
    % שימוש בפונקציית הפילטר המהירה שלך
    enhancedImg = ridgefilter(normim, orientim, freqim, cfg.gabor.kx, cfg.gabor.ky, 0);
    
    % 6. בינאריזציה
    % כאן אנו משתמשים במסיכה החתוכה והמורחבת שיצרנו בהתחלה
    binaryImg = enhancedImg > 0;
    binaryImg = binaryImg & roiMask; 
    
    % ניקוי חורים קטנים
    binaryImg = bwareaopen(binaryImg, 10);
    binaryImg = ~bwareaopen(~binaryImg, 10);
    
    debug.binaryMasked = binaryImg;
    
    % 7. יצירת שלד (Skeletonization)
    skeletonImg = bwmorph(binaryImg, 'thin', Inf);
    skeletonImg = bwmorph(skeletonImg, 'clean');
    skeletonImg = bwmorph(skeletonImg, 'diag');
    skeletonImg = bwmorph(skeletonImg, 'spur', 5); 
    
    debug.skeletonImg = skeletonImg;
    
    % 8. חילוץ נקודות
    rawMinutiae = extract_minutiae_features(skeletonImg, cfg);
    debug.rawMinutiae = rawMinutiae;
    
    % 9. סינון סופי
    template = filter_minutiae(rawMinutiae, roiMask, cfg);
    debug.finalTemplate = template;
    
    % 10. דסקריפטורים
    descriptors = compute_descriptors(template, cfg);
    
    % --- ויזואליזציה ---
    if do_viz
        visualize_pipeline(debug, cfg);
    end
end