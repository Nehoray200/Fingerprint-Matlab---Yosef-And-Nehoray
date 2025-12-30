function cleanList = filter_minutiae(minutiaeList, roiMask)
    % filter_minutiae - סינון נקודות לפי מסיכה ולפי מרחק (מקושר לקונפיג)
    % קלט: רשימת נקודות, ומסיכת ROI מוכנה
    
    if isempty(minutiaeList)
        cleanList = [];
        return;
    end
    
    % --- 1. טעינת הגדרות מקובץ config.m ---
    cfg = get_config();
    minDistance = cfg.filter.min_distance; % שימוש בערך מההגדרות (למשל 6)
    
    %% שלב 1: סינון לפי מסיכה (ROI)
    X = round(minutiaeList(:, 1)); % מעגלים למספר שלם
    Y = round(minutiaeList(:, 2));
    
    [rows, cols] = size(roiMask);
    
    % בדיקה שהנקודות בתוך גבולות התמונה (למניעת קריסה)
    valid_bounds = (X > 0) & (X <= cols) & (Y > 0) & (Y <= rows);
    
    % בדיקה מול המסיכה (ROI)
    valid_roi = false(size(X));
    
    if any(valid_bounds)
        % המרת קואורדינטות לאינדקס ליניארי לבדיקה מהירה
        indices = sub2ind([rows, cols], Y(valid_bounds), X(valid_bounds));
        valid_roi(valid_bounds) = roiMask(indices) == 1;
    end
    
    % משאירים רק את הנקודות שנמצאות בתוך האזור הלבן
    minutiaeList = minutiaeList(valid_roi, :);
    
    %% שלב 2: סינון מרחק (Distance Filter)
    % מסירים נקודות שקרובות מדי אחת לשניה (רעש)
    
    % מיון לפי סוג (מעדיפים לשמור פיצולים על פני סיומות במקרה של קונפליקט)
    [~, sortIdx] = sort(minutiaeList(:, 3), 'descend');
    minutiaeList = minutiaeList(sortIdx, :);
    
    numPoints = size(minutiaeList, 1);
    keep = true(numPoints, 1); % וקטור בוליאני: מי נשאר?
    
    for i = 1:numPoints
        if ~keep(i), continue; end % אם הנקודה כבר נמחקה, דלג
        
        % חישוב מרחק מהנקודה הנוכחית לכל השאר
        dists = sqrt((minutiaeList(:,1) - minutiaeList(i,1)).^2 + ...
                     (minutiaeList(:,2) - minutiaeList(i,2)).^2);
        
        % מציאת נקודות קרובות מדי (שאינן הנקודה עצמה)
        % כאן משתמשים ב-minDistance שהגיע מה-Config!
        too_close = (dists < minDistance) & (dists > 0);
        
        % מחיקת השכנים הקרובים
        keep(too_close) = false; 
    end
    
    % החזרת הרשימה הנקייה הסופית
    cleanList = minutiaeList(keep, :);
end