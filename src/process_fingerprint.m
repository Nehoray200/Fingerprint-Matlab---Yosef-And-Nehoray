function [template, roiMask, rawMinutiae, descriptors] = process_fingerprint(img)
    % 1. המרה ושיפור
    if size(img, 3) == 3, img = rgb2gray(img); end
    img = im2double(img);
    imgEnhanced = imgaussfilt(img, 0.5);
    
    % 2. בינאריזציה ושלד
    binaryImg = imbinarize(imgEnhanced, 'adaptive', 'Sensitivity', 0.65);
    skeletonImg = bwmorph(binaryImg, 'thin', Inf);
    
    % 3. עיבוד וחילוץ
    roiMask = get_roi_mask(skeletonImg);
    rawMinutiae = extract_minutiae_features(skeletonImg);
    
    % סינון
    template = filter_minutiae(rawMinutiae, roiMask);
    
    % 4. חישוב מתארים (החלק החדש והחשוב!)
    descriptors = compute_descriptors(template);
end