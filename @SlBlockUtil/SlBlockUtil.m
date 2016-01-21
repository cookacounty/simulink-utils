classdef SlBlockUtil < handle
    % SlBlockUtil Simulink block utility functions
    
    properties
        mdl = ''; % The subsystems model
        sys = ''; % The subsystem name
        name = ''; % The subsystem name (without hierarchy)
        parent = '';
        pos = []; % The location of the block [left top right bottom]
        pnum; % Struct for number of ports
        s; % Struct for sizing
        p; % Port handles
    end
    
    methods
        
        function obj = SlBlockUtil(sys_name)
            %% SLBLOCKUTIL(sys_name)
            % sys_name - the name of the subsystem
            
            obj.sys = sys_name;
            obj.get_mdl;
            obj.load_sys;
            obj.get_true_path;
            obj.unlock;
            
            obj.parent = get_param(obj.sys,'Parent');
            obj.name = get_param(obj.sys,'Name');
            obj.get_pos;
            obj.get_ports;
            obj.get_max_num_ports;
            
            obj.s.port.pitch = 20;
            obj.s.sys.w = 200;
            obj.s.bus.w = 20;
            
            obj.s.port.h = 14;
            obj.s.port.w = 30;
            
        end
        
        function get_mdl(obj)
            obj.mdl =  strtok(obj.sys,'/');
        end
        
        function unlock(obj)
            try
                set_param(obj.mdl,'Lock','off') % Unlock libraries
            catch
            end
        end
        
        function load_sys(obj)
            load_system(obj.mdl);
            open_system(obj.mdl);
        end
        
        function get_pos(obj)
            obj.pos =  get_param(obj.sys,'Position');
        end
        
        function set_pos(obj)
            set_param(obj.sys,'Position',obj.pos);
        end
        
        function get_ports(obj)
            %%
            ihandles=find_system(obj.sys,'FindAll','On','SearchDepth',1,'BlockType','Inport');
            ohandles=find_system(obj.sys,'FindAll','On','SearchDepth',1,'BlockType','Outport');
            
            for type = {'i' 'o'}
                type = type{1};
                switch type
                    case 'i'
                        handles = ihandles;
                    case 'o'
                        handles = ohandles;
                end
                obj.p.(type).names = get(handles,'Name');
                obj.p.(type).nums  = get(handles,'Port');
                obj.p.(type).type  = get(handles,'BlockType');
                
                %Fix stupid matlab crap to make results always a cell
                if length(handles) == 1
                    obj.p.(type).names = {obj.p.(type).names};
                    obj.p.(type).nums = {obj.p.(type).nums};
                    obj.p.(type).type = {obj.p.(type).type};
                end
            end
            
            obj.p.ph   = get_param(obj.sys,'PortHandles');
        end
        
        function determine_pos(obj)
            %% Position [left top right bottom]
            obj.pos = [obj.pos(1) obj.pos(2) obj.pos(1)+obj.s.sys.w obj.pos(2)+obj.s.port.pitch*obj.pnum.max];
        end
        
        function get_max_num_ports(obj)
            %% Determine the number max number of ports
            
            ph = get_param(obj.sys,'PortHandles');
            obj.pnum.in = length(ph.Inport);
            obj.pnum.out = length(ph.Outport);
            obj.pnum.max = max([obj.pnum.in obj.pnum.out]);
        end
        
        function get_true_path(obj)
            %% Get the true path of the object, will seek through library references
            
            % Object is a resolved library link
            if ~isempty(find_system(obj.sys,'LinkStatus','resolved'))
                rb = get_param(obj.sys,'ReferenceBlock');
                obj.sys = rb;
                obj.get_mdl;
                obj.load_sys;
                obj.get_true_path;
            end
        end
        
        function pinfo = get_port_by_name(obj,pname)
            %% Get info on a port by its name
            pfound = 0;
            for type = {'i' 'o'}
                type = type{1};
                for i = 1:length(obj.p.(type).names)
                    if strcmp(obj.p.(type).names{i},pname)
                        pfound = 1;
                        pinfo.num = obj.p.(type).nums{i};
                        pinfo.type = obj.p.(type).nums{i};
                        switch type
                            case 'i'
                                pinfo.ph = obj.p.ph.Inport(i);
                            case 'o'
                                pinfo.ph = obj.p.ph.Outport(i);
                        end
                        
                    end
                end
            end
            if ~pfound
               pinfo = []; 
            end
        end
        
        
    end
    
end




