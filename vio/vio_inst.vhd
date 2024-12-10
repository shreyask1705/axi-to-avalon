	component vio is
		port (
			source     : out std_logic_vector(2 downto 0);        -- source
			source_clk : in  std_logic                    := 'X'  -- clk
		);
	end component vio;

	u0 : component vio
		port map (
			source     => CONNECTED_TO_source,     --    sources.source
			source_clk => CONNECTED_TO_source_clk  -- source_clk.clk
		);

