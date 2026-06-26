library ieee;
use ieee.std_logic_1164.all;
use work.sha256_pkg.all;

-- Base de Controle do Adaptador: FSM que recebe a mensagem em fatias de 128 bits,
-- acumula em um estado interno de 512 bits e, quando cheio, dispara o nucleo SHA-256.
entity sha256_adaptor_bc is
    port(
        -- Sincronismo, gatilho externo (rdy), status do contador de fatias (parts_last)
        -- e sinal de conclusao vindo do nucleo SHA-256 interno (core_fin)
        clk, rst, rdy, parts_last, core_fin : in  std_logic;
        -- Comandos para o datapath do adaptador e finalizacao externa (fin)
        c_capture, core_rdy, fin            : out std_logic
    );
end entity;

architecture sha256_adaptor_bc_arch of sha256_adaptor_bc is
    -- Estados da maquina de controle do adaptador:
    --   A_IDLE  : aguarda o pulso de rdy para receber uma fatia
    --   A_CAP   : captura a fatia de 128 bits atual no estado interno
    --   A_HOLD  : aguarda o rdy retornar a '0' antes de aceitar a proxima fatia
    --   A_START : pulsa o rdy do nucleo SHA-256 (bloco de 512 bits ja montado)
    --   A_BUSY  : aguarda o nucleo SHA-256 terminar o calculo
    --   A_FIN   : sinaliza a conclusao para o mundo externo
    type ADAPTOR_STATE is (A_IDLE, A_CAP, A_HOLD, A_START, A_BUSY, A_FIN);
    signal state, next_state : ADAPTOR_STATE := A_IDLE;
begin

    -- Processo Sincrono: atualiza o estado atual a cada subida de clock
    process(clk, rst) begin
        if rst = '1' then
            state <= A_IDLE; -- Reset assincrono retorna ao repouso
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    -- Processo Combinacional: define as regras de transicao de estado
    process(state, rdy, parts_last, core_fin) begin
        case state is

            -- Aguarda o pulso de pronto para capturar a proxima fatia
            when A_IDLE => if rdy = '1' then
                    next_state <= A_CAP;
                else
                    next_state <= A_IDLE;
                end if;

            -- Apos capturar: se era a ultima fatia inicia o nucleo, senao espera o rdy abaixar
            when A_CAP => if parts_last = '1' then
                    next_state <= A_START;
                else
                    next_state <= A_HOLD;
                end if;

            -- Espera o rdy retornar a '0' para nao capturar a mesma fatia duas vezes
            when A_HOLD => if rdy = '0' then
                    next_state <= A_IDLE;
                else
                    next_state <= A_HOLD;
                end if;

            -- Pulso unico de rdy para o nucleo SHA-256
            when A_START => next_state <= A_BUSY;

            -- Permanece ocupado ate o nucleo sinalizar fim do calculo
            when A_BUSY => if core_fin = '1' then
                    next_state <= A_FIN;
                else
                    next_state <= A_BUSY;
                end if;

            -- Conclusao. No proximo ciclo volta a esperar uma nova mensagem
            when A_FIN => next_state <= A_IDLE;

        end case;
    end process;

    -- Logica de Saida (Maquina de Moore): comandos baseados apenas no estado atual
    c_capture <= '1' when state = A_CAP   else '0'; -- Carrega a fatia atual no estado interno
    core_rdy  <= '1' when state = A_START else '0'; -- Dispara o nucleo SHA-256
    fin       <= '1' when state = A_FIN   else '0'; -- Avisa o exterior que o hash terminou

end architecture;
