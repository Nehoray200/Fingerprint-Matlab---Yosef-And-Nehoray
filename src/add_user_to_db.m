function add_user_to_db(fname, name, dataStruct, path)
    % add_user_to_db - מוסיפה משתמש חדש לקובץ הנתונים
    % Inputs:
    %   fname:      שם קובץ ה-MAT של המאגר
    %   name:       שם המשתמש להוספה
    %   dataStruct: מבנה המכיל minutiae ו-descriptors
    %   path:       נתיב התמונה המקורית (לרפרנס)
    
    if isfile(fname)
        load(fname, 'fingerprintDB');
        % בדיקת תאימות לאחור (הוספת שדה חסר אם צריך)
        if ~isfield(fingerprintDB, 'descriptors')
             [fingerprintDB(:).descriptors] = deal([]); 
        end
    else
        % יצירת מאגר חדש אם לא קיים
        fingerprintDB = struct('name', {}, 'template', {}, 'descriptors', {}, 'imagePath', {});
    end
    
    % יצירת רשומה חדשה
    newEntry.name = name;
    newEntry.template = dataStruct.minutiae;       
    newEntry.descriptors = dataStruct.descriptors; 
    newEntry.imagePath = path;
    
    % הוספה למערך ושמירה
    fingerprintDB(end+1) = newEntry;
    save(fname, 'fingerprintDB');
    
    msgbox(['המשתמש ' name ' נשמר בהצלחה!'], 'אישור');
end