function spiketrain(gdf, varargin)
P.yoffset = 0;
P.restrictTo = [];
P.colorList = {};
P.setYLims = 0;
P = mysort.util.parseInputs(P, varargin);

if ~isempty(P.restrictTo)
    gdf(~ismember(gdf(:,1), P.restrictTo),:) = [];
end
c = unique(gdf(:,1));
hold on
for i=1:length(c)
    idx = gdf(:,1) == c(i);
    if isempty(P.colorList)
        plot(gdf(idx,2), P.yoffset+c(i), 'o', 'markersize', 15, ...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor',mysort.plot.vectorColor(c(i)))
    else
        plot(gdf(idx,2), P.yoffset+c(i), 'o', 'markersize', 15, ...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor',P.colorList{c(i)})
    end
end
if P.setYLims
    set(gca, 'ylim', [0 length(c)+1]);
end