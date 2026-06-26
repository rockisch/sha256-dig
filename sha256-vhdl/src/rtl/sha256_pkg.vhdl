library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Pacote de tipos e funções fundamentais do algoritmo SHA-256
package sha256_pkg is
    -- Tipos de dados customizados (arrays de 32 bits)
    type H_TYPE is array (0 to 7) of std_logic_vector(31 downto 0);  -- 8 registradores de estado do hash
    type W_TYPE is array (0 to 15) of std_logic_vector(31 downto 0); -- 16 palavras iniciais do bloco de mensagem
    type K_TYPE is array (0 to 63) of std_logic_vector(31 downto 0); -- 64 constantes da rodada de compressão

    -- Estados da máquina de controle (FSM)
    -- As etapas de agendamento e compressão são divididas em 3 subestados cada:
    -- os dois primeiros calculam variáveis temporárias (s0/s1 e temp1/temp2)
    -- e o terceiro aplica essas variáveis nos cálculos e atribuições finais.
    type FSM_STATE is (
        S_IDLE, S_INIT,
        S_SCHED1, S_SCHED2, S_SCHED3,
        S_COMP1, S_COMP2, S_COMP3, S_COMP4,
        S_DONE
    );

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
