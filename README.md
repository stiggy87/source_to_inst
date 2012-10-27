source_to_inst
==============

This is a TCL script that will take in Verilog and VHDL files and generate an instantiation template appropriately for the user to use in their design.

How to Run
==========

To run this you need to be in a TCL shell or TCL console. Most Linux OS have a TCL shell built-in and to activate it you type:

```shell
tclsh
```

Then you need to source the file. This is because there is a procedure in the file.

```tcl
source <path_to>/source_to_inst.tcl
```

To use the procedure, you need to tell it what type of source file it is Verilog or VHDL (mixed is not supported but it will come), and give it a list (including full or relative path) to the files.

Example:
```tcl
source_to_inst -filetype verilog -files ./test.v
```

It will produce this output:

```tcl
source_to_inst -filetype verilog -files ./test.v
./test.veo
```

From here you can view the test.veo file and and see the generated instantiation template.