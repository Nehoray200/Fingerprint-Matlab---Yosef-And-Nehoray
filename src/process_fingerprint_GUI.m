function [template, roiMask, rawMinutiae, descriptors] = process_fingerprint_GUI(img, app)
    % process_fingerprint_GUI - מותאם ללוגיקה המדויקת + 7 תחנות (כולל מסיכה)
    
    % אתחול משתנים
    template = []; roiMask = []; rawMinutiae = []; descriptors = [];
    
    try
        if isempty(app.CurrentConfig), error('Config is empty!'); end
        cfg = app.CurrentConfig;
        
        % =========================================================
        % תחנה 1: עיבוד מקדים + חיתוך חכם
        % =========================================================
        app.lblStatus.Text = 'Step 1/7: Preprocessing...'; drawnow;
        
        % 1. המרה לאפור ונרמול ראשוני
        if size(img, 3) == 3, img = rgb2gray(img); end
        img = im2double(img);
        img = adapthisteq(img, 'ClipLimit', 0.02);
        
        % --- שלב החיתוך החכם ---
        fullMask = get_roi_mask(img);
        [r, c] = find(fullMask);
        if isempty(r)
            r1=1; r2=size(img,1); c1=1; c2=size(img,2);
        else
            padding = 15;
            r1 = max(1, min(r) - padding);
            r2 = min(size(img,1), max(r) + padding);
            c1 = max(1, min(c) - padding);
            c2 = min(size(img,2), max(c) + padding);
        end
        
        % חיתוך בפועל
        img = img(r1:r2, c1:c2);
        roiMask = fullMask(r1:r2, c1:c2);
        
        % >> ציור תחנה 1: מקור
        plot_step(app.axStep1, img, '1. Original');
        
        % =========================================================
        % תחנה 2: מסיכה (ROI Mask)
        % =========================================================
        app.lblStatus.Text = 'Step 2/7: Segmentation...'; drawnow;
        
        % חישוב סגמנטציה (Ridge Segment)
        [normim, ~, ~] = ridgesegment(img, cfg.gabor.blk_sze, cfg.gabor.thresh);
        
        % >> ציור תחנה 2: המסיכה
        plot_step(app.axStep2, roiMask, '2. ROI Mask');

        % =========================================================
        % תחנה 3: Gabor Filter
        % =========================================================
        app.lblStatus.Text = 'Step 3/7: Gabor Filtering...'; drawnow;
        
        orientim = ridgeorient(normim, cfg.gabor.grad_sigma, cfg.gabor.block_sigma, cfg.gabor.smooth_sigma);
        [freqim, ~] = ridgefreq(normim, roiMask, orientim, cfg.gabor.freq_blk, ...
                                cfg.gabor.freq_wind, cfg.gabor.min_wl, cfg.gabor.max_wl);
        
        enhancedImg = ridgefilter(normim, orientim, freqim, cfg.gabor.kx, cfg.gabor.ky, 0);
        
        binaryImg = enhancedImg > 0;
        binaryImg = binaryImg & roiMask; 
        binaryImg = bwareaopen(binaryImg, 10);
        binaryImg = ~bwareaopen(~binaryImg, 10);
        
        % >> ציור תחנה 3: Gabor
        plot_step(app.axStep3, enhancedImg, '3. Gabor Filtered');

        % =========================================================
        % תחנה 4: שלד (Skeleton)
        % =========================================================
        app.lblStatus.Text = 'Step 4/7: Skeletonization...'; drawnow;
        
        skeletonImg = bwmorph(binaryImg, 'thin', Inf);
        skeletonImg = bwmorph(skeletonImg, 'clean');
        skeletonImg = bwmorph(skeletonImg, 'diag');
        skeletonImg = bwmorph(skeletonImg, 'spur', 5); 
        
        % >> ציור תחנה 4: שלד
        plot_step(app.axStep4, ~skeletonImg, '4. Skeleton');

        % =========================================================
        % תחנה 5: חילוץ גולמי (Raw Minutiae)
        % =========================================================
        app.lblStatus.Text = 'Step 5/7: Raw Extraction...'; drawnow;
        
        % --- יצירת מסיכה קפדנית (Strict Mask) ---
        erosionVal = 12;
        if isfield(cfg.roi, 'strict_erosion')
            erosionVal = cfg.roi.strict_erosion;
        end
        seStrict = strel('disk', erosionVal);
        strictMask = imerode(roiMask, seStrict);
        
        % חילוץ עם המסיכה הקפדנית
        rawMinutiae = extract_minutiae_features(skeletonImg, strictMask, cfg);
        
        % >> ציור תחנה 5: נקודות גולמיות
        plot_step(app.axStep5, ~skeletonImg, ['5. Raw Points (' num2str(size(rawMinutiae,1)) ')']);
        hold(app.axStep5, 'on');
        if ~isempty(rawMinutiae)
            plot(app.axStep5, rawMinutiae(:,1), rawMinutiae(:,2), 'b.', 'MarkerSize', 8);
        end
        hold(app.axStep5, 'off');

        % =========================================================
        % תחנה 6: תוצאה סופית (Final Result)
        % =========================================================
        app.lblStatus.Text = 'Step 6/7: Final Filtering...'; drawnow;
        
        % סינון סופי וחישוב דסקריפטורים
        template = filter_minutiae(rawMinutiae, strictMask, cfg);
        descriptors = compute_descriptors(template, cfg);
        numPoints = size(template, 1);
        
        % >> ציור תחנה 6: תוצאה סופית
        plot_step(app.axStep6, ~skeletonImg, ['6. Final Result (' num2str(numPoints) ')']);
        hold(app.axStep6, 'on');
        
        % א. גבול חכם (מגנטה)
        if size(rawMinutiae, 1) >= 3
            try
                X = rawMinutiae(:,1); Y = rawMinutiae(:,2);
                idx = sub2ind(size(roiMask), round(Y), round(X));
                valid = roiMask(idx);
                validPts = [X(valid), Y(valid)];
                
                shrinkVal = 0.5;
                if isfield(cfg.filter, 'boundary_shrink_factor'), shrinkVal = cfg.filter.boundary_shrink_factor; end
                
                k = boundary(validPts(:,1), validPts(:,2), shrinkVal);
                plot(app.axStep6, validPts(k,1), validPts(k,2), 'm-', 'LineWidth', 2); 
            catch
            end
        end
        
        % ב. נקודות סופיות (אדום/ירוק)
        if ~isempty(template)
            termIdx = template(:,3) == 1;
            plot(app.axStep6, template(termIdx, 1), template(termIdx, 2), 'ro', 'LineWidth', 1.5, 'MarkerSize', 6);
            bifIdx = template(:,3) == 3;
            plot(app.axStep6, template(bifIdx, 1), template(bifIdx, 2), 'gs', 'LineWidth', 1.5, 'MarkerSize', 6);
        end
        hold(app.axStep6, 'off');

        app.lblStatus.Text = 'Done.';
        
    catch err
        app.lblStatus.Text = 'Error';
        uialert(app.UIFigure, ['Processing Error: ' err.message], 'Error');
        disp(err.message);
    end
end

% ========================================================
% פונקציית עזר פנימית לציור (נמצאת רק פעם אחת בסוף!)
% ========================================================
function plot_step(ax, img, titleText)
    imagesc(ax, img);
    colormap(ax, 'gray');
    axis(ax, 'image'); 
    axis(ax, 'off');
    
    % רקע שקוף למניעת שוליים לבנים
    set(ax, 'Color', 'none'); 
    
    title(ax, titleText, 'Interpreter', 'none');
end