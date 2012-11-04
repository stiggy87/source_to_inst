package require cmdline

# Name: source_to_inst
# Description: This script will take in .vhdl/.v file types and identify the top-level instantation
# of the file and generate a .vho/.veo that a user can use in their design. It will speed-up code
# generation for the user and their design
#
# Inputs:
#	-filetype <vhdl|verilog> : REQUIRED The type of files being checking
# 	<files> : REQUIRED A list of files to use with absolute pathing
#	-h|-help : Will printout usage.
# Outputs:
#	<path_to_files> : Path to all the .veo/.vho files generated
#	<generated_files> : All the generated files in the same directory as where the files located

proc source_to_inst { args } {	
	# Set options
	set ::argv0 "source_to_inst"
	array set options [::cmdline::getoptions args {
#		{filetype.arg "The type of files being parsed. <verilog|vhdl>"}
		{files.arg	  "A list of files. These must match -filetype."}	
		}]
	# "source_to_inst -filetype <verilog|vhdl> -files <list of files>"
	
	# if { [llength $args] == 0 } {
		# return -code error "source_to_inst -filetype <verilog|vhdl> -files <list of files>"
		# break; # Not sure if this is needed
	# }
	
        set files $options(files)

        # Determine filetype from files extensions
        set verilog_files ""
        set vhdl_files ""
        set v_type ""
        set vhdl_type ""
        foreach file $files {
            # if the extension meets the .v"
            if {[regexp -all {.+\.v(?![hdl])} $file] } {
                lappend verilog_files $file
                #puts "Verilog file: $file"
                set v_type "verilog"
            } elseif { [regexp -all {(.+\.vhd)|(.+\.vhdl)} $file] } {
                lappend vhdl_files $file
                #puts "VHDL file : $file"
                set vhdl_type "vhdl"
            } else {
                puts "$file - Not a valid file."
            }
        }	
        #puts $verilog_files
        #puts $vhdl_files
		
	if { $v_type == "verilog"} {
                #puts "Getting into Verilog..."
		# Read in the file
		foreach file $verilog_files {
                        #puts $file
			set verilog_fid [open $file r]
			set verilog_lines [split [read $verilog_fid] \n]
			close $verilog_fid
			
			# Regex the file and find all 'module ()' definitions
			
			# Get the module name
			set mod_line [lsearch -regexp -all -inline  $verilog_lines {module\s(.+)(?=\()}]
			regexp -all {module\s(.+)(?=\()} $mod_line all mod_name

                        # Need to setup sorting algo to identify type of instantiation
                        # Possible solution - search for the module line and identify it from there...
                        # 1st type of Port List
                        # module_name (port_1, port_2, port_3, etc);
                         
			# Get the port list
			set port_line [lsearch -regexp -all -inline  $verilog_lines {module\s(.+)(?=\()}]
			regexp -all {module\s.+\((.+)\)} $port_line all port_list

                        # 2nd type of Port list - Need to check file type
                        # input port_1;
                        # input port_2; // etc...
                        set port_line [lsearch -regexp -all -inline $verilog_lines {(input|output|inout|\[.+\]).+}]
                        set port_line [concat {*}$port_line]

                        # Remove the input|output|inout with bus size
                        regsub -all {(\s|input|output|inout|\[.+\])} $port_line "" port_list

                        
			# Delete the commas
			set port_list [string map {, \ } $port_list]
                        puts $port_list
			
			# Regex and find all the ports and their types
			#	- Collect: Name, Size/length, parameters
			
			# Get path
			regexp -all {(.+)(?=\/.+.v)} $file all path

			# Get file name
			regexp -all {(?:.+\/)(.+).v} $file all file_name

			# Populate the template design with data gathered above
			set veo_file [open "$path/$file_name\.veo" w]
			
			# Test of function
			verilog_temp $veo_file $mod_name $port_list 
			
			# Repeat for all listed files
			lappend return_val "$path/$file_name\.veo"
		}
	}

        if { $vhdl_type == "vhdl"} {
                #puts "Getting into VHDL..."
		foreach file $vhdl_files {
                        #puts $file
			# Regex the file and find all top-level definitions
			# This includes components, etc
			set vhdl_fid [open $file r]
			set vhdl_lines [split [read $vhdl_fid] \n]
			close $vhdl_fid
			
			# Get entity name for component name
			set entity_line [lsearch -nocase -regexp -all -inline $vhdl_lines {entity}]
			regexp -all {entity\s(.+)(?=\sis)} $entity_line all comp_name
			
			# Get port list (This will be difficult since VHDL must have a port per line)
			set port_list [lsearch -nocase -regexp -all -inline $vhdl_lines {(in|out|inout)\sSTD_LOGIC}]
			set port_list_final ""
			foreach port $port_list {
				lappend port_list_final [string trim $port]
			}
			
			# Get path
			regexp -all {(.+)(?=\/.+.vhd)} $file all path
			
			# Get file name
			regexp -all {(?:.+\/)(.+).vhd} $file all file_name
			
			# Populate the template design with data gathered above
			set vho_file [open "$path/$file_name\.vho" w]
			
			vhdl_temp $vho_file $comp_name $port_list_final 
			
			lappend return_val "$path/$file_name\.vho"
		# Repeat for all listed files
		}
	}

        foreach rval $return_val {
            puts $rval
        }
}

# Name: verilog_temp
# Description: A procedure that is the contains the template information for verilog 
#
# Inputs:
#	<veo_file> : The FID for the veo_file
#	<mod_name> : Module name
#	<port_list> : List of all the ports
#	<param_list> : List of any parameters used (OPTIONAL)
# Outputs:
#	1 : Success
#	0 : Fail
proc verilog_temp { veo_file mod_name port_list {param_list {}}} {
	# Define template
	set template {///////////////////////////////////////////////////}
	lappend template {// This instantiation template was created from source_to_inst} 
	lappend template {///////////////////////////////////////////////////}
	lappend template {// <-- BEGIN COPY/CUT FROM HERE -->}
	
	# Add the module name to the template
	lappend template "$mod_name your_inst_name("
	
	# Parameter list
	# Add any parameter items to template
	if { $param_list != {} } {
		set i [llength $param_list]
		foreach param $param_list {
			if { $i == 1 } {
				lappend template "\t$param == "
			} else {
				lappend template "\t$param,\n"
			}
		}
	}
	
	# Port list
	# Add ports to template
	set i [llength $port_list]

	foreach port $port_list {
		if { $i == 1 } {
			lappend template "\t\.$port\($port\)"
		} else {
			lappend template "\t\.$port\($port\),"
		}
		incr i -1
	}
	
	# Add footer to template
	lappend template ");\n"
	lappend template {// <-- END COPY/CUT FROM HERE -->}
	
	# Print out template
	foreach line $template {
		puts $veo_file $line
	}
	
	close $veo_file
}

# Name: vhdl_temp
# Description: A procedure that is the contains the template information for vhdl 
#
# Inputs:
# Inputs:
#	<vho_file> : The FID for the veo_file
#	<comp_name> : Component name
#	<port_list> : List of all the ports
#	<generic_list> : List of any generics used (OPTIONAL)
# Outputs:
#	1 : Success
#	0 : Fail
proc vhdl_temp { vho_file comp_name port_list {generic_list {}} } {
	set template {--------------------------------------------------}
	lappend template {-- This instantiation template was created from source_to_inst}
	lappend template {--------------------------------------------------}
	lappend template {-- BEGIN COPY/CUT for COMPONENT Declaration --}
	lappend template "COMPONENT $comp_name"  
	
	if {$generic_list != {} } {
		
		lappend template {  GENERIC (}
		
		# Add the generic list to the template (if there are any)
		lappend template "  \);\n"
	}
	
	lappend template "  PORT \("
	
	# Add the port list to the template
	foreach port $port_list {
		lappend template "\t$port"
	}
	
	lappend template {  );}
	lappend template {END COMPONENT;}
	lappend template "-- END COPY/CUT for COMPONENT Declaration --\n"
	lappend template "--------------------------------------------------\n"
	lappend template {-- BEGIN COPY/CUT for INSTANTIATION Template --}
	lappend template "your_inst_name : $comp_name"
	
	# Add the generic list : generic => generic
	if {$generic_list != {} } {
		lappend template {GENERIC MAP (}
		lappend template "  \);\n"
	}
	
	lappend template {  PORT MAP (}
	
	# Add the port list : port => port
	set i [llength $port_list]
	foreach port $port_list {
		# regexp out the ACTUAL port
		regexp -all {(.+)(?=\s\:)} $port all port_final
		set port_final [string trim $port_final \{\}]
		if { $i == 1 } {
			lappend template "\t$port_final => $port_final"
		} else {
			lappend template "\t$port_final => $port_final,"
		}
		incr i -1
	}
	
	lappend template {  );}
	lappend template {-- END COPY/CUT for INSTANTIATION Template --}

	foreach line $template {
		puts $vho_file $line
	}
	
	# Write file to location
	close $vho_file
}
