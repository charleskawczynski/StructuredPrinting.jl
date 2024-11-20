# StructuredPrinting.jl

A simple Julia package for printing structs in a structured way, while offering a way to filter and highlight specified information. This package was developed for debugging.

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
@structured_print t Options(; print_obj = x-> x isa typeof(t.branchB))

# Print struct with Tuple of types highlighted
@structured_print t Options(; print_obj = x->any(y->x isa y, (typeof(t.branchB), typeof(t.branchA))))
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
@structured_print obj Options(; highlight = x->any(y->x isa y, (UnionAll, DataType))) # highlight `UnionAll` and `DataType`s
```
