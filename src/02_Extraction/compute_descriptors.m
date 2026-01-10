function descriptors = compute_descriptors(minutiae, cfg)
    % compute_descriptors - גרסה וקטורית מואצת (Fully Vectorized)
    % מבוססת על מיון מטריציוני במקום לולאות.
    
    % בדיקת קלט
    if nargin < 2 || ~isfield(cfg.feature, 'descriptor_k')
        kNeighbors = 5; 
    else
        kNeighbors = cfg.feature.descriptor_k;
    end
    
    numMinutiae = size(minutiae, 1);
    
    % הגנה: אם אין מספיק נקודות
    if numMinutiae <= kNeighbors
        descriptors = zeros(numMinutiae, kNeighbors);
        return;
    end
    
    % חילוץ קואורדינטות
    x = minutiae(:, 1);
    y = minutiae(:, 2);
    
    % חישוב מטריצת מרחקים מלאה (N x N)
    % שימוש בזהות כפל מטריצות לחישוב מהיר: (x-x')^2 = x^2 - 2xx' + x'^2
    % (אופציונלי: הקוד הקודם עם bsxfun או חיסור ישיר גם בסדר, פה נשאר עם הפשוט והבטוח)
    dx = x - x.'; 
    dy = y - y.';
    distMatrix = sqrt(dx.^2 + dy.^2);
    
    % === הלב של האופטימיזציה ===
    % במקום לרוץ בלולאה על כל שורה ולמיין, ממיינים את כל המטריצה בבת אחת!
    % 2 אומר שממיינים לאורך השורות.
    sortedDists = sort(distMatrix, 2, 'ascend');
    
    % לוקחים את העמודות 2 עד K+1 (מדלגים על עמודה 1 שהיא המרחק 0 לעצמה)
    descriptors = sortedDists(:, 2 : kNeighbors + 1);
end