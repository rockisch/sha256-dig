library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter64 is
    port(
        clk      : in  std_logic;
        rst      : in  std_logic;
        increase : in  std_logic;
        value    : out unsigned(5 downto 0);
        overflow : out std_logic
    );
end entity;

architecture counter64_arch of counter64 is
    -- Define o valor inicial do contador como 16
    constant INITIAL : unsigned(5 downto 0) := to_unsigned(16, 6);

    signal count     : unsigned(5 downto 0) := INITIAL;
    signal result    : unsigned(6 downto 0);
begin
    -- Calcula o próximo valor da contagem
    result <= ('0' & count) + 1;

    -- Processo síncrono acionado pelo clock
    process(clk, rst) begin
        if rst = '1' then
            -- Reset assíncrono: retorna ao valor inicial (16)
            count <= INITIAL;
        elsif rising_edge(clk) then
            -- Incrementa o contador apenas se o sinal 'increase' estiver ativo
            if increase = '1' then
                count <= result(5 downto 0);
            end if;
        end if;
    end process;

    -- Atualiza a saída continuamente com o valor interno
    value <= count;

    -- Gera pulso de overflow de forma combinacional quando atinge 63
    overflow <= '1' when count = to_unsigned(63, 6) else '0';

end architecture;
