function [template, roiMask, rawMinutiae, descriptors] = process_fingerprint(img)
    
    % 1. המרה לאפור ונרמול
    if size(img, 3) == 3, img = rgb2gray(img); end
    img = im2double(img);
    
    % 2. חישוב מסיכה (ROI)
    roiMask = get_roi_mask(img);
    
    % 3. שיפור ניגודיות (CLAHE) - עוזר מאוד להדגיש רכסים
    imgEnhanced = adapthisteq(img);
    imgEnhanced = imgaussfilt(imgEnhanced, 0.8); 
    
    % 4. בינאריזציה חכמה
    % אם התמונה המקורית נקייה מאוד (כמו שאמרת), עדיף סף גלובלי
    % אבל נשאיר אדפטיבי עם רגישות נמוכה יותר כדי למנוע חורים
    binaryImg = imbinarize(imgEnhanced, 'adaptive', 'Sensitivity', 0.50, 'ForegroundPolarity', 'dark');
    
    % === התיקון הקריטי: סתימת חורים ברכסים ===
    % הפקודה imclose סוגרת רווחים קטנים בתוך הקווים השחורים
    se = strel('disk', 1);
    binaryImg = imclose(~binaryImg, se); % עובדים על הלבן, אז הופכים רגע
    binaryImg = ~binaryImg;              % מחזירים חזרה
    
    % מילוי חורים פנימיים (Fill Holes)
    binaryImg = ~bwareaopen(~binaryImg, 5); % סוגר חורים שחורים בתוך הלבן
    
    % ניקוי רעשים (נקודות בודדות)
    binaryImg = bwareaopen(binaryImg, 20);
    
    % חיתוך לפי המסיכה
    binaryImg = binaryImg & roiMask;
    
    % 5. יצירת שלד (Skeletonization)
    skeletonImg = bwmorph(binaryImg, 'thin', Inf);
    
    % ניקוי סופי של השלד
    skeletonImg = bwmorph(skeletonImg, 'clean'); % מוריד פיקסלים בודדים
    skeletonImg = bwmorph(skeletonImg, 'spur', 5); % מוריד זיפים קצרים
    
    % 6. חילוץ נקודות (Minutiae Extraction)
    % קורא לפונקציה שכתבנו מקודם (הגרסה עם ה-CN וה-Thinning)
    rawMinutiae = extract_minutiae_features(skeletonImg);
    
    % 7. סינון סופי
    template = filter_minutiae(rawMinutiae, roiMask);
    
    % 8. חישוב מתארים
    descriptors = compute_descriptors(template);
end