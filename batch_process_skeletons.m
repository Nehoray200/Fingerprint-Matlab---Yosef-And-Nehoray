%% סקריפט: עיבוד טביעות אצבע לשלדים (Batch Processing)
% סקריפט זה מאפשר לבחור מספר תמונות, להפוך אותן לשלד (קו שחור על לבן) ולשמור.

clc; close all; clear; % ניקוי זיכרון ומסך

% 1. בחירת קבצים (חלון קופץ)
disp('אנא בחר את התמונות לעיבוד...');
[files, path] = uigetfile({'*.tif;*.png;*.jpg;*.bmp', 'Image Files'; ...
                           '*.*', 'All Files'}, ...
                           'בחר תמונה אחת או יותר (השתמש ב-Ctrl/Shift לבחירה מרובה)', ...
                           'MultiSelect', 'on');

% בדיקה אם המשתמש לחץ "ביטול"
if isequal(files, 0)
    disp('לא נבחרו קבצים. הסקריפט נעצר.');
    return;
end

% טיפול במקרה של קובץ בודד (הופך אותו לרשימה כדי שהלולאה תעבוד)
if ischar(files)
    files = {files};
end

totalFiles = length(files);
fprintf('נבחרו %d קבצים. מתחיל עיבוד...\n', totalFiles);

% יצירת סרגל התקדמות
h = waitbar(0, 'מתחיל לעבד...');

%% === לולאה על כל הקבצים ===
for k = 1:totalFiles
    
    filename = files{k};
    fullPath = fullfile(path, filename);
    
    % עדכון סרגל ההתקדמות
    waitbar(k/totalFiles, h, sprintf('מעבד: %s (%d/%d)', filename, k, totalFiles));
    
    try
        % --- שלב א: טעינה והכנה ---
        img = imread(fullPath);
        
        if size(img, 3) == 3
            img = rgb2gray(img);
        end
        img = im2double(img);
        
        % --- שלב ב: בינאריזציה וניקוי ---
        % שימוש ב-Adaptive Threshold כדי להתמודד עם תאורה לא אחידה
        binImg = imbinarize(img, 'adaptive', 'Sensitivity', 0.5);
        
        % וידוא שהרכס הוא "לבן" (1) והרקע "שחור" (0) לצורך העיבוד
        if mean(binImg(:)) > 0.5
            binImg = ~binImg;
        end
        
        % ניקוי רעשים קטנים
        binImg = bwareaopen(binImg, 10);
        
        % --- שלב ג: יצירת שלד (Thinning) ---
        skeletonImg = bwmorph(binImg, 'thin', Inf);
        
        % ניקוי "קוצים" קטנים מהשלד (אופציונלי, משפר את המראה)
        skeletonImg = bwmorph(skeletonImg, 'clean');
        
        % --- שלב ד: היפוך לתצוגה (קו שחור על רקע לבן) ---
        finalOutput = ~skeletonImg;
        
        % --- שלב ה: שמירה ---
        [~, name, ext] = fileparts(filename);
        newFilename = sprintf('%s_skeleton%s', name, ext);
        savePath = fullfile("C:\Users\User\OneDrive - ac.sce.ac.il\מסמכים\MATLAB\fingerprint matlab\data", newFilename);
        
        imwrite(finalOutput, savePath);
        fprintf('  V נשמר: %s\n', newFilename);
        
    catch err
        fprintf('  X שגיאה בקובץ %s: %s\n', filename, err.message);
    end
end

close(h); % סגירת סרגל ההתקדמות
disp('--- הסתיים בהצלחה! ---');

% הצגת דוגמה אחרונה
if exist('finalOutput', 'var')
    figure('Name', 'Last Processed Image');
    imshow(finalOutput);
    title(['תוצאה (דוגמה): ', newFilename]);
end