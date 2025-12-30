function [finalScore, bestAlignedInput, isMatch] = find_best_match(template, input, scoreThreshold)
    % find_best_match_optimized - גרסה מהירה מבוססת מטריצות ומספרים מרוכבים
    
    bestScore = 0;
    bestAlignedInput = [];
    
    NT = size(input, 1);    
    ND = size(template, 1); 
    
    if NT < 3 || ND < 3
        finalScore = 0; isMatch = false; return;
    end
    
    % --- המרה למספרים מרוכבים (Complex Numbers) לחישוב מהיר ---
    % Z = X + iY
    % זה מאפשר לסובב את כל הנקודות בשורת קוד אחת ע"י כפל ב- exp(i*theta)
    T_complex = complex(input(:,1), input(:,2));      % וקטור עמודה
    D_complex = complex(template(:,1), template(:,2)); % וקטור עמודה
    
    % חילוץ זוויות וסוגים לגישה מהירה
    T_angles = input(:,4); 
    D_angles = template(:,4);
    T_types  = input(:,3);
    D_types  = template(:,3);
    
    % קבועים (Thresholds)
    distThrSq = 12^2;        % מרחק בריבוע (חוסך חישוב שורש יקר)
    angThr = deg2rad(15);
    
    % --- לולאת היישור (עדיין חייבים לנסות זוגות, אבל בפנים זה מהיר) ---
    for i = 1:NT
        for j = 1:ND
            
            % 1. סינון מהיר לפי סוג
            if T_types(i) ~= D_types(j), continue; end
            
            % 2. חישוב זווית הסיבוב הדרושה (Delta Theta)
            dTheta = D_angles(j) - T_angles(i);
            
            % === הקסם הווקטורי: סיבוב והזזה של כל הנקודות בבת אחת ===
            % במקום לולאה, אנו מבצעים פעולה על כל הווקטור T_complex
            
            % א. סיבוב כל הנקודות סביב נקודה i
            % נוסחה: (Point - Center) * Rotation + Center
            % אבל אצלנו אנחנו רוצים להביא את i ל-j, אז החישוב הוא:
            % T_rotated = (T - T(i)) * exp(i*dTheta) + D(j)
            
            rotationFactor = exp(1i * dTheta);
            T_prime_complex = (T_complex - T_complex(i)) * rotationFactor + D_complex(j);
            
            % חישוב הזוויות החדשות (גם וקטורי)
            % mod עם פאי כדי לשמור על טווח
            T_prime_angles = mod(T_angles + dTheta + pi, 2*pi) - pi;
            
            % --- שלב הספירה המהירה (Matrix Distance Calculation) ---
            % במקום שתי לולאות, נחשב מרחקים בצורה חכמה
            
            matches = 0;
            
            % לולאה קצרה רק על הנקודות כדי למצוא שכנים
            % (אפשר לעשות גם את זה ללא לולאות עם pdist2 אבל זה דורש זיכרון,
            % הלולאה הפנימית הזו מספיק מהירה בגלל שהיא פשוטה)
            
            used_D = false(ND, 1);
            
            for k = 1:NT
                % חישוב המרחק מנקודה k (המוזזת) לכל הנקודות במאגר D
                % abs(Z1 - Z2) נותן מרחק אוקלידי במספרים מרוכבים
                distsSq = abs(T_prime_complex(k) - D_complex).^2;
                
                % מציאת המועמדים הקרובים (פילטר מרחק)
                [minDistSq, idx] = min(distsSq);
                
                if minDistSq < distThrSq && ~used_D(idx)
                    % בדיקת סוג
                    if T_types(k) == D_types(idx)
                        % בדיקת זווית
                        angDiff = abs(mod(T_prime_angles(k) - D_angles(idx) + pi, 2*pi) - pi);
                        if angDiff < angThr
                            matches = matches + 1;
                            used_D(idx) = true; % סימון שהנקודה נתפסה
                        end
                    end
                end
            end
            
            % --- חישוב הציון ---
            currentScore = (matches^2) / (NT * ND) * 100;
            
            if currentScore > bestScore
                bestScore = currentScore;
                
                % המרה חזרה ממרוכבים ל-(X,Y) רק עבור התוצאה הסופית
                bestAlignedInput = [real(T_prime_complex), imag(T_prime_complex), T_types, T_prime_angles];
            end
        end
    end
    
    finalScore = bestScore;
    isMatch = (finalScore >= scoreThreshold);
end