--------------------------------------------------
-- This instantiation template was created from source_to_inst
--------------------------------------------------

-- BEGIN COPY/CUT for COMPONENT Declaration --
COMPONENT test_1
  PORT {
	port_1 : in std_logic;
	port_2 : in std_logic;
	port_3 : inout std_logic;
	port_4 : out std_logic_vector (7 downto 0)
  );
END COMPONENT;
-- END COPY/CUT for COMPONENT Declaration --

--------------------------------------------------

-- BEGIN COPY/CUT for INSTANTIATION Template --
your_inst_name : test_1
  PORT MAP (
	port_1 => port_1,
	port_2 => port_2,
	port_3 => port_3,
	port_4 => port_4
  );
-- END COPY/CUT for INSTANTIATION Template --