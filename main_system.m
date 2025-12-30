%% ========================================================================
%% מערכת ביומטרית לזיהוי טביעת אצבע - main_system.m
%% ========================================================================
clc; clear; close all;

% --- 1. הגדרת נתיבים (חובה כדי ש-MATLAB ימצא את הפונקציות) ---
addpath(genpath('src')); % מוסיף את תיקיית src וכל תתי-התיקיות שלה
addpath('data');         % מוסיף את תיקיית התמונות (אם צריך)

% --- 2. הגדרות מערכת ---
dbFileName = 'fingerprint_database.mat';
PASS_THRESHOLD = 12; % סף למעבר

% טעינת קונפיגורציה (אם תרצה להשתמש בה בהמשך)
if exist('get_config', 'file')
    cfg = get_config();
else
    warning('קובץ config לא נמצא, משתמש בערכי ברירת מחדל.');
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
    currentTemplate = [];
    currentImg = [];
    
    if choice == 1 || choice == 2
        % שימוש ב-uigetfile כדי לבחור תמונה מכל מקום
        [file, path] = uigetfile({'*.tif;*.png;*.jpg;*.bmp', 'Fingerprint Files'}, ...
                                 'בחר תמונת טביעת אצבע', 'data/'); % ברירת מחדל לתיקיית data
        
        if isequal(file, 0), continue; end % המשתמש ביטל
        
        fullPath = fullfile(path, file);
        currentImg = imread(fullPath);
        
        % --- קריאה לפונקציית העיבוד (שנמצאת ב-src) ---
        disp('>> מעבד תמונה (Pipeline)...');
        try
            % פה אנחנו קוראים לפונקציה Process שיצרנו קודם
            [currentTemplate, ~, ~] = process_fingerprint(currentImg);
        catch err
            errordlg(['שגיאה בעיבוד: ' err.message]);
            continue;
        end
        
        % בדיקת איכות
        if size(currentTemplate, 1) < 8
            msgbox('איכות התמונה נמוכה מדי (מעט מדי נקודות).', 'שגיאה', 'error');
            continue;
        end
    end

    %% לוגיקה לפי בחירה
    switch choice
        % --- רישום ---
        case 1
            name = inputdlg('הכנס שם משתמש:', 'רישום');
            if ~isempty(name) && ~isempty(name{1})
                add_user_to_db(dbFileName, name{1}, currentTemplate, fullPath);
            end

        % --- זיהוי ---
        case 2
            if ~isfile(dbFileName)
                msgbox('המאגר ריק.', 'שגיאה', 'error'); continue;
            end
            
            load(dbFileName, 'fingerprintDB');
            
            bestScore = 0;
            bestName = 'לא ידוע';
            bestAlignedPoints = [];
            bestDbTemplate = [];
            
            wb = waitbar(0, 'סורק...');
            for i = 1:length(fingerprintDB)
                waitbar(i/length(fingerprintDB), wb);
                
                % --- קריאה לפונקציית ההשוואה (שנמצאת ב-src) ---
                % וודא ששם הפונקציה תואם לקובץ שלך (find_best_match או הגרסה האופטימלית)
                [score, alignedData, ~] = find_best_match(fingerprintDB(i).template, currentTemplate, 0);
                
                if score > bestScore
                    bestScore = score;
                    bestName = fingerprintDB(i).name;
                    bestAlignedPoints = alignedData;
                    bestDbTemplate = fingerprintDB(i).template;
                end
            end
            close(wb);
            
            % הצגת תוצאות
            if bestScore >= PASS_THRESHOLD
                msgbox(['זוהה: ' bestName ' (ציון: ' num2str(bestScore) ')'], 'הצלחה');
                visualize_match_result(currentImg, bestDbTemplate, bestAlignedPoints, bestName, bestScore);
            else
                msgbox('לא נמצאה התאמה.', 'כישלון', 'error');
            end
            
        % --- הצגה ---
        case 3
            if isfile(dbFileName)
                load(dbFileName, 'fingerprintDB');
                listdlg('ListString', {fingerprintDB.name}, 'Name', 'משתמשים רשומים');
            else
                msgbox('אין נתונים.');
            end
    end
end

%% --- פונקציות עזר פנימיות ל-Main ---

function add_user_to_db(fname, name, template, path)
    if isfile(fname)
        load(fname, 'fingerprintDB');
        if ~isfield(fingerprintDB, 'imagePath'), [fingerprintDB(:).imagePath] = deal(''); end
    else
        fingerprintDB = struct('name', {}, 'template', {}, 'imagePath', {});
    end
    
    newEntry.name = name;
    newEntry.template = template;
    newEntry.imagePath = path;
    fingerprintDB(end+1) = newEntry;
    
    save(fname, 'fingerprintDB');
    msgbox('נשמר בהצלחה!');
end

function visualize_match_result(img, dbTemp, alignedInput, name, score)
    figure; imshow(img); hold on;
    title(['Match: ' name ' (Score: ' num2str(score) ')']);
    if ~isempty(dbTemp)
        plot(dbTemp(:,1), dbTemp(:,2), 'ro', 'LineWidth', 2);
        plot(alignedInput(:,1), alignedInput(:,2), 'g+');
        legend('Database', 'Input (Aligned)');
    end
    hold off;
end