function [template, roiMask, rawMinutiae, descriptors] = process_fingerprint(img)
    % process_fingerprint - גרסה גולמית (Raw Mode) ללא ניקוי
    % הופכת ישר לבינארי ולשלד, בלי פילטרים בדרך.
    
    % 1. המרה לאפור (חובה כדי לעבוד)
    if size(img, 3) == 3, img = rgb2gray(img); end
    img = im2double(img);
    
    % --- בוטל: שלב שיפור וסינון רעשים (Enhancement) ---
    % img = imgaussfilt(img, 0.5); 
    
    % 2. בינאריזציה (חובה - הפיכה לשחור לבן)
    % משתמשים ישירות בתמונה המקורית.
    % Sensitivity נשאר כדי לקבוע איפה הגבול בין שחור ללבן
    binaryImg = imbinarize(img, 'adaptive', 'Sensitivity', 0.86);
    
    % --- בוטל: ניקוי רעשים מורפולוגי (Post-processing) ---
    % השורות האלו נועדו למחוק נקודות שחורות קטנות או לסגור חורים לבנים
    % binaryImg = ~bwareaopen(~binaryImg, 10); 
    % binaryImg = bwareaopen(binaryImg, 10);
    
    % 3. יצירת שלד (Skeletonization)
    % הופכים ישר את התמונה הבינארית לשלד
    skeletonImg = bwmorph(binaryImg, 'thin', Inf);
    
    % --- בוטל: ניקוי קוצים מהשלד ---
    % פעולה זו מנקה "זנבות" קטנים שנחשבים בדרך כלל לטעות
    % skeletonImg = bwmorph(skeletonImg, 'clean');
    
    % 4. עיבוד וחילוץ נקודות (המשך רגיל)
    roiMask = get_roi_mask(skeletonImg);
    rawMinutiae = extract_minutiae_features(skeletonImg);
    
    % סינון לפי המסיכה
    template = filter_minutiae(rawMinutiae, roiMask);
    
    % 5. חישוב מתארים
    descriptors = compute_descriptors(template);
end