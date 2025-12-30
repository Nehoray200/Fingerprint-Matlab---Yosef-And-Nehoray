function [template, roiMask, rawMinutiae] = process_fingerprint(img)
    % 1. טעינת הגדרות
    cfg = get_config(); 
    
    % 2. המרה ושיפור תמונה (Enhancement)
    if size(img, 3) == 3, img = rgb2gray(img); end
    img = im2double(img);
    
    % שימוש בפילטר גאוסיאני עדין להחלקת רעש
    imgEnhanced = imgaussfilt(img, 0.5);
    
    % 3. בינאריזציה ושלד
    binaryImg = imbinarize(imgEnhanced, 'adaptive', 'Sensitivity', 0.5);
    skeletonImg = bwmorph(binaryImg, 'thin', Inf);
    
    % 4. עיבוד (ROI -> Extract -> Filter)
    roiMask = get_roi_mask(skeletonImg);
    rawMinutiae = extract_minutiae_features(skeletonImg);
    
    % כאן ה-filter_minutiae כבר יקרא ל-cfg בעצמו, אז זה מצוין
    template = filter_minutiae(rawMinutiae, roiMask);
end