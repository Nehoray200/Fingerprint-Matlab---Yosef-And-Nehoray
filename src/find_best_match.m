function [finalScore, bestAlignedInput, isMatch] = find_best_match(template, input, manualThreshold)
    % find_best_match - גרסה אופטימלית (מהירה) עם ניקוד חכם וקונפיגורציה
    % משלב את המהירות של מספרים מרוכבים עם הדיוק של Weighted Score
    
    % --- 1. טעינת הגדרות ---
    cfg = get_config();
    
    % קביעת הסף (ידני או מהקונפיג)
    if nargin < 3 || manualThreshold == 0
        scoreThreshold = cfg.match.pass_threshold;
    else
        scoreThreshold = manualThreshold;
    end
    
    % הכנת פרמטרים לחישוב מהיר (שליפה מה-struct חוסכת זמן גישה בלולאה)
    distThrSq = cfg.match.max_dist^2;      % מרחק בריבוע (לחסוך שורש)
    angThr    = cfg.match.max_ang_rad;     % סף זווית ברדיאנים
    sigmaDist = cfg.score.sigma_dist;      % דעיכת מרחק
    sigmaAng  = cfg.score.sigma_ang_rad;   % דעיכת זווית
    
    bestScore = 0;
    bestAlignedInput = [];
    
    NT = size(input, 1);    
    ND = size(template, 1); 
    
    % הגנה מפני קלטים ריקים
    if NT < 3 || ND < 3
        finalScore = 0; isMatch = false; return;
    end
    
    % --- המרה למספרים מרוכבים (Complex Numbers) לביצועים ---
    T_complex = complex(input(:,1), input(:,2));       % קלט
    D_complex = complex(template(:,1), template(:,2)); % מאגר
    
    T_angles = input(:,4); 
    D_angles = template(:,4);
    T_types  = input(:,3);
    D_types  = template(:,3);
    
    % --- לולאת היישור (Alignment Loop) ---
    for i = 1:NT
        for j = 1:ND
            
            % 1. סינון מהיר לפי סוג
            if T_types(i) ~= D_types(j), continue; end
            
            % 2. חישוב זווית הסיבוב (Delta Theta)
            dTheta = D_angles(j) - T_angles(i);
            
            % === יישור וקטורי מהיר ===
            % סיבוב כל הנקודות במכה אחת באמצעות כפל ב-exp
            rotationFactor = exp(1i * dTheta);
            T_prime_complex = (T_complex - T_complex(i)) * rotationFactor + D_complex(j);
            
            % עדכון זוויות
            T_prime_angles = mod(T_angles + dTheta + pi, 2*pi) - pi;
            
            % --- שלב חישוב הציון (Weighted Score) ---
            totalQuality = 0;
            used_D = false(ND, 1);
            
            for k = 1:NT
                % חישוב מרחק לכל הנקודות במאגר (מרוכבים)
                distsSq = abs(T_prime_complex(k) - D_complex).^2;
                
                % מציאת השכן הכי קרוב
                [minDistSq, idx] = min(distsSq);
                
                % בדיקת סף מרחק (בריבוע)
                if minDistSq < distThrSq && ~used_D(idx)
                    % בדיקת סוג
                    if T_types(k) == D_types(idx)
                        % בדיקת זווית
                        angDiff = abs(mod(T_prime_angles(k) - D_angles(idx) + pi, 2*pi) - pi);
                        
                        if angDiff < angThr
                            % === חישוב הניקוד החכם (במקום סתם +1) ===
                            q_d = exp(-minDistSq / (2 * sigmaDist^2));
                            q_a = exp(-angDiff^2 / (2 * sigmaAng^2));
                            
                            totalQuality = totalQuality + (q_d * q_a);
                            used_D(idx) = true; 
                        end
                    end
                end
            end
            
            % --- נרמול הציון הסופי ---
            % הנוסחה: (SumOfQualities^2) / (NT * ND) * 100
            currentScore = (totalQuality^2) / (NT * ND) * 100;
            
            if currentScore > bestScore
                bestScore = currentScore;
                % המרה חזרה לקואורדינטות רגילות רק עבור התצוגה
                bestAlignedInput = [real(T_prime_complex), imag(T_prime_complex), T_types, T_prime_angles];
            end
        end
    end
    
    finalScore = bestScore;
    isMatch = (finalScore >= scoreThreshold);
end