library ieee;
use ieee.std_logic_1164.all;
use work.sha256_pkg.all;

entity sha256_bc is
    port(
        clk, rst, rdy, o_loop_last : in  std_logic;
        fin, c_init, c_loop_sched, c_loop_comp, c_done : out std_logic
    );
end entity;

architecture sha256_bc_arch of sha256_bc is
    signal state, next_state : FSM_STATE := S_IDLE;
begin
    process(clk, rst) begin
        if rst = '1' then state <= S_IDLE;
        elsif rising_edge(clk) then state <= next_state;
        end if;
    end process;

    process(state, rdy, o_loop_last) begin
        case state is
            when S_IDLE  => next_state <= S_INIT when rdy = '1' else S_IDLE;
            when S_INIT  => next_state <= S_SCHED;
            when S_SCHED => next_state <= S_COMP when o_loop_last = '1' else S_SCHED;
            when S_COMP  => next_state <= S_DONE when o_loop_last = '1' else S_COMP;
            when S_DONE  => next_state <= S_IDLE;
        end case;
    end process;

    c_init       <= '1' when state = S_INIT else '0';
    c_loop_sched <= '1' when state = S_SCHED else '0';
    c_loop_comp  <= '1' when state = S_COMP else '0';
    c_done       <= '1' when state = S_DONE else '0';
    fin          <= '1' when state = S_DONE else '0';
end architecture;