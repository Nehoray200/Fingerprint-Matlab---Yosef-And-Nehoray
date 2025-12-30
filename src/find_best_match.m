function [finalScore, bestAlignedInput, isMatch] = find_best_match(templateData, inputData, manualThreshold)
    % find_best_match - גרסה מתוקנת (ללא סינון אגרסיבי של descriptors)
    
    % פירוק הקלט
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
    
    % המרה למרוכבים
    I_complex = complex(I_pts(:,1), I_pts(:,2));
    D_complex = complex(T_pts(:,1), T_pts(:,2));
    
    I_angles = I_pts(:,4); 
    D_angles = T_pts(:,4);
    I_types  = I_pts(:,3);
    D_types  = T_pts(:,3);
    
    % --- לולאת היישור (Alignment Loop) ---
    for i = 1:NT 
        for j = 1:ND
            
            % סינון בסיסי: חייבים להיות מאותו סוג (סיום/פיצול)
            if I_types(i) ~= D_types(j), continue; end
            
            % --- שינוי: ביטלנו את הסינון המקדים לפי descriptors ---
            % במקום למנוע את הניסיון, נשתמש בזה רק לניקוד הסופי.
            % הסינון כאן גרם לכישלון ברוטציות בגלל רעש דיגיטלי.
            
            % חישוב זווית והזזה
            dTheta = D_angles(j) - I_angles(i);
            rotationFactor = exp(1i * dTheta);
            
            % טרנספורמציה (יישור)
            I_prime_complex = (I_complex - I_complex(i)) * rotationFactor + D_complex(j);
            I_prime_angles = mod(I_angles + dTheta + pi, 2*pi) - pi;
            
            % --- חישוב הציון ---
            currentScore = 0;
            used_D = false(ND, 1);
            
            for k = 1:NT
                distsSq = abs(I_prime_complex(k) - D_complex).^2;
                [minDistSq, idx] = min(distsSq);
                
                if minDistSq < distThrSq && ~used_D(idx)
                    
                    angDiff = abs(mod(I_prime_angles(k) - D_angles(idx) + pi, 2*pi) - pi);
                    
                    if I_types(k) == D_types(idx) && angDiff < angThr
                        
                        % התאמה גאומטרית
                        quality_geom = exp(-minDistSq / (2 * sigmaDist^2));
                        
                        % התאמת מתארים (Descriptors) - כבונוס לציון בלבד
                        quality_desc = 1; 
                        if ~isempty(I_desc) && ~isempty(T_desc)
                            descDist = norm(I_desc(k,:) - T_desc(idx,:));
                            % אם הדמיון טוב, ניתן בונוס. אם לא, הציון יורד קצת אבל לא מתאפס
                             quality_desc = exp(-descDist^2 / (2 * 10^2)); 
                        end
                        
                        currentScore = currentScore + (quality_geom * quality_desc);
                        used_D(idx) = true;
                    end
                end
            end
            
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