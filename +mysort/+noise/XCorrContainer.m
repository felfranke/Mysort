classdef XCorrContainer < handle
    properties(Constant = true)
        MAXNCHANS = 100000;
    end
    properties
        P
        X
        nXCorrs
        maxLag
        XCorrBuffer
        XCorrBufferChannelPairHashes
    end
    
    methods
        %------------------------------------------------------------------
        function self = XCorrContainer(X, maxLag, varargin)
            P.noiseEpochs = [];
            P.startBufferSize = 100;
            P = mysort.util.parseInputs(P, varargin);
            
            self.P = P;
            self.X = X;
            self.maxLag = maxLag;
            self.XCorrBuffer = zeros(2*maxLag+1, P.startBufferSize);
            self.XCorrBufferChannelPairHashes = zeros(P.startBufferSize, 1);
            self.nXCorrs = 0;
        end
        
        %------------------------------------------------------------------
        function [xc cp] = getXCorr4Channels(self, channelIdx, maxLag)
            if nargin < 3
                maxLag = self.maxLag;
            elseif maxLag > self.maxLag
                error('maxLag must not be larger then the maxLag provided in the constructor');
            end
            [bIdx cp h] = self.getBufferIdx4Channels(channelIdx);
            newCPs = bIdx==0;
            if any(newCPs)
                bIdx(newCPs) = self.computeXCorr4ChannelPairs(cp(newCPs,:), h(newCPs));
            end
            xc = self.XCorrBuffer(:,bIdx);
        end
        %------------------------------------------------------------------
        function x = invMul(self, y, channelIdx)
            % solves C*x = y; <=> x = inv(C)*y
            % if y is a matrix invMul operates on the ROWS of y
            
%             nC = length(channelIdx);
%             maxLag = self.maxLag;
            ccol = self.getCCol4Channels(channelIdx);            
            
            if size(y,1) > 1 && size(y,2) > 1
                % y is a matrix, solve every row individually
                x = zeros(size(y));
                for i=1:size(y,1)
                    x(i,:) = matlabfilecentral.block_levinson(y, ccol);
                end                
            else
                % y is a vector, keep orientation
                turn = 0;
                if size(y,1) == 1
                    turn = 1;
                    y = y';
                end

                x = matlabfilecentral.block_levinson(y, ccol);

                if turn
                    x = x';
                end
            end
        end        
        
        %------------------------------------------------------------------
        function ccol = getCCol4Channels(self, channelIdx)
            Cte = self.getCte4Channels(channelIdx);
            ccol = mysort.noise.Cte2Ccol(Cte, length(channelIdx));
        end        
        %------------------------------------------------------------------
        function Cte = getCte4Channels(self, channelIdx)
            [xc cp] = self.getXCorr4Channels(channelIdx);
            maxlag = (size(xc,1)-1)/2;
            Tf = maxlag+1;
            nC = length(channelIdx);

            Cte = zeros(Tf*nC, Tf*nC);
            uChannels = unique(cp(:));
            for xccol=1:size(cp,1)
                i = find(uChannels==cp(xccol,1),1);
                j = find(uChannels==cp(xccol,2),1);
                iidx = (i-1)*Tf +1: i*Tf;
                jidx = (j-1)*Tf +1: j*Tf;
                Cte(iidx, jidx) = toeplitz(xc(Tf:end, xccol), flipud(xc(1:Tf, xccol)));
                if i~=j
                    Cte(jidx, iidx) = Cte(iidx, jidx)';
                end
            end            
        end       
        %------------------------------------------------------------------
        function Cce = getCce4Channels(self, channelIdx)
            Cte = self.getCte4Channels(channelIdx);
            Cce = mysort.noise.Cte2Cce(Cte, length(channelIdx));
        end               
        
        
        %------------------------------------------------------------------
        function bIdx = computeXCorr4ChannelPairs(self, cp, hashes)
            if isempty(cp)
                bIdx = [];
                return
            end
            xc = mysort.noise.computeXCorrs(self.X, cp, self.maxLag, self.P.noiseEpochs);
            bIdx = self.addXCorr4ChannelPairs(xc, hashes);
        end
        %------------------------------------------------------------------
        function newbIdx = addXCorr4ChannelPairs(self, xc, hashes)
            % check if buffer needs to be enlarged
            nNewCps = size(xc,2);
            if size(self.XCorrBuffer,2) < nNewCps + self.nXCorrs
                newSize = ceil(1.5*(nNewCps + self.nXCorrs));
                self.XCorrBuffer(1, newSize) = 0;
                self.XCorrBufferChannelPairHashes(newSize,1) = 0;
            end
            
            % add xc to buffer
            newbIdx = self.nXCorrs+1:self.nXCorrs+nNewCps;
            self.XCorrBufferChannelPairHashes(newbIdx,1) = hashes;
            self.XCorrBuffer(:,newbIdx) = xc;
            self.nXCorrs = self.nXCorrs+nNewCps;
        end        
        
        %------------------------------------------------------------------
        function [bIdx cp h] = getBufferIdx4Channels(self, channelIdx)
            cp = mysort.noise.computeChannelPairs4Channels(channelIdx);
            [bIdx h] = self.getBufferIdx4ChannelPairs(cp);
        end
        %------------------------------------------------------------------
        function [bIdx cp_hashes] = getBufferIdx4ChannelPairs(self, cp)
            cp_hashes = self.computeHash4ChannelPair(cp);
            [~, bIdx] = ismember(cp_hashes, self.XCorrBufferChannelPairHashes);
        end        

        %------------------------------------------------------------------
        function h = computeHash4ChannelPair(self, cp)
            h = uint32(cp(:,1)*self.MAXNCHANS + cp(:,2));
        end    
        %------------------------------------------------------------------
        function cp = computeChannelPair4Hash(self, h)
            cp = [floor(h/self.MAXNCHANS) mod(h,self.MAXNCHANS)];
        end           
    end
end