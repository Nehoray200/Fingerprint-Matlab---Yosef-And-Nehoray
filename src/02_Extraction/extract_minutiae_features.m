function minutiaeData = extract_minutiae_features(skeletonImage, cfg)
    % extract_minutiae_features - גרסה מואצת (Optimized)
    % משתמשת בפונקציות C++ מובנות של MATLAB לזיהוי מהיר של נקודות
    
    %% 1. נרמול ושיפור השלד
    skeletonImage = logical(skeletonImage);
    
    % בדיקת היפוך צבעים (אם הרקע לבן - נהפוך אותו)
    if sum(skeletonImage(:)) > numel(skeletonImage)/2
        skeletonImage = ~skeletonImage;
    end
    
    % ניקוי ודיקוק (כמו במקור)
    skeletonImage = bwmorph(skeletonImage, 'thin', Inf);
    skeletonImage = bwmorph(skeletonImage, 'clean'); % מסיר פיקסלים בודדים
    skeletonImage = bwmorph(skeletonImage, 'spur', 5); % מסיר קווים קצרצרים (זיזים)
    
    %% 2. זיהוי טופולוגי מהיר (במקום Crossing Number ידני)
    % הפונקציה bwmorph רצה ב-C++ ומבצעת את חישוב ה-CN לכל התמונה בבת אחת
    
    % מציאת סיומות (End points)
    bw_endings = bwmorph(skeletonImage, 'endpoints');
    [r_end, c_end] = find(bw_endings);
    
    % מציאת פיצולים (Branch points)
    bw_branches = bwmorph(skeletonImage, 'branchpoints');
    [r_bif, c_bif] = find(bw_branches);
    
    %% 3. איחוד המידע וחישוב זוויות
    numEnd = length(r_end);
    numBif = length(r_bif);
    
    % הקצאה מראש מדויקת (אין צורך בניחוש גודל)
    minutiaeData = zeros(numEnd + numBif, 4);
    
    % --- עיבוד סיומות (Type = 1) ---
    for i = 1:numEnd
        % חישוב זווית רק לנקודות שנמצאו
        angle = calculate_orientation_reliable(skeletonImage, r_end(i), c_end(i), cfg);
        minutiaeData(i, :) = [c_end(i), r_end(i), 1, angle];
    end
    
    % --- עיבוד פיצולים (Type = 3) ---
    for i = 1:numBif
        angle = calculate_orientation_reliable(skeletonImage, r_bif(i), c_bif(i), cfg);
        
        % הערה: המיקום של branchpoints ב-bwmorph הוא לפעמים פיקסל אחד ליד
        % הצומת האמיתי, אבל זה זניח לרוב השימושים.
        minutiaeData(numEnd + i, :) = [c_bif(i), r_bif(i), 3, angle];
    end
    
    % (אין צורך ב"חיתוך סופי" כי גודל המערך ידוע מראש ומדויק)
end

%% פונקציית עזר לחישוב זווית (ללא שינוי, כפי שביקשת)
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