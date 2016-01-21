function [ output_args ] = autoconnect_ports(obj,dir,blk,auto_reorder)
%% AUTOCONNECT_PORTS(blk,dir) autoconenct ports between two blocks using the port names
% DIR - direction (inport,outport)
%   inport will connect the outports from "blk" to the inports of the
%   current object
%   outport will connect the outports of the curren object to the inports
%   of "blk"
% BLK
%   The name of the subsystem to connect to
% AUTO_REORDER
%   (0/1) Automatically reorder the ports in the current object to
%   match the order in "blk"

if auto_reorder
    strict = 1; % Force port names to all match
else
    strict = 0;
end

% Create an object for the second block
blk_slbu = SlBlockUtil(blk);

switch dir
    case 'inport'
        objpinfo = obj.p.i;
        blkpinfo = blk_slbu.p.o;
    case 'outport'
        objpinfo = obj.p.o;
        blkpinfo = blk_slbu.p.i;
    otherwise
        error('Dir must be inport or outport');
end


if ~strcmp(obj.parent,blk_slbu.parent)
    error('Source Parent %s must match dst Parent %s', obj.parent, slbu.parent);
end

objpcount = length(objpinfo.nums);
blkpcount = length(blkpinfo.nums);

if strict && objpcount ~= blkpcount
    error('Number of ports must match for auto_reorder\nCheck that system %s and system %s have the same number of ports',obj.sys, blk_slbu.sys);
end

for i = 1:objpcount
    if strict
        pname = blkpinfo.names{i};
    else
        pname = objpinfo.names{i};
    end
    
    objpi = obj.get_port_by_name(pname);
    blkpi = blk_slbu.get_port_by_name(pname);
    
    if ~isempty(objpi) && ~isempty(blkpi)
        if auto_reorder
            set_param([obj.sys '/' pname],'Port',blkpi.num);
        end
        
        switch dir
            case 'inport'
                sph = blkpi.ph;
                dph = objpi.ph;
            case 'outport'
                sph = objpi.ph;
                dph = blkpi.ph;
        end
        % Only connect if not connected
        if get_param(dph,'Line') == -1
            add_line(obj.parent,sph,dph,'autorouting','on'); %connect
        end
        
    elseif strict
        error('Port names must match for auto_reorder\nCheck that system %s and system %s have the same port named %s',obj.sys, blk_slbu.sys, pname);
    end
end

end

