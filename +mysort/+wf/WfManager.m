classdef WfManager < handle
    properties             
        eventTimes     % stores the single channel detection events
        eventChans     % stores the channelindex into the wfDataSource.ME 
                       % multiElectrode where the spike was detected
        eventIDs       % unique identifier of that event
        MultiElectrode
    end
    
    %------------------------------------------------------------------
    methods (Abstract)
        wfs = getWaveform4Idx(self, eventIdx, cutleft, cutlength, electrodeNumber)
        wfManager = getWfManger4SubIdx(self, idx)
        nC = getNChannels(self)
    end
    
    methods
        %------------------------------------------------------------------
        function self = WfManager(eventTimes, eventChans, eventIDs, ME)
            self.eventTimes = eventTimes;
            self.eventChans = eventChans;
            if nargin < 3 || isempty(eventIDs)
                eventIDs = 1:length(eventTimes);
            end
            self.eventIDs = eventIDs;
%             if nargin < 4 || isempty(ME)
%                 ME = mysort.ds.MultiElectrode(unique(eventChans));
%             end
            self.MultiElectrode = ME;
        end

        %------------------------------------------------------------------
        function wfs = getWaveform4ID(self, eventIDs, varargin)
            [c, eventIdx, ib] = intersect(self.eventIDs, eventIDs);            
            wfs = self.getWaveform4Idx(eventIdx, varargin{:});
        end

        %------------------------------------------------------------------
        function n = getNWfs(self)
            n = length(self.eventTimes);
        end

        %------------------------------------------------------------------
        function wfManager = getWfManger4SubIDs(self, eventIDs)
            [c, eventIdx, ib] = intersect(self.eventIDs, eventIDs); 
            assert(length(eventIdx) == length(eventIDs), 'Not all eventIDs could be found!');
            s = self; % matlab bug here?
            wfManager = s.getWfManger4SubIdx(eventIdx);
        end        
    end
end