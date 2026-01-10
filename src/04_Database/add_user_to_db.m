function add_user_to_db(fname, name, dataStruct, path)
    % add_user_to_db - מוסיפה משתמש חדש לקובץ הנתונים
    
    if isfile(fname)
        load(fname, 'fingerprintDB');
        % בדיקת תאימות לאחור
        if ~isfield(fingerprintDB, 'descriptors')
             [fingerprintDB(:).descriptors] = deal([]); 
        end
        if ~isfield(fingerprintDB, 'T_sq')
             [fingerprintDB(:).T_sq] = deal([]); 
        end
    else
        % יצירת מאגר חדש עם השדה החדש לאופטימיזציה
        fingerprintDB = struct('name', {}, 'template', {}, 'descriptors', {}, 'imagePath', {}, 'T_sq', {});
    end
    
    % יצירת רשומה חדשה
    newEntry.name = name;
    newEntry.template = dataStruct.minutiae;        
    newEntry.descriptors = dataStruct.descriptors; 
    newEntry.imagePath = path;
    
    % --- אופטימיזציה: חישוב ושמירת הנורמה בריבוע ---
    % זה יחסוך חישוב יקר בזמן הזיהוי (Real-Time)
    newEntry.T_sq = sum(dataStruct.minutiae(:,1:2).^2, 2);
    % ---------------------------------------------
    
    % הוספה למערך ושמירה
    fingerprintDB(end+1) = newEntry;
    save(fname, 'fingerprintDB');
    
    msgbox(['המשתמש ' name ' נשמר בהצלחה!'], 'אישור');
end