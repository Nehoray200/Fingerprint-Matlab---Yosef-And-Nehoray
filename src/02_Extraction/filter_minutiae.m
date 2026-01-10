function cleanList = filter_minutiae(minutiaeList, roiMask, cfg)
    % filter_minutiae - סינון מתקדם עם מחיקת גבולות אגרסיבית (Erosion)
    
    if isempty(minutiaeList)
        cleanList = [];
        return;
    end
    
    [rows, cols] = size(roiMask);
    
    %% שלב 1: מחיקת "אפקט המסגרת" (Boundary Effect Removal)
    % הבעיה: בקצה המסיכה, השלד נחתך ויוצר נקודות סיום מזויפות.
    % הפתרון: יצירת מסיכה פנימית קטנה יותר. רק נקודות בתוכה יישמרו.
    
    % קובעים שוליים רחבים (לפחות 15 פיקסלים, מומלץ 20)
    margin = cfg.filter.border_margin;
    if margin < 15, margin = 15; end 
    
    % ביצוע Erosion (שחיקה) למסיכה - זה מקטין את הלבן מכל הכיוונים
    se = strel('disk', margin);
    innerMask = imerode(roiMask, se);
    
    % וידוא שהמסגרת החיצונית של התמונה שחורה לחלוטין (למקרה שהמסיכה נגעה בקצה)
    innerMask(1:margin, :) = 0;
    innerMask(end-margin:end, :) = 0;
    innerMask(:, 1:margin) = 0;
    innerMask(:, end-margin:end) = 0;
    
    % --- סינון הנקודות לפי המסיכה הפנימית ---
    % המרת קואורדינטות (X,Y) לאינדקסים
    X = round(minutiaeList(:, 1));
    Y = round(minutiaeList(:, 2));
    
    % הגנה מחריגה בגבולות (Clamping)
    X = max(1, min(X, cols));
    Y = max(1, min(Y, rows));
    
    indices = sub2ind([rows, cols], Y, X);
    
    % השאר רק נקודות שנמצאות על הלבן במסיכה ה*פנימית*
    keepIdx = innerMask(indices);
    currentList = minutiaeList(keepIdx, :);
    
    if isempty(currentList), cleanList = []; return; end

    %% שלב 2: סינון גיאומטרי (מרחקים קצרים, גשרים, וקוצים)
    % הקוד הזה נשאר זהה לקוד המקורי שלך כי הוא נכון מתמטית
    
    numPts = size(currentList, 1);
    to_remove = false(numPts, 1);
    
    shortDistSq = cfg.filter.max_short_ridge_dist^2; 
    bridgeDistSq = cfg.filter.max_bridge_dist^2;          
    spikeDistSq = cfg.filter.max_spike_dist^2; 
    angTol = cfg.filter.angle_tolerance;
    
    % חישוב מרחקים מהיר (מטריצת מרחקים)
    % זה חוסך לולאות כפולות ומאיץ את הקוד משמעותית
    coords = currentList(:, 1:2);
    distMatSq = (coords(:,1) - coords(:,1)').^2 + (coords(:,2) - coords(:,2)').^2;
    
    % איפוס האלכסון (מרחק מעצמו) לאינסוף כדי לא להפריע
    distMatSq(logical(eye(numPts))) = inf;
    
    for i = 1:numPts
        if to_remove(i), continue; end
        
        type1 = currentList(i, 3);
        ang1 = currentList(i, 4);
        
        % מצא שכנים קרובים שחשודים כרעש
        neighbors = find(distMatSq(i, :) < max([shortDistSq, bridgeDistSq, spikeDistSq]));
        
        for j = neighbors
            if to_remove(j) || j <= i, continue; end % j<=i מונע בדיקה כפולה
            
            type2 = currentList(j, 3);
            ang2 = currentList(j, 4);
            distSq = distMatSq(i, j);
            
            % א. זיהוי שבר (Short Ridge): שתי סיומות קרובות שמביטות זו לזו
            if type1 == 1 && type2 == 1 && distSq < shortDistSq
                angleDiff = abs(mod(ang1 - ang2 + pi, 2*pi) - pi); 
                % אם הזוויות הפוכות (בערך 180 מעלות), זה שבר בקו
                if abs(angleDiff - pi) < angTol || abs(angleDiff + pi) < angTol 
                    to_remove(i) = true; to_remove(j) = true;
                end
            
            % ב. זיהוי גשר (Bridge): שני פיצולים קרובים
            elseif type1 == 3 && type2 == 3 && distSq < bridgeDistSq
                to_remove(i) = true; to_remove(j) = true;
                
            % ג. זיהוי קוץ (Spike): סיומת שמחוברת לפיצול קרוב
            elseif ((type1 == 1 && type2 == 3) || (type1 == 3 && type2 == 1)) && distSq < spikeDistSq
                to_remove(i) = true; to_remove(j) = true;
            end
            
            if to_remove(i), break; end
        end
    end
    
    currentList(to_remove, :) = [];
    
    %% שלב 3: ניקוי צפיפות סופי (Spacial Clean)
    if ~isempty(currentList)
        minDistSq = cfg.filter.min_distance^2;
        
        % חישוב מחודש של מרחקים לרשימה הנקייה
        coords = currentList(:, 1:2);
        distMatSq = (coords(:,1) - coords(:,1)').^2 + (coords(:,2) - coords(:,2)').^2;
        distMatSq(logical(eye(size(distMatSq,1)))) = inf;
        
        % מחיקת נקודות שקרובות מדי אחת לשניה (משאירים רק אחת)
        [row, col] = find(distMatSq < minDistSq);
        % מחיקת השני בזוג באופן נאיבי כדי לדלל
        remove_close = row(row > col); 
        
        currentList(remove_close, :) = [];
        cleanList = currentList;
    else
        cleanList = [];
    end
end