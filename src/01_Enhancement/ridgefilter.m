function [newim] = ridgefilter(im, orient, freq, kx, ky, showfilter)
    % RIDGEFILTER - גרסה מתוקנת עם PADDING למניעת מחיקת קצוות
    
    if nargin == 5; showfilter = 0; end
    
    angleInc = 3;
    im = double(im);
    [rows, cols] = size(im);
    newim = zeros(rows,cols);
    
    % עיגול תדרים
    freq_1d = freq(:);
    ind = find(freq_1d > 0);
    freq_1d(ind) = round(freq_1d(ind)*100)/100;
    unifreqs = unique(freq_1d(ind));
    
    % חישוב גודל מקסימלי של פילטר (לצורך ריפוד)
    % אנחנו צריכים לדעת מה הריפוד הכי גדול שנצטרך כדי לא לחרוג מהגבולות
    max_filter_size = 0;
    
    % שלב 1: בניית הפילטרים וחישוב הגודל המקסימלי
    sze = zeros(length(unifreqs),1);
    filters = cell(length(unifreqs), 180/angleInc);
    
    for k = 1:length(unifreqs)
        sigmax = kx/unifreqs(k);
        sigmay = ky/unifreqs(k);
        sze(k) = round(3*max(sigmax,sigmay));
        max_filter_size = max(max_filter_size, sze(k)); % שמירת הגודל המקסימלי
        
        [x,y] = meshgrid(-sze(k):sze(k));
        reffilter = exp(-(x.^2/sigmax^2 + y.^2/sigmay^2)/2)...
                    .*cos(2*pi*unifreqs(k)*x);
        
        for o = 1:180/angleInc
            filters{k,o} = imrotate(reffilter, -(o*angleInc+90), 'bilinear', 'crop'); 
        end
    end
    
    % === תיקון קריטי: ריפוד התמונה (Padding) ===
    % מוסיפים שוליים של אפסים (או שכפול שפה) מסביב לתמונה המקורית
    % כדי שנוכל לגשת לפיקסלים בקצה בלי לחרוג מהמערך.
    padSz = max_filter_size + 2; % קצת ספייר לביטחון
    im_padded = padarray(im, [padSz padSz], 'symmetric'); % symmetric עדיף על אפסים בקצה
    
    % המרת המטריצות לאינדקסים
    maxorientindex = round(180/angleInc);
    orientindex = round(orient/pi*180/angleInc);
    i = find(orientindex < 1);   orientindex(i) = orientindex(i)+maxorientindex;
    i = find(orientindex > maxorientindex); orientindex(i) = orientindex(i)-maxorientindex; 
    
    % שלב 2: החלת הפילטרים על התמונה המרופדת
    for k = 1:length(unifreqs)
        thisfreq = unifreqs(k);
        freqind = find(freq_1d == thisfreq);
        
        for o = 1:180/angleInc
            ind = intersect(freqind, find(orientindex(:)==o));
             
            if ~isempty(ind)
                filter = filters{k,o};
                [r, c] = ind2sub([rows,cols], ind);
                
                % כאן השינוי הגדול: אין יותר בדיקת "valid" שמוחקת קצוות.
                % אנחנו משתמשים באינדקסים מוזזים מול התמונה המרופדת.
                
                % הסטת האינדקסים למרכז התמונה המרופדת
                r_pad = r + padSz;
                c_pad = c + padSz;
                
                for i = 1:length(r)
                    % שליפת הבלוק מתוך התמונה המרופדת (בטוח לחלוטין)
                    r_curr = r_pad(i);
                    c_curr = c_pad(i);
                    sz = sze(k);
                    
                    blk = im_padded(r_curr-sz:r_curr+sz, c_curr-sz:c_curr+sz);
                    
                    % כתיבה לתמונה החדשה (באינדקסים המקוריים)
                    newim(r(i), c(i)) = sum(sum(blk.*filter));
                end
            end
        end
    end
end