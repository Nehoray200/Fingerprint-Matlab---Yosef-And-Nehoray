function [template, roiMask, rawMinutiae, descriptors, img] = process_fingerprint(img, do_viz)
    % process_fingerprint - הגרסה הרגילה
    
    if nargin < 2, do_viz = false; end
    cfg = get_config(); % טעינת הגדרות (כולל מה שנשמר בקובץ המשתמש)
    debug = struct();
    
    % 1. המרה לאפור
    if size(img, 3) == 3, img = rgb2gray(img); end
    img = im2double(img);
    img = adapthisteq(img, 'ClipLimit', 0.02);
    
    % --- שינוי: שליחת cfg למסיכה ---
    fullMask = get_roi_mask(img, cfg);
    % -------------------------------
    
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
    
    % 2-7. עיבוד
    [normim, ~, ~] = ridgesegment(img, cfg.gabor.blk_sze, cfg.gabor.thresh);
    orientim = ridgeorient(normim, cfg.gabor.grad_sigma, cfg.gabor.block_sigma, cfg.gabor.smooth_sigma);
    [freqim, ~] = ridgefreq(normim, roiMask, orientim, cfg.gabor.freq_blk, ...
                            cfg.gabor.freq_wind, cfg.gabor.min_wl, cfg.gabor.max_wl);
    
    enhancedImg = ridgefilter(normim, orientim, freqim, cfg.gabor.kx, cfg.gabor.ky, 0);
    
    binOffset = 0;
    if isfield(cfg, 'binarize') && isfield(cfg.binarize, 'sens')
        binOffset = cfg.binarize.sens - 0.5; 
    end
    binaryImg = enhancedImg > binOffset;
    
    binaryImg = binaryImg & roiMask; 
    binaryImg = bwareaopen(binaryImg, 10);
    binaryImg = ~bwareaopen(~binaryImg, 10);
    
    debug.binaryMasked = binaryImg;
    
    skeletonImg = bwmorph(binaryImg, 'thin', Inf);
    skeletonImg = bwmorph(skeletonImg, 'clean');
    skeletonImg = bwmorph(skeletonImg, 'diag');
    skeletonImg = bwmorph(skeletonImg, 'spur', 5); 
    
    debug.skeletonImg = skeletonImg;
    
    % מסיכה קפדנית
    erosionVal = 12; 
    if isfield(cfg.roi, 'strict_erosion'), erosionVal = cfg.roi.strict_erosion; end
    seStrict = strel('disk', erosionVal);
    strictMask = imerode(roiMask, seStrict);
    
    % 8. חילוץ
    rawMinutiae = extract_minutiae_features(skeletonImg, strictMask, cfg);
    debug.rawMinutiae = rawMinutiae;
    
    % 9. סינון
    template = filter_minutiae(rawMinutiae, strictMask, cfg);
    debug.finalTemplate = template;
    
    % 10. דסקריפטורים
    descriptors = compute_descriptors(template, cfg);
    
    if do_viz
        visualize_pipeline(debug, cfg);
    end
end