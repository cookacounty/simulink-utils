function mdlName = generate_slx(obj)



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

for d = 1:d_points
    y = 0;
    for h = 1:h_points
        s.grid(d,h,:) = [x y];
        y = y+s.space_tb;
    end
    x = x-s.space_lr;
end

lvl.max = obj.max_depth+1;
lvl.d = 1;
lvl.h = ones(1,lvl.max);

%% Create a subsystem
sysName = [mdlName '/iface_bus' ];
add_block('built-in/Subsystem',sysName, 'Position', [0 0 100 s.port_pitch*h_points]);


%% Generate the busses

pp = make_initial_port(sysName,s);

[~,~] = make_lvl(sysName,obj,s,lvl,pp);

end

%% Recursive level step
function [lvl,bh] = make_lvl(mdlName,obj,s,lvl, pp)

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
    
    % Create a buscreator
    if ~obj.is_vector
        bh = make_buscreator(mdlName,pos,obj);
        if obj.verbose;disp(['Created Bus ' obj.name]); end
        % Create a vector creator
    else
        bh = make_vectorconcat(mdlName,pos,obj);
        if obj.verbose;disp(['Created Vector ' obj.name]); end
    end
    
    % Create each child
    for c = 1:obj.child_count
        ph = get_param(bh,'PortHandles');
        new_pp = ph.Inport(c);
        lvl.d = lvl.d + 1;
        [lvl,~] = make_lvl(mdlName,obj.children(c),s,lvl,new_pp);
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
    bh = make_io('Inport',ioname,ppos);
    lvl = update_all_lvls(lvl);
    if obj.verbose; disp('\tUpdated all H'); disp(lvl.h); end
end

if pp
    ph = get_param(bh,'PortHandles');
    cp = ph.Outport;
    
    if d == 1 % The final label is out
        set(cp, 'SignalNameFromLabel', 'out')
    else
    if ~strcmp(obj.alias,'')
        set(cp, 'SignalNameFromLabel', obj.alias)
    else
        set(cp, 'SignalNameFromLabel', obj.name)
    end
    end
    
    add_line(mdlName,cp,pp,'autorouting','on'); %connect
end

end

%% Insert a bus creator
function h = make_buscreator(mdlName,pos,obj)
name = generate_recursive_name('bus_creator',obj);
h = add_block('simulink/Signal Routing/Bus Creator',...
    [mdlName '/' name], ...
    'Inputs',num2str(obj.child_count), ...
    'Position', pos ...
    );
end

%% Insert a vector concat
function h = make_vectorconcat(mdlName,pos,obj)
name = generate_recursive_name('vector_concat',obj);
h = add_block('simulink/Signal Routing/Vector Concatenate',...
    [mdlName '/' name], ...
    'NumInputs',num2str(obj.child_count), ...
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
function pp = make_initial_port(mdlName,s)

x1 = s.grid(1,1,1)+s.space_lr;
y1 = s.grid(1,1,2)+s.space_tb;
x2 = x1+s.port.w;
y2 = y1+s.port.h;
ppos = [x1 y1 x2 y2];
bh = make_io('Outport',[mdlName '/out'],ppos);
ph = get_param(bh,'PortHandles');
pp = ph.Inport;
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

name = [ name '_' obj.name ];

if isa(obj.parent,'IfaceBus')
   name = generate_recursive_name(name,obj.parent); 
end

end
