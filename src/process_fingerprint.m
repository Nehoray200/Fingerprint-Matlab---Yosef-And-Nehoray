function [template, roiMask, rawMinutiae, descriptors] = process_fingerprint(img)
    % process_fingerprint - עיבוד, סינון רעשים וחישוב מאפיינים
    
    % 1. המרה ושיפור
    if size(img, 3) == 3, img = rgb2gray(img); end
    img = im2double(img);
    imgEnhanced = imgaussfilt(img, 0.5);
    
    % 2. בינאריזציה אדפטיבית (רגישות מותאמת)
    binaryImg = imbinarize(imgEnhanced, 'adaptive', 'Sensitivity', 0.65);
    
    % --- שיפור: ניקוי רעשים נקודתיים (Post-processing) ---
    % הסרת כתמים שחורים קטנים מדי שאינם רכסים
    binaryImg = ~bwareaopen(~binaryImg, 10); 
    % הסרת חורים לבנים קטנים בתוך הרכסים
    binaryImg = bwareaopen(binaryImg, 10);
    
    % 3. יצירת שלד (Skeletonization)
    skeletonImg = bwmorph(binaryImg, 'thin', Inf);
    
    % ניקוי קוצים קטנים מהשלד (Spurs) - משפר מאוד את דיוק המינושות
    skeletonImg = bwmorph(skeletonImg, 'clean');
    
    % 4. עיבוד וחילוץ
    roiMask = get_roi_mask(skeletonImg);
    rawMinutiae = extract_minutiae_features(skeletonImg);
    
    % סינון
    template = filter_minutiae(rawMinutiae, roiMask);
    
    % 5. חישוב מתארים (Descriptors)
    descriptors = compute_descriptors(template);
end