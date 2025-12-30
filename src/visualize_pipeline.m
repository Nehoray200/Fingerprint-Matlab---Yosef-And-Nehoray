function visualize_pipeline(img)
    % visualize_pipeline - מציג את תהליך העיבוד המלא והאמיתי
    % קורא לפונקציות המקוריות כדי להבטיח שהתצוגה זהה למה שקורה בפועל
    
    % 1. טעינת הגדרות (כדי שנהיה מסונכרנים עם ה-Process)
    cfg = get_config();
    
    figure('Name', 'Fingerprint Pipeline Debugger (Real-Time)', 'Units', 'normalized', 'Position', [0 0 1 1]);
    
    %% --- שלב 1: עיבוד תמונה ראשוני (שחזור הלוגיקה של process_fingerprint) ---
    if size(img, 3) == 3, img = rgb2gray(img); end
    img = im2double(img);
    
    % שיפור (חייב להיות זהה ל-process_fingerprint)
    imgEnh = adapthisteq(img);
    imgEnh = imgaussfilt(imgEnh, 0.5);
    
    subplot(2, 4, 1); 
    imshow(imgEnh); 
    title('1. שיפור תמונה (CLAHE + Gauss)');

    %% --- שלב 2: בינאריזציה וניקוי ---
    % שימוש באותם פרמטרים כמו בקוד הראשי
    binaryImg = imbinarize(imgEnh, 'adaptive', 'Sensitivity', 0.65);
    
    % הצגת הגרסה לפני ניקוי (כדי לראות את הרעש)
    subplot(2, 4, 2); 
    imshow(binaryImg); 
    title('2. בינאריזציה גולמית (לפני ניקוי)');
    
    % ביצוע הניקוי האמיתי
    binaryClean = bwareaopen(binaryImg, 5);
    binaryClean = ~bwareaopen(~binaryClean, 5);
    
    subplot(2, 4, 3); 
    imshow(binaryClean); 
    title('3. אחרי ניקוי רעשים');

    %% --- שלב 3: שלד (Skeleton) ---
    skeletonImg = bwmorph(binaryClean, 'thin', Inf);
    skeletonImg = bwmorph(skeletonImg, 'clean');
    
    subplot(2, 4, 4); 
    imshow(skeletonImg); 
    title('4. שלד (Skeleton)');

    %% --- שלב 4: חישוב מסיכה (קריאה לפונקציה המקורית) ---
    % קוראים לפונקציה get_roi_mask כדי לראות איזה איזור היא בחרה
    rawMask = get_roi_mask(skeletonImg);
    
    % מבצעים את הכרסום (Erosion) לפי ההגדרות ב-Config
    se = strel('disk', cfg.roi.erosion_size); 
    finalMask = imerode(rawMask, se);
    
    % ויזואליזציה: אדום = מה שנמחק, ירוק = מה שנשאר
    rgbMask = cat(3, skeletonImg, skeletonImg .* finalMask, skeletonImg .* finalMask);
    
    subplot(2, 4, 5); 
    imshow(rgbMask); 
    title(['5. מסיכת ROI (Erosion: ' num2str(cfg.roi.erosion_size) ')']);

    %% --- שלב 5: חילוץ גולמי (קריאה ל-extract_minutiae_features) ---
    rawMinutiae = extract_minutiae_features(skeletonImg);
    
    subplot(2, 4, 6); 
    imshow(img); hold on;
    if ~isempty(rawMinutiae)
        plot(rawMinutiae(:,1), rawMinutiae(:,2), 'rx', 'LineWidth', 1);
    end
    title(['6. כל הנקודות (' num2str(size(rawMinutiae,1)) ') - לפני סינון']);
    hold off;

    %% --- שלב 6: סינון סופי (קריאה ל-filter_minutiae) ---
    % זה השלב הקריטי! כאן נראה מה נשאר אחרי המסיכה והמרחקים
    finalTemplate = filter_minutiae(rawMinutiae, finalMask);
    
    subplot(2, 4, 7); 
    imshow(img); hold on;
    if ~isempty(finalTemplate)
        % הפרדה לצבעים: אדום=סיום, ירוק=פיצול
        term = finalTemplate(finalTemplate(:,3) == 1, :);
        bif  = finalTemplate(finalTemplate(:,3) == 2, :);
        
        plot(term(:,1), term(:,2), 'ro', 'LineWidth', 2, 'MarkerSize', 6);
        plot(bif(:,1), bif(:,2), 'g+', 'LineWidth', 2, 'MarkerSize', 6);
        legend(['Ending (' num2str(size(term,1)) ')'], ['Bifurcation (' num2str(size(bif,1)) ')']);
    end
    title(['7. תוצאה סופית (' num2str(size(finalTemplate,1)) ')']);
    hold off;

    %% --- שלב 7: בדיקת כיוונים (Orientation Check) ---
    % מציג לאן כל נקודה "מסתכלת" כדי לוודא שאין טעויות בחישוב הזווית
    subplot(2, 4, 8); 
    imshow(skeletonImg); hold on;
    
    if ~isempty(finalTemplate)
        x = finalTemplate(:, 1);
        y = finalTemplate(:, 2);
        theta = finalTemplate(:, 4);
        
        % ציור חצים צהובים
        len = 12;
        u = len * cos(theta);
        v = -len * sin(theta);
        
        quiver(x, y, u, v, 0, 'y', 'LineWidth', 1.5, 'MaxHeadSize', 0.5);
        plot(x, y, 'r.', 'MarkerSize', 8);
    end
    title('8. כיווניות (האם החצים לאורך הקו?)');
    hold off;
    
    %% --- בדיקה סופית: קריאה ל-process_fingerprint המלא ---
    % כדי לוודא ב-100% שמה שציירנו זה מה שהמערכת מוציאה
    [realTemplate, ~, ~, ~] = process_fingerprint(img);
    if size(realTemplate, 1) ~= size(finalTemplate, 1)
        disp('⚠️ אזהרה: יש אי-התאמה בין הויזואליזציה לבין process_fingerprint האמיתי!');
    else
        disp(['✅ ויזואליזציה תקינה. זוהו ' num2str(size(realTemplate, 1)) ' נקודות.']);
    end
end