library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;
use work.sha256_pkg.all;

-- Entidade de teste (Testbench) do adaptador. Sem portas pois é o topo da simulação.
entity sha256_adaptor_tb is
end entity;

architecture sha256_adaptor_tb_arch of sha256_adaptor_tb is
    -- Sinais internos para estimular e monitorar o adaptador (DUT)
    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal rdy        : std_logic := '0';
    signal fin        : std_logic := '0';
    signal chunk_part : std_logic_vector(127 downto 0) := (others => '0');
    signal h_in_part  : std_logic_vector(63 downto 0)  := (others => '0');

    -- Valores iniciais padronizados dos registradores do SHA-256 (referência local,
    -- enviada ao adaptador em 4 fatias de 64 bits)
    constant h_in     : H_TYPE := (
        X"6a09e667", X"bb67ae85", X"3c6ef372", X"a54ff53a",
        X"510e527f", X"9b05688c", X"1f83d9ab", X"5be0cd19"
    );
    signal h_out      : H_TYPE := (others => (others => '0'));

    -- Função de padding obrigatório do SHA-256: adiciona o bit '1', preenche com
    -- zeros e insere o tamanho original (em bits) ao final do bloco de 512 bits.
    function get_final_chunk(length : integer; chunk : std_logic_vector(511 downto 0)) return std_logic_vector is
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

    -- Função auxiliar para converter texto (string) em vetores binários (ASCII)
    function get_string_vector(s: string) return std_logic_vector is
        constant ss: string(1 to s'length) := s;
        variable answer: std_logic_vector(1 to 8 * s'length);
        variable p, c: integer;
    begin
        for i in ss'range loop
            p := 8 * i;
            c := character'pos(ss(i));
            answer(p - 7 to p) := std_logic_vector(to_unsigned(c,8));
        end loop;
        return answer;
    end function;

begin
    -- Geração do clock (alterna a cada 1 ns, período total de 2 ns)
    clk <= not clk after 1 ns;

    -- Geração do pulso de reset (inicia em '1' e vai para '0' após 2 ns)
    rst <= '1', '0' after 2 ns;

    -- Instanciação do adaptador (Device Under Test)
    dut: entity work.sha256_adaptor port map(
        clk => clk, rst => rst, rdy => rdy, fin => fin,
        chunk_part => chunk_part, h_in_part => h_in_part, h_out => h_out
    );

    -- Processo de estímulo: monta o bloco "abc" com padding e o envia em 4 fatias
    stimulus: process
        variable full_chunk : std_logic_vector(511 downto 0) := (others => '0');
    begin
        wait for 4 ns;

        -- Monta o bloco completo de 512 bits da palavra "abc" já com padding
        full_chunk := (others => '0');
        full_chunk(511 downto 511-23) := get_string_vector("abc");
        full_chunk := get_final_chunk(3, full_chunk);

        -- Envia as 4 fatias da mais significativa para a menos: a cada pulso de rdy
        -- vão juntas uma fatia de 128 bits da mensagem e uma fatia de 64 bits (duas
        -- palavras) do estado inicial do hash.
        for i in 0 to 3 loop
            chunk_part <= full_chunk(511 - 128*i downto 384 - 128*i);
            h_in_part  <= h_in(2*i) & h_in(2*i + 1);
            wait for 2 ns;

            rdy <= '1';
            wait for 2 ns;
            rdy <= '0';
            wait for 2 ns;
        end loop;

        -- Pausa até o adaptador sinalizar a conclusão do hash completo
        wait until fin = '1';

        -- Aguarda a propagação dos dados nos registradores de saída
        wait for 5 ns;

        -- Imprime o resultado final formatado em hexadecimal no console
        report "================================================================";
        report "RESULTADO DO HASH SHA-256 DA PALAVRA 'abc' (via adaptador 128b):";
        report to_hstring(h_out(0)) & to_hstring(h_out(1)) &
               to_hstring(h_out(2)) & to_hstring(h_out(3)) &
               to_hstring(h_out(4)) & to_hstring(h_out(5)) &
               to_hstring(h_out(6)) & to_hstring(h_out(7));
        report "================================================================";

        -- Encerra a simulação
        finish;
    end process stimulus;
end architecture;
