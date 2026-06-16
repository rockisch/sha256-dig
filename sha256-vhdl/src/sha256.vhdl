library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sha256 is
	port(
		clk        : in  std_logic;     -- ck
		rst_a      : in  std_logic;     -- reset
		enable     : in  std_logic;     -- iniciar
		payload : in std_logic_vector(512 downto 0);
		sha  : out std_logic_vector(256 downto 0);
		done : out std_logic
	);
end entity sha256;

architecture structure of sha256 is
begin
	process is
	begin
		report "Hello world";
		wait;
	end process;
end architecture structure;
