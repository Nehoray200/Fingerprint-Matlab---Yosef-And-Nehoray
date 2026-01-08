%% run_batch_gabor.m - עיבוד אצווה עם Gabor ב-MATLAB בלבד
clc; close all; clear;

% הוספת נתיב לפונקציות
addpath('src');

% הגדרת תיקיית שמירה
saveFolder = fullfile(pwd, 'data', 'processed_skeletons'); 
if ~exist(saveFolder, 'dir'), mkdir(saveFolder); end

% 1. בחירת קבצים
disp('אנא בחר את התמונות המקוריות לעיבוד...');
[files, path] = uigetfile({'*.tif;*.png;*.jpg;*.bmp', 'Image Files'}, ...
                           'בחר תמונות', 'MultiSelect', 'on');

if isequal(files, 0), disp('לא נבחרו קבצים.'); return; end
if ischar(files), files = {files}; end

h = waitbar(0, 'מתחיל עיבוד...');
totalFiles = length(files);

for k = 1:totalFiles
    filename = files{k};
    fullPath = fullfile(path, filename);
    [~, nameNoExt, ~] = fileparts(filename);
    
    waitbar(k/totalFiles, h, sprintf('מעבד: %s...', filename));
    
    try
        % --- שלב העיבוד (קורא לפונקציה החדשה שיצרנו) ---
        img = imread(fullPath);
        
        % הפונקציה הזו מחליפה את הסקריפט של פייתון + העיבוד הקודם
        [skeletonMask, ~, enhancedImg] = process_fingerprint_gabor(img);
        
        % --- שמירה ---
        % שמירת השלד (נהפוך צבעים אם צריך שחור על גבי לבן ל-PNG)
        % ~skeletonMask הופך את ה-1 (רכס) ל-0 (שחור) ואת הרקע ללבן
        finalOutput = ~skeletonMask; 
        
        saveName = fullfile(saveFolder, [nameNoExt '_skeleton.png']);
        imwrite(finalOutput, saveName);
        
        % אופציונלי: שמירת התמונה המשופרת (Gabor) לצורך בדיקה
        % imwrite(enhancedImg > 0, fullfile(saveFolder, [nameNoExt '_enhanced.png']));
        
        fprintf('V הושלם: %s\n', filename);
        
    catch err
        fprintf('X שגיאה ב-%s: %s\n', filename, err.message);
    end
end

close(h);
msgbox(['הסתיים העיבוד! הקבצים נשמרו ב: ' saveFolder]);