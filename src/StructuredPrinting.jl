module StructuredPrinting

import Crayons
export @structured_print, Options

"""
    Options(
        [types...];
        match_only::Bool = false
        print_types::Bool = false
        recursion_types = (UnionAll,DataType)
        recursion_depth = 1000
    )

Printing options for `@structured_print`:

 - `match_only`: only print properties that match the given types
 - `print_types`: print types (e.g., `prop::typeof(prop)`)
 - `recursion_types`: skip recursing through recursion types (e.g., `UnionAll` and `DataType`)
                      to avoid infinite recursion
 - `recursion_depth`: limit recursion depth (to avoid infinite recursion)

## Example

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
"""
struct Options{T}
    types::T
    match_only::Bool
    print_types::Bool
    recursion_types::Tuple
    recursion_depth::Int
    function Options(
            types...;
            match_only = false,
            print_types = false,
            recursion_types = (UnionAll, DataType),
            recursion_depth = 1000
        )
        if (types isa AbstractArray || types isa Tuple) && length(types) > 0
            types = types[1]
        else
            types = (Union{},)
        end
        return new{typeof(types)}(
            types,
            match_only,
            print_types,
            recursion_types,
            recursion_depth
        )
    end
end
Options(type::Type; kwargs...) = Options((type, ); kwargs...)

Options() = Options(();)

function _structured_print(io, obj, pc; o::Options, name, counter=0)
    counter > o.recursion_depth && return
    for pn in propertynames(obj)
        prop = getproperty(obj, pn)
        pc_full = (pc..., ".", pn)
        pc_string = name*string(join(pc_full))
        if any(map(type -> prop isa type, o.types))
            suffix = o.print_types ? "::$(typeof(prop))" : ""
            pc_colored = Crayons.Box.RED_FG(pc_string)
            println(io, "$pc_colored$suffix")
            if !any(map(x->prop isa x, o.recursion_types))
                _structured_print(io, prop, pc_full; o, name, counter=counter+1)
                counter > o.recursion_depth && return
            end
        else
            if !o.match_only
                suffix = o.print_types ? "::$(typeof(prop))" : ""
                println(io, "$pc_string$suffix")
            end
            if !any(map(x->prop isa x, o.recursion_types))
                _structured_print(io, prop, pc_full; o, name, counter=counter+1)
            end
            counter > o.recursion_depth && return
        end
    end
end

print_name(io, name, o) = o.match_only || println(io, name)

function structured_print(io, obj, name, o::Options = Options())
    print_name(io, name, o)
    _structured_print(
        io,
        obj,
        (); # pc
        o,
        name,
    )
    println(io, "")
end

"""
    @structured_print obj options

Recursively print out propertynames of
`obj` given options `options`. See
[`Options`](@ref) for more information
on available options.
"""
macro structured_print(obj, o)
    return :(
        structured_print(
            stdout,
            $(esc(obj)),
            $(string(obj)),
            $(esc(o)),
        )
    )
end

"""
    @structured_print obj options

Recursively print out propertynames of
`obj` given options `options`. See
[`Options`](@ref) for more information
on available options.
"""
macro structured_print(obj)
    return :(
        structured_print(
            stdout,
            $(esc(obj)),
            $(string(obj)),
        )
    )
end

end # module
