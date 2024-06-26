# Generator
The generator is used to generate the neural network VHDL file, from a supplied ONNX file. The program uses the onnx python library to read the file, and then convert it a graph, that can be written out ot a file.

# How to Use
To run the program, execute the main Python file with the path to the ONNX file you want to convert, the path to nn.vhd file and the path to the defs.vhd file, e.g. if the path to the file is "/home/accel/graph.onnx", the path to the nn is "/path/to/nn.vhd" and the path to the defs is "/path/to/defs.vhd" (path substitution for e.g. "~" is also possible):

```
python . /home/accel/graph.onnx /path/to/nn.vhd /path/to/defs.vhd
```

# How it Works
The program can be split into three parts; first loading in the file using the onnx python library, then converting that into a graph, calculating all the sizes of every component, lastly that graph is converted into a VHDL file, with all the signals between the components, the entities, and the FSM.

## Generating Graph
After loading in the ONNX model, we go through all of the operators in it and convert them into nodes. The nodes are then connected to eachother, based on the connection names, to create the directed graph of the entire model.

With this graph, we calculate the input and output size of each node, taking braodcasting into account, raising an error, if some of the sizes do not match. With this calculated we can remove the unnececery nodes, e.g. reshape nodes that do not change the data, to create a graph of only the nodes we can synthesize.

## Converting Graph to VHDL
Once a synthesizable graph has been generated, we pass that onto the convertion function, to convert it into two files, the neural network and the defines. The general structure is to load in a template file, containing some specific comments, that are then replaced with a string containing the information we want. Before reading in the files, we also do a general querry of the graph, to get some of the parameters we want to use in the files.

To create the neural network file, we substitute five comments: "-- STATES", "-- SIGNALS", "-- FSM", "-- ENTITIES", and "-- CONSTANT".
* "-- STATES" is substiuted with the state and next\_state signals, which is at the moment just an integer, but this would ease with chaning this later, if needed.  
* "-- SIGNALS" is substituted with the signal desciptions for each connection between the nodes. This is based on the model, and is calculated by going through each node, and combining its name with either \_o for its output or \_i\_num for each of its inputs, where "num" is substitued with its index, this is bundled together with the signals size.
* "-- FSM" is substitued with the FSM body, going from state=1 until it is out of states. For this we use the precalculated parameters, which include the ordered list of operations we want to do. To calculate this, we go thorugh each output node and traverse up the graph in a DFS, always taking the smallest path first, then we add each node to a list of operators in reverse, so the input nodes go first in the list, and then down. This ensures that we first of all only store the smallest possible amount of data to the RAM, as at each junction we have to store the data we will not use right away, and that the feedback always gets the biggest input, e.g. we have an adder and a subtractor connected to eachother, like in the picture bellow. We start at the adder, then traverse to the subtractor and continue up to Branch 1, then we add all of the nodes in the branch to a list and begin traversing up Branch 2, this ensures that we only store 5 bytes to RAM, while feeding the 10 bytes back into the FSM. We continue this for the adder, the result would be "Branch 1 - Branch 2 - SUB - Branch 3 - ADD".

![Example of traversing the graph to get operations list](Diagrams/Graph%20Traversal.png)
* "-- ENTITIES" is substitued with all the entity initializations, for each of the nodes that we have in the operations list. To form the string each node type has a conversion to a VHDL entity string, which is combined and collected to an output string. If one of the inputs to the entity uses broadcasting, we also create a braodcasting entity for that node, wireing the outputs of it to the inputs of the node that uses broadcasting.
* "-- CONSTANT" is substituted with all the constant wires, that is all the signals for the inputs of the nodes, that are connected to a constant node, are initialized to their value. This is done outside of the FSM, to force the synthesizer to optimize constants away.

To create the defs file, we substitute 2 comments: "-- INSTRUCTIONS" and "-- INPUT SIZE".
* "-- INSTRUCTIONS" is substituted with the instructions we want the memory FSM to take, when a handshake is being done between it and the neural network. Each instruction has a 3 bit lower instruction, and a 32 bit value, which tells the FSM what to do (Push, Pop, Read, etc.) and how many values we want affected. The instruction list is stored in the model parameters, and is generated by each time we hit a junction, where a node can take two paths, we add a push instruction at after calculating one of its branches, then we add a pop instruction when we re-enter the junction and want to do its calculation, e.g. if we look at the image above, we would get the instructions "branch 1 - store 5 - branch 2 - load 5 - store 5 - branch 1 - load 5". Some combinations of consecutive instruction can be concatinated to one instruction, that is storing and loading from input, and loading from RAM and input.
* "-- INPUT SIZE" is substituted with a variable that sets the total size of the input data, declaring when input data stop on the RAM and when the stack starts. The size is calculated by adding all the input node sizes together and is stored in the model parameters.

## Implemented Operands
As of now, all of the operators only support version 1 of the ONNX standard

|Operator|Status|Notes|
|-|-|-|
|Const|✅||
|Division|✅||
|Convolution|✅||
|Adder|✅||
|Relu|✅||
|Max Pool|✅||
|Mat Mul|✅||

✅ means working
❌ means not working

All of these operators has only had very limited testing done, feel free to test them on a ONNX model of your own.

To add new operators, create a new class for the operator, extending the Node class, and add it to the convert\_op\_type function
