library ieee;
use ieee.std_logic_1164.all;
use work.sha256_pkg.all;

-- Base de Controle: Máquina de Estados Finitos (FSM) que orquestra o algoritmo
entity sha256_bc is
    port(
        -- Entradas de controle e status vindos do contador (o_loop_last)
        clk, rst, rdy, o_loop_last : in std_logic;
        -- Saídas de comando para a Base Operativa (prefixo 'c_') e finalização ('fin')
        fin, c_init, c_done : out std_logic;
        -- Comandos dos subestados de agendamento e compressão
        c_sched1, c_sched2, c_sched3 : out std_logic;
        c_comp1, c_comp2, c_comp3, c_comp4 : out std_logic
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

            when S_INIT => next_state <= S_SCHED1;

            -- Subestados de agendamento: calcula s0, depois s1 e por fim a palavra W
            when S_SCHED1 => next_state <= S_SCHED2;
            when S_SCHED2 => next_state <= S_SCHED3;
            when S_SCHED3 => if o_loop_last = '1' then
                    next_state <= S_COMP1;
                else
                    next_state <= S_SCHED1;
                end if;

            -- Subestados de compressão: calcula temp1, depois temp2 e por fim os registradores
            when S_COMP1 => next_state <= S_COMP2;
            when S_COMP2 => next_state <= S_COMP3;
            when S_COMP3 => next_state <= S_COMP4;
            when S_COMP4 => if o_loop_last = '1' then
                    next_state <= S_DONE;
                else
                    next_state <= S_COMP1;
                end if;

            when S_DONE => next_state <= S_IDLE;

            when others => next_state <= S_IDLE;

        end case;
    end process;

    -- Lógica de Saída (Máquina de Moore): Ativa os comandos apenas baseado no estado em que está
    c_init       <= '1' when state = S_INIT else '0';
    c_sched1     <= '1' when state = S_SCHED1 else '0';
    c_sched2     <= '1' when state = S_SCHED2 else '0';
    c_sched3     <= '1' when state = S_SCHED3 else '0';
    c_comp1      <= '1' when state = S_COMP1 else '0';
    c_comp2      <= '1' when state = S_COMP2 else '0';
    c_comp3      <= '1' when state = S_COMP3 else '0';
    c_comp4      <= '1' when state = S_COMP4 else '0';
    c_done       <= '1' when state = S_DONE else '0';
    fin          <= '1' when state = S_DONE else '0'; -- Avisa quem está fora do chip que o cálculo acabou

end architecture;
