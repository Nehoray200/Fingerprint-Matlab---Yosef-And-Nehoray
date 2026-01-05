function [finalScore, bestAlignedInput, isMatch] = find_best_match(templateData, inputData, manualThreshold)
    % find_best_match - משווה בין שתי תבניות ומחזירה ציון התאמה
    
    T_pts = templateData.minutiae;
    T_desc = templateData.descriptors;
    I_pts = inputData.minutiae;
    I_desc = inputData.descriptors;
    
    cfg = get_config();
    scoreThreshold = cfg.match.pass_threshold;
    if nargin >= 3 && manualThreshold > 0, scoreThreshold = manualThreshold; end
    
    % בדיקת שפיות
    if size(T_pts,1) < 5 || size(I_pts,1) < 5
        finalScore = 0; bestAlignedInput=[]; isMatch=false; return;
    end
    
    angThr = cfg.match.max_ang_rad;
    sigmaDist = cfg.score.sigma_dist;
    sigmaDesc = cfg.score.sigma_desc;
    
    % --- שלב 1: מציאת מועמדים ---
    NI = size(I_pts, 1); NT = size(T_pts, 1);
    
    % מטריצת מרחקים בין דסקריפטורים
    diffMat = zeros(NI, NT);
    for i = 1:NI
        d = I_desc(i,:) - T_desc; 
        diffMat(i,:) = sqrt(sum(d.^2, 2));
    end
    
    numCandidates = min(cfg.match.candidate_count, NI * NT);
    [~, sortIdx] = sort(diffMat(:), 'ascend');
    [candidateI, candidateJ] = ind2sub([NI, NT], sortIdx(1:numCandidates));
    
    bestScore = 0;
    bestAlignedInput = [];
    
    % --- שלב 2: לולאת יישור ---
    for k = 1:numCandidates
        i = candidateI(k);
        j = candidateJ(k);
        
        % יישור (Alignment) לפי ההפרש הזוויתי והמיקום של הזוג הנבחר
        dTheta = T_pts(j,4) - I_pts(i,4);
        c = cos(dTheta); s = sin(dTheta);
        rotMat = [c -s; s c];
        
        centeredI = I_pts(:,1:2) - I_pts(i,1:2);
        rotatedI = centeredI * rotMat';
        alignedI = rotatedI + T_pts(j,1:2);
        
        alignedAng = mod(I_pts(:,4) + dTheta + pi, 2*pi) - pi;
        
        % מציאת השכן הקרוב ביותר לכל נקודה
        dists = zeros(NI, 1);
        idx = zeros(NI, 1);
        RefCoords = T_pts(:, 1:2);
        
        for q = 1:NI
            diffs = RefCoords - alignedI(q, :);
            dsSq = sum(diffs.^2, 2); 
            [minValSq, minIdx] = min(dsSq);
            dists(q) = sqrt(minValSq);
            idx(q) = minIdx;
        end
        
        % סינון נקודות שרחוקות מדי
        valid = dists < cfg.match.max_dist;
        
        % דורשים לפחות 3 נקודות תואמות כדי לחשב ציון
        if sum(valid) >= 3
            matchedIdxInput = find(valid);
            matchedIdxDb = idx(valid);
            
            % בדיקת זווית וסוג לכל זוג
            angDiffs = abs(mod(alignedAng(matchedIdxInput) - T_pts(matchedIdxDb,4) + pi, 2*pi) - pi);
            typeMatch = (I_pts(matchedIdxInput,3) == T_pts(matchedIdxDb,3));
            
            goodMatches = (angDiffs < angThr) & typeMatch;
            
            numGoodMatches = sum(goodMatches);
            
            if numGoodMatches > 0
                % חישוב ציונים חלקיים (גאוס)
                geomScore = sum(exp(-dists(valid(goodMatches)).^2 / (2*sigmaDist^2)));
                
                linIdx = sub2ind([NI, NT], matchedIdxInput(goodMatches), matchedIdxDb(goodMatches));
                descVals = diffMat(linIdx);
                descScore = sum(exp(-descVals.^2 / (2*sigmaDesc^2)));
                
                % === השינוי: נרמול חכם ===
                % במקום לחלק במכפלה (NI*NT), אנו מנרמלים לפי כמות הנקודות בפועל.
                % הנוסחה הזו נותנת משקל לכמות ההתאמות ולטיב שלהן.
                
                % ממוצע האיכות (0-1) של ההתאמות שנמצאו
                avgQuality = (geomScore + descScore) / (2 * numGoodMatches);
                
                % הציון הוא שילוב של איכות וכמות.
                % כמות: כמה נקודות תאמו מתוך המקסימום האפשרי (הקטן מבין השניים)
                matchRatio = numGoodMatches / min(NI, NT); 
                
                % ציון סופי (פקטור 100 כדי שיהיה קריא)
                % אנו מעלים בריבוע כדי להעניש התאמות חלשות
                currentScore = (avgQuality * matchRatio^2) * 100 * (numGoodMatches / 5); 
                
                % הסבר לתיקון האחרון (numGoodMatches/5): 
                % זה בונוס ליניארי לכמות. אם יש הרבה נקודות, הציון יעלה משמעותית.
                
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