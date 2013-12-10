function xc = computeXCorrs(X, cp, maxLag, epochs, maxSamples)
    % computes the pairwise xcorr functions of columns cp(:,1) and cp(:,2)
    % of matrix X in the epochs (parts of columns) given in epochs.
    % if the length of all epochs is larger than maxSamples, only so many
    % epochs will be used, that at least maxSamples are contained.
    
    if isempty(cp)
        cp = mysort.noise.computeChannelPairs4Channels(1:size(X,2));
    end
    
%     if matlabpool('size')==0;
%         warning('No Matlabpool initialized. You can speed up computation by calling, e.g., matlabpool(n) with n being your computers core number');
%     end
    if nargin < 5
        maxSamples = size(X,1);
    end    
    if nargin < 4 || isempty(epochs)
        epochs = [1 min(size(X,1), maxSamples)];
    end
    
    L = mysort.epoch.length(epochs);
    totalEpochLength = sum(L);

    
    if totalEpochLength > maxSamples
        % randomy permute epochs
        rp = randperm(size(epochs,1));
        cs = cumsum(L(rp));
        lastIdx = find(cs>maxSamples,1);
        epochs = epochs(rp(1:lastIdx),:);
%         L = L(rp(1:lastIdx));
        totalEpochLength = cs(lastIdx);
    end
    
    % replace the channel index into X by the relative channel idx
    uChans = unique(cp(:));
    [a cpidx] = ismember(cp, uChans);

    xc = zeros(2*maxLag+1, length(uChans)^2);
    for k=1:size(epochs,1)
        % get all data for this epoch
        x = X(epochs(k,1):epochs(k,2), uChans);
        % compute channel pairs
        xc = xc+xcorr(x, maxLag, 'none');        
    end
    nCp = size(cp,1);
    % compute the index into xc for each of the cp
    xcidx = (cpidx(:,1)-1)*length(uChans) + cpidx(:,2);
    
    % take only those who are needed and normalize
    xc = xc(:, xcidx)/totalEpochLength;
