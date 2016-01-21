classdef SystemPortTrace < handle
    %% SystemPortTrace - A class for tracing the src/dst of a port(s)
    % in a system. It is specifically designed to stop at defined
    % block types/ block paths and report the name
    
    %#ok<*PROP>
    %#ok<*MATCH2>
    
    properties
        hBlock;
        tDir;
        stopBlocks;
        verbose = 0;
        singleStepDebug = 0;
        busNames = {}; %Names of valid busses
        busDepth = 0; % The current depth of bussing
        results; % A table of results
        missing; % A table of missing ports
        debugInstName=''; % An instance to stop at for debug
        sysRoot;
        getDt = 1; % Get the port data type. Requires model to be in compiled state
    end
    methods
        function obj = SystemPortTrace(stopBlocks)
            %% SYSTEMPORTTRACE() Create a new object for tracing system ports
            % SYSTEMPORTTRACE(stopBlocks) - specify custom stop block rules
            %
            % Format for stop blocks is a struct with cell arrays of the
            % Each type should have a corresponding parent.
            %
            % TODO: A parent of '' means any parent will cause a stop.
            %
            % For example:
            %   stopBlocks.type   = {'Constant','Inport'}
            %   stopBlocks.parent = {'mysys1','mysys1/subsystem'}
            
            if ~exist('stopBlocks','var')
                % Default Stop Blocks
                obj.stopBlocks.type   = {'Constant',                          'Inport',             'Outport'};
                obj.stopBlocks.parent = {'tb_dig_top/dig_top/dig_rtl/ids_top','tb_dig_top/dig_top', 'tb_dig_top/dig_top'};
            else
                obj.stopBlocks = stopBlocks;
            end
        end
        
        
        function traceSystem(obj,systemName)
            %% Trace all ports in a system
            
            obj.sysRoot = bdroot(systemName);
            
            %Force system to compiled state
            if obj.getDt
                feval(obj.sysRoot,[],[],[],'compile');
            end
            
            portDirs = {'Inport','Outport'};
            
            for portDir = portDirs
                portDir = portDir{:};
                switch portDir
                    case 'Inport'
                        traceDir = 'backward';
                    case 'Outport'
                        traceDir = 'forward';
                end
                
                ports = find_system(systemName,'SearchDepth',1,'FollowLinks','on','BlockType',portDir);
                if isempty(ports)
                    error('Could not find any %s in system %s',ports,systemName);
                end
                
                for port = ports'
                    port = port{:};
                    if obj.verbose; fprintf('Begin Trace on Port %s\n',port); end;
                    obj.tracePort(port,traceDir);
                end
            end
            
            if obj.getDt
                feval(obj.sysRoot,[],[],[],'term');
            end
            
        end
        
        
        function tracePort(obj,hBlock,tDir)
            %% TRACEPORT(hBlock,tDir,busNames))
            %  Trace a system's ports to their source/dst
            %
            % hBlock - The hierarctical name of port to trace
            % tDir   - The direction of the trace ('forward','backward')
            
            %% Input Validation
            
            %Check that the input is a port
            bType = get_param(hBlock,'BlockType');
            if ~any(strcmp(bType,{'Inport','Outport'}))
                error('Block %b must be an Inport or Outport', hPort)
            end
            
            
            %Determine trace direction
            if strmatch('b',lower(tDir))
                obj.tDir = 'backward';
            elseif strmatch('f',lower(tDir))
                obj.tDir = 'forward';
            end
            % Save data into class
            obj.hBlock = hBlock;
            
            %% Run trace
            obj.run();
        end
        
        function run(obj)
            %% Run the script
            
            switch obj.tDir
                case 'backward'
                    pType = 'Outport';
                case 'forward'
                    pType = 'Inport';
            end
            
            pHandles = get_param(obj.hBlock,'PortHandles');
            hPort = pHandles.(pType);
            hBus = get_param(hPort,'SignalHierarchy');
            
            obj.busNames = obj.buildBusNames(hBus);
            
            tinfo.bussedName = '';
            
            obj.traceStep(hPort,tinfo)
            obj.cleanResults();
            obj.validateResults();
            if obj.verbose; obj.dispResults; end;
        end
        
        function cleanResults(obj)
            %% Clean duplicate results
            
            obj.results = unique(obj.results);
            
        end
        
        function dispResults(obj)
            %% Display the results
            fprintf('\nTrace Results:\n\n');
            disp(obj.results);
            fprintf('\nUnmatched Ports:\n\n');
            disp(obj.missing);
        end
        
        function validateResults(obj)
            %% Check that each busName had a port
            if ~isempty(obj.busNames)
                for busName = obj.busNames'
                    busName = busName{:}; %#ok<FXSET>
                    if ~any(strmatch(busName,obj.results.OriginalBusName))
                        fprintf('Warning: Bussed Signal %s for Port %s was not found\n',...
                            busName,obj.hBlock);
                        
                        t = table({obj.hBlock},{busName}, ...
                            'VariableNames',{'PortName','BussedName',});
                        
                        if ~isempty(obj.missing)
                            obj.missing = [obj.missing; t];
                        else
                            obj.missing = t;
                        end
                        
                    end
                end
            end
        end
        
    end
end

