# Conclusions from discussion with Ross and Lenny (4/18).
* Every processor or processing element (e.g. in a spatial architecture) can be thought of as a single function of several inputs which outputs a tuple of values. If we want to think of a Verilog/RTL analogy, this function would be the top-level module for the processing element, and the inputs and outputs would be the delcared `input` and `output` wires at the top of the module. Note that this abstract description applies to both a general puprose processor (like a CPU) as well as a PE in a spatial architecture/CGRA. See below how they may differ in implementation. Also, initially, we ignore the internal stateful-ness of the processing elements (i.e. it can be modeled as a pure function).
* The main claim while designing this DSL is that all a programmer is doing is specifying both the interface/signature of that function, as well as the actual semantics of the function. From this claim, we note sevaral things:
  - We could offer the programmer a very limited set of RTL-like tools to enable the specification of this function (e.g. a bit-vector class with overloaded operators), and ask the programmer to specify the function in python (or in any high-level language really). Using this methodology, the programmer has complete control over the semantics of the function. Of course, this is not at all useful since we are basically telling the programmer to write a functional spec from scratch, which is what they are doing now anyway.
  - Therefore, the path to designing this DSL should maintain the original principle that the programmer is simply specifying a single function, while automating (by making native to the language) as many common tasks as possible. Under this methodology, the programmer **could** specify a function from scratch as mentioned above, but the language provides lots of features to make this easier. Also, the language should provide abstractions which align with the existing programming models in which **hardware designers** think. Specifically, we want hardware designers to use this language, and we don't want to force them to think like software programmers.
  - Ultimately, the task of designing the language boils down into a decision of (a) what to **provide** the progammer through inherent language syntax/structures, and (b) how to **restrict** the programmer so that the result of any code/spec is a proper spec.
* **It is very important for the language to not devolve into an RTL language**. We don't want to reinvent Chisel, Magma, or Verilog.
* It is not immediately obvious how to design a DSL for specifying both processing elements of spatial architectures (e.g. CGRA) and those of temporal architectures (e.g. CPU). In fact, it need not be the case that they can or even should be both specified using the same language. Along these lines, there are several thoughts:
  - It still makes sense to think about both in a functional way. At first glance, the fundamental difference between a single PE in a spatial architecture and a temporal processor is just that some inputs are *fixed* (for the lifetime of a configuration) in a spatial PE, where as all inputs are dynamic (i.e. vary in time) for a temporal PE. In this way, we could think about a reconfigurable processor (e.g. a spatial PE) as a *closure* over a set of specific configuration inputs, and a temporal PE as a normal function. To reconfigure the processor, we would have to compute a new closure. Going back to our initial hypothesis, we still maintain a simple functional model; however, in a spatial architecture the output of the function would be another function (the closure), where as in a temporal architecture the output would be a set of "real" outputs (i.e. wires).
  - This seemingly fundamental difference, is actually not so fundamental. Really, the fundamental difference between a PE in a spatial architecture and a PE in a temporal architecture is in their use, not in their operation. This is because even temporal PE's have some configuration state (e.g. performance counters) - it's just that this is often not on the critical path for functional specification. Again, the real distinction is in their use: spatial PE's are often tiled together with instructions/op-codes coming from on-tile registers that only change at configuration; temporal PE's are standalone components which read different instructions from memory over time (instruction fetch). The "decode" and "execute" stages of both types of processors are in fact quite similar.
  - We therefore limit the scope of the language to cover the functionality of decode and execute stages. The fetch, memory and writeback stages are outside of the scope of this lanaguage. An important task will be drawing the lines between these stages.
  - Our hypothesis is that the language should allow specification of both types of procsessors in the same way. Specifically, we claim that there are two distinct types of input variables: `dynamic` variables and `configuration` variables. Once declared, both types of variables can be used in the same way - there is effectively no distinction downstream from the programmers perspective. In terms of the language internals, however, they may have different meanings (e.g. they would correspond to different RTL, and different semantics in a functional model). This allows the progammer to decouple the functional interface of the processor from how much it is a "spatial" vs. "temporal" PE (in fact, those lines are blurred here).
