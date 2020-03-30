----------------------------------------------------------------------------------
-- Company: Politecnico di Milano
-- Student: Juri Sacchetta - 890600
-- Module Name: project_reti_logiche - Behavioral
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    port (
        i_clk : in std_logic;
        i_start : in std_logic;
        i_rst : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        o_address : out std_logic_vector(15 downto 0);
        o_done : out std_logic;
        o_en : out std_logic;
        o_we : out std_logic;
        o_data : out std_logic_vector (7 downto 0)
    );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

constant NUMBER_OF_WORKING_ZONE : natural :=8; --numero di working zone in memoria
constant NUM_BIT_WZ : natural :=3; --Numero di bit necessario per esprimere il numero di WZ in binario
constant DIM_WZ : natural :=4; --Dimensione della Working Zone 
constant NUM_BIT_DIM : natural := DIM_WZ; --L'offset si calcola in codifica OneHot quindi il numero di bit è proprio la dimensione della Working Zone
constant ADDR_DATA_TO_CONVERT : std_logic_vector := std_logic_vector(to_unsigned(8,16)); --indirizzo del dato da convertire
constant ADDR_DATA_CONVERTED : std_logic_vector := std_logic_vector(to_unsigned(9,16)); --indirizzo dove scrivere il dato convertito

type state_type is (IDLE, FETCH_DATA, WAIT_DATA, FETCH_BASE_WZ, ANALYZE_DATA, DONE);
 
signal next_state, current_state: state_type;
signal data_to_convert, next_data_to_convert : unsigned(7 downto 0);
signal numwz, next_numwz : integer range 0 to NUMBER_OF_WORKING_ZONE :=0;

begin
    --processo sensibile al clock e reset per gestire i cambi di stato
    state_reg: process(i_clk, i_rst)
    begin
        if i_rst='1' then
            current_state <= IDLE;
            data_to_convert <= (others => '-');
            numwz <=0;
            elsif rising_edge(i_clk) then
            current_state<=next_state;
            data_to_convert <= next_data_to_convert;
            numwz <= next_numwz;
        end if;
    end process;
    
    --processo per definire lo stato prossimo e la logica interna
    delta: process(current_state, i_start, i_data, data_to_convert, numwz)
    variable tmp : natural;
    variable offset : unsigned(NUM_BIT_DIM-1 downto 0);
    variable tmp_numwz : unsigned(NUM_BIT_WZ-1 downto 0) :=(others => '-');
    begin
    
    
    o_address <=(others =>'-');
    o_done <= '0';
    o_en <='0';
    o_we <= '-';
    o_data <= (others => '-');
    
    next_data_to_convert <= data_to_convert;
    next_numwz <= numwz;
    
    
    case current_state is
    
    when IDLE =>
        if i_start='1' then
            next_state <= FETCH_DATA;
        else
            next_state <= IDLE;
        end if;
        
        
    when FETCH_DATA =>        
        o_address <= ADDR_DATA_TO_CONVERT;
        o_en <='1';
        o_we <='0';
        next_state <= WAIT_DATA;
        
    when WAIT_DATA =>
        next_data_to_convert <= unsigned(i_data);
        next_state <= FETCH_BASE_WZ;
        
    when FETCH_BASE_WZ =>
        o_address <= (15 downto NUM_BIT_WZ => '0') & std_logic_vector(to_unsigned(numwz, NUM_BIT_WZ)); 
        o_en<='1';
        o_we<='0';
        next_numwz <= numwz+1;
        next_state <= ANALYZE_DATA;
        
    when ANALYZE_DATA =>
            tmp :=  to_integer(data_to_convert - unsigned(i_data));
        --Qua va messa la logica del controllo di appartenenza
            if tmp>=DIM_WZ OR tmp<0 then
                if numwz < NUMBER_OF_WORKING_ZONE then
                    next_state <=FETCH_BASE_WZ;
                else
                    o_address <= ADDR_DATA_CONVERTED;
                    o_en<='1';
                    o_we<='1';
                    o_data<=std_logic_vector(data_to_convert);
                    next_state <= DONE;
                end if;
            else
                offset := (0=>'1', others =>'0');
                offset := shift_left(offset, tmp);
                tmp_numwz := to_unsigned(numwz-1, NUM_BIT_WZ);
                o_address <= ADDR_DATA_CONVERTED;
                o_data <= std_logic_vector('1' & tmp_numwz(2 downto 0) & offset);
                o_en<='1';
                o_we<='1';
                next_state <= DONE;
            end if;
            
    
    when DONE =>
        if i_start = '1' then
            o_done <= '1';
            next_state <= DONE;
        else
            o_done <= '0';
            next_state <= IDLE;
            next_data_to_convert <= (others => '-');
            next_numwz <= 0;
        end if;
        
    end case;
    end process;
end Behavioral;
