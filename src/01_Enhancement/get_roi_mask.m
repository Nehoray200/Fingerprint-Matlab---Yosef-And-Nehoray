function mask = get_roi_mask(img)
    % get_roi_mask - מחזירה מסיכה מלאה ואטומה (ללא כרסום)
    
    cfg = get_config();
    
    % 1. זיהוי טקסטורה
    textureMap = rangefilt(img);
    level = graythresh(textureMap);
    mask = imbinarize(textureMap, level);
    
    % 2. חיבור וסגירה
    % שימוש בערך גדול (20) כדי לאחד את כל הפסים לגוש אחד
    seClose = strel('disk', cfg.roi.closing_size); 
    mask = imclose(mask, seClose);
    
    % 3. מילוי חורים (קריטי לחישוב מרחק תקין)
    mask = imfill(mask, 'holes');
    
    % 4. ניקוי רעשי רקע (השארת הגוש הגדול בלבד)
    mask = bwareafilt(mask, 1);
    
    mask = logical(mask);
end