library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.sha256_pack.all;

entity bc is
	port(
        clk         : in std_logic;
        rst_a       : in std_logic;
        start       : in std_logic;
        status      : in std_logic_vector(6 downto 0);
        commands    : out commands;
        done        : out std_logic
	);
end entity bc;

architecture structure of bc is
        TYPE state_type is (IDLE, INIT, SCHED, COMP, DONE_STATE);
        SIGNAL state, next_state : state_type;
begin
	reg_estado : process(clk, rst_a)
        begin
            if rst_a = '1' then
                state <= IDLE;
            elsif rising_edge(clk) then
                state <= next_state;
            end if;
        end process;

        lpe : process(state, start, status)
        begin
            case state is
                when IDLE =>
                        if start = '1' then
                            next_state <= INIT;
                        else
                            next_state <= IDLE;
                        end if;
                when INIT =>
                        next_state <= SCHED;
                when SCHED =>
                        if status(6) = '1' then
                            next_state <= COMP;
                        else
                            next_state <= SCHED;
                        end if;
                when COMP =>
                        if status(6) = '0' then
                                next_state <= DONE_STATE;
                                else
                                next_state <= COMP;
                                end if;
                when DONE_STATE =>
                        next_state <= IDLE;
                when others =>
                        next_state <= IDLE;
            end case;
        end process;

        ls : process(state)
        begin
            case state is
                when IDLE =>
                        commands <= (init_load => '0', sched_en => '0', comp_en => '0', out_en => '0');
                        done <= '0';
                when INIT =>
                        commands <= (init_load => '1', sched_en => '0', comp_en => '0', out_en => '0');
                        done <= '0';
                when SCHED =>
                        commands <= (init_load => '0', sched_en => '1', comp_en => '0', out_en => '0');
                        done <= '0';
                when COMP =>
                        commands <= (init_load => '0', sched_en => '0', comp_en => '1', out_en => '0');
                        done <= '0';
                when DONE_STATE =>
                        commands <= (init_load => '0', sched_en => '0', comp_en => '0', out_en => '1');
                        done <= '1';
                when others =>
                        commands <= (init_load => '0', sched_en => '0', comp_en => '0', out_en => '0');
                        done <= '0';
            end case;
        end process;

end architecture structure;
 