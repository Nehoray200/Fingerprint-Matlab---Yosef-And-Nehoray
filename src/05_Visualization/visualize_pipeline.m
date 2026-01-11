function visualize_pipeline(data, cfg)
    % visualize_pipeline - מציג את שלבי האלגוריתם (גרסה מתוקנת: תצוגה תואמת לוגיקה)
    
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
    
    % --- שורה תחתונה: ניתוח המינוטים ---
    
    % 5. גולמי (Raw)
    subplot(2, 4, 5); 
    imshow(~data.skeletonImg); hold on; 
    
    rawPts = data.rawMinutiae;
    if ~isempty(rawPts)
        % אנחנו נציג את כל הנקודות הגולמיות, אבל נסמן בצבע אחר את אלו שבחוץ
        plot(rawPts(:,1), rawPts(:,2), 'b.', 'MarkerSize', 8); 
    end
    title(['5. גולמי על שלד (' num2str(size(rawPts,1)) ')'], 'FontSize', 12);
    
    % 6. סופי (סינון + גבולות)
    finalPts = data.finalTemplate;
    subplot(2, 4, 6); 
    imshow(~data.skeletonImg); hold on; 
    
    % === תיקון קריטי בויזואליזציה ===
    % חישוב הגבול הוירטואלי בדיוק כמו בפילטר (רק לנקודות שבמסיכה)
    if ~isempty(rawPts)
        % 1. סינון הנקודות לפי המסיכה (כמו בלוגיקה האמיתית)
        X = round(rawPts(:, 1));
        Y = round(rawPts(:, 2));
        [h, w] = size(data.roiMask);
        
        % זריקת חריגים
        validIdx = (X >= 1) & (X <= w) & (Y >= 1) & (Y <= h);
        tempPts = rawPts(validIdx, :);
        X = X(validIdx); Y = Y(validIdx);
        
        % בדיקת מסיכה
        ind = sub2ind([h, w], Y, X);
        inMask = data.roiMask(ind);
        maskedPts = tempPts(inMask, :);
        
        % 2. ציור הגבול רק סביב הנקודות החוקיות
        if size(maskedPts, 1) >= 3
            if isfield(cfg.filter, 'boundary_shrink_factor')
                shrinkVal = cfg.filter.boundary_shrink_factor;
            else
                shrinkVal = 0.5; 
            end
            
            try
                k = boundary(maskedPts(:,1), maskedPts(:,2), shrinkVal);
                boundPts = maskedPts(k, :);
                
                % ציור קו הגבול (מגנטה)
                plot(boundPts(:,1), boundPts(:,2), 'm-', 'LineWidth', 2); 
            catch
            end
        end
    end
    % ================================
    
    % ציור הנקודות הסופיות שנשארו
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
    title(['6. סופי (' num2str(size(finalPts,1)) ') + גבול חכם'], 'FontSize', 12);
    
    % 7. כיוונים (אוריינטציה)
    subplot(2, 4, 7); 
    imshow(~data.skeletonImg); hold on;
    if ~isempty(finalPts)
        quiver(finalPts(:,1), finalPts(:,2), ...
               cos(finalPts(:,4))*10, -sin(finalPts(:,4))*10, ...
               0, 'b', 'LineWidth', 1.2); 
    end
    title('7. כיוונים', 'FontSize', 12);
    
    % 8. סיכום טקסטואלי
    subplot(2, 4, 8); axis off;
    
    minRequired = cfg.enroll.min_minutiae;
    numPoints = size(finalPts, 1);
    
    if numPoints >= minRequired
        statusColor = 'g'; 
        statusText = '✅ איכות טובה';
    elseif numPoints >= (minRequired * 0.7)
        statusColor = [1 0.5 0]; 
        statusText = '⚠️ גבולי';
    else
        statusColor = 'r'; 
        statusText = '❌ נכשל';
    end
    
    text(0.5, 0.7, statusText, 'Color', statusColor, 'FontSize', 16, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
    text(0.5, 0.5, sprintf('נמצאו %d נקודות', numPoints), 'Color', 'k', 'FontSize', 12, 'HorizontalAlignment', 'center');
    text(0.5, 0.3, ['סף נדרש: ' num2str(minRequired)], 'Color', [0.5 0.5 0.5], 'FontSize', 10, 'HorizontalAlignment', 'center');
end