function [fingerData, processedImg, errorMsg] = load_and_process_image(fullPath, minPoints)
    fingerData = []; 
    processedImg = []; % משתנה לתמונה המעובדת
    errorMsg = '';
    
    if nargin < 2, minPoints = 12; end 
    
    try
        % 1. קריאת התמונה המקורית
        rawImg = imread(fullPath);
        
        % 2. הפעלת האלגוריתם - שים לב שאנחנו מבקשים כעת 5 משתנים!
        [template, ~, ~, descriptors, processedImg] = process_fingerprint(rawImg, false);
        
        % 3. בדיקת איכות
        if size(template, 1) < minPoints
            errorMsg = sprintf('איכות נמוכה: נמצאו רק %d נקודות (דרוש %d).', size(template, 1), minPoints);
            return;
        end
        
        % 4. אריזת הנתונים
        fingerData.minutiae = template;
        fingerData.descriptors = descriptors;
        
    catch err
        errorMsg = ['שגיאה בקריאה/עיבוד: ' err.message];
    end
end