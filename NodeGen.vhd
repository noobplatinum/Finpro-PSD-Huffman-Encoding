
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;
use IEEE.NUMERIC_STD.ALL;

entity NodeGenerator is
    Port (
        clk           : in  STD_LOGIC;
        reset         : in  STD_LOGIC;
        node_ready    : out STD_LOGIC;
        node_char     : out STD_LOGIC_VECTOR(7 downto 0);
        node_freq     : out INTEGER;
        done          : out STD_LOGIC
    );
end NodeGenerator;

architecture Behavioral of NodeGenerator is
    type node_type is record
        character     : character;
        frequency     : integer;
        left_child    : integer;
        right_child   : integer;
        merged        : boolean;
    end record;

    constant MAX_NODES : integer := 256;
    type node_array is array (0 to MAX_NODES - 1) of node_type;

    signal nodes           : node_array := (others => (character => ' ', frequency => 0, left_child => -1, right_child => -1, merged => false));
    signal total_nodes     : integer := 0;
    signal node_index      : integer := 0;

    type state_type is (read_file, parse_line, create_node, done_state);
    signal state : state_type := read_file;

    file input_file : text open read_mode is "Output";

    function char_to_slv(c : character) return STD_LOGIC_VECTOR is
    begin
        return std_logic_vector(to_unsigned(character'pos(c), 8));
    end function;

begin
    process(clk, reset)
        variable input_line  : line;
        variable char_read   : character;
        variable freq_read   : integer;
    begin
        if reset = '1' then
            -- Reset
            state       <= read_file;
            total_nodes <= 0;
            node_index  <= 0;
            node_ready  <= '0';
            done        <= '0';
        elsif rising_edge(clk) then
            case state is
                when read_file =>
                    if not endfile(input_file) then
                        -- Read line
                        readline(input_file, input_line);
                        state <= parse_line;
                    else
                        state <= done_state;
                    end if;

                when parse_line =>
                    -- Parse character
                    read(input_line, char_read);
                    read(input_line, freq_read);
                    
                    -- Store data
                    nodes(total_nodes).character <= char_read;
                    nodes(total_nodes).frequency <= freq_read;
                    nodes(total_nodes).left_child <= -1;
                    nodes(total_nodes).right_child <= -1;
                    nodes(total_nodes).merged <= false;

                    -- Log
                    report "Character read: " & char_read & ", Frequency read: " & integer'image(freq_read);

                    -- Increment
                    total_nodes <= total_nodes + 1;

                    -- Create_node state
                    state <= create_node;

                when create_node =>
                    -- Output data
                    if node_index < total_nodes then
                        node_char <= char_to_slv(nodes(node_index).character);
                        node_freq <= nodes(node_index).frequency;
                        node_ready <= '1';

                        report "Outputting node: Char = " & nodes(node_index).character &
                               ", Freq = " & integer'image(nodes(node_index).frequency);

                        node_index <= node_index + 1;

                        -- Read next line
                        state <= read_file;
                    else
                        node_ready <= '0';
                        state <= done_state;
                    end if;

                when done_state =>
                    -- Mark as completed
                    node_ready <= '0';
                    done <= '1';
                    report "Node generation completed. Total nodes: " & integer'image(total_nodes);

                when others =>
                    state <= done_state;
            end case;
        end if;
    end process;
end Behavioral;

