% ========================================================================
% מערכת ביומטרית לזיהוי טביעת אצבע - main_system.m (גרסה נקייה)
% ========================================================================
clc; clear; close all;

% --- 1. הגדרת נתיבים ---
addpath(genpath('src'));
addpath('data');         

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
                  '5. הצגת המאגר', ...
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
                add_user_to_db(dbFileName, name{1}, currentData, fullfile(path, file));
                db_needs_reload = true; % לסמן לטעון מחדש
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
                
                [score, aligned, ~] = find_best_match(dbData, currentData);
                
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
            
        % === 3. רישום המוני ===
        case 3
            [files, path] = uigetfile({'*.tif;*.png;*.jpg', 'Images'}, 'בחר תמונות', 'data/', 'MultiSelect', 'on');
            if isequal(files, 0), continue; end
            if ischar(files), files = {files}; end
            
            hWait = waitbar(0, 'מבצע רישום...');
            cnt = 0;
            for k = 1:length(files)
                waitbar(k/length(files), hWait, sprintf('מעבד %d/%d', k, length(files)));
                [data, ~, err] = load_and_process_image(fullfile(path, files{k}), minPointsEnroll);
                
                if isempty(err)
                    [~, nameByUser, ~] = fileparts(files{k});
                    add_user_to_db(dbFileName, nameByUser, data, fullfile(path, files{k}));
                    cnt = cnt + 1;
                end
            end
            close(hWait);
            db_needs_reload = true;
            msgbox(['נוספו ' num2str(cnt) ' משתמשים למאגר.'], 'סיום');

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
                
                realID = strsplit(files{k}, '_'); realID = realID{1}; % הנחה: השם הוא ID_X.tif
                
                if ~isempty(err)
                    results(end+1, :) = {files{k}, realID, '---', 0, 'פסול (איכות)'};
                    continue;
                end
                
                valid = valid + 1;
                bestScore = 0; bestMatch = '---';
                
                for i = 1:length(fingerprintDB)
                    dbData.minutiae = fingerprintDB(i).template;
                    dbData.descriptors = fingerprintDB(i).descriptors;
                    [score, ~, ~] = find_best_match(dbData, currData);
                    
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

        % === 5. הצגת המאגר ===
        case 5
            if isempty(fingerprintDB)
                msgbox('המאגר ריק.');
            else
                listdlg('ListString', {fingerprintDB.name}, 'Name', 'משתמשים רשומים', 'ListSize', [300 400]);
            end
    end
end