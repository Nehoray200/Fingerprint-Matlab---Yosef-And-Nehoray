function visualize_match_result(img, dbTemp, alignedInput, name, score)
    % visualize_match_result - מציגה גרפית את תוצאת ההתאמה
    % Inputs:
    %   img:          התמונה המקורית של הנבדק
    %   dbTemp:       הנקודות של המשתמש מהמאגר (אדום)
    %   alignedInput: הנקודות של הנבדק אחרי יישור (ירוק)
    %   name:         שם המזוהה
    %   score:        ציון ההתאמה
    
    figure('Name', 'תוצאת זיהוי', 'NumberTitle', 'off');
    imshow(img); hold on;
    
    titleString = sprintf('Match Found: %s (Score: %.2f)', name, score);
    title(titleString, 'FontSize', 12, 'Color', 'b');
    
    if ~isempty(dbTemp) && ~isempty(alignedInput)
        % נקודות מהמאגר (המטרה) - אדום
        h1 = plot(dbTemp(:,1), dbTemp(:,2), 'ro', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Database');
        
        % נקודות מהקלט (אחרי שסובבנו אותן) - ירוק
        h2 = plot(alignedInput(:,1), alignedInput(:,2), 'g+', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Input (Aligned)');
        
        % קו מחבר בין נקודות קרובות (ויזואליזציה של ההתאמה)
        % (אופציונלי - עוזר לראות מי התאים למי)
        for i = 1:size(alignedInput, 1)
            % מחפש את הנקודה הקרובה ביותר במאגר
            dists = sum((dbTemp(:,1:2) - alignedInput(i,1:2)).^2, 2);
            [minD, idx] = min(dists);
            if minD < 100 % אם הן קרובות (מרחק < 10 פיקסלים)
                plot([alignedInput(i,1) dbTemp(idx,1)], ...
                     [alignedInput(i,2) dbTemp(idx,2)], 'y-', 'LineWidth', 1);
            end
        end
        
        legend([h1, h2], 'Location', 'best');
    end
    
    hold off;
end