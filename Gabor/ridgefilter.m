% =========================================================================
% RIDGEFILTER - שיפור התמונה בעזרת מסנן גאבור (Gabor Filter)
% =========================================================================
% תפקיד הפונקציה בפועל:
% זהו "המנוע" של המערכת. הפונקציה בונה מסנן ייחודי לכל פיקסל בתמונה,
% בהתבסס על:
% 1. הכיוון שלו (מ-ridgeorient)
% 2. העובי שלו (מ-ridgefreq)
%
% הפעולה שהיא מבצעת:
% היא "מורחת" את הפיקסלים *רק* לאורך כיוון הרכס.
% התוצאה: "חורים" ונתקים בתוך הרכס מתמלאים (נסגרים),
% ורעש שנמצא בין הרכסים (בעמקים) נמחק.
%
% פלט: תמונה משופרת ונקייה, מוכנה לבינאריזציה ודיקוק.
% =========================================================================


function [newim] = ridgefilter(im, orient, freq, kx, ky, showfilter)
% RIDGEFILTER - Enhances fingerprint image via oriented filters
%
% Usage: [newim] = ridgefilter(im, orient, freq, kx, ky, showfilter)
%
% Arguments:  im         - Image to be processed.
%             orient     - Ridge orientation image.
%             freq       - Ridge frequency image.
%             kx, ky     - Scale factors specifying the filter sigma relative
%                          to the wavelength of the filter (suggest 0.5).
%             showfilter - An optional flag 0/1.  If set to 1 the code will
%                          display the filter being created.
%
% Returns:    newim      - The enhanced image.

    if nargin == 5; showfilter = 0; end
    
    angleInc = 3;  % Fixed angle increment between filter orientations in degrees
    im = double(im);
    [rows, cols] = size(im);
    newim = zeros(rows,cols);
    
    % Round the array of frequencies to the nearest 0.01 to reduce the
    % number of distinct frequencies we have to generate filters for.
    freq_1d = freq(:);
    ind = find(freq_1d > 0);
    freq_1d(ind) = round(freq_1d(ind)*100)/100;
    unifreqs = unique(freq_1d(ind));
    
    % Generate filters corresponding to these distinct frequencies and
    % orientations in 'angleInc' increments.
    sigmax = 0; sigmay = 0;
    sze = zeros(length(unifreqs),1);
    filters = cell(length(unifreqs), 180/angleInc);
    
    for k = 1:length(unifreqs)
        sigmax = kx/unifreqs(k);
        sigmay = ky/unifreqs(k);
        sze(k) = round(3*max(sigmax,sigmay));
        [x,y] = meshgrid(-sze(k):sze(k));
        reffilter = exp(-(x.^2/sigmax^2 + y.^2/sigmay^2)/2)...
                    .*cos(2*pi*unifreqs(k)*x);
        
        % Generate rotated versions of the filter
        for o = 1:180/angleInc
            filters{k,o} = imrotate(reffilter, -(o*angleInc+90), 'bilinear', 'crop'); 
        end
    end

    % Apply the filters to the image
    % Find indices of matrix points greater than maxsze from the image boundary
    maxsze = sze(1);
    finalind = find(freq>0);
    
    % Convert orientation matrix values from radians to an index value
    % that corresponds to round(degrees/angleInc)
    maxorientindex = round(180/angleInc);
    orientindex = round(orient/pi*180/angleInc);
    i = find(orientindex < 1);   orientindex(i) = orientindex(i)+maxorientindex;
    i = find(orientindex > maxorientindex); orientindex(i) = orientindex(i)-maxorientindex; 
    
    % Filter the image
    for k = 1:length(unifreqs)
        thisfreq = unifreqs(k);
        
        % Find where this frequency occurs in the image
        freqind = find(freq_1d == thisfreq);
        
        % Iterate through the orientation indices
        for o = 1:180/angleInc
            ind = intersect(freqind, find(orientindex(:)==o));
             
            if ~isempty(ind)
                % Extract the relevant filter
                filter = filters{k,o};
                
                % Get row and col indices
                [r, c] = ind2sub([rows,cols], ind);
                
                % Apply filter to these pixels (valid boundary check required in loops)
                % Simplification for speed: Block processing or full convolution 
                % is usually done here. For pixel-wise efficiency:
                 
                 r_valid = r(r>sze(k) & r<rows-sze(k) & c>sze(k) & c<cols-sze(k));
                 c_valid = c(r>sze(k) & r<rows-sze(k) & c>sze(k) & c<cols-sze(k));
                 
                 % Note: This loop can be slow in MATLAB. A faster way is using
                 % block processing, but this is the explicit implementation.
                 for i = 1:length(r_valid)
                     blk = im(r_valid(i)-sze(k):r_valid(i)+sze(k), c_valid(i)-sze(k):c_valid(i)+sze(k));
                     newim(r_valid(i),c_valid(i)) = sum(sum(blk.*filter));
                 end
            end
        end
    end
end