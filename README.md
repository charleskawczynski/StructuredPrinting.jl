# StructuredPrinting.jl

A simple Julia package for printing structs in a structured way, while offering a way to filter and highlight specified information. This package was developed for debugging.

<details>
  <summary>The story of how this started</summary>

One day, I was trying to find out if `UnionAll` objects existed in a very large OrdinaryDiffEq integrator. I ended up writing:

```julia
import Crayons
function getpropertyviz(obj, pc = (), indent = "")
    for pn in propertynames(obj)
        prop = getproperty(obj, pn)
        pc_full = (pc..., ".", pn)
        pc_string = string(join(pc_full))
        if prop isa UnionAll || prop isa DataType
            pc_colored = Crayons.Box.RED_FG(pc_string)
            println("$indent $pc_colored :: $(typeof(prop)), FLAGME!")
        else
            println("$indent $pc_string :: $(typeof(prop))")
            getpropertyviz(prop, pc_full, indent*"  ")
        end
    end
end

getpropertyviz(integrator)
```
Which ended up highlighting 3 (of the thousands of) structs that were either `UnionAll`, or `DataType`, and this helped me to identify which structs were responsible for hurting compiler inference in a large codebase.

Since this code was so generic, I thought it might be useful to write a small tool for it and add some bells and whistles. Enter StructuredPrinting.jl.

</details>

## Demo
Here's a demo of this package in action (directly from the test suite):

```julia
struct Leaf{T} end

struct Branch{A,B,C}
    leafA::A
    leafB::B
    leafC::C
end

struct Tree{A,B,C}
    branchA::A
    branchB::B
    branchC::C
end

t = Tree(
    Branch(Leaf{(:A1, :L1)}(), Leaf{(:B1, :L2)}(), Leaf{(:C1, :L3)}()),
    Branch(Leaf{(:A2, :L1)}(), Leaf{(:B2, :L2)}(), Leaf{(:C2, :L3)}()),
    Branch(Leaf{(:A3, :L1)}(), Leaf{(:B3, :L2)}(), Leaf{(:C3, :L3)}()),
)

using StructuredPrinting
# Print struct alone
@structured_print t

# Print struct with type highlighted
@structured_print t Options(typeof(t.branchB))

# Print struct with Tuple of types highlighted
@structured_print t Options((typeof(t.branchB), typeof(t.branchA)))
```

StructuredPrinting can be useful to find which object match certain types, which can be helpful to identify potential inference issues:

```julia
struct Foo{A}
a::A
end
bar(obj, i::Int) = obj.type(i)
obj = (; type = Foo, x = 1, y = 2) # using a (<:Type)::DataType is a performance issue
bar(obj, 3) # make sure this is callable
@code_warntype bar(obj, 3) # demo performance issue

using StructuredPrinting
@structured_print obj Options((UnionAll, DataType)) # highlight `UnionAll` and `DataType`s
# Or, print types directly:
@structured_print obj Options((UnionAll, DataType); print_types=true)
```
