function descriptors = compute_descriptors(minutiae)
    % compute_descriptors - יצירת מתאר (Descriptor) לכל נקודת מינושה
    % גרסה עצמאית (ללא צורך ב-Statistics Toolbox)
    
    % קלט: minutiae - מטריצה N x 4 (x, y, type, theta)
    % פלט: descriptors - מטריצה N x K (כאשר K הוא מספר השכנים שנבדקים)
    
    numMinutiae = size(minutiae, 1);
    kNeighbors = 5; % מספר השכנים שישמרו בכל מתאר
    
    % אם אין מספיק נקודות, נחזיר מטריצה של אפסים
    if numMinutiae <= kNeighbors
        descriptors = zeros(numMinutiae, kNeighbors);
        return;
    end
    
    % חילוץ קואורדינטות (X, Y)
    x = minutiae(:, 1);
    y = minutiae(:, 2);
    
    % --- חישוב מטריצת מרחקים ידני (במקום pdist) ---
    % חישוב ההפרש בין כל X לכל X, ובין כל Y לכל Y
    % (משתמשים בטריק של מטריצות: וקטור עמודה פחות וקטור שורה יוצר מטריצה)
    dx = x - x.'; 
    dy = y - y.';
    
    % מרחק אוקלידי (פיתגורס): שורש של (dx בריבוע ועוד dy בריבוע)
    distMatrix = sqrt(dx.^2 + dy.^2);
    
    % --- המשך הקוד זהה לקודם ---
    descriptors = zeros(numMinutiae, kNeighbors);
    
    for i = 1:numMinutiae
        % שליפת המרחקים עבור הנקודה הנוכחית
        dists = distMatrix(i, :);
        
        % מיון המרחקים מהקטן לגדול
        sortedDists = sort(dists, 'ascend');
        
        % לוקחים את ה-K שכנים הקרובים (מתחילים מ-2 כי 1 הוא המרחק 0 לעצמה)
        nearestDists = sortedDists(2 : kNeighbors + 1);
        
        % שמירה
        descriptors(i, :) = nearestDists;
    end
end