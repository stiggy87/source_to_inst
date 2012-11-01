entity test_2 is
	generic ( width : integer := 8;
			  height : integer := 7;
	);
	port (
		port_1 : in std_logic;
		port_2 : in std_logic;
		port_3 : inout std_logic;
		port_4 : out std_logic_vector (width downto 0)
	);
end test_2;

