function cfg = get_config()
    % config.m - קובץ הגדרות מרכזי למערכת
    % כל שינוי ברגישות או בהגדרות האלגוריתם מתבצע רק כאן!

    %% הגדרות כלליות
    cfg.db_filename = 'fingerprint_database.mat';
    
    %% הגדרות עיבוד תמונה וסינון (Preprocessing)
    % המרחק המינימלי בין נקודות כדי שלא ייחשבו כרעש (בפיקסלים)
    cfg.filter.min_distance = 6; 
    
    % שוליים - מחיקת נקודות שקרובות מדי לקצה התמונה
    cfg.filter.border_margin = 15;

    %% הגדרות התאמה וניקוד (Matching & Scoring)
    % סף הציון כדי להכריז על "התאמה" (Pass/Fail)
    cfg.match.pass_threshold = 3.0; 
    
    % המרחק המקסימלי שבו שתי נקודות נחשבות "שכנות" (בפיקסלים)
    cfg.match.max_dist = 20;
    
    % סטיית הזווית המקסימלית המותרת (במעלות)
    cfg.match.max_ang_deg = 20;
    cfg.match.max_ang_rad = deg2rad(20); % המרה אוטומטית לרדיאנים
    
    %% הגדרות מסיכה (ROI)
    % גודל הדיסק לסגירת רווחים בין הרכסים (כדי ליצור גוש אחד)
    cfg.roi.closing_size = 15; 
    
    % כמה לכרסם מקצוות המסיכה פנימה (כדי להעיף רעשי מסגרת)
    cfg.roi.erosion_size = 10;
    
    % --- פרמטרים לנוסחת הניקוד החכמה (Weighted Score) ---
    % קבועי דעיכה (Sigma) - קובעים כמה הציון יורד כשהמרחק גדל
    cfg.score.sigma_dist = 10;
    cfg.score.sigma_ang_rad = deg2rad(20);
end