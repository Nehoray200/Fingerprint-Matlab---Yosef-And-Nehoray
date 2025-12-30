function cfg = get_config()
    % config.m - הגדרות אופטימליות המבוססות על מחקר וסטנדרטים פורנזיים
    
    %% הגדרות כלליות
    cfg.db_filename = 'fingerprint_database.mat';
    
    %% הגדרות סינון (Preprocessing)
    % סינון נקודות קרובות מדי (Artifacts) - מבוסס על המאמר Post-processing
    cfg.filter.border_margin = 15;
cfg.filter.min_distance = 10; % נקודות לא יכולות להיות קרובות מ-10 פיקסלים
    %% הגדרות התאמה (Matching)
    % סף המעבר:
    % ציון 8.0 ומעלה משקף סבירות גבוהה ל-10 עד 12 נקודות תואמות.
    cfg.match.pass_threshold = 8.0; 
    
    % מרחק מקסימלי לחיפוש שכן (Search Box)
    cfg.match.max_dist = 20;       
    
    % סובלנות לסיבוב (Rotation Invariance)
    cfg.match.max_ang_deg = 45;    
    cfg.match.max_ang_rad = deg2rad(cfg.match.max_ang_deg);
    
    % בדיקת כל האפשרויות לדיוק מקסימלי
   cfg.match.candidate_count = 80;

    %% הגדרות ניקוד (Scoring Logic)
    % Sigma = 12 נותן איזון טוב בין גמישות לדיוק (לפי FVC standards)
    cfg.score.sigma_dist = 12;     
    
    % Descriptors: סלחנות גבוהה יותר כי הצורה משתנה בלחץ שונה
    cfg.score.sigma_desc = 45;     

    %% הגדרות מסיכה (ROI)
    cfg.roi.erosion_size = 6;
    cfg.roi.closing_size = 20; 
    cfg.roi.erosion_size = 5;
end