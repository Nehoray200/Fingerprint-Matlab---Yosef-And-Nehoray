function M = count_matching_minutiae(template, alignedInput)
    % count_matching_minutiae - ספירת זוגות תואמים (M) לפי החוקים שהגדרת
    % קלט: תבנית המאגר (D), והקלט המיושר (T')
    % פלט: M - מספר הזוגות שנמצאו
    
    M = 0;
    
    % --- תנאי סף (Thresholds) ---
    r0 = 12;             % סף מרחק (פיקסלים) - גודל התיבה התוחמת
    theta0 = deg2rad(15); % סף זווית (רדיאנים)
    
    numT = size(alignedInput, 1); % NT
    numD = size(template, 1);     % ND
    
    % מערך מעקב: כל נקודה ב-D יכולה להיות חלק מזוג אחד בלבד!
    isMatchedD = false(numD, 1); 
    
    % מעבר על כל נקודה בתבנית הקלט המיושרת (T')
    for i = 1:numT
        
        inputPoint = alignedInput(i, :); % [x, y, type, angle]
        
        % חיפוש נקודה מתאימה בתבנית המאגר (D)
        for j = 1:numD
            % אם הנקודה ב-D כבר נתפסה ע"י מישהו אחר - דלג
            if isMatchedD(j)
                continue;
            end
            
            dbPoint = template(j, :);
            
            % 1. בדיקת סוג (Type Check)
            if inputPoint(3) ~= dbPoint(3)
                continue;
            end
            
            % 2. בדיקת מרחק אוקלידי (Euclidean Distance)
            dist = sqrt((inputPoint(1)-dbPoint(1))^2 + (inputPoint(2)-dbPoint(2))^2);
            
            if dist < r0
                % 3. בדיקת זווית (Direction Difference)
                % חישוב ההפרש המינימלי במעגל (בין -pi ל-pi)
                angleDiff = abs(mod(inputPoint(4) - dbPoint(4) + pi, 2*pi) - pi);
                
                if angleDiff < theta0
                    % === נמצא זוג תואם! ===
                    M = M + 1;
                    isMatchedD(j) = true; % נועלים את הנקודה ב-D
                    break; % עוברים לנקודה הבאה ב-T
                end
            end
        end
    end
end