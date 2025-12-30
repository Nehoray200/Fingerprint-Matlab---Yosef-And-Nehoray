function [finalScore, bestAlignedInput, isMatch] = find_best_match(templateData, inputData, manualThreshold)
    % find_best_match - גרסה נקייה ומתכווננת (Configurable)
    
    % --- פירוק הקלט ---
    T_pts = templateData.minutiae;
    T_desc = templateData.descriptors;
    I_pts = inputData.minutiae;
    I_desc = inputData.descriptors;
    
    % --- 1. טעינת הגדרות מהקונפיגורציה ---
    cfg = get_config();
    if nargin < 3 || manualThreshold == 0
        scoreThreshold = cfg.match.pass_threshold;
    else
        scoreThreshold = manualThreshold;
    end
    
    % שימוש בערכים מקובץ ההגדרות
    distThrSq     = cfg.match.max_dist^2;
    angThr        = cfg.match.max_ang_rad;
    numCandidates = cfg.match.candidate_count; % שולט על המהירות/דיוק
    
    sigmaDist     = cfg.score.sigma_dist;
    sigmaDesc     = cfg.score.sigma_desc;      % שולט על הסלחנות של ה-Descriptor
    
    bestScore = 0;
    bestAlignedInput = [];
    
    NT = size(T_pts, 1);
    NI = size(I_pts, 1);
    
    if NT < 3 || NI < 3, finalScore = 0; isMatch = false; return; end
    
    % המרה למרוכבים
    I_complex = complex(I_pts(:,1), I_pts(:,2));
    D_complex = complex(T_pts(:,1), T_pts(:,2));
    
    I_angles = I_pts(:,4); 
    D_angles = T_pts(:,4);
    I_types  = I_pts(:,3);
    D_types  = T_pts(:,3);
    
    % --- שלב 1: בחירת מועמדים (Priority Selection) ---
    diffMat = zeros(NI, NT);
    for i = 1:NI
        d = I_desc(i,:) - T_desc; 
        diffMat(i,:) = sqrt(sum(d.^2, 2));
    end
    
    % לוקחים את כמות המועמדים שהוגדרה ב-Config (למשל 100)
    actualCandidates = min(numCandidates, NI * NT);
    
    [~, sortIdx] = sort(diffMat(:), 'ascend');
    [candidateI, candidateJ] = ind2sub([NI, NT], sortIdx(1:actualCandidates));
    
    % --- שלב 2: לולאת היישור ---
    for k = 1:actualCandidates
        i = candidateI(k);
        j = candidateJ(k);
        
        if I_types(i) ~= D_types(j), continue; end
        
        % יישור
        dTheta = D_angles(j) - I_angles(i);
        rotationFactor = exp(1i * dTheta);
        
        I_prime_complex = (I_complex - I_complex(i)) * rotationFactor + D_complex(j);
        I_prime_angles = mod(I_angles + dTheta + pi, 2*pi) - pi;
        
        % חישוב הציון
        distGrid = abs(I_prime_complex - D_complex.'); 
        [minDists, closestIndices] = min(distGrid, [], 2);
        
        validMatches = (minDists.^2 < distThrSq);
        
        idxInput = find(validMatches);
        idxDb = closestIndices(validMatches);
        
        if isempty(idxInput), continue; end
        
        % בדיקת זווית לפי הסף שהוגדר ב-Config
        angleDiffs = abs(mod(I_prime_angles(idxInput) - D_angles(idxDb) + pi, 2*pi) - pi);
        
        typeMatch = (I_types(idxInput) == D_types(idxDb));
        strictMatch = (angleDiffs < angThr) & typeMatch;
        
        currentScore = 0;
        if any(strictMatch)
            geomScores = exp(-minDists(idxInput(strictMatch)).^2 / (2 * sigmaDist^2));
            
            % שימוש ב-sigmaDesc מתוך ה-Config
            descScores = zeros(size(geomScores));
            for m = 1:length(geomScores)
                descVal = diffMat(idxInput(m), idxDb(m));
                descScores(m) = exp(-descVal^2 / (2 * sigmaDesc^2)); 
            end
            
            currentScore = sum(geomScores .* descScores);
        end
        
        % נרמול
        finalIterScore = (currentScore^2) / (NT * NI) * 100;
        
        if finalIterScore > bestScore
            bestScore = finalIterScore;
            bestAlignedInput = [real(I_prime_complex), imag(I_prime_complex), I_types, I_prime_angles];
        end
        
        % עצירה מוקדמת (Hardcoded כי זה אופטימיזציה אבסולוטית)
        if bestScore > 80
            break;
        end
    end
    
    finalScore = bestScore;
    isMatch = (finalScore >= scoreThreshold);
end