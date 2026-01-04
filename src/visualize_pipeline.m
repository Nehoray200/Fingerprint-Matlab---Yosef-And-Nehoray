function visualize_pipeline(img)
    % visualize_pipeline - ויזואליזציה מסונכרנת עם התיקון לרכסים חלולים
    
    cfg = get_config(); 
    
    figure('Name', 'Pipeline: Euclidean Distance & Debug', 'Units', 'normalized', 'Position', [0 0 1 1]);
    
    % 1. מקור
    if size(img, 3) == 3, img = rgb2gray(img); end
    img = im2double(img);
    subplot(2, 4, 1); imshow(img); title('1. מקור');
    
    % 2. מסיכה
    roiMask = get_roi_mask(img);
    subplot(2, 4, 2); imshow(roiMask); title('2. מסיכה');
    
    % 3. בינארי חתוך (הלוגיקה המתוקנת)
    % שיפור קונטרסט וטשטוש עדין
    imgEnh = adapthisteq(img);
    imgEnh = imgaussfilt(imgEnh, 0.8);
    
    % בינאריזציה ברגישות נמוכה יותר למניעת חורים
    bin = imbinarize(imgEnh, 'adaptive', 'Sensitivity', 0.50, 'ForegroundPolarity', 'dark');
    
    % --- התיקון לרכסים חלולים ---
    se = strel('disk', 1);
    bin = imclose(~bin, se); % סגירת רווחים בתוך הקווים השחורים
    bin = ~bin;              % החזרה ללבן
    
    % ניקוי רעשים
    bin = ~bwareaopen(~bin, 5); % סגירת חורים זעירים
    bin = bwareaopen(bin, 20);  % הסרת איים קטנים
    
    binMasked = bin & roiMask;
    subplot(2, 4, 3); imshow(binMasked); title('3. בינארי חתוך (מתוקן)');
    
    % 4. שלד
    skel = bwmorph(binMasked, 'thin', Inf);
    skel = bwmorph(skel, 'clean');
    skel = bwmorph(skel, 'spur', 5); % ניקוי זיפים
    subplot(2, 4, 4); imshow(skel); title('4. שלד');
    
    % 5. גולמי (תצוגה כחולה)
    % קורא לפונקציה extract_minutiae_features המעודכנת שלך
    rawPts = extract_minutiae_features(skel);
    subplot(2, 4, 5); imshow(img); hold on;
    if ~isempty(rawPts)
        plot(rawPts(:,1), rawPts(:,2), 'b.', 'MarkerSize', 5); 
    end
    title(['5. גולמי (' num2str(size(rawPts,1)) ')']);
    
    % 6. סופי (עם קו הגבול ודיבוג צבעים)
    finalPts = filter_minutiae(rawPts, roiMask);
    subplot(2, 4, 6); imshow(img); hold on;
    
    % --- ציור קו הגבול (המרחק האוקלידי) ---
    margin = cfg.filter.border_margin;
    maskFilled = imfill(roiMask, 'holes');
    distMap = bwdist(~maskFilled);
    safeZone = distMap > margin;
    
    boundaries = bwboundaries(safeZone);
    if ~isempty(boundaries)
        for k = 1:length(boundaries)
            b = boundaries{k};
            % המרה מ-[Y,X] ל-[X,Y] עבור plot
            plot(b(:,2), b(:,1), 'c', 'LineWidth', 1.5); % צבע תכלת
        end
    end
    
    % --- ציור הנקודות ---
    if ~isempty(finalPts)
        % 1. נקודות בסיס (מגנטה) - לוודא שהן קיימות
        % plot(finalPts(:,1), finalPts(:,2), 'mo', 'LineWidth', 2, 'MarkerSize', 8);
        
        % 2. הדפסת סוגים לקונסול (לדיבוג)
        types = unique(finalPts(:,3));
        fprintf('Debug: Found types inside finalPts: %s\n', mat2str(types'));
        
        % 3. צביעה לפי סוג
        % סיומות (Type 1) - עיגול אדום
        termIdx = finalPts(:,3) == 1;
        if any(termIdx)
            plot(finalPts(termIdx, 1), finalPts(termIdx, 2), 'ro', 'LineWidth', 2);
        end
        
        % פיצולים (Type 3) - כוכבית ירוקה
        % שימו לב: באלגוריתם ה-CN שלנו פיצול הוא 3, לא 2
        bifIdx = finalPts(:,3) == 3;
        if any(bifIdx)
            plot(finalPts(bifIdx, 1), finalPts(bifIdx, 2), 'g*', 'LineWidth', 2);
        end
    end
    title(['6. סופי (' num2str(size(finalPts,1)) ')']);
    
    % 7. כיוונים
    subplot(2, 4, 7); imshow(skel); hold on;
    if ~isempty(finalPts)
        quiver(finalPts(:,1), finalPts(:,2), ...
               cos(finalPts(:,4))*15, -sin(finalPts(:,4))*15, ...
               0, 'y', 'LineWidth', 1.5);
    end
    title('7. כיוונים');
    
    % 8. אימות
    % מפעיל את הפונקציה הראשית כדי לוודא שהתוצאות זהות
    [pT, ~, ~, ~] = process_fingerprint(img);
    subplot(2, 4, 8); axis off;
    
    % השוואה פשוטה לפי כמות הנקודות
    if size(finalPts,1) == size(pT,1)
        text(0.1,0.5,'✅ תואם','Color','g','FontSize',14);
    else
        text(0.1,0.5,'❌ שגיאה','Color','r','FontSize',14);
        text(0.1,0.3, sprintf('Viz: %d, Main: %d', size(finalPts,1), size(pT,1)), 'Color','k');
    end
end