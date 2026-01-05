function descriptors = compute_descriptors(minutiae, cfg)
    % compute_descriptors - יצירת מתאר (Descriptor) לכל נקודת מינושה
    % גרסה עצמאית (ללא צורך ב-Statistics Toolbox)
    
    % קלט: 
    %   minutiae - מטריצה N x 4 (x, y, type, theta)
    %   cfg      - מבנה ההגדרות (מכיל את feature.descriptor_k)
    % פלט: 
    %   descriptors - מטריצה N x K
    
    % בדיקת קלט (הגנה למקרה ששכחנו להגדיר בקונפיג)
    if nargin < 2 || ~isfield(cfg.feature, 'descriptor_k')
        kNeighbors = 5; % ברירת מחדל
    else
        kNeighbors = cfg.feature.descriptor_k;
    end
    
    numMinutiae = size(minutiae, 1);
    
    % אם אין מספיק נקודות, נחזיר מטריצה של אפסים
    % (חייבים לפחות K+1 נקודות כי הנקודה עצמה לא נחשבת שכן של עצמה)
    if numMinutiae <= kNeighbors
        descriptors = zeros(numMinutiae, kNeighbors);
        return;
    end
    
    % חילוץ קואורדינטות (X, Y)
    x = minutiae(:, 1);
    y = minutiae(:, 2);
    
    % --- חישוב מטריצת מרחקים ידני (במקום pdist) ---
    dx = x - x.'; 
    dy = y - y.';
    
    % מרחק אוקלידי
    distMatrix = sqrt(dx.^2 + dy.^2);
    
    % --- יצירת המתארים ---
    descriptors = zeros(numMinutiae, kNeighbors);
    
    for i = 1:numMinutiae
        % שליפת המרחקים עבור הנקודה הנוכחית
        dists = distMatrix(i, :);
        
        % מיון המרחקים מהקטן לגדול
        sortedDists = sort(dists, 'ascend');
        
        % לוקחים את ה-K שכנים הקרובים 
        % (מתחילים מאינדקס 2, כי אינדקס 1 הוא המרחק 0 של הנקודה לעצמה)
        nearestDists = sortedDists(2 : kNeighbors + 1);
        
        % שמירה
        descriptors(i, :) = nearestDists;
    end
end