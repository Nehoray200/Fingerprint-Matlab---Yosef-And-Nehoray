%% ========================================================================
%% מערכת ביומטרית לזיהוי טביעת אצבע - main_system.m
%% ========================================================================
clc; clear; close all;

% --- 1. הגדרת נתיבים ---
% הוספת תיקיית ה-src ותת-התיקיות שלה
addpath(genpath('src')); 
% הוספת תיקיית התמונות
addpath('data');         

% --- 2. הגדרות מערכת ---
cfg = get_config();
dbFileName = cfg.db_filename; % שימוש בשם מהקונפיגורציה
PASS_THRESHOLD = cfg.match.pass_threshold;

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
    currentData = []; 
    currentImg = [];
    
    if choice == 1 || choice == 2
        % בחירת קובץ
        [file, path] = uigetfile({'*.tif;*.png;*.jpg;*.bmp', 'Fingerprint Files'}, ...
                                 'בחר תמונת טביעת אצבע', 'data/');
        
        if isequal(file, 0), continue; end 
        
        fullPath = fullfile(path, file);
        currentImg = imread(fullPath);
        
        % --- עיבוד התמונה ---
        disp('>> מעבד תמונה (Pipeline)...');
        try
            % עיבוד מלא: מחזיר גם את הנקודות (template) וגם את המתארים (descriptors)
            [template, ~, ~, descriptors] = process_fingerprint(currentImg);
            
            % אריזה למבנה נתונים
            currentData.minutiae = template;
            currentData.descriptors = descriptors;
            
        catch err
            errordlg(['שגיאה בעיבוד: ' err.message]);
            continue;
        end
        
        % בדיקת איכות
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
                % קריאה לפונקציה חיצונית בתיקיית src
                add_user_to_db(dbFileName, name{1}, currentData, fullPath);
            end
            
        % --- זיהוי (Identification) ---
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
                
                % הכנת נתונים מהמאגר
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
            
            % תוצאות
            if bestScore >= PASS_THRESHOLD
                msgbox(['זוהה: ' bestName ' (ציון: ' num2str(bestScore) ')'], 'הצלחה');
                % קריאה לפונקציה חיצונית בתיקיית src
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