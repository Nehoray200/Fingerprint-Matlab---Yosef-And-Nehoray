function visualize_pipeline(img)
    % visualize_pipeline - מציג את תהליך העיבוד החסכוני
    
    cfg = get_config();
    figure('Name', 'Pipeline: Optimization (Mask Early)', 'Units', 'normalized', 'Position', [0 0 1 1]);
    
    % 1. מקור
    if size(img, 3) == 3, img = rgb2gray(img); end
    img = im2double(img);
    
    subplot(2, 4, 1); imshow(img); title('1. תמונה מקורית');
    
    % 2. מסיכה
    roiMask = get_roi_mask(img);
    subplot(2, 4, 2); imshow(roiMask); title('2. מסיכה (Texture)');
    
    % 3. עיבוד וחיתוך
    imgEnh = adapthisteq(img);
    imgEnh = imgaussfilt(imgEnh, 0.5);
    bin = imbinarize(imgEnh, 'adaptive', 'Sensitivity', 0.65);
    
    bin = bwareaopen(bin, 10);
    bin = ~bwareaopen(~bin, 10);
    
    % החיתוך המוקדם
    binMasked = bin & roiMask;
    
    subplot(2, 4, 3); imshow(binMasked); 
    title('3. בינארי חתוך (רק בתוך המסיכה)');
    
    % 4. שלד
    skel = bwmorph(binMasked, 'thin', Inf);
    skel = bwmorph(skel, 'spur', 8);
    skel = bwmorph(skel, 'clean');
    
    subplot(2, 4, 4); imshow(skel); title('4. שלד נקי');
    
    % 5. חילוץ (עכשיו זה יהיה נקי!)
    rawPts = extract_minutiae_features(skel);
    subplot(2, 4, 5); imshow(img); hold on;
    if ~isempty(rawPts), plot(rawPts(:,1), rawPts(:,2), 'rx'); end
    title(['5. גולמי (' num2str(size(rawPts,1)) ') - נקי מרעש רקע']);
    
    % 6. סינון סופי
    finalPts = filter_minutiae(rawPts, roiMask);
    subplot(2, 4, 6); imshow(img); hold on;
    if ~isempty(finalPts)
        plot(finalPts(finalPts(:,3)==1,1), finalPts(finalPts(:,3)==1,2), 'ro', 'LineWidth', 2);
        plot(finalPts(finalPts(:,3)==2,1), finalPts(finalPts(:,3)==2,2), 'g+', 'LineWidth', 2);
    end
    title(['6. סופי (' num2str(size(finalPts,1)) ')']);
    
    % 7. כיוונים
    subplot(2, 4, 7); imshow(skel); hold on;
    if ~isempty(finalPts)
        quiver(finalPts(:,1), finalPts(:,2), cos(finalPts(:,4))*15, -sin(finalPts(:,4))*15, 0, 'y');
    end
    title('7. כיוונים');
    
    % 8. אימות
    [pT, ~, ~, ~] = process_fingerprint(img);
    subplot(2, 4, 8); axis off;
    if size(finalPts,1) == size(pT,1)
        text(0.1,0.5,'✅ תואם','Color','g','FontSize',14);
    else
        text(0.1,0.5,'❌ שגיאה','Color','r','FontSize',14);
    end
end