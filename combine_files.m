%% סקריפט לאיחוד כל קבצי הקוד לפרויקט אחד
% הסקריפט עובר על כל התיקיות, מוצא קבצי .m ומעתיק אותם לקובץ פלט אחד.
clc; clear; close all;

%% 1. הגדרות
outputFileName = 'Full_Project_Code.txt'; % שם הקובץ שיוצר (סיומת txt כדי שלא ירוץ בטעות)
excludePattern = 'combine_files.m';       % כדי לא להעתיק את הסקריפט הזה עצמו

%% 2. בחירת תיקייה ראשית
disp('אנא בחר את התיקייה הראשית של הפרויקט...');
folderPath = uigetdir(pwd, 'בחר תיקייה לסריקה');

if isequal(folderPath, 0)
    disp('לא נבחרה תיקייה. יציאה.');
    return;
end

%% 3. מציאת כל קבצי ה-m (כולל תתי-תיקיות)
% הסימון ** אומר למאטלב לחפש גם בתוך תתי-תיקיות
files = dir(fullfile(folderPath, '**', '*.m'));

% סינון תיקיות (לפעמים dir מחזיר תיקיות)
files = files(~[files.isdir]);

if isempty(files)
    disp('לא נמצאו קבצי MATLAB בתיקייה זו.');
    return;
end

%% 4. יצירת הקובץ המאוחד
fidOut = fopen(outputFileName, 'w', 'n', 'UTF-8'); % פתיחה לכתיבה בקידוד UTF-8 (תומך עברית)

if fidOut == -1
    error('לא ניתן ליצור את קובץ הפלט. בדוק הרשאות כתיבה.');
end

fprintf('נמצאו %d קבצים. מתחיל באיחוד...\n', length(files));
h = waitbar(0, 'מאחד קבצים...');

totalLines = 0;

for k = 1:length(files)
    waitbar(k/length(files), h, sprintf('מעבד: %s', files(k).name));
    
    % דילוג על הסקריפט הנוכחי אם הוא נמצא בתיקייה
    if strcmp(files(k).name, excludePattern)
        continue;
    end
    
    fullFilePath = fullfile(files(k).folder, files(k).name);
    
    try
        % קריאת תוכן הקובץ
        fileContent = fileread(fullFilePath);
        
        % --- כתיבת כותרת הפרדה ברורה ---
        fprintf(fidOut, '%% ========================================================================\n');
        fprintf(fidOut, '%% FILENAME: %s\n', files(k).name);
        fprintf(fidOut, '%% PATH:     %s\n', files(k).folder);
        fprintf(fidOut, '%% ========================================================================\n\n');
        
        % כתיבת התוכן
        fprintf(fidOut, '%s\n\n', fileContent);
        
        % הוספת רווחים בסוף הקובץ
        fprintf(fidOut, '\n\n');
        
    catch err
        fprintf('שגיאה בקריאת הקובץ %s: %s\n', files(k).name, err.message);
    end
end

% סגירת הקובץ ומחיקת ה-waitbar
fclose(fidOut);
close(h);

disp('--------------------------------------------------');
disp(['✅ התהליך הסתיים בהצלחה!']);
disp(['📁 כל הקוד נמצא בקובץ: ' outputFileName]);
disp('--------------------------------------------------');
% פתיחת הקובץ שנוצר לצפייה
winopen(outputFileName);