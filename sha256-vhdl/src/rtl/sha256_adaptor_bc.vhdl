library ieee;
use ieee.std_logic_1164.all;
use work.sha256_pkg.all;

entity sha256_adaptor_bc is
    port(
        clk, rst, rdy, parts_last, core_fin : in  std_logic;
        c_capture, core_rdy, fin            : out std_logic
    );
end entity;

architecture sha256_adaptor_bc_arch of sha256_adaptor_bc is
    type ADAPTOR_STATE is (A_IDLE, A_CAP, A_HOLD, A_START, A_BUSY, A_FIN);
    signal state, next_state : ADAPTOR_STATE := A_IDLE;
begin

    -- Processo Síncrono
    process(clk, rst) begin
        if rst = '1' then
            state <= A_IDLE;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    -- Processo Combinacional
    process(state, rdy, parts_last, core_fin) begin
        case state is

            -- Aguarda o pulso de pronto para capturar a próxima fatia
            when A_IDLE => if rdy = '1' then
                    next_state <= A_CAP;
                else
                    next_state <= A_IDLE;
                end if;

            -- Após capturar: se era a última fatia inicia o núcleo, senão espera o rdy abaixar
            when A_CAP => if parts_last = '1' then
                    next_state <= A_START;
                else
                    next_state <= A_HOLD;
                end if;

            -- Espera o rdy retornar a '0' para não capturar a mesma fatia duas vezes
            when A_HOLD => if rdy = '0' then
                    next_state <= A_IDLE;
                else
                    next_state <= A_HOLD;
                end if;

            -- Pulso único de rdy para o núcleo SHA-256
            when A_START => next_state <= A_BUSY;

            -- Permanece ocupado até o núcleo sinalizar fim do cálculo
            when A_BUSY => if core_fin = '1' then
                    next_state <= A_FIN;
                else
                    next_state <= A_BUSY;
                end if;

            -- Conclusão. No próximo ciclo volta a esperar uma nova mensagem
            when A_FIN => next_state <= A_IDLE;

        end case;
    end process;

    c_capture <= '1' when state = A_CAP   else '0';
    core_rdy  <= '1' when state = A_START else '0';
    fin       <= '1' when state = A_FIN   else '0';

end architecture;
