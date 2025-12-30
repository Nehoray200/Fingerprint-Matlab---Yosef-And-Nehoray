function mask = get_roi_mask(img)
    % get_roi_mask - יצירת מסיכה ראשונית לפי טקסטורה (Texture Based)
    % מקבל את התמונה המקורית (Grayscale) ומחזיר את אזור האצבע
    
    cfg = get_config();
    
    % 1. זיהוי אזורים עם "פעילות" (פסים)
    % rangefilt מחזיר ערכים גבוהים איפה שיש שינויים חדים (כמו בטביעת אצבע)
    textureMap = rangefilt(img);
    
    % 2. בינאריזציה של הטקסטורה
    % מוצאים סף אוטומטי שמפריד בין אזור חלק לאזור מחוספס
    level = graythresh(textureMap);
    mask = imbinarize(textureMap, level);
    
    % 3. ניקוי ועיצוב המסיכה
    % מילוי חורים בתוך האצבע
    mask = imfill(mask, 'holes');
    
    % חיבור אזורים קרובים (למקרה שהטביעה מקוטעת)
    seClose = strel('disk', 10);
    mask = imclose(mask, seClose);
    
    % 4. השארת הגוש הגדול בלבד (האצבע)
    % מנקה רעשים קטנים ברקע
    mask = bwareafilt(mask, 1);
    
    % 5. כרסום שוליים (Erosion)
    % כדי לא לקחת נקודות שנמצאות ממש על הקצה הבעייתי
    if cfg.roi.erosion_size > 0
        seErode = strel('disk', cfg.roi.erosion_size);
        mask = imerode(mask, seErode);
    end
    
    mask = logical(mask);
end