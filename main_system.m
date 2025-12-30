%% ========================================================================
%% מערכת ביומטרית לזיהוי טביעת אצבע - main_system.m
%% ========================================================================
clc; clear; close all;

% --- 1. הגדרת נתיבים ---
addpath(genpath('src')); % מוסיף את תיקיית src
addpath('data');         % מוסיף את תיקיית התמונות

% --- 2. הגדרות מערכת ---
dbFileName = 'fingerprint_database.mat';

% טעינת קונפיגורציה (חובה ראשון!)
if exist('get_config', 'file')
    cfg = get_config();
else
    warning('קובץ config לא נמצא, משתמש בערכי ברירת מחדל.');
    cfg.match.pass_threshold = 12; 
end

% קביעת סף המעבר
if isfield(cfg, 'match') && isfield(cfg.match, 'pass_threshold')
    PASS_THRESHOLD = cfg.match.pass_threshold;
else
    PASS_THRESHOLD = 12;
end

while true
    %% תפריט ראשי
    choice = menu('מערכת ביומטרית - תפריט ראשי', ...
                  '1. רישום משתמש (Enrollment)', ...
                  '2. זיהוי משתמש (Identification)', ...
                  '3. הצגת המאגר', ...
                  '4. יציאה');
              
    if choice == 4 || choice == 0
        disp('יציאה מהמערכת.');
        break;
    end
    
    %% שלב משותף: טעינת תמונה ועיבוד (Pipeline)
    currentData = []; % אתחול המבנה
    currentImg = [];
    
    if choice == 1 || choice == 2
        % בחירת קובץ
        [file, path] = uigetfile({'*.tif;*.png;*.jpg;*.bmp', 'Fingerprint Files'}, ...
                                 'בחר תמונת טביעת אצבע', 'data/');
        
        if isequal(file, 0), continue; end % המשתמש ביטל
        
        fullPath = fullfile(path, file);
        currentImg = imread(fullPath);
        
        % --- עיבוד התמונה ---
        disp('>> מעבד תמונה (Pipeline)...');
        try
            % קריאה לפונקציה המעודכנת שמחזירה גם descriptors
            % (הנחה: עדכנת את process_fingerprint.m לפי ההוראות הקודמות)
            [template, ~, ~, descriptors] = process_fingerprint(currentImg);
            
            % אריזת הנתונים למבנה מסודר להעברה
            currentData.minutiae = template;
            currentData.descriptors = descriptors;
            
        catch err
            errordlg(['שגיאה בעיבוד: ' err.message]);
            continue;
        end
        
        % בדיקת איכות בסיסית
        if size(currentData.minutiae, 1) < 8
            msgbox('איכות התמונה נמוכה מדי (מעט מדי נקודות).', 'שגיאה', 'error');
            continue;
        end
    end
    
    %% לוגיקה לפי בחירה
    switch choice
        % --- רישום (Enrollment) ---
        case 1
            name = inputdlg('הכנס שם משתמש:', 'רישום');
            if ~isempty(name) && ~isempty(name{1})
                % שליחת המבנה המלא (נקודות + מתארים) לפונקציית השמירה
                add_user_to_db(dbFileName, name{1}, currentData, fullPath);
            end
            
        % --- זיהוי (Identification) ---
        case 2
            if ~isfile(dbFileName)
                msgbox('המאגר ריק. נא לבצע רישום תחילה.', 'שגיאה', 'error');
                continue;
            end
            
            load(dbFileName, 'fingerprintDB');
            
            % אתחול משתנים למציאת ההתאמה הטובה ביותר
            bestScore = 0;
            bestName = 'לא ידוע';
            bestAlignedPoints = [];
            bestDbTemplate = [];
            
            wb = waitbar(0, 'סורק מאגר...');
            
            for i = 1:length(fingerprintDB)
                waitbar(i/length(fingerprintDB), wb);
                
                % הכנת הנתונים מהמאגר להשוואה
                % (בודקים אם המאגר מכיל descriptors, למקרה שהוא ישן)
                dbData.minutiae = fingerprintDB(i).template;
                if isfield(fingerprintDB(i), 'descriptors')
                    dbData.descriptors = fingerprintDB(i).descriptors;
                else
                    % תמיכה לאחור או טיפול בשגיאה אם המאגר ישן
                    dbData.descriptors = []; 
                end
                
                % קריאה לפונקציית ההשוואה
                [score, alignedData, ~] = find_best_match(dbData, currentData, 0);
                
                % בדיקה אם זו התוצאה הכי טובה עד כה
                if score > bestScore
                    bestScore = score;
                    bestName = fingerprintDB(i).name;
                    bestAlignedPoints = alignedData;
                    bestDbTemplate = fingerprintDB(i).template;
                end
            end
            close(wb);
            
            % הצגת התוצאות
            if bestScore >= PASS_THRESHOLD
                msgbox(['זוהה: ' bestName ' (ציון: ' num2str(bestScore) ')'], 'הצלחה');
                visualize_match_result(currentImg, bestDbTemplate, bestAlignedPoints, bestName, bestScore);
            else
                msgbox(['לא נמצאה התאמה. הציון הגבוה ביותר: ' num2str(bestScore)], 'כישלון', 'error');
            end
            
        % --- הצגת המאגר ---
        case 3
            if isfile(dbFileName)
                load(dbFileName, 'fingerprintDB');
                if isempty(fingerprintDB)
                    msgbox('המאגר קיים אך ריק.');
                else
                    listdlg('ListString', {fingerprintDB.name}, 'Name', 'משתמשים רשומים');
                end
            else
                msgbox('אין נתונים.');
            end
    end
end

%% --- פונקציות עזר פנימיות ל-Main ---

function add_user_to_db(fname, name, dataStruct, path)
    % פונקציה לשמירת משתמש חדש במאגר
    if isfile(fname)
        load(fname, 'fingerprintDB');
        % אם זה מאגר ישן בלי השדה descriptors, נוסיף אותו
        if ~isfield(fingerprintDB, 'descriptors')
             [fingerprintDB(:).descriptors] = deal([]); 
        end
    else
        % יצירת מאגר חדש אם לא קיים
        fingerprintDB = struct('name', {}, 'template', {}, 'descriptors', {}, 'imagePath', {});
    end
    
    newEntry.name = name;
    newEntry.template = dataStruct.minutiae;       % הנקודות (x,y,type,theta)
    newEntry.descriptors = dataStruct.descriptors; % המתארים החדשים (Feature Vectors)
    newEntry.imagePath = path;
    
    fingerprintDB(end+1) = newEntry;
    
    save(fname, 'fingerprintDB');
    msgbox('משתמש נשמר בהצלחה!');
end

function visualize_match_result(img, dbTemp, alignedInput, name, score)
    % פונקציה להצגה גרפית של ההתאמה
    figure('Name', 'תוצאת זיהוי', 'NumberTitle', 'off');
    imshow(img); hold on;
    title(['Match: ' name ' (Score: ' num2str(score) ')']);
    
    if ~isempty(dbTemp) && ~isempty(alignedInput)
        % הצגת הנקודות מהמאגר (אדום - עיגול)
        plot(dbTemp(:,1), dbTemp(:,2), 'ro', 'LineWidth', 2, 'MarkerSize', 8);
        % הצגת הנקודות מהקלט אחרי היישור (ירוק - פלוס)
        plot(alignedInput(:,1), alignedInput(:,2), 'g+', 'LineWidth', 2, 'MarkerSize', 8);
        
        legend('Database Template', 'Input (Aligned)', 'Location', 'best');
    end
    hold off;
end