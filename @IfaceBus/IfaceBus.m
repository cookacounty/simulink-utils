classdef IfaceBus < handle
    %IFACEBUS Object to store information about busses
    
    properties
        parent;
        children;
        child_count = 0;
        total_count = 0;
        name;
        alias = ''; % Name in bus
        depth;
        max_depth = 0;
        is_vector = 0;
        vector_index = -1;
        verbose = 0;
    end
    
    methods
        function obj = IfaceBus(parent,bname,depth,alias)
            
            if ~exist('alias','var')
                alias = '';
            end
            
            obj.parent = parent;
            
            [prefix,suffix,len] = split_bname(bname);
            obj.name=prefix;
            obj.depth = depth;
            
            if len ~= 1
                cname =suffix;
                obj.add_child(cname,alias);
                obj.increase_depth(obj.depth+1);
            else
                obj.increase_total;
                
                obj.alias = alias;
                
                if isavec(prefix)
                    obj.parent.is_vector = 1;
                    [vprefix,vindex] = split_vname(prefix);
                    if vindex ~= obj.parent.vector_index+1;
                        error('Vectors must increase sequentially starting from 0 %s',prefix)
                    else
                        obj.parent.vector_index=obj.parent.vector_index+1;
                    end
                    obj.is_vector = 1;
                    obj.name = vprefix;
                    obj.vector_index = vindex;
                end
            end
            
        end
        
        function add_child(obj,bname,alias) %alias is optional
            
            if ~exist('alias','var')
                alias = '';
            end
            
            [prefix,suffix,~] = split_bname(bname);
            
            if isempty(obj.children)
                new_child = IfaceBus(obj,bname,obj.depth+1,alias);
                obj.children =  [ new_child ];
            else
                cfound = 0;
                for c = 1:length(obj.children)
                    child = obj.children(c);
                    if strcmp(child.name, prefix)
                        cfound = 1;
                        child.add_child(suffix,alias);
                    end
                end
                if ~cfound
                    new_child = IfaceBus(obj,bname,obj.depth+1,alias);
                    obj.children = [ obj.children new_child ];
                end
            end
            
            obj.child_count = length(obj.children);
        end
        
        function print(obj)
            if obj.depth == 0
                fprintf('Interface Bus Summary\n==================\n')
                fprintf('\tTotal count: %d\n', obj.total_count);
            end
            tabs = repmat('\t',1,obj.depth);
            
            if obj.child_count > 0
                summary = [' elem=' num2str(obj.child_count) ' '];
            elseif ~strcmp(obj.alias,'')
                summary = ['==' obj.alias ' '];
            else
                summary = '';
            end
            
            if obj.is_vector
                fprintf([tabs 'vec %d:%s%s\n'],obj.vector_index,obj.name,summary)
            else
                fprintf([tabs '%s%s\n'],obj.name, summary)
            end
            for i=1:obj.child_count
                print(obj.children(i));
            end
        end
    end
    methods (Access = 'private')
        function increase_depth(obj,depth)
            if isabus(obj.parent)
                obj.parent.increase_depth(depth);
            else
                if obj.max_depth < depth;
                    obj.max_depth = depth;
                end
            end
        end
        function increase_total(obj)
            obj.total_count = obj.total_count+1;
            if isabus(obj.parent)
                obj.parent.increase_total;
            end
        end
    end
end

function [prefix,suffix,len] = split_bname(bname)
bsplit = strsplit(bname,'.');
prefix = bsplit{1};
len = length(bsplit);

if len > 1
    suffix = strjoin(bsplit(2:end),'.');
else
    suffix = 0;
end

% Debug
%tabs = repmat('\t',1,len);
%fprintf([tabs 'Prefix %s Sufix %s Len %d\n'], prefix, suffix, len);

end

% Split a vector
function [prefix,index] = split_vname(vname)
vsplit = strsplit(vname,':');
prefix = vsplit{1};
index = str2double(vsplit{2});
end

function t_f = isabus(obj)
t_f = isa(obj,'IfaceBus');
end

function t_f = isavec(str)
t_f = 0;
sstr = strsplit(str,':');
if length(sstr) == 2
    t_f = 1;
end
end