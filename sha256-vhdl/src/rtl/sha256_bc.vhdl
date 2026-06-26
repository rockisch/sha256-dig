library ieee;
use ieee.std_logic_1164.all;
use work.sha256_pkg.all;

-- Base de Controle: Máquina de Estados Finitos (FSM) que orquestra o algoritmo
entity sha256_bc is
    port(
        -- Entradas de controle e status vindos do contador (o_loop_last)
        clk, rst, rdy, o_loop_last : in std_logic;
        -- Saídas de comando para a Base Operativa (prefixo 'c_') e finalização ('fin')
        fin, c_init, c_loop_sched, c_loop_comp, c_done : out std_logic
    );
end entity;

architecture sha256_bc_arch of sha256_bc is
    -- Sinais para armazenar o estado atual e o próximo estado da máquina
    signal state, next_state : FSM_STATE := S_IDLE;
begin

    -- Processo Síncrono: Atualiza o estado atual a cada subida de clock
    process(clk, rst) begin
        if rst = '1' then
            state <= S_IDLE; -- Retorna ao repouso caso o botão de reset seja apertado
        elsif rising_edge(clk) then
            state <= next_state; -- Avança para a etapa seguinte
        end if;
    end process;

    -- Processo Combinacional: Define as regras de mudança de estado (para onde ir)
    process(state, rdy, o_loop_last) begin
        case state is

            when S_IDLE => if rdy = '1' then
                    next_state <= S_INIT;
                else
                    next_state <= S_IDLE;
                end if;

            when S_INIT => next_state <= S_SCHED;

            when S_SCHED => if o_loop_last = '1' then
                    next_state <= S_COMP;
                else
                    next_state <= S_SCHED;
                end if;

            when S_COMP => if o_loop_last = '1' then
                    next_state <= S_DONE;
                else
                    next_state <= S_COMP;
                end if;

            when S_DONE => next_state <= S_IDLE;

            when others => next_state <= S_IDLE;

        end case;
    end process;

    -- Lógica de Saída (Máquina de Moore): Ativa os comandos apenas baseado no estado em que está
    c_init       <= '1' when state = S_INIT else '0';
    c_loop_sched <= '1' when state = S_SCHED else '0';
    c_loop_comp  <= '1' when state = S_COMP else '0';
    c_done       <= '1' when state = S_DONE else '0';
    fin          <= '1' when state = S_DONE else '0'; -- Avisa quem está fora do chip que o cálculo acabou

end architecture;
