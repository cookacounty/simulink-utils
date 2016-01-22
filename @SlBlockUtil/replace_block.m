function replace_block(obj,src_sys)
%% REPLACE_BLOCK(SRC_SYS) Replace and existing block with a block from another source
% SRC_SYS - The name of the subsystem to copy from

delete_block(obj.sys);
open_system(obj.parent); % once the system is deleted, the diagram is closed, open the parent
add_block(src_sys, obj.sys, 'CopyOption', 'duplicate', 'Position',obj.pos)


end


function check_port_names(obj)
%% CHECK_PORT_NAMES - check that the port names match before replacing


end