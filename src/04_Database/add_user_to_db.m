function add_user_to_db(fname, name, dataStruct, processedImg)
    % add_user_to_db - גרסה מעודכנת: שומרת את התמונה החתוכה במאגר
    % הקלט 'processedImg' הוא התמונה עצמה (מטריצה), לא נתיב לקובץ.

    % טעינת המאגר הקיים או יצירת חדש
    if isfile(fname)
        loaded = load(fname, 'fingerprintDB');
        fingerprintDB = loaded.fingerprintDB;
    else
        % מבנה מעודכן: במקום imagePath יש לנו processedImg
        fingerprintDB = struct('name', {}, 'template', {}, 'descriptors', {}, 'processedImg', {}, 'T_sq', {});
    end

    % בניית הרשומה החדשה
    newEntry.name = name;
    newEntry.template = dataStruct.minutiae;
    newEntry.descriptors = dataStruct.descriptors;
    % --- שינוי קריטי: שמירת התמונה החתוכה בתוך המאגר ---
    newEntry.processedImg = processedImg;
    % -------------------------------------------------

    % חישוב T_sq (אופטימיזציה לזיהוי)
    newEntry.T_sq = sum(dataStruct.minutiae(:,1:2).^2, 2);

    % הוספה למערך
    if isempty(fingerprintDB)
        fingerprintDB = newEntry;
    else
        fingerprintDB(end+1) = newEntry;
    end

    % שמירה לקובץ
    save(fname, 'fingerprintDB');

    disp(['>> משתמש נוסף למאגר: ' name]);
end