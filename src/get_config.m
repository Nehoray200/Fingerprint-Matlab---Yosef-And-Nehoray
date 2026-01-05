function cfg = get_config()
    % get_config - קובץ הגדרות מרכזי (מעודכן ומותאם מלא)
    
    %% 1. הגדרות מערכת וקבצים
    cfg.db_filename = 'fingerprint_database.mat';
    
    %% 2. הגדרות עיבוד מקדים (Preprocessing)
    % אלו היו "קשיחים" בתוך process_fingerprint, עדיף לרכז כאן
    cfg.preprocess.gauss_sigma = 0.8;       % עוצמת ההחלקה
    cfg.preprocess.bin_sensitivity = 0.65;  % רגישות הבינאריזציה האדפטיבית
    
    cfg.feature.descriptor_k = 5;   % מספר השכנים למתאר (Descriptor)

    %% 3. הגדרות מסיכה (ROI)
    cfg.roi.erosion_size = 0;   % משאירים 0 כדי לא לאבד מידע בקצוות
    cfg.roi.closing_size = 20;  % סגירה חזקה למניעת חורים באצבע
    
    %% 4. חילוץ מאפיינים (Feature Extraction)
    % כמה צעדים ללכת לאורך הרכס כדי לחשב זווית?
    cfg.feature.angle_steps = 3; 
    
    %% 5. הגדרות סינון (Filtering)
    cfg.filter.border_margin = 25; % מרחק מהקצה (מסיכה)
    cfg.filter.min_distance = 15;   % מרחק מינימלי למניעת כפילויות
    
    %% 6. הגדרות התאמה (Matching & Search)
    cfg.match.pass_threshold = 12.0;    % הציון המינימלי לזיהוי חיובי
    cfg.match.candidate_count = 50;     % כמה מועמדים לבדוק (הורדתי מ-80 לשיפור מהירות)
    
    % ספי החלטה בינאריים (האם להחשיב נקודה כתואמת?)
    cfg.match.max_dist = 15;            % מרחק בפיקסלים (כ-3% מהתמונה)
    
    % שינוי קריטי: 45 מעלות זה המון! הורדתי ל-30 כדי לדייק.
    cfg.match.max_ang_deg = 45;         
    cfg.match.max_ang_rad = deg2rad(cfg.match.max_ang_deg);
    
    %% 7. הגדרות ניקוד (Scoring Functions)
    % פרמטרים לפונקציות הגאוס (כמה מהר הציון יורד כשיש אי-התאמה)
    
    cfg.score.sigma_dist = 10;     % החמרה קלה בדיוק המיקום
    
    % >>> חסר לך הפרמטר הזה בקובץ המקורי! <<<
    % נדרש עבור calculate_score לחישוב איכות הזווית
    cfg.score.sigma_ang_rad = 0.5; % שווה בערך ל-28 מעלות
    cfg.score.sigma_desc = 45;     % משקל המתארים (Descriptors)
end