function [template, roiMask, rawMinutiae, descriptors, img] = process_fingerprint_GUI(img, app)
    % process_fingerprint_GUI - גרסה מעודכנת שמעבירה הגדרות למסיכה
    
    template = []; roiMask = []; rawMinutiae = []; descriptors = [];
    
    try
        if isempty(app.CurrentConfig), error('Config is empty!'); end
        cfg = app.CurrentConfig;
        
        updateStatus(app, 'Step 1/7: Preprocessing...');
        
        % 1. המרה לאפור
        if size(img, 3) == 3, img = rgb2gray(img); end
        img = im2double(img);
        img = adapthisteq(img, 'ClipLimit', 0.02);
        
        % --- שינוי קריטי: שולחים את cfg לפונקציה get_roi_mask ---
        fullMask = get_roi_mask(img, cfg);
        % -------------------------------------------------------
        
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
        
        img = img(r1:r2, c1:c2);
        roiMask = fullMask(r1:r2, c1:c2);
        
        plotIfExist(app, 'axStep1', img, '1. Original');
        
        % 2. סגמנטציה
        updateStatus(app, 'Step 2/7: Segmentation...');
        [normim, ~, ~] = ridgesegment(img, cfg.gabor.blk_sze, cfg.gabor.thresh);
        plotIfExist(app, 'axStep2', roiMask, '2. ROI Mask');

        % 3. Gabor
        updateStatus(app, 'Step 3/7: Gabor Filtering...');
        orientim = ridgeorient(normim, cfg.gabor.grad_sigma, cfg.gabor.block_sigma, cfg.gabor.smooth_sigma);
        [freqim, ~] = ridgefreq(normim, roiMask, orientim, cfg.gabor.freq_blk, ...
                                cfg.gabor.freq_wind, cfg.gabor.min_wl, cfg.gabor.max_wl);
        
        enhancedImg = ridgefilter(normim, orientim, freqim, cfg.gabor.kx, cfg.gabor.ky, 0);
        
        binOffset = 0;
        if isfield(cfg, 'binarize') && isfield(cfg.binarize, 'sens')
            binOffset = cfg.binarize.sens - 0.5; 
        end
        
        binaryImg = enhancedImg > binOffset; 
        binaryImg = binaryImg & roiMask; 
        binaryImg = bwareaopen(binaryImg, 10);
        binaryImg = ~bwareaopen(~binaryImg, 10);
        
        plotIfExist(app, 'axStep3', enhancedImg, '3. Gabor Filtered');

        % 4. שלד
        updateStatus(app, 'Step 4/7: Skeletonization...');
        skeletonImg = bwmorph(binaryImg, 'thin', Inf);
        skeletonImg = bwmorph(skeletonImg, 'clean');
        skeletonImg = bwmorph(skeletonImg, 'diag');
        skeletonImg = bwmorph(skeletonImg, 'spur', 5); 
        
        plotIfExist(app, 'axStep4', ~skeletonImg, '4. Skeleton');

        % 5. חילוץ
        updateStatus(app, 'Step 5/7: Raw Extraction...');
        
        erosionVal = 12;
        if isfield(cfg.roi, 'strict_erosion'), erosionVal = cfg.roi.strict_erosion; end
        seStrict = strel('disk', erosionVal);
        strictMask = imerode(roiMask, seStrict);
        
        rawMinutiae = extract_minutiae_features(skeletonImg, strictMask, cfg);
        
        if isprop(app, 'axStep5') && isvalid(app.axStep5)
            plot_step(app.axStep5, ~skeletonImg, ['5. Raw (' num2str(size(rawMinutiae,1)) ')']);
            hold(app.axStep5, 'on');
            if ~isempty(rawMinutiae)
                plot(app.axStep5, rawMinutiae(:,1), rawMinutiae(:,2), 'b.', 'MarkerSize', 8);
            end
            hold(app.axStep5, 'off');
        end

        % 6. סינון סופי
        updateStatus(app, 'Step 6/7: Final Filtering...');
        
        template = filter_minutiae(rawMinutiae, strictMask, cfg);
        descriptors = compute_descriptors(template, cfg);
        numPoints = size(template, 1);
        
        if isprop(app, 'axStep6') && isvalid(app.axStep6)
            plot_step(app.axStep6, ~skeletonImg, ['6. Final (' num2str(numPoints) ')']);
            hold(app.axStep6, 'on');
            
            % א. גבול חכם
            if size(rawMinutiae, 1) >= 3
                try
                    shrinkVal = 0.5;
                    if isfield(cfg.filter, 'boundary_shrink_factor'), shrinkVal = cfg.filter.boundary_shrink_factor; end
                    
                    X = round(rawMinutiae(:,1)); Y = round(rawMinutiae(:,2));
                    validIdx = (X>=1 & X<=size(roiMask,2) & Y>=1 & Y<=size(roiMask,1));
                    validPts = rawMinutiae(validIdx, 1:2);
                    
                    k = boundary(validPts(:,1), validPts(:,2), shrinkVal);
                    plot(app.axStep6, validPts(k,1), validPts(k,2), 'm-', 'LineWidth', 2); 
                catch
                end
            end
            
            % ב. נקודות
            if ~isempty(template)
                termIdx = template(:,3) == 1;
                plot(app.axStep6, template(termIdx, 1), template(termIdx, 2), 'ro', 'LineWidth', 1.5, 'MarkerSize', 6);
                bifIdx = template(:,3) == 3;
                plot(app.axStep6, template(bifIdx, 1), template(bifIdx, 2), 'gs', 'LineWidth', 1.5, 'MarkerSize', 6);
            end
            hold(app.axStep6, 'off');
        end
        
        updateStatus(app, 'Done.');
        
    catch err
        updateStatus(app, 'Error');
        disp(['Processing Error: ' err.message]);
    end
end

% פונקציות עזר (אותן פונקציות שהיו קודם)
function updateStatus(app, text)
    if isprop(app, 'lblStatus') && isvalid(app.lblStatus)
        app.lblStatus.Text = text;
        drawnow limitrate;
    end
end
function plotIfExist(app, axName, img, titleText)
    if isprop(app, axName) && isvalid(app.(axName))
        plot_step(app.(axName), img, titleText);
    end
end
function plot_step(ax, img, titleText)
    imagesc(ax, img);
    colormap(ax, 'gray');
    axis(ax, 'image'); 
    axis(ax, 'off');
    set(ax, 'Color', 'none'); 
    title(ax, titleText, 'Interpreter', 'none');
end