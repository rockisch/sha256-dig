library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package sha256_pkg is
	type H_TYPE is array (0 to 7) of std_logic_vector(31 downto 0);
	type W_TYPE is array (0 to 15) of std_logic_vector(31 downto 0);
	type K_TYPE is array (0 to 63) of std_logic_vector(31 downto 0);

    type FSM_STATE is ( S_IDLE, S_INIT, S_SCHED, S_COMP, S_DONE );
end package;

package body sha256_pkg is
end sha256_pkg;
