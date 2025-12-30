%% ========================================================================
%% מערכת ביומטרית לזיהוי טביעת אצבע - הגרסה הסופית
%% ========================================================================
clc; clear; close all;

% --- הגדרות מערכת ---
dbFileName = 'fingerprint_database.mat';
PASS_THRESHOLD = 50; % ציון מינימלי למעבר (מספר נקודות תואמות)

while true
    %% 1. תפריט ראשי
    choice = menu('מערכת ביומטרית - תפריט ראשי', ...
                  '1. רישום משתמש חדש (Enrollment)', ...
                  '2. זיהוי משתמש (Identification)', ...
                  '3. הצגת רשימת המשתמשים במאגר', ...
                  '4. יציאה');
              
    if choice == 4 || choice == 0
        disp('להתראות!');
        break;
    end
    
    %% 2. שלב משותף: טעינת תמונה ועיבוד (Pipeline)
    % אנחנו מבצעים את העיבוד הכבד כאן, לפני שמחליטים אם לרשום או לזהות
    currentTemplate = [];
    currentImg = [];
    
    if choice == 1 || choice == 2
        [file, path] = uigetfile({'*.tif;*.png;*.jpg;*.bmp', 'Fingerprint Images'}, 'בחר תמונה');
        if isequal(file, 0), continue; end % המשתמש ביטל
        
        currentImg = imread(fullfile(path, file));
        
        % --- קריאה לפונקציית המעטפת (Wrapper) ---
        % שים לב: כאן קוראים לפונקציה process_fingerprint ולא main_step2
        disp('>> מפעיל עיבוד תמונה (Pipeline)...');
        try
            [currentTemplate, ~, ~] = process_fingerprint(currentImg);
        catch err
            errordlg(['שגיאה בעיבוד התמונה: ' err.message]);
            continue;
        end
        
        % בדיקת איכות: אם לא מצאנו מספיק נקודות, אין טעם להמשיך
        if size(currentTemplate, 1) < 8
            msgbox('איכות התמונה נמוכה מדי (לא נמצאו מספיק נקודות). נסה תמונה אחרת.', 'שגיאה', 'error');
            continue;
        end
    end

    %% 3. לוגיקה לפי בחירה
    switch choice
        
        % ---------------------------------------------------------
        % אפשרות 1: רישום (Enrollment)
        % ---------------------------------------------------------
        case 1
            name = inputdlg('הכנס שם משתמש לשמירה:', 'רישום משתמש');
            if ~isempty(name) && ~isempty(name{1})
                % קריאה לפונקציית עזר להוספה למאגר
                add_user_to_db(dbFileName, name{1}, currentTemplate, fullfile(path, file));
            end

        % ---------------------------------------------------------
        % אפשרות 2: זיהוי (Identification)
        % ---------------------------------------------------------
        case 2
            if ~isfile(dbFileName)
                msgbox('המאגר ריק. נא לבצע רישום תחילה.', 'שגיאה', 'error');
                continue;
            end
            
            load(dbFileName, 'fingerprintDB');
            numUsers = length(fingerprintDB);
            disp(['>> מתחיל סריקה מול ' num2str(numUsers) ' משתמשים...']);
            
            % משתנים לשמירת התוצאה הטובה ביותר
            bestScore = 0;
            bestMatchName = 'לא ידוע';
            bestAlignedPoints = [];
            bestTemplateFound = [];
            
            % חלון טעינה
            wb = waitbar(0, 'סורק מאגר נתונים...');
            
            % === לולאת ההשוואה (1 מול N) ===
            for i = 1:numUsers
                waitbar(i/numUsers, wb, ['בודק מול: ' fingerprintDB(i).name]);
                
                dbTemplate = fingerprintDB(i).template;
                
                % שימוש בפונקציית ההתאמה שלנו
                % הפרמטר השלישי (סף) הוא 0 כי אנחנו רוצים את הציון המדויק להשוואה
                [score, alignedData, ~] = find_best_match(dbTemplate, currentTemplate, 0);
                
                % אם זה הציון הכי גבוה שראינו עד עכשיו - נשמור אותו
                if score > bestScore
                    bestScore = score;
                    bestMatchName = fingerprintDB(i).name;
                    bestAlignedPoints = alignedData;
                    bestTemplateFound = dbTemplate;
                end
            end
            close(wb);
            
            % === שלב ההחלטה (Decision Logic) ===
            if bestScore >= PASS_THRESHOLD
                % -- עבר --
                resultText = sprintf('התאמה נמצאה!\nמשתמש: %s\nציון: %d (מעל הסף %d)', ...
                                     bestMatchName, bestScore, PASS_THRESHOLD);
                msgbox(resultText, 'ACCESS GRANTED', 'help'); % אייקון ירוק/וי
                
                % הצגת התוצאה בגרף
                visualize_result(currentImg, bestTemplateFound, bestAlignedPoints, bestMatchName, bestScore, true);
            else
                % -- נכשל --
                resultText = sprintf('לא נמצאה התאמה.\nהציון הכי קרוב: %d (המשתמש: %s)\nנדרש מיניмум: %d', ...
                                     bestScore, bestMatchName, PASS_THRESHOLD);
                msgbox(resultText, 'ACCESS DENIED', 'error'); % אייקון אדום/שגיאה
                
                % הצגת הכישלון בגרף (אופציונלי)
                visualize_result(currentImg, bestTemplateFound, bestAlignedPoints, bestMatchName, bestScore, false);
            end
            
        % ---------------------------------------------------------
        % אפשרות 3: הצגת רשימה
        % ---------------------------------------------------------
        case 3
            if isfile(dbFileName)
                load(dbFileName, 'fingerprintDB');
                if isempty(fingerprintDB)
                    msgbox('הקובץ קיים אך המאגר ריק.');
                else
                    names = {fingerprintDB.name};
                    listdlg('ListString', names, 'Name', 'רשימת משתמשים', ...
                            'PromptString', ['סה"כ רשומים: ' num2str(length(names))], ...
                            'SelectionMode', 'single');
                end
            else
                msgbox('המאגר טרם נוצר.');
            end
    end
