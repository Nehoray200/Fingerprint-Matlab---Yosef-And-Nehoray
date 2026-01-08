function [finalScore, bestAlignedInput, isMatch] = find_best_match(templateData, inputData, manualThreshold)
    % find_best_match - השוואה גיאומטרית וחישוב ציון התאמה משוקלל (Optimized)
    
    T_pts = templateData.minutiae;
    T_desc = templateData.descriptors;
    I_pts = inputData.minutiae;
    I_desc = inputData.descriptors;
    
    cfg = get_config();
    scoreThreshold = cfg.match.pass_threshold;
    if nargin >= 3 && manualThreshold > 0, scoreThreshold = manualThreshold; end
    
    % בדיקת שפיות: אם אין מספיק נקודות, אין טעם להשוות
    if size(T_pts,1) < 5 || size(I_pts,1) < 5
        finalScore = 0; bestAlignedInput=[]; isMatch=false; return;
    end
    
    angThr = cfg.match.max_ang_rad;
    sigmaDist = cfg.score.sigma_dist;
    sigmaDesc = cfg.score.sigma_desc;
    
    % --- שלב 1: מציאת מועמדים ליישור (Alignment Candidates) ---
    NI = size(I_pts, 1); NT = size(T_pts, 1);
    
    % חישוב מרחק בין הדסקריפטורים של כל הנקודות
    diffMat = zeros(NI, NT);
    for i = 1:NI
        d = I_desc(i,:) - T_desc; 
        diffMat(i,:) = sqrt(sum(d.^2, 2));
    end
    
    % בחירת הזוגות הסבירים ביותר להתחלת היישור
    numCandidates = min(cfg.match.candidate_count, NI * NT);
    [~, sortIdx] = sort(diffMat(:), 'ascend');
    [candidateI, candidateJ] = ind2sub([NI, NT], sortIdx(1:numCandidates));
    
    bestScore = 0;
    bestAlignedInput = [];
    
    % --- שלב 2: לולאת יישור ובדיקה ---
    for k = 1:numCandidates
        i = candidateI(k);
        j = candidateJ(k);
        
        % חישוב פרמטרי היישור (הזזה וסיבוב) לפי הזוג הנוכחי
        dTheta = T_pts(j,4) - I_pts(i,4);
        c = cos(dTheta); s = sin(dTheta);
        rotMat = [c -s; s c];
        
        % ביצוע היישור על כל נקודות הקלט
        centeredI = I_pts(:,1:2) - I_pts(i,1:2);
        rotatedI = centeredI * rotMat';
        alignedI = rotatedI + T_pts(j,1:2);
        
        % יישור הזוויות
        alignedAng = mod(I_pts(:,4) + dTheta + pi, 2*pi) - pi;
        
        % מציאת השכן הקרוב ביותר במאגר לכל נקודה מיושרת
        % (אופטימיזציה קטנה: אין צורך במטריצה מלאה, עושים שורה שורה)
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
        
        % סינון ראשוני לפי מרחק מקסימלי מותר
        valid = dists < cfg.match.max_dist;
        
        % דורשים מינימום 3 נקודות תואמות כדי להתייחס לתוצאה ברצינות
        if sum(valid) >= 3
            matchedIdxInput = find(valid);
            matchedIdxDb = idx(valid);
            
            % בדיקה שנייה: התאמת זווית וסוג מינושיה
            angDiffs = abs(mod(alignedAng(matchedIdxInput) - T_pts(matchedIdxDb,4) + pi, 2*pi) - pi);
            typeMatch = (I_pts(matchedIdxInput,3) == T_pts(matchedIdxDb,3));
            
            goodMatches = (angDiffs < angThr) & typeMatch;
            numGoodMatches = sum(goodMatches);
            
            % דרושות לפחות 3 התאמות חזקות (כולל זווית וסוג) כדי לחשב ניקוד
            if numGoodMatches >= 3
                % --- חישוב הציון המשופר ---
                
                % 1. חישוב איכות גיאומטרית (לפי מרחק)
                geomScore = sum(exp(-dists(valid(goodMatches)).^2 / (2*sigmaDist^2)));
                
                % 2. חישוב איכות דסקריפטורים (לפי דמיון סביבתי)
                linIdx = sub2ind([NI, NT], matchedIdxInput(goodMatches), matchedIdxDb(goodMatches));
                descVals = diffMat(linIdx);
                descScore = sum(exp(-descVals.^2 / (2*sigmaDesc^2)));
                
                % 3. שקלול סופי:
                % avgQuality: מדד בין 0 ל-1 שמייצג כמה ה"פיט" (Fit) מדויק
                avgQuality = (geomScore + descScore) / (2 * numGoodMatches);
                
                % === השינוי בנוסחה ===
                % הנוסחה הישנה הסתמכה על matchRatio שהעניש חיתוכים חלקיים.
                % הנוסחה החדשה: (איכות * כמות) * פקטור לוגריתמי
                
                % פקטור בונוס: מעודד כמות גדולה של נקודות בצורה מתונה (Log scale)
                % הוספנו +1 כדי שגם עבור מעט נקודות זה לא יאפס את הציון
                quantityFactor = 1 + log10(numGoodMatches); 
                
                % הציון הסופי:
                % avgQuality * numGoodMatches = הסכום האפקטיבי של הנקודות הטובות
                % כפול ה-quantityFactor נותן בונוס על אמינות סטטיסטית
                % כפול 2.5 כדי להביא את המספרים לטווח דומה למה שהוגדר ב-CONFIG (סביב 10-20 להצלחה)
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