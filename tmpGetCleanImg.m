% 1. טעינת התמונה המקורית

originalImg = imread("DB1_B\106_2.tif");

% 2. המרה לבינארי
% הופכים לשחור לבן. בדרך כלל הרכס יוצא שחור והרקע לבן
binImg = imbinarize(originalImg, 'adaptive', 'Sensitivity', 0.5);

% 3. וידוא שהרכס הוא "1" (לבן) לצורך העיבוד
% המחשב חייב שהקו יהיה "1" כדי לעשות לו Thinning
if mean(binImg(:)) > 0.5
    % אם רוב התמונה לבנה, סימן שהרקע לבן. אנו הופכים כדי שהקו יהיה לבן
    binImg = ~binImg;
end

% 4. ניקוי רעשים (מחיקת נקודות קטנות)
binImg = bwareaopen(binImg, 10);

% 5. דילול (Thinning) - יצירת השלד
% בשלב זה: הקו הוא לבן (1) והרקע שחור (0)
skeletonImg = bwmorph(binImg, 'thin', Inf);

% 6. === השלב שביקשת: היפוך לצורך תצוגה ושמירה ===
% כעת הקו יהיה שחור (0) והרקע לבן (1)
finalImage = ~skeletonImg;

% 7. תצוגה
figure;
imshow(finalImage);
title('Skeleton: Black Ridges on White Background');

% 8. שמירה לקובץ
imwrite(finalImage, 'my_test_fingerprint62.tif');
disp('התמונה my_test_fingerprint62.tif נשמרה בהצלחה!');