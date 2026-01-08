function cfg = get_config()
    % get_config - קובץ הגדרות מרכזי (גרסה מתוקנת)
    
    %% 1. הגדרות מערכת וקבצים
    cfg.db_filename = 'fingerprint_database.mat';
    
    %% 2. הגדרות Gabor (שיפור תמונה מתקדם)
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
    
    %% 3. הגדרות עיבוד המשך ובינאריזציה
    cfg.binarize.sens = 0.5;      
    
    %% 4. הגדרות רישום ובקרת איכות (Enrollment)
    cfg.enroll.min_minutiae = 12; % מינימום נקודות לרישום
    
    %% 5. הגדרות מסיכה ועיבוד מקדים
    cfg.roi.erosion_size = 0;   
    cfg.roi.closing_size = 20;  
    
    cfg.preprocess.gauss_sigma = 0.8;       
    cfg.preprocess.bin_sensitivity = 0.65;  
    
    %% 6. חילוץ מאפיינים
    cfg.feature.descriptor_k = 5;   
    cfg.feature.angle_steps = 5;    
    
    %% 7. הגדרות סינון (Filtering)
    cfg.filter.border_margin = 25; 
    cfg.filter.min_distance = 20;  
    
    % סינון גיאומטרי
    cfg.filter.max_short_ridge_dist = 15; 
    cfg.filter.max_bridge_dist = 12; 
    cfg.filter.max_spike_dist = 8;
    cfg.filter.angle_tolerance = deg2rad(35);
    
    %% 8. הגדרות התאמה (Matching)
    cfg.match.pass_threshold = 12.0;    
    cfg.match.candidate_count = 50;     
    
    cfg.match.max_dist = 15;            
    cfg.match.max_ang_deg = 45;         
    cfg.match.max_ang_rad = deg2rad(cfg.match.max_ang_deg);
    
    %% 9. הגדרות ניקוד (Scoring)
    cfg.score.sigma_dist = 10;     
    cfg.score.sigma_ang_rad = 0.5; 
    cfg.score.sigma_desc = 45;     
end