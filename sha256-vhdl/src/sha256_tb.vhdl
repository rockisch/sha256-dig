library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;
use work.sha256_pkg.all;

entity sha256_tb is
end entity;

architecture sha256_tb_arch of sha256_tb is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal rdy : std_logic := '0';
    signal fin : std_logic := '0';
    signal chunk_in : std_logic_vector(511 downto 0) := (others => '0');
    signal h_in : H_TYPE := (others => (others => '0'));
    signal h_out : H_TYPE := (others => (others => '0'));

    function get_final_chunk(
        length : integer;
        chunk : std_logic_vector(511 downto 0)
    ) return std_logic_vector is
        variable result : std_logic_vector(511 downto 0);
    begin
        result := (others => '0');
        result(511 - (length * 8)) := '1';
        result(31 downto 0) := std_logic_vector(to_unsigned(length * 8, 32));
        if length > 0 then
            result(511 downto 512 - length * 8) := chunk(511 downto 512 - length * 8);
        end if;
        return result;
    end function;

    function get_string_vector(s: string) return std_logic_vector is
        constant ss: string(1 to s'length) := s;
        variable answer: std_logic_vector(1 to 8 * s'length);
        variable p: integer;
        variable c: integer;
    begin
        for i in ss'range loop
            p := 8 * i;
            c := character'pos(ss(i));
            answer(p - 7 to p) := std_logic_vector(to_unsigned(c,8));
        end loop;
        return answer;
    end function;
begin
    -- Reset and clk
    clk <= not clk after 1 ns;
    rst <= '1', '0' after 1 ns;

    -- Instantiate the design under test
    dut: entity work.sha256 port map (
        clk => clk,
        rst	=> rst,
        rdy => rdy,
        fin => fin,
        chunk => chunk_in,
        h_in => h_in,
        h_out => h_out
    );

    -- Generate the test stimulus
    stimulus: process begin
        -- Chunk setup
        chunk_in(511 downto 511-23) <= get_string_vector("abc");
        wait for 1 ns;
        chunk_in <= get_final_chunk(3, chunk_in);

        -- Start test
        rdy <= '1';
        wait for 200 ns;

        -- assert h_out(0) = X"ba7816bf" report "invalid h0: " & to_bstring(h_out(0)) severity failure;
        -- assert h_out(1) = X"8f01cfea" report "invalid h1: " & to_bstring(h_out(1)) severity failure;
        -- assert h_out(2) = X"414140de" report "invalid h2: " & to_bstring(h_out(2)) severity failure;
        -- assert h_out(3) = X"5dae2223" report "invalid h3: " & to_bstring(h_out(3)) severity failure;
        -- assert h_out(4) = X"b00361a3" report "invalid h4: " & to_bstring(h_out(4)) severity failure;
        -- assert h_out(5) = X"96177a9c" report "invalid h5: " & to_bstring(h_out(5)) severity failure;
        -- assert h_out(6) = X"b410ff61" report "invalid h6: " & to_bstring(h_out(6)) severity failure;
        -- assert h_out(7) = X"f20015ad" report "invalid h7: " & to_bstring(h_out(7)) severity failure;
        report "chunk_in: " & to_bstring(chunk_in);
        report "h_out: " & LF &
            to_bstring(h_out(0)) & LF &
            to_bstring(h_out(1)) & LF &
            to_bstring(h_out(2)) & LF &
            to_bstring(h_out(3)) & LF &
            to_bstring(h_out(4)) & LF &
            to_bstring(h_out(5)) & LF &
            to_bstring(h_out(6)) & LF &
            to_bstring(h_out(7));
        finish;
    end process stimulus;
end architecture;
