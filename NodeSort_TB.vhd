-- NodeMerger_tb.vhd
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity NodeMerger_tb is
end NodeMerger_tb;

architecture Behavioral of NodeMerger_tb is
  
    component NodeMerger is
        Port (
            clk           : in  std_logic;
            reset         : in  std_logic;
            sorted_char   : in  std_logic_vector(7 downto 0);
            sorted_freq   : in  integer;
            sort_ready    : in  std_logic;
            sort_done     : in  std_logic;
            merge_done    : out std_logic;
            root_index    : out integer
        );
    end component;

    signal clk           : std_logic := '0';
    signal reset         : std_logic := '0';
    signal sorted_char   : std_logic_vector(7 downto 0) := (others => '0');
    signal sorted_freq   : integer := 0;
    signal sort_ready    : std_logic := '0';
    signal sort_done     : std_logic := '0';
    signal merge_done    : std_logic;
    signal root_index    : integer;

    constant clk_period : time := 10 ns;

    type test_data_type is record
        char : character;
        freq : integer;
    end record;

    type test_array is array (0 to 7) of test_data_type;
    constant test_data : test_array := (
        ('r', 3),
        ('s', 2),
        ('u', 2),
        ('v', 2),
        ('e', 1),
        ('i', 1),
        ('o', 1),
        ('p', 1)
    );

begin
    uut: NodeMerger port map (
        clk         => clk,
        reset       => reset,
        sorted_char => sorted_char,
        sorted_freq => sorted_freq,
        sort_ready  => sort_ready,
        sort_done   => sort_done,
        merge_done  => merge_done,
        root_index  => root_index
    );

    clk_process: process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    stim_proc: process
    begin
        reset <= '1';
        wait for clk_period * 2;
        reset <= '0';
        wait for clk_period * 2;
    
        for i in test_data'range loop
            sorted_char <= std_logic_vector(to_unsigned(character'pos(test_data(i).char), 8));
            sorted_freq <= test_data(i).freq;
            
            wait until rising_edge(clk);
            sort_ready <= '1';
            
            report "Sending node: Char = " & test_data(i).char & 
                   ", Freq = " & integer'image(test_data(i).freq);
                   
            wait until rising_edge(clk);
            sort_ready <= '0';
            
            wait for clk_period * 2;
        end loop;
    
        wait for clk_period * 4;
        
        sort_done <= '1';
        wait for clk_period;
        sort_done <= '0';
    
        wait until merge_done = '1';
        
        wait for clk_period * 5;
        wait;
    end process;

end Behavioral;
