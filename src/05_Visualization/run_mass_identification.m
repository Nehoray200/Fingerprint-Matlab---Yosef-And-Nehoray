function run_mass_identification(app, fileList, basePath)
    % run_mass_identification - גרסה המקבלת רשימת קבצים ספציפית
    % app: האפליקציה (לעדכון גרפים)
    % fileList: רשימת שמות הקבצים (Cell Array)
    % basePath: הנתיב לתיקייה בה הם נמצאים
    
    totalFiles = length(fileList);
    
    % 1. איפוס הטבלה והמד
    app.tblMassResults.Data = {};
    app.gaugeProgress.Value = 0; 
    
    % משתנים לסטטיסטיקה
    resultsData = {}; 
    successCount = 0;
    validCount = 0;
    
    % סף להצלחה
    threshold = 15;
    if isfield(app.CurrentConfig.match, 'pass_threshold')
        threshold = app.CurrentConfig.match.pass_threshold;
    end
    
    % 2. הלולאה הראשית (רוצה על הרשימה שקיבלנו)
    for k = 1:totalFiles
        filename = fileList{k}; % שליפת השם מהרשימה
        fullFilePath = fullfile(basePath, filename);
        
        % חילוץ ID (הנחה: 101_1.tif)
        nameParts = strsplit(filename, {'_', '.'});
        realID = nameParts{1};
        
        % --- עיבוד התמונה ---
        try
            [currentData, ~, err] = load_and_process_image(fullFilePath, app.CurrentConfig.enroll.min_minutiae);
        catch
            err = 'Critical Error';
        end
        
        % טיפול בשגיאות ואיכות נמוכה
        if ~isempty(err)
            resultsData(end+1, :) = {filename, realID, '---', 0, 'שגיאת איכות'};
        else
            validCount = validCount + 1;
            
            % --- חיפוש במאגר ---
            bestScore = 0;
            bestName = 'Unknown';
            
            for i = 1:length(app.FingerprintDB)
                dbData.minutiae = app.FingerprintDB(i).template;
                dbData.descriptors = app.FingerprintDB(i).descriptors;
                
                if isfield(app.FingerprintDB(i), 'T_sq')
                    dbData.T_sq = app.FingerprintDB(i).T_sq;
                end
                
                [score, ~] = find_best_match(dbData, currentData);
                
                if score > bestScore
                    bestScore = score;
                    bestName = app.FingerprintDB(i).name;
                end
            end
            
            % --- בדיקת תוצאה ---
            isMatch = (bestScore >= threshold);
            status = 'NO MATCH';
            
            if isMatch
                matchParts = strsplit(bestName, {'_', '.'});
                matchID = matchParts{1};
                
                if strcmp(realID, matchID)
                    successCount = successCount + 1;
                    status = 'V (נכון)';
                else
                    status = 'X (שגוי)';
                end
            else
                status = 'X (לא זוהה)';
            end
            
            % שמירת הנתונים
            resultsData(end+1, :) = {filename, realID, bestName, bestScore, status};
        end
        
        % --- עדכון ה-Progress Bar ---
        % מעדכנים כל 5 תמונות או אם זו התמונה האחרונה
        if mod(k, 5) == 0 || k == totalFiles
            
            progressPercent = (k / totalFiles) * 100;
            
            % עדכון המד
            app.gaugeProgress.Value = progressPercent;
            
            % עדכון הטבלה
            app.tblMassResults.Data = resultsData;
            
            % עדכון הטקסט
            app.lblMassStatus.Text = sprintf('מעבד... %.1f%% (%d/%d)', progressPercent, k, totalFiles);
            
            drawnow limitrate; 
        end
    end
    
    % 3. סיום
   currentAccuracy = 0;
    if validCount > 0
        currentAccuracy = (successCount / validCount) * 100;
    end
    
    app.gaugeProgress.Value = 100; 
    app.lblMassStatus.Text = sprintf('סיום! דיוק סופי: %.2f%%', currentAccuracy);
    
    % === התיקון כאן: הוספנו 'Icon', 'success' ===
    uialert(app.UIFigure, 'תהליך הזיהוי ההמוני הסתיים בהצלחה.', 'הושלם', 'Icon', 'success');
end