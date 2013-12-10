function gdf = gdf2multiSessionGdf(gdf, start_end_times, sessionidx)
    % if the individual sesssion lengths are in L then
    % start_end_times = [0 cumsum(L)];
    if isempty(gdf)
        return
    end
    nS = length(start_end_times)-1;
    if isempty(start_end_times) || nS == 0
        error('star_end_times invalid');
    end
    if nargin == 2 || isempty(sessionidx)
        sessionidx = 1:nS;
    end
    gdf = [gdf zeros(size(gdf,1),1)];
    for i=1:nS
        idx = gdf(:,2) > start_end_times(i) & gdf(:,2) <= start_end_times(i+1);
        gdf(idx,3) = sessionidx(i);
        gdf(idx,2) = gdf(idx,2) - start_end_times(i);
    end
    assert(~any(gdf(:,3)==0), 'Some events were in no session!');