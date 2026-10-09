needsPackage "MinimalPrimes";
needsPackage "Saturation";

------------------------------------------------------------
-- Hasse-Witt matrix of a plane hypersurface
--
-- f must be homogeneous of degree d in K[x,y,z],
-- with char(K) = p > 0.
--
-- The basis is indexed by positive triples
--     (a,b,c),  a+b+c=d.
------------------------------------------------------------

planeHasseWittMatrix = f -> (
    R := ring f;
    K := coefficientRing R;
    p := char K;
    d := first degree f;

    pa := (d-1)*(d-2)//2;

    U := {};

    for a from 1 to d-2 do (
        for b from 1 to d-a-1 do (
            U = append(U,{a,b,d-a-b});
        );
    );

    assert(#U == pa);

    fp := f^(p-1);

    coeffAt := e -> (
        if e#0 < 0 or e#1 < 0 or e#2 < 0 then
            0_K
        else
            coefficient(
                R_0^(e#0) *
                R_1^(e#1) *
                R_2^(e#2),
                fp
            )
    );

    H := matrix table(
        pa,
        pa,
        (i,j) -> (
            u := U#i;
            v := U#j;

            e := {
                p*(v#0) - u#0,
                p*(v#1) - u#1,
                p*(v#2) - u#2
            };

            coeffAt e
        )
    );

    H
);


------------------------------------------------------------
-- Apply Frobenius entrywise to a matrix
------------------------------------------------------------

frobeniusTwist = (A,p) -> (
    matrix table(
        numRows A,
        numColumns A,
        (i,j) -> (A_(i,j))^p
    )
);


------------------------------------------------------------
-- Matrix of the n-th iterate of semilinear Frobenius:
--
-- H * H^(p) * H^(p^2) * ... * H^(p^(n-1))
------------------------------------------------------------

frobeniusProduct = (H,p,n) -> (
    if n < 1 then error "n must be positive";

    P := H;
    T := H;

    for r from 2 to n do (
        T = frobeniusTwist(T,p);
        P = P*T;
    );

    P
);


------------------------------------------------------------
-- p-rank of normalization of an irreducible plane curve
-- having at worst ordinary nodes.
--
-- OUTPUT is a HashTable.
------------------------------------------------------------

pRankNodalPlaneCurve = f -> (

    R := ring f;
    K := coefficientRing R;

    --------------------------------------------------------
    -- Basic checks
    --------------------------------------------------------

    if numgens R != 3 then
        error "The ambient ring must have exactly three variables.";

    if char K == 0 then
        error "The coefficient field must have positive characteristic.";

    if not isHomogeneous f then
        error "The polynomial must be homogeneous.";

    p := char K;
    d := first degree f;
    pa := (d-1)*(d-2)//2;

    --------------------------------------------------------
    -- Irreducibility
    --
    -- For a polynomial over a field, irreducibility implies
    -- reducedness.
    --------------------------------------------------------

    irreducible := isPrime f;

    if not irreducible then (

        new HashTable from {
            "accepted" => false,
            "reason" => "The polynomial is not irreducible over the coefficient field.",
            "degree" => d
        }

    ) else (

        ----------------------------------------------------
        -- Projective singular scheme
        ----------------------------------------------------

        J := ideal(
            f,
            diff(R_0,f),
            diff(R_1,f),
            diff(R_2,f)
        );

        singI := saturate J;

        smooth := singI == ideal(1_R);

        delta := null;
        curveType := null;
        reason := null;

        ----------------------------------------------------
        -- Smooth case
        ----------------------------------------------------

        if smooth then (
            delta = 0;
            curveType = "smooth";
        )

        ----------------------------------------------------
        -- Singular case:
        --
        -- For an irreducible reduced plane curve,
        -- if the projective singular scheme is finite
        -- and reduced, every singularity is an ordinary node.
        ----------------------------------------------------

        else (
            if codim singI != 2 then (
                reason =
                "The singular locus is not zero-dimensional.";
            )
            else if radical singI != singI then (
                reason =
                "The singular scheme is nonreduced, so the curve has a singularity worse than a node.";
            )
            else (
                delta = degree singI;
                curveType = "nodal";
            );
        );

        ----------------------------------------------------
        -- Reject curves that are not smooth/nodal
        ----------------------------------------------------

        if delta === null then (

            new HashTable from {
                "accepted" => false,
                "irreducible" => true,
                "smooth" => false,
                "reason" => reason,
                "degree" => d,
                "arithmeticGenus" => pa,
                "singularIdeal" => singI
            }

        ) else (

            ------------------------------------------------
            -- Genus of the normalization
            ------------------------------------------------

            g := pa - delta;

            if g < 0 then
                error "Computed geometric genus is negative.";

            ------------------------------------------------
            -- Genus zero: no Jacobian
            ------------------------------------------------

            if pa == 0 then (

                new HashTable from {
                    "accepted" => true,
                    "curveType" => curveType,
                    "irreducible" => true,
                    "smooth" => smooth,
                    "degree" => d,
                    "arithmeticGenus" => pa,
                    "delta" => delta,
                    "geometricGenus" => g,
                    "pRankNormalization" => 0
                }

            ) else (

                ------------------------------------------------
                -- Hasse-Witt matrix on H^1(C,O_C)
                ------------------------------------------------

                H := planeHasseWittMatrix f;

                ------------------------------------------------
                -- Stable Frobenius:
                --
                -- dim H^1(C,O_C) = pa, so pa iterates suffice.
                ------------------------------------------------

                Fstable := frobeniusProduct(H,p,pa);

                stableRank := rank Fstable;

                aNum := pa - rank H;

                ------------------------------------------------
                -- Normalization exact sequence:
                --
                -- 0 -> k^delta
                --   -> H^1(C,O_C)
                --   -> H^1(C~,O_C~)
                --   -> 0
                --
                -- Frobenius is bijective on the node term,
                -- hence
                --
                -- p-rank(Jac(C~)) = stableRank - delta.
                ------------------------------------------------

                pRankNorm := stableRank - delta;

                assert(pRankNorm >= 0);
                assert(pRankNorm <= g);

                new HashTable from {
                    "accepted" => true,
                    "curveType" => curveType,
                    "irreducible" => true,
                    "smooth" => smooth,
                    "degree" => d,
                    "arithmeticGenus" => pa,
                    "delta" => delta,
                    "geometricGenus" => g,
                    "singularIdeal" => singI,
                    "hasseWitt" => H,
                    "frobeniusStableProduct" => Fstable,
                    "stableRankH1OC" => stableRank,
                    "pRankNormalization" => pRankNorm,
                    "aNumberNormalization" => aNum
                }
            )
        )
    )
);
