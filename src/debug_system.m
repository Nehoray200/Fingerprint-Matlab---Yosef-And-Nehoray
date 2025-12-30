%% סקריפט דיבאג - בדיקה סינתטית
clc; clear; close all;
addpath(genpath('src'));
addpath('data');

disp('=== מצב דיבאג: בדיקת רובוסטיות סינתטית ===');

% 1. בחירת תמונה לבדיקה
[file, path] = uigetfile({'*.tif;*.png;*.jpg'}, 'בחר תמונה לבדיקה (רצוי איכותית)');
if isequal(file, 0), return; end
img = imread(fullfile(path, file));

% 2. עיבוד התמונה המקורית (DB Template)
disp('>> מעבד את התמונה המקורית...');
[templateOriginal, ~, ~, descOriginal] = process_fingerprint(img);

if size(templateOriginal, 1) < 10
    errordlg('לא נמצאו מספיק נקודות בתמונה המקורית כדי לבצע בדיקה.');
    return;
end

% אריזה למבנה
dbData.minutiae = templateOriginal;
dbData.descriptors = descOriginal;

% 3. יצירת עיוות מלאכותי (Input Template)
disp('>> יוצר נתונים סינתטיים (סיבוב + הזזה + רעש)...');
imgSize = size(img);
rotation = 25;   % סיבוב של 25 מעלות (מאתגר אבל אפשרי)
shiftX = 10;     % הזזה של 10 פיקסלים
shiftY = -15;    % הזזה של -15 פיקסלים

% קריאה לפונקציה שלך
syntheticMinutiae = generate_synthetic_input(templateOriginal, imgSize, rotation, shiftX, shiftY);

% חשוב מאוד: לחשב descriptors מחדש עבור הנקודות המעוותות!
% האלגוריתם החדש שלנו מסתמך על זה
syntheticDescriptors = compute_descriptors(syntheticMinutiae);

% אריזה למבנה
inputData.minutiae = syntheticMinutiae;
inputData.descriptors = syntheticDescriptors;

% 4. הצגת הנקודות (לפני ההתאמה) כדי לראות את האתגר
figure('Name', 'האתגר: מקור מול מעוות', 'NumberTitle', 'off');
plot(templateOriginal(:,1), templateOriginal(:,2), 'ro'); hold on;
plot(syntheticMinutiae(:,1), syntheticMinutiae(:,2), 'bx');
legend('Original', 'Synthetic (Rotated+Shifted)');
axis ij; title('לפני התאמה (Alignment)');
hold off;

% 5. הרצת האלגוריתם
disp('>> מריץ find_best_match...');
[score, alignedData, isMatch] = find_best_match(dbData, inputData, 0);

% 6. תוצאות
disp('---------------------------------');
disp(['ציון שהתקבל: ', num2str(score)]);
if score > 15
    disp('✅ הצלחה! האלגוריתם עובד מצוין מבחינה לוגית.');
    disp('מסקנה: אם זה לא עובד על תמונות אמיתיות, הבעיה היא באיכות התמונות (Minutiae extraction לא עקבי).');
else
    disp('❌ כישלון. הציון נמוך מדי למרות שהתמונות זהות בתוכן.');
    disp('מסקנה: יש באג בקוד ההתאמה (find_best_match) או בחישוב ה-descriptors.');
end

% ויזואליזציה של התוצאה הסופית
if ~isempty(alignedData)
    figure('Name', 'תוצאת האלגוריתם', 'NumberTitle', 'off');
    plot(templateOriginal(:,1), templateOriginal(:,2), 'ro', 'MarkerSize', 8); hold on;
    plot(alignedData(:,1), alignedData(:,2), 'g+', 'MarkerSize', 8);
    legend('Database', 'Input (After Alignment)');
    axis ij; title(['Result Score: ' num2str(score)]);
end