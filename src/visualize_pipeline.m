function visualize_pipeline(data, cfg)
    % visualize_pipeline - מקבלת את כל הנתונים מוכנים ומציגה אותם
    % data: מבנה נתונים שמכיל את כל שלבי הביניים מ-process_fingerprint
    
    if nargin < 2
        cfg = get_config(); % גיבוי למקרה שלא נשלח
    end
    
    figure('Name', 'Pipeline: Unified Logic', 'Units', 'normalized', 'Position', [0 0 1 1]);
    
    % 1. מקור
    subplot(2, 4, 1); 
    imshow(data.imgGray); 
    title('1. מקור (אפור)');
    
    % 2. מסיכה
    subplot(2, 4, 2); 
    imshow(data.roiMask); 
    title('2. מסיכה (ROI)');
    
    % 3. בינארי חתוך
    subplot(2, 4, 3); 
    imshow(data.binaryMasked); 
    title('3. בינארי סופי');
    
    % 4. שלד
    subplot(2, 4, 4); 
    imshow(data.skeletonImg); 
    title('4. שלד');
    
    % 5. גולמי (תצוגה כחולה על המקור)
    subplot(2, 4, 5); 
    imshow(data.imgGray); hold on;
    rawPts = data.rawMinutiae;
    if ~isempty(rawPts)
        plot(rawPts(:,1), rawPts(:,2), 'b.', 'MarkerSize', 5); 
    end
    title(['5. גולמי (' num2str(size(rawPts,1)) ')']);
    
    % 6. סופי (סינון)
    finalPts = data.finalTemplate;
    subplot(2, 4, 6); 
    imshow(data.imgGray); hold on;
    
    % --- ציור קו הגבול (ויזואלי בלבד, לא משפיע על הלוגיקה) ---
    margin = cfg.filter.border_margin;
    maskFilled = imfill(data.roiMask, 'holes');
    distMap = bwdist(~maskFilled);
    safeZone = distMap > margin;
    
    boundaries = bwboundaries(safeZone);
    if ~isempty(boundaries)
        for k = 1:length(boundaries)
            b = boundaries{k};
            plot(b(:,2), b(:,1), 'c', 'LineWidth', 1.5); 
        end
    end
    
    % --- ציור הנקודות ---
    if ~isempty(finalPts)
        % סיומות - אדום
        termIdx = finalPts(:,3) == 1;
        if any(termIdx)
            plot(finalPts(termIdx, 1), finalPts(termIdx, 2), 'ro', 'LineWidth', 2);
        end
        
        % פיצולים - ירוק
        bifIdx = finalPts(:,3) == 3;
        if any(bifIdx)
            plot(finalPts(bifIdx, 1), finalPts(bifIdx, 2), 'g*', 'LineWidth', 2);
        end
    end
    title(['6. סופי (' num2str(size(finalPts,1)) ')']);
    
    % 7. כיוונים
    subplot(2, 4, 7); 
    imshow(data.skeletonImg); hold on;
    if ~isempty(finalPts)
        quiver(finalPts(:,1), finalPts(:,2), ...
               cos(finalPts(:,4))*15, -sin(finalPts(:,4))*15, ...
               0, 'y', 'LineWidth', 1.5);
    end
    title('7. כיוונים');
    
    % 8. סיכום
    subplot(2, 4, 8); axis off;
    text(0.1, 0.5, 'הושלם בהצלחה', 'Color', 'g', 'FontSize', 14);
    text(0.1, 0.3, sprintf('סה"כ נקודות: %d', size(finalPts, 1)), 'Color', 'k');
end