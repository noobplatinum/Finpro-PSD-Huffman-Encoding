library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;

entity ReaderSorterX is
    -- Put sorted_chars and sorted_freqs as an output port
    port (
        sorted_chars : out character;
        sorted_freqs : out integer
    );
end ReaderSorterX;

architecture Behavioral of ReaderSorterX is
    constant MAX_CHARS : integer := 256; -- Maximum number of characters to read
    constant ASCII_RANGE : integer := 128; -- Number of ASCII characters

    type char_array is array (0 to MAX_CHARS - 1) of character;
    type freq_array is array (0 to MAX_CHARS - 1) of integer;

begin
    process
        file input_file  : text open read_mode is "Input";
        file output_file : text open write_mode is "Output";
        variable input_line  : line;
        variable output_line : line;
        variable char_count  : integer := 0;
        variable temp_char   : character;
        variable frequencies : freq_array := (others => 0);
        variable chars_list  : char_array := (others => ' ');
        variable freqs_list  : freq_array := (others => 0);
        variable unsorted_chars : char_array := (others => ' ');
        variable sorted_chars  : char_array := (others => ' ');
        variable sorted_freqs  : freq_array := (others => 0);
        variable i, j, k     : integer;
        variable temp_freq   : integer;
        variable temp_char_var : character;

        -- Function to convert character to string
        function char_to_string(c : character) return string is
        begin
            return (c & ""); -- Convert character to single-character string
        end function;

    begin
        -- Read characters from the input file
        while not endfile(input_file) loop
            readline(input_file, input_line);
            for idx in input_line'range loop
                if char_count < MAX_CHARS then
                    temp_char := input_line(idx);
                    unsorted_chars(char_count) := temp_char; -- Assign to variable
                    char_count := char_count + 1;
                end if;
            end loop;
        end loop;

        -- Count frequency of each character
        for i in 0 to char_count - 1 loop
            frequencies(character'pos(unsorted_chars(i))) := frequencies(character'pos(unsorted_chars(i))) + 1;
        end loop;

        -- Initialize chars_list and freqs_list
        j := 0;
        for i in 0 to ASCII_RANGE - 1 loop
            if frequencies(i) > 0 then
                chars_list(j) := character'val(i);
                freqs_list(j) := frequencies(i);
                j := j + 1;
            end if;
        end loop;

        -- Sort the characters by frequency (Descending order)
        for i in 0 to j - 2 loop
            for k in 0 to j - i - 2 loop
                if freqs_list(k) < freqs_list(k + 1) then
                    -- Swap frequencies
                    temp_freq := freqs_list(k);
                    freqs_list(k) := freqs_list(k + 1);
                    freqs_list(k + 1) := temp_freq;
                    -- Swap characters
                    temp_char_var := chars_list(k);
                    chars_list(k) := chars_list(k + 1);
                    chars_list(k + 1) := temp_char_var;
                end if;
            end loop;
        end loop;

        -- Store the sorted results in variables
        for i in 0 to j - 1 loop
            sorted_chars(i) := chars_list(i);
            sorted_freqs(i) := freqs_list(i);
        end loop;

        -- Display the sorted results in the console
        for i in 0 to j - 1 loop
            write(output_line, string'(char_to_string(sorted_chars(i)) & " : "));
            write(output_line, sorted_freqs(i));
            writeline(output, output_line);
        end loop;

        -- Write the sorted characters and frequencies to the output file
        for i in 0 to j - 1 loop
            write(output_line, string'(char_to_string(sorted_chars(i)) & " : "));
            write(output_line, sorted_freqs(i));
            writeline(output_file, output_line);
        end loop;

        wait;
    end process;
end Behavioral;

