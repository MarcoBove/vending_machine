library ieee;
use ieee.STD_LOGIC_1164.all;

entity register is
    generic (
        DATA_WIDTH : integer := 9; --500 sono 9 bit
        RESET_VAL  : STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0) := (others => '0')
    );
    port (
        clk      : in  STD_LOGIC;
        areset_n : in  STD_LOGIC;
        d        : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        q        : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
    );
end register;

architecture behavioural of register is
begin
    -- behavioural process sensitive to clk and areset_n
    process (clk, areset_n)
    begin
        -- Asynchronous active-low reset
        if areset_n = '0' then
            -- Assigns RESET_VAL
            q <= RESET_VAL;
        -- Synchronous data propagation
        elsif rising_edge(clk) then
            q <= d;
        end if;
    end process;
end behavioural;