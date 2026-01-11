function setup_project()
    % setup_project - מגדיר את הנתיבים באופן אוטומטי
    % מריצים את זה פעם אחת כשמתחילים לעבוד
    
    % קבלת הנתיב של התיקייה בה נמצא הקובץ הזה
    currentDir = fileparts(mfilename('fullpath'));
    
    % הוספת תיקיית המקור (כולל תתי-תיקיות)
    addpath(genpath(fullfile(currentDir, 'src')));
    
    % הוספת תיקיית הדאטה
    addpath(fullfile(currentDir, 'data'));
    
    disp('>> נתיבי הפרויקט הוגדרו בהצלחה (Relative Paths).');
end