library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_pkg.all; -- Importa o pacote com os tipos de dados customizados (como H_TYPE)

-- Adaptador de entrada: a placa nao aceita mais de 512 bits por vez, entao a
-- mensagem chega em 4 fatias de 128 bits. O adaptador acumula as fatias em um
-- estado interno de 512 bits e, quando ele esta cheio, aciona o nucleo SHA-256.
entity sha256_adaptor is
    port(
        clk, rst, rdy : in std_logic;                      -- Sincronismo e gatilho de cada fatia (rdy)
        fin           : out std_logic;                     -- Sinalizador de conclusao do hash completo
        chunk_part    : in std_logic_vector(127 downto 0); -- Fatia de entrada de 128 bits
        h_in          : in H_TYPE;                         -- Estado inicial/intermediario do Hash
        h_out         : out H_TYPE                         -- Saida com o Hash final calculado
    );
end entity;

architecture sha256_adaptor_arch of sha256_adaptor is
    -- Estado interno de 512 bits montado a partir das 4 fatias de 128 bits
    signal chunk_full : std_logic_vector(511 downto 0) := (others => '0');
    -- Contador de qual fatia esta sendo recebida (0 a 3)
    signal part_count : unsigned(1 downto 0) := (others => '0');

    -- Fios de interligacao entre a Base de Controle do adaptador e o datapath/nucleo
    signal c_capture, core_rdy, core_fin, parts_last : std_logic;
begin

    -- Indica que a fatia capturada agora (indice 3) e a ultima do bloco de 512 bits
    parts_last <= '1' when part_count = "11" else '0';

    -- Base de Controle (FSM) que orquestra a recepcao das fatias e o disparo do nucleo
    adaptor_bc: entity work.sha256_adaptor_bc port map(
        clk => clk, rst => rst, rdy => rdy,
        parts_last => parts_last, core_fin => core_fin,
        c_capture => c_capture, core_rdy => core_rdy, fin => fin
    );

    -- Datapath do adaptador: registra cada fatia na posicao correta do estado de 512 bits.
    -- A primeira fatia ocupa os bits mais significativos, mantendo a ordem big-endian
    -- esperada pelo nucleo SHA-256.
    process(clk, rst) begin
        if rst = '1' then
            chunk_full <= (others => '0');
            part_count <= (others => '0');
        elsif rising_edge(clk) then
            if c_capture = '1' then
                case part_count is
                    when "00"   => chunk_full(511 downto 384) <= chunk_part;
                    when "01"   => chunk_full(383 downto 256) <= chunk_part;
                    when "10"   => chunk_full(255 downto 128) <= chunk_part;
                    when others => chunk_full(127 downto 0)   <= chunk_part;
                end case;
                -- Avanca para a proxima fatia (volta a 0 automaticamente apos a quarta)
                part_count <= part_count + 1;
            end if;
        end if;
    end process;

    -- Instancia o nucleo SHA-256 (top-level original) ja com o bloco completo de 512 bits.
    -- O reset assincrono e os demais sinais sao propagados igual ao projeto original.
    sha256_core: entity work.sha256 port map(
        clk => clk, rst => rst, rdy => core_rdy, fin => core_fin,
        chunk => chunk_full, h_in => h_in, h_out => h_out
    );

end architecture;
