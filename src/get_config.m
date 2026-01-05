function cfg = get_config()
    % get_config - קובץ הגדרות מרכזי (מותאם לסינון מרחק אוקלידי)
    
    %% הגדרות כלליות
    cfg.db_filename = 'fingerprint_database.mat';
    
    %% הגדרות סינון (Preprocessing)
    % border_margin: המרחק בפיקסלים מהקצה שמתחתיו נקודה תימחק.
    cfg.filter.border_margin = 25;
    
    % min_distance: מרחק מינימלי בין נקודות למניעת כפילויות.
    cfg.filter.min_distance = 7; 
    
    %% הגדרות התאמה (Matching)
    cfg.match.pass_threshold = 12.0;    
    cfg.match.max_dist = 15;    
    cfg.match.max_ang_deg = 45;    
    cfg.match.max_ang_rad = deg2rad(cfg.match.max_ang_deg);
    cfg.match.candidate_count = 80;

    %% הגדרות ניקוד (Scoring)
    cfg.score.sigma_dist = 12;     
    cfg.score.sigma_desc = 45;     
    
    %% הגדרות מסיכה (ROI)
    % erosion_size = 0: אנחנו רוצים מסיכה מלאה ("שמנה") כדי למדוד מרחק מדויק.
    cfg.roi.erosion_size = 0; 
    
    % closing_size = 20: סגירה אגרסיבית כדי למנוע חורים בתוך האצבע.
    cfg.roi.closing_size = 20; 
end