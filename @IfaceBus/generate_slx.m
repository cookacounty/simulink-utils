function mdlName = generate_slx(obj,dir)
%% MDLNAME = GENERATE_SLX Create a simulink model from a bus and return the handle


switch dir
    case 'inport'
    case 'outport'
    otherwise
        error('Generate slx argument must be ''inport'' or ''outport''');
end



%% Create a new model
ns = new_system; open_system(ns);
mdlName = get_param(ns, 'Name');
hdlsetup(mdlName);



%% Specs for spacings
s.origin = [0 0 0 0];

s.space_tb =  50;
s.space_lr = 100;

s.port.h = 14;
s.port.w = 30;

s.bus.h = 30;
s.bus.w = 10;

s.port_pitch = 10;


%% Create a grid of x,y points

d_points = obj.max_depth+1;
h_points = obj.total_count;

x = 0;

switch dir
    case 'inport'
        xsign = 1;
    case 'outport'
        xsign = -1;
end

for d = 1:d_points
    y = 0;
    for h = 1:h_points
        s.grid(d,h,:) = [x y];
        y = y+s.space_tb;
    end
    x = x+xsign*s.space_lr;
end

lvl.max = obj.max_depth+1;
lvl.d = 1;
lvl.h = ones(1,lvl.max);

%% Create a subsystem
sysName = [mdlName '/iface_bus' ];
add_block('built-in/Subsystem',sysName, 'Position', [0 0 100 s.port_pitch*h_points]);


%% Generate the busses

pp = make_initial_port(sysName,dir,s);

[~,~] = make_lvl(sysName,dir,obj,s,lvl,pp);

end

%% Recursive level step
function [lvl,bh] = make_lvl(mdlName,dir,obj,s,lvl, pp)

d = lvl.d;
h = lvl.h(d);
if obj.verbose
    fprintf('NEW LEVEL=========\n');
    fprintf('d %d h %d\n',d,h);
    disp(lvl.h)
end
lvl = update_lvl(lvl,obj.total_count);
if obj.verbose; disp('\tUpdated H');disp(lvl.h); end

% Position [left top right bottom]



if obj.child_count > 0
    
    x1 = s.grid(d,h,1);
    y1 = s.grid(d,h,2);
    x2 = x1+s.bus.w;
    if obj.child_count > 1
        y2 = s.grid(d,h+obj.child_count-1,2);
    else
        y2 = y1 + s.bus.h;
    end
    pos = [ x1 y1 x2 y2 ];
    
    if ~obj.is_vector % Create a buscreator
        bh = make_bus(mdlName,dir,pos,obj);
        if obj.verbose;disp(['Created Bus ' obj.name]); end
        
    else % Create a vector creator
        bh = make_vector(mdlName,dir,pos,obj);
        if obj.verbose;disp(['Created Vector ' obj.name]); end
    end
    
    % Create each child
    for c = 1:obj.child_count
        ph = get_param(bh,'PortHandles');
        switch dir
            case'outport'
                new_pp = ph.Inport(c);
            case 'inport'
                new_pp = ph.Outport(c);
        end
        lvl.d = lvl.d + 1;
        [lvl,~] = make_lvl(mdlName,dir,obj.children(c),s,lvl,new_pp);
        lvl.d = lvl.d - 1;
    end
    
else
    
    x1 = s.grid(end,h,1);
    y1 = s.grid(end,h,2);
    x2 = x1+s.port.w;
    y2 = y1+s.port.h;
    ppos = [ x1 y1 x2 y2];
    
    if obj.verbose; disp(['Created IO ' obj.name]); end;
    ioname = [mdlName '/' obj.name];
    switch dir
        case 'inport'
            ptype = 'Outport';
        case 'outport'
            ptype = 'Inport';
    end
    bh = make_io(ptype,ioname,ppos);
    lvl = update_all_lvls(lvl);
    if obj.verbose; disp('\tUpdated all H'); disp(lvl.h); end
end

