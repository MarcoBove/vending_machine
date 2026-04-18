library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity output_gate is
    generic (
        DATA_WIDTH : integer := 9
    );
    port (
        data_in  : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);
        en   : in  STD_LOGIC; -- Controllato dalla FSM
        data_out : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
    );
end output_gate;

architecture Behavioral of output_gate is
begin
    data_out <= data_in when en = '1' else (others => '0');
end Behavioral;
