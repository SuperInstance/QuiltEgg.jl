# QuiltEgg.jl

The Quilt cell, ported from the Python `quilt-egg` substrate, on top of the
cross-substrate canary.

The substrate's load-bearing claim is not a data structure:

> **Perception is INDUCED from the relationship graph, not COMPUTED from the stimulus.**

A cell handed the same stimulus should perceive different things depending on who it is
related to. This port exists to test that, in Julia, by execution rather than by reading.

## What the port found

**The claim holds — so completely that the stimulus turns out to be vestigial.**

`resonance(w) = w * (1 - |w - s|)` is monotone increasing in `w` over the range these
modulated edges occupy, so the heavier relationship wins at *every* stimulus:

```
modulated edges   0.026909 (rank 5)   0.028727 (rank 9)
  s = 0.0  0.1  0.3  0.5  0.9  1.0     ->   always rank 9
```

And with an **exact** tie the winner is decided by iteration order, not by the stimulus.

That is a property of `quilt-egg`'s formula, surfaced by porting it and running it. Two
drafts of this test asserted the intuitive thing — that perception tracks the stimulus —
and both failed against the real code. Whether a stimulus with no say is intended is the
author's call; what the code does is now pinned by a test that will fail if it changes.

## API

```julia
Cell(rank; parent=nothing)          # 16 dials, a relationship dict, a witness log
relate_to!(a, b; weight=0.5)       # bidirectional, weight modulated by the constant c
induce_perception(cell, stimulus)   # the rank that resonates most, or nothing if isolated
tick!(cell)                         # one substrate step; dials move with the GRAPH, mod 4
```

`CONSTANTS` carries the substrate physics (`c`, `G`, `h`, `slow`, `fast`) — immutable
across cells, which is what makes a cell's behaviour attributable to its relationships
rather than to its own configuration.

## Tests

```
julia --project=. -e 'using Pkg; Pkg.test()'
```

29 assertions, including the cross-substrate canary, the two-cells-one-stimulus
discrimination, the measured weight-dominance property above, bidirectional modulation,
mod-4 wrap, and an isolated cell's tick being a no-op.

## The chain

```
quilt-canary        Python · TypeScript · Rust · C#   0x024a555471370b18d
QuiltCanary.jl      Julia                              0x024a555471370b18d
QuiltEgg.jl         Julia (the cell, on the canary)    0x024a555471370b18d
```

The canary is how you know the substrate did not change while you were not looking.