if pp
    ph = get_param(bh,'PortHandles');
    
    switch dir
        case 'inport'
            to_port = ph.Inport;
            from_port = pp;
        case 'outport'
            to_port = pp;
            from_port = ph.Outport;
    end
    
    if d == 1 % The final label is out
        switch dir
            case 'inport'
                wire_label = 'in';
            case 'outport'
                wire_label = 'out';
        end
        set(from_port, 'SignalNameFromLabel', 'out')
    else
        if ~strcmp(obj.alias,'')
            wire_label = obj.alias;
        else
            wire_label = obj.name;
        end
    end
    try
        set(from_port, 'SignalNameFromLabel', wire_label); %This will fail on a bus selector
    catch
    end
    add_line(mdlName,from_port,to_port,'autorouting','on'); %connect
end

end

%% Insert a bus creator
function h = make_bus(mdlName,dir,pos,obj)
name = generate_recursive_name('bus',obj);

switch dir
    case 'inport'
        btype = 'simulink/Signal Routing/Bus Selector';
        args = {'OutputSignals', generate_bus_extractor_names(obj)};
    case 'outport'
        btype = 'simulink/Signal Routing/Bus Creator';
        args = {'Inputs',num2str(obj.child_count)};
end
h = add_block(btype,...
    [mdlName '/' name], ...
    args{:}, ...
    'Position', pos ...
    );
end

%% Insert a vector concat
function h = make_vector(mdlName,dir,pos,obj)
name = generate_recursive_name('vector',obj);
switch dir
    case 'inport'
        vtype = 'simulink/Signal Routing/Demux';
        args = {'Outputs',num2str(obj.child_count)};
    case 'outport'
        vtype = 'simulink/Signal Routing/Vector Concatenate';
        args = {'NumInputs',num2str(obj.child_count)};
end

h = add_block(vtype,...
    [mdlName '/' name], ...
    args{:}, ...
    'Position', pos ...
    );
end

%% Insert an inport or outport
function h = make_io(type,name,pos)

if ~strcmp(type,'Inport') && ~strcmp(type,'Outport')
    error('make_io must be Inport or Outport type')
end

%% If a port already exists, just return it's handle
h = getSimulinkBlockHandle(name);
if h == -1
    h = add_block(['built-in/' type], name , 'Position', pos);
end

end

%% Make an initial port
function pp = make_initial_port(mdlName,dir,s)

switch dir
    case 'inport'
        sign = -1;
        ptype = 'Inport';
        phtype = 'Outport';
        pname = 'in';
    case 'outport'
        sign = 1;
        ptype = 'Outport';
        phtype = 'Inport';
        pname = 'out';
end

x1 = s.grid(1,1,1)+sign*s.space_lr;
y1 = s.grid(1,1,2)+s.space_tb;
x2 = x1+s.port.w;
y2 = y1+s.port.h;
ppos = [x1 y1 x2 y2];
bh = make_io(ptype,[mdlName '/' pname],ppos);
ph = get_param(bh,'PortHandles');
pp = ph.(phtype);
end

%% Update the current level index
function lvl = update_lvl(lvl,cnt)
lvl.h(lvl.d) = cnt+lvl.h(lvl.d);
end


%% Update all level indexs below the current level
function lvl = update_all_lvls(lvl)
for d = lvl.d+1:lvl.max
    lvl.h(d) = lvl.h(lvl.d);
end
end

%% Generate a unique name for bus/vectors
function name = generate_recursive_name(name,obj)

if ~strcmp(name, '')
    name = [ name '_' obj.name ];
else
    name = obj.name;
end

if isa(obj.parent,'IfaceBus')
    name = generate_recursive_name(name,obj.parent);
end

end

%% Generate signals for bus extractor
function bnames = generate_bus_extractor_names(obj)

bnames = '';

% Create each child
for c = 1:obj.child_count
    child = obj.children(c);
    
    if ~strcmp(child.alias,'')
        cname = child.alias;
    else
        cname = child.name;
    end
    
    bnames = [bnames cname ',']; %#ok<AGROW>
end
bnames(end) = []; % remove the last ,
end
