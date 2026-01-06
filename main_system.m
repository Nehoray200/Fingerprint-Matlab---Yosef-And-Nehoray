%% ========================================================================
%% מערכת ביומטרית לזיהוי טביעת אצבע - main_system.m
%% ========================================================================
clc; clear; close all;

% --- 1. הגדרת נתיבים ---
addpath(genpath('src')); 
addpath('data');         

% --- 2. הגדרות מערכת ---
cfg = get_config();
dbFileName = cfg.db_filename; 
PASS_THRESHOLD = cfg.match.pass_threshold;
minPointsEnroll = cfg.enroll.min_minutiae; 

while true
    %% תפריט ראשי
    choice = menu('מערכת ביומטרית - תפריט ראשי', ...
                  '1. רישום משתמש בודד (Single Enrollment)', ...
                  '2. זיהוי משתמש בודד (Single Identification)', ...
                  '3. רישום המוני (Batch Enrollment)', ...
                  '4. זיהוי המוני + סטטיסטיקה (Batch Identification)', ...
                  '5. הצגת המאגר', ...
                  '6. יציאה');
              
    if choice == 6 || choice == 0
        disp('יציאה מהמערכת.');
        break;
    end
    
    %% משתנים לשימוש
    currentData = []; 
    currentImg = [];
    fullPath = '';
    
    %% --- טיפול במקרים 1 ו-2 (קבצים בודדים) ---
    if choice == 1 || choice == 2
        [file, path] = uigetfile({'*.tif;*.png;*.jpg;*.bmp', 'Fingerprint Files'}, ...
                                 'בחר תמונת טביעת אצבע', 'data/');
        
        if isequal(file, 0), continue; end 
        
        fullPath = fullfile(path, file);
        try
            currentImg = imread(fullPath);
            disp('>> מעבד תמונה...');
            [template, ~, ~, descriptors] = process_fingerprint(currentImg); 
            
            if size(template, 1) < minPointsEnroll
                msgbox(sprintf('איכות נמוכה: %d נקודות (דרוש %d).', size(template, 1), minPointsEnroll), 'שגיאה', 'error');
                continue;
            end
            
            currentData.minutiae = template;
            currentData.descriptors = descriptors;
            
        catch err
            errordlg(['שגיאה בעיבוד הקובץ: ' err.message]);
            continue;
        end
    end
    
    %% --- לוגיקה לפי בחירה ---
    switch choice
        
        % === 1. רישום בודד ===
        case 1
            name = inputdlg('הכנס שם משתמש:', 'רישום');
            if ~isempty(name) && ~isempty(name{1})
                add_user_to_db(dbFileName, name{1}, currentData, fullPath);
            end
            
        % === 2. זיהוי בודד ===
        case 2
            if ~isfile(dbFileName)
                msgbox('המאגר ריק.', 'שגיאה', 'error'); continue;
            end
            load(dbFileName, 'fingerprintDB');
            
            bestScore = 0;
            bestName = 'לא ידוע';
            bestAlignedPoints = [];
            bestDbTemplate = [];
            
            wb = waitbar(0, 'סורק מאגר...');
            for i = 1:length(fingerprintDB)
                waitbar(i/length(fingerprintDB), wb);
                
                dbData.minutiae = fingerprintDB(i).template;
                if isfield(fingerprintDB(i), 'descriptors')
                    dbData.descriptors = fingerprintDB(i).descriptors;
                else, dbData.descriptors = []; end
                
                [score, alignedData, ~] = find_best_match(dbData, currentData, 0);
                
                if score > bestScore
                    bestScore = score;
                    bestName = fingerprintDB(i).name;
                    bestAlignedPoints = alignedData;
                    bestDbTemplate = fingerprintDB(i).template;
                end
            end
            close(wb);
            
            if bestScore >= PASS_THRESHOLD
                msgbox(['זוהה: ' bestName ' (ציון: ' num2str(bestScore) ')'], 'הצלחה');
                visualize_match_result(currentImg, bestDbTemplate, bestAlignedPoints, bestName, bestScore);
            else
                msgbox(['לא נמצאה התאמה. ציון הכי גבוה: ' num2str(bestScore)], 'כישלון', 'error');
            end
            
        % === 3. רישום המוני ===
        case 3
            [files, path] = uigetfile({'*.tif;*.png;*.jpg;*.bmp', 'Fingerprint Files'}, ...
                                      'בחר תמונות לרישום', 'data/', 'MultiSelect', 'on');
            if isequal(files, 0), continue; end
            if ischar(files), files = {files}; end
            
            wb = waitbar(0, 'מבצע רישום המוני...');
            successCount = 0;
            for k = 1:length(files)
                waitbar(k/length(files), wb, sprintf('רושם: %s...', files{k}));
                fullPath = fullfile(path, files{k});
                try
                    img = imread(fullPath);
                    [template, ~, ~, descriptors] = process_fingerprint(img);
                    
                    if size(template, 1) >= minPointsEnroll
                        [~, nameByUser, ~] = fileparts(files{k});
                        tempData.minutiae = template;
                        tempData.descriptors = descriptors;
                        add_user_to_db(dbFileName, nameByUser, tempData, fullPath);
                        successCount = successCount + 1;
                    end
                catch, end
            end
            close(wb);
            msgbox(['נוספו ' num2str(successCount) ' משתמשים.'], 'סיום');

        % === 4. זיהוי המוני + חישוב אחוזי הצלחה ===
        case 4
            if ~isfile(dbFileName)
                msgbox('המאגר ריק.', 'שגיאה', 'error'); continue;
            end
            load(dbFileName, 'fingerprintDB');
            
            [files, path] = uigetfile({'*.tif;*.png;*.jpg;*.bmp', 'Fingerprint Files'}, ...
                                      'בחר תמונות לבדיקה', 'data/', 'MultiSelect', 'on');
            if isequal(files, 0), continue; end
            if ischar(files), files = {files}; end
            
            results = {}; 
            wb = waitbar(0, 'מבצע זיהוי המוני...');
            
            correctCount = 0;
            validCount = 0; % סופר רק תמונות שהצלחנו לעבד
            
            for k = 1:length(files)
                waitbar(k/length(files), wb, sprintf('בודק: %s...', files{k}));
                thisFile = files{k};
                fullPath = fullfile(path, thisFile);
                
                % --- חילוץ "הזהות האמיתית" משם הקובץ (Ground Truth) ---
                [~, fNameNoExt, ~] = fileparts(thisFile);
                parts = strsplit(fNameNoExt, '_');
                realID = parts{1}; % לוקח את החלק הראשון (למשל '101' מתוך '101_8')
                
                try
                    img = imread(fullPath);
                    [template, ~, ~, descriptors] = process_fingerprint(img);
                    
                    % דילוג על תמונות גרועות (לא נכנסות לסטטיסטיקה או נחשבות כישלון, לבחירתך)
                    % כאן נסמן כ"איכות נמוכה" ולא נספור באחוזים
                    if size(template, 1) < minPointsEnroll
                        results{end+1, 1} = thisFile;
                        results{end, 2} = realID;
                        results{end, 3} = '---';
                        results{end, 4} = 0;
                        results{end, 5} = 'איכות נמוכה';
                        continue;
                    end
                    
                    validCount = validCount + 1;
                    
                    % חיפוש במאגר
                    bestScore = 0;
                    bestMatchName = 'לא זוהה';
                    
                    currData.minutiae = template;
                    currData.descriptors = descriptors;
                    
                    for i = 1:length(fingerprintDB)
                        dbData.minutiae = fingerprintDB(i).template;
                        if isfield(fingerprintDB(i), 'descriptors')
                            dbData.descriptors = fingerprintDB(i).descriptors;
                        else, dbData.descriptors = []; end
                        
                        [score, ~, ~] = find_best_match(dbData, currData, 0);
                        
                        if score > bestScore
                            bestScore = score;
                            if score >= PASS_THRESHOLD
                                bestMatchName = fingerprintDB(i).name;
                            end
                        end
                    end
                    
                    % --- בדיקת הצלחה (Success Check) ---
                    % מחלצים גם את ה-ID מהשם שנמצא במאגר (למקרה שגם הוא 101_1)
                    matchParts = strsplit(bestMatchName, '_');
                    matchID = matchParts{1};
                    
                    if strcmp(realID, matchID)
                        status = 'V הצלחה';
                        correctCount = correctCount + 1;
                    else
                        status = 'X שגיאה';
                    end
                    
                    % שמירה לטבלה
                    results{end+1, 1} = thisFile;      % קובץ
                    results{end, 2} = realID;          % מי זה באמת
                    results{end, 3} = bestMatchName;   % מי המערכת חשבה שזה
                    results{end, 4} = bestScore;       % ציון
                    results{end, 5} = status;          % סטטוס
                    
                catch err
                    results{end+1, 1} = thisFile;
                    results{end, 2} = realID;
                    results{end, 3} = 'Error';
                    results{end, 4} = 0;
                    results{end, 5} = 'שגיאה';
                end
            end
            close(wb);
            
            % --- חישוב אחוזי הצלחה ---
            if validCount > 0
                successRate = (correctCount / validCount) * 100;
            else
                successRate = 0;
            end
            
            % --- הצגת התוצאות ---
            f = figure('Name', 'תוצאות זיהוי וסטטיסטיקה', 'NumberTitle', 'off', ...
                       'Position', [100 100 650 500], 'MenuBar', 'none');
                   
            % כותרת עם האחוזים
            uicontrol('Style', 'text', 'Parent', f, ...
                      'String', sprintf('אחוזי הצלחה: %.2f%% (%d/%d)', successRate, correctCount, validCount), ...
                      'FontSize', 16, 'FontWeight', 'bold', 'ForegroundColor', 'blue', ...
                      'Position', [20 450 600 30]);
            
            % הטבלה
            t = uitable(f, 'Data', results, ...
                        'ColumnName', {'שם קובץ', 'זהות אמיתית', 'זוהה כ-', 'ציון', 'סטטוס'}, ...
                        'ColumnWidth', {120, 80, 120, 60, 80}, ...
                        'Position', [20 20 610 420]);
            
        % === 5. הצגת המאגר ===
        case 5
            if isfile(dbFileName)
                load(dbFileName, 'fingerprintDB');
                if isempty(fingerprintDB)
                    msgbox('המאגר קיים אך ריק.');
                else
                    listdlg('ListString', {fingerprintDB.name}, 'Name', 'רשימת משתמשים', 'ListSize', [300 400]);
                end
            else
                msgbox('אין נתונים.');
            end
    end
end