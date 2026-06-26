library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Pacote de tipos e funções fundamentais do algoritmo SHA-256
package sha256_pkg is
    -- Tipos de dados customizados (arrays de 32 bits)
    type H_TYPE is array (0 to 7) of std_logic_vector(31 downto 0);  -- 8 registradores de estado do hash
    type W_TYPE is array (0 to 15) of std_logic_vector(31 downto 0); -- Janela deslizante de 16 palavras do message schedule
    type K_TYPE is array (0 to 63) of std_logic_vector(31 downto 0); -- 64 constantes da rodada de compressão

    -- Estados da máquina de controle (FSM). Cada rodada é dividida em 2 subestados
    -- (S_R1/S_R2) para encurtar o caminho crítico da cadeia kt -> temp1 -> update:
    --   S_IDLE : repouso, aguarda o pulso de rdy
    --   S_INIT : carrega o estado inicial e a mensagem na janela
    --   S_R1   : palavra do schedule (kt), somas parciais t1part e temp2, desloca a janela
    --   S_R2   : temp1 = t1part + kt e atualização dos registradores de estado
    --   S_DONE : soma o resultado ao hash anterior e sinaliza o fim
    type FSM_STATE is (S_IDLE, S_INIT, S_R1, S_R2, S_DONE);

    -- Declaração das funções matemáticas não-lineares do algoritmo
    function sha_ch(x, y, z : std_logic_vector) return std_logic_vector;
    function sha_maj(x, y, z : std_logic_vector) return std_logic_vector;
    function sha_bsig0(x : std_logic_vector) return std_logic_vector;
    function sha_bsig1(x : std_logic_vector) return std_logic_vector;
    function sha_ssig0(x : std_logic_vector) return std_logic_vector;
    function sha_ssig1(x : std_logic_vector) return std_logic_vector;
end package;

package body sha256_pkg is
    -- Função Choice (Escolha)
    function sha_ch(x, y, z : std_logic_vector) return std_logic_vector is
    begin
        return (x and y) xor ((not x) and z);
    end function;

    -- Função Majority (Maioria)
    function sha_maj(x, y, z : std_logic_vector) return std_logic_vector is
    begin
        return (x and y) xor (x and z) xor (y and z);
    end function;

    -- Funções Big Sigma (utilizadas na etapa de compressão principal)
    function sha_bsig0(x : std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector((unsigned(x) ror 2) xor (unsigned(x) ror 13) xor (unsigned(x) ror 22));
    end function;

    function sha_bsig1(x : std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector((unsigned(x) ror 6) xor (unsigned(x) ror 11) xor (unsigned(x) ror 25));
    end function;

    -- Funções Small Sigma (utilizadas na etapa de expansão da mensagem)
    function sha_ssig0(x : std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector((unsigned(x) ror 7) xor (unsigned(x) ror 18) xor (unsigned(x) srl 3));
    end function;

    function sha_ssig1(x : std_logic_vector) return std_logic_vector is
    begin
        return std_logic_vector((unsigned(x) ror 17) xor (unsigned(x) ror 19) xor (unsigned(x) srl 10));
    end function;
end;
