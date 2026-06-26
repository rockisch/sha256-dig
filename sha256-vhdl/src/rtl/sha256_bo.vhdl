library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_pkg.all;

-- Unidade de processamento de dados (Datapath) do SHA-256
entity sha256_bo is
    port(
        clk, rst    : in std_logic;
        chunk       : in std_logic_vector(511 downto 0);
        h_in        : in H_TYPE;
        h_out       : out H_TYPE;
        o_loop_last : out std_logic;
        c_init, c_done : in std_logic;
        c_r1, c_r2 : in std_logic
    );
end entity;

architecture sha256_bo_arch of sha256_bo is
    -- Constantes fixas de 32 bits do algoritmo SHA-256
    constant K : K_TYPE := (
        X"428a2f98", X"71374491", X"b5c0fbcf", X"e9b5dba5", X"3956c25b", X"59f111f1", X"923f82a4", X"ab1c5ed5",
        X"d807aa98", X"12835b01", X"243185be", X"550c7dc3", X"72be5d74", X"80deb1fe", X"9bdc06a7", X"c19bf174",
        X"e49b69c1", X"efbe4786", X"0fc19dc6", X"240ca1cc", X"2de92c6f", X"4a7484aa", X"5cb0a9dc", X"76f988da",
        X"983e5152", X"a831c66d", X"b00327c8", X"bf597fc7", X"c6e00bf3", X"d5a79147", X"06ca6351", X"14292967",
        X"27b70a85", X"2e1b2138", X"4d2c6dfc", X"53380d13", X"650a7354", X"766a0abb", X"81c2c92e", X"92722c85",
        X"a2bfe8a1", X"a81a664b", X"c24b8b70", X"c76c51a3", X"d192e819", X"d6990624", X"f40e3585", X"106aa070",
        X"19a4c116", X"1e376c08", X"2748774c", X"34b0bcb5", X"391c0cb3", X"4ed8aa4a", X"5b9cca4f", X"682e6ff3",
        X"748f82ee", X"78a5636f", X"84c87814", X"8cc70208", X"90befffa", X"a4506ceb", X"bef9a3f7", X"c67178f2"
    );

    -- 'Sliding window' de 16 palavras do message schedule.
    -- Enquanto o algorítmo padrão inicializa os 64 valores no começo, ele
    -- precisaria de um mux de 64:1.
    signal W : W_TYPE := (others => X"00000000");
    signal loop_count : unsigned(5 downto 0);
begin

    -- Counter até 64
    COUNTER: entity work.counter64 port map(
        clk => clk, rst => rst or c_init, value => loop_count,
        overflow => o_loop_last, increase => c_r2
    );

    -- Algoritmo e nomes de variáveis baseados no pseudocódigo da página do SHA-2
    -- na Wikipédia:
    -- https://en.wikipedia.org/wiki/SHA-2#Pseudocode
    process(clk, rst)
        -- Registradores de trabalho internos para os cálculos
        variable a, b, c, d, e, f, g, h : std_logic_vector(31 downto 0);
        -- Valor W temporário (wt), soma parcial de temp1 (temp1_part)
        variable wt, temp1_part, temp1, temp2 : std_logic_vector(31 downto 0);
        -- Índice da rodada atual, derivado do contador
        variable loop_i : integer;

        -- Essas variáveis são só combinatórias (calculadas e usadas no mesmo ciclo):
        -- as funções small/big sigma, ch e maj que alimentam wt, temp1_part e temp2
        variable s0, s1, s0_big, s1_big, ch, maj : std_logic_vector(31 downto 0);
    begin
        -- Lógica de reset assíncrono
        if rst = '1' then
            W <= (others => X"00000000");
            h_out <= (others => (others => '0'));

        elsif rising_edge(clk) then

            -- Estado de inicialização: carrega o estado inicial e as 16 palavras
            -- da mensagem na janela (a primeira palavra ocupa a posição mais antiga)
            if c_init = '1' then
                for j in 0 to 15 loop
                    W(j) <= chunk(511 - 32 * j downto 480 - 32 * j);
                end loop;
                a := h_in(0);
                b := h_in(1);
                c := h_in(2);
                d := h_in(3);
                e := h_in(4);
                f := h_in(5);
                g := h_in(6);
                h := h_in(7);

            -- Rodada, subestado 1: calcula a palavra do schedule (wt) e as somas
            -- parciais que não dependem de wt (temp1_part e temp2); depois desloca a janela.
            elsif c_r1 = '1' then
                loop_i := to_integer(loop_count);

                -- Funções auxiliares combinatórias (small sigma, big sigma, ch e maj)
                s0     := sha_ssig0(W(1));
                s1     := sha_ssig1(W(14));
                s0_big := sha_bsig0(a);
                s1_big := sha_bsig1(e);
                ch     := sha_ch(e, f, g);
                maj    := sha_maj(a, b, c);

                -- Nas 16 primeiras rodadas a palavra vem direto da mensagem (W(0));
                -- a partir daí ela é a recorrência do message schedule, lida em
                -- posições fixas da janela (W(0)=i-16, W(1)=i-15, W(9)=i-7, W(14)=i-2).
                if loop_count < 16 then
                    wt := W(0);
                else
                    wt := std_logic_vector(unsigned(W(0)) + unsigned(s0) + unsigned(W(9)) + unsigned(s1));
                end if;

                -- Parte de temp1 que independe de wt e a soma temp2 (4 e 2 operandos)
                temp1_part := std_logic_vector(unsigned(h) + unsigned(s1_big) + unsigned(ch) + unsigned(K(loop_i)));
                temp2  := std_logic_vector(unsigned(s0_big) + unsigned(maj));

                -- Desloca a janela uma posição e insere a palavra atual no fim
                for j in 0 to 14 loop
                    W(j) <= W(j + 1);
                end loop;
                W(15) <= wt;

            -- Rodada, subestado 2: completa temp1 (= temp1_part + wt) e atualiza os
            -- registradores de estado. A soma de temp1 e a cadeia de atualização
            -- cabem no mesmo ciclo sem ultrapassar o caminho crítico do subestado 1.
            elsif c_r2 = '1' then
                temp1 := std_logic_vector(unsigned(temp1_part) + unsigned(wt));
                h := g;
                g := f;
                f := e;
                e := std_logic_vector(unsigned(d) + unsigned(temp1));
                d := c;
                c := b;
                b := a;
                a := std_logic_vector(unsigned(temp1) + unsigned(temp2));

            -- Estado final: soma o resultado processado ao valor anterior do hash
            elsif c_done = '1' then
                h_out(0) <= std_logic_vector(unsigned(h_in(0)) + unsigned(a));
                h_out(1) <= std_logic_vector(unsigned(h_in(1)) + unsigned(b));
                h_out(2) <= std_logic_vector(unsigned(h_in(2)) + unsigned(c));
                h_out(3) <= std_logic_vector(unsigned(h_in(3)) + unsigned(d));
                h_out(4) <= std_logic_vector(unsigned(h_in(4)) + unsigned(e));
                h_out(5) <= std_logic_vector(unsigned(h_in(5)) + unsigned(f));
                h_out(6) <= std_logic_vector(unsigned(h_in(6)) + unsigned(g));
                h_out(7) <= std_logic_vector(unsigned(h_in(7)) + unsigned(h));
            end if;

        end if;
    end process;
end architecture;
