function minutiaeData = extract_minutiae_features(skeletonImage, cfg)
    % extract_minutiae_features - גרסה סופית ומתוקנת (עם Preallocation)
    % כוללת טיפול באלכסונים וחישוב זווית אמין
    
    %% 1. נרמול ושיפור השלד
    skeletonImage = logical(skeletonImage);
    
    % בדיקת היפוך צבעים (אם הרקע לבן - נהפוך אותו)
    if sum(skeletonImage(:)) > numel(skeletonImage)/2
        skeletonImage = ~skeletonImage;
    end
    
    % תיקון קריטי: שימוש ב-thin במקום clean
    skeletonImage = bwmorph(skeletonImage, 'thin', Inf);
    
    % ניקוי רעשים נוסף
    skeletonImage = bwmorph(skeletonImage, 'spur');
    
    %% 2. הכנה ללולאה (Preallocation - תיקון האזהרה)
    [H, W] = size(skeletonImage);
    
    % מוצאים את כל הפיקסלים הדלוקים
    [rows, cols] = find(skeletonImage);
    numPixels = length(rows);
    
    % === התיקון: הקצאת זיכרון מראש ===
    % במקרה הגרוע ביותר, כל פיקסל הוא נקודת עניין (לא באמת יקרה),
    % אז נקצה מערך בגודל המקסימלי האפשרי ונמלא אותו.
    minutiaeData = zeros(numPixels, 4); 
    count = 0; % מונה למספר הנקודות שמצאנו בפועל
    
    %% 3. אימות וסיווג (הלולאה הראשית)
    for k = 1:numPixels
        r = rows(k);
        c = cols(k);
        
        % דילוג על שוליים
        if r < 2 || c < 2 || r > H-1 || c > W-1
            continue;
        end
        
        % שליפת 8 השכנים במעגל (עם כיוון השעון)
        blk = skeletonImage(r-1:r+1, c-1:c+1);
        neighbors_circle = [blk(1,2), blk(1,3), blk(2,3), blk(3,3), ...
                            blk(3,2), blk(3,1), blk(2,1), blk(1,1), blk(1,2)];
                     
        % חישוב Crossing Number (CN)
        transitions = sum(abs(diff(double(neighbors_circle))));
        cn = transitions / 2;
        
        if cn == 1
            % === נקודת סיום (Ending) ===
            angle = calculate_orientation_reliable(skeletonImage, r, c, cfg);
            count = count + 1;
            minutiaeData(count, :) = [c, r, 1, angle];
            
        elseif cn == 3
            % === נקודת פיצול (Bifurcation) ===
            angle = calculate_orientation_reliable(skeletonImage, r, c, cfg);
            count = count + 1;
            minutiaeData(count, :) = [c, r, 3, angle];
        end
    end
    
    % === חיתוך סופי ===
    % זורקים את השורות המיותרות (האפסים) שנשארו בסוף המערך
    minutiaeData = minutiaeData(1:count, :);
end

%% פונקציית עזר לחישוב זווית (ללא שינוי)
function angle = calculate_orientation_reliable(img, r, c, cfg)
    % קבלת מספר הצעדים מהקונפיגורציה
    steps = cfg.feature.angle_steps;
    
    path_r = zeros(steps + 2, 1); 
    path_c = zeros(steps + 2, 1);
    
    path_r(1) = r; path_c(1) = c;
    
    for k = 1:steps
        curr_r = path_r(k); curr_c = path_c(k);
        foundNeighbor = false;
        
        for dr = -1:1
            for dc = -1:1
                if dr==0 && dc==0, continue; end
                nr = curr_r + dr; nc = curr_c + dc;
                
                [H, W] = size(img);
                if nr < 1 || nc < 1 || nr > H || nc > W, continue; end
                
                if img(nr, nc) == 1
                    if k > 1 && nr == path_r(k-1) && nc == path_c(k-1), continue; end
                    path_r(k+1) = nr; path_c(k+1) = nc;
                    foundNeighbor = true; break;
                end
            end
            if foundNeighbor, break; end
        end
        if ~foundNeighbor, break; end
    end
    
    last_idx = find(path_r ~= 0, 1, 'last');
    
    if last_idx > 1
        dy = path_r(last_idx) - path_r(1);
        dx = path_c(last_idx) - path_c(1);
        angle = atan2(dy, dx);
    else
        angle = 0;
    end
end