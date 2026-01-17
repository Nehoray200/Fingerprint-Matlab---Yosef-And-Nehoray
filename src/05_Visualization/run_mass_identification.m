function run_mass_identification(app, fileList, basePath)
    % run_mass_identification - גרסה עם פס טעינה מותאם אישית (Custom Progress Bar)
    
    totalFiles = length(fileList);
    
    % 1. איפוס והגדרת סגנונות
    app.tblMassResults.Data = {};
    
    % --- איפוס פס הטעינה הידני ---
    % 1. משיגים את הרוחב המקסימלי של הבר (רוחב הרקע)
    maxWidth = app.pnlProgressBack.Position(3); 
    % 2. מאפסים את המילוי ל-0
    app.lblProgressFill.Position(3) = 0; 
    
    % עיצוב טבלה
    removeStyle(app.tblMassResults); 
    styleBlue = uistyle('BackgroundColor', '#3849c7', 'FontColor', '#ffffff', 'FontWeight', 'bold');
    styleWhite = uistyle('BackgroundColor', '#ffffff', 'FontColor', '#171b26');
    
    resultsData = {}; 
    successCount = 0;
    validCount = 0;
    lastStyledRow = 0; 
    
    threshold = 15;
    if isfield(app.CurrentConfig.match, 'pass_threshold')
        threshold = app.CurrentConfig.match.pass_threshold;
    end
    
    % 2. הלולאה הראשית
    for k = 1:totalFiles
        filename = fileList{k}; 
        fullFilePath = fullfile(basePath, filename);
        nameParts = strsplit(filename, {'_', '.'});
        realID = nameParts{1};
        
        % עיבוד
        try
            [currentData, ~, err] = load_and_process_image(fullFilePath, app.CurrentConfig.enroll.min_minutiae);
        catch
            err = 'Critical Error';
        end
        
        if ~isempty(err)
            resultsData(end+1, :) = {filename, realID, '---', 0, 'שגיאת איכות'};
        else
            validCount = validCount + 1;
            bestScore = 0; bestName = 'Unknown';
            for i = 1:length(app.FingerprintDB)
                dbData.minutiae = app.FingerprintDB(i).template;
                dbData.descriptors = app.FingerprintDB(i).descriptors;
                if isfield(app.FingerprintDB(i), 'T_sq'), dbData.T_sq = app.FingerprintDB(i).T_sq; end
                [score, ~] = find_best_match(dbData, currentData);
                if score > bestScore, bestScore = score; bestName = app.FingerprintDB(i).name; end
            end
            
            isMatch = (bestScore >= threshold);
            if isMatch
                matchParts = strsplit(bestName, {'_', '.'});
                if strcmp(realID, matchParts{1})
                    successCount = successCount + 1; status = 'V (נכון)';
                else
                    status = 'X (שגוי)';
                end
            else
                status = 'X (לא זוהה)';
            end
            resultsData(end+1, :) = {filename, realID, bestName, bestScore, status};
        end
        
        % --- עדכון התצוגה (כולל הבר החדש) ---
        if mod(k, 5) == 0 || k == totalFiles
            
            app.tblMassResults.Data = resultsData;
            
            % --- צביעת שורות ---
            newRowsRange = (lastStyledRow + 1) : k;
            if ~isempty(newRowsRange)
                oddRows = newRowsRange(mod(newRowsRange, 2) == 1);
                evenRows = newRowsRange(mod(newRowsRange, 2) == 0);
                if ~isempty(oddRows), addStyle(app.tblMassResults, styleWhite, 'row', oddRows); end
                if ~isempty(evenRows), addStyle(app.tblMassResults, styleBlue, 'row', evenRows); end
                lastStyledRow = k;
            end
            
            % --- עדכון הבר החדש (שינוי רוחב) ---
            progressRatio = (k / totalFiles); % מספר בין 0 ל-1
            newWidth = maxWidth * progressRatio; % חישוב הרוחב החדש בפיקסלים
            app.lblProgressFill.Position(3) = newWidth; % השמת הרוחב החדש
            
            % עדכון טקסט
            app.lblMassStatus.Text = sprintf('מעבד... %.0f%% (%d/%d)', progressRatio*100, k, totalFiles);
            
            drawnow limitrate; 
        end
    end
    
    % 3. סיום
    currentAccuracy = 0;
    if validCount > 0
        currentAccuracy = (successCount / validCount) * 100;
    end
    
    % מילוי מלא בסוף (ליתר ביטחון)
    app.lblProgressFill.Position(3) = maxWidth;
    app.lblMassStatus.Text = sprintf('סיום! דיוק סופי: %.2f%%', currentAccuracy);
    
    uialert(app.UIFigure, 'תהליך הזיהוי ההמוני הסתיים בהצלחה.', 'הושלם', 'Icon', 'success');
end