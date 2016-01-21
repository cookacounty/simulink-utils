%% Detemine the buss struction
function top_bus = parse_busses(obj)

% Busses
% btable = obj.itable(~strcmp(obj.itable.Bus,''),:);

% Vector only
% vtable = obj.itable(strcmp(obj.itable.Bus,'') & ~strcmp(obj.itable.Vec,''),:);

%disp(btable)

%% Determine the max bus depth
top_bus = IfaceBus(0,'top',0);
total_count = height(obj.itable);

for r = 1:height(obj.itable)
    
    trow = obj.itable(r,:);
        
    % ; delimites multiple busses
    multibus = strsplit(trow.Bus{:},';');
    if length(multibus) > 1
        for i = 1:length(multibus)
           bname = multibus{i};
           new_trow = trow;
           new_trow.Bus{1} = bname;
           top_bus = parse_row(new_trow,top_bus);
           total_count = total_count + 1;
           %top_bus.total_count = top_bus.total_count + 1;
        end
    else
        top_bus = parse_row(trow,top_bus);
    end
        
end

if total_count ~= top_bus.total_count
   %error('Total number of elements did not match expected'); 
end


end

function top_bus = parse_row(trow,top_bus)
sname  = trow.Name{:};
alias = trow.Alias{:};
bname = trow.Bus{:};
vname = trow.Vec{:};

if strcmp(bname,'')
    bstr = ['misc.' sname];
else
    bstr = [bname '.' sname];
end

% Vector delimited by ":"
if ~strcmp(vname,'')
    bstr = [bstr ':' vname];
end

%Alias delimited by "="
if ~strcmp(alias,'')
    top_bus.add_child(bstr,alias)
else
    top_bus.add_child(bstr)
end
end