library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


    -------------------------------------------------------------------------
    -- INGRESSI
    -- uscita del registro somma-sottrazione
    
    -------------------------------------------------------------------------

-- difficoltà temporizzare adder con la fsm
-- deve leggere solo dalla rom
-- riscrivere stati 
-- valutare se passare a mealy

    -------------------------------------------------------------------------
    -- USCITE
    -- operation dell'adder
    
    -------------------------------------------------------------------------

entity finite_state_machine is
    generic (
        -- Range massimo credito (es. fino a 500c = 5 euro)
        MAX_CREDIT : integer := 9;
        BUTTON_NUM : integer := 4
    );
    port (
        CLK             : in  std_logic;
        aresetn         : in  std_logic; -- Reset asincrono attivo basso
        
        -- Ingressi: Monete 
        -- Le monete possono essere 50 centesimi, 100 centesimi (1 euro) o 200 centesimi (2 euro)
        coin_50c_p      : in  std_logic; 
        coin_1e_p       : in  std_logic; 
        coin_2e_p       : in  std_logic; 


        -- Ingressi: Tastierino Numerico (0..9) e  OK e C
        btn_num         : in  STD_LOGIC_VECTOR(BUTTON_NUM-1 downto 0); -- Codice prodotto
        btn_ok_p        : in  std_logic; -- Tasto OK (conferma)
        btn_c_p         : in  std_logic; -- Tasto C (cancella)
        
        -- Uscite 
        current_credit_out      : out STD_LOGIC_VECTOR(MAX_CREDIT-1 downto 0);
        credit_insufficient_out : out std_logic;
        dispense_item_out       : out STD_LOGIC_VECTOR(MAX_CREDIT-1 downto 0);
        dispense_change_out     : out STD_LOGIC_VECTOR(MAX_CREDIT-1 downto 0);
    );
end entity;

architecture Behavioral of finite_state_machine is

    -- Definizione degli stati dell'automa
    type state_type is (
        S_WAIT, 
        S_SELECT_PRODUCT
        );    

    signal price_val : integer;


    signal current_state, next_state : state_type;

    -- Registri interni espressi in centesimi
    signal sig_reg_credit      : integer range 0 to MAX_CREDIT;--credito attuale
    signal sig_reg_price       : integer range 0 to MAX_CREDIT;--prezzo del prodotto selezionato
    
    -- Comparator Flags registrate 
    -- Da usare come ingressi per la FSM combinatoria
    signal sig_credit_get_price : std_logic; -- '1' se credito >= prezzo
    signal sig_credit_lt_price : std_logic; -- '1' se credito < prezzo
    signal sig_credit_is_zero  : std_logic; -- '1' se credito = 0

    signal btn_num_press_p : std_logic; -- Pulsante numerico premuto (qualunque numero)

