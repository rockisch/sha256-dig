library ieee;
use ieee.std_logic_1164.all;
use work.sha256_pkg.all;

entity sha256_bc is
    port(
        clk, rst, rdy, o_loop_last : in std_logic;
        fin : out std_logic;
        -- Saídas de comando para o Bloco Operativo
        c_init, c_done, c_r1, c_r2 : out std_logic
    );
end entity;

architecture sha256_bc_arch of sha256_bc is
    signal state, next_state : FSM_STATE := S_IDLE;
begin

    -- Processo Síncrono
    process(clk, rst) begin
        if rst = '1' then
            state <= S_IDLE;
        elsif rising_edge(clk) then
            state <= next_state;
        end if;
    end process;

    -- Processo Combinacional
    process(state, rdy, o_loop_last) begin
        case state is

            when S_IDLE => if rdy = '1' then
                    next_state <= S_INIT;
                else
                    next_state <= S_IDLE;
                end if;

            when S_INIT => next_state <= S_R1;

            when S_R1 => next_state <= S_R2;

            -- Fim de uma rodada: após 64 rodadas (contador estoura) vai para S_DONE
            when S_R2 => if o_loop_last = '1' then
                    next_state <= S_DONE;
                else
                    next_state <= S_R1;
                end if;

            when S_DONE => next_state <= S_IDLE;

            when others => next_state <= S_IDLE;

        end case;
    end process;

    c_init <= '1' when state = S_INIT else '0';
    c_r1   <= '1' when state = S_R1   else '0';
    c_r2   <= '1' when state = S_R2   else '0';
    c_done <= '1' when state = S_DONE else '0';
    fin    <= '1' when state = S_DONE else '0';

end architecture;
