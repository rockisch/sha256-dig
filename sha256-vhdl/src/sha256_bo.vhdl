library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_pkg.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sha256_bo is

	port(
		clk : in std_logic;
		rst : in std_logic;
		chunk : in std_logic_vector(511 downto 0);
		h_in : in H_TYPE;
		h_out : out H_TYPE;

		-- operating signals
		o_loop_last : out std_logic;

		-- control signals
		c_init : in std_logic;
		c_loop_sched : in std_logic;
		c_loop_comp : in std_logic
	);

	constant K : K_TYPE := (
		X"428a2f98", X"71374491", X"b5c0fbcf", X"e9b5dba5", X"3956c25b", X"59f111f1", X"923f82a4", X"ab1c5ed5",
		X"d807aa98", X"12835b01", X"243185be", X"550c7dc3", X"72be5d74", X"80deb1fe", X"9bdc06a7", X"c19bf174",
		X"e49b69c1", X"efbe4786", X"0fc19dc6", X"240ca1cc", X"2de92c6f", X"4a7484aa", X"5cb0a9dc", X"76f988da",
		X"983e5152", X"a831c66d", X"b00327c8", X"bf597fc7", X"c6e00bf3", X"d5a79147", X"06ca6351", X"14292967",
		X"27b70a85", X"2e1b2138", X"4d2c6dfc", X"53380d13", X"650a7354", X"766a0abb", X"81c2c92e", X"92722c85",
		X"a2bfe8a1", X"a81a664b", X"c24b8b70", X"c76c51a3", X"d192e819", X"d6990624", X"f40e3585", X"106aa070",
		X"19a4c116", X"1e376c08", X"2748774c", X"34b0bcb5", X"391c0cb3", X"4ed8aa4a", X"5b9cca4f", X"682e6ff3",
		X"748f82ee", X"78a5636f", X"84c87814", X"8cc70208", X"90befffa", X"a4506ceb", X"bef9a3f7", X"c67178f2"
	);
	signal W : K_TYPE := (
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000",
        X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000", X"00000000"
    );

	signal loop_count : unsigned(5 downto 0);
end entity;

architecture sha256_bo_arch of sha256_bo is
begin
	COUNTER: entity work.counter64 port map(
		clk => clk,
		-- Reset the counter on init
		rst => rst or c_init,
		value => loop_count,
		overflow => o_loop_last,
		increase => c_loop_sched or c_loop_comp
	);

	process (clk, rst)
		variable loop_i : integer;

		variable a : std_logic_vector(31 downto 0) := h_in(0);
		variable b : std_logic_vector(31 downto 0) := h_in(1);
		variable c : std_logic_vector(31 downto 0) := h_in(2);
		variable d : std_logic_vector(31 downto 0) := h_in(3);
		variable e : std_logic_vector(31 downto 0) := h_in(4);
		variable f : std_logic_vector(31 downto 0) := h_in(5);
		variable g : std_logic_vector(31 downto 0) := h_in(6);
		variable h : std_logic_vector(31 downto 0) := h_in(7);

		variable s0 : std_logic_vector(31 downto 0);
		variable s1 : std_logic_vector(31 downto 0);
	begin
		if clk = '1' then
			if c_init = '1' then
				for i in 0 to 15 loop
					W(i) <= chunk(511 - 32 * i downto 480 - 32 * i);
				end loop;
			elsif c_loop_sched = '1' then
				-- TODO: The counter ends up returning 0 on the same state it returns 'loop_last'...
				-- TODO: Either store the next value in a register or just do a minus 1
				loop_i := to_integer(loop_count-1);

				s0 := (W(loop_i-15) ror 7) xor (w(loop_i-15) ror 18) xor (w(loop_i-15) srl 3);
				s1 := (W(loop_i-2) ror 17) xor (w(loop_i-2) ror 19) xor (w(loop_i-2) srl 10);
				W(loop_i) <= std_logic_vector(unsigned(W(loop_i-16)) + unsigned(s0) + unsigned(W(loop_i-7)) + unsigned(s1));
				report "W!!! " & integer'image(loop_i) & LF & to_bstring(W(loop_i-1));
			elsif c_loop_comp = '1' then
			end if;
		end if;
	end process;
end architecture;
