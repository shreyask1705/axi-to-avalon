	component res is
		port (
			ninit_done : out std_logic   -- reset
		);
	end component res;

	u0 : component res
		port map (
			ninit_done => CONNECTED_TO_ninit_done  -- ninit_done.reset
		);

