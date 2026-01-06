%% run_visualizer.m - סקריפט לבחירת תמונה והצגת ה-Pipeline
clc; clear;

%% === הגדרות משתמש ===
% שנה ל-true כדי לעבוד מהר עם קובץ קבוע, או false כדי לבחור כל פעם
USE_FIXED_FILE = false; 

% שם הקובץ הקבוע (חייב להיות בתוך תיקיית data, או נתיב מלא)
FIXED_FILENAME = '102_1_skeleton.png'; 
%% ====================

fullPath = 'C:\Users\User\OneDrive - ac.sce.ac.il\מסמכים\MATLAB\fingerprint matlab\data';

% 1. לוגיקה לבחירת הקובץ
if USE_FIXED_FILE
    % --- אופציה א': טעינה מהירה של קובץ קבוע ---
    % מניחים שהקובץ נמצא בתיקיית data. אם לא, שנה את הנתיב כאן.
    fullPath = fullfile('data', FIXED_FILENAME);
    
    % בדיקה שהקובץ אכן קיים
    if ~isfile(fullPath)
        % ננסה לחפש אותו בתיקייה הנוכחית אם הוא לא ב-data
        fullPath = FIXED_FILENAME;
        if ~isfile(fullPath)
            error('הקובץ הקבוע "%s" לא נמצא! בדוק את השם או את הנתיב.', FIXED_FILENAME);
        end
    end
    fprintf('>> מצב אוטומטי: טוען תמונה %s\n', FIXED_FILENAME);
    
else
    % --- אופציה ב': בחירה ידנית עם חלון ---
    [fileName, pathName] = uigetfile({'*.tif;*.png;*.jpg;*.bmp', 'Fingerprint Images'}, ...
                                     'בחר תמונה לבדיקה', 'data/');
    
    if isequal(fileName, 0)
        disp('לא נבחרה תמונה. יציאה.');
        return;
    end
    fullPath = fullfile(pathName, fileName);
    fprintf('>> נבחר ידנית: %s\n', fileName);
end

% 2. טעינת התמונה וביצוע העיבוד
try
    img = imread(fullPath);
    
    % 3. הפעלת העיבוד במצב ויזואליזציה
    % הפרמטר 'true' מפעיל את ה-visualize_pipeline מתוך הפונקציה
    process_fingerprint(img, true);
    
catch err
    errordlg(['שגיאה בטעינה או בעיבוד: ' err.message]);
    disp(err.message);
end