library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity data_gater is
    generic (
        DATA_WIDTH : integer := 9
    );
    port (
        data_in  : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        enable   : in  STD_LOGIC; -- Controllato dalla FSM
        data_out : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
    );
end data_gater;

architecture Behavioral of data_gater is
begin
    data_out <= data_in when enable = '1' else (others => '0');
end Behavioral;
