function cleanList = filter_minutiae(minutiaeList, roiMask)
    % filter_minutiae - גרסה אופטימלית ונקייה
    % מסנן נקודות שנמצאות מחוץ למסיכה ונקודות קרובות מדי
    
    if isempty(minutiaeList)
        cleanList = [];
        return;
    end
    
    % קבוע למרחק מינימלי
    minDistance = 6; 

    %% שלב 1: סינון לפי מסיכה (ROI) - ללא לולאה!
    % במקום לרוץ אחד-אחד, אנחנו בודקים את כולם בבת אחת
    
    X = round(minutiaeList(:, 1)); % מעגלים למספר שלם
    Y = round(minutiaeList(:, 2));
    
    [rows, cols] = size(roiMask);
    
    % 1. בדיקה שהנקודות בתוך גבולות התמונה (למניעת קריסה)
    valid_bounds = (X > 0) & (X <= cols) & (Y > 0) & (Y <= rows);
    
    % 2. בדיקה מול המסיכה (ממירים קואורדינטות לאינדקס ליניארי)
    % זו הפקודה שמחליפה את הלולאה הראשונה:
    valid_roi = false(size(X));
    
    % בודקים במסיכה רק את הנקודות שנמצאות בתוך הגבולות
    if any(valid_bounds)
        % sub2ind הופך (X,Y) לכתובת אחת בזיכרון
        indices = sub2ind([rows, cols], Y(valid_bounds), X(valid_bounds));
        valid_roi(valid_bounds) = roiMask(indices) == 1;
    end
    
    % משאירים רק את הנקודות התקינות
    minutiaeList = minutiaeList(valid_roi, :);
    
    %% שלב 2: סינון מרחק (Distance Filter)
    % כאן נשתמש בלולאה אחת בלבד כי הסינון הוא תלוי-תוצאה (Greedy)
    % אבל נכתוב אותה בצורה מסודרת
    
    % מיון לפי סוג (כדי שנעדיף לשמור פיצולים על פני סיומות)
    [~, sortIdx] = sort(minutiaeList(:, 3), 'descend');
    minutiaeList = minutiaeList(sortIdx, :);
    
    numPoints = size(minutiaeList, 1);
    keep = true(numPoints, 1); % וקטור בוליאני: מי נשאר?
    
    for i = 1:numPoints
        if ~keep(i), continue; end % אם הנקודה כבר נמחקה, דלג
        
        % חישוב מרחק מהנקודה הנוכחית (i) לכל שאר הנקודות ברשימה בבת אחת!
        dists = sqrt((minutiaeList(:,1) - minutiaeList(i,1)).^2 + ...
                     (minutiaeList(:,2) - minutiaeList(i,2)).^2);
        
        % מצא את אלו שקרובים מדי (אבל לא את הנקודה עצמה)
        too_close = (dists < minDistance) & (dists > 0);
        
        % מחק את השכנים הקרובים
        keep(too_close) = false; 
    end
    
    % התוצאה הסופית
    cleanList = minutiaeList(keep, :);
    
end