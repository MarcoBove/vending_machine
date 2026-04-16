library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ROM_price is
    generic(
        DATA_WIDTH : integer := 9; -- fino a 500 centesimi
        BUTTON_NUM : integer := 4  -- pulsanti 0..9
    );
    port (
        button_i : in  STD_LOGIC_VECTOR(BUTTON_NUM-1 downto 0);
        price_o  : out STD_LOGIC_VECTOR(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture Behavioral of ROM_price is

    -- ROM con valori in unsigned
    type rom_price_type is array (0 to DATA_WIDTH-1) of unsigned(DATA_WIDTH-1 downto 0);

    constant PRICE_VAL : rom_price_type := (
        0 => to_unsigned(50,  DATA_WIDTH), --acqua
        1 => to_unsigned(100, DATA_WIDTH), --coca cola
        2 => to_unsigned(250, DATA_WIDTH), --snack
        3 => to_unsigned(200, DATA_WIDTH), --fitness
        4 => to_unsigned(0,   DATA_WIDTH),
        5 => to_unsigned(0,   DATA_WIDTH),
        6 => to_unsigned(0,   DATA_WIDTH),
        7 => to_unsigned(0,   DATA_WIDTH),
        8 => to_unsigned(0,   DATA_WIDTH),
        9 => to_unsigned(0,   DATA_WIDTH)
    );

begin

    -- converto button in indice intero
    price <= std_logic_vector(PRICE_VAL(to_integer(unsigned(button))));

end architecture;

