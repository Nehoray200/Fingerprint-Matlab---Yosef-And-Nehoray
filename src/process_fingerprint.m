function [template, roiMask, rawMinutiae, descriptors] = process_fingerprint(img)
    % process_fingerprint - גרסה אופטימלית: חיתוך מוקדם עם המסיכה
    
    % 1. המרה לאפור
    if size(img, 3) == 3, img = rgb2gray(img); end
    img = im2double(img);
    
    % 2. חישוב מסיכה (השלב הראשון והחשוב)
    roiMask = get_roi_mask(img);
    
    % 3. עיבוד ובינאריזציה
    img = adapthisteq(img);
    imgEnhanced = imgaussfilt(img, 0.5);
    binaryImg = imbinarize(imgEnhanced, 'adaptive', 'Sensitivity', 0.65);
    
    % ניקוי ראשוני
    binaryImg = bwareaopen(binaryImg, 10);
    binaryImg = ~bwareaopen(~binaryImg, 10);
    
    % --- האופטימיזציה שלך! ---
    % מוחקים את כל מה שמחוץ למסיכה *עכשיו*, לפני יצירת השלד.
    binaryImg = binaryImg & roiMask;
    
    % 4. יצירת שלד (עכשיו השלד ייווצר רק בתוך האצבע)
    skeletonImg = bwmorph(binaryImg, 'thin', Inf);
    skeletonImg = bwmorph(skeletonImg, 'spur', 8); 
    skeletonImg = bwmorph(skeletonImg, 'clean');
    
    % 5. חילוץ
    % עכשיו rawMinutiae יכיל הרבה פחות נקודות זבל
    rawMinutiae = extract_minutiae_features(skeletonImg);
    
    % 6. סינון סופי
    % עדיין צריך את זה כדי להעיף נקודות שנוצרו בדיוק על קו החיתוך
    template = filter_minutiae(rawMinutiae, roiMask);
    
    descriptors = compute_descriptors(template);
end