classdef CsvIface < handle
    %CSVIFACE A Csv descriptive language to describe busses and vectors
    %
    
    properties
        filename;
        lnumber; %Line number
        itable;
        itable_names = {'Name','Alias','Bus','Vec'};
    end
    
    methods
        
        %% CSVIFACE Create object from filename
        function obj = CsvIface(filename)
            obj.filename = filename;
            obj.read_csv;
        end
        
        function append_name(obj,name,bus)
            if ~exist('bus','var')
                bus = '';
            end
            t=cell2table({name,'',bus,''});
            obj.append_table(t);
        end
        
        function append_line(obj,line)
            strcell = strsplit(line,',','CollapseDelimiters',0);
            strcell = obj.check_line(strcell);
            t = cell2table(strcell);
            obj.append_table(t);
        end
        
        
        
        %% FIND_ITEM - find an itemp by name, returns 0 if item does not exist, otherwise returns index
        function index = find_item(obj,name)
            index = 0;
            if( ~isempty(obj.itable))
                
                sfind = strcmp(obj.itable.Name,name);
                if any(sfind)
                    index = find(sfind,1,'first');
                end
                    
            end
            
        end
        
        %% Sort the iface table
        function sort(obj)
           obj.itable  = sortrows(obj.itable,{'Bus','Vec','Name'},{'ascend','ascend','ascend'});
        end
        
        
        %% WRITE_CSV Write out the csv file
        function write_csv(obj, fout)
            
            if ~exist('fout','var')
                fout = obj.filename;
            end
            writetable(obj.itable,fout)
        end
    end
    
    methods (Access='private')
        function read_csv(obj)
            if exist(obj.filename,'file')
                fprintf('\tFound existing csv %s, reading file\n', obj.filename);
                
                fid = fopen(obj.filename);
                fgetl(fid); %skip first line
                line = fgetl(fid);
                obj.lnumber = 2;
                while ischar(line)
                    if ~isempty(line)
                        obj.append_line(line);
                    end
                    line = fgetl(fid);
                    obj.lnumber = obj.lnumber+1;
                end
                fclose(fid);
                obj.sort;
            end
        end
        
        %% Append table item
        function append_table(obj,t)
            t.Properties.VariableNames = obj.itable_names;
            if isempty(obj.itable)
                obj.itable = t;
            else
                obj.itable = [obj.itable ; t];
            end
            
        end
        
        function strcell = clean_line(obj,strcell)
            
        end
        
        %% Validate lines when reading in
        function strcell = check_line(obj,strcell)
            
            % Force columns allowed
            if length(strcell) ~= 4
                disp(strcell)
                error('Invalid string file: %s line: %d\n\t4 columns must be provided, no more no less.', obj.filename,obj.lnumber);
            end
            
            for i=1:length(strcell)
                
                % Remove quotes from begin and end
                strcell{i} = strrep(strcell{i},'"','');
               
                % clean whiles spaces
                strcell{i} =  strtrim(strcell{i});
            end
            
            % Vector must be an integer
            if ~isempty(strcell{4})
                if any(~isstrprop(strcell{4},'digit'))
                    error('Invalid string file: %s line: %d\n\tVector must be an integer number', obj.filename,obj.lnumber);
                end
            end
            
            if ~isempty(strcell{4}) && isempty(strcell{3})
                    error('Invalid string file: %s line: %d\n\tVectors must be given a bus name', obj.filename,obj.lnumber);
                
            end
        end
    end
    
end

