-- The SHA256 algorithm requires 2 usages of a counter:
-- 1. Count from 16 to 63 to populate the message schedule
-- 2. Count from 0 to 63 to run the compression algo
-- Given both parts of the algorithm only requires counting up to 64, we can use the overflow
-- signal as a way to know whether we can stop counting.
-- Also, given the first part of the algo starts at 16, we define our initial state to be 16 as
-- well
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter64 is
    port (
        clk : in  std_logic;
        rst : in  std_logic;
        increase : in std_logic;
        value : out unsigned(5 downto 0);
        overflow : out std_logic
    );

    -- Start at 16
    constant INITIAL : unsigned(5 downto 0) := to_unsigned(17, 6);
end entity;

architecture counter64_arch of counter64 is
    signal count : unsigned(5 downto 0) := INITIAL;
    -- Define intermediary value 1 bit larger so we can extract the overflow
    signal result : unsigned(6 downto 0);
begin
    result <= ('0' & count) + 1;

    process (clk, rst)
    begin
        if rst = '1' then
            count    <= INITIAL;
            overflow <= '0';
        elsif rising_edge(clk) then
            overflow <= '0';
            if increase = '1' then
                count    <= result(5 downto 0);
                overflow <= result(6);
            end if;
        end if;
    end process;

    value <= count;
end architecture;
