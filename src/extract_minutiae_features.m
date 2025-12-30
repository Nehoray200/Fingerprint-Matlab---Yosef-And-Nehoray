function minutiaeData = extract_minutiae_features(skeletonImage)
    % extract_minutiae_features - חילוץ נקודות מאפיין (מינוציות)
    % קלט: תמונת שלד (רצוי קווים שחורים על רקע לבן, או להפך - הפונקציה תסדר את זה)
    % פלט: מטריצה בגודל N על 4
    %      Col 1: X position
    %      Col 2: Y position
    %      Col 3: Type (1=Ending, 3=Bifurcation)
    %      Col 4: Angle (in Radians)

    %% 1. הכנת התמונה (נרמול ללוגיקה של 1=קו, 0=רקע)
    % אנו מניחים שהקלט הוא קווים שחורים (0) ורקע לבן (1)
    % נהפוך את זה כי מתמטית קל יותר לספור "1"
    binaryImg = ~logical(skeletonImage); 
    
    [rows, cols] = size(binaryImg);
    minutiaeData = []; % אתחול המערך

    %% 2. סריקת התמונה
    % רצים על כל הפיקסלים (מדלגים על המסגרת כדי לא לחרוג)
    for r = 2 : rows-1
        for c = 2 : cols-1
            
            % אם הפיקסל הוא "רכס" (ערך 1)
            if binaryImg(r,c) == 1
                
                % גזירת חלון 3x3 סביב הפיקסל
                window = binaryImg(r-1:r+1, c-1:c+1);
                
                % חישוב Crossing Number (סכום השכנים)
                % מפחיתים 1 כדי לא לספור את הפיקסל המרכזי עצמו
                cn = sum(window(:)) - 1;
                
                % בדיקה אם זו מינוציה מעניינת
                if cn == 1 || cn == 3
                    
                    % חישוב הזווית
                    angle = calculate_angle(binaryImg, r, c, cn);
                    
                    % שמירה למערך: [X, Y, Type, Angle]
                    minutiaeData = [minutiaeData; c, r, cn, angle];
                end
            end
        end
    end
end

%% פונקציית עזר פנימית לחישוב זווית
function angle = calculate_angle(img, r, c, type)
    % חישוב זווית פשוט: מוצאים את השכן הקרוב ומחשבים כיוון אליו
    % הערה: במימוש מתקדם יותר, הולכים מספר צעדים אחורה על הקו כדי לדייק.
    
    % מציאת מיקום השכנים בחלון 3x3
    [nr, nc] = find(img(r-1:r+1, c-1:c+1));
    
    % המרת קואורדינטות מקומיות (1-3) לקואורדינטות גלובליות
    % אנו מחפשים שכן שהוא *לא* המרכז (2,2)
    found = false;
    for i = 1:length(nr)
        if ~(nr(i) == 2 && nc(i) == 2)
            % מצאנו שכן
            neighbor_r = r + (nr(i) - 2);
            neighbor_c = c + (nc(i) - 2);
            
            % חישוב זווית (בשיטת atan2)
            % הערה: במערכת צירים של תמונה Y יורד למטה
            dy = r - neighbor_r; 
            dx = c - neighbor_c; % כיוון החוצה מהנקודה
            
            angle = atan2(dy, dx);
            found = true;
            break; % לוקחים את השכן הראשון שמצאנו
        end
    end
    
    if ~found
        angle = 0; % ברירת מחדל אם יש שגיאה
    end
end