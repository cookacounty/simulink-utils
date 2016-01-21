%% TRACESTEP(pHandle,bussedName)
% Runs a single trace step
% pHandle is a handle for a Port
% tinfo is a sturct that contains:
%   bussedName - a string that keeps track of the name in a bus
%   vectorName - used to track the name of signals in vectors
function traceStep(obj,pHandle,tinfo)

pHandleParent = get_param(pHandle,'Parent');
pHandleName   = get_param(pHandle,'Name');
pHandleType = get_param(pHandle,'Type');
pHandlePortType = get_param(pHandle,'PortType');
pHandleParent(pHandleParent==10) = ' '; % Remove carriage returns
if obj.verbose; fprintf('Tracing %s %s %s %s\n', ...
        pHandleParent, pHandleName, pHandleType, pHandlePortType); end

%% Get the driver/sink port from the port's line
lineH = get_param(pHandle,'Line');
try
    switch obj.tDir
        case 'forward'
            tracePort.H = get_param(lineH,'DstPortHandle');
        case 'backward'
            tracePort.H = get_param(lineH,'SrcPortHandle');
    end
catch
    ePort = get(pHandle);
    error('Trace failed for port %s parent %s\n',ePort.Name,ePort.parent);
end

if obj.verbose; fprintf('\tTracing line %s %s %s\n', ...
        get_param(lineH,'Parent'),get_param(lineH,'Name'),obj.tDir); end

for h = tracePort.H'
    
    newTracePort.H = h;
    traceHandle(obj,newTracePort,tinfo,lineH)
    
end

end

%%
function traceHandle(obj,tracePort,tinfo,lineH) %#ok<INUSD>

tDir = obj.tDir;
stopBlocks = obj.stopBlocks;

%% Get the parent of the traced driver/sink
tracePort.Num = get_param(tracePort.H,'PortNumber');
tracePort.Type = get_param(tracePort.H,'PortType');

