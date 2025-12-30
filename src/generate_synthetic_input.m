function inputDB = generate_synthetic_input(templateDB, imgSize, rotationDeg, shiftX, shiftY)
    % generate_synthetic_input - יוצרת טביעה "מזויפת" לבדיקה על ידי עיוות המקור
    % קלט:
    %   templateDB: רשימת הנקודות המקורית [X, Y, Type, Angle]
    %   imgSize: גודל התמונה [rows, cols] (כדי למצוא את המרכז לסיבוב)
    %   rotationDeg: כמה לסובב (במעלות)
    %   shiftX, shiftY: כמה להזיז (בפיקסלים)
    % פלט:
    %   inputDB: הרשימה החדשה המעוותת
    
    if isempty(templateDB)
        inputDB = [];
        return;
    end

    inputDB = templateDB; % מעתיקים את המקור
    
    % המרות וחישובים מקדימים
    theta_rad = deg2rad(rotationDeg);
    c = cos(theta_rad);
    s = sin(theta_rad);
    
    centerY = imgSize(1) / 2;
    centerX = imgSize(2) / 2;
    
    % לולאה לביצוע הטרנספורמציה על כל נקודה
    for k = 1:size(inputDB, 1)
        % 1. חילוץ קואורדינטות מקוריות
        x = inputDB(k, 1);
        y = inputDB(k, 2);
        angle = inputDB(k, 4);
        
        % 2. ביצוע סיבוב סביב מרכז התמונה
        % מזיזים את המרכז ל-(0,0)
        x_centered = x - centerX;
        y_centered = y - centerY;
        
        % כפל מטריצות לסיבוב
        x_rot = x_centered * c - y_centered * s;
        y_rot = x_centered * s + y_centered * c;
        
        % מחזירים את המרכז
        new_x = x_rot + centerX;
        new_y = y_rot + centerY;
        
        % 3. ביצוע הזזה (Translation)
        new_x = new_x + shiftX;
        new_y = new_y + shiftY;
        
        % 4. הוספת רעש אקראי (Random Noise)
        % במציאות המיקום אף פעם לא מושלם, נוסיף סטייה של עד 2 פיקסלים
        noise_x = (rand() - 0.5) * 2; 
        noise_y = (rand() - 0.5) * 2;
        
        % 5. עדכון הערכים בטבלה החדשה
        inputDB(k, 1) = new_x + noise_x;
        inputDB(k, 2) = new_y + noise_y;
        
        % עדכון הזווית (גם הכיוון של המינוציה מסתובב!)
        % משתמשים ב-wrapToPi כדי לשמור על טווח חוקי של רדיאנים
        inputDB(k, 4) = mod(angle + theta_rad + pi, 2*pi) - pi;
    end
end