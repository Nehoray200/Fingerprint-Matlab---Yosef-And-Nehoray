function [finalScore, bestAlignedInput, isMatch] = find_best_match(templateData, inputData, manualThreshold)
    % find_best_match - גרסה ממוטבת ביצועים (Smart Filtering)
    % אופטימיזציה: שימוש ב-Descriptors לסינון מוקדם של זוגות ליישור.
    
    % --- פירוק הקלט ---
    T_pts = templateData.minutiae;      % נקודות במאגר (X, Y, Type, Angle)
    T_desc = templateData.descriptors;  % מתארים במאגר
    
    I_pts = inputData.minutiae;         % נקודות בקלט
    I_desc = inputData.descriptors;     % מתארים בקלט
    
    % --- טעינת הגדרות ---
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
    
    NT = size(T_pts, 1);
    NI = size(I_pts, 1);
    
    if NT < 3 || NI < 3, finalScore = 0; isMatch = false; return; end
    
    % המרה למרוכבים לחישוב וקטורי מהיר
    I_complex = complex(I_pts(:,1), I_pts(:,2));
    D_complex = complex(T_pts(:,1), T_pts(:,2));
    
    I_angles = I_pts(:,4); 
    D_angles = T_pts(:,4);
    I_types  = I_pts(:,3);
    D_types  = T_pts(:,3);
    
    % --- שלב 1: יצירת רשימת מועמדים חכמה (Candidate Selection) ---
    % במקום לנסות ליישר כל נקודה מול כל נקודה, נחפש זוגות עם Descriptors דומים.
    
    % חישוב מרחק בין כל ה-Descriptors (מטריצה בגודל NI x NT)
    % אנו משתמשים בחישוב וקטורי מהיר (pdist2 גרסה ידנית)
    diffMat = zeros(NI, NT);
    for i = 1:NI
        % מרחק אוקלידי בין המתאר של נקודה i בקלט לכל המתארים במאגר
        d = I_desc(i,:) - T_desc; 
        diffMat(i,:) = sqrt(sum(d.^2, 2));
    end
    
    % מציאת הזוגות הכי טובים (אלו עם המרחק הקטן ביותר)
    % נבחר את ה-K הזוגות המבטיחים ביותר (למשל 30)
    numCandidates = min(30, NI * NT); 
    [~, sortIdx] = sort(diffMat(:), 'ascend');
    [candidateI, candidateJ] = ind2sub([NI, NT], sortIdx(1:numCandidates));
    
    % --- שלב 2: לולאת היישור רק על המועמדים (Alignment Loop) ---
    
    for k = 1:numCandidates
        i = candidateI(k); % אינדקס בקלט
        j = candidateJ(k); % אינדקס במאגר
        
        % סינון סוג הנקודה (חייב להיות זהה: פיצול מול פיצול וכו')
        if I_types(i) ~= D_types(j), continue; end
        
        % חישוב זווית והזזה ליישור
        dTheta = D_angles(j) - I_angles(i);
        rotationFactor = exp(1i * dTheta);
        
        % טרנספורמציה גלובלית
        I_prime_complex = (I_complex - I_complex(i)) * rotationFactor + D_complex(j);
        I_prime_angles = mod(I_angles + dTheta + pi, 2*pi) - pi;
        
        % --- חישוב הציון (וקטורי לחלוטין) ---
        currentScore = 0;
        
        % מטריצת מרחקים בין הנקודות המיושרות לנקודות המאגר
        % ניצול יכולות המטריצה של MATLAB (Broadcasting)
        % שורות = נקודות קלט, עמודות = נקודות מאגר
        distGrid = abs(I_prime_complex - D_complex.'); 
        
        % לכל נקודה בקלט, מצא את השכן הכי קרוב במאגר
        [minDists, closestIndices] = min(distGrid, [], 2);
        
        % חישוב הציון רק עבור התאמות טובות
        validMatches = (minDists.^2 < distThrSq);
        
        % בדיקת כיוון וסוג עבור ההתאמות שנמצאו קרובות
        idxInput = find(validMatches);
        idxDb = closestIndices(validMatches);
        
        if isempty(idxInput), continue; end
        
        % בדיקת הפרש זוויות לכל הזוגות בבת אחת
        angleDiffs = abs(mod(I_prime_angles(idxInput) - D_angles(idxDb) + pi, 2*pi) - pi);
        typeMatch = (I_types(idxInput) == D_types(idxDb));
        
        % סינון סופי: גם קרוב, גם זווית תואמת, גם סוג תואם
        strictMatch = (angleDiffs < angThr) & typeMatch;
        
        % סיכום הניקוד
        if any(strictMatch)
            % ניקוד גאומטרי
            geomScores = exp(-minDists(idxInput(strictMatch)).^2 / (2 * sigmaDist^2));
            
            % בונוס על דמיון Descriptors (אופציונלי, מחזק אמינות)
            % שולפים את המרחקים שכבר חישבנו ב-diffMat
            % צריך להיזהר עם אינדקסים ליניאריים
            descScores = zeros(size(geomScores));
            for m = 1:length(geomScores)
                descScores(m) = exp(-diffMat(idxInput(m), idxDb(m))^2 / (2 * 10^2));
            end
            
            currentScore = sum(geomScores .* descScores);
        end
        
        % נרמול הציון
        finalIterScore = (currentScore^2) / (NT * NI) * 100;
        
        if finalIterScore > bestScore
            bestScore = finalIterScore;
            bestAlignedInput = [real(I_prime_complex), imag(I_prime_complex), I_types, I_prime_angles];
        end
        
        % אופטימיזציה: עצירה מוקדמת אם הגענו לציון מעולה
        if bestScore > 80
            break;
        end
    end
    
    finalScore = bestScore;
    isMatch = (finalScore >= scoreThreshold);
end