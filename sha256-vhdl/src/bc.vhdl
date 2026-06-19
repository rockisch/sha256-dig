library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bc is
	port(
        clk         : in std_logic;
        rst_a       : in std_logic;
        start       : in std_logic;
        status      : in std_logic_vector(6 downto 0);
        init_load   : out std_logic;
        sched_en    : out std_logic;
        comp_en     : out std_logic;
        out_en      : out std_logic;
        done        : out std_logic
	);
end entity bc;

architecture structure of bc is
begin
	process is
	begin
		report "Hello world";
		wait;
	end process;
end architecture structure;
