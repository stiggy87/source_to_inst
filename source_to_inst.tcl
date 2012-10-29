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
		{filetype.arg "The type of files being parsed. <verilog|vhdl>"}
		{files.arg	  "A list of files. These must match -filetype."}	
		}]
	# "source_to_inst -filetype <verilog|vhdl> -files <list of files>"
	
	# if { [llength $args] == 0 } {
		# return -code error "source_to_inst -filetype <verilog|vhdl> -files <list of files>"
		# break; # Not sure if this is needed
	# }
	
	set filetype $options(filetype)
	set files $options(files)
		
	if { $filetype == "verilog"} {
		# Read in the file
		foreach file $files {
			set verilog_fid [open $file r]
			set verilog_lines [split [read $verilog_fid] \n]
			close $verilog_fid
			
			# Regex the file and find all 'module ()' definitions
			# Two types of 'module {}' definitions
			# 1) module ( input , inout, output, etc)
			# 2) module ( port_1, port_2, etc);\n input,output,inout etc
			
			# Get the module name
			set mod_line [lsearch -regexp -all -inline  $verilog_lines {module\s(.+)(?=\()}]
			regexp -all {module\s(.+)(?=\()} $mod_line all mod_name
			
			# Get the port list
			set port_line [lsearch -regexp -all -inline  $verilog_lines {module\s(.+)(?=\()}]
			regexp -all {module\s.+\((.+)\)} $port_line all port_list
			
			# Delete the commas
			set port_list [string map {, \ } $port_list]
			
			# Regex and find all the ports and their types
			#	- Collect: Name, Size/length, parameters
			
			# Generate a template design (format appropriately)
			set header "///////////////////////////////////////////////////\n// This instantiation template was created from source_to_inst\n///////////////////////////////////////////////////\n// <-- BEGIN COPY/CUT FROM HERE -->\n\n"
			set module_header "$mod_name your_inst_name(\n"
			# foreach port $port_list {
				# set port_declare($port) "\t\.$port\($port\),\n"
			# }
			set module_footer ");\n\n"
			set footer {// <-- END COPY/CUT FROM HERE -->}
			
			# Get path
			regexp -all {(.+)(?=\/.+.v)} $file all path
			
			# Get file name
			regexp -all {(?:.+\/)(.+).v} $file all file_name
			
			# Populate the template design with data gathered above
			set veo_file [open "$path/$file_name\.veo" w]
			puts -nonewline $veo_file "$header"
			puts -nonewline $veo_file "$module_header"
			set i [llength $port_list]
			foreach port $port_list {
				if { $i == 1 } {
					puts -nonewline $veo_file "\t\.$port\($port\)\n"
				} else {
					puts -nonewline $veo_file "\t\.$port\($port\),\n"
				}
				incr i -1
			}
			puts -nonewline $veo_file $module_footer
			puts -nonewline $veo_file $footer
			
			# Write file to location
			close $veo_file
			
			# Repeat for all listed files
			return "$path/$file_name\.veo"
		}
	} elseif { $filetype == "vhdl"} {
		foreach file $files {
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
			#puts $port_list_final
			
			# Regex and find all the ports and their types
			#	- Collect: Direction, Name, Size/length, parameters
			
			# Generate a template design (format appropriately)
			set header "--------------------------------------------------\n-- This instantiation template was created from source_to_inst\n--------------------------------------------------\n\n-- BEGIN COPY/CUT for COMPONENT Declaration --\n"
			set comp_header "COMPONENT $comp_name\n  PORT (\n"
			set comp_footer "  );\nEND COMPONENT;\n-- END COPY/CUT for COMPONENT Declaration --\n\n"
			
			set divider "--------------------------------------------------\n\n-- BEGIN COPY/CUT for INSTANTIATION Template --\n"
			set inst_header "your_inst_name : $comp_name\n  PORT MAP (\n"
			set inst_footer "  \);\n"
			set footer "-- END COPY/CUT for INSTANTIATION Template --"
			
			# Get path
			regexp -all {(.+)(?=\/.+.vhd)} $file all path
			
			# Get file name
			regexp -all {(?:.+\/)(.+).vhd} $file all file_name
			
			# Populate the template design with data gathered above
			set vho_file [open "$path/$file_name\.vho" w]
			puts -nonewline $vho_file $header
			puts -nonewline $vho_file $comp_header
			foreach port $port_list_final {
				puts -nonewline $vho_file "\t$port\n"
			}
			
			puts -nonewline $vho_file $comp_footer
			puts -nonewline $vho_file $divider
			puts -nonewline $vho_file $inst_header
			
			# Port delecaration: port => port
			set i [llength $port_list_final]
			foreach port $port_list_final {
				# regexp out the ACTUAL port
				regexp -all {(.+)(?=\s\:)} $port all port_final
				set port_final [string trim $port_final \{\}]
				if { $i == 1 } {
					puts -nonewline $vho_file "\t$port_final => $port_final\n"
				} else {
					puts -nonewline $vho_file "\t$port_final => $port_final,\n"
				}
				incr i -1
			}
			puts -nonewline $vho_file $inst_footer
			puts -nonewline $vho_file $footer
			
			# Write file to location
			close $vho_file
			
			return "$path/$file_name\.vho"
		# Repeat for all listed files
		}
	}
}

# Name: verilog_temp
# Description: A procedure that is the contains the template information for verilog 
#
# Inputs:
#	<fid> : The output file's fid
#	<msg> : Text in a list to print out.
# Outputs:
#	1 : Success
#	0 : Fail
proc verilog_temp { fid { msg{}} } {
	set header {{///////////////////////////////////////////////////} {// This instantiation template was created from source_to_inst} {///////////////////////////////////////////////////} {// <-- BEGIN COPY/CUT FROM HERE -->\n}
	set module_header "$mod_name your_inst_name(\n"
	# foreach port $port_list {
	# set port_declare($port) "\t\.$port\($port\),\n"
	set footer {// <-- END COPY/CUT FROM HERE -->}

}

# Name: vhdl_temp
# Description: A procedure that is the contains the template information for vhdl 
#
# Inputs:
#	<fid> : The output file's fid
#	<msg> : Text in a list to print out.
# Outputs:
#	1 : Success
#	0 : Fail
proc vhdl_temp { fid { msg {} } } {

}
