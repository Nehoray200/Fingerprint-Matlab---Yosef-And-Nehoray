

function visualize_pipeline(img)
    % visualize_pipeline - מריץ את העיבוד שלב-אחר-שלב ומציג תמונות
    % שימוש:
    % img = imread('data/my_fingerprint.tif');
    % visualize_pipeline(img);

    figure('Name', 'Fingerprint Processing Pipeline', 'NumberTitle', 'off', 'Units', 'normalized', 'Position', [0.1 0.1 0.8 0.8]);
    
    % --- שלב 1: טעינה והמרה ---
    if size(img, 3) == 3, img = rgb2gray(img); end
    img = im2double(img);
    
    subplot(2, 3, 1);
    imshow(img);
    title('1. תמונה מקורית (Grayscale)');
    
    % --- שלב 2: שיפור (Enhancement) ---
    % שים לב: אם ב-process_fingerprint המקורי יש פילטרים נוספים, הם יופיעו כאן
    imgEnhanced = imgaussfilt(img, 0.5);
    
    subplot(2, 3, 2);
    imshow(imgEnhanced);
    title('2. שיפור וסינון רעשים (Gaussian)');
    
    % --- שלב 3: בינאריזציה (Binarization) ---
    binaryImg = imbinarize(imgEnhanced, 'adaptive', 'Sensitivity', 0.5);
    
    subplot(2, 3, 3);
    imshow(binaryImg);
    title('3. בינאריזציה (שחור/לבן)');
    
    % --- שלב 4: שלד (Skeletonization) ---
    skeletonImg = bwmorph(binaryImg, 'thin', Inf);
    
    subplot(2, 3, 4);
    imshow(skeletonImg);
    title('4. שלד (Skeleton)');
    
    % --- שלב 5: מסיכה (ROI) ---
    % נסה לטעון את הפונקציה שלך, אם לא קיימת נציג את השלד בלבד
    try
        roiMask = get_roi_mask(skeletonImg);
        % הצגת המסיכה על גבי השלד (באדום)
        rgbOverlay = cat(3, skeletonImg, skeletonImg .* ~roiMask, skeletonImg .* ~roiMask);
        
        subplot(2, 3, 5);
        imshow(rgbOverlay);
        title('5. מסיכת ROI (אדום = אזור מסונן)');
    catch
        subplot(2, 3, 5);
        text(0.5, 0.5, 'get_roi_mask not found', 'HorizontalAlignment', 'center');
    end
    
    % --- שלב 6: חילוץ נקודות (Minutiae) ---
    try
        rawMinutiae = extract_minutiae_features(skeletonImg);
        if exist('roiMask', 'var')
            template = filter_minutiae(rawMinutiae, roiMask);
        else
            template = rawMinutiae;
        end
        
        subplot(2, 3, 6);
        imshow(img); hold on;
        % ציור הנקודות הסופיות
        if ~isempty(template)
            % התפלגות לפי סוגים (אם קיים טור 3)
            terminals = template(template(:,3) == 1, :);
            bifurcations = template(template(:,3) == 2, :);
            
            plot(terminals(:,1), terminals(:,2), 'ro', 'LineWidth', 1, 'MarkerSize', 5);
            plot(bifurcations(:,1), bifurcations(:,2), 'g+', 'LineWidth', 1, 'MarkerSize', 5);
            legend('Endings', 'Bifurcations');
        end
        title(['6. תוצאה סופית (' num2str(size(template, 1)) ' נקודות)']);
        hold off;
        
    catch err
        subplot(2, 3, 6);
        text(0.5, 0.5, ['Error: ' err.message], 'HorizontalAlignment', 'center', 'Color', 'r');
    end
end