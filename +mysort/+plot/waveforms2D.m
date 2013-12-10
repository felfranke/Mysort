function h = waveforms2D(wfs, electrodePositions, varargin)
    % wfs is tensor time x channels x items
    % electrodePositions is matrix, first column x, second column y
    P.AxesHandle = [];
    P.absThreshold = [];
    P.maxNumberOfChannels = [];
    P.plotArgs = {'-', 'color', [.5 .5 .5], 'linewidth', 1};
    P.plotMedian = 0;
    P.plotMedianPlotArgs = {'-', 'color', [.0 .0 .0], 'linewidth', 2};
    P.plotMeanConfidenceWithSigma = [];
    P.plotElNumbers = [];
    P.maxWaveforms = 3000;
    P = mysort.util.parseInputs(P, varargin, 'error');
    %assert(size(wfs,2) == size(electrodePositions,1), 'electrode number does not match!');
    if isempty(P.AxesHandle)
        P.AxesHandle = axes();
    end
    
    if ~iscell(P.plotArgs)
        P.plotArgs = {P.plotArgs};
    end
    
    if ~isempty(P.absThreshold)
        maxs = max(abs(wfs),[],1);
        electrodePositions(maxs<P.absThreshold,:) = [];
        wfs(:,maxs<P.absThreshold,:) = [];
    end
    
    if ~isempty(P.maxNumberOfChannels) && size(wfs,2) > P.maxNumberOfChannels
        mwfs = max(abs(wfs),[],3);
        maxs = max(abs(mwfs),[],1);
        maxs = sortrows([maxs(:) (1:length(maxs))'], 1);
        idx = maxs(end-P.maxNumberOfChannels+1:end,2);
        electrodePositions = electrodePositions(idx,:);
        wfs = wfs(:,idx,:);
    end    
    
    if ~isempty(P.maxWaveforms) & P.maxWaveforms < size(wfs,3)
        rp = randperm(size(wfs,3));
        wfs = wfs(:,:, rp(1:P.maxWaveforms));
    end
    
    EP = electrodePositions;
    [Tf, nC, nWf] = size(wfs);
    pIdx = nan((Tf+1)*nC,1);
    Y = nan((Tf+1)*nC,nWf);
    for i=1:nC
        s1 = ((Tf+1)*(i-1)+1);
        idx = s1:s1+Tf-1;
        pIdx(idx,1) = EP(i,1) + 15*(0:Tf-1)/Tf;
        Y(idx,:)   = EP(i,2) - .2*squeeze(wfs(:,i,:));
    end            
    set(P.AxesHandle, 'NextPlot', 'add');
    h = plot(P.AxesHandle, pIdx, Y, P.plotArgs{:});
    if P.plotMedian && ~isempty(P.plotMedianPlotArgs)
        hold on
        MED = median(Y,2);
        h(2) = plot(P.AxesHandle, pIdx, MED, P.plotMedianPlotArgs{:});
        if ~isempty(P.plotMeanConfidenceWithSigma)
            var_mean = P.plotMeanConfidenceWithSigma/sqrt(nWf);
            h(3) = plot(P.AxesHandle, pIdx, MED+3*var_mean, P.plotMedianPlotArgs{:});
            h(3) = plot(P.AxesHandle, pIdx, MED-3*var_mean, P.plotMedianPlotArgs{:});
        end
    end
    if ~isempty(P.plotElNumbers)
        for i=1:nC
            x = EP(i,1);
            y  = EP(i,2);
            text(x+15, y, num2str(P.plotElNumbers(i)), 'parent', P.AxesHandle);
        end          
    end
    axis(P.AxesHandle, 'tight');
    axis(P.AxesHandle, 'ij');