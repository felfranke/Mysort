
function R = alignGDFs(gdf1, gdf2, maxJitter, maxShift, maxOverlapDist)
    
    st1 = {};
    if ~isempty(gdf1)
        gdf1 = double(sortrows(gdf1,2));
        [st1 newids1 ids1] = mysort.spiketrain.fromGdf(gdf1);
    end
    
    st2 = {};
    if ~isempty(gdf2)
        gdf2 = double(sortrows(gdf2,2));
        [st2 newids2 ids2]= mysort.spiketrain.fromGdf(gdf2);
    end
    R = mysort.spiketrain.align(st1, st2, maxJitter, maxShift, maxOverlapDist, ids1, ids2);
end