function transformedList = transform_minutiae(minutiaeList, dTheta, dX, dY)
    % transform_minutiae - מבצעת מניפולציה גיאומטרית על רשימת נקודות
    % קלט: רשימת נקודות, זווית סיבוב (רדיאנים), והזזה ב-X וב-Y
    
    if isempty(minutiaeList)
        transformedList = [];
        return;
    end
    
    transformedList = minutiaeList; % מעתיקים את המבנה
    
    c = cos(dTheta);
    s = sin(dTheta);
    
    % חישוב וקטורי מהיר (בלי לולאות)
    X = minutiaeList(:, 1);
    Y = minutiaeList(:, 2);
    Angles = minutiaeList(:, 4);
    
    % 1. נוסחת הסיבוב (סביב הראשית 0,0)
    X_rot = X * c - Y * s;
    Y_rot = X * s + Y * c;
    
    % 2. הוספת ההזזה
    transformedList(:, 1) = X_rot + dX;
    transformedList(:, 2) = Y_rot + dY;
    
    % 3. עדכון הזווית של המינוציה עצמה (גם היא מסתובבת)
    % שימוש ב-mod כדי לשמור על טווח -pi עד pi
    transformedList(:, 4) = mod(Angles + dTheta + pi, 2*pi) - pi;
end