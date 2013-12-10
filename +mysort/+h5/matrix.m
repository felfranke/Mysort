classdef matrix < handle
    properties (Constant)

    end
    properties
        fname
        h5path
        nDims
        h5_dims
        h5_maxDims
        dims
        maxDims        
        chunkDims
        deflation
        h5type
        
        fileID
        datasetID
        dataspaceID
        
        layout
        propInfo
        nProps
    end
    
    methods
        %% CONSTRUCTOR FUNCTION
        %------------------------------------------------------------------
        function self = matrix(fname, h5path, varargin)
            self.fname = fname;
            self.h5path = h5path;
            
            if exist(fname, 'file')
                self = self.openH5File(varargin{:});
            else
                self = mysort.h5.createVariableAndOrFile(fname, h5path, varargin{:});
            end
        end
        % DESTRUCTOR
        %------------------------------------------------------------------
        function delete(self)
            self.closeH5File();
        end
        
        
        %% TOP LEVEL DATA ACCESS FUNCTIONS
        %------------------------------------------------------------------
        function B = subsref(self,S)
            if strcmp(S(1).type, '.')
                % for the '.' subsref call the standard one
                B = builtin('subsref', self, S);
                return
            end
            assert(strcmp(S.type, '()'), 'Only () is implemented!');
            assert(length(S)==1, 'Only X(a,b) is possible, no further subindexing!');
            assert(length(S.subs) < 3, 'Only 2 dimensions can be indexed!');
            %assert(length(S.subs) > 1, '(x) is not implemented!')
%             if ~self.transposed
            B = self.getData(S.subs{:});
%             else
%                 B = self.getData(S.subs{2}, S.subs{1});
%             end
        end
        %------------------------------------------------------------------
        function self = subsasgn(self, S, B)
            if strcmp(S(1).type, '.')
                % for the '.' subsref call the standard one
                B = builtin('subsasgn', self, S, B);
                return
            end
            assert(strcmp(S.type, '()'), 'Only () is implemented!');
            assert(length(S)==1, 'Only X(a,b) is possible, no further subindexing!');
            assert(length(S.subs) < 3, 'Only 2 dimensions can be indexed!');
%             if ~self.transposed
                self.setData(B, S.subs{:});
%             else
%                 self.setData(B, S.subs{2}, S.subs{1});
%             end
        end
        
        %------------------------------------------------------------------
        function L = getNSamples_(self)
            L = self.dims(1);
        end  
        %------------------------------------------------------------------
        function varargout = size(self,varargin)
            varargout = matlabfilecentral.parseSize.parseSize(self.dims,nargout,varargin{:}); 
        end             
        %------------------------------------------------------------------
        function out = end(self, k, n)
            out = self.size(k);
        end   
        %------------------------------------------------------------------
        function self = transpose(self)
            error('not implemented, conflicts with handle class');
        end
        %------------------------------------------------------------------
        function self = ctranspose(self)
            error('not implemented, conflicts with handle class');     
        end
        
        %% MIDDLE LEVEL ACCESS FUNCTIONS
        %------------------------------------------------------------------ 
        %------------------------------------------------------------------
        function X = getData(self, varargin)
            [bb relIdx] = mysort.h5.getBoundingBoxFromIndexing(self.size, varargin{:});
            if nargin == 2
                % if only one index was requested, only ask for one
                % dimension
                bb = bb(:,1);
            end
            assert(~any(bb(:)<=0), 'Bounding box contains invalid indices!');
            block = bb(2,:) - bb(1,:) +1;
            numEl = prod(block);
            assert(numEl < 10^9, sprintf('Loading that much data (%d) at once is not recommended!', numEl));
            offset = bb(1,:) - 1;
            % read outer bounding box of requested data, this is usually faster
            % than reading individual rows or indices
            X = mysort.h5.read_dset(self.datasetID, block, offset);
            % select actually requested data
            if ~isempty(relIdx)
                X = X(relIdx{:});
            end
        end
        
        %------------------------------------------------------------------
        function setData(self, X, varargin)
            [bb relIdx] = mysort.h5.getBoundingBoxFromIndexing(self.dims, varargin{:});
            assert(isempty(relIdx), 'Currently only consecutive blocks can be written in an h5.matrix!');
            if nargin == 3
                bb = bb(:,1);
            end
            block = bb(2,:) - bb(1,:) +1;
            offset = bb(1,:)-1;
            dBlock = size(X);
            if ~any(dBlock~=1) && any(block~=1)
                X = repmat(X, block);
                dBlock = size(X);
            end
            assert(~any(dBlock~=block), 'Assigning a bigger slab a smaller slab is not implemented. Use repmat to manually increase the data size');
            
            % check if dataset needs to be extended
            self.check_extend(dBlock+offset);
            
            mysort.h5.write_dset(self.datasetID, X, offset);
        end 
        
        %------------------------------------------------------------------
        function check_extend(self, e)
            h5_e = fliplr(e);
            if any(h5_e > self.h5_dims)
                me = max([h5_e; self.h5_dims], [], 1);
                H5D.extend(self.datasetID, me); % depricated? remove?
                H5D.set_extent(self.datasetID, me);
                self.h5_dims = me;
                self.dims = fliplr(me);
                % keep track of that internally, this is not directly
                % reflected in the h5 file. need some flush maybe?
            end
        end
%     end
%     
%     methods (Access = private)
        %% USED BY CONSTRUCTOR/DESTRUCTOR    
        %------------------------------------------------------------------
        function self = openH5File(self, bReadOnly)
            plist = 'H5P_DEFAULT';
            if nargin == 1 || ~bReadOnly
                rmode = 'H5F_ACC_RDWR';
            else
                rmode = 'H5F_ACC_RDONLY';
            end
            try
                self.fileID    = H5F.open(self.fname, rmode, plist); 
            catch
                str = mysort.util.buildLastErrString();
                disp(str);
                error('Could not open file %s!', self.fname);
            end
                
            try
                self.datasetID = H5D.open(self.fileID, self.h5path);
            catch
                str = mysort.util.buildLastErrString();
                disp(str);
                error('Could not find H5 Variable %s!', self.h5path);
            end
            self.dataspaceID = H5D.get_space(self.datasetID);
            self.getProps();
        end
        
        %------------------------------------------------------------------
        function getProps(self)
            [self.nDims self.h5_dims self.h5_maxDims] = H5S.get_simple_extent_dims(self.dataspaceID);
            self.dims = fliplr(self.h5_dims);
            self.maxDims = fliplr(self.h5_maxDims);
            plist = H5D.get_create_plist(self.datasetID);
            self.layout = H5P.get_layout(plist);
            self.nProps = H5P.get_nprops(plist);
            self.propInfo = mysort.h5.h5propinfo(plist);
        end
        
        %------------------------------------------------------------------
        function self = closeH5File(self)
            try
                H5D.close(self.datasetID);
            catch
%                 warning('could not close h5 dataset!');
            end
            try
                H5F.close(self.fileID); 
            catch
%                 warning('could not close h5 file!');
            end
        end
    end
end