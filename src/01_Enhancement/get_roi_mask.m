function mask = get_roi_mask(img, cfg)
    % get_roi_mask - גרסה מתוקנת שמקבלת הגדרות (cfg) מבחוץ
    
    % אם לא נשלח קונפיג (למשל הרצה ידנית), טען ברירת מחדל
    if nargin < 2
        cfg = get_config();
    end
    
    % 1. זיהוי טקסטורה
    textureMap = stdfilt(img, true(11));
    
    % 2. סף אוטומטי
    level = graythresh(textureMap);
    mask = textureMap > level;
    
    % 3. ניקוי ראשוני
    mask = bwareaopen(mask, 500); 
    
    % 4. עיבוד מורפולוגי
    seClose = strel('disk', 15); 
    mask = imclose(mask, seClose);
    mask = imfill(mask, 'holes');
    
    % 5. הרחבת המסיכה - משתמש בערך שהתקבל מהאפליקציה!
    if isfield(cfg, 'roi') && isfield(cfg.roi, 'mask_dilation')
        dilationRadius = cfg.roi.mask_dilation;
    else
        dilationRadius = 10; 
    end
    
    if dilationRadius > 0
        seDilate = strel('disk', dilationRadius);
        mask = imdilate(mask, seDilate);
    end
    
    % 6. וידוא שנשאר רק הגוש הגדול
    mask = bwareafilt(mask, 1);
    mask = logical(mask);
end