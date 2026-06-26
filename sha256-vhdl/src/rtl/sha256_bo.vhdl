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
        c_sched1, c_sched2, c_sched3 : in std_logic;
        c_comp1, c_comp2, c_comp3, c_comp4 : in std_logic
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

    -- Memória para armazenamento das 64 palavras expandidas
    signal W : K_TYPE := (others => X"00000000");
    signal loop_count : unsigned(5 downto 0);
begin

    -- Instanciação do módulo contador para controle de iterações
    -- O contador só avança no último subestado de cada iteração (sched3/comp4),
    -- mantendo loop_count estável durante o cálculo das variáveis temporárias.
    COUNTER: entity work.counter64 port map(clk => clk, rst => rst or c_init, value => loop_count, overflow => o_loop_last, increase => c_sched3 or c_comp4);

    -- Algoritmo e nomes de variáveis baseados no pseudocódigo da página do SHA-2
    -- na Wikipédia:
    -- https://en.wikipedia.org/wiki/SHA-2#Pseudocode
    process(clk, rst)
        -- Variáveis que persistem entre clocks
        variable a, b, c, d, e, f, g, h : std_logic_vector(31 downto 0);
        variable s0_w, s1_w : std_logic_vector(31 downto 0);
        variable s1_big, ch, s0_big, maj : std_logic_vector(31 downto 0);
        variable kw : std_logic_vector(31 downto 0);
        variable temp1, temp2 : std_logic_vector(31 downto 0);

        -- Variáveis que não persistem entre clocks
        variable loop_i : integer;
        variable s0, s1 : std_logic_vector(31 downto 0);
    begin
        -- Lógica de reset assíncrono
        if rst = '1' then
            W <= (others => X"00000000");
            h_out <= (others => (others => '0'));
        elsif rising_edge(clk) then
            -- Divide o bloco de 512 bits e carrega o estado inicial
            if c_init = '1' then
                for i in 0 to 15 loop
                    W(i) <= chunk(511 - 32 * i downto 480 - 32 * i);
                end loop;
                a := h_in(0);
                b := h_in(1);
                c := h_in(2);
                d := h_in(3);
                e := h_in(4);
                f := h_in(5);
                g := h_in(6);
                h := h_in(7);

            -- s0 = sigma(W[i-15]); s0_w = s0 + W[i-16]
            elsif c_sched1 = '1' then
                loop_i := to_integer(loop_count);
                s0   := sha_ssig0(W(loop_i - 15));
                s0_w := std_logic_vector(unsigned(s0) + unsigned(W(loop_i - 16)));

            -- s1 = sigma(W[i-2]); s1_w = s1 + W[i-7]
            elsif c_sched2 = '1' then
                loop_i := to_integer(loop_count);
                s1   := sha_ssig1(W(loop_i - 2));
                s1_w := std_logic_vector(unsigned(s1) + unsigned(W(loop_i - 7)));

            -- w[i] = (s0 + w[i-16) + (s1 + w[i-7])
            elsif c_sched3 = '1' then
                loop_i := to_integer(loop_count);
                W(loop_i) <= std_logic_vector(unsigned(s0_w) + unsigned(s1_w));

            -- Valores intermediários baratos; kw = k[i]+w[i]
            elsif c_comp1 = '1' then
                loop_i := to_integer(loop_count);
                s1_big := sha_bsig1(e);     -- S1  = (e ror 6) xor (e ror 11) xor (e ror 25)
                ch     := sha_ch(e, f, g);  -- ch  = (e and f) xor ((not e) and g)
                s0_big := sha_bsig0(a);     -- S0  = (a ror 2) xor (a ror 13) xor (a ror 22)
                maj    := sha_maj(a, b, c); -- maj = (a and b) xor (a and c) xor (b and c)
                kw     := std_logic_vector(unsigned(K(loop_i)) + unsigned(W(loop_i)));

            -- temp1 = h + S1 + ch + kw
            elsif c_comp2 = '1' then
                temp1 := std_logic_vector(unsigned(h) + unsigned(s1_big) + unsigned(ch) + unsigned(kw));

            -- temp2 = S0 + maj
            elsif c_comp3 = '1' then
                temp2 := std_logic_vector(unsigned(s0_big) + unsigned(maj));

            -- Atualiza os registradores de estado
            elsif c_comp4 = '1' then
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