* We also add another qualifier to inputs: `quantitative` vs. `nominal`. Quantitative inputs are those which represent general n-bit wires, and can be used in anyway, e.g. in logic, in arithmetic, for storage. They are parameterized by a positive integer n, and can take on any value in [0, 2^n]. Nominal inputs, however, can only be used as select signals, i.e. as subjects of a switch-case statement. Basically, they are like `enum`s in C/C++, and can only take on a set of predetermined values. Note that the size of the range of nominal values need not be a power of 2. This is the critical distinction between nominal and quantitative variables. For nominal variables, the programmer need not think about the bit-level encoding of the signal, just the range of possible values. For example, a signal like `flag_sel` really doesn't take on values like `0x00`, `0x01`, etc.; instead, it takes on labels like `"z"` or `"not_z"`. We disallow any action on nominal inputs which are not of the form of a switch-case statement. (The actual syntax is TBD.)
  - The quantitative/temporal qualifier is orthogonal from the dynamic/configuration qualifier. So, every variable is declared like:

    ```
    var <quantitative/nominal> <config/dynamic> foo(<args>)
    ```

    (Again syntax very TBD, just the flavor).
  - Quantitative variables require a bit-width argument, while nominal variables require a list of possible labels (like an enum). So we have:

    ```
    var quantitative <config/dynamic> data0(32)
    ```

    and

    ```
    var nominal <config/dynamic> reg0_mode(["CONST", "VALID", "BYPASS", "DELAY"])
    ```

* There is a special variable `instruction` which is built-in. This variable is always nominal, and can be specified to either be dynamic or configuration. Since it is a special variable, its range need not be explicitly specified. Instead, the range is assumed from downstream code, where the user will specify a series of instructions. For example, we may want to specify that there are 3 instructions in the processor like this:

    ```
    instruction add : return data0 + data1 + bit1
    instruction sub : return data0 + ~data1 + 1
    instruction abs : return (0 - data0) if data0[15] else data0
    ```

  Again the syntax here is very TBD. Most importantly, the phrase `instruction` is overloaded here. Also what exactly should be on the "right-hand side" of each instruction is unclear. Should it be arbitrary python code which can change any values, or should it be lambda's which have an output cardinality matching the output cardinality of the entire PE? How do we specify side effects of this function (such as setting intermediate `Z, C, N, V` flags)?
* All inputs should be declared up front, even if they are to be used only for a subset of instructions. For instance some instructions require two `src` registers and some require an `imm` (immediate) value; often, these are disjoint sets of instructions, but both need to be encoded in the instruction. The programmer should declare these all individually.
* All inputs are immutable. However, we can use arbitrary python code to create intermediate variables, user-defined functions, etc on top of the input variables.
* The language should still allow the meta-proramming techniques already used in hardware design. As a specific example, things like bit-width of wires and registers should be template-able.
## Important open issues
* How to define and deal with statefulness like registers and memory? One thought is to define all stateful components upfront like `state reg0(...)`. Then we can use the output of any state variable, but also need to define some FSM-like semantics for each state. One fear with this methodology is that it can devlove into asking the programmer to write general RTL (see 3rd bullet from top). A more abstract/elegant solution may be warranted here.
* In the current CGRA implementation the distinction between persistent state and configuration is blurred, namely through the `REG_CONST` mode. In this mode, registers (data0 through bit2) can take on constant values specified at configuration time. Therefore, there are configuration variables which are really persistent state. Functionally, this is irrelevant since dynamic and configuration variables can be used in the same way **and** all inputs are immutable. However, from an implementation perspective such configuration variables are quite different, since they do not occupy their own space and are effectively "aliased" with the other state of the PE. For example, in `REG_CONST` mode the configuration variable `reg_const_value` is really stored in internal state of the PE rather than in its own configuration register.

# Notes from PH Hardware meeting (4/18)
* (From Kayvon) The distinction between architecture and implementation is important for us. Are we designing a DSL for specifying processor architectures or process implementations? The conclusion is that our language is for specifying "architectures" -- namely, for specifying the interface and functional output of processors, not the implementation. In particular, things like an ISA, instruction decode semantics, # of registers, etc. are in our scope. Thing like pipeline depth, out-of-order execution, branch prediction are *not* in our scope. There is seemingly some gray area. For example, SIMD execution: SIMD registers and instructions need to be declared as part of the ISA, and is therefore in our scope; however, the manifestation of the SIMD RTL is not in our scope.
  - We can think of a given architecture specification implying a space of valid implementations. Each of those implmentations may have its own tradeoffs but at first, our language is not intended to allow automatic exploration of that design space. We can think of a separate compiler toolchain which produces "optimized" RTL for a given architectural specification.
  - We also consider a Halide like system: similar to decoupling "algorithm" and "schedule", we want to decouple "architecture" and "implementation" (or "functional spec" and "implementation"). In this way we can enable good RTL generation by providing the programmer with abstractios which guide the "implementation", but there exists some notion of a naive or default implementation (similar to Halide, wherein you can provide a custom schedule or simply perform a naive/default schedule). Furthering this analogy, a useful tool would be an automatic method to produce optimized RTL, similar to efforts to design a Halide "auto-scheduler".
