%% This example will demonstrate all off the utility toolbox functionality

bdclose all

% Setup stuff, add paths
setup_examples;

% Copy the original example
copyfile('system_original.slx','system_modified.slx');
sys  = 'system_modified';

%% Input interface

% Create the csviface object from a file
iface = CsvIface('example_csv_iface_in.csv');

% Generate a block diagram
iface_bus = iface.parse_busses;

% Generate the slx and return the block handle
h = iface_bus.generate_slx('inport');

% Replace the existing interface
slbu = SlBlockUtil([sys '/top/iface_to']);
slbu.replace_block([h '/iface_bus'])

% Close the temp model
bdclose(h)

% Connect the ports
slbu = SlBlockUtil([sys '/top/static_IP']);
slbu.autoconnect_ports('inport',[sys '/top/iface_to'],1)

%% Output interface

% Create the csviface object from a file
iface = CsvIface('example_csv_iface_out.csv');

% Generate a block diagram
iface_bus = iface.parse_busses;

% Generate the slx and return the block handle
h = iface_bus.generate_slx('outport');

% Replace the existing interface
slbu = SlBlockUtil([sys '/top/iface_from']);
slbu.replace_block([h '/iface_bus'])

% Close the temp model
bdclose(h)

% Connect the ports
slbu = SlBlockUtil([sys '/top/static_IP']);
slbu.autoconnect_ports('outport',[sys '/top/iface_from'],1);

