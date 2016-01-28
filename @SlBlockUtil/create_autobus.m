function create_autobus(obj,type)
%% CREATE_AUTOBUS Automatically create a bus for all inport or outports

outstr = '';

switch type
    case 'inport'
        btype = 'simulink/Signal Routing/Bus Selector';
        bname = [obj.parent '/' obj.name '_bus_in'];
        pcount = obj.pnum.in;
        args = {};
        
        
        
    case 'outport'
        btype = 'simulink/Signal Routing/Bus Creator';
        bname = [obj.parent '/' obj.name '_bus_out'];
        pcount = obj.pnum.out;
        args = {'Inputs',num2str(pcount)};
    otherwise
        error('Autobus type must be inport or outport')
end


%% loop through ports to build a list of bus names
switch type
    case 'inport'
        for i = 1:length(obj.p.i.names)
            outstr = [outstr obj.p.i.names{i} ','];
        end
        outstr(end) = [];
end


%% Make the bus
bus_pos = obj.pos;
switch type
    case 'inport'
        bus_pos(1) = bus_pos(1) - obj.s.sys.w;
        bus_pos(3) = bus_pos(1) + obj.s.bus.w;
    case 'outport'
        bus_pos(1) = obj.pos(3) + obj.s.sys.w;
        bus_pos(3) = bus_pos(1) + obj.s.bus.w;
end

bh = add_block(btype ,...
    bname, ...
    'Position', bus_pos, ...
    args{:} ...
    );

switch type
    case 'inport'
        set_param(bh,'OutputSignals',outstr)
end

%% connect the bus

bph = get_param(bh,'PortHandles');

switch type
    
    case 'inport'
        to_p = obj.p.ph.Inport;
        from_p = bph.Outport;
        names = obj.p.i.names;
        numbers = obj.p.i.nums;
    case 'outport'
        to_p = bph.Inport;
        from_p = obj.p.ph.Outport;
        names = obj.p.o.names;
        numbers = obj.p.o.nums;
end

for i = 1:length(to_p)
    switch type
        case 'outport'
            set(from_p(i), 'SignalNameFromLabel', names{i})
    end
    if str2double(numbers{i}) ~= i
        error('Port numbers did not match the names! Connectivity would be wrong, aborting');
    end
    add_line(obj.parent,from_p(i),to_p(i),'autorouting','on'); %connect
end

%% Create inports/outport
switch type
    case 'inport'
        pname = [obj.name '_in'];
    case 'outport'
        pname = [obj.name '_out'];
end

slbu = SlBlockUtil(bh);
slbu.create_autoport(type,pname);


% port_pos = bus_pos;
%
% switch type
%     case 'inport'
%         pname = [obj.name '_in'];
%         ptype = 'Inport';
%         port_pos(1) = port_pos(1) - obj.s.sys.w;
%         port_pos(3) = port_pos(1) + obj.s.port.w;
%     case 'outport'
%         pname = [obj.name '_out'];
%         port_pos(1) = bus_pos(3) + obj.s.sys.w;
%         port_pos(3) = port_pos(1) + obj.s.port.w;
%         ptype = 'Outport';
% end
%
% port_pos(4) = round(mean([bus_pos(2) bus_pos(4)]) + obj.s.port.h/2);
% port_pos(2) = round(mean([bus_pos(2) bus_pos(4)]) - obj.s.port.h/2);
%
% ph = add_block(['built-in/' ptype], [obj.parent '/' pname] , 'Position', port_pos);
%
% %% Route inport/outport
% pph = get_param(ph,'PortHandles');
%
% switch type
%     case 'inport'
%         from_p = pph.Outport(1);
%         to_p = bph.Inport(1);
%     case 'outport'
%         from_p = bph.Outport(1);
%         to_p = pph.Inport(1);
% end
%
% set(from_p, 'SignalNameFromLabel', pname)
% add_line(obj.parent,from_p,to_p,'autorouting','on'); %connect

end