function visualize_pipeline(img)
    % visualize_pipeline - מעודכן לפי הלוגיקה החדשה של process_fingerprint
    % כולל adapthisteq, ניקוי עדין (5), וגיזום ענפים (Spur 8)

    cfg = get_config(); 
    
    figure('Name', 'Updated Pipeline Debugger', 'Units', 'normalized', 'Position', [0 0 1 1]);
    
    %% 1. המרה ושיפור
    if size(img, 3) == 3, img = rgb2gray(img); end
    img = im2double(img);
    
    % שיפור ניגודיות (כמו ב-process_fingerprint החדש)
    imgEnh = adapthisteq(img); 
    imgEnh = imgaussfilt(imgEnh, 0.5); % פילטר עדין
    
    subplot(2, 4, 1); imshow(imgEnh); title('1. שיפור (CLAHE + Gauss 0.5)');

    %% 2. בינאריזציה
    % רגישות 0.65
    binaryImg = imbinarize(imgEnh, 'adaptive', 'Sensitivity', 0.65);
    
    subplot(2, 4, 2); imshow(binaryImg); title('2. בינאריזציה (Sens 0.65)');
    
    %% 3. ניקוי רעשים
    % סגירת חורים קטנים (5)
    binaryClean = bwareaopen(binaryImg, 5); 
    % מחיקת רעש רקע (5)
    binaryClean = ~bwareaopen(~binaryClean, 5); 
    
    subplot(2, 4, 3); imshow(binaryClean); title('3. ניקוי עדין (Area 5)');

    %% 4. שלד וגיזום (Spur)
    skeletonImg = bwmorph(binaryClean, 'thin', Inf);
    
    % מחיקת ענפים קטנים (Spur 8) - השינוי המהותי שמנקה את ה"קוצים"
    skeletonImg = bwmorph(skeletonImg, 'spur', 8); 
    skeletonImg = bwmorph(skeletonImg, 'clean');
    
    subplot(2, 4, 4); imshow(skeletonImg); title('4. שלד אחרי גיזום (Spur 8)');

    %% 5. מסיכה (ROI)
    try
        roiMask = get_roi_mask(skeletonImg);
        % כרסום מינימלי (2) - שומר על הקצוות
        se = strel('disk', 2); 
        roiMaskEroded = imerode(roiMask, se);
        
        rgbMask = cat(3, skeletonImg, skeletonImg .* roiMaskEroded, skeletonImg .* roiMaskEroded);
        subplot(2, 4, 5); imshow(rgbMask); title('5. מסיכה (Erosion 2)');
    catch
        roiMaskEroded = true(size(skeletonImg));
        subplot(2, 4, 5); imshow(skeletonImg); title('5. (ROI Failed)');
    end

    %% 6. חילוץ גולמי
    rawMinutiae = extract_minutiae_features(skeletonImg);
    
    subplot(2, 4, 6); imshow(img); hold on;
    if ~isempty(rawMinutiae)
        plot(rawMinutiae(:,1), rawMinutiae(:,2), 'rx');
    end
    title(['6. חילוץ גולמי (' num2str(size(rawMinutiae,1)) ')']);
    hold off;

    %% 7. סינון סופי
    template = filter_minutiae(rawMinutiae, roiMaskEroded);
    
    subplot(2, 4, 7); imshow(img); hold on;
    if ~isempty(template)
        term = template(template(:,3) == 1, :);
        bif  = template(template(:,3) == 2, :);
        plot(term(:,1), term(:,2), 'ro', 'LineWidth', 2);
        plot(bif(:,1), bif(:,2), 'g+', 'LineWidth', 2);
    end
    title(['7. סופי (' num2str(size(template,1)) ')']);
    hold off;

    %% 8. כיוונים
    subplot(2, 4, 8); imshow(skeletonImg); hold on;
    if ~isempty(template)
        quiver(template(:,1), template(:,2), ...
               cos(template(:,4))*15, -sin(template(:,4))*15, ...
               0, 'y', 'LineWidth', 1.5);
    end
    title('8. כיוונים (Orientation)');
    hold off;
end