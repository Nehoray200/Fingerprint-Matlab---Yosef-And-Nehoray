function score = calculate_score(template, input, cfg)
    % calculate_score - חישוב ציון חכם המבוסס על הגדרות מקובץ config
    % קלט:
    %   template - רשימת נקודות מהמאגר [x, y, type, angle]
    %   input    - רשימת נקודות מהקלט (אחרי יישור)
    %   cfg      - מבנה ההגדרות (נטען מ-config.m)
    
    % --- 1. שליפת פרמטרים מקובץ ההגדרות ---
    maxDist   = cfg.match.max_dist;       % סף מרחק מקסימלי
    maxAng    = cfg.match.max_ang_rad;    % סף זווית מקסימלי (ברדיאנים)
    
    % קבועי דעיכה לנוסחה (Sigma)
    sigmaDist = cfg.score.sigma_dist; 
    sigmaAng  = cfg.score.sigma_ang_rad;
    
    % מונים
    totalQualitySum = 0; % זה ה-M החדש והמשוקלל שלנו
    
    numT = size(template, 1);
    numI = size(input, 1);
    
    % הגנה מפני קלטים ריקים
    if numT == 0 || numI == 0
        score = 0;
        return;
    end
    
    isMatched = false(numT, 1); 
    
    for i = 1:numI
        for t = 1:numT
            if isMatched(t), continue; end 
            
            % 1. בדיקת סוג (Type Check) - חייב להיות זהה
            if input(i, 3) ~= template(t, 3), continue; end
            
            % 2. חישוב מרחק אוקלידי
            dist = sqrt((input(i,1) - template(t,1))^2 + (input(i,2) - template(t,2))^2);
            
            if dist <= maxDist
                % 3. חישוב הפרש זווית (ההפרש הקטן ביותר במעגל)
                dAng = abs(mod(input(i,4) - template(t,4) + pi, 2*pi) - pi);
                
                if dAng <= maxAng
                    
                    % === החלק החכם: חישוב איכות ההתאמה ===
                    
                    % איכות המרחק (1 = מושלם, שואף ל-0 ככל שמתרחקים)
                    quality_d = exp(-(dist^2) / (2 * sigmaDist^2));
                    
                    % איכות הזווית
                    quality_a = exp(-(dAng^2) / (2 * sigmaAng^2));
                    
                    % הציון לזוג הספציפי הזה (Weighted Pair Score)
                    pairScore = quality_d * quality_a;
                    
                    % הוספה לסכום הכולל
                    totalQualitySum = totalQualitySum + pairScore;
                    
                    isMatched(t) = true;
                    break; 
                end
            end
        end
    end
    
    % === חישוב הציון הסופי ===
    % המונה: סכום האיכויות בריבוע (נותן משקל גבוה להתאמות רבות)
    % המכנה: נרמול לפי גודל הקלט והמאגר
    
    score = (totalQualitySum * totalQualitySum) / (numT * numI) * 100;
end