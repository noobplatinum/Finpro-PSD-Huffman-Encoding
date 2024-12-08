## Huffman Encoder - PSD Final Project
This project focuses on designing and implementing a Huffman Encoding system using VHDL. The encoder compresses data by generating an optimal prefix-free binary code based on the frequency of characters in the input string.

### I. Overview
Huffman encoding is a lossless data compression algorithm that assigns variable-length codes to input characters based on their frequency of occurrence. The most frequent characters receive shorter codes, while less frequent ones receive longer codes, resulting in efficient data representation.
This project involves creating modular components to achieve a fully functional Huffman Encoder, capable of generating and applying Huffman codes to compress input strings.

### II.Project Structure
The project is divided into several key modules, each responsible for a distinct part of the encoding process:

1. String Reading & Breaking Module
   
    Description: Reads the input string and breaks it into individual characters.
    Key Functions:
        Accepts input via a text
        Parses, counts, and stores unique characters into a file for further processing.

2. Node Generator
   
    Description: Generates nodes based on the frequency of characters in the input string.
    Key Functions:
        Calculates frequency counts for each character.
        Creates nodes for each unique character, associating each with its frequency.

3. Node Sorter
   
    Description: Sorts the nodes in ascending order of frequency.
    Key Functions:
        Implements bubble sorting logic to order the nodes by frequency. These nodes will later be used for building the main tree.

4. Node Merger
   
    Description: Combines the two nodes with the smallest frequencies into a single parent node.
    Key Functions:
        Merges the two least frequent nodes iteratively until a single Huffman tree remains.
        Updates the node list after each merge.

5. Tree Builder & Traverser

    Description: Constructs the Huffman tree and traverses it to generate binary codes for each character.
    Key Functions:
        Builds the binary tree using the sorted nodes and merges.
        Traverses the tree to assign binary codes to characters based on tree paths (left = 0, right = 1).

6. Translator

    Description: Encodes the input string into the compressed binary format using the generated Huffman codes.
    Key Functions:
        Maps input characters to their corresponding binary codes.
        Outputs the compressed bitstream.

7. Top Module

    Description: Integrates all modules into a cohesive system.
    Key Functions:
        Manages the data flow between modules.
        Handles external communication and control signals for encoding operations.

### III. Key Features

- Behavioral Style Programming - Modules
- Structural/Hierarchical Style Programming - Topmodules and Subcomponents
- Testbenching
- Looping Constructs
- Procedures and Functions
- Finite State Machine

### IV. Group Project Members

1. Jesaya David Gamalael N P (2306161965)
2. Muhammad Bryan Farras (2306230975)
