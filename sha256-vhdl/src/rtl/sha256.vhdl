library ieee;
use ieee.std_logic_1164.all;
use work.sha256_pkg.all; -- Importa o pacote com os tipos de dados customizados (como H_TYPE)

-- Entidade principal (Top-Level) que encapsula todo o sistema criptográfico
entity sha256 is
    port(
        clk, rst, rdy : in std_logic;                      -- Sinais de sincronismo e gatilho de início (rdy)
        fin           : out std_logic;                     -- Sinalizador de conclusão (vai a '1' quando termina)
        chunk         : in std_logic_vector(511 downto 0); -- Bloco de entrada com a mensagem de 512 bits
        h_in          : in H_TYPE;                         -- Estado inicial/intermediário do Hash
        h_out         : out H_TYPE                         -- Saída com o Hash final calculado
    );
end entity;

architecture sha256_arch of sha256 is
    -- Sinais internos (fios) usados para conectar a Base de Controle à Base Operativa
    signal o_loop_last, c_init, c_done : std_logic;
    signal c_sched1, c_sched2, c_sched3, c_comp1, c_comp2, c_comp3, c_comp4 : std_logic;
begin

    -- Instancia a Base de Controle (O "cérebro" que dita qual passo executar)
    arch_bc: entity work.sha256_bc port map(
        clk=>clk, rst=>rst, rdy=>rdy, fin=>fin,
        o_loop_last=>o_loop_last, c_init=>c_init, c_done=>c_done,
        c_sched1=>c_sched1, c_sched2=>c_sched2, c_sched3=>c_sched3,
        c_comp1=>c_comp1, c_comp2=>c_comp2, c_comp3=>c_comp3, c_comp4=>c_comp4
    );

    -- Instancia a Base Operativa (Os "músculos" que fazem as contas e guardam os dados)
    arch_bo: entity work.sha256_bo port map(
        clk=>clk, rst=>rst, chunk=>chunk, h_in=>h_in, h_out=>h_out,
        o_loop_last=>o_loop_last, c_init=>c_init, c_done=>c_done,
        c_sched1=>c_sched1, c_sched2=>c_sched2, c_sched3=>c_sched3,
        c_comp1=>c_comp1, c_comp2=>c_comp2, c_comp3=>c_comp3, c_comp4=>c_comp4
    );

end architecture;
