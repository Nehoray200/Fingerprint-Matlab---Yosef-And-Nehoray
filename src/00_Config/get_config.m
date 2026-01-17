function cfg = get_config()
    % get_config - קובץ הגדרות מרכזי (מעודכן עם נתיב שמירה ל-src/04_Database)
    % פונקציה זו מחזירה מבנה (struct) המכיל את כל הפרמטרים של המערכת.
    % שינוי ערכים כאן ישפיע על כל שלבי העיבוד והזיהוי.
    
    %% 1. הגדרות מערכת וקבצים
    
    % --- שינוי: חישוב נתיב חכם לתיקיית Database ---
    
    % 1. משיג את המיקום של הקובץ הזה (נמצא ב-src/00_Config)
    currentFileDir = fileparts(mfilename('fullpath'));
    
    % 2. עולה רמה אחת למעלה (לתיקיית src)
    srcDir = fileparts(currentFileDir);
    
    % 3. בונה את הנתיב לתיקיית היעד
    targetFolder = fullfile(srcDir, '04_Database');
    
    % 4. יצירת התיקייה אם היא לא קיימת (קריטי למניעת שגיאות!)
    if ~exist(targetFolder, 'dir')
        mkdir(targetFolder);
    end
    
    % 5. הגדרת הנתיב המלא לקובץ הדאטה-בייס
    cfg.db_filename = fullfile(targetFolder, 'fingerprint_database.mat');
    
    %% 2. הגדרות Gabor (שיפור תמונה מתקדם)
    % פילטר Gabor הוא הכלי המרכזי שמנקה את התמונה ומדגיש את הרכסים (Ridges).
    
    cfg.gabor.blk_sze = 16;       % גודל הבלוק שבו התמונה מחולקת (למשל 16x16 פיקסלים) לצורך חישובים מקומיים.
    cfg.gabor.thresh = 0.1;       % סף הרגישות להפרדת האצבע מהרקע (כמה "רעש" נחשב לרקע).
    cfg.gabor.grad_sigma = 1;     % רמת החלקה בחישוב הנגזרות (לזיהוי כיוון הקווים).
    cfg.gabor.block_sigma = 7;    % רמת החלקה של הממוצעים בתוך הבלוק.
    cfg.gabor.smooth_sigma = 7;   % החלקה סופית של מפת הכיוונים (כדי למנוע שינויי כיוון חדים מדי שנובעים מרעש).
    cfg.gabor.freq_blk = 30;      % גודל הבלוק לצורך חישוב תדר (צפיפות) הקווים.
    cfg.gabor.freq_wind = 5;      % גודל החלון לחישוב פיקים בתדר.
    cfg.gabor.min_wl = 3;         % אורך גל מינימלי (המרחק הכי קטן הגיוני בין שני קווים באצבע).
    cfg.gabor.max_wl = 25;        % אורך גל מקסימלי (המרחק הכי גדול הגיוני בין שני קווים).
    cfg.gabor.kx = 0.5;          % עוצמת הפילטר בציר X (כיוון הזרימה של הקו).
    cfg.gabor.ky = 0.5;          % עוצמת הפילטר בציר Y (בניצב לקו - לניקוי המרווחים).
    
    %% 3. הגדרות עיבוד המשך ובינאריזציה
    % השלב שבו הופכים את התמונה המשופרת לשחור-לבן מוחלט (0 ו-1).
    cfg.binarize.sens = 0.5;      % רגישות ההמרה (מעל 0.5 הופך ללבן, מתחת לשחור).
    
    %% 4. הגדרות רישום ובקרת איכות (Enrollment)
    % כאן קובעים את "רף הכניסה" למערכת.
    cfg.enroll.min_minutiae = 12; % אם נמצאו פחות מ-12 נקודות אפיון, המערכת תדחה את התמונה כי היא לא איכותית מספיק לזיהוי בטוח.
    
    %% 5. הגדרות מסיכה ועיבוד מקדים
    % שליטה על האזור המוגדר כ"אצבע" (ROI - Region of Interest).
    
    cfg.roi.erosion_size = 10;    % כמה "לכרסם" פנימה את המסיכה כדי להסיר קצוות רועשים.
    cfg.roi.closing_size = 10;    % גודל האלמנט לסגירת חורים קטנים במסיכה.
    cfg.roi.mask_dilation = 20;   % *חשוב*: כמה להרחיב את המסיכה החוצה. מספר גבוה (כמו 20) מבטיח שלא נחתוך קצוות אמיתיים של האצבע.
    cfg.roi.strict_erosion = 12;      % כיווץ המסיכה לפני חילוץ נקודות (במקום המספר 12 הקבוע)
    cfg.preprocess.gauss_sigma = 0.8;       % טשטוש קל בהתחלה להסרת רעשי מצלמה (Salt & Pepper).
    cfg.preprocess.bin_sensitivity = 0.65;  % רגישות ספציפית לשלב ה-Preprocessing.
    
    %% 6. חילוץ מאפיינים
    % הגדרות לתיאור כל נקודה (Minutia Descriptor).
    cfg.feature.descriptor_k = 5;   % כמה שכנים קרובים נשמור עבור כל נקודה (כדי ליצור לה "תעודת זהות" ייחודית).
    cfg.feature.angle_steps = 5;    % מספר הצעדים קדימה שבודקים כדי לחשב את זווית הנקודה במדויק.
    
    %% 7. הגדרות סינון (Filtering) - החלק הקריטי לניקוי רעשים
    % כאן נקבע מה נחשב לנקודה אמיתית ומה נחשב ל"זבל" שצריך למחוק.
    
    cfg.filter.border_margin = 25; % מרחק ביטחון בפיקסלים מהגבול. נקודות קרובות מדי לקצה יימחקו.
    cfg.filter.min_distance = 1;  % מרחק מינימלי בין שתי נקודות. אם יש שתיים קרובות מדי (פחות מ-20 פיקסלים), הן כנראה כפילות או רעש.
    
    % --- הגדרה חדשה לשליטה בגבולות (מהתיקון האחרון) ---
    % שולט על כמה הגבול הוירטואלי "צמוד" לנקודות.
    % 0 = גבול רחב וקמור (Convex Hull), 1 = גבול הדוק מאוד שנכנס למפרצים.
    % 0.5 = האיזון המומלץ.
    cfg.filter.boundary_shrink_factor = 0.5; 
    
    % --- סינון גיאומטרי (מבני רעש מוכרים) ---
    cfg.filter.max_short_ridge_dist = 15; % זיהוי "שבר": קו קצר מאוד שנוצר בטעות.
    cfg.filter.max_bridge_dist = 12;      % זיהוי "גשר": חיבור קטן בין שני קווים מקבילים (שלא אמור להיות שם).
    cfg.filter.max_spike_dist = 8;        % זיהוי "קוץ": בליטה קטנה שיוצאת מקו ישר.
    cfg.filter.angle_tolerance = deg2rad(35); % סובלנות לזווית בזיהוי שברים (אם שני קצוות פונים זה לזה בסטייה של עד 35 מעלות, נחבר אותם או נמחק אותם).
    
    %% 8. הגדרות התאמה (Matching)
    % השלב שבו משווים בין תמונה חדשה למאגר.
    
    cfg.match.pass_threshold = 12.0;    % הציון הסופי המינימלי כדי להכריז על "התאמה מוצלחת" (V ירוק).
    cfg.match.candidate_count = 50;     % כמה זוגות פוטנציאליים לבדוק לפני שמחליטים על ההתאמה הטובה ביותר (לביצועים).
    
    cfg.match.max_dist = 15;            % רדיוס הסובלנות בפיקסלים: אם הנקודה זזה עד 15 פיקסלים, זה עדיין נחשב אותה נקודה.
    cfg.match.max_ang_deg = 45;         % סובלנות לזווית: אם האצבע סובבה קצת, עדיין נקבל את ההתאמה.
    cfg.match.max_ang_rad = deg2rad(cfg.match.max_ang_deg); % המרה לרדיאנים (כי המחשב עובד ברדיאנים).
    
    %% 9. הגדרות ניקוד (Scoring)
    % הנוסחאות לחישוב הציון הסופי.
    cfg.score.sigma_dist = 10;     % סטיית התקן לחישוב ציון המרחק (ככל שהנקודה קרובה יותר למקור, הציון עולה).
    cfg.score.sigma_ang_rad = 0.5; % סטיית התקן לציון הזווית.
    cfg.score.sigma_desc = 45; % סטיית התקן לדמיון בין הדסקריפטורים (השכנים של הנקודה).

    %% טעינת הגדרות משתמש (שנשמרו ע"י ה-App)
   try
        configDir = fileparts(mfilename('fullpath'));
        userConfigFile = fullfile(configDir, 'user_settings.mat');
        
        if isfile(userConfigFile)
            userData = load(userConfigFile, 'savedCfg');
            if isfield(userData, 'savedCfg')
                saved = userData.savedCfg;
                % מיזוג חכם: מעדכן רק את מה שקיים בקובץ השמור
                if isfield(saved, 'gabor'), cfg.gabor = saved.gabor; end
                if isfield(saved, 'roi'), cfg.roi = saved.roi; end
                if isfield(saved, 'enroll'), cfg.enroll = saved.enroll; end
                if isfield(saved, 'match'), cfg.match = saved.match; end
                if isfield(saved, 'filter'), cfg.filter = saved.filter; end
                if isfield(saved, 'binarize'), cfg.binarize = saved.binarize; end
            end
        end
    catch
        % במקרה של תקלה בטעינה, ממשיכים עם ברירת המחדל
    end
end