library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux_2to1 is
    generic (
        DATA_WIDTH : integer := 9
    );
    port (
        in_0 : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0); -- Es: Valore Moneta
        in_1 : in  STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0); -- Es: Valore Prezzo
        sel  : in  STD_LOGIC; -- Segnale di selezione (dalla FSM)
        mux_out : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
    );
end mux_2to1;

architecture Behavioral of mux_2to1 is
begin
    mux_out <= in_1 when sel = '1' else in_0;
end Behavioral;
