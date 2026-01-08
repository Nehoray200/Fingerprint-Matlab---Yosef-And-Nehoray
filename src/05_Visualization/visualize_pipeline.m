function visualize_pipeline(data, cfg)
    % visualize_pipeline - מציג את שלבי האלגוריתם (גרסה עם שלד ברקע)
    
    if nargin < 2
        cfg = get_config(); 
    end
    
    figure('Name', 'Fingerprint Pipeline: Skeleton View', 'Units', 'normalized', 'Position', [0 0.1 1 0.8]);
    
    % 1. מקור
    subplot(2, 4, 1); 
    imshow(data.imgGray); 
    title('1. מקור (אפור)', 'FontSize', 12);
    
    % 2. מסיכה (ROI)
    subplot(2, 4, 2); 
    imshow(data.roiMask); 
    title('2. מסיכה (Segmentation)', 'FontSize', 12);
    
    % 3. בינארי (אחרי Gabor)
    subplot(2, 4, 3); 
    imshow(data.binaryMasked); 
    title('3. בינארי (Gabor Filtered)', 'FontSize', 12);
    
    % 4. שלד
    subplot(2, 4, 4); 
    imshow(data.skeletonImg); 
    title('4. שלד (Thinned)', 'FontSize', 12);
    
    % --- שינוי: תצוגה על גבי שלד הפוך (שחור על לבן) ---
    
    % 5. גולמי
    subplot(2, 4, 5); 
    % השימוש ב- (~) הופך שחור ללבן ולהפך
    imshow(~data.skeletonImg); hold on; 
    
    rawPts = data.rawMinutiae;
    if ~isempty(rawPts)
        % נקודות כחולות
        plot(rawPts(:,1), rawPts(:,2), 'b.', 'MarkerSize', 8); 
    end
    title(['5. גולמי על שלד (' num2str(size(rawPts,1)) ')'], 'FontSize', 12);
    
    % 6. סופי (סינון)
    finalPts = data.finalTemplate;
    subplot(2, 4, 6); 
    imshow(~data.skeletonImg); hold on; % גם כאן: שלד שחור על לבן
    
    % --- ציור "האזור הבטוח" ---
    margin = cfg.filter.border_margin;
    maskFilled = imfill(data.roiMask, 'holes');
    distMap = bwdist(~maskFilled);
    safeZone = distMap > margin;
    
    boundaries = bwboundaries(safeZone);
    if ~isempty(boundaries)
        for k = 1:length(boundaries)
            b = boundaries{k};
            % שיניתי למגנטה (m) כי תכלת (c) לא רואים טוב על לבן
            plot(b(:,2), b(:,1), 'm--', 'LineWidth', 1); 
        end
    end
    
    % --- ציור הנקודות הסופיות ---
    if ~isempty(finalPts)
        % סיומות (Endings) - עיגול אדום
        termIdx = finalPts(:,3) == 1;
        if any(termIdx)
            plot(finalPts(termIdx, 1), finalPts(termIdx, 2), 'ro', 'LineWidth', 1.5, 'MarkerSize', 6);
        end
        
        % פיצולים (Bifurcations) - ריבוע ירוק
        bifIdx = finalPts(:,3) == 3;
        if any(bifIdx)
            plot(finalPts(bifIdx, 1), finalPts(bifIdx, 2), 'gs', 'LineWidth', 1.5, 'MarkerSize', 6);
        end
    end
    title(['6. סופי על שלד (' num2str(size(finalPts,1)) ')'], 'FontSize', 12);
    
    % 7. כיוונים (אוריינטציה)
    subplot(2, 4, 7); 
    imshow(~data.skeletonImg); hold on; % שלד שחור על לבן
    if ~isempty(finalPts)
        % ציור חצים קטנים
        quiver(finalPts(:,1), finalPts(:,2), ...
               cos(finalPts(:,4))*10, -sin(finalPts(:,4))*10, ...
               0, 'b', 'LineWidth', 1.2); % חצים בכחול
    end
    title('7. כיוונים', 'FontSize', 12);
    
    % 8. סיכום טקסטואלי
    subplot(2, 4, 8); axis off;
    
    minRequired = 12;
    numPoints = size(finalPts, 1);
    
    if numPoints >= minRequired
        statusColor = 'g'; 
        statusText = '✅ איכות טובה';
    elseif numPoints >= 8
        statusColor = [1 0.5 0]; 
        statusText = '⚠️ גבולי';
    else
        statusColor = 'r'; 
        statusText = '❌ נכשל';
    end
    
    text(0.5, 0.7, statusText, 'Color', statusColor, 'FontSize', 16, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(0.5, 0.5, sprintf('נמצאו %d נקודות', numPoints), 'Color', 'k', 'FontSize', 12, 'HorizontalAlignment', 'center');
    text(0.5, 0.3, 'תצוגה על גבי שלד נקי', 'Color', [0.5 0.5 0.5], 'FontSize', 10, 'HorizontalAlignment', 'center');
end