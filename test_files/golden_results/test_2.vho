--------------------------------------------------
-- This instantiation template was created from source_to_inst
--------------------------------------------------

-- BEGIN COPY/CUT for COMPONENT Declaration --
COMPONENT test_2
  GENERIC (
	width : integer := 8;
	height : integer := 7
  );
  
  PORT {
	port_1 : in std_logic;
	port_2 : in std_logic;
	port_3 : inout std_logic;
	port_4 : out std_logic_vector (width downto 0)
  );
END COMPONENT;
-- END COPY/CUT for COMPONENT Declaration --

--------------------------------------------------

-- BEGIN COPY/CUT for INSTANTIATION Template --
your_inst_name : test_2
  GENERIC MAP (
	width => width,
	height => height
  );
  
  PORT MAP (
	port_1 => port_1,
	port_2 => port_2,
	port_3 => port_3,
	port_4 => port_4
  );
-- END COPY/CUT for INSTANTIATION Template --