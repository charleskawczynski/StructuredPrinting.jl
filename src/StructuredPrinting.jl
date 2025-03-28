module StructuredPrinting

import Crayons
export @structured_print, Options

function type_string(io, obj; maxdepth)
    sz = get(io, :displaysize, displaysize(io))::Tuple{Int, Int}
    S = max(sz[2], 120)
    slim = Base.type_depth_limit(string(typeof(obj)), S; maxdepth)
    return slim
end

"""
    Options(;
        print_obj = Returns(true),
        highlight = Returns(false),
        recurse = x -> !any(y -> x isa y, (UnionAll, DataType)),
        custom = x -> "",
        print_type::Bool = false,
        recursion_depth::Int = 1000,
        max_type_depth::Int = 3
    )

Printing options for `@structured_print`:

 - `print_obj` callable that returns a `Bool` indicating whether the object
   (& maybe type) should be printed.
 - `highlight` callable that returns a `Bool` indicating whether the object
   (& maybe type) should be highlighted.
 - `recurse` callable that returns a `Bool` indicating whether printing should
   recurse further into this object. Default is set to `x -> !any(y -> x isa
   y, (UnionAll, DataType))` as they are defined recursively.
 - `custom` callable that returns an empty string, which appends the printed
   string.
 - `print_type`: callable that returns a `Bool` indicating whether the object's
   type should be printed.
 - `recursion_depth`: Int indicating depth to stop recursing.
 - `max_type_depth`: Int used for depth-limited type printing.

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
@structured_print t Options(;print_obj= x -> x isa typeof(t.branchB))

# Print struct with Tuple of types highlighted
@structured_print t Options(;print_obj= x -> any(y-> x isa y, (typeof(t.branchB), typeof(t.branchA))))
```
"""
struct Options{T, H, R, C, PT}
    print_obj::T
    highlight::H
    recurse::R
    custom::C
    print_type::PT
    recursion_depth::Int
    max_type_depth::Int
end
function Options(;
        print_obj = Returns(true),
        highlight = Returns(false),
        recurse = x -> !any(y -> x isa y, (UnionAll, DataType)),
        custom = x -> "",
        print_type = Returns(true),
        recursion_depth::Int = 1000,
        max_type_depth::Int = 3
    )
    return Options{
        typeof(print_obj),
        typeof(highlight),
        typeof(recurse),
        typeof(custom),
        typeof(print_type)
    }(
        print_obj,
        highlight,
        recurse,
        custom,
        print_type,
        recursion_depth,
        max_type_depth
    )
end

Options(print_obj; kwargs...) = Options(; print_obj, kwargs...)

function _structured_print(io, obj, pc; o::Options, name, counter=0)
    counter > o.recursion_depth && return
    # o.print_obj(obj) || return
    o.recurse(obj) || return
    for pn in propertynames(obj)
        prop = getproperty(obj, pn)
        pc_full = (pc..., ".", pn)
        suffix = o.print_type(prop) ? "::$(type_string(io, prop; maxdepth=o.max_type_depth))" : ""
        pc_string = name*string(join(pc_full))
        pc_colored = o.highlight(prop) ? Crayons.Box.RED_FG(pc_string) : pc_string
        o.print_obj(prop) && println(io, "$pc_colored$suffix$(o.custom(prop))")
        _structured_print(io, prop, pc_full; o, name, counter=counter+1)
    end
end

function structured_print(io, obj, name, o::Options = Options())
    o.print_obj(obj) && println(io, name)
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
