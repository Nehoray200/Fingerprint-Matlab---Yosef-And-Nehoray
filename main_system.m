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

while true
    %% תפריט ראשי
    choice = menu('מערכת ביומטרית - תפריט ראשי', ...
                  '1. רישום משתמש בודד (Single Enrollment)', ...
                  '2. זיהוי משתמש (Identification)', ...
                  '3. רישום המוני מתמונות (Batch Enrollment)', ...
                  '4. הצגת המאגר', ...
                  '5. יציאה');
              
    if choice == 5 || choice == 0
        disp('יציאה מהמערכת.');
        break;
    end
    
    %% משתנים לשימוש (מאופסים כל לולאה)
    currentData = []; 
    currentImg = [];
    fullPath = '';
    
    %% --- טיפול במקרים 1 ו-2 (דורשים קובץ בודד) ---
    if choice == 1 || choice == 2
        [file, path] = uigetfile({'*.tif;*.png;*.jpg;*.bmp', 'Fingerprint Files'}, ...
                                 'בחר תמונת טביעת אצבע', 'data/');
        
        if isequal(file, 0), continue; end 
        
        fullPath = fullfile(path, file);
        try
            currentImg = imread(fullPath);
            
            % עיבוד (שימוש ב-process_fingerprint שלך)
            disp('>> מעבד תמונה...');
            [template, ~, ~, descriptors] = process_fingerprint(currentImg); % ברירת מחדל: ללא ציור
            
            % בדיקת איכות
            if size(template, 1) < 8
                msgbox('איכות התמונה נמוכה מדי (מעט מדי נקודות).', 'שגיאה', 'error');
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
        
        % === 1. רישום משתמש בודד ===
        case 1
            name = inputdlg('הכנס שם משתמש:', 'רישום');
            if ~isempty(name) && ~isempty(name{1})
                add_user_to_db(dbFileName, name{1}, currentData, fullPath);
            end
            
        % === 2. זיהוי משתמש ===
        case 2
            if ~isfile(dbFileName)
                msgbox('המאגר ריק. נא לבצע רישום תחילה.', 'שגיאה', 'error');
                continue;
            end
            
            load(dbFileName, 'fingerprintDB');
            
            bestScore = 0;
            bestName = 'לא ידוע';
            bestAlignedPoints = [];
            bestDbTemplate = [];
            
            wb = waitbar(0, 'סורק מאגר...');
            
            for i = 1:length(fingerprintDB)
                waitbar(i/length(fingerprintDB), wb);
                
                % הכנת נתונים
                dbData.minutiae = fingerprintDB(i).template;
                if isfield(fingerprintDB(i), 'descriptors')
                    dbData.descriptors = fingerprintDB(i).descriptors;
                else
                    dbData.descriptors = [];
                end
                
                % השוואה
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
            
        % === 3. רישום המוני (Batch) ===
        case 3
            disp('--- התחלת רישום המוני ---');
            % בחירת מספר קבצים
            [files, path] = uigetfile({'*.tif;*.png;*.jpg;*.bmp', 'Fingerprint Files'}, ...
                                      'בחר תמונות (ניתן לבחור כמה ביחד)', 'data/', ...
                                      'MultiSelect', 'on');
                                  
            if isequal(files, 0), continue; end
            
            % המרה לתא (Cell Array) אם נבחר רק קובץ אחד
            if ischar(files), files = {files}; end
            
            wb = waitbar(0, 'מבצע רישום המוני...');
            successCount = 0;
            
            for k = 1:length(files)
                waitbar(k/length(files), wb, sprintf('מעבד תמונה %d מתוך %d...', k, length(files)));
                
                thisFile = files{k};
                fullPath = fullfile(path, thisFile);
                
                try
                    img = imread(fullPath);
                    
                    % עיבוד
                    [template, ~, ~, descriptors] = process_fingerprint(img); % ללא ויזואליזציה למהירות
                    
                    if size(template, 1) >= 8
                        % לוגיקת שם: שם הקובץ ללא הסיומת הופך לשם המשתמש
                        [~, nameByUser, ~] = fileparts(thisFile);
                        
                        tempData.minutiae = template;
                        tempData.descriptors = descriptors;
                        
                        % הוספה למאגר
                        add_user_to_db(dbFileName, nameByUser, tempData, fullPath);
                        successCount = successCount + 1;
                        disp(['V נרשם בהצלחה: ' nameByUser]);
                    else
                        disp(['X נכשל (איכות נמוכה): ' thisFile]);
                    end
                    
                catch err
                    disp(['X שגיאה בקובץ ' thisFile ': ' err.message]);
                end
            end
            close(wb);
            msgbox(['הרישום ההמוני הסתיים. נוספו: ' num2str(successCount) ' משתמשים.'], 'סיום');

        % === 4. הצגת המאגר ===
        case 4
            if isfile(dbFileName)
                load(dbFileName, 'fingerprintDB');
                if isempty(fingerprintDB)
                    msgbox('המאגר קיים אך ריק.');
                else
                    listdlg('ListString', {fingerprintDB.name}, 'Name', 'משתמשים רשומים', 'ListSize', [300 400]);
                end
            else
                msgbox('אין נתונים.');
            end
    end
end