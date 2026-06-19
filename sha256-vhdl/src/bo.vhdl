library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bo is
	port(
        clk         : in std_logic;
        rst_a       : in std_logic;
        init_load   : in std_logic;
        sched_en    : in std_logic;
        comp_en     : in std_logic;
        out_en      : in std_logic;
        chunk       : in std_logic_vector(511 downto 0);
        state_in    : in std_logic_vector(255 downto 0);
        state_out   : out std_logic_vector(255 downto 0);
        status      : out std_logic_vector(6 downto 0)
	);
end entity bo;

architecture structure of bo is
begin
	process is
	begin
		report "Hello world";
		wait;
	end process;
end architecture structure;
