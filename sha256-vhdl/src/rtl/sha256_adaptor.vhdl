library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_pkg.all;

-- Adaptador de entrada: a placa não aceita tantos bits de entrada por vez, então a
-- mensagem chega em 4 fatias de 128 bits e o estado inicial do hash chega em 4 fatias
-- de 64 bits. O adaptador acumula as fatias em estados internos de 512 e 256 bits e,
-- quando estão cheios, aciona o núcleo SHA-256.
entity sha256_adaptor is
    port(
        clk, rst, rdy : in std_logic;
        fin           : out std_logic;
        chunk_part    : in std_logic_vector(127 downto 0); -- Fatia de entrada da mensagem (128 bits)
        h_in_part     : in std_logic_vector(63 downto 0);  -- Fatia de entrada do estado do hash (64 bits)
        h_out         : out H_TYPE                         -- Saída com o próximo estado do hash (256 bits)
    );
end entity;

architecture sha256_adaptor_arch of sha256_adaptor is
    -- Estado interno de 512 bits da mensagem, montado a partir das 4 fatias de 128 bits
    signal chunk_full : std_logic_vector(511 downto 0) := (others => '0');
    -- Estado interno de 256 bits do hash inicial, montado a partir das 4 fatias de 64 bits
    signal h_in_full  : H_TYPE := (others => (others => '0'));
    -- Contador de qual fatia está sendo recebida (0 a 3)
    signal part_count : unsigned(1 downto 0) := (others => '0');

    signal c_capture, core_rdy, core_fin, parts_last : std_logic;
begin

    -- Indica que a fatia capturada agora (índice 3) é a última do bloco de 512 bits
    parts_last <= '1' when part_count = "11" else '0';

    adaptor_bc: entity work.sha256_adaptor_bc port map(
        clk => clk, rst => rst, rdy => rdy,
        parts_last => parts_last, core_fin => core_fin,
        c_capture => c_capture, core_rdy => core_rdy, fin => fin
    );

    process(clk, rst) begin
        if rst = '1' then
            chunk_full <= (others => '0');
            h_in_full  <= (others => (others => '0'));
            part_count <= (others => '0');
        elsif rising_edge(clk) then
            if c_capture = '1' then
                case part_count is
                    when "00" =>
                        chunk_full(511 downto 384) <= chunk_part;
                        h_in_full(0) <= h_in_part(63 downto 32);
                        h_in_full(1) <= h_in_part(31 downto 0);
                    when "01" =>
                        chunk_full(383 downto 256) <= chunk_part;
                        h_in_full(2) <= h_in_part(63 downto 32);
                        h_in_full(3) <= h_in_part(31 downto 0);
                    when "10" =>
                        chunk_full(255 downto 128) <= chunk_part;
                        h_in_full(4) <= h_in_part(63 downto 32);
                        h_in_full(5) <= h_in_part(31 downto 0);
                    when others =>
                        chunk_full(127 downto 0) <= chunk_part;
                        h_in_full(6) <= h_in_part(63 downto 32);
                        h_in_full(7) <= h_in_part(31 downto 0);
                end case;
                -- Avança para a próxima fatia (volta a 0 automaticamente após a quarta)
                part_count <= part_count + 1;
            end if;
        end if;
    end process;

    -- Instancia o núcleo SHA-256 (top-level original) já com os estados completos.
    -- O reset assíncrono e os demais sinais são propagados igual ao projeto original.
    sha256_core: entity work.sha256 port map(
        clk => clk, rst => rst, rdy => core_rdy, fin => core_fin,
        chunk => chunk_full, h_in => h_in_full, h_out => h_out
    );

end architecture;
