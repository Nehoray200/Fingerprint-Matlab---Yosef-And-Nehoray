function [template, roiMask, rawMinutiae] = process_fingerprint(img)
    % process_fingerprint - פונקציית על שמנהלת את כל תהליך העיבוד
    % הפונקציה מקבלת תמונה גולמית ומחזירה תבנית מוכנה להשוואה/שמירה.
    %
    % קלט:  img - תמונת טביעת אצבע (מטריצה)
    % פלט:  template - הרשימה הסופית והנקייה [X, Y, Type, Angle]
    %       roiMask - המסיכה שנוצרה (לצרכי תצוגה)
    %       rawMinutiae - הנקודות לפני סינון (לצרכי תצוגה)

    %% 1. שלב מקדים: המרה לשחור לבן אם צריך
    if size(img, 3) == 3
        img = rgb2gray(img);
    end
    
    % המרה ללוגי אם זה לא נעשה כבר (בינאריזציה)
    if ~islogical(img)
        % אפשר להוסיף כאן שלבי שיפור תמונה (Enhancement) בעתיד
        img = imbinarize(img);
    end

    %% 2. יצירת אזור עניין (ROI)
    % קורא לפונקציה שבנינו בנפרד
    roiMask = get_roi_mask(img);

    %% 3. חילוץ מאפיינים (Feature Extraction)
    % קורא לפונקציה שמבצעת Crossing Number
    rawMinutiae = extract_minutiae_features(img);

    %% 4. סינון וניקוי (Post-Processing)
    % קורא לפונקציה שמסננת לפי ROI ולפי מרחק
    template = filter_minutiae(rawMinutiae, roiMask);
    
end