end

%% ========================================================================
%% פונקציות עזר (Helper Functions)
%% ========================================================================

function add_user_to_db(fname, name, template, path)
    % יצירה או טעינה של המאגר בצורה בטוחה
    if isfile(fname)
        load(fname, 'fingerprintDB');
        % וידוא שהשדה imagePath קיים (למקרה של גרסאות ישנות)
        if ~isfield(fingerprintDB, 'imagePath')
            [fingerprintDB(:).imagePath] = deal('');
        end
    else
        fingerprintDB = struct('name', {}, 'template', {}, 'imagePath', {});
    end
    
    newEntry.name = name;
    newEntry.template = template;
    newEntry.imagePath = path;
    
    fingerprintDB(end+1) = newEntry;
    save(fname, 'fingerprintDB');
    msgbox(['המשתמש ' name ' נשמר בהצלחה!'], 'Success');
end

function visualize_result(img, dbTemp, alignedInput, name, score, isPass)
    figure('Name', 'Authentication Result', 'NumberTitle', 'off');
    imshow(img); hold on;
    
    if isPass
        titleColor = 'g'; % ירוק
        statusText = ['ACCESS GRANTED: ' name];
    else
        titleColor = 'r'; % אדום
        statusText = ['ACCESS DENIED (Best guess: ' name ')'];
    end
    
    title({statusText, ['Score: ' num2str(score)]}, 'Color', titleColor, 'FontSize', 14, 'FontWeight', 'bold');
    
    if ~isempty(dbTemp) && ~isempty(alignedInput)
        % ציור הנקודות מהמאגר (אדום - המקור)
        plot(dbTemp(:,1), dbTemp(:,2), 'ro', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Database Template');
        % ציור הנקודות מהסריקה הנוכחית (ירוק - אחרי הזזה)
        plot(alignedInput(:,1), alignedInput(:,2), 'g+', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Input (Aligned)');
        legend show;
    end
    hold off;
end