begin

    -------------------------------------------------------------------------
    -- PROCESSO 1: Logica Combinatoria del Prossimo Stato 
    -------------------------------------------------------------------------
    p_next_state : process(current_state, sig_credit_get_price, sig_credit_is_zero,
                           btn_ok_p, btn_c_p, 
                           coin_50c_p, coin_1e_p, coin_2e_p)
    begin
        -- Valore di default
        next_state <= current_state;

        case current_state is
            

            when S_WAIT =>
                --  'coins' self-loop. Rimaniamo in WAIT.
                -- Foto: da WAIT on 'C' -> CHANGE COINS
                if (btn_c_p = '1') then
                    next_state <= S_WAIT;
                elsif(coin_50c_p = '1' or coin_1e_p = '1' or coin_2e_p = '1') then
                    next_state <= S_WAIT;
                elsif(btn_num = 1) or (btn_num=2) or (btn_num=3) or (btn_num=4) or (btn_num=5) then
                    next_state <= S_SELECT_PRODUCT;
                elsif(btn_ok_p = '1') then
                    next_state <= S_WAIT;
                end if;
                -- Foto: da WAIT on 'buttons(0..s)' -> SELECT PRODUCT
                if (coin_50c_p = '1' or coin_1e_p = '1' or coin_2e_p = '1') then
                    next_state <= S_WAIT;
                end if;
               

            when S_SELECT_PRODUCT =>
     
                if (btn_ok_p = '1' and sig_credit_lt_price = '1') then
                    next_state <= S_WAIT;
               
                elsif (btn_c_p = '1') then
                    next_state <= S_WAIT;
                elsif (sig_credit_is_zero = '1') then
                    next_state <= S_WAIT;
                end if;


            when others => -- CASO IN CUI DA WAIT PASSIAMO A CHANGES ATTRAVERSO 'C' (cancella tutto e da il resto)
                next_state <= S_WAIT;
        end case;
    end process;

    -------------------------------------------------------------------------
    -- PROCESSO 2: Logica Combinatoria delle Uscite (Output logic)
    -------------------------------------------------------------------------
    p_outputs_mealy : process(current_state, sig_reg_credit, sig_credit_lt_price, btn_ok_p)
    begin
        -- Valori di default per evitare latch
        dispense_item_out       <= '0';
        dispense_change_out     <= '0';
        credit_insufficient_out <= '0';
        
        -- Il credito corrente è sempre mostrato
        current_credit_out <= sig_reg_credit;

        case current_state is
            when S_SELECT_PRODUCT =>
                -- Comportamento Mealy: l'uscita dipende IMMEDIATAMENTE dalla pressione di OK.
                if (sig_credit_lt_price = '1' and btn_ok_p = '1') then
                    credit_insufficient_out <= '1';
                end if;

                if(sig_credit_get_price = '1' and btn_ok_p = '1') then
                    dispense_item_out <= '1';
                    if(sig_credit_is_zero = '0') then
                   dispense_change_out  <= '1';
                end if;

                end if;                
            
        end case;
    end process;



    -------------------------------------------------------------------------
    -- PROCESSO 3: MEMORY PROCESS 
    -------------------------------------------------------------------------

    p_reg_proc : process(CLK, aresetn)
    begin
        -- Reset asincrono attivo basso 
        if aresetn = '0' then
            current_state      <= S_WAIT;
            sig_reg_credit     <= 0;
            sig_reg_price      <= 0;
            sig_credit_get_price <= '0';
            sig_credit_lt_price <= '1'; -- Default
            sig_credit_is_zero <= '1'; -- Default
            
        elsif rising_edge(CLK) then
            -- Aggiornamento dello stato dell'automa
            current_state <= next_state;
            
            -- qua non va bene port map
            sig_credit_is_zero <= '1' when (sig_reg_credit = 0) else '0';
            
            -- Aritmetica e Datapath
            case current_state is

                when S_WAIT =>
                    sig_reg_credit <= 0;
                    sig_reg_price  <= 0;
                    -- Calcolo Aritmetico Sincrono del Credito
                    -- non va bene va fatto con il adder_substractor
                    if (coin_50c_p = '1' and (sig_reg_credit + 50 <= MAX_CREDIT)) then
                        sig_reg_credit <= sig_reg_credit + 50;
                    elsif (coin_1e_p = '1' and (sig_reg_credit + 100 <= MAX_CREDIT)) then
                        sig_reg_credit <= sig_reg_credit + 100;
                    elsif (coin_2e_p = '1' and (sig_reg_credit + 200 <= MAX_CREDIT)) then
                        sig_reg_credit <= sig_reg_credit + 200;
                    end if;

                when S_SELECT_PRODUCT =>
                    -- La FSM si è mossa da WAIT a SELECT PRODUCT.
                    -- Al primo colpo di clock in questo stato, carichiamo il prezzo.
                    if (sig_reg_price = 0 and btn_num_press_p = '0') then 
                        sig_reg_price <= get_price(btn_num);
                    end if;
                    
                    -- Calcolo Flag comparatori per FSM (usati nel prossimo clock)
                    if (sig_reg_credit >= sig_reg_price and sig_reg_price /= 0) then
                        sig_credit_ge_price <= '1';
                        sig_credit_lt_price <= '0';
                    else
                        sig_credit_ge_price <= '0';
                        sig_credit_lt_price <= '1';
                    end if;

                    -- Resto 
                    -- non va bene va fatto con adder_substractor
                    if (sig_reg_price /= 0) then
                        sig_reg_credit <= sig_reg_credit - sig_reg_price;
                        sig_reg_price <= 0; -- Resettiamo prezzo dopo calcolo
                    end if;

                    -- mette il credito a zero
                    if (sig_reg_credit /= 0) then
                        sig_reg_credit <= 0;
                    end if;

                when others =>
                    null;
            end case;
        end if;
    end process;

end architecture Behavioral;