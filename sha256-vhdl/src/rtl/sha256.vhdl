library ieee;
use ieee.std_logic_1164.all;
use work.sha256_pkg.all;

entity sha256 is
    port(
        clk, rst, rdy : in std_logic;
        fin           : out std_logic;
        chunk         : in std_logic_vector(511 downto 0); -- Bloco de entrada com a mensagem de 512 bits
        h_in          : in H_TYPE;                         -- Estado inicial/intermediário do Hash
        h_out         : out H_TYPE                         -- Saída com o próximo estado do Hash
    );
end entity;

architecture sha256_arch of sha256 is
    signal o_loop_last, c_init, c_done : std_logic;
    signal c_r1, c_r2 : std_logic;
begin

    arch_bc: entity work.sha256_bc port map(
        clk=>clk, rst=>rst, rdy=>rdy, fin=>fin,
        o_loop_last=>o_loop_last, c_init=>c_init, c_done=>c_done,
        c_r1=>c_r1, c_r2=>c_r2
    );

    arch_bo: entity work.sha256_bo port map(
        clk=>clk, rst=>rst, chunk=>chunk, h_in=>h_in, h_out=>h_out,
        o_loop_last=>o_loop_last, c_init=>c_init, c_done=>c_done,
        c_r1=>c_r1, c_r2=>c_r2
    );

end architecture;
