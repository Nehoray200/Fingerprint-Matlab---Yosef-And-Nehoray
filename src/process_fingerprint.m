function [template, roiMask, rawMinutiae, descriptors] = process_fingerprint(img)
    % process_fingerprint - גרסה משודרגת הכוללת חישוב Descriptors
    
    % 1. טעינת הגדרות
     cfg = get_config();

    
    % 2. המרה ושיפור תמונה (Enhancement)
    if size(img, 3) == 3, img = rgb2gray(img); end
    img = im2double(img);
    
    imgEnhanced = imgaussfilt(img, 0.5);
    
    % 3. בינאריזציה ושלד
    binaryImg = imbinarize(imgEnhanced, 'adaptive', 'Sensitivity', 0.5);
    skeletonImg = bwmorph(binaryImg, 'thin', Inf);
    
    % 4. עיבוד וחילוץ נקודות
    roiMask = get_roi_mask(skeletonImg);
    rawMinutiae = extract_minutiae_features(skeletonImg);
    
    % סינון ראשוני
    template = filter_minutiae(rawMinutiae, roiMask);
    
    % --- תוספת חדשה: חישוב מתארים (Descriptors) ---
    % יצירת וקטור מאפיינים עשיר לכל נקודה [cite: 102]
    descriptors = compute_descriptors(template);
end