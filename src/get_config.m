function cfg = get_config()
    % get_config - קובץ הגדרות מרכזי (הגדרות מומלצות ל-500 DPI)
    
    %% 1. הגדרות מערכת וקבצים
    cfg.db_filename = 'fingerprint_database.mat';

    %% 2. הגדרות Gabor (החדשות)
    % פרמטרים לשיפור התמונה בשיטת הונג (Hong et al.)
    cfg.gabor.blk_sze = 16;       % גודל בלוק לסגמנטציה
    cfg.gabor.thresh = 0.1;       % סף שונות להפרדת רקע
    cfg.gabor.grad_sigma = 1;     % סיגמא לחישוב נגזרות כיוון
    cfg.gabor.block_sigma = 7;    % סיגמא להחלקת כיוונים
    cfg.gabor.smooth_sigma = 7;   % החלקה סופית של שדה הכיוונים
    cfg.gabor.freq_blk = 38;      % גודל בלוק לחישוב תדר
    cfg.gabor.freq_wind = 5;      % חלון חישוב תדר
    cfg.gabor.min_wl = 5;         % אורך גל מינימלי
    cfg.gabor.max_wl = 15;        % אורך גל מקסימלי
    cfg.gabor.kx = 0.65;          % חוזק הסינון בציר X
    cfg.gabor.ky = 0.65;          % חוזק הסינון בציר Y
    
    %% 3. הגדרות עיבוד המשך (בינאריזציה ושלד)
    cfg.binarize.sens = 0.5;      % סף לבינאריזציה (או adaptive)

    
    %% 2. הגדרות עיבוד מקדים (Preprocessing)
    % אם משתמשים בגרסת Ultra-Lite, חלק מאלו לא בשימוש, אך טוב שיהיו מוגדרים.
    cfg.preprocess.gauss_sigma = 0.8;       
    cfg.preprocess.bin_sensitivity = 0.65;  
    
    % מספר השכנים למתאר. 5 זה איזון טוב בין דיוק למהירות.
    cfg.feature.descriptor_k = 5;   
    
    %% 3. הגדרות מסיכה (ROI)
    cfg.roi.erosion_size = 0;   % 0 זה מצוין כדי לא לאבד מידע בקצוות
    cfg.roi.closing_size = 20;  % סוגר חורים בתוך האצבע, ערך טוב.
    
    %% 4. חילוץ מאפיינים (Feature Extraction)
    % שינוי מומלץ: הגדלה מ-3 ל-5. 
    % הליכה של 3 פיקסלים היא קצרה מדי ורגישה לרעשים. 5 נותן זווית אמינה יותר.
    cfg.feature.angle_steps = 5; 
    
    %% 5. הגדרות סינון (Filtering) - קריטי לניקיון
    
    cfg.filter.border_margin = 20; % מצוין. מנקה את "המסגרת" הבעייתית.
    cfg.filter.min_distance = 10;  % מומלץ: כרוחב רכס ממוצע. מונע שתי נקודות על אותו רכס.
    
    % === הגדרות סינון גיאומטרי (טיפול ברעשים) ===
    % הערכים הקודמים (1) היו נמוכים מדי ולא סיננו כלום.
    
    % 1. הסרת "רכסים קצרים" (איים):
    % אם קו מתחיל ונגמר תוך פחות מ-15 פיקסלים (כ-1.5 רוחב רכס) -> למחוק.
    cfg.filter.max_short_ridge_dist = 25; 
    
    % 2. הסרת "גשרים" (חיבורים שקריים בין רכסים):
    % אם שני פיצולים קרובים מדי (פחות מ-15 פיקסלים) -> למחוק.
    cfg.filter.max_bridge_dist = 15; 
    
    % 3. הסרת "קוצים" (Spikes - זיזים קטנים):
    % אם קו מתפצל ומיד נגמר (תוך 15 פיקסלים) -> למחוק.
    cfg.filter.max_spike_dist = 15;
    
    % סובלנות זווית לזיהוי שברים (35 מעלות זה סביר).
    cfg.filter.angle_tolerance = deg2rad(35);
    
    %% 6. הגדרות התאמה (Matching & Search)
    cfg.match.pass_threshold = 12.0;    % המלצה: להעלות טיפה ל-15 כדי להפחית זיהויים שגויים (FAR).
    cfg.match.candidate_count = 50;     % 50 זה מצוין לביצועים.
    
    % ספי החלטה:
    cfg.match.max_dist = 15;            % 15 פיקסלים סובלנות למרחק (אלסטיות העור).
    cfg.match.max_ang_deg = 45;         % 45 מעלות סובלנות לסיבוב (הנחה נוחה).
    cfg.match.max_ang_rad = deg2rad(cfg.match.max_ang_deg);
    
    %% 7. הגדרות ניקוד (Scoring Functions)
    % פרמטרים לפונקציות גאוס (כמה מהר הציון יורד)
    cfg.score.sigma_dist = 10;     
    cfg.score.sigma_ang_rad = 0.5; 
    cfg.score.sigma_desc = 45;     
end