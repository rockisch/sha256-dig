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
    constant H_INIT   : H_TYPE := (
        X"6a09e667", X"bb67ae85", X"3c6ef372", X"a54ff53a",
        X"510e527f", X"9b05688c", X"1f83d9ab", X"5be0cd19"
    );
    signal h_out      : H_TYPE := (others => (others => '0'));

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

    -- Função de padding obrigatório do SHA-256: adiciona o bit '1', preenche com
    -- zeros e insere o tamanho original (em bits) ao final do bloco de 512 bits.
    -- 'length' é a quantidade de bytes de dados neste bloco final; 'total_length'
    -- é o tamanho total da mensagem em bytes, usado no campo de comprimento. Para
    -- mensagens de um único bloco os dois coincidem, por isso 'total_length' assume
    -- 'length' por padrão; em mensagens de vários blocos é preciso informar o total.
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

    -- Processo de estímulo: envia blocos de 512 bits em 4 fatias e valida o hash
    stimulus: process
        variable full_chunk : std_logic_vector(511 downto 0) := (others => '0');

        -- Envia um bloco de 512 bits (chunk) junto do estado inicial do hash (st)
        -- em 4 fatias, da mais significativa para a menos: a cada pulso de rdy vão
        -- juntas uma fatia de 128 bits da mensagem e uma fatia de 64 bits (duas
        -- palavras) do estado. Em seguida aguarda o adaptador sinalizar a conclusão.
        procedure send_block(chunk : std_logic_vector(511 downto 0); st : H_TYPE) is
        begin
            for i in 0 to 3 loop
                chunk_part <= chunk(511 - 128*i downto 384 - 128*i);
                h_in_part  <= st(2*i) & st(2*i + 1);
                wait for 2 ns;

                rdy <= '1';
                wait for 2 ns;
                rdy <= '0';
                wait for 2 ns;
            end loop;

            -- Pausa até o adaptador sinalizar a conclusão do hash do bloco
            wait until fin = '1';

            -- Aguarda a propagação dos dados nos registradores de saída
            wait for 5 ns;
        end procedure;

        -- Estado intermediário do hash, reaproveitado entre os blocos da mensagem
        variable mid_state : H_TYPE;
    begin
        wait for 4 ns;

        -- ============================================================
        -- Primeiro teste: mensagem de um bloco ("abc")
        -- ============================================================
        full_chunk := (others => '0');
        full_chunk(511 downto 511-23) := get_string_vector("abc");
        full_chunk := get_final_chunk(3, full_chunk);
        send_block(full_chunk, H_INIT);

        report LF & "message: abc" & LF & "hash: " &
               to_hstring(h_out(0)) & to_hstring(h_out(1)) &
               to_hstring(h_out(2)) & to_hstring(h_out(3)) &
               to_hstring(h_out(4)) & to_hstring(h_out(5)) &
               to_hstring(h_out(6)) & to_hstring(h_out(7));

        assert h_out = ABC_EXPECTED
            report "FALHA: hash de 'abc' diferente do esperado!"
            severity failure;

        -- ============================================================
        -- Segundo teste: mensagem de dois blocos ('lorem ipsum')
        -- ============================================================
        -- Primeiro bloco: os 64 primeiros bytes da mensagem entram crus, sem
        -- padding, partindo do estado inicial padrão do hash.
        full_chunk := get_string_vector(LOREM(1 to 64));
        send_block(full_chunk, H_INIT);

        -- Encadeia os blocos: o hash intermediário deste bloco vira o estado
        -- inicial do bloco seguinte.
        mid_state := h_out;

        -- Segundo (e último) bloco: posiciona os bytes restantes no topo e aplica
        -- o padding final informando o tamanho TOTAL da mensagem ('LOREM'length).
        full_chunk := (others => '0');
        full_chunk(511 downto 512 - LOREM_REMAIN * 8) := get_string_vector(LOREM(65 to LOREM'length));
        full_chunk := get_final_chunk(LOREM_REMAIN, full_chunk, LOREM'length);
        send_block(full_chunk, mid_state);

        report LF & "message: " & LOREM & LF & "hash: " &
               to_hstring(h_out(0)) & to_hstring(h_out(1)) &
               to_hstring(h_out(2)) & to_hstring(h_out(3)) &
               to_hstring(h_out(4)) & to_hstring(h_out(5)) &
               to_hstring(h_out(6)) & to_hstring(h_out(7));

        assert h_out = LOREM_EXPECTED
            report "FALHA: hash de dois blocos diferente do esperado!"
            severity failure;

        -- Encerra a simulação
        finish;
    end process stimulus;
end architecture;
