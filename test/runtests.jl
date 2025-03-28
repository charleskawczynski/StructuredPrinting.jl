using Test
using StructuredPrinting

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

@testset "StructuredPrinting" begin
    # Print struct alone
    @structured_print t
end

@testset "StructuredPrinting with types" begin
    # Print struct with type
    @structured_print t Options(x-> x isa typeof(t.branchB))
    # Print struct with Tuple of types
    types = (typeof(t.branchB), typeof(t.branchA))
    @structured_print t Options(x->any(y->x isa y, types))
end

@testset "StructuredPrinting with types and matching" begin
    # Print struct with type
    print_obj = x->x isa typeof(t.branchB)
    @structured_print t Options(;print_obj, highlight = print_obj)
    # Print struct with Tuple of types
    types = (typeof(t.branchB), typeof(t.branchA))
    print_obj = x -> any(y-> x isa y, types)
    @structured_print t Options(;print_obj, highlight = print_obj)
end

@testset "StructuredPrinting with types and matching" begin
    # Print struct with type
    print_obj = x->x isa typeof(t.branchB)
    @structured_print t Options(;print_obj, highlight = print_obj, print_type = Returns(true))
    # Print struct with Tuple of types
    types = (typeof(t.branchB), typeof(t.branchA))
    print_obj = x -> any(y-> x isa y, types)
    @structured_print t Options(; print_obj, print_type = Returns(true))
end

@testset "StructuredPrinting with recursive objects" begin
    BC = Base.Broadcast.broadcasted
    a = [1]
    b = [1]
    c = [1]
    bc = BC(+, a, BC(*, b, BC(-, a, c)))
    print_obj = x -> x === a
    @structured_print bc Options(;print_obj, print_type = Returns(true))
end
