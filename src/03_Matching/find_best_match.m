function [finalScore, bestAlignedInput, isMatch] = find_best_match(templateData, inputData, manualThreshold)
    % find_best_match - גרסה סופית מואצת (Matrix Optimized)
    % משתמשת בחישוב מטריציוני מלא ללא לולאות פנימיות
    
    T_pts = templateData.minutiae;
    T_desc = templateData.descriptors;
    I_pts = inputData.minutiae;
    I_desc = inputData.descriptors;
    
    cfg = get_config();
    scoreThreshold = cfg.match.pass_threshold;
    if nargin >= 3 && manualThreshold > 0, scoreThreshold = manualThreshold; end
    
    % בדיקות מקדימות
    if size(T_pts,1) < 5 || size(I_pts,1) < 5
        finalScore = 0; bestAlignedInput=[]; isMatch=false; return;
    end
    
    angThr = cfg.match.max_ang_rad;
    sigmaDist = cfg.score.sigma_dist;
    sigmaDesc = cfg.score.sigma_desc;
    
    % --- שלב 1: מציאת מועמדים ליישור ---
    NI = size(I_pts, 1); 
    NT = size(T_pts, 1);
    
    % חישוב מרחק בין דסקריפטורים (ווקטורי)
    diffMat = zeros(NI, NT);
    for i = 1:NI
        d = I_desc(i,:) - T_desc; 
        diffMat(i,:) = sum(d.^2, 2); 
    end
    diffMat = sqrt(diffMat);
    
    % בחירת הזוגות הטובים ביותר
    numCandidates = min(cfg.match.candidate_count, NI * NT);
    [~, sortIdx] = sort(diffMat(:), 'ascend');
    [candidateI, candidateJ] = ind2sub([NI, NT], sortIdx(1:numCandidates));
    
    bestScore = 0;
    bestAlignedInput = [];
    
    % הכנת נתונים לחישוב וקטורי
    I_coords_orig = I_pts(:, 1:2);
    I_angles_orig = I_pts(:, 4);
    T_coords = T_pts(:, 1:2);
    T_angles = T_pts(:, 4);
    T_types  = T_pts(:, 3);
    
    % חישוב מקדים של ריבועי המרחקים של הטמפלייט (חוסך זמן בתוך הלולאה)
    T_sq = sum(T_coords.^2, 2); 
    
    % --- שלב 2: לולאת יישור (Candidate Loop) ---
    for k = 1:numCandidates
        i = candidateI(k);
        j = candidateJ(k);
        
        % חישוב פרמטרי יישור
        dTheta = T_angles(j) - I_angles_orig(i);
        c = cos(dTheta); s = sin(dTheta);
        rotMat = [c -s; s c];
        
        % יישור כל הנקודות
        centeredI = I_coords_orig - I_coords_orig(i, :);
        alignedI = (centeredI * rotMat') + T_coords(j, :);
        alignedAng = mod(I_angles_orig + dTheta + pi, 2*pi) - pi;
        
        % --- חישוב מטריציוני מהיר למציאת השכן הקרוב (Nearest Neighbor) ---
        % שימוש בזהות: ||A-B||^2 = ||A||^2 + ||B||^2 - 2*A*B'
        % זה הרבה יותר מהיר מלחשב הפרשים לכל זוג נקודות
        
        I_sq = sum(alignedI.^2, 2)'; % (1 x NI)
        
        % מטריצת המרחקים הריבועיים (NT x NI)
        % bsxfun מוסיף את הוקטורים בצורה יעילה ללא שכפול זיכרון
        distMatSq = bsxfun(@plus, T_sq, I_sq) - 2 * (T_coords * alignedI');
        
        % מציאת המינימום לכל עמודה (לכל נקודת קלט - מי השכן הכי קרוב בטמפלייט)
        [minValsSq, matchIndices] = min(distMatSq, [], 1);
        
        % תיקון שגיאות חישוב קטנות (שלילי אפסי) ושורש
        dists = sqrt(max(minValsSq, 0))'; 
        matchIndices = matchIndices';
        
        % --- המשך הלוגיקה המקורית ---
        valid = dists < cfg.match.max_dist;
        
        if sum(valid) >= 3
            idxInput = find(valid);
            idxDb = matchIndices(valid);
            
            % בדיקת זוויות וסוג
            angDiffs = abs(mod(alignedAng(idxInput) - T_angles(idxDb) + pi, 2*pi) - pi);
            typeMatch = (I_pts(idxInput, 3) == T_types(idxDb));
            
            goodMatches = (angDiffs < angThr) & typeMatch;
            numGoodMatches = sum(goodMatches);
            
            if numGoodMatches >= 3
                % חישוב ציון
                geomScore = sum(exp(-dists(valid(goodMatches)).^2 / (2*sigmaDist^2)));
                
                linIdx = sub2ind([NI, NT], idxInput(goodMatches), idxDb(goodMatches));
                descVals = diffMat(linIdx);
                descScore = sum(exp(-descVals.^2 / (2*sigmaDesc^2)));
                
                avgQuality = (geomScore + descScore) / (2 * numGoodMatches);
                quantityFactor = 1 + log10(numGoodMatches); 
                currentScore = (avgQuality * numGoodMatches) * quantityFactor * 2.5;
                
                if currentScore > bestScore
                    bestScore = currentScore;
                    bestAlignedInput = [alignedI, I_pts(:,3), alignedAng];
                end
            end
        end
    end
    
    finalScore = bestScore;
    isMatch = (finalScore >= scoreThreshold);
end