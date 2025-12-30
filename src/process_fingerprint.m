function [template, roiMask, rawMinutiae, descriptors] = process_fingerprint(img)
    % process_fingerprint - גרסה סלחנית (לוכדת מקסימום נקודות)
    
    % 1. המרה ושיפור
    if size(img, 3) == 3, img = rgb2gray(img); end
    img = im2double(img);
    
    % שיפור ניגודיות (עוזר מאוד לתמונות חיוורות)
    img = adapthisteq(img); 
    imgEnhanced = imgaussfilt(img, 0.5); % פילטר עדין יותר
    
    % 2. בינאריזציה רגישה
    % Sensitivity גבוה (0.65) אומר: תחשוב שיותר דברים הם "רכס" ולא רקע
    binaryImg = imbinarize(imgEnhanced, 'adaptive', 'Sensitivity', 0.65);
    
    % --- ניקוי עדין בלבד ---
    % סגירת חורים קטנים בתוך הרכסים
    binaryImg = bwareaopen(binaryImg, 5); 
    % מחיקת רעש רקע (רק נקודות ממש קטנות)
    binaryImg = ~bwareaopen(~binaryImg, 5); 
    
    % 3. יצירת שלד
    skeletonImg = bwmorph(binaryImg, 'thin', Inf);
    
    % ניקוי בסיסי (בלי 'spur' שמוחק קצוות)
    skeletonImg = bwmorph(skeletonImg, 'clean');
    
    % 4. מסיכה (ROI) מקסימלית
    roiMask = get_roi_mask(skeletonImg);
    
    % כרסום מינימלי (כמעט לא נוגעים בשוליים)
    se = strel('disk', 2); 
    roiMask = imerode(roiMask, se);
    
    % חילוץ
    rawMinutiae = extract_minutiae_features(skeletonImg);
    
    % סינון
    template = filter_minutiae(rawMinutiae, roiMask);
    
    % 5. מתארים
    descriptors = compute_descriptors(template);
end