function mask = get_roi_mask(img)
    % get_roi_mask - חישוב מסיכה המבוסס על שונות (Variance) עם הרחבת גבולות
    
    cfg = get_config();
    
    % 1. זיהוי טקסטורה ע"י סטיית תקן (Standard Deviation)
    % רוב המאמרים (כמו Hong et al.) ממליצים על בדיקת שונות בבלוקים.
    % stdfilt היא המקבילה היעילה ביותר במטלב לכך.
    % שימוש בשכנים של 11x11 נותן תוצאה חלקה יותר מ-3x3.
    textureMap = stdfilt(img, true(11));
    
    % 2. סף אוטומטי (Otsu's Method)
    level = graythresh(textureMap);
    mask = textureMap > level;
    
    % 3. ניקוי ראשוני (הסרת רעשי רקע קטנים)
    % מוחק כתמים לבנים קטנים שאינם האצבע (למשל אבק על הסורק)
    mask = bwareaopen(mask, 500); 
    
    % 4. עיבוד מורפולוגי ליצירת גוש אחיד
    % סגירה (Closing) - מחברת קווים שבורים
    seClose = strel('disk', 15); 
    mask = imclose(mask, seClose);
    
    % מילוי חורים (Filling) - ממלא אזורים שקטים בתוך האצבע
    mask = imfill(mask, 'holes');
    
    % 5. הרחבת המסיכה (Dilation) - קריטי!
    % שלב זה מרחיב את הלבן החוצה כדי למנוע חיתוך של קצות הרכסים
    % כפי שביקשת (שהמסיכה תהיה גדולה מהאצבע)
    seDilate = strel('disk', 10);
    mask = imdilate(mask, seDilate);
    
    % 6. וידוא שנשאר רק הגוש הגדול ביותר (האצבע עצמה)
    mask = bwareafilt(mask, 1);
    
    mask = logical(mask);
end