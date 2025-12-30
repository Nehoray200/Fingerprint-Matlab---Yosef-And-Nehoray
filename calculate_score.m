function score = calculate_score(template, input)
    % calculate_smart_score - חישוב ציון חכם מבוסס איכות ומשקל
    % הנוסחה: סכום (איכות_מרחק * איכות_זווית) מנורמל לפי גודל המאגרים
    
    % --- פרמטרים לרגישות ---
    maxDist = 15;         % סף מרחק מקסימלי (פיקסלים)
    maxAng = deg2rad(20); % סף זווית מקסימלי (רדיאנים)
    
    % קבועי דעיכה (ככל שהמספר קטן יותר, הציון יורד מהר יותר עם המרחק)
    sigma_dist = 5; 
    sigma_ang  = deg2rad(10);
    
    % מונים
    totalQualitySum = 0; % זה ה-M החדש והמשוקלל שלנו
    
    numT = size(template, 1);
    numI = size(input, 1);
    
    isMatched = false(numT, 1); 
    
    for i = 1:numI
        for t = 1:numT
            if isMatched(t), continue; end 
            
            % 1. בדיקת סוג
            if input(i, 3) ~= template(t, 3), continue; end
            
            % 2. חישוב מרחק אוקלידי
            dist = sqrt((input(i,1) - template(t,1))^2 + (input(i,2) - template(t,2))^2);
            
            if dist <= maxDist
                % 3. חישוב הפרש זווית
                dAng = abs(mod(input(i,4) - template(t,4) + pi, 2*pi) - pi);
                
                if dAng <= maxAng
                    
                    % === החלק החכם: חישוב איכות ההתאמה ===
                    
                    % איכות המרחק (1 = מושלם, שואף ל-0 ככל שמתרחקים)
                    quality_d = exp(-(dist^2) / (2 * sigma_dist^2));
                    
                    % איכות הזווית
                    quality_a = exp(-(dAng^2) / (2 * sigma_ang^2));
                    
                    % הציון לזוג הספציפי הזה
                    pairScore = quality_d * quality_a;
                    
                    % הוספה לסכום הכולל
                    totalQualitySum = totalQualitySum + pairScore;
                    
                    isMatched(t) = true;
                    break; 
                end
            end
        end
    end
    
    % === החלק הסופי: הנוסחה שביקשת עם שיפור ===
    % המונה: סכום האיכויות (במקום סתם לספור M)
    % המכנה: שורש של מכפלת הכמויות (מנרמל את הציון)
    
    if numT > 0 && numI > 0
        % כופלים ב-100 כדי לקבל מספר נוח (בין 0 ל-100)
        score = (totalQualitySum * totalQualitySum) / (numT * numI) * 100;
        
        % אופציה חלופית (עדינה יותר):
        % score = (totalQualitySum * 2) / (numT + numI) * 100;
    else
        score = 0;
    end
end