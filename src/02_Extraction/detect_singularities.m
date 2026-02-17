function singularities = detect_singularities(orientim, mask)
    % detect_singularities - Finds Core and Delta points using Poincare Index
    % Returns a struct with 'cores' and 'deltas' (Nx2 coordinates: [x, y]).
    % This enables "Absolute Pre-alignment" capabilities.
    
    singularities = struct('cores', [], 'deltas', []);
    if nargin < 2, return; end

    [rows, cols] = size(orientim);
    
    % 1. Calculate Poincare Index using 8-neighbor path
    % We use matrix shifting for speed instead of loops
    
    % Define 8-neighbor path (counter-clockwise)
    % offsets: (row, col)
    path_r = [-1 -1 -1  0  1  1  1  0];
    path_c = [-1  0  1  1  1  0 -1 -1];
    % Close loop
    path_r(end+1) = path_r(1);
    path_c(end+1) = path_c(1);
    
    sum_diff = zeros(rows, cols);
    
    for i = 1:8
        % Shift orientation image to get value of neighbor i
        % (Note: circshift shifts content, so shift(-1) moves (2,2) to (1,1).
        % We want to bring neighbor (r,c) to center. So shift(-r, -c).)
        val_curr = circshift(orientim, [-path_r(i), -path_c(i)]);
        val_next = circshift(orientim, [-path_r(i+1), -path_c(i+1)]);
        
        diff = val_next - val_curr;
        
        % Wrap differences to [-pi/2, pi/2]
        % This is crucial because orientation is defined modulo pi (0..pi)
        diff(diff < -pi/2) = diff(diff < -pi/2) + pi;
        diff(diff > pi/2)  = diff(diff > pi/2) - pi;
        
        sum_diff = sum_diff + diff;
    end
    
    % 2. Identify Singularities
    % Poincare Index = sum_diff / pi
    % Core (Loop/Whorl): Index = 1 (sum = pi)
    % Delta: Index = -1 (sum = -pi)
    
    p_index = sum_diff / pi;
    
    % Filter by mask and border (avoid spurious detections at edges)
    border = 5;
    valid_mask = mask;
    valid_mask(1:border, :) = 0; valid_mask(end-border+1:end, :) = 0;
    valid_mask(:, 1:border) = 0; valid_mask(:, end-border+1:end) = 0;
    
    % Tolerance for float comparison
    tol = 0.2; 
    
    core_map = (abs(p_index - 1) < tol) & valid_mask;
    delta_map = (abs(p_index + 1) < tol) & valid_mask;
    
    % 3. Post-processing (Clustering)
    % Singularities often appear as small clusters of pixels. We take the centroid.
    singularities.cores = get_centroids(core_map);
    singularities.deltas = get_centroids(delta_map);
end

function points = get_centroids(binary_map)
    points = [];
    % Remove very small noise
    binary_map = bwareaopen(binary_map, 2);
    
    % Use regionprops to find centers of connected components
    stats = regionprops(binary_map, 'Centroid');
    if ~isempty(stats)
        points = cat(1, stats.Centroid); % Returns [x, y]
    end
end