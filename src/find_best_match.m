function [finalScore, bestAlignedInput, isMatch] = find_best_match(templateData, inputData, manualThreshold)
    % find_best_match - משודרג עם תמיכה ב-Descriptors
    % מבצע יישור גלובלי (Alignment) ואז התאמה מבוססת מתארים [cite: 16]
    
    % פירוק הקלט: אנו מצפים ש-templateData ו-inputData יהיו struct או cell
    % שמכילים גם את הנקודות וגם את ה-descriptors.
    % כדי לשמור על תאימות לאחור בתוך הפונקציה, נניח שהקלט מגיע מפורק או כמבנה.
    
    % הנחה: templateData.minutiae, templateData.descriptors
    T_pts = templateData.minutiae;
    T_desc = templateData.descriptors;
    
    I_pts = inputData.minutiae;
    I_desc = inputData.descriptors;
    
    % --- 1. טעינת הגדרות ---
    cfg = get_config();
    if nargin < 3 || manualThreshold == 0
        scoreThreshold = cfg.match.pass_threshold;
    else
        scoreThreshold = manualThreshold;
    end
    
    % פרמטרים
    distThrSq = cfg.match.max_dist^2;
    angThr    = cfg.match.max_ang_rad;
    sigmaDist = cfg.score.sigma_dist;
    
    bestScore = 0;
    bestAlignedInput = [];
    
    NT = size(I_pts, 1);    
    ND = size(T_pts, 1); 
    
    if NT < 3 || ND < 3, finalScore = 0; isMatch = false; return; end
    
    % המרה למרוכבים לטובת יישור (Alignment) מהיר [cite: 36]
    I_complex = complex(I_pts(:,1), I_pts(:,2));
    D_complex = complex(T_pts(:,1), T_pts(:,2));
    
    I_angles = I_pts(:,4); 
    D_angles = T_pts(:,4);
    I_types  = I_pts(:,3);
    D_types  = T_pts(:,3);
    
    % --- לולאת היישור (Alignment Loop) ---
    % מנסים ליישר את התמונות על בסיס זוגות נקודות תואמות
    for i = 1:min(NT, 20) % אופטימיזציה: בודקים רק 20 נקודות ראשונות כציר
        for j = 1:min(ND, 20)
            
            if I_types(i) ~= D_types(j), continue; end
            
            % בדיקה מקדימה: האם ה-Descriptors של נקודות הציר דומים?
            % זה חוסך יישורים מיותרים אם הסביבה המקומית שונה לגמרי! 
            diffDesc = norm(I_desc(i,:) - T_desc(j,:));
            if diffDesc > 15 % סף שרירותי לדמיון מתארים
                continue; 
            end
            
            % חישוב זווית והזזה
            dTheta = D_angles(j) - I_angles(i);
            rotationFactor = exp(1i * dTheta);
            I_prime_complex = (I_complex - I_complex(i)) * rotationFactor + D_complex(j);
            I_prime_angles = mod(I_angles + dTheta + pi, 2*pi) - pi;
            
            % --- חישוב הציון המשולב ---
            currentScore = 0;
            used_D = false(ND, 1);
            
            for k = 1:NT
                distsSq = abs(I_prime_complex(k) - D_complex).^2;
                [minDistSq, idx] = min(distsSq);
                
                if minDistSq < distThrSq && ~used_D(idx)
                    % 1. התאמה גאומטרית (מיקום + זווית)
                    geomMatch = false;
                    angDiff = abs(mod(I_prime_angles(k) - D_angles(idx) + pi, 2*pi) - pi);
                    if I_types(k) == D_types(idx) && angDiff < angThr
                        geomMatch = true;
                    end
                    
                    if geomMatch
                        % 2. התאמת מתארים (Descriptor Matching)
                        % חישוב המרחק האוקלידי בין המתארים [cite: 62]
                        descDist = norm(I_desc(k,:) - T_desc(idx,:));
                        
                        % ניקוד: משקלב מרחק פיזי + דמיון מתארים
                        % ככל שהמתאר דומה יותר (descDist נמוך), הציון עולה
                        quality_geom = exp(-minDistSq / (2 * sigmaDist^2));
                        quality_desc = exp(-descDist^2 / (2 * 10^2)); % Sigma=10 למתאר
                        
                        % הציון הוא שילוב של השניים
                        currentScore = currentScore + (quality_geom * quality_desc);
                        used_D(idx) = true;
                    end
                end
            end
            
            % נרמול הציון
            finalIterScore = (currentScore^2) / (NT * ND) * 100;
            
            if finalIterScore > bestScore
                bestScore = finalIterScore;
                bestAlignedInput = [real(I_prime_complex), imag(I_prime_complex), I_types, I_prime_angles];
            end
        end
    end
    
    finalScore = bestScore;
    isMatch = (finalScore >= scoreThreshold);
end