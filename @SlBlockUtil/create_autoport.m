function create_autoport(obj,type,forced_name)
%% CREATE_AUTOPORT(TYPE,FORCED_NAME) - automatically creates a port for each port in a system
% TYPE - the type of port to make, inport or outpor
% FORCED_NAME - the name to call the port, only valid for a single port

switch type
    case 'inport'
        pphs = obj.p.ph.Inport;
        pnames = obj.p.i.names;
        ptype = 'Inport';
    case 'outport'
        pphs = obj.p.ph.Outport;
        pnames = obj.p.o.names;
        ptype = 'Outport';
end

num_ports = length(pphs);

if exist('forced_name','var')
    if num_ports > 1
        error('A port name can only be forced for a single port');
    end
else
    forced_name = '';
end

%%
for i = 1:num_ports;
    
    pph = pphs(i);
    pp_pos = get_param(pphs(i),'Position');
    
    switch type
        case 'inport'
            port_pos(1) = pp_pos(1) - obj.s.sys.w;
        case 'outport'
            port_pos(1) = pp_pos(1) + obj.s.sys.w;
    end
    port_pos(3) = port_pos(1) + obj.s.port.w;
    
    port_pos(4) = round(pp_pos(2) + obj.s.port.h/2);
    port_pos(2) = round(pp_pos(2) - obj.s.port.h/2);
    
    if ~strcmp(forced_name,'')
        pname = forced_name;
    else
        switch type
            case 'inport'
                pname = [pnames{i} '_in'];
            case 'outport'
                pname = [pnames{i} '_out'];
        end
    end
    
    ph = add_block(['built-in/' ptype], [obj.parent '/' pname] , 'Position', port_pos);
    
    %% Route inport/outport
    nph = get_param(ph,'PortHandles');
    
    switch type
        case 'inport'
            from_p = nph.Outport(1);
            to_p = pph;
        case 'outport'
            from_p = pph;
            to_p = nph.Inport(1);
    end
    
    set(from_p, 'SignalNameFromLabel', pname)
    add_line(obj.parent,from_p,to_p,'autorouting','on'); %connect
    
end

end