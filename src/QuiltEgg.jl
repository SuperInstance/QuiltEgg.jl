"""
    QuiltEgg

The cell, ported from the Python `quilt-egg` substrate.

The load-bearing claim of this substrate is not a hash and not a data structure. It is:

> **Perception is INDUCED from the relationship graph, not COMPUTED from the stimulus.**

A cell handed the same stimulus perceives different things depending on who it is
related to. That is the inversion of "feed x through an equation." An equation's output
depends on x. A cell's output depends on x *and on the company it keeps* — and the test
suite enforces that, because an implementation that quietly reduces to the equation will
still pass a dozen ordinary assertions.
"""
module QuiltEgg

using QuiltCanary
export Cell, CONSTANTS, relate_to!, induce_perception, tick!

const NUM_DIALS = 16

"""
Immutable substrate physics. These are the substrate's constants, not parameters:
they do not change between cells, which is what makes a cell's behaviour attributable
to its relationships rather than to its own configuration.
"""
const CONSTANTS = (
    c     = 299792458.0,      # speed of light (m/s)
    G     = 6.67430e-11,      # gravitational constant
    h     = 6.62607015e-34,   # Planck constant
    slow  = 0.1,              # substrate tick-rate baseline
    fast  = 10.0,             # relationship-firing rate
)

mutable struct Cell
    rank::Int
    dials::Vector{Float64}
    relationships::Dict{Int,Float64}   # first-class object, not a side table
    witness_log::Vector{Dict{String,Any}}
    parent::Union{Nothing,Int}
    alive::Bool
    birth_tick::Int
    function Cell(rank::Integer; parent::Union{Nothing,Int}=nothing, birth_tick::Integer=0)
        new(Int(rank), zeros(Float64, NUM_DIALS), Dict{Int,Float64}(),
            Dict{String,Any}[], parent, true, Int(birth_tick))
    end
end

"""
    relate_to!(a::Cell, b::Cell; weight=0.5) -> Bool

Form a cellular relationship. It is bidirectional, and the weight is modulated by the
substrate constant `c` — a relationship's strength is physics, not a free parameter.
"""
function relate_to!(a::Cell, b::Cell; weight::Real=0.5)
    c = CONSTANTS.c / 1e8                      # normalized relationship speed
    w = weight * tanh(c * weight / 10)
    a.relationships[b.rank] = w
    b.relationships[a.rank] = w
    return true
end

"""
    induce_perception(cell, stimulus) -> Union{Nothing,Int}

The relationship graph INDUCES perception. The stimulus is not the answer; it is what the
relationships *resonate* with. Returns the rank of the most-resonant relationship, or
`nothing` when the cell has no relationships (an isolated cell perceives nothing, which
is the correct answer and not an error).
"""
function induce_perception(cell::Cell, stimulus::Real)
    isempty(cell.relationships) && return nothing
    best_rank, best_res = nothing, -Inf
    for (other_rank, weight) in cell.relationships
        resonance = weight * (1.0 - abs(weight - stimulus))
        if resonance > best_res
            best_res, best_rank = resonance, other_rank
        end
    end
    return best_rank
end

"""
    tick!(cell) -> Dict

Walk one step. Dials are updated from the RELATIONSHIP GRAPH, never from raw input:
each neighbour applies a pull indexed by its own rank, and the dial wraps mod 4.
"""
function tick!(cell::Cell)
    cell.alive || return Dict("tick" => 0, "alive" => false)
    G = CONSTANTS.G * 1e10                          # normalized
    for (other_rank, weight) in cell.relationships
        dial_idx = mod(other_rank, NUM_DIALS)
        pull = G * weight / max(abs(dial_idx - other_rank) + 1, 1)
        cell.dials[dial_idx] = mod(cell.dials[dial_idx] + pull, 4.0)
    end
    entry = Dict("tick" => length(cell.witness_log),
                 "rank"    => cell.rank,
                 "neighbours" => sort(collect(keys(cell.relationships))),
                 "dials"   => copy(cell.dials))
    push!(cell.witness_log, entry)
    return entry
end

end # module
