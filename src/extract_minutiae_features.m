function minutiaeData = extract_minutiae_features(skeletonImage)
    % extract_minutiae_features - חילוץ מהיר ומתוקן של נקודות
    % קלט: תמונת שלד (בינארית)
    % פלט: [X, Y, Type, Angle]
    % Type: 1 = סיום (Ending), 3 = פיצול (Bifurcation)
    
    %% 1. נרמול התמונה (תיקון הבאג הקריטי)
    % וידוא שהרכסים הם לבנים (1) והרקע שחור (0)
    skeletonImage = logical(skeletonImage);
    
    % בדיקה מהירה: אם רוב התמונה לבנה, כנראה שהרכסים שחורים -> נהפוך
    if sum(skeletonImage(:)) > numel(skeletonImage)/2
        skeletonImage = ~skeletonImage;
    end
    
    % ניקוי אחרון של פיקסלים בודדים (Spurs) שיכולים לבלבל
    skeletonImage = bwmorph(skeletonImage, 'clean');

    %% 2. חישוב Crossing Number בצורה וקטורית (מהיר פי 100 מלולאות)
    % פילטר שסוכם את כל 8 השכנים
    filter = [1 1 1; 1 0 1; 1 1 1];
    
    % חישוב סכום שכנים לכל פיקסל בתמונה בפקודה אחת
    cnMatrix = conv2(double(skeletonImage), filter, 'same');
    
    % אנחנו מעוניינים רק בערכי CN שנמצאים על הרכס עצמו
    cnMatrix = cnMatrix .* double(skeletonImage);
    
    %% 3. איסוף הנקודות
    % מציאת הקואורדינטות של נקודות הסיום (CN=1) והפיצול (CN=3)
    [r_end, c_end] = find(cnMatrix == 1);
    [r_bif, c_bif] = find(cnMatrix == 3);
    
    minutiaeData = [];
    
    % --- עיבוד נקודות סיום (Endings) ---
    for i = 1:length(r_end)
        r = r_end(i); c = c_end(i);
        % דילוג על שוליים (מונע קריסה בחישוב זווית)
        if r < 4 || c < 4 || r > size(skeletonImage,1)-4 || c > size(skeletonImage,2)-4
            continue; 
        end
        
        angle = calculate_orientation_reliable(skeletonImage, r, c);
        minutiaeData = [minutiaeData; c, r, 1, angle];
    end
    
    % --- עיבוד נקודות פיצול (Bifurcations) ---
    for i = 1:length(r_bif)
        r = r_bif(i); c = c_bif(i);
        if r < 4 || c < 4 || r > size(skeletonImage,1)-4 || c > size(skeletonImage,2)-4
            continue; 
        end
        
        angle = calculate_orientation_reliable(skeletonImage, r, c);
        minutiaeData = [minutiaeData; c, r, 3, angle];
    end
end

%% פונקציית עזר לחישוב זווית אמין
function angle = calculate_orientation_reliable(img, r, c)
    % חישוב זווית ע"י הליכה של 3 צעדים לאורך הרכס
    % זה נותן זווית הרבה יותר יציבה מרעש של פיקסל בודד
    
    path_r = zeros(5,1);
    path_c = zeros(5,1);
    
    path_r(1) = r;
    path_c(1) = c;
    
    % הולכים עד 3 צעדים
    for k = 1:3
        curr_r = path_r(k);
        curr_c = path_c(k);
        
        % חיפוש שכן בחלון 3x3
        foundNeighbor = false;
        
        for dr = -1:1
            for dc = -1:1
                if dr==0 && dc==0, continue; end
                
                nr = curr_r + dr;
                nc = curr_c + dc;
                
                % האם יש פה רכס?
                if img(nr, nc) == 1
                    % בדיקה שלא חזרנו אחורה (לאיפה שבאנו ממנו)
                    if k > 1
                        if nr == path_r(k-1) && nc == path_c(k-1)
                            continue;
                        end
                    end
                    
                    % מצאנו את הצעד הבא
                    path_r(k+1) = nr;
                    path_c(k+1) = nc;
                    foundNeighbor = true;
                    break;
                end
            end
            if foundNeighbor, break; end
        end
        
        if ~foundNeighbor
            break; % נתקענו (קו קצר מדי)
        end
    end
    
    % חישוב הזווית בין ההתחלה לסוף המסלול שמצאנו
    last_idx = find(path_r ~= 0, 1, 'last');
    if last_idx > 1
        dy = path_r(last_idx) - path_r(1);
        dx = path_c(last_idx) - path_c(1);
        angle = atan2(dy, dx); % מחזיר רדיאנים (-pi עד pi)
    else
        angle = 0;
    end
end