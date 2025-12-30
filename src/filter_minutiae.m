function cleanList = filter_minutiae(minutiaeList, roiMask)
    % filter_minutiae - סינון נקודות לפי מסיכה ולפי מרחק (מקושר לקונפיג)
    % קלט: רשימת נקודות, ומסיכת ROI מוכנה
    
    if isempty(minutiaeList)
        cleanList = [];
        return;
    end
    
    % --- 1. טעינת הגדרות מקובץ config.m ---
    cfg = get_config();
    minDistSq = cfg.filter.min_distance^2; % עבודה עם מרחק בריבוע לביצועים
    margin    = cfg.filter.border_margin;  % שוליים ביטחון מקצה התמונה
    
    %% שלב 1: סינון לפי מסיכה (ROI) וגבולות תמונה
    X = round(minutiaeList(:, 1));
    Y = round(minutiaeList(:, 2));
    
    [rows, cols] = size(roiMask);
    
    % בדיקה שהנקודות בתוך גבולות התמונה + מרווח ביטחון (Margin)
    valid_bounds = (X > margin) & (X <= cols - margin) & ...
                   (Y > margin) & (Y <= rows - margin);
    
    % בדיקה מול המסיכה (ROI) - רק עבור נקודות שבתוך הגבולות
    valid_roi = false(size(X));
    
    if any(valid_bounds)
        % המרת קואורדינטות לאינדקס ליניארי
        indices = sub2ind([rows, cols], Y(valid_bounds), X(valid_bounds));
        valid_roi(valid_bounds) = roiMask(indices) == 1;
    end
    
    % עדכון הרשימה: רק נקודות חוקיות נשארות
    minutiaeList = minutiaeList(valid_roi, :);
    
    %% שלב 2: סינון צפיפות (Distance Filter)
    % הסרת נקודות שקרובות מדי אחת לשניה (רעש)
    
    % מיון לפי סוג (כדי לתת עדיפות לסוגים מסוימים אם צריך, או סתם לסדר)
    [~, sortIdx] = sort(minutiaeList(:, 3), 'descend');
    minutiaeList = minutiaeList(sortIdx, :);
    
    numPoints = size(minutiaeList, 1);
    keep = true(numPoints, 1); 
    
    for i = 1:numPoints
        if ~keep(i), continue; end 
        
        % חישוב מרחק בריבוע (מהיר יותר מ-sqrt)
        distsSq = (minutiaeList(:,1) - minutiaeList(i,1)).^2 + ...
                  (minutiaeList(:,2) - minutiaeList(i,2)).^2;
        
        % מציאת נקודות קרובות מדי (שאינן הנקודה עצמה)
        too_close = (distsSq < minDistSq) & (distsSq > 0);
        
        % מחיקת השכנים הקרובים
        keep(too_close) = false; 
    end
    
    % התוצאה הסופית
    cleanList = minutiaeList(keep, :);
end