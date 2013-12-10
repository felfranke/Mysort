function V = vSubChanSel(V, nC, chan_idx)
    % subselects the channel index into multi channel waveforms on every
    % channel specified in chan_idx 

    T = mysort.wf.v2t(V, nC);
    T = T(:,chan_idx,:);
    V = mysort.wf.t2v(T);