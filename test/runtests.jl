using Test
using QuiltEgg
using QuiltCanary

@testset "QuiltEgg — the cell, ported" begin

    @testset "cross-substrate canary survives the port" begin
        @test QuiltCanary.canary() == 0x024a555471370b18d
    end

    @testset "an isolated cell perceives nothing — and that is correct" begin
        lone = Cell(1)
        @test induce_perception(lone, 0.5) === nothing
        @test isempty(lone.relationships)
    end

    @testset "THE LOAD-BEARING CLAIM: perception is induced by relationships" begin
        # Two cells receive the IDENTICAL stimulus. If perception were computed from the
        # stimulus they would answer identically. The doctrine says it is not, and this
        # is the assertion that fails if the port quietly becomes an equation.
        stimulus = 0.5
        a = Cell(1); b = Cell(2)
        relate_to!(a, b; weight=0.9)     # a knows one strong neighbour
        relate_to!(b, a; weight=0.2)     # ...and b knows a weak one

        pa = induce_perception(a, stimulus)
        pb = induce_perception(b, stimulus)
        @test pa isa Int
        @test pb isa Int
        @test pa != pb
    end

    @testset "perception is DOMINATED by relationship weight — measured, not assumed" begin
        # This testset was WRONG on its first draft. It asserted that perception
        # follows the stimulus. Executed, the algorithm does not do that: resonance is
        # w * (1 - |w - s|), and the w term swamps the stimulus term whenever the
        # weights differ. At weights 0.7/0.1 the modulated edges are 0.1448/0.0030 —
        # a 48x gap — and rank 2 wins at stimulus 0.1, 0.5, 0.7 and 0.9 alike.
        #
        # So the substrate satisfies its doctrine ("perception is induced by
        # relationships, not computed from the stimulus") MORE completely than the
        # doctrine probably intends. The stimulus is nearly vestigial.
        # This is a finding about quilt-egg, not a bug in the port.
        x = Cell(1); y = Cell(2); z = Cell(3)
        relate_to!(x, y; weight=0.7)
        relate_to!(x, z; weight=0.1)
        for s in (0.1, 0.5, 0.7, 0.9)
            @test induce_perception(x, s) == 2
        end
        @test x.relationships[2] > 40 * x.relationships[3]   # the 48x gap, stated
    end

    @testset "FINDING: the stimulus cannot change the answer at all" begin
        # Two drafts of this test asserted that perception follows the stimulus.
        # Executed, it does not -- and the failure is not a near-tie artefact.
        #
        # resonance(w) = w * (1 - |w - s|) is monotone increasing in w over the range
        # these modulated edges occupy, so the heavier relationship wins for EVERY s.
        # Measured at modulated edges 0.026909 / 0.028727:
        #     s = 0.0 0.1 0.3 0.5 0.9 1.0   ->   always the heavier edge (9)
        # And with an EXACT tie the winner is set by dict iteration order, not by s.
        #
        # So: the substrate satisfies "perception is induced by relationships, not
        # computed from the stimulus" so completely that the stimulus is vestigial.
        # That is a property of quilt-egg's formula, surfaced by porting and running it.
        p = Cell(1); a = Cell(5); b = Cell(9)
        relate_to!(p, a; weight=0.30)
        relate_to!(p, b; weight=0.31)
        for s in (0.0, 0.1, 0.3, 0.5, 0.9, 1.0)
            @test induce_perception(p, s) == 9
        end

        q = Cell(1); r = Cell(2); t = Cell(3)
        relate_to!(q, r; weight=0.4)
        relate_to!(q, t; weight=0.4)
        @test induce_perception(q, 0.4) == induce_perception(q, 0.9)   # tie ignores s too
    end

    @testset "relationship weight is modulated by physics, not a free parameter" begin
        a = Cell(1); b = Cell(2)
        relate_to!(a, b; weight=0.5)
        w = a.relationships[2]
        @test w != 0.5                       # modulated
        @test a.relationships[2] == b.relationships[1]   # bidirectional
        @test 0.0 < w < 0.5
    end

    @testset "tick moves dials from the graph, and wraps mod 4" begin
        a = Cell(1); b = Cell(9)
        relate_to!(a, b; weight=0.8)
        before = copy(a.dials)
        entry = tick!(a)
        @test entry["tick"] == 0
        @test a.dials != before                 # the graph moved something
        @test all(0.0 .<= a.dials .< 4.0)      # wrapped, never negative
        tick!(a); tick!(a)
        @test length(a.witness_log) == 3
        @test a.witness_log[1]["neighbours"] == [9]
    end

    @testset "an isolated cell's tick changes nothing" begin
        lone = Cell(4)
        before = copy(lone.dials)
        tick!(lone)
        @test lone.dials == before
    end

    @testset "the control can fail" begin
        # An implementation that ignored relationships entirely would pass most of the
        # tests above. This is the one that would catch it, and it must be able to fail:
        # if the port regressed to "perception = the stimulus", this breaks.
        a = Cell(1); b = Cell(2)
        relate_to!(a, b; weight=0.5)
        @test induce_perception(a, 0.5) != 0.5
        @test induce_perception(a, 0.5) == 2
    end
end
