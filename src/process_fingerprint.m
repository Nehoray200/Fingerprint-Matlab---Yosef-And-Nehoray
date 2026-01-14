function [template, roiMask, rawMinutiae, descriptors, img, debug] = process_fingerprint(img, cfg, statusHandle)
    % process_fingerprint - המנוע הלוגי המרכזי (Unified Engine)
    % קלט:
    %   img - התמונה המקורית
    %   cfg - (אופציונלי) מבנה הגדרות. אם לא נשלח, יטען ברירת מחדל.
    %   statusHandle - (אופציונלי) פונקציה לעדכון סטטוס ב-GUI.
    % פלט:
    %   כל הנתונים הסופיים + debug struct שמכיל את תמונות הביניים.
    
    debug = struct();
    template = []; roiMask = []; rawMinutiae = []; descriptors = [];

    % 1. טיפול בארגומנטים חסרים
    if nargin < 2 || isempty(cfg) || islogical(cfg)
        % תמיכה לאחור: אם נשלח false/true או לא נשלח כלום, טען הגדרות
        cfg = get_config(); 
    end
    
    if nargin < 3
        statusHandle = @(x) []; % פונקציה ריקה אם לא נשלח ידית
    end

    try
        statusHandle('Step 1/7: Preprocessing...');
        
        % 2. המרה לאפור ונרמול
        if size(img, 3) == 3, img = rgb2gray(img); end
        img = im2double(img);
        img = adapthisteq(img, 'ClipLimit', 0.02);
        
        % 3. חיתוך ו-ROI (שימוש ב-cfg)
        fullMask = get_roi_mask(img, cfg);
        
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
        
        % שמירה לדיבאג
        debug.imgGray = img;
        debug.roiMask = roiMask;
        
        statusHandle('Step 2/7: Segmentation...');
        [normim, ~, ~] = ridgesegment(img, cfg.gabor.blk_sze, cfg.gabor.thresh);
        
        statusHandle('Step 3/7: Gabor Filtering...');
        orientim = ridgeorient(normim, cfg.gabor.grad_sigma, cfg.gabor.block_sigma, cfg.gabor.smooth_sigma);
        [freqim, ~] = ridgefreq(normim, roiMask, orientim, cfg.gabor.freq_blk, ...
                                cfg.gabor.freq_wind, cfg.gabor.min_wl, cfg.gabor.max_wl);
        
        enhancedImg = ridgefilter(normim, orientim, freqim, cfg.gabor.kx, cfg.gabor.ky, 0);
        
        % בינאריזציה עם הרגישות מה-Config
        binOffset = 0;
        if isfield(cfg, 'binarize') && isfield(cfg.binarize, 'sens')
            binOffset = cfg.binarize.sens - 0.5; 
        end
        
        binaryImg = enhancedImg > binOffset; 
        binaryImg = binaryImg & roiMask; 
        binaryImg = bwareaopen(binaryImg, 10);
        binaryImg = ~bwareaopen(~binaryImg, 10);
        
        debug.binaryMasked = binaryImg;
        debug.enhancedImg = enhancedImg; % שומרים גם את ה-Gabor המקורי לתצוגה

        statusHandle('Step 4/7: Skeletonization...');
        skeletonImg = bwmorph(binaryImg, 'thin', Inf);
        skeletonImg = bwmorph(skeletonImg, 'clean');
        skeletonImg = bwmorph(skeletonImg, 'diag');
        skeletonImg = bwmorph(skeletonImg, 'spur', 5); 
        
        debug.skeletonImg = skeletonImg;

        statusHandle('Step 5/7: Raw Extraction...');
        
        erosionVal = 12;
        if isfield(cfg.roi, 'strict_erosion'), erosionVal = cfg.roi.strict_erosion; end
        seStrict = strel('disk', erosionVal);
        strictMask = imerode(roiMask, seStrict);
        
        rawMinutiae = extract_minutiae_features(skeletonImg, strictMask, cfg);
        debug.rawMinutiae = rawMinutiae;

        statusHandle('Step 6/7: Final Filtering...');
        template = filter_minutiae(rawMinutiae, strictMask, cfg);
        
        statusHandle('Step 7/7: Descriptors...');
        descriptors = compute_descriptors(template, cfg);
        
        debug.finalTemplate = template;
        
    catch err
        % במקרה של שגיאה במנוע, זורקים אותה החוצה
        rethrow(err);
    end
end