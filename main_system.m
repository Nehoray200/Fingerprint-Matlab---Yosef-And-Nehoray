% ========================================================================
% מערכת ביומטרית לזיהוי טביעת אצבע - main_system.m (גרסה סופית ומתוקנת)
% ========================================================================
clc; clear; close all;

% --- 1. הגדרת נתיבים (חכם) ---
% קורא לפונקציה שמגדירה נתיבים יחסיים כדי שהקוד יעבוד בכל מחשב
setup_project();

% --- 2. הגדרות מערכת ---
cfg = get_config();
dbFileName = cfg.db_filename; 
PASS_THRESHOLD = cfg.match.pass_threshold;
minPointsEnroll = cfg.enroll.min_minutiae; 

% --- 3. ניהול זיכרון ---
fingerprintDB = []; 
db_needs_reload = true; 

while true
    %% טעינת מאגר חכמה
    if db_needs_reload
        if isfile(dbFileName)
            try
                loadedData = load(dbFileName, 'fingerprintDB');
                if isfield(loadedData, 'fingerprintDB')
                    fingerprintDB = loadedData.fingerprintDB;
                    disp(['>> המאגר נטען: ' num2str(length(fingerprintDB)) ' משתמשים.']);
                end
            catch
                warning('שגיאה בטעינת קובץ המאגר.');
                fingerprintDB = [];
            end
        else
            fingerprintDB = [];
        end
        db_needs_reload = false; 
    end
    
    %% תפריט ראשי
    choice = menu('מערכת ביומטרית - תפריט ראשי', ...
                  '1. רישום משתמש בודד', ...
                  '2. זיהוי משתמש בודד', ...
                  '3. רישום המוני (תיקייה)', ...
                  '4. זיהוי המוני + סטטיסטיקה', ...
                  '5. הצגת המאגר (מתקדם)', ...
                  '6. יציאה');
              
    if choice == 6 || choice == 0
        disp('יציאה מהמערכת.'); break;
    end
    
    %% לוגיקה לפי בחירה
    switch choice
        
        % === 1. רישום בודד ===
        case 1
            [file, path] = uigetfile({'*.tif;*.png;*.jpg', 'Fingerprint'}, 'בחר תמונה לרישום', 'data/');
            if isequal(file, 0), continue; end
            
            [currentData, ~, err] = load_and_process_image(fullfile(path, file), minPointsEnroll);
            
            if ~isempty(err)
                msgbox(err, 'שגיאה', 'error'); continue;
            end
            
            name = inputdlg('הכנס שם משתמש:', 'רישום');
            if ~isempty(name) && ~isempty(name{1})
                % הפונקציה add_user_to_db עודכנה לחשב T_sq גם כאן
                add_user_to_db(dbFileName, name{1}, currentData, fullfile(path, file));
                db_needs_reload = true; 
            end
            
        % === 2. זיהוי בודד ===
        case 2
            if isempty(fingerprintDB), msgbox('המאגר ריק.', 'שגיאה', 'error'); continue; end
            
            [file, path] = uigetfile({'*.tif;*.png;*.jpg', 'Fingerprint'}, 'בחר תמונה לזיהוי', 'data/');
            if isequal(file, 0), continue; end
            
            [currentData, currentImg, err] = load_and_process_image(fullfile(path, file), minPointsEnroll);
            
            if ~isempty(err)
                msgbox(err, 'שגיאה', 'error'); continue;
            end
            
            % תהליך החיפוש
            hWait = waitbar(0, 'מזהה...');
            bestScore = 0; bestName = 'לא ידוע'; bestTemplate = []; bestAligned = [];
            
            for i = 1:length(fingerprintDB)
                waitbar(i/length(fingerprintDB), hWait);
                dbData.minutiae = fingerprintDB(i).template;
                dbData.descriptors = fingerprintDB(i).descriptors;
                
                % בדיקת אופטימיזציה (אם קיימת במאגר)
                if isfield(fingerprintDB(i), 'T_sq')
                    dbData.T_sq = fingerprintDB(i).T_sq;
                end
                
                % --- תיקון: הפונקציה מחזירה רק 2 ערכים כעת ---
                [score, aligned] = find_best_match(dbData, currentData);
                
                if score > bestScore
                    bestScore = score;
                    bestName = fingerprintDB(i).name;
                    bestTemplate = fingerprintDB(i).template;
                    bestAligned = aligned;
                end
            end
            close(hWait);
            
            if bestScore >= PASS_THRESHOLD
                msgbox(['זוהה: ' bestName ' (ציון: ' num2str(bestScore) ')'], 'הצלחה');
                visualize_match_result(currentImg, bestTemplate, bestAligned, bestName, bestScore);
            else
                msgbox(['לא נמצאה התאמה. הציון הכי גבוה: ' num2str(bestScore)], 'כישלון', 'error');
            end
            
        % === 3. רישום המוני (אופטימלי) ===
        case 3
            [files, path] = uigetfile({'*.tif;*.png;*.jpg', 'Images'}, 'בחר תמונות', 'data/', 'MultiSelect', 'on');
            if isequal(files, 0), continue; end
            if ischar(files), files = {files}; end
            
            % טעינת המאגר הקיים
            currentDB = [];
            if isfile(dbFileName)
                try
                    tmp = load(dbFileName, 'fingerprintDB');
                    currentDB = tmp.fingerprintDB;
                catch
                    currentDB = struct('name', {}, 'template', {}, 'descriptors', {}, 'imagePath', {}, 'T_sq', {});
                end
            else
                currentDB = struct('name', {}, 'template', {}, 'descriptors', {}, 'imagePath', {}, 'T_sq', {});
            end
            
            hWait = waitbar(0, 'מבצע רישום...');
            numFiles = length(files);
            
            % --- תיקון: שימוש ב-Cell Array למניעת הקצאת זיכרון איטית ---
            tempDB = cell(numFiles, 1); 
            cnt = 0;
            
            for k = 1:numFiles
                waitbar(k/numFiles, hWait, sprintf('מעבד %d/%d', k, numFiles));
                
                fullFilePath = fullfile(path, files{k});
                [data, ~, err] = load_and_process_image(fullFilePath, minPointsEnroll);
                
                if isempty(err)
                    [~, nameByUser, ~] = fileparts(files{k});
                    
                    % בניית המבנה
                    newEntry = struct();
                    newEntry.name = nameByUser;
                    newEntry.template = data.minutiae;
                    newEntry.descriptors = data.descriptors;
                    newEntry.imagePath = fullFilePath;
                    
                    % חישוב T_sq מראש (אופטימיזציה)
                    newEntry.T_sq = sum(data.minutiae(:,1:2).^2, 2);
                    
                    % שמירה לתא במערך הזמני
                    tempDB{k} = newEntry;
                    cnt = cnt + 1;
                end
            end
            close(hWait);
            
            % מיזוג למאגר הראשי ושמירה בפעולה אחת
            tempDB = tempDB(~cellfun('isempty', tempDB));
            if ~isempty(tempDB)
                newStructs = [tempDB{:}]; 
                currentDB = [currentDB; newStructs(:)];
                
                fingerprintDB = currentDB;
                save(dbFileName, 'fingerprintDB');
                db_needs_reload = true;
                msgbox(['נוספו ' num2str(cnt) ' משתמשים למאגר בהצלחה!'], 'סיום');
            else
                msgbox('לא נוספו משתמשים (איכות נמוכה או שגיאה).', 'מידע');
            end

        % === 4. זיהוי המוני (בדיקות) ===
        case 4
            if isempty(fingerprintDB), msgbox('המאגר ריק.', 'שגיאה', 'error'); continue; end
            
            [files, path] = uigetfile({'*.tif;*.png;*.jpg', 'Images'}, 'בחר תמונות לבדיקה', 'data/', 'MultiSelect', 'on');
            if isequal(files, 0), continue; end
            if ischar(files), files = {files}; end
            
            results = {};
            hWait = waitbar(0, 'מריץ טסטים...');
            correct = 0; valid = 0;
            
            for k = 1:length(files)
                waitbar(k/length(files), hWait, sprintf('בודק %d/%d', k, length(files)));
                [currData, ~, err] = load_and_process_image(fullfile(path, files{k}), minPointsEnroll);
                
                realID = strsplit(files{k}, '_'); realID = realID{1}; 
                
                if ~isempty(err)
                    results(end+1, :) = {files{k}, realID, '---', 0, 'פסול (איכות)'};
                    continue;
                end
                
                valid = valid + 1;
                bestScore = 0; bestMatch = '---';
                
                for i = 1:length(fingerprintDB)
                    dbData.minutiae = fingerprintDB(i).template;
                    dbData.descriptors = fingerprintDB(i).descriptors;
                    
                    % בדיקת אופטימיזציה T_sq
                    if isfield(fingerprintDB(i), 'T_sq')
                        dbData.T_sq = fingerprintDB(i).T_sq;
                    end
                    
                    % --- תיקון: הפונקציה מחזירה רק 2 ערכים ---
                    [score, ~] = find_best_match(dbData, currData);
                    
                    if score > bestScore
                        bestScore = score;
                        if score >= PASS_THRESHOLD
                            bestMatch = fingerprintDB(i).name;
                        end
                    end
                end
                
                matchParts = strsplit(bestMatch, '_'); matchID = matchParts{1};
                isCorrect = strcmp(realID, matchID);
                if isCorrect, correct = correct + 1; status = 'V'; else, status = 'X'; end
                
                results(end+1, :) = {files{k}, realID, bestMatch, bestScore, status};
            end
            close(hWait);
            
            % הצגת טבלה
            succRate = 0; if valid > 0, succRate = (correct/valid)*100; end
            f = figure('Name', 'תוצאות', 'Position', [100 100 600 500], 'MenuBar', 'none');
            uitable(f, 'Data', results, 'ColumnName', {'קובץ', 'אמת', 'זוהה', 'ציון', 'סטטוס'}, ...
                    'Position', [20 20 560 420]);
            uicontrol(f, 'Style', 'text', 'String', sprintf('דיוק: %.1f%%', succRate), ...
                      'Position', [20 450 560 30], 'FontSize', 14, 'FontWeight', 'bold');

        % === 5. הצגת המאגר (משודרג - צפייה בנתונים) ===
        case 5
            if isempty(fingerprintDB)
                msgbox('המאגר ריק.', 'מידע');
            else
                % הכנת רשימה יפה לתצוגה שכוללת גם את מספר הנקודות
                displayList = cell(length(fingerprintDB), 1);
                for i = 1:length(fingerprintDB)
                    numPts = size(fingerprintDB(i).template, 1);
                    displayList{i} = sprintf('%s  [נקודות: %d]', fingerprintDB(i).name, numPts);
                end
                
                [idx, tf] = listdlg('ListString', displayList, ...
                                    'SelectionMode', 'single', ...
                                    'ListSize', [300 400], ...
                                    'Name', 'מאגר משתמשים', ...
                                    'PromptString', 'בחר משתמש לצפייה בפרטים:');
                
                if tf
                    selectedUser = fingerprintDB(idx);
                    
                    figure('Name', ['פרטי משתמש: ' selectedUser.name], ...
                           'NumberTitle', 'off', 'MenuBar', 'none', ...
                           'Position', [200 200 800 400]);
                    
                    % צד ימין: תמונה
                    subplot(1, 2, 1);
                    if isfield(selectedUser, 'imagePath') && exist(selectedUser.imagePath, 'file')
                        imshow(imread(selectedUser.imagePath));
                        title('תמונה מקורית', 'FontSize', 12);
                    else
                        axis off; 
                        text(0.5, 0.5, 'קובץ המקור לא נמצא', ...
                             'HorizontalAlignment', 'center', 'Color', 'r', 'FontSize', 14);
                    end
                    
                    % צד שמאל: נקודות
                    subplot(1, 2, 2);
                    pts = selectedUser.template;
                    plot(pts(:,1), pts(:,2), 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 4);
                    hold on;
                    quiver(pts(:,1), pts(:,2), cos(pts(:,4)), -sin(pts(:,4)), 0.3, 'r');
                    axis ij; grid on; axis equal;
                    title(['תבנית ביומטרית: ' num2str(size(pts,1)) ' נקודות'], 'FontSize', 12);
                    legend('Minutiae', 'Direction');
                    xlim([0 300]); ylim([0 300]); 
                end
            end
    end
end