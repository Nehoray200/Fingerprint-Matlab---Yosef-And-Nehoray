function cleanList = filter_minutiae(minutiaeList, roiMask, cfg)
    % filter_minutiae - מסנן רעשים: שוליים, צפיפות, שברים, גשרים וקוצים.
    
    if isempty(minutiaeList)
        cleanList = [];
        return;
    end
    
    % --- שלב 1: טיפול באפקט הגבול (Boundary Effects) ---
    % חישוב מרחק של כל פיקסל מהקצה השחור הקרוב ביותר של המסיכה
    margin = cfg.filter.border_margin; 
    maskFilled = imfill(roiMask, 'holes');
    
    % bwdist מחשב מרחק מהפיקסל ה-0 (הרקע) הקרוב ביותר
    distMap = bwdist(~maskFilled);
    
    X = round(minutiaeList(:, 1));
    Y = round(minutiaeList(:, 2));
    [rows, cols] = size(distMap);
    
    X = max(1, min(X, cols));
    Y = max(1, min(Y, rows));
    
    indices = sub2ind([rows, cols], Y, X);
    
    % שמירה רק של נקודות שנמצאות ב"אזור הבטוח" (רחוקות מהשוליים)
    keep_mask = distMap(indices) > margin;
    currentList = minutiaeList(keep_mask, :);
    
    if isempty(currentList), cleanList = []; return; end

    % --- שלב 2: סינון גיאומטרי מבני (Structural Post-processing) ---
    numPts = size(currentList, 1);
    to_remove = false(numPts, 1);
    
    % שליפת ספים בריבוע (לחישוב מרחק מהיר)
    shortRidgeDistSq = cfg.filter.max_short_ridge_dist^2; 
    bridgeDistSq     = cfg.filter.max_bridge_dist^2;          
    spikeDistSq      = cfg.filter.max_spike_dist^2; % סף חדש לקוצים
    angTol           = cfg.filter.angle_tolerance;
    
    for i = 1:numPts
        if to_remove(i), continue; end
        
        type1 = currentList(i, 3);
        x1 = currentList(i, 1);
        y1 = currentList(i, 2);
        ang1 = currentList(i, 4);
        
        for j = (i+1):numPts
            if to_remove(j), continue; end
            
            type2 = currentList(j, 3);
            x2 = currentList(j, 1);
            y2 = currentList(j, 2);
            ang2 = currentList(j, 4);
            
            distSq = (x1-x2)^2 + (y1-y2)^2;
            
            % ---------------------------------------------------------
            % מקרה א': רכס קצר / שבר (Ending <-> Ending)
            % ---------------------------------------------------------
            if type1 == 1 && type2 == 1
                if distSq < shortRidgeDistSq
                    % בודקים אם הם פונים זה מול זה (כ-180 מעלות הפרש)
                    angleDiff = abs(mod(ang1 - ang2 + pi, 2*pi) - pi); 
                    if abs(angleDiff - pi) < angTol || abs(angleDiff + pi) < angTol 
                        to_remove(i) = true;
                        to_remove(j) = true;
                        break; 
                    end
                end
            
            % ---------------------------------------------------------
            % מקרה ב': גשר / חור (Bifurcation <-> Bifurcation)
            % ---------------------------------------------------------
            elseif type1 == 3 && type2 == 3
                if distSq < bridgeDistSq
                    % שני פיצולים קרובים מאוד הם כמעט תמיד רעש
                    to_remove(i) = true;
                    to_remove(j) = true;
                    break; 
                end
                
            % ---------------------------------------------------------
            % מקרה ג': קוץ / זיז (Spike) (Ending <-> Bifurcation)
            % ---------------------------------------------------------
            % אחד הוא סוג 1 ואחד הוא סוג 3
            elseif (type1 == 1 && type2 == 3) || (type1 == 3 && type2 == 1)
                if distSq < spikeDistSq
                     % זיז קטן שיוצא מרכס: יוצר ביפורקציה ואז נגמר מיד
                    to_remove(i) = true;
                    to_remove(j) = true;
                    break;
                end
            end
        end
    end
    
    currentList(to_remove, :) = [];
    
    % --- שלב 3: ניקוי צפיפות סופי ---
    if ~isempty(currentList)
        minDistSq = cfg.filter.min_distance^2;
        [~, sortIdx] = sort(currentList(:, 2)); % מיון
        currentList = currentList(sortIdx, :);
        
        numPts = size(currentList, 1);
        keep = true(numPts, 1);
        
        for i = 1:numPts
            if ~keep(i), continue; end
            distsSq = (currentList(:,1) - currentList(i,1)).^2 + ...
                      (currentList(:,2) - currentList(i,2)).^2;
            too_close = (distsSq < minDistSq) & (distsSq > 0);
            keep(too_close) = false;
        end
        cleanList = currentList(keep, :);
    else
        cleanList = [];
    end
end