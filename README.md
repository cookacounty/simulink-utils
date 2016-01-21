# Simulink Utilies
A Collection of useful Simulink utilities.


## Csv to Bus Creator

Create a bus from a comma seperated table. Usful when you have a block that you might not be able to change the pins on and want to orginize the signals into a collection of busses and vectors

* Limitations
   * Vectors must be the last thing
   

* Structure
  * CsvIface
    * Reads the Csv into an object
  * IfaceBus
    * Creates a simulink diagram from a CsvIface Object

## SlBlockUtil

Utilites for creation of blocks

Reads information from the model and can be used to resize
* resize - Resize a block based on a standard port pitch
* replace_block - Replace a destination block with one from another source
* create_autobus - automatically create a bus that connects to a block
* create_autoport - automatically create a port(s) that connects to a block

## Examples

To run an example, just clone the repo! The Example systems were created with Matlab R2015b

* Csv to Bus interface Creator

[example_csv_to_bus.m](examples/example_csv_to_bus.m)


![alt tag](https://raw.githubusercontent.com/cookacounty/simulink-utils/master/examples/screenshots/example_csv_to_bus.png)

* SlBlockUtil combined with csv to bus interface

[example_full.m](examples/example_full.m)


https://raw.githubusercontent.com/cookacounty/simulink-utils/master/examples/screenshots/example_full.png




## SystemPortTrace

A class for tracing the src/dst of a port(s) in a system. It is specifically designed to stop at defined block types/ block paths and report the name

## VlogWrapper

Create a simulink wrapper around a verilog block
