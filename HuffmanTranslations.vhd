library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use STD.TEXTIO.ALL;

entity HuffmanTranslator is
    Port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        start       : in  std_logic;
        done        : out std_logic
    );
end HuffmanTranslator;

architecture Behavioral of HuffmanTranslator is
    -- Node type definition
    type node_type is record
        character    : std_logic_vector(7 downto 0);
        frequency    : integer;
        left_child   : integer;
        right_child  : integer;
        is_leaf      : boolean;
    end record;
    
    -- Dynamic arrays
    type node_array is array (natural range <>) of node_type;
    type path_array is array (natural range <>) of std_logic;
    
    -- State machine with preprocessing
    type state_type is (idle, counting, reading, translating, done_state);
    signal state : state_type := idle;
    
    -- Storage with initial sizes
    signal nodes : node_array(0 to 511);  -- Allow up to 256 characters (512 total nodes)
    signal path : path_array(0 to 511);   -- Max possible path length
    signal path_length : integer := 0;
    signal root_index : integer := 0;
    signal num_nodes : integer := 0;
    signal max_depth : integer := 0;
    
    -- File handling
    file tree_file : text;
    file orig_file : text;
    file output_file : text open write_mode is "FinalOutput";

    function maximum(a, b: integer) return integer is
    begin
        if a > b then
            return a;
        else
            return b;
        end if;
    end function;

    -- Helper function to calculate tree height
    function calculate_tree_height(
        nodes_arr: in node_array;
        node_idx: in integer) return integer is
        variable left_height, right_height : integer;
    begin
        -- Bounds checking
        if node_idx < 0 or node_idx > 511 then
            report "Warning: Node index " & integer'image(node_idx) & " out of bounds" severity warning;
            return 0;
        end if;

        -- Base cases
        if node_idx = -1 then
            return 0;
        elsif nodes_arr(node_idx).is_leaf then
            return 0;
        else
            -- Check child nodes exist within bounds
            if nodes_arr(node_idx).left_child >= 0 and nodes_arr(node_idx).left_child <= 511 then
                left_height := calculate_tree_height(nodes_arr, nodes_arr(node_idx).left_child);
            else
                left_height := 0;
            end if;

            if nodes_arr(node_idx).right_child >= 0 and nodes_arr(node_idx).right_child <= 511 then
                right_height := calculate_tree_height(nodes_arr, nodes_arr(node_idx).right_child);
            else 
                right_height := 0;
            end if;

            -- Protect against overflow
            if left_height < 0 or right_height < 0 then
                report "Warning: Height calculation overflow detected" severity warning;
                return 0;
            end if;

            return 1 + maximum(left_height, right_height);
        end if;
    end function;
    
    -- Helper procedure to write translation
    procedure write_translation(
        file f: text;
        char: in std_logic_vector(7 downto 0);
        path: in path_array;
        length: in integer) is
        variable l: line;
        variable temp_char: character;
    begin
        temp_char := character'val(to_integer(unsigned(char)));
        write(l, temp_char);
        write(l, string'(": "));
        
        for i in 0 to length-1 loop
            if path(i) = '0' then
                write(l, character'('0'));
            else
                write(l, character'('1'));
            end if;
        end loop;
        writeline(f, l);
    end procedure;

    procedure translate_string(
        file input_file: text;
        file output_file: text;
        nodes_arr: in node_array;
        root: in integer) is
        variable l_in, l_out: line;
        variable in_char: character;
        variable curr_node: integer;
        variable result: string(1 to 1024);
        variable binary: string(1 to 4096);
        variable result_len: integer := 0;
        variable binary_len: integer := 0;
        variable temp_path: path_array(0 to 511);
        variable path_len: integer;
        variable found: boolean;
    begin
        readline(input_file, l_in);
        write(l_out, string'("Original text translation: "));
        
        while l_in'length > 0 loop
            read(l_in, in_char);
            result_len := result_len + 1;
            result(result_len) := in_char;
            
            -- Reset for new character search
            curr_node := root;
            path_len := 0;
            found := false;
            
            -- Find path to character
            while not found loop
                if nodes_arr(curr_node).is_leaf then
                    if character'val(to_integer(unsigned(nodes_arr(curr_node).character))) = in_char then
                        found := true;
                    else
                        -- Backtrack - remove last path bit and try right path
                        while path_len > 0 and temp_path(path_len-1) = '1' loop
                            path_len := path_len - 1;
                            curr_node := root; -- Reset to root for backtracking
                            -- Rebuild path up to this point
                            for i in 0 to path_len-1 loop
                                if temp_path(i) = '0' then
                                    curr_node := nodes_arr(curr_node).left_child;
                                else
                                    curr_node := nodes_arr(curr_node).right_child;
                                end if;
                            end loop;
                        end loop;
                        if path_len > 0 then
                            -- Try right path
                            path_len := path_len - 1;
                            curr_node := root;
                            -- Rebuild path
                            for i in 0 to path_len-1 loop
                                if temp_path(i) = '0' then
                                    curr_node := nodes_arr(curr_node).left_child;
                                else
                                    curr_node := nodes_arr(curr_node).right_child;
                                end if;
                            end loop;
                            -- Add right path
                            temp_path(path_len) := '1';
                            path_len := path_len + 1;
                            curr_node := nodes_arr(curr_node).right_child;
                        end if;
                    end if;
                else
                    -- Try left path first
                    temp_path(path_len) := '0';
                    path_len := path_len + 1;
                    curr_node := nodes_arr(curr_node).left_child;
                end if;
            end loop;
            
            -- Add found path to binary result
            for i in 0 to path_len-1 loop
                binary_len := binary_len + 1;
                if temp_path(i) = '0' then
                    binary(binary_len) := '0';
                else
                    binary(binary_len) := '1';
                end if;
            end loop;
        end loop;
        
        -- Write results
        write(l_out, result(1 to result_len));
        writeline(output_file, l_out);
        
        write(l_out, string'("Binary translation: "));
        write(l_out, binary(1 to binary_len));
        writeline(output_file, l_out);
    end procedure;

    -- Recursive traversal procedure
    procedure traverse_tree(
        node_index: in integer;
        curr_path: inout path_array;
        curr_length: inout integer;
        nodes_arr: in node_array) is
    begin
        if nodes_arr(node_index).is_leaf then
            -- Found leaf node, write translation
            write_translation(output_file, nodes_arr(node_index).character, curr_path, curr_length);
            report "Found translation for " & 
                   character'val(to_integer(unsigned(nodes_arr(node_index).character))) & 
                   " at depth " & integer'image(curr_length);
        else
            -- Traverse left (0)
            if nodes_arr(node_index).left_child /= -1 then
                curr_path(curr_length) := '0';
                curr_length := curr_length + 1;
                traverse_tree(nodes_arr(node_index).left_child, curr_path, curr_length, nodes_arr);
                curr_length := curr_length - 1;
            end if;
            
            -- Traverse right (1)
            if nodes_arr(node_index).right_child /= -1 then
                curr_path(curr_length) := '1';
                curr_length := curr_length + 1;
                traverse_tree(nodes_arr(node_index).right_child, curr_path, curr_length, nodes_arr);
                curr_length := curr_length - 1;
            end if;
        end if;
    end procedure;

begin
    process(clk, reset)
        variable line_in : line;
        variable char : character;
        variable node_index, freq, left, right : integer;
        variable is_leaf : boolean;
        variable temp_path : path_array(0 to 511);
        variable temp_length : integer;
        variable node_count : integer := 0;
    begin
        if reset = '1' then
            state <= idle;
            done <= '0';
            path_length <= 0;
            root_index <= 0;
            num_nodes <= 0;
            
        elsif rising_edge(clk) then
            case state is
                when idle =>
                    if start = '1' then
                        -- First count nodes
                        file_open(tree_file, "HuffmanArray", read_mode);
                        state <= counting;
                    end if;

                when counting =>
                    -- Count total nodes in file
                    while not endfile(tree_file) loop
                        readline(tree_file, line_in);
                        node_count := node_count + 1;
                    end loop;
                    
                    num_nodes <= node_count;
                    file_close(tree_file);
                    file_open(tree_file, "HuffmanArray", read_mode);
                    state <= reading;

                when reading =>
                    while not endfile(tree_file) loop
                        readline(tree_file, line_in);
                        
                        -- Parse node index
                        read(line_in, node_index);
                        read(line_in, char); -- Skip comma
                        
                        -- Parse character/dash
                        read(line_in, char);
                        if char = '-' then
                            nodes(node_index).character <= (others => '0');
                            nodes(node_index).is_leaf <= false;
                        else
                            nodes(node_index).character <= std_logic_vector(to_unsigned(character'pos(char), 8));
                            nodes(node_index).is_leaf <= true;
                        end if;
                        
                        -- Parse frequency, left child, right child
                        read(line_in, char); -- Skip comma
                        read(line_in, freq);
                        read(line_in, char); -- Skip comma
                        read(line_in, left);
                        read(line_in, char); -- Skip comma
                        read(line_in, right);
                        read(line_in, char); -- Skip comma
                        read(line_in, is_leaf);
                        
                        -- Assign values
                        nodes(node_index).frequency <= freq;
                        nodes(node_index).left_child <= left;
                        nodes(node_index).right_child <= right;
                    end loop;
                    
                    -- Find root (last node)
                    file_close(tree_file);
                    root_index <= num_nodes - 1;
                    max_depth <= calculate_tree_height(nodes, num_nodes - 1);
                    state <= translating;

                    when translating =>
                    temp_length := 0;
                    traverse_tree(root_index, temp_path, temp_length, nodes);
                    
                    file_open(orig_file, "Input", read_mode);
                    translate_string(orig_file, output_file, nodes, root_index);
                    file_close(orig_file);
                    
                    state <= done_state;

                when done_state =>
                    done <= '1';

                when others =>
                    state <= idle;
            end case;
        end if;
    end process;

end Behavioral;
