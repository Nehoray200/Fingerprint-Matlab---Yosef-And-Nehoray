function add_user_to_db(fname, name, dataStruct, imgPath)
    % add_user_to_db - הוספת משתמש עם אופטימיזציה לחישוב מרחקים
    
    % טעינת המאגר הקיים או יצירת חדש
    if isfile(fname)
        loaded = load(fname, 'fingerprintDB');
        fingerprintDB = loaded.fingerprintDB;
        
        % תיקון תאימות לאחור (אם המאגר ישן וחסרים שדות)
        if ~isfield(fingerprintDB, 'T_sq')
             [fingerprintDB(:).T_sq] = deal([]); 
        end
    else
        fingerprintDB = struct('name', {}, 'template', {}, 'descriptors', {}, 'imagePath', {}, 'T_sq', {});
    end
    
    % בניית הרשומה החדשה
    newEntry.name = name;
    newEntry.template = dataStruct.minutiae;        
    newEntry.descriptors = dataStruct.descriptors; 
    newEntry.imagePath = imgPath;
    
    % --- אופטימיזציה קריטית ---
    % חישוב סכום הריבועים מראש (חוסך זמן יקר בזמן הזיהוי)
    newEntry.T_sq = sum(dataStruct.minutiae(:,1:2).^2, 2);
    % --------------------------
    
    % הוספה ושמירה
    fingerprintDB(end+1) = newEntry;
    save(fname, 'fingerprintDB');
    
    disp(['>> משתמש נוסף למאגר: ' name]);
    msgbox(['המשתמש ' name ' נשמר בהצלחה!'], 'אישור');
end