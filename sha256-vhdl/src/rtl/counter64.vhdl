library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter64 is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        increase : in  std_logic;
        value    : out unsigned(5 downto 0);
        overflow : out std_logic
    );
end entity;

architecture counter64_arch of counter64 is
    constant INITIAL : unsigned(5 downto 0) := to_unsigned(16, 6);
    signal count     : unsigned(5 downto 0) := INITIAL;
    signal result    : unsigned(6 downto 0);
begin
    result <= ('0' & count) + 1;
    
    process (clk, rst) begin
        if rst = '1' then
            count <= INITIAL;
        elsif rising_edge(clk) then
            if increase = '1' then
                count <= result(5 downto 0);
            end if;
        end if;
    end process;
    
    value <= count;
    
    -- O overflow agora é disparado de forma combinacional para evitar atraso de clock
    overflow <= '1' when count = to_unsigned(63, 6) else '0';
    
end architecture;