function mask = get_roi_mask(skeletonImg)
    % get_roi_mask - יוצרת מסיכה בינארית של אזור האצבע
    % משתמשת בהגדרות מתוך config.m
    
    % 1. טעינת הגדרות
    cfg = get_config();
    closeDiskSize = cfg.roi.closing_size; % למשל 15
    erodeDiskSize = cfg.roi.erosion_size; % למשל 10
    
    % 2. המרה ללוגי
    % הערה: אנו מניחים שהרכסים הם 1 (לבן) והרקע 0 (שחור).
    if ~islogical(skeletonImg)
        bin = imbinarize(skeletonImg);
    else
        bin = skeletonImg;
    end
    
    % 3. סגירה מורפולוגית (Closing)
    % מחברים את כל הקווים לגוש אחד גדול ולבן
    closedImg = imclose(bin, strel('disk', closeDiskSize));
    
    % 4. מילוי חורים (Fill Holes)
    % אם נשארו "חורים" שחורים בתוך האצבע - ממלאים אותם
    filledImg = imfill(closedImg, 'holes');
    
    % 5. כיווץ (Erosion) - השלב הקריטי!
    % מקטינים את האזור הלבן פנימה כדי להעיף קצוות מזויפים
    mask = imerode(filledImg, strel('disk', erodeDiskSize));
    
    % המרה ללוגי סופי
    mask = logical(mask);
end