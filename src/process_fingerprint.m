function [template, roiMask, rawMinutiae, descriptors] = process_fingerprint(img, do_viz)
    % process_fingerprint - גרסה עם חילוץ מונחה מסיכה
    
    if nargin < 2, do_viz = false; end
    cfg = get_config();
    debug = struct();
    
    % 1. המרה לאפור ונרמול ראשוני
    if size(img, 3) == 3, img = rgb2gray(img); end
    img = im2double(img);
    img = adapthisteq(img, 'ClipLimit', 0.02);
    
    % --- שלב החיתוך החכם ---
    fullMask = get_roi_mask(img);
    [r, c] = find(fullMask);
    if isempty(r)
        r1=1; r2=size(img,1); c1=1; c2=size(img,2);
    else
        padding = 15;
        r1 = max(1, min(r) - padding);
        r2 = min(size(img,1), max(r) + padding);
        c1 = max(1, min(c) - padding);
        c2 = min(size(img,2), max(c) + padding);
    end
    
    img = img(r1:r2, c1:c2);
    roiMask = fullMask(r1:r2, c1:c2);
    
    debug.imgGray = img;
    debug.roiMask = roiMask;
    
    % 2-7. עיבוד תמונה (Gabor, בינאריזציה ושלד)
    [normim, ~, ~] = ridgesegment(img, cfg.gabor.blk_sze, cfg.gabor.thresh);
    orientim = ridgeorient(normim, cfg.gabor.grad_sigma, cfg.gabor.block_sigma, cfg.gabor.smooth_sigma);
    [freqim, ~] = ridgefreq(normim, roiMask, orientim, cfg.gabor.freq_blk, ...
                            cfg.gabor.freq_wind, cfg.gabor.min_wl, cfg.gabor.max_wl);
    
    enhancedImg = ridgefilter(normim, orientim, freqim, cfg.gabor.kx, cfg.gabor.ky, 0);
    
    binaryImg = enhancedImg > 0;
    binaryImg = binaryImg & roiMask; 
    binaryImg = bwareaopen(binaryImg, 10);
    binaryImg = ~bwareaopen(~binaryImg, 10);
    
    debug.binaryMasked = binaryImg;
    
    skeletonImg = bwmorph(binaryImg, 'thin', Inf);
    skeletonImg = bwmorph(skeletonImg, 'clean');
    skeletonImg = bwmorph(skeletonImg, 'diag');
    skeletonImg = bwmorph(skeletonImg, 'spur', 5); 
    
    debug.skeletonImg = skeletonImg;
    
    % --- שלב התיקון: יצירת מסיכה קפדנית לפני החילוץ ---
    % אנו מכווצים את המסיכה ב-12 פיקסלים כדי לזרוק את הקצוות הרועשים
   % --- שלב התיקון: יצירת מסיכה קפדנית לפני החילוץ ---
   % שימוש בערך מהקונפיגורציה
   erosionVal = 12; % ברירת מחדל
   if isfield(cfg.roi, 'strict_erosion')
       erosionVal = cfg.roi.strict_erosion;
   end
   seStrict = strel('disk', erosionVal);
    strictMask = imerode(roiMask, seStrict);
    
    % 8. חילוץ נקודות - שולחים את המסיכה הקפדנית!
    % הנקודות שיוחזרו מכאן כבר יהיו מסוננות ראשונית
    rawMinutiae = extract_minutiae_features(skeletonImg, strictMask, cfg);
    debug.rawMinutiae = rawMinutiae;
    
    % 9. סינון סופי ומתקדם (בודק גם גיאומטריה וגם גבול וירטואלי נוסף ליתר ביטחון)
    template = filter_minutiae(rawMinutiae, strictMask, cfg);
    debug.finalTemplate = template;
    
    % 10. דסקריפטורים
    descriptors = compute_descriptors(template, cfg);
    
    % --- ויזואליזציה ---
    if do_viz
        visualize_pipeline(debug, cfg);
    end
end