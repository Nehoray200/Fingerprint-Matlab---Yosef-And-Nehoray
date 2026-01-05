function [template, roiMask, rawMinutiae, descriptors] = process_fingerprint(img)
    % טעינת קובץ ההגדרות המרכזי
    cfg = get_config();

    % 1. המרה לאפור ונרמול
    if size(img, 3) == 3, img = rgb2gray(img); end
    img = im2double(img);
    
    % 2. חישוב מסיכה (ROI)
    % ניתן לעדכן גם את get_roi_mask לקבל את cfg אם יש שם פרמטרים רלוונטיים
    roiMask = get_roi_mask(img);
    
    % 3. שיפור ניגודיות (CLAHE)
    imgEnhanced = adapthisteq(img);
    % שימוש בפרמטר מתוך הקונפיגורציה (במקום 0.8)
    imgEnhanced = imgaussfilt(imgEnhanced, cfg.preprocess.gauss_sigma); 
    
    % 4. בינאריזציה חכמה
    % שימוש בפרמטר הרגישות מתוך הקונפיגורציה (במקום 0.50)
    binaryImg = imbinarize(imgEnhanced, 'adaptive', ...
        'Sensitivity', cfg.preprocess.bin_sensitivity, ...
        'ForegroundPolarity', 'dark');
    
    % === תיקונים מורפולוגיים (נשארים לוגית כפי שהגדרת, ניתן להוסיף לקונפיג בהמשך) ===
    se = strel('disk', 1);
    binaryImg = imclose(~binaryImg, se); 
    binaryImg = ~binaryImg;              
    
    binaryImg = ~bwareaopen(~binaryImg, 5); % מילוי חורים
    binaryImg = bwareaopen(binaryImg, 20);  % ניקוי רעשים
    
    % חיתוך לפי המסיכה
    binaryImg = binaryImg & roiMask;
    
    % 5. יצירת שלד (Skeletonization)
    skeletonImg = bwmorph(binaryImg, 'thin', Inf);
    skeletonImg = bwmorph(skeletonImg, 'clean');
    skeletonImg = bwmorph(skeletonImg, 'spur', 5);
    
    % 6. חילוץ נקודות (Minutiae Extraction)
    % מעבירים את cfg כדי שהפונקציה תדע כמה צעדים ללכת בחישוב הזווית
    rawMinutiae = extract_minutiae_features(skeletonImg, cfg);
    
    % 7. סינון סופי
    % מעבירים את cfg כדי להשתמש ב-border_margin וב-min_distance
    template = filter_minutiae(rawMinutiae, roiMask, cfg);
    
    % 8. חישוב מתארים
    % מעבירים את cfg אם נדרש שם פרמטר לחישוב התיאור
    descriptors = compute_descriptors(template, cfg);
end