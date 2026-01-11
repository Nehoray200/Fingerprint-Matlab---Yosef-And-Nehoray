function mask = get_roi_mask(img)
    % get_roi_mask - חישוב מסיכה עם פרמטר הרחבה דינאמי
    
    cfg = get_config();
    
    % 1. זיהוי טקסטורה ע"י סטיית תקן
    textureMap = stdfilt(img, true(11));
    
    % 2. סף אוטומטי
    level = graythresh(textureMap);
    mask = textureMap > level;
    
    % 3. ניקוי ראשוני
    mask = bwareaopen(mask, 500); 
    
    % 4. עיבוד מורפולוגי ליצירת גוש אחיד
    seClose = strel('disk', 15); 
    mask = imclose(mask, seClose);
    mask = imfill(mask, 'holes');
    
    % 5. הרחבת המסיכה (Dilation) - לפי הפרמטר בקונפיג
    % בדיקה אם הפרמטר קיים, אחרת ברירת מחדל 10
    if isfield(cfg, 'roi') && isfield(cfg.roi, 'mask_dilation')
        dilationRadius = cfg.roi.mask_dilation;
    else
        dilationRadius = 10; 
    end
    
    % יצירת אלמנט ההרחבה בגודל המבוקש
    seDilate = strel('disk', dilationRadius);
    mask = imdilate(mask, seDilate);
    
    % 6. וידוא שנשאר רק הגוש הגדול ביותר
    mask = bwareafilt(mask, 1);
    
    mask = logical(mask);
end