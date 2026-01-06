%% סקריפט משולב: Python (שיפור) + MATLAB (שלד)
clc; close all; clear;

% =========================================================================
% הגדרות חובה - שנה את הנתיב הזה למיקום שבו שמרת את קובץ הפייתון!
% =========================================================================
pythonScriptPath = 'gabor.py';
% =========================================================================

% בדיקה שהסקריפט של פייתון קיים
if ~exist(pythonScriptPath, 'file')
    error('לא מצאתי את קובץ הפייתון בנתיב: %s', pythonScriptPath);
end

% 1. בחירת קבצים
disp('אנא בחר את התמונות המקוריות לעיבוד...');
[files, path] = uigetfile({'*.tif;*.png;*.jpg;*.bmp;*.heic;', 'Image Files'; ...
                           '*.*', 'All Files'}, ...
                           'בחר תמונות (Ctrl לבחירה מרובה)', ...
                           'MultiSelect', 'on');

if isequal(files, 0)
    disp('לא נבחרו קבצים.'); return;
end
if ischar(files), files = {files}; end % המרה לתא בודד אם נבחר רק אחד

totalFiles = length(files);
h = waitbar(0, 'מאתחל תהליך...');

%% === לולאה על כל הקבצים ===
for k = 1:totalFiles
    
    originalFilename = files{k};
    fullPathInput = fullfile(path, originalFilename);
    
    waitbar(k/totalFiles, h, sprintf('שלב 1: פייתון מעבד את %s...', originalFilename));
    
    try
        % --- שלב א: הרצת Python דרך CMD ---
        % אנו בונים פקודה: python "script.py" "image.jpg"
        % השימוש במרכאות כפולות חשוב אם יש רווחים בשמות התיקיות
        commandStr = sprintf('python "%s" "%s"', pythonScriptPath, fullPathInput);
        
        [status, cmdOut] = system(commandStr);
        
        if status ~= 0
            % אם פייתון נכשל
            fprintf('  X שגיאה בפייתון עבור %s: %s\n', originalFilename, cmdOut);
            continue; 
        end
        
        % --- שלב ב: חישוב שם הקובץ שפייתון יצר ---
        % הפייתון מוסיף _enhanced ושומר כ-png
        [~, nameNoExt, ~] = fileparts(originalFilename);
        enhancedFilename = [nameNoExt, '_enhanced.png'];
        fullPathEnhanced = fullfile(path, enhancedFilename);
        
        % בדיקה שהקובץ באמת נוצר
        if ~exist(fullPathEnhanced, 'file')
           fprintf('  X פייתון סיים אך לא מצאתי את הקובץ: %s\n', fullPathEnhanced);
           continue;
        end
        
        % --- שלב ג: טעינת התמונה המשופרת ל-MATLAB ---
        waitbar(k/totalFiles, h, sprintf('שלב 2: MATLAB יוצר שלד ל-%s...', originalFilename));
        
        img = imread(fullPathEnhanced);
        
        % המרה ללוגי (0 ו-1) - התמונה מפייתון כבר בשחור לבן
        % אבל MATLAB צריך format לוגי לפקודת bwmorph
        binImg = imbinarize(img); 
        
        % --- שלב ד: יצירת שלד (Skeletonization) ---
        skeletonImg = bwmorph(binImg, 'thin', Inf);
        skeletonImg = bwmorph(skeletonImg, 'clean'); % ניקוי רעשים
        
        % היפוך צבעים (קו שחור על לבן)
        finalOutput = ~skeletonImg;
        
        % --- שלב ה: שמירה סופית ---
        finalName = sprintf('%s_skeleton.png', nameNoExt);
        % שמירה בתיקייה ייעודית (כפי שביקשת בקוד המקורי)
        saveFolder = "C:\Users\User\OneDrive - ac.sce.ac.il\מסמכים\MATLAB\fingerprint matlab\data";
        
        % אם התיקייה לא קיימת, ניצור אותה כדי למנוע שגיאה
        if ~exist(saveFolder, 'dir')
           mkdir(saveFolder);
        end
        
        fullSavePath = fullfile(saveFolder, finalName);
        imwrite(finalOutput, fullSavePath);
        
        fprintf('  V הושלם: %s -> %s\n', originalFilename, finalName);
        
        % אופציונלי: מחיקת הקובץ הזמני שפייתון יצר (כדי לא ללכלך את התיקייה)
        % delete(fullPathEnhanced); 
        
    catch err
        fprintf('  X שגיאה כללית ב-%s: %s\n', originalFilename, err.message);
    end
end

close(h);
disp('--- כל הקבצים עובדו! ---');