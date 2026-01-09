%% run_visualizer.m - סקריפט לבחירת תמונה והצגת ה-Pipeline
clc; clear;

% --- תיקון קריטי: הוספת תיקיית הפונקציות ל-Path ---
% הפקודה הזו אומרת למאטלב לחפש פונקציות גם בתיקיית src
if exist('src', 'dir')
    addpath(genpath('src'));
else
    warning('תיקיית src לא נמצאה במיקום הנוכחי!');
end
% --------------------------------------------------

%% === הגדרות משתמש ===
USE_FIXED_FILE = true; 

% הגדר כאן רק את שם הקובץ
FIXED_FILENAME = '101_5.tif'; 

% הגדר כאן את הנתיב לתיקייה
FIXED_FOLDER = 'C:\Users\User\OneDrive - ac.sce.ac.il\מסמכים\MATLAB\fingerprint matlab\data\DB1_B';
%% ====================

% 1. לוגיקה לבחירת הקובץ
if USE_FIXED_FILE
    % חיבור הנתיב הארוך עם שם הקובץ
    fullPath = fullfile(FIXED_FOLDER, FIXED_FILENAME);
    
    % בדיקה שהקובץ אכן קיים
    if ~isfile(fullPath)
        % ניסיון אחרון: אולי הקובץ נמצא בתיקייה הנוכחית?
        if isfile(FIXED_FILENAME)
            fullPath = FIXED_FILENAME;
        else
            % הודעת שגיאה ברורה עם הנתיב שניסינו
            error('הקובץ לא נמצא!\nחיפשתי ב:\n%s\nוגם בתיקייה הנוכחית.', fullPath);
        end
    end
    fprintf('>> מצב אוטומטי: טוען תמונה %s\n', FIXED_FILENAME);
    
else
    % --- אופציה ב': בחירה ידנית עם חלון ---
    startPath = 'data/';
    if ~exist(startPath, 'dir'), startPath = pwd; end
    
    [fileName, pathName] = uigetfile({'*.png;*.tif;*.jpg;*.bmp', 'Fingerprint Images'}, ...
                                     'בחר תמונה לבדיקה', startPath);
    
    if isequal(fileName, 0)
        disp('לא נבחרו קבצים. יציאה.');
        return;
    end
    fullPath = fullfile(pathName, fileName);
    fprintf('>> נבחר ידנית: %s\n', fileName);
end

% 2. טעינת התמונה וביצוע העיבוד
try
    img = imread(fullPath);
    
    % 3. הפעלת העיבוד במצב ויזואליזציה
    % כעת הפונקציה תרוץ כי הוספנו את addpath('src') בהתחלה
    process_fingerprint(img, true);
    
catch err
    errordlg(['שגיאה בטעינה או בעיבוד: ' err.message]);
    rethrow(err); % הצגת השגיאה המלאה בחלון הפקודות
end