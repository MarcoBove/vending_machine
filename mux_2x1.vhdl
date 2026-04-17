library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- scegliere moneta o prezzo da mandare all'adder

entity mux_2x1 is
    generic (
        DATA_WIDTH : integer := 9
    );
    port (
        in_0 : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);  --Moneta
        in_1 : in STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0);  --Prezzo
        sel  : in STD_LOGIC; --segnale di selezione della fsm
        m_out  : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture Behavioural of mux_2x1 is
begin
    m_out <= in_1 when sel = '1' else in_0;

end architecture;