function cleanList = filter_minutiae(minutiaeList, roiMask, cfg)
    % filter_minutiae - גרסה מתוקנת שמקבלת את cfg מבחוץ
    
    if isempty(minutiaeList)
        cleanList = [];
        return;
    end
    
    % cfg = get_config(); % <-- שורה זו מיותרת כעת כי קיבלנו את cfg כפרמטר
    
    % --- שלב 1: ניקוי שוליים (לפי מרחק אוקלידי) ---
    margin = cfg.filter.border_margin; 
    
    % חישוב מרחק מדויק מהקצה
    maskFilled = imfill(roiMask, 'holes');
    distMap = bwdist(~maskFilled);
    
    % בדיקת מיקום הנקודות
    X = round(minutiaeList(:, 1));
    Y = round(minutiaeList(:, 2));
    [rows, cols] = size(distMap);
    
    X = max(1, min(X, cols));
    Y = max(1, min(Y, rows));
    
    indices = sub2ind([rows, cols], Y, X);
    pointDistances = distMap(indices);
    
    % שמירה רק של מה שרחוק מהקצה
    keep_mask = pointDistances > margin;
    cleanList = minutiaeList(keep_mask, :);
    
    % --- שלב 2: ניקוי כפילויות ---
    if ~isempty(cleanList)
        % אנחנו נגדיר מרחק מינימלי קטן. כל מה שקרוב יותר מזה - יאוחד.
        minDistSq = cfg.filter.min_distance^2;
        
        % מיון כדי לשמור על סדר אחיד
        [~, sortIdx] = sort(cleanList(:, 3), 'descend');
        cleanList = cleanList(sortIdx, :);
        
        numPoints = size(cleanList, 1);
        keep = true(numPoints, 1);
        
        for i = 1:numPoints
            if ~keep(i), continue; end
            
            % חישוב מרחק מול כל שאר הנקודות ברשימה
            distsSq = (cleanList(:,1) - cleanList(i,1)).^2 + ...
                      (cleanList(:,2) - cleanList(i,2)).^2;
            
            % אם מצאנו שכנים קרובים מדי (אבל לא הנקודה עצמה) -> נמחק אותם
            too_close = (distsSq < minDistSq) & (distsSq > 0);
            keep(too_close) = false;
        end
        
        cleanList = cleanList(keep, :);
    end
end