bdclose all

% Setup stuff, add paths
setup_examples;

% Create the csviface object from a file
iface = CsvIface('example_csv_iface.csv');

% Generate a block diagram
iface_bus = iface.parse_busses;

% Generate the slx and return the block handle
h = iface_bus.generate_slx('outport');
h = iface_bus.generate_slx('inport');