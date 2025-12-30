function [finalScore, bestAlignedInput, isMatch] = find_best_match(templateData, inputData, manualThreshold)
    % find_best_match - גרסה עצמאית (ללא צורך ב-Toolboxes)
    
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
    
    distThrSq = cfg.match.max_dist^2;
    angThr = cfg.match.max_ang_rad;
    sigmaDist = cfg.score.sigma_dist;
    sigmaDesc = cfg.score.sigma_desc;
    
    % --- שלב 1: מציאת מועמדים ---
    NI = size(I_pts, 1); NT = size(T_pts, 1);
    
    % חישוב ידני של מטריצת מרחקים בין Descriptors (במקום pdist2)
    diffMat = zeros(NI, NT);
    for i = 1:NI
        d = I_desc(i,:) - T_desc; 
        diffMat(i,:) = sqrt(sum(d.^2, 2));
    end
    
    % בחירת המועמדים הטובים ביותר
    numCandidates = min(cfg.match.candidate_count, NI * NT);
    [~, sortIdx] = sort(diffMat(:), 'ascend');
    [candidateI, candidateJ] = ind2sub([NI, NT], sortIdx(1:numCandidates));
    
    bestScore = 0;
    bestAlignedInput = [];
    
    % --- שלב 2: לולאת יישור ---
    for k = 1:numCandidates
        i = candidateI(k);
        j = candidateJ(k);
        
        % יישור לפי זוג אחד
        dTheta = T_pts(j,4) - I_pts(i,4);
        c = cos(dTheta); s = sin(dTheta);
        rotMat = [c -s; s c];
        
        centeredI = I_pts(:,1:2) - I_pts(i,1:2);
        rotatedI = centeredI * rotMat';
        alignedI = rotatedI + T_pts(j,1:2);
        
        alignedAng = mod(I_pts(:,4) + dTheta + pi, 2*pi) - pi;
        
        % --- החלפת knnsearch בחישוב ידני ---
        % לכל נקודה ב-alignedI, מוצאים את הכי קרובה ב-T_pts
        dists = zeros(NI, 1);
        idx = zeros(NI, 1);
        RefCoords = T_pts(:, 1:2);
        
        for q = 1:NI
            % חישוב מרחק לכל הנקודות במאגר
            diffs = RefCoords - alignedI(q, :);
            dsSq = sum(diffs.^2, 2); % מרחק בריבוע
            [minValSq, minIdx] = min(dsSq);
            dists(q) = sqrt(minValSq);
            idx(q) = minIdx;
        end
        % ------------------------------------
        
        % סינון התאמות טובות
        valid = dists < cfg.match.max_dist;
        
        if sum(valid) >= 3
            matchedIdxInput = find(valid);
            matchedIdxDb = idx(valid);
            
            angDiffs = abs(mod(alignedAng(matchedIdxInput) - T_pts(matchedIdxDb,4) + pi, 2*pi) - pi);
            typeMatch = (I_pts(matchedIdxInput,3) == T_pts(matchedIdxDb,3));
            
            goodMatches = (angDiffs < angThr) & typeMatch;
            
            if sum(goodMatches) > 0
                geomScore = sum(exp(-dists(valid).^2 / (2*sigmaDist^2)));
                
                linIdx = sub2ind([NI, NT], matchedIdxInput(goodMatches), matchedIdxDb(goodMatches));
                descVals = diffMat(linIdx);
                descScore = sum(exp(-descVals.^2 / (2*sigmaDesc^2)));
                
                currentScore = (geomScore * descScore) / (NI * NT) * 1000;
                
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