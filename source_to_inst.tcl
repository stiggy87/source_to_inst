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
			# Count how many "module" lines it finds and put in foreach loop
			
			# Get the module name
			set mod_line [lsearch -regexp -all -inline  $verilog_lines {module\s(\w+)}]
            set mod_line [concat {*}$mod_line]
			set mod_count [regexp -all {module\s(\w+)} $mod_line all mod_name];
			#puts $mod_name
			# Get path
			regexp -all {(.+)(?=\/.+.v)} $file all path

			# Get file name
			regexp -all {(?:.+\/)(.+).v} $file all file_name
			
			set veo_file [open "$path/$file_name\.veo" w]
			
			foreach mod_name [concat {*}[regsub -all {module\s} [regexp -inline -all {module\s\w+} $mod_line] ""]] {
				#puts $mod_name
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
				set port_list [string map {, \  ; \ } $port_list]
				#puts $port_list
				

				# Parameter capture
				set param_list [lsearch -regexp -all -inline $verilog_lines {parameter.+}]
				#set param_list [concat {*}$param_list]
				#puts $param_list

				# Remove the parameter keyword
				array set param_arr {}
				foreach param $param_list {
					regexp -all {parameter\s(\w+)\=(.+);} $param all param_key param_val
					set param_arr($param_key) $param_val
					#puts "$param_arr($param_key) = $param_val"
				}

				# Populate the template design with data gathered above
				
				# Test of function
				#puts "[array size param_arr]"
				verilog_temp $veo_file $mod_name $port_list param_arr $mod_count
				
				# Repeat for all listed files
				incr mod_count -1
			}
			
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
			
            # Generic List
            set generic_list [lsearch -nocase -regexp -all -inline $vhdl_lines {.+\:\=.+}]
            set generic_final ""
            foreach generic $generic_list {
                lappend generic_final [string trim $generic]
            }
            
            #puts $generic_list
			# Get path
			regexp -all {(.+)(?=\/.+.vhd)} $file all path
			
			# Get file name
			regexp -all {(?:.+\/)(.+).vhd} $file all file_name
			
			# Populate the template design with data gathered above
			set vho_file [open "$path/$file_name\.vho" w]
			
			vhdl_temp $vho_file $comp_name $port_list_final $generic_final 1
			
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
#	<param_arr> : Array of any parameters used (OPTIONAL)
#	<mod_count> : # of times a file contains a module, this is to help with files with mulitple
#				  module instantiations
# Outputs:
#	1 : Success
#	0 : Fail
proc verilog_temp { veo_file mod_name port_list param_arr mod_count} {
    upvar $param_arr pa
    #puts [array size pa]
	# Define template
	
	set template {///////////////////////////////////////////////////}
	lappend template {// This instantiation template was created from source_to_inst} 
	lappend template {///////////////////////////////////////////////////}
	lappend template {// <-- BEGIN COPY/CUT FROM HERE -->}
	
	# Add the module name to the template
	
	
	# Parameter list
	# Add any parameter items to template
	if { [array size pa] != 0 } {
		set i [array size pa]
        #puts $i
        lappend template "$mod_name #("
		foreach {key val} [array get pa] {
			if { $i == 1 } {
				lappend template "\t\.$key\($val\) "
			} else {
				lappend template "\t.$key\($val\), "
			}
            incr i -1
		}

        lappend template "\t\) your_inst_name \("
	} else {
        lappend template "$mod_name your_inst_name("
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
	
	if { $mod_count == 1 } {
		close $veo_file
	}
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
#	<entity_count> : Counts the # of times an entity is in a file. So far, this is set
#					 to 1 since no evidence shows this as normal coding practices
# Outputs:
#	1 : Success
#	0 : Fail
proc vhdl_temp { vho_file comp_name port_list {generic_list {}} entity_count} {
	set template {--------------------------------------------------}
	lappend template {-- This instantiation template was created from source_to_inst}
	lappend template "--------------------------------------------------\n"
	lappend template {-- BEGIN COPY/CUT for COMPONENT Declaration --}
	lappend template "COMPONENT $comp_name"  
	
    set generic_final {}
	if {$generic_list != {} } {
		# Remove the generic
        foreach generic $generic_list {
            if { [regexp -all -nocase {generic\s\(} $generic]} {
                regsub -all {generic\s\(} $generic "" gen_temp
                lappend generic_final [string trim [string map {; \ } $gen_temp]]
            } else {
                lappend generic_final [string trim [string map {; \ } $generic]]
            }
        }
        
		lappend template {  GENERIC (}
		
        set i [llength $generic_final]
        foreach generic $generic_final {
            if {$i == 1} {
                lappend template "\t$generic"
            } else {
                lappend template "\t$generic;"
            }
            incr i -1
        }

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
	if {$generic_final != {} } {
		lappend template {GENERIC MAP (}
        set i [llength $generic_final]
        foreach generic $generic_final {
            regexp -all {\w+.+(?=\:)(?!\:=)} $generic gen_post
            set gen_post [string trim $gen_post]
            if {$i == 1} {
                lappend template "\t$gen_post => $gen_post"
            } else {
                lappend template "\t$gen_post => $gen_post,"
            }
            incr i -1
        }
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
	if { $entity_count == 1 } {
		close $vho_file
	}
}
