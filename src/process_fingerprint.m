function [template, roiMask, rawMinutiae, descriptors] = process_fingerprint(img, do_viz)
    % process_fingerprint - גרסה משודרגת עם שיפור Gabor
    % קלט: תמונה גולמית (צבעונית או אפורה)
    % פלט: תבנית נקודות מסוננת, מסיכה, נקודות גולמיות, ודסקריפטורים
    
    if nargin < 2, do_viz = false; end
    cfg = get_config();
    
    % מבנה לדיבוג
    debug = struct();
    
    % 1. המרה לאפור ונרמול
    if size(img, 3) == 3, img = rgb2gray(img); end
    img = im2double(img);
    debug.imgGray = img;
    
    % --- שלב השיפור החדש (Gabor Enhancement) ---
    
    % 2. סגמנטציה (הפרדת האצבע מהרקע)
    [normim, mask, ~] = ridgesegment(img, cfg.gabor.blk_sze, cfg.gabor.thresh);
    roiMask = mask; % שומרים את המסיכה המדויקת שחושבה כאן
    debug.roiMask = roiMask;
    
    % 3. חישוב כיוונים (Orientation Map)
    orientim = ridgeorient(normim, cfg.gabor.grad_sigma, cfg.gabor.block_sigma, cfg.gabor.smooth_sigma);
    
    % 4. חישוב תדרים (Frequency Map)
    [freqim, ~] = ridgefreq(normim, mask, orientim, cfg.gabor.freq_blk, ...
                            cfg.gabor.freq_wind, cfg.gabor.min_wl, cfg.gabor.max_wl);
    
    % 5. שיפור תמונה (Gabor Filtering)
    % התמונה הזו חלקה וברורה הרבה יותר מהמקור
    enhancedImg = ridgefilter(normim, orientim, freqim, cfg.gabor.kx, cfg.gabor.ky, 0);
    
    % 6. בינאריזציה וניקוי
    % פלט גאבור הוא סביב ה-0. ערכים > 0 הם רכסים.
    binaryImg = enhancedImg > 0;
    binaryImg = binaryImg & roiMask; % חיתוך לפי המסיכה
    
    % ניקוי חורים קטנים שנוצרו (אופציונלי אך מומלץ)
    binaryImg = bwareaopen(binaryImg, 10);
    binaryImg = ~bwareaopen(~binaryImg, 10);
    
    debug.binaryMasked = binaryImg;
    
    % 7. יצירת שלד (Skeletonization)
    skeletonImg = bwmorph(binaryImg, 'thin', Inf);
    skeletonImg = bwmorph(skeletonImg, 'clean');
    skeletonImg = bwmorph(skeletonImg, 'diag');
    skeletonImg = bwmorph(skeletonImg, 'spur', 5); 
    
    debug.skeletonImg = skeletonImg;
    
    % --- שלב חילוץ המאפיינים (כמו בקוד הקודם) ---
    
    % 8. חילוץ נקודות (Minutiae) מהשלד הנקי
    rawMinutiae = extract_minutiae_features(skeletonImg, cfg);
    debug.rawMinutiae = rawMinutiae;
    
    % 9. סינון סופי (שוליים, צפיפות, מבנה)
    template = filter_minutiae(rawMinutiae, roiMask, cfg);
    debug.finalTemplate = template;
    
    % 10. חישוב מתארים (Descriptors)
    descriptors = compute_descriptors(template, cfg);
    
    % --- ויזואליזציה ---
    if do_viz
        visualize_pipeline(debug, cfg);
    end
end