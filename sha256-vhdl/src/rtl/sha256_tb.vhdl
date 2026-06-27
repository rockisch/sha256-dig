library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;
use work.sha256_pkg.all;

entity sha256_tb is
end entity;

architecture sha256_tb_arch of sha256_tb is
    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal rdy      : std_logic := '0';
    signal fin      : std_logic := '0';
    signal chunk_in : std_logic_vector(511 downto 0) := (others => '0');

    -- Valores iniciais padronizados dos registradores do SHA-256
    constant H_INIT : H_TYPE := (
        X"6a09e667", X"bb67ae85", X"3c6ef372", X"a54ff53a",
        X"510e527f", X"9b05688c", X"1f83d9ab", X"5be0cd19"
    );
    signal h_in     : H_TYPE := H_INIT;
    signal h_out    : H_TYPE := (others => (others => '0'));

    -- Hash SHA-256 esperado para a palavra "abc"
    constant ABC_EXPECTED : H_TYPE := (
        X"ba7816bf", X"8f01cfea", X"414140de", X"5dae2223",
        X"b00361a3", X"96177a9c", X"b410ff61", X"f20015ad"
    );

    -- Mensagem de teste de dois blocos (78 bytes): exercita o encadeamento de
    -- chunks usando o h_out de um bloco como h_in do bloco seguinte. Os primeiros
    -- 64 bytes formam o primeiro bloco; os 14 restantes recebem o padding final.
    constant LOREM        : string  := "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor";
    constant LOREM_REMAIN : integer := LOREM'length - 64;

    -- Hash SHA-256 esperado para a mensagem LOREM
    constant LOREM_EXPECTED : H_TYPE := (
        X"1c3f958a", X"bd85c549", X"05c97fe8", X"e0628fe7",
        X"64957119", X"62a27daa", X"e3403378", X"1486da00"
    );

    -- Função para aplicar o preenchimento (padding) obrigatório do SHA-256:
    -- Adiciona o bit '1', preenche com zeros e insere o tamanho original no final.
    function get_final_chunk(length : integer; chunk : std_logic_vector(511 downto 0);
                             total_length : integer := -1) return std_logic_vector is
        variable result : std_logic_vector(511 downto 0);
        variable total  : integer;
    begin
        if total_length < 0 then
            total := length;
        else
            total := total_length;
        end if;
        result := (others => '0');
        result(511 - (length * 8)) := '1';
        result(31 downto 0) := std_logic_vector(to_unsigned(total * 8, 32));
        if length > 0 then
            result(511 downto 512 - length * 8) := chunk(511 downto 512 - length * 8);
        end if;
        return result;
    end function;

    -- Função auxiliar para converter caracteres de texto (string) para vetores binários (ASCII)
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
    -- Geração do sinal de clock (alterna a cada 1 ns, período total de 2 ns)
    clk <= not clk after 1 ns;

    -- Geração do pulso de reset (inicia em '1' e vai para '0' após 2 ns)
    rst <= '1', '0' after 2 ns;

    -- Instanciação do módulo criptográfico principal (Device Under Test)
    dut: entity work.sha256 port map(
        clk => clk, rst => rst, rdy => rdy, fin => fin,
        chunk => chunk_in, h_in => h_in, h_out => h_out
    );

    -- Processo de estímulo: injeta os dados de teste e controla a simulação
    stimulus: process begin
        wait for 4 ns;

        -- Carrega a string "abc" no início do bloco de dados
        chunk_in(511 downto 511-23) <= get_string_vector("abc");
        wait for 2 ns;

        -- Aplica a formatação de padding no bloco
        chunk_in <= get_final_chunk(3, chunk_in);
        wait for 2 ns;

        -- Envia o pulso de 'ready' para a FSM iniciar o processamento
        rdy <= '1';
        wait for 2 ns;
        rdy <= '0';

        -- Pausa a execução do testbench até que o sinal 'fin' indique a conclusão
        wait until fin = '1';

        -- Aguarda tempo adicional para garantir a propagação dos dados nos registradores de saída
        wait for 5 ns;

        -- Imprime o resultado final formatado em hexadecimal no console do simulador
        report LF & "message: abc" & LF & "hash: " &
               to_hstring(h_out(0)) & to_hstring(h_out(1)) &
               to_hstring(h_out(2)) & to_hstring(h_out(3)) &
               to_hstring(h_out(4)) & to_hstring(h_out(5)) &
               to_hstring(h_out(6)) & to_hstring(h_out(7));

        -- Valida que o hash calculado bate com o valor esperado
        assert h_out = ABC_EXPECTED
            report "FALHA: hash de 'abc' diferente do esperado!"
            severity failure;

        -- ============================================================
        -- Segundo teste: mensagem de dois blocos ('lorem ipsum')
        -- ============================================================
        -- Reinicia o estado do hash para os valores iniciais padrão antes de
        -- processar o primeiro bloco da mensagem.
        h_in <= H_INIT;
        wait for 2 ns;

        -- Primeiro bloco: os 64 primeiros bytes da mensagem entram crus, sem
        -- padding, pois ainda há mais dados a processar.
        chunk_in <= get_string_vector(LOREM(1 to 64));
        wait for 2 ns;

        rdy <= '1';
        wait for 2 ns;
        rdy <= '0';

        wait until fin = '1';
        wait for 5 ns;

        -- Encadeia os blocos: o hash intermediário (h_out) deste bloco vira o
        -- estado inicial (h_in) do bloco seguinte.
        h_in <= h_out;
        wait for 2 ns;

        -- Segundo (e último) bloco: posiciona os bytes restantes no topo e aplica
        -- o padding final informando o tamanho TOTAL da mensagem ('LOREM'length).
        chunk_in <= (others => '0');
        chunk_in(511 downto 512 - LOREM_REMAIN * 8) <= get_string_vector(LOREM(65 to LOREM'length));
        wait for 2 ns;
        chunk_in <= get_final_chunk(LOREM_REMAIN, chunk_in, LOREM'length);
        wait for 2 ns;

        rdy <= '1';
        wait for 2 ns;
        rdy <= '0';

        wait until fin = '1';
        wait for 5 ns;

        report LF & "message: " & LOREM & LF & "hash: " &
               to_hstring(h_out(0)) & to_hstring(h_out(1)) &
               to_hstring(h_out(2)) & to_hstring(h_out(3)) &
               to_hstring(h_out(4)) & to_hstring(h_out(5)) &
               to_hstring(h_out(6)) & to_hstring(h_out(7));

        -- Valida que o hash calculado bate com o valor esperado
        assert h_out = LOREM_EXPECTED
            report "FALHA: hash de dois blocos diferente do esperado!"
            severity failure;

        -- Encerra a simulação
        finish;
    end process stimulus;
end architecture;
