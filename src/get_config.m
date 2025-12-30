function cfg = get_config()
    % config.m - קובץ השליטה המרכזי של המערכת
    % כאן מגדירים את כל הרגישויות והספים במקום אחד מסודר.

    %% הגדרות כלליות
    cfg.db_filename = 'fingerprint_database.mat';
    
    %% הגדרות סינון ועיבוד (Preprocessing)
    cfg.filter.min_distance = 6; 
    cfg.filter.border_margin = 15;

    %% הגדרות התאמה (Matching Parameters)
    % סף הציון כדי להכריז על "התאמה" (Pass/Fail)
    cfg.match.pass_threshold = 3.0; 
    
    % 1. טווח חיפוש גיאומטרי
    % מרחק מקסימלי (בפיקסלים) כדי שנקודה תחשב "קרובה" לאחרת
    cfg.match.max_dist = 25;       % (היה 20, הגדלנו ל-25 לטובת גמישות)
    
    % 2. טווח סבלנות לזווית
    % זווית מקסימלית (במעלות) - קריטי לזיהוי תמונות מסובבות!
    cfg.match.max_ang_deg = 35;    % (היה 20, הגדלנו ל-35)
    cfg.match.max_ang_rad = deg2rad(cfg.match.max_ang_deg); % המרה אוטומטית
    
    % 3. כמות בדיקות (Performance vs Accuracy)
    % כמה זוגות מובילים לבדוק?
    % 30 = מהיר מאוד, 100 = מדויק יותר ברוטציות חזקות
    cfg.match.candidate_count = 10000; 

    %% הגדרות ניקוד (Scoring Equation)
    % הפרמטרים הללו קובעים כמה מהר הציון יורד כשיש אי-התאמה
    
    % Sigma למרחק (כמה אנחנו קשוחים על המיקום המדויק)
    cfg.score.sigma_dist = 10;
    
    % Sigma למתארים (כמה אנחנו קשוחים על צורת הסביבה)
    % ערך 10 = קשוח מאוד, ערך 40 = סלחני (מתאים לרוטציות ועיוותים)
    cfg.score.sigma_desc = 40;     

    %% הגדרות מסיכה (ROI)
    cfg.roi.closing_size = 20; 
    cfg.roi.erosion_size = 2;
end