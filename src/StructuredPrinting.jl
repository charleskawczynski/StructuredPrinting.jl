module StructuredPrinting

import Crayons
export @structured_print, PrintingOptions, GoodProperties

"""
    PrintingOptions(
        [types...];
        match_only::Bool = false
        skip_known_recursion::Bool = false
    )

Printing options for `@structured_print`:

 - `match_only`: only print properties that match the given types
 - `print_type_params`: print type parameters (e.g., `prop::typeof(prop)`)
 - `skip_known_recursion`: skip recursion for `UnionAll` and `DataType`
    types (which results in infinite recursion)

## Example

```julia
struct Leaf{T} end
po = PrintingOptions(typeof(Leaf{Int}));
@structured_print t PrintingOptions((typeof(t.branchB), typeof(t.branchA)))
@structured_print t PrintingOptions(typeof(t.branchB); match_only=true)
```
"""
struct PrintingOptions{T}
    types::T
    match_only::Bool
    print_type_params::Bool
    skip_known_recursion::Bool
    function PrintingOptions(
            types...;
            match_only = false,
            print_type_params=false,
            skip_known_recursion=false
        )
        if (types isa AbstractArray || types isa Tuple) && length(types) > 0
            types = types[1]
        else
            types = (Union{},)
        end
        return new{typeof(types)}(
            types,
            match_only,
            print_type_params,
            skip_known_recursion
        )
    end
end
PrintingOptions(type::Type; kwargs...) = PrintingOptions((type, ); kwargs...)

PrintingOptions() = PrintingOptions(();)
GoodProperties() =
    PrintingOptions(
        (UnionAll, DataType);
        match_only = false,
        skip_known_recursion = true
    )

function _structured_print(io, obj, pc; po, name)
    for pn in propertynames(obj)
        prop = getproperty(obj, pn)
        pc_full = (pc..., ".", pn)
        pc_string = name*string(join(pc_full))
        if any(map(type -> prop isa type, po.types))
            suffix = po.print_type_params ? "::$(typeof(prop))" : ""
            pc_colored = Crayons.Box.RED_FG(pc_string)
            println(io, "$pc_colored$suffix")
            po.skip_known_recursion || _structured_print(io, prop, pc_full; po, name)
        else
            if !po.match_only
                suffix = po.print_type_params ? "::$(typeof(prop))" : ""
                println(io, "$pc_string$suffix")
            end
            _structured_print(io, prop, pc_full; po, name)
        end
    end
end

print_name(io, name, po) = po.match_only || println(io, name)

function structured_print(io, obj, name, po::PrintingOptions = PrintingOptions())
    print_name(io, name, po)
    _structured_print(
        io,
        obj,
        (); # pc
        po,
        name,
    )
    println(io, "")
end

"""
    @structured_print obj options

Recursively print out propertynames of
`obj` given options `options`. See
[`PrintingOptions`](@ref) for more information
on available options.
"""
macro structured_print(obj, po)
    return :(
        structured_print(
            stdout,
            $(esc(obj)),
            $(string(obj)),
            $(esc(po)),
        )
    )
end

"""
    @structured_print obj options

Recursively print out propertynames of
`obj` given options `options`. See
[`PrintingOptions`](@ref) for more information
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
