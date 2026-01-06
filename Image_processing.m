%% שלב 0: הגדרות נתיבים וניקוי
clc; clear; close all;
addpath('functions'); % וודא שתיקיית הפונקציות זמינה

%% שלב 1: טעינת התמונה
% וודא שהנתיב תואם לקובץ שלך
filename = 'data/DB1_B/101_1.tif'; 
img = imread(filename);

if size(img,3) == 3
    img = rgb2gray(img);
end

% נרמול לטווח 0-1
img = double(img);
img = (img - min(img(:))) / (max(img(:)) - min(img(:)));

%% שלב 2: עיבוד מקדים (Gabor Filter Pipeline)

% 1. סגמנטציה - הפרדת האצבע מהרקע
% תיקון: העלאת הסף ל-0.2 מנקה את רעשי הרקע (הבלוקים)
[normim, mask, maskind] = ridgesegment(img, 16, 0.2);

% 2. חישוב כיווניות (Orientation)
orientim = ridgeorient(normim, 1, 5, 5);

% 3. חישוב תדרים (Frequency)
[freqim, medfreq] = ridgefreq(normim, mask, orientim, 32, 5, 5, 15);

% 4. סינון גאבור (Gabor Filter)
newim = ridgefilter(normim, orientim, freqim, 0.5, 0.5, 1);

% --- תיקון קריטי: החלת המסכה ---
% זה מוחק את כל הריבועים הלבנים שנשארו ברקע
newim = newim .* mask;

%% שלב 3: בינאריזציה ודיקוק (Thinning)

% בינאריזציה (הפיכה לשחור לבן)
bw = newim > 0;

% חיבור קווים וסגירת חורים קטנים
bw = bwmorph(bw, 'bridge', inf); % גשרים קטנים
bw = bwmorph(bw, 'close');       % סגירה מורפולוגית
bw = imfill(bw, 'holes');        % מילוי חורים פנימיים

% דיקוק לרמת פיקסל אחד
skeleton = bwmorph(bw, 'thin', inf);

% --- תיקון סופי: ניקוי השלד ---
% ניקוי נקודות בודדות (רעש)
skeleton = bwmorph(skeleton, 'clean');
% הסרת "זיזים" (Spurs) - קווים קטנים שבולטים החוצה
skeleton = bwmorph(skeleton, 'spur', 5);

%% שלב 4: תצוגה
figure('Name', 'Fingerprint Process Final', 'NumberTitle', 'off');

subplot(1,3,1);
imshow(img);
title('1. מקור');

subplot(1,3,2);
imshow(newim);
title('2. אחרי Gabor (ללא רקע)');

subplot(1,3,3);
imshow(skeleton);
title('3. שלד נקי (ללא זיזים)');

imshow(~skeleton); 
title('שלד (תצוגת דיו)');

%% שלב 5 (השוואה כפולה): השלד על המקור מול השלד על המעובד

figure('Name', 'Skeleton Overlay Comparison', 'Units', 'normalized', 'Position', [0.1 0.3 0.8 0.5]);

% --- תמונה 1: השלד על התמונה המקורית ---
subplot(1,2,1);

% הכנת תמונת רקע (נרמול לטווח 0-1 לתצוגה)
bg_orig = double(img);
bg_orig = (bg_orig - min(bg_orig(:))) / (max(bg_orig(:)) - min(bg_orig(:)));
overlay_orig = cat(3, bg_orig, bg_orig, bg_orig); % המרה ל-RGB

% צביעת השלד באדום
tmp = overlay_orig(:,:,1); tmp(skeleton) = 1; overlay_orig(:,:,1) = tmp; % ערוץ אדום מלא
tmp = overlay_orig(:,:,2); tmp(skeleton) = 0; overlay_orig(:,:,2) = tmp; % איפוס ירוק
tmp = overlay_orig(:,:,3); tmp(skeleton) = 0; overlay_orig(:,:,3) = tmp; % איפוס כחול

imshow(overlay_orig);
title('1. השלד על התמונה המקורית (Original)');


% --- תמונה 2: השלד על התמונה המעובדת (אחרי Gabor) ---
subplot(1,2,2);

% הכנת תמונת רקע (נרמול לטווח 0-1 לתצוגה)
bg_enhanced = newim;
bg_enhanced = (bg_enhanced - min(bg_enhanced(:))) / (max(bg_enhanced(:)) - min(bg_enhanced(:)));
overlay_enhanced = cat(3, bg_enhanced, bg_enhanced, bg_enhanced); % המרה ל-RGB

% צביעת השלד באדום
tmp = overlay_enhanced(:,:,1); tmp(skeleton) = 1; overlay_enhanced(:,:,1) = tmp;
tmp = overlay_enhanced(:,:,2); tmp(skeleton) = 0; overlay_enhanced(:,:,2) = tmp;
tmp = overlay_enhanced(:,:,3); tmp(skeleton) = 0; overlay_enhanced(:,:,3) = tmp;

imshow(overlay_enhanced);
title('2. השלד על התמונה המעובדת (Enhanced)');

% קישור הצירים כדי שזום באחד יעשה זום גם בשני
linkaxes;