% The parent of the port ( a block
tracePortParent.H     = get_param(tracePort.H,'Parent');
tracePortParent.Type  = get_param(tracePortParent.H,'BlockType');
tracePortParent.Name     = get_param(tracePortParent.H,'Name');
tracePortParent.DispName = regexprep(tracePortParent.Name,'\s','');
tracePortParent.Ports = get_param(tracePortParent.H,'PortHandles');

% The parent of the parent of the port (a subsystem or the top level diagram)
tracePortParentSystem.H = get_param(tracePortParent.H,'Parent');

%% Debugging
if obj.singleStepDebug
    hilite_system(tracePortParent.H)
    fprintf('Single step mode. keyboard statement Press F5 to advance\n')
    %keyboard
end

if any(strcmp(obj.debugInstName,tracePortParent.H))
    fprintf('Debug inst found!\n\t%s\n',obj.debugInstName)
    keyboard
end

%% Determine if the block is a stop block
%  if it is, add it to the results table
isStopBlock = false;
if any(strcmp(tracePortParent.Type,stopBlocks.type))
    if any(strcmp(tracePortParentSystem.H,stopBlocks.parent))
        [isValidBus, orignalBusName] = match_bus_name(obj,tinfo.bussedName);
        if isempty(obj.busNames) || isValidBus;
            isStopBlock = true;
            if obj.verbose
                fprintf('**** Found stop block: %s\n\tBlock Path: %s\n\tBussedName: %s\n', ...
                    tracePortParent.Name,tracePortParentSystem.H,tinfo.bussedName);
            end
            hBlock.Name = get_param(obj.hBlock,'Name');
            dtStr = getPortDataType(tracePortParent.H,tDir);
            
            if isVector(tinfo)
                bussedName = tinfo.vectorName;
            else
                bussedName = tinfo.bussedName;
            end
            
            t = table({hBlock.Name},{tracePortParent.Name},{dtStr},{tracePortParentSystem.H},{bussedName},{orignalBusName},{tracePortParent.H}, ...
                'VariableNames',{'PortName','ObjectName','DataType','ParentName','BusName','OriginalBusName','Handle'});
            
            %disp(get_param(tracePortParent.H,'OutputDataTypeStr'));
            
            if ~isempty(obj.results)
                obj.results = [obj.results; t];
            else
                obj.results = t;
            end
        end
    end
end


if ~isStopBlock
    %% Determine the next port object to trace
    if obj.verbose; fprintf('\tPort Parent Block Type: %s\n', tracePortParent.Type); end
    switch tracePortParent.Type
        case {'Inport','Outport'}
            %% Search up into a subsystem
            if obj.verbose; fprintf('\tUp %s\n',tracePortParent.H); end
            pType = tracePortParent.Type;
            tracePortParent.Num = get_param(tracePortParent.H,'Port');
            pNum = tracePortParent.Num;
            
            %The handle of the port in the parent subsystem
            tracePortParentSystem.Ports = get_param(tracePortParentSystem.H,'PortHandles');
            ports = tracePortParentSystem.Ports.(pType);
            if isempty(ports)
                error('Something bad happened');
            end
            
            if ischar(pNum)
                pNum = str2double(pNum);
            end
            nextTracePort = ports(pNum);
            
            obj.traceStep(nextTracePort,tinfo)
            
            
        case {'SubSystem'}
            %% Search down into a subsystem
            
            switch tracePort.Type
                case 'outport'
                    bType = 'Outport';
                    pType = 'Inport';
                case 'inport'
                    bType = 'Inport';
                    pType = 'Outport';
            end
            
            if obj.verbose; fprintf('\tDn %s\n',tracePortParent.H); end
            
            nextTraceBlock = find_system(tracePortParent.H,'SearchDepth',1,'FollowLinks','on','BlockType',bType,'Port',num2str(tracePort.Num));
            if isempty(nextTraceBlock)
                error('Something is messed up')
            end
            nextTraceBlock = nextTraceBlock{1};
            
            bPorts = get_param(nextTraceBlock,'PortHandles');
            nextTracePort = bPorts.(pType);
            
            % Run the next step in the trace
            obj.traceStep(nextTracePort,tinfo);
            
        case {'BusCreator','BusSelector'}
            
            pType = get_pType(tDir);
            
            busClass = [tracePortParent.Type '_' tDir];
            
            switch busClass
                case {'BusCreator_forward','BusSelector_backward'}
                    if obj.verbose; fprintf('\t\tBus %s depth %d\n',tracePortParent.DispName,obj.busDepth); end
                    new_tinfo = copy_tinfo(tinfo);
                    new_tinfo.bussedName = trimBusName(tinfo.bussedName);
                    nextTracePort = tracePortParent.Ports.(pType);
                    obj.traceStep(nextTracePort,new_tinfo);
                case {'BusCreator_backward','BusSelector_forward'}
                    ports = tracePortParent.Ports.(pType);
                    if obj.verbose;
                        fprintf('\t\tBus %s depth %d\n',tracePortParent.DispName,obj.busDepth);
                        for p=ports; pName = get_param(p,'Name'); fprintf('\t\t\t%s\n',pName); end
                    end
                    if strcmp(busClass,'BusSelector_forward')
                        signalNames = strsplit(strrep(get_param(tracePortParent.H,'OutputSignals'),'.','/'),',');
                    end
                    
                    pindex = 1;
                    for p = ports
                        if strcmp(busClass,'BusSelector_forward')
                            signalName = signalNames{pindex};
                        else
                            signalName = get_param(p,'Name');
                        end
                        
                        new_tinfo = copy_tinfo(tinfo);
                        new_tinfo.bussedName = concatBusName(tinfo.bussedName,signalName);
                        if isVector(tinfo)
                            new_tinfo.vectorName =  concatBusName(tinfo.vectorName,signalName);
                        end
                        nextTracePort = p;
                        obj.traceStep(nextTracePort,new_tinfo);
                        pindex = pindex+1;
                    end
                    if obj.verbose; fprintf('\t\tDone bus %s\n',tracePortParent.DispName); end
                otherwise
                    error('Something is messed up');
            end
        case {'SignalSpecification','DataTypeConversion'}
            %% Routing blocks
            pType = get_pType(tDir);
            nextTracePort = tracePortParent.Ports.(pType);
            obj.traceStep(nextTracePort,tinfo);
        case {'From'}
            pType = get_pType(tDir);
            tag = get_param(tracePortParent.H,'GotoTag');
            gotoblk = find_system(tracePortParentSystem.H,'FollowLinks','On','BlockType','Goto','GotoTag',tag);
            bPorts = get_param(gotoblk{1},'PortHandles');
            nextTracePort = bPorts.(pType);
            
            % Run the next step in the trace
            obj.traceStep(nextTracePort,tinfo);
        case {'Goto'}
            error('Currently Goto Blocks are not supported for a forward trace');
        case {'Concatenate'}
            if strcmp(tDir, 'forward')
                error('Vector Concat blocks are only currently only supported for a backwards trace');
                %This is pretty easy to implement, I'm just lazy
            else
                pType = get_pType(tDir);
                bPorts = get_param(tracePortParent.H,'PortHandles');
                nextTracePorts = bPorts.(pType);
                
                numPorts = length(nextTracePorts);
                if obj.verbose;
                    fprintf('\t\tVector Concat %s ports %d\n',tracePortParent.DispName,numPorts);
                end
                for p = 1:numPorts
                    nextTracePort=nextTracePorts(p);
                    
                    new_tinfo = copy_tinfo(tinfo);
                    if isVector(tinfo)
                        new_tinfo.vectorName = [tinfo.vectorName '_' num2str(p-1)];
                    else
                        new_tinfo.vectorName = [tinfo.bussedName '_' num2str(p-1)];
                        new_tinfo.isVector = 1;
                    end
                    
                    obj.traceStep(nextTracePort,new_tinfo);
                end
            end
            
        otherwise
            %% Do nothing, object is not important
            if obj.verbose; fprintf('Done\n'); end
            
    end
end

if obj.singleStepDebug
    hilite_system(tracePortParent.H,'none')
end

end

%% Concat two bus names
function name = concatBusName(old, new)
delimeter = '/';
new = regexprep(new,'[<>]','');
name = [old delimeter new];
end

%% Trim the trailing /* off a bus name
function name = trimBusName(name)
name = regexprep(name,'/[\w<>]*$','');
end


%% Get the port type based on the trace direction
% For standard pass-through blocks
function pType = get_pType(tDir)
switch tDir
    case 'backward'
        pType = 'Inport';
    case 'forward'
        pType = 'Outport';
end
end

%% Check for a matching bus name
%There is probably cases where this will report the wrong thing if you
%have more than one bus with the same signal names
function [t_f,orignalBusName] = match_bus_name(obj,bussedName)

orignalBusName = '';
t_f = any(strcmp(bussedName,obj.busNames));

if ~t_f && strcmp(obj.tDir,'forward')
    %% If the depth is not 0, the bus is not coming from the block
    finished = 0;
    newName=bussedName;
    while ~finished
        newName = regexprep(newName,'^/\w+','');
        t_f = any(strcmp(newName,obj.busNames));
        if t_f
            orignalBusName = obj.busNames{strcmp(newName,obj.busNames)};
        end
        if t_f || strcmp(newName,'')
            finished = 1;
        end
    end
elseif t_f
    orignalBusName = obj.busNames{strcmp(bussedName,obj.busNames)};
end

end

%% Get Datatype for an matched stopBlock
function dataTypeStr = getPortDataType(block,tDir)

dt = get_param(block, 'CompiledPortDataTypes');

if ~isempty(dt)
    
    if strcmp(tDir,'forward')
        dataTypeStr = dt.Inport;
    else
        dataTypeStr = dt.Outport;
    end
    
    if length(dataTypeStr) > 1
        error('Found a data type str with length > 1');
    else
        dataTypeStr = dataTypeStr{1};
    end
else
    dataTypeStr = '';
end

end


%% Untilty funciton that determines if the signal is a vector
function t_f = isVector(tinfo)
if isfield(tinfo,'isVector')
    t_f = 1;
else
    t_f = 0;
end
end

%% Utilty function to copy tinfo
function new_tinfo = copy_tinfo(tinfo)
new_tinfo = tinfo;
end