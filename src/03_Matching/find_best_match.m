function [finalScore, bestAlignedInput, isMatch] = find_best_match(templateData, inputData, manualThreshold)
    % find_best_match - גרסה יציבה (Stable)
    % הוסרה בדיקת הסוג הקשוחה שהורידה את הדיוק.
    
    cfg = get_config();
    
    % שליפת הנתונים
    T_pts = templateData.minutiae;   
    T_desc = templateData.descriptors;
    I_pts = inputData.minutiae;      
    I_desc = inputData.descriptors;
    
    % קביעת סף
    scoreThreshold = cfg.match.pass_threshold;
    if nargin >= 3 && manualThreshold > 0, scoreThreshold = manualThreshold; end
    
    if size(T_pts,1) < 5 || size(I_pts,1) < 5
        finalScore = 0; bestAlignedInput=[]; isMatch=false; return;
    end
    
    angThr = cfg.match.max_ang_rad;
    sigmaDist = cfg.score.sigma_dist;
    sigmaDesc = cfg.score.sigma_desc;
    
    % שימוש בחישוב מהיר של T_sq מהמאגר
    if isfield(templateData, 'T_sq') && ~isempty(templateData.T_sq)
        T_sq = templateData.T_sq;
    else
        T_sq = sum(T_pts(:, 1:2).^2, 2); 
    end
    
    % שלב 1: מציאת מועמדים
    NI = size(I_pts, 1); 
    NT = size(T_pts, 1);
    
    % חישוב מרחקים בין דסקריפטורים
    diffMat = zeros(NI, NT);
    for i = 1:NI
        d = I_desc(i,:) - T_desc; 
        diffMat(i,:) = sum(d.^2, 2); 
    end
    diffMat = sqrt(diffMat);
    
    [~, sortIdx] = sort(diffMat(:), 'ascend');
    
    % לקיחת המועמדים הכי טובים
    numCandidates = min(cfg.match.candidate_count, NI * NT);
    [candidateI, candidateJ] = ind2sub([NI, NT], sortIdx(1:numCandidates));
    
    bestScore = 0;
    bestAlignedInput = [];
    
    % שלב 2: לולאת יישור (ללא סינון סוג קשוח!)
    for k = 1:numCandidates
        i = candidateI(k); 
        j = candidateJ(k); 
        
        % חישוב זווית והזזה
        dTheta = T_pts(j, 4) - I_pts(i, 4);
        dX = T_pts(j, 1) - I_pts(i, 1); 
        dY = T_pts(j, 2) - I_pts(i, 2);
        centerPoint = [I_pts(i, 1), I_pts(i, 2)];
        
        % ביצוע הטרנספורמציה (עם הפונקציה המתוקנת שלנו)
        alignedData = transform_minutiae(I_pts, dTheta, dX, dY, centerPoint);
        alignedCoords = alignedData(:, 1:2);
        alignedAng = alignedData(:, 4);
        
        % חישוב מרחקים מטריציוני מהיר
        I_sq = sum(alignedCoords.^2, 2)'; 
        distMatSq = bsxfun(@plus, T_sq, I_sq) - 2 * (T_pts(:,1:2) * alignedCoords');
        
        [minValsSq, matchIndices] = min(distMatSq, [], 1);
        dists = sqrt(max(minValsSq, 0))'; 
        matchIndices = matchIndices';
        
        % סינון התאמות
        valid = dists < cfg.match.max_dist;
        
        if sum(valid) >= 3
            idxInput = find(valid);
            idxDb = matchIndices(valid);
            
            % כאן בודקים סוג רק לצורך ניקוד, לא לפסילה גורפת!
            angDiffs = abs(mod(alignedAng(idxInput) - T_pts(idxDb, 4) + pi, 2*pi) - pi);
            typeMatch = (I_pts(idxInput, 3) == T_pts(idxDb, 3));
            
            goodMatches = (angDiffs < angThr) & typeMatch;
            numGoodMatches = sum(goodMatches);
            
            if numGoodMatches >= 3
                geomScore = sum(exp(-dists(valid(goodMatches)).^2 / (2*sigmaDist^2)));
                
                linIdx = sub2ind([NI, NT], idxInput(goodMatches), idxDb(goodMatches));
                descVals = diffMat(linIdx);
                descScore = sum(exp(-descVals.^2 / (2*sigmaDesc^2)));
                
                avgQuality = (geomScore + descScore) / (2 * numGoodMatches);
                quantityFactor = 1 + log10(numGoodMatches); 
                
                currentScore = (avgQuality * numGoodMatches) * quantityFactor * 2.5;
                
                if currentScore > bestScore
                    bestScore = currentScore;
                    bestAlignedInput = alignedData; 
                end
            end
        end
    end
    
    finalScore = bestScore;
    isMatch = (finalScore >= scoreThreshold);
end