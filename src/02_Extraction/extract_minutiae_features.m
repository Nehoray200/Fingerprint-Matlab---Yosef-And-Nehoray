function minutiaeData = extract_minutiae_features(skeletonImage, roiMask, cfg)
    % extract_minutiae_features - גרסה מסננת (Mask-Aware)
    % הפונקציה מקבלת את המסיכה ומתעלמת מראש מנקודות שנמצאות באזור השחור
    
    %% 1. נרמול ושיפור השלד
    skeletonImage = logical(skeletonImage);
    
    % בדיקת היפוך צבעים (אם הרקע לבן - נהפוך אותו)
    if sum(skeletonImage(:)) > numel(skeletonImage)/2
        skeletonImage = ~skeletonImage;
    end
    
    % ניקוי ודיקוק
    skeletonImage = bwmorph(skeletonImage, 'thin', Inf);
    skeletonImage = bwmorph(skeletonImage, 'clean'); 
    skeletonImage = bwmorph(skeletonImage, 'spur', 5); 
    
    %% 2. זיהוי טופולוגי מהיר בתוך המסיכה בלבד
    
    % --- מציאת סיומות (End points) ---
    bw_endings = bwmorph(skeletonImage, 'endpoints');
    
    % [תיקון קריטי] מוחקים מיד כל סיומת שלא נמצאת בתוך המסיכה
    bw_endings = bw_endings & roiMask; 
    
    [r_end, c_end] = find(bw_endings);
    
    % --- מציאת פיצולים (Branch points) ---
    bw_branches = bwmorph(skeletonImage, 'branchpoints');
    
    % [תיקון קריטי] מוחקים מיד כל פיצול שלא נמצא בתוך המסיכה
    bw_branches = bw_branches & roiMask;
    
    [r_bif, c_bif] = find(bw_branches);
    
    %% 3. איחוד המידע וחישוב זוויות (מתבצע רק על נקודות חוקיות)
    numEnd = length(r_end);
    numBif = length(r_bif);
    
    minutiaeData = zeros(numEnd + numBif, 4);
    
    % --- עיבוד סיומות (Type = 1) ---
    for i = 1:numEnd
        angle = calculate_orientation_reliable(skeletonImage, r_end(i), c_end(i), cfg);
        minutiaeData(i, :) = [c_end(i), r_end(i), 1, angle];
    end
    
    % --- עיבוד פיצולים (Type = 3) ---
    for i = 1:numBif
        angle = calculate_orientation_reliable(skeletonImage, r_bif(i), c_bif(i), cfg);
        minutiaeData(numEnd + i, :) = [c_bif(i), r_bif(i), 3, angle];
    end
end

%% פונקציית עזר לחישוב זווית (נשארת ללא שינוי)
function angle = calculate_orientation_reliable(img, r, c, cfg)
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