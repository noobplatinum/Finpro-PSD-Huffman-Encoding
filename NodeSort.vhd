library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity NodeSorter is
    Port (
        clk           : in  STD_LOGIC;
        reset         : in  STD_LOGIC;
        -- Input interface
        node_ready    : in  STD_LOGIC;
        node_char     : in  STD_LOGIC_VECTOR(7 downto 0);
        node_freq     : in  INTEGER;
        input_done    : in  STD_LOGIC;
        -- Output interface
        sort_ready    : out STD_LOGIC;
        sorted_char   : out STD_LOGIC_VECTOR(7 downto 0);
        sorted_freq   : out INTEGER;
        sort_done     : out STD_LOGIC
    );
end NodeSorter;

architecture Behavioral of NodeSorter is
    type node_type is record
        character   : STD_LOGIC_VECTOR(7 downto 0);
        frequency   : integer;
    end record;

    constant MAX_NODES : integer := 256;
    type node_array is array (0 to MAX_NODES - 1) of node_type;

    signal nodes        : node_array;
    signal node_count   : integer := 0;
    signal output_index : integer := 0;

    type state_type is (receiving, sorting, outputting, done_state);
    signal state : state_type := receiving;

begin
    process(clk, reset)
        variable temp_nodes : node_array;
        variable i, j : integer;
        variable temp_node : node_type;
        variable found : boolean;
    begin
        if reset = '1' then
            report "Reset activated";
            state <= receiving;
            node_count <= 0;
            output_index <= 0;
            sort_ready <= '0';
            sort_done <= '0';
        elsif rising_edge(clk) then
            case state is
                when receiving =>
                    if node_ready = '1' then
                        report "Receiving new node - Char: " & 
                               character'val(to_integer(unsigned(node_char))) &
                               " Freq: " & integer'image(node_freq);
                        
                        if node_count = 0 then
                            report "First node being added";
                            nodes(0).character <= node_char;
                            nodes(0).frequency <= node_freq;
                            node_count <= 1;
                        else
                            found := false;
                            for i in 0 to node_count-1 loop
                                if nodes(i).character = node_char then
                                    report "Character already exists at index " & integer'image(i);
                                    found := true;
                                    exit;
                                end if;
                            end loop;
                            
                            if not found then
                                report "Adding new node at index " & integer'image(node_count);
                                nodes(node_count).character <= node_char;
                                nodes(node_count).frequency <= node_freq;
                                node_count <= node_count + 1;
                            end if;
                        end if;
                    elsif input_done = '1' then
                        report "Input complete. Total nodes: " & integer'image(node_count);
                        state <= sorting;
                    end if;

                when sorting =>
                    report "Starting sort phase";
                    report "Initial array:";
                    for i in 0 to node_count-1 loop
                        report "Node[" & integer'image(i) & "]: Char=" & 
                               character'val(to_integer(unsigned(nodes(i).character))) &
                               " Freq=" & integer'image(nodes(i).frequency);
                    end loop;

                    temp_nodes := nodes;
                    for i in 0 to node_count-2 loop
                        for j in 0 to node_count-i-2 loop
                            if temp_nodes(j).frequency < temp_nodes(j+1).frequency then
                                report "Swapping nodes " & integer'image(j) & " and " & integer'image(j+1);
                                temp_node := temp_nodes(j);
                                temp_nodes(j) := temp_nodes(j+1);
                                temp_nodes(j+1) := temp_node;
                            end if;
                        end loop;
                    end loop;

                    report "Sort complete. Final array:";
                    for i in 0 to node_count-1 loop
                        report "Node[" & integer'image(i) & "]: Char=" & 
                               character'val(to_integer(unsigned(temp_nodes(i).character))) &
                               " Freq=" & integer'image(temp_nodes(i).frequency);
                    end loop;

                    nodes <= temp_nodes;
                    state <= outputting;

                when outputting =>
                    if output_index < node_count then
                        report "Outputting node " & integer'image(output_index) & 
                               ": Char=" & character'val(to_integer(unsigned(nodes(output_index).character))) &
                               " Freq=" & integer'image(nodes(output_index).frequency);
                        sorted_char <= nodes(output_index).character;
                        sorted_freq <= nodes(output_index).frequency;
                        sort_ready <= '1';
                        output_index <= output_index + 1;
                    else
                        report "Output complete";
                        sort_ready <= '0';
                        state <= done_state;
                    end if;

                when done_state =>
                    report "Sorting process complete";
                    sort_ready <= '0';
                    sort_done <= '1';

                when others =>
                    state <= done_state;
            end case;
        end if;
    end process;
end Behavioral;