* (From Rick) The interconnect implicitly specifies a contract for memories and PE's.
* Much of the need to maintain hard architectural boundaries over time (i.e. fully backwards compatible ISA's) is due to the huge overhead of rewriting the software tools for each new architecture (e.g. compiler, assembler, disassembler). The need to maintain this hard boundary is not so important if we automatically generate some of these software tools.
* An important question is whether or not to require the programmer to specify bit-level decode semantics or have this be a degree-of-freedom over which the system can optimize. There are reasons for both:
  - In the case where the programmer (a) is writing a spec to match a pre-existing implementation, (b) is writing a spec to be backwards compatible with a previous implentation, or (c) has optimized decode semantics, we must allow the programmer to specify these bit patterns.
  - However, it may be that the programmer only wants to write a high-level spec, and is not concerned with these bit patterns. In fact, it may be a service of our language to derive an optimized decoder. (It is unclear how feasible this is.)
  - (From Lenny) One possible view is that there is a continuum, spanning the programmer specifying the decode patterns in their entirety, to the programmer specifying **none** of the decode patterns. It may be possible to allow the progammer to sit anywhere in that range: whatever the programmer wants control over and wants to specify, they can. Whatever is not important to them, they can leave to the system. Actually implementing such a flexible methodology may be difficult.

# More notes (4/25)
## Thoughts about state
* Could we allow some inter-mix of verilog/RTL, python, and custom syntax? Is this useful or overkill? Is it possible to design such a language? Would it devlove into people just using RTL? If we do this, then people could specify RTL for stateful components like registers
* One thought is that combinational-/sequential-ness of code is inferred. Specifically, sequential logic is quarantined to reads and writes from stateful components which are explicitly declared as being stateful (e.g. as regfiles or memory components). We can have one architectural memory primitive which is a timing-less "word"-addressable memory block (where "word can be customized for each such component, e.g. we can have a 32-bit regfile and a 128-bit wide memory).
  - If we follow this, then we can the specification is bound to being at the architectural level and **not** at the implementation/RTL level. For example, all statements involving such components would look like:

    ```
    regfile[a] <- regfile[b] + addr[c]  # generic add
    M[addr] <- regfile[a]  # store
    ```

    This is **very** close to ISA specification-like semantics and would allow quick specification, without worrying about timing, memory controllers, etc.
  - Often such stateful componetns are nested, e.g. address calculation:

    ```
    M[regfile[a] + imm] <- regfile[b]  # store effective addr
    ```

    Such nesting should be straight-forward to specify and have very **well defined and clear semantics**. Furthermore, it should be supported by downstream components (compilers, etc.). There may need to be certain types of restrictions, for example nested memory references are not common in ISA's:

    ```
    M[M[regfile[a]] <- regfile[b]
    ```

    Such operations would normally happen as a sequence of multiple ISA instructions (load, store effective addr). An important question is whether to allow the designer to specify these constraints somehow, or have the system impose these constraints (unclear how to do the latter in a principled fashion).
  - It seems valuable to distinguish between off-PE vs on-PE stateful components. One possible design is to require programmers to specify whether stateful components are `external` or `internal`. For example we may want to specify a large off-chip memory that's independent from an on-chip regfile. One possible design is to have two fundamentally types of stateful components: `memory` and `regfile`. Both are instanced similarly (both require word-size, address space) and have similar interfaces/usage in downstream code (see later for the differences); however, `memory` is assumed to be outside of the PE, where as `regfile` is assumed to be inside. This distinction has the following implications:
    + The generated RTL would be very different. All read and write logic to `regfile` components would be contained inside the RTL. However, `memory` components would not generate any explicit RTL. Instead the memory would be assumed to be an external module, and the PE would expose a set of input and output wires (e.g. addr, data_in, data_out). Specifying or generating/inferring this interface maybe hard and in fact maybe the main point where these abstractions break down.
    + Generally, both `regfile` and `memory` components could be used similarly (indexed using an appropriately sized wire, and can be read and written to). However, we would likely impose different restrictions for each. For example, in a single "combninational" path, you can only read or write from memory once, therefore, nested memory references should not be allowed. Similarly, regfiles can only be addressed by combinational values (i.e. `regfile[regfile[a]]` should be disallowed).
    + We may want memory to be a singleton, where as generally it makes sense to have several regfiles (e.g. one for scalars and one for vectors). 
  - This abstraction allows us to maintain concepts like virtual memory.
-
## What is the interface of a PE
* In general what are the inputs and outputs for a PE? Can they be inferred from other parts of the spec? Or should they be explicitly declared? Requiring programmers to declare them explicitly seems very RTL-like.
* One thought is that anything that would tradititionally be output of fetch (instruction), output to memory (addr, data_in), input from memory (data_out), or output to fetch (branch condition) should be automatically added to the interface. Anything else needs to be explicitly declared. This makes sense for processors, but the CGRA PE lacks many of these. In fact, the only inputs and outputs are data wires plus an output irq signal.
## Branch control
## Extracting semantic information from RTL-like code (or generic code)
## Interrupts
## Error messages