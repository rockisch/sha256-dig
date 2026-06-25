library ieee;
use ieee.std_logic_1164.all;
use work.sha256_pkg.all;

entity sha256 is
    port(
        clk, rst, rdy : in std_logic;
        fin : out std_logic;
        chunk : in std_logic_vector(511 downto 0);
        h_in : in H_TYPE;
        h_out : out H_TYPE
    );
end entity;

architecture sha256_arch of sha256 is
    signal o_loop_last, c_init, c_loop_sched, c_loop_comp, c_done : std_logic;
begin
    arch_bc: entity work.sha256_bc port map(clk=>clk, rst=>rst, rdy=>rdy, fin=>fin, o_loop_last=>o_loop_last, c_init=>c_init, c_loop_sched=>c_loop_sched, c_loop_comp=>c_loop_comp, c_done=>c_done);
    arch_bo: entity work.sha256_bo port map(clk=>clk, rst=>rst, chunk=>chunk, h_in=>h_in, h_out=>h_out, o_loop_last=>o_loop_last, c_init=>c_init, c_loop_sched=>c_loop_sched, c_loop_comp=>c_loop_comp, c_done=>c_done);
end architecture;