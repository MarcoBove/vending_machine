library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity finite_state_machine is
    generic (
        -- Range massimo credito (es. fino a 500c = 5 euro)
        MAX_CREDIT_BIT : integer := 9;
        BUTTON_NUM_BIT : integer := 4
    );
    port (
        CLK              : in  std_logic;
        areset_n         : in  std_logic; -- Reset asincrono attivo basso
        
        -- Ingressi: Monete 
        -- Le monete possono essere 50 centesimi, 100 centesimi (1 euro) o 200 centesimi (2 euro)
        coin_50c_in      : in  std_logic; 
        coin_1e_in       : in  std_logic; 
        coin_2e_in       : in  std_logic; 


        -- Ingressi: Tastierino Numerico (0..9) e  OK e C
        btn_num_in       : in  STD_LOGIC_VECTOR(BUTTON_NUM_BIT-1 downto 0); -- Codice prodotto
        btn_ok_in        : in  std_logic; -- Tasto OK (conferma)
        btn_c_in         : in  std_logic; -- Tasto C (cancella)


        -- Ingressi controllo
        credit_ok_in     : in std_logic; -- uscita comparatore quando il credito attuale è >= del prezzo allora si alza

        
        -- Uscite 
        credit_insufficient_out : out std_logic;

        --Uscite controllo
        update_credit_out         : out std_logic; --se è stato aggiornato il credito, abilita il registro
        clear_credit_out          : out std_logic; --azzera il credito sempre del registro
        add_sub_operation_out     : out std_logic; --seleziona somma o sottrazione
        mux_sel_out               : out std_logic; --seleziona moneta o prezzo
        en_dispense_item_out      : out std_logic; --eroga se è 1
        en_change_out             : out std_logic; --dai resto se è 1
        
    );
end entity;


-------------------------------------------------------------------------
    -- FUNZIONE USCITE 
    -- WAIT
    --Update cred se è stata inserita una moneta
    --op = 0 somma : se è stata inserita moneta
    --mux_sel: --Moneta sel=0 if coins = 1
    --
    
    -------------------------------------------------------------------------

    -------------------------------------------------------------------------
    -- FUNZIONE USCITE
    -- SELECT PRODUCT
    -- credit insufficient : if credit_ok=0 and Ok
    -- enable_dispense_item : if credit_ok = 1 and OK
    -- enable_change_out : if credit is zero = 0
    -- operation = 1 : differenza 
    -- mux_sel: Prezzo sel=1 quando devo calcolare il resto
    -- clear cred : quando ho erogato prodotto e dato resto
    -------------------------------------------------------------------------


architecture Behavioral of finite_state_machine is

    -- Definizione degli stati dell'automa
    type state_type is (
        S_WAIT, 
        S_SELECT_PRODUCT
    );
    
    signal current_state, next_state : state_type;

    -- Comparator Flags registrate 
    -- Da usare come ingressi per la FSM combinatoria
    signal sig_credit_is_zero  : std_logic; -- '1' se credito = 0   
    -- non lo so se metterlo perchè si puo mettere come ingresso oppure gestire con il tasto C

begin
    -------------------------------------------------------------------------
    -- PROCESSO 1: Logica Combinatoria del Prossimo Stato 
    -------------------------------------------------------------------------

    p_next_state : process(current_state, sig_credit_is_zero,
                           btn_ok_in, btn_c_in, 
                           coin_50c_in, coin_1e_in, coin_2e_in, btn_num_in, credit_ok_in)
    begin
        -- Valore di default
        next_state <= current_state;

        case current_state is
            when S_WAIT =>
                --  'coins' self-loop. Rimaniamo in WAIT.
                -- da WAIT on 'C' -> CHANGE COINS
                if (btn_c_in = '1') then
                    next_state <= S_WAIT;
                elsif(coin_50c_in = '1' or coin_1e_in = '1' or coin_2e_in = '1') then
                    next_state <= S_WAIT;
                elsif(btn_num_in = "0000" ) or (btn_num_in="0001") or (btn_num_in="0010") or (btn_num_in="0011") then   --qua bisogna vedere se metto un codice con valore 0 se passare a sel_product secondo me si
                    next_state <= S_SELECT_PRODUCT;
                elsif(btn_ok_in = '1') then
                    next_state <= S_WAIT;
                end if;
               
            when S_SELECT_PRODUCT =>
                if (btn_ok_in = '1' and credit_ok_in = '0') then
                    next_state <= S_WAIT;
                elsif (btn_c_in = '1') then
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

    p_outputs_mealy : process(current_state, sig_credit_is_zero,
                           btn_ok_in, btn_c_in, 
                           coin_50c_in, coin_1e_in, coin_2e_in, btn_num_in, credit_ok_in)
    begin

        credit_insufficient_out <= '0';

        --Uscite controllo
        update_credit_out         <= '0';
        clear_credit_out          <= '0';
        add_sub_operation_out     <= '0';
        mux_sel_out               <= '0';
        en_dispense_item_out      <= '0';
        en_change_out             <= '0';

        case current_state is
            when S_WAIT =>
                if (coin_50c_in = '1' or coin_1e_in = '1' or coin_2e_in = '1') then
                    update_credit_out <= '1';
                end if;

            when S_SELECT_PRODUCT =>
                if (credit_ok_in = '0' and btn_ok_in = '1') then
                    credit_insufficient_out <= '1';
                end if;

                if(credit_ok_in = '1' and btn_ok_in = '1') then
                    en_dispense_item_out <= '1';
                    add_sub_operation_out <= '1';
                    mux_sel_out <= '1';
                    if(sig_credit_is_zero = '1') then
                        en_dispense_change_out  <= '1';
                        clear_credit_out <= '1';
                    end if;
                end if;
            when others =>
                    null;    --questo non lo so                
        end case;
    end process;

    -------------------------------------------------------------------------
    -- PROCESSO 3: MEMORY PROCESS 
    -------------------------------------------------------------------------

    p_reg_proc : process(CLK, areset_n)
    begin
        -- Reset asincrono attivo basso 
        if areset_n = '0' then
            current_state      <= S_WAIT;
            sig_credit_is_zero <= '1'; -- Default
            
        elsif rising_edge(CLK) then
            -- Aggiornamento dello stato dell'automa
            current_state <= next_state;
        end if;
    end process;

end architecture Behavioral;