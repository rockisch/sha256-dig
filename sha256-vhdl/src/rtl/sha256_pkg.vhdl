library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package sha256_pkg is
    type H_TYPE is array (0 to 7) of std_logic_vector(31 downto 0);
    type W_TYPE is array (0 to 15) of std_logic_vector(31 downto 0);
    type K_TYPE is array (0 to 63) of std_logic_vector(31 downto 0);
    type FSM_STATE is ( S_IDLE, S_INIT, S_SCHED, S_COMP, S_DONE );

    function sha_ch(x, y, z : std_logic_vector) return std_logic_vector;
    function sha_maj(x, y, z : std_logic_vector) return std_logic_vector;
    function sha_bsig0(x : std_logic_vector) return std_logic_vector;
    function sha_bsig1(x : std_logic_vector) return std_logic_vector;
    function sha_ssig0(x : std_logic_vector) return std_logic_vector;
    function sha_ssig1(x : std_logic_vector) return std_logic_vector;
end package;

package body sha256_pkg is
    function sha_ch(x, y, z : std_logic_vector) return std_logic_vector is
    begin return (x and y) xor ((not x) and z); end function;
    
    function sha_maj(x, y, z : std_logic_vector) return std_logic_vector is
    begin return (x and y) xor (x and z) xor (y and z); end function;
    
    function sha_bsig0(x : std_logic_vector) return std_logic_vector is
    begin return std_logic_vector( (unsigned(x) ror 2) xor (unsigned(x) ror 13) xor (unsigned(x) ror 22) ); end function;
    
    function sha_bsig1(x : std_logic_vector) return std_logic_vector is
    begin return std_logic_vector( (unsigned(x) ror 6) xor (unsigned(x) ror 11) xor (unsigned(x) ror 25) ); end function;
    
    function sha_ssig0(x : std_logic_vector) return std_logic_vector is
    begin return std_logic_vector( (unsigned(x) ror 7) xor (unsigned(x) ror 18) xor (unsigned(x) srl 3) ); end function;
    
    function sha_ssig1(x : std_logic_vector) return std_logic_vector is
    begin return std_logic_vector( (unsigned(x) ror 17) xor (unsigned(x) ror 19) xor (unsigned(x) srl 10) ); end function;
end sha256_pkg;
