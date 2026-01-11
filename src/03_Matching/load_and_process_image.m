function [fingerData, img, errorMsg] = load_and_process_image(fullPath, minPoints)
    % load_and_process_image - פונקציית עזר לטעינה ועיבוד תמונה
    % מחזירה את הנתונים הביומטריים, התמונה המקורית, והודעת שגיאה אם יש.
    
    fingerData = []; 
    img = []; 
    errorMsg = '';
    
    if nargin < 2, minPoints = 12; end % ברירת מחדל
    
    try
        % 1. קריאת התמונה
        img = imread(fullPath);
        
        % 2. הפעלת האלגוריתם (ללא ויזואליזציה)
        [template, ~, ~, descriptors] = process_fingerprint(img, false);
        
        % 3. בדיקת איכות (מספר נקודות מינימלי)
        if size(template, 1) < minPoints
            errorMsg = sprintf('איכות נמוכה: נמצאו רק %d נקודות (דרוש %d).', size(template, 1), minPoints);
            return;
        end
        
        % 4. אריזת הנתונים למבנה נוח
        fingerData.minutiae = template;
        fingerData.descriptors = descriptors;
        
    catch err
        errorMsg = ['שגיאה בקריאה/עיבוד: ' err.message];
    end
end