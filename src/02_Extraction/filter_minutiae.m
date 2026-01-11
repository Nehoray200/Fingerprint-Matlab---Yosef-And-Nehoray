function cleanList = filter_minutiae(minutiaeList, ~, cfg)
    % filter_minutiae - סינון עם פרמטר גבול דינאמי מהקונפיג
    
    if isempty(minutiaeList)
        cleanList = [];
        return;
    end
    
    %% שלב 1: זיהוי גבולות ענן הנקודות
    pts = minutiaeList(:, 1:2);
    x = pts(:, 1);
    y = pts(:, 2);
    
    % קריאת רגישות הגבול מהקונפיג (ברירת מחדל 0.5 אם לא מוגדר)
    if isfield(cfg.filter, 'boundary_shrink_factor')
        shrinkVal = cfg.filter.boundary_shrink_factor;
    else
        shrinkVal = 0.5; 
    end
    
    try
        % שימוש בערך מהקונפיג
        k = boundary(x, y, shrinkVal); 
    catch
        k = convhull(x, y);
    end
    
    boundaryPoints = pts(k, :);
    
    %% שלב 2: יצירת שכבת הגנה (Protection Layer)
    margin = cfg.filter.border_margin; 
    if margin < 15, margin = 15; end
    marginSq = margin^2;
    
    numPts = size(minutiaeList, 1);
    to_remove_boundary = false(numPts, 1);
    
    for i = 1:numPts
        dists = (boundaryPoints(:,1) - pts(i,1)).^2 + (boundaryPoints(:,2) - pts(i,2)).^2;
        if min(dists) < marginSq
            to_remove_boundary(i) = true;
        end
    end
    
    currentList = minutiaeList(~to_remove_boundary, :);
    
    if isempty(currentList), cleanList = []; return; end

    %% שלב 3: סינון גיאומטרי (נשאר ללא שינוי)
    numPts = size(currentList, 1);
    to_remove_geo = false(numPts, 1);
    
    shortDistSq = cfg.filter.max_short_ridge_dist^2; 
    bridgeDistSq = cfg.filter.max_bridge_dist^2;          
    spikeDistSq = cfg.filter.max_spike_dist^2; 
    angTol = cfg.filter.angle_tolerance;
    
    coords = currentList(:, 1:2);
    distMatSq = (coords(:,1) - coords(:,1)').^2 + (coords(:,2) - coords(:,2)').^2;
    distMatSq(logical(eye(numPts))) = inf;
    
    for i = 1:numPts
        if to_remove_geo(i), continue; end
        type1 = currentList(i, 3);
        ang1 = currentList(i, 4);
        neighbors = find(distMatSq(i, :) < max([shortDistSq, bridgeDistSq, spikeDistSq]));
        
        for j = neighbors
            if to_remove_geo(j) || j <= i, continue; end
            type2 = currentList(j, 3);
            ang2 = currentList(j, 4);
            distSq = distMatSq(i, j);
            
            if type1 == 1 && type2 == 1 && distSq < shortDistSq
                angleDiff = abs(mod(ang1 - ang2 + pi, 2*pi) - pi); 
                if abs(angleDiff - pi) < angTol || abs(angleDiff + pi) < angTol 
                    to_remove_geo(i) = true; to_remove_geo(j) = true;
                end
            elseif type1 == 3 && type2 == 3 && distSq < bridgeDistSq
                to_remove_geo(i) = true; to_remove_geo(j) = true;
            elseif ((type1 == 1 && type2 == 3) || (type1 == 3 && type2 == 1)) && distSq < spikeDistSq
                to_remove_geo(i) = true; to_remove_geo(j) = true;
            end
            if to_remove_geo(i), break; end
        end
    end
    currentList(to_remove_geo, :) = [];
    
    %% שלב 4: ניקוי צפיפות סופי
    if ~isempty(currentList)
        minDistSq = cfg.filter.min_distance^2;
        coords = currentList(:, 1:2);
        distMatSq = (coords(:,1) - coords(:,1)').^2 + (coords(:,2) - coords(:,2)').^2;
        distMatSq(logical(eye(size(distMatSq,1)))) = inf;
        [row, col] = find(distMatSq < minDistSq);
        remove_close = row(row > col); 
        currentList(remove_close, :) = [];
        cleanList = currentList;
    else
        cleanList = [];
    end
end