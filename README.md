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

The test.v contains:
```verilog
module test_1(port_1, port_2, port_3, port_4);
...
endmodule
```

It will produce this .veo output:
```verilog
///////////////////////////////////////////////////
// This instantiation template was created from source_to_inst
///////////////////////////////////////////////////
// <-- BEGIN COPY/CUT FROM HERE -->

test_1 your_inst_name(
	.port_1(port_1),
	.port_2(port_2),
	.port_3(port_3),
	.port_4(port_4)
);

// <-- END COPY/CUT FROM HERE -->
```

What the Tclsh will see:
```tcl
source_to_inst -filetype verilog -files ./test.v
./test.veo
```

From here you can view the test.veo file and and see the generated instantiation template.
