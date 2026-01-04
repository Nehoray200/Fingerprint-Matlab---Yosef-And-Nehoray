function minutiaeData = extract_minutiae_features(skeletonImage)
    % extract_minutiae_features - גרסה סופית ומתוקנת
    % כוללת טיפול באלכסונים וחישוב זווית אמין
    
    %% 1. נרמול ושיפור השלד
    skeletonImage = logical(skeletonImage);
    
    % בדיקת היפוך צבעים (אם הרקע לבן - נהפוך אותו)
    if sum(skeletonImage(:)) > numel(skeletonImage)/2
        skeletonImage = ~skeletonImage;
    end
    
    % תיקון קריטי: שימוש ב-thin במקום clean
    % זה מבטיח עובי של פיקסל אחד בדיוק ומונע בעיות "מדרגות" באלכסונים
    skeletonImage = bwmorph(skeletonImage, 'thin', Inf);
    
    % ניקוי רעשים נוסף (מוריד זיפים קטנים בקצוות)
    skeletonImage = bwmorph(skeletonImage, 'spur');
    
    %% 2. סינון מועמדים (שלב מהיר)
    [H, W] = size(skeletonImage);
    minutiaeData = [];
    
    % מוצאים את כל הפיקסלים הדלוקים (השלד עצמו)
    [rows, cols] = find(skeletonImage);
    
    %% 3. אימות וסיווג (הלולאה הראשית)
    for k = 1:length(rows)
        r = rows(k);
        c = cols(k);
        
        % דילוג על שוליים (כדי למנוע חריגה מגבולות המערך)
        if r < 2 || c < 2 || r > H-1 || c > W-1
            continue;
        end
        
        % שליפת 8 השכנים במעגל (עם כיוון השעון)
        blk = skeletonImage(r-1:r+1, c-1:c+1);
        neighbors_circle = [blk(1,2), blk(1,3), blk(2,3), blk(3,3), ...
                            blk(3,2), blk(3,1), blk(2,1), blk(1,1), blk(1,2)];
                     
        % חישוב Crossing Number (CN)
        % מכיוון שהשתמשנו ב-'thin', חישוב CN לבדו הוא אמין כעת
        transitions = sum(abs(diff(double(neighbors_circle))));
        cn = transitions / 2;
        
        if cn == 1
            % === נקודת סיום (Ending) ===
            angle = calculate_orientation_reliable(skeletonImage, r, c);
            minutiaeData = [minutiaeData; c, r, 1, angle];
            
        elseif cn == 3
            % === נקודת פיצול (Bifurcation) ===
            angle = calculate_orientation_reliable(skeletonImage, r, c);
            minutiaeData = [minutiaeData; c, r, 3, angle];
        end
    end
end

%% פונקציית עזר לחישוב זווית (חייבת להיות באותו קובץ)
function angle = calculate_orientation_reliable(img, r, c)
    % מחשבת זווית ע"י הליכה של 3 צעדים לאורך הרכס
    path_r = zeros(5,1); path_c = zeros(5,1);
    path_r(1) = r; path_c(1) = c;
    
    for k = 1:3
        curr_r = path_r(k); curr_c = path_c(k);
        foundNeighbor = false;
        
        % סריקת 8 השכנים
        for dr = -1:1
            for dc = -1:1
                if dr==0 && dc==0, continue; end
                nr = curr_r + dr; nc = curr_c + dc;
                
                % בדיקת גבולות בתוך הלולאה הפנימית
                [H, W] = size(img);
                if nr < 1 || nc < 1 || nr > H || nc > W, continue; end
                
                if img(nr, nc) == 1
                    % מוודאים שלא חוזרים אחורה
                    if k > 1 && nr == path_r(k-1) && nc == path_c(k-1), continue; end
                    
                    path_r(k+1) = nr; path_c(k+1) = nc;
                    foundNeighbor = true; break;
                end
            end
            if foundNeighbor, break; end
        end
        if ~foundNeighbor, break; end
    end
    
    % חישוב הזווית הסופית (dy/dx)
    last_idx = find(path_r ~= 0, 1, 'last');
    if last_idx > 1
        dy = path_r(last_idx) - path_r(1);
        dx = path_c(last_idx) - path_c(1);
        angle = atan2(dy, dx);
    else
        angle = 0;
    end
end