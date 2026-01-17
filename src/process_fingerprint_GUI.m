function [template, roiMask, rawMinutiae, descriptors, img, debug] = process_fingerprint_GUI(img, app)
    % process_fingerprint_GUI - מעטפת גרפית (Wrapper)
    % עדכון: כעת מחזירה גם את 'debug' כפלט שישי כדי לאפשר גישה לתמונות ביניים
    
    template = []; roiMask = []; rawMinutiae = []; descriptors = []; debug = struct();
    
    try
        if isempty(app.CurrentConfig), error('Config is empty!'); end
        cfg = app.CurrentConfig;
        
        % הגדרת פונקציה לעדכון הסטטוס ב-GUI
        statusFcn = @(txt) updateStatus(app, txt);
        
        % --- קריאה למנוע הראשי ---
        % המנוע מחזיר את debug, ואנחנו מעבירים אותו החוצה
        [template, roiMask, rawMinutiae, descriptors, img, debug] = ...
            process_fingerprint(img, cfg, statusFcn);
        % -------------------------
        
        % מכאן והלאה: רק ציור לגרפים (Plotting)
        
        % 1. מקור
        plotIfExist(app, 'axStep1', img, '1. Original (Cropped)');
        
        % 2. מסיכה
        plotIfExist(app, 'axStep2', debug.roiMask, '2. ROI Mask');
        
        % 3. Gabor
        plotIfExist(app, 'axStep3', debug.enhancedImg, '3. Gabor Filtered');
        
        % 4. שלד
        plotIfExist(app, 'axStep4', ~debug.skeletonImg, '4. Skeleton');
        
        % 5. גולמי (Raw)
        if isprop(app, 'axStep5') && isvalid(app.axStep5)
            plot_step(app.axStep5, ~debug.skeletonImg, ['5. Raw (' num2str(size(rawMinutiae,1)) ')']);
            hold(app.axStep5, 'on');
            if ~isempty(rawMinutiae)
                plot(app.axStep5, rawMinutiae(:,1), rawMinutiae(:,2), 'b.', 'MarkerSize', 8);
            end
            hold(app.axStep5, 'off');
        end
        
        % 6. סופי
        if isprop(app, 'axStep6') && isvalid(app.axStep6)
            numPoints = size(template, 1);
            plot_step(app.axStep6, ~debug.skeletonImg, ['6. Final (' num2str(numPoints) ')']);
            hold(app.axStep6, 'on');
            
            % ציור הגבול החכם (Visual Only)
            if size(rawMinutiae, 1) >= 3
                try
                    shrinkVal = 0.5;
                    if isfield(cfg.filter, 'boundary_shrink_factor'), shrinkVal = cfg.filter.boundary_shrink_factor; end
                    
                    % חישוב מהיר רק לציור
                    X = round(rawMinutiae(:,1)); Y = round(rawMinutiae(:,2));
                    validIdx = (X>=1 & X<=size(roiMask,2) & Y>=1 & Y<=size(roiMask,1));
                    validPts = rawMinutiae(validIdx, 1:2);
                    
                    k = boundary(validPts(:,1), validPts(:,2), shrinkVal);
                    plot(app.axStep6, validPts(k,1), validPts(k,2), 'm-', 'LineWidth', 2); 
                catch
                end
            end
            
            % ציור הנקודות
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
        disp(['GUI Processing Error: ' err.message]);
        % אופציונלי: להציג הודעה למשתמש
        uialert(app.UIFigure, err.message, 'Processing Error');
    end
end

% פונקציות עזר פנימיות ל-GUI (לא משתנות)
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