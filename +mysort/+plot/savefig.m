
function savefig(fig_handle, fname, varargin)
    % Saves the figure in the provided figure handle or the current figure to
    % a) a png file and b) a .fig file. Since the default dpi of 100 might
    % be changed during this process to increase the quality of the .png file
    % it will set all "unit" properties of axes/annotations etc in the
    % figure to "normalized" before calling print.
    P.dpi = 300;
    P.fig = 1;
    P.png = 1;
    P.eps = 0;
    P.ai = 0;
    P = mysort.util.parseInputs(P, 'savefig', varargin);    
    global savefig__;
    if ~isempty(savefig__) && savefig__ == 0
        return
    end
    if nargin == 1
        fname = fig_handle;
        fig_handle = gcf();
    end
    set(fig_handle, 'PaperPositionMode', 'auto');   % Use screen size
    visibility = get(fig_handle, 'visible');
    set(fig_handle, 'visible', 'on');
    mysort.plot.figureChildrenSet(fig_handle, 'Units', 'normalized');
    if P.png
        print(fig_handle, ['-r' num2str(P.dpi)], '-dpng', [fname '.png']);
    end
    if P.fig
        saveas(fig_handle, [fname '.fig'], 'fig');
    end
    if P.eps
        saveas(fig_handle, [fname '.eps'], 'eps');
    end
    if P.ai
        saveas(fig_handle, [fname '.ai'], 'ai');
    end    
    set(fig_handle, 'visible', visibility);