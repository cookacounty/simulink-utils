%% Gets all of the names of a bus in a Port
function nameCell = buildBusNames(obj,hBus,name)

delimeter = '/';

if ~exist('name','var')
    name = '';
else
    name = [name delimeter];
end

signalName = [name hBus.SignalName];

if ~isempty(hBus.Children)
    numChildren = length(hBus.Children);
    nameCell = cell(0,0);
    for child = 1:numChildren
        childNames = obj.buildBusNames(hBus.Children(child));
        if iscell(childNames)
            for subChild = 1:length(childNames)
                subName = childNames{subChild};
                nameCell{end+1,1} = [signalName delimeter subName];
            end
        else
            nameCell{end+1,1} = [signalName delimeter childNames];
        end
    end
else
    nameCell = signalName;
end


end