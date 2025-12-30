function cleanList = filter_minutiae(minutiaeList, roiMask)
    % filter_minutiae - גרסה משופרת: מתעלמת מנקודות על קצה המסיכה
    
    if isempty(minutiaeList)
        cleanList = [];
        return;
    end
    
    cfg = get_config();
    minDistSq = cfg.filter.min_distance^2; 
    margin    = cfg.filter.border_margin;  % המרווח שנגדיר בקונפיג (למשל 10 או 15)
    
    %% שלב 1: יצירת "אזור ביטחון" (Safe Zone)
    % הבעיה: החיתוך של המסיכה יוצר נקודות סיום מזויפות על הקצה.
    % הפתרון: אנחנו מכרסמים את המסיכה פנימה ב-'margin' פיקסלים.
    % כל נקודה שנופלת באזור שנמחק - נחשבת לא אמינה ונזרקת.
    
    if margin > 0
        se = strel('disk', margin);
        safeMask = imerode(roiMask, se);
    else
        safeMask = roiMask;
    end
    
    %% שלב 2: סינון לפי המסיכה הבטוחה
    X = round(minutiaeList(:, 1));
    Y = round(minutiaeList(:, 2));
    
    [rows, cols] = size(safeMask);
    
    % בדיקה שהנקודות בתוך גבולות התמונה
    valid_bounds = (X > 0) & (X <= cols) & (Y > 0) & (Y <= rows);
    
    valid_roi = false(size(X));
    if any(valid_bounds)
        indices = sub2ind([rows, cols], Y(valid_bounds), X(valid_bounds));
        % בודקים מול safeMask (המקורסם) ולא מול roiMask המקורי
        valid_roi(valid_bounds) = safeMask(indices) == 1;
    end
    
    minutiaeList = minutiaeList(valid_roi, :);
    
    %% שלב 3: סינון צפיפות (Distance Filter)
    % מחיקת נקודות קרובות מדי אחת לשניה
    
    % מיון כדי לתעדף סוגים (אופציונלי, עוזר ליציבות)
    [~, sortIdx] = sort(minutiaeList(:, 3), 'descend');
    minutiaeList = minutiaeList(sortIdx, :);
    
    numPoints = size(minutiaeList, 1);
    keep = true(numPoints, 1); 
    
    for i = 1:numPoints
        if ~keep(i), continue; end 
        
        distsSq = (minutiaeList(:,1) - minutiaeList(i,1)).^2 + ...
                  (minutiaeList(:,2) - minutiaeList(i,2)).^2;
        
        too_close = (distsSq < minDistSq) & (distsSq > 0);
        keep(too_close) = false; 
    end
    
    cleanList = minutiaeList(keep, :);
end