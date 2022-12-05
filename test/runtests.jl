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
    @structured_print t Options(typeof(t.branchB))
    # Print struct with Tuple of types
    types = (typeof(t.branchB), typeof(t.branchA))
    @structured_print t Options(types)
end

@testset "StructuredPrinting with types and matching" begin
    # Print struct with type
    @structured_print t Options(typeof(t.branchB); match_only=true)
    # Print struct with Tuple of types
    types = (typeof(t.branchB), typeof(t.branchA))
    @structured_print t Options(types; match_only=true)
end

@testset "StructuredPrinting with types and matching" begin
    # Print struct with type
    @structured_print t Options(typeof(t.branchB); match_only=true, print_types = true)
    # Print struct with Tuple of types
    types = (typeof(t.branchB), typeof(t.branchA))
    @structured_print t Options(types; match_only=true, print_types = true)
end
