library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.finish;
use work.sha256_pkg.all;

-- Entidade de teste (Testbench). Não possui portas pois é o topo da hierarquia de simulação.
entity sha256_tb is
end entity;

architecture sha256_tb_arch of sha256_tb is
    -- Sinais internos para estimular e monitorar o módulo principal (DUT)
    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal rdy      : std_logic := '0';
    signal fin      : std_logic := '0';
    signal chunk_in : std_logic_vector(511 downto 0) := (others => '0');
    
    -- Valores iniciais padronizados dos registradores do SHA-256
    signal h_in     : H_TYPE := (
        X"6a09e667", X"bb67ae85", X"3c6ef372", X"a54ff53a",
        X"510e527f", X"9b05688c", X"1f83d9ab", X"5be0cd19"
    );
    signal h_out    : H_TYPE := (others => (others => '0'));

    -- Função para aplicar o preenchimento (padding) obrigatório do SHA-256:
    -- Adiciona o bit '1', preenche com zeros e insere o tamanho original no final.
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
    dut: entity work.sha256 port map (
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
        report "================================================================";
        report "RESULTADO DO HASH SHA-256 DA PALAVRA 'abc':";
        report to_hstring(h_out(0)) & to_hstring(h_out(1)) & 
               to_hstring(h_out(2)) & to_hstring(h_out(3)) & 
               to_hstring(h_out(4)) & to_hstring(h_out(5)) & 
               to_hstring(h_out(6)) & to_hstring(h_out(7));
        report "================================================================";
        
        -- Encerra a simulação
        finish;
    end process stimulus;
end architecture;
