function transformedList = transform_minutiae(minutiaeList, dTheta, dX, dY, centerPoint)
    % transform_minutiae - מבצעת מניפולציה גיאומטרית
    % כעת תומכת בסיבוב סביב נקודה ספציפית (centerPoint)
    
    if isempty(minutiaeList)
        transformedList = [];
        return;
    end
    
    if nargin < 5 || isempty(centerPoint)
        cx = 0; cy = 0; % ברירת מחדל: סיבוב סביב הראשית (כמו קודם)
    else
        cx = centerPoint(1); cy = centerPoint(2);
    end
    
    transformedList = minutiaeList; 
    
    c = cos(dTheta);
    s = sin(dTheta);
    
    X = minutiaeList(:, 1);
    Y = minutiaeList(:, 2);
    Angles = minutiaeList(:, 4);
    
    % 1. הזזה לראשית (ביחס לנקודת המרכז)
    X = X - cx;
    Y = Y - cy;
    
    % 2. סיבוב
    X_rot = X * c - Y * s;
    Y_rot = X * s + Y * c;
    
    % 3. החזרה למקום + הזזה גלובלית
    transformedList(:, 1) = X_rot + cx + dX;
    transformedList(:, 2) = Y_rot + cy + dY;
    
    % 4. עדכון זווית
    transformedList(:, 4) = mod(Angles + dTheta + pi, 2*pi) - pi;
end