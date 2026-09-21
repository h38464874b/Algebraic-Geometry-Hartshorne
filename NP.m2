needsPackage "RationalPoints2";

------------------------------------------------------------
-- p-adic valuation
------------------------------------------------------------

vp = (a, p) -> (
    n := abs a;
    e := 0;

    while n != 0 and n % p == 0 do (
        n = n // p;
        e = e + 1;
    );

    e
);

------------------------------------------------------------
-- Compute b^e modulo m
------------------------------------------------------------

powModPoly = (b, e, m) -> (
    T := ring b;

    r := 1_T;
    a := b % m;
    n := e;

    while n > 0 do (
        if n % 2 == 1 then
        r = (r*a) % m;

        n = n // 2;

        if n > 0 then
        a = (a*a) % m;
    );

    r
);

------------------------------------------------------------
-- Number of roots of h(t) in F_q
--
-- #roots = deg gcd(h(t), t^q - t)
------------------------------------------------------------

numberRootsFF = (h, t, q) -> (

    T := ring h;

    -- zero polynomial: every element is a root
    if h == 0_T then
    return q;

    -- nonzero constant: no roots
    if first degree h == 0 then
    return 0;

    -- compute t^q - t modulo h
    r := (powModPoly(t, q, h) - t) % h;

    G := gcd(h, r);

    first degree G
);

------------------------------------------------------------
-- Count points on F = 0 in P^2(F_{p^n})
--
-- Uses:
--
--   affine chart z = 1
--   points at infinity [x:1:0]
--   remaining point [1:0:0]
------------------------------------------------------------

planeCurvePointCountFast = (F, n) -> (

    R0 := ring F;
    p := char R0;
    q := p^n;

    --------------------------------------------------------
    -- Extension field F_{p^n}
    --------------------------------------------------------

    K := GF(p, n, SizeLimit => q+1);

    --------------------------------------------------------
    -- Base change F from F_p to F_{p^n}
    --------------------------------------------------------

    Fq := baseChange(K, F);

    -- Each entry of terms is
    --
    -- ({exponent of x, exponent of y, exponent of z},
    --  coefficient)
    --------------------------------------------------------

    terms := listForm Fq;

    --------------------------------------------------------
    -- Univariate polynomial ring K[t]
    --------------------------------------------------------

    T := K[symbol t];
    t := T_0;

    --------------------------------------------------------
    -- List all elements of K
    --------------------------------------------------------

    elts := if n == 1 then (
        apply(toList(0..(p-1)), i -> i*1_K)
    ) else (
        {0_K} | apply(toList(0..(q-2)), i -> K_0^i)
    );

    --------------------------------------------------------
    -- AFFINE CHART z = 1
    --
    -- For each x = a, form
    --
    --        h_a(t) = F(a,t,1)
    --
    -- and count its F_q-roots.
    --------------------------------------------------------

    Naff := 0;

    for a in elts do (

        h := 0_T;

        for term in terms do (
            e := term#0;
            c := term#1;

            h = h
            + c
            * a^(e#0)
            * t^(e#1);
        );

        Naff = Naff + numberRootsFF(h, t, q);
    );

    --------------------------------------------------------
    -- POINTS AT INFINITY
    --
    -- First count [x:1:0].
    --
    -- This is the number of roots of F(t,1,0).
    --------------------------------------------------------

    hInf := 0_T;

    for term in terms do (
        e := term#0;
        c := term#1;

        if e#2 == 0 then
        hInf = hInf + c*t^(e#0);
    );

    Ninf := numberRootsFF(hInf, t, q);

    --------------------------------------------------------
    -- Remaining point [1:0:0]
    --------------------------------------------------------

    v100 := 0_K;

    for term in terms do (
        e := term#0;
        c := term#1;

        if e#1 == 0 and e#2 == 0 then
        v100 = v100 + c;
    );

    N100 := if v100 == 0_K then 1 else 0;

    --------------------------------------------------------

    Naff + Ninf + N100
);

------------------------------------------------------------
-- Compute
--
-- N_n = #C(F_{p^n}),  n = 1,...,g
------------------------------------------------------------

planeCurvePointCountsFast = (F, gC) -> (

    p := char ring F;

    apply(1..gC, n -> (
            q := p^n;

            print(
                "Counting points over GF(" |
                toString q |
                ")"
            );

            planeCurvePointCountFast(F, n)
    ))
);

------------------------------------------------------------
-- Recover Frobenius polynomial
--
-- P(T) = 1 + c_1 T + ... + c_{2g} T^(2g)
--
-- from point counts N_1,...,N_g
------------------------------------------------------------

frobeniusCoefficients = (N, p, gC) -> (

    --------------------------------------------------------
    -- S_n = sum alpha_i^n
    --     = p^n + 1 - #C(F_{p^n})
    --------------------------------------------------------

    S := apply(
        1..gC,
        n -> p^n + 1 - N#(n-1)
    );

    c := new MutableList from
    apply(0..(2*gC), i -> 0);

    c#0 = 1;

    --------------------------------------------------------
    -- Newton identities:
    --
    -- k*c_k + sum_{i=1}^k c_{k-i} S_i = 0
    --------------------------------------------------------

    for k from 1 to gC do (

        temp := 0;

        for i from 1 to k do (
            temp =
            temp
            + c#(k-i)*S#(i-1);
        );

        if temp % k != 0 then
        error "Error in Newton identities.";

        c#k = -(temp // k);
    );

    --------------------------------------------------------
    -- Functional equation:
    --
    -- c_{2g-i} = p^(g-i) c_i
    --------------------------------------------------------

    for i from 0 to gC-1 do (
        c#(2*gC-i)
        = p^(gC-i)*c#i;
    );

    new List from c
);

------------------------------------------------------------
-- Lower convex hull
------------------------------------------------------------

lowerHull = pts -> (

    H := {};

    scan(pts, P -> (

            H = append(H, P);

            keepGoing := true;

            while #H >= 3 and keepGoing do (

                A := H#(#H-3);
                B := H#(#H-2);
                C := H#(#H-1);

                ------------------------------------------------
                -- Compare slopes AB and BC without division
                ------------------------------------------------

                bad :=
                (B#1-A#1)*(C#0-B#0)
                >=
                (C#1-B#1)*(B#0-A#0);

                if bad then (
                    H =
                    take(H, #H-2)
                    | {H#(#H-1)};
                )
                else (
                    keepGoing = false;
                );
            );
    ));

    H
);

------------------------------------------------------------
-- Newton slopes
--
-- output:
--
-- {{slope,multiplicity}, ...}
------------------------------------------------------------

newtonSlopes = H -> (

    apply(
        0..(#H-2),
        i -> (

            A := H#i;
            B := H#(i+1);

            dx := B#0-A#0;
            dy := B#1-A#1;

            {dy/dx, dx}
        )
    )
);

------------------------------------------------------------
-- MAIN FUNCTION
------------------------------------------------------------

newtonPolygonPlaneCurve = F -> (

    R0 := ring F;
    p := char R0;

    d := first degree F;

    gC := ((d-1)*(d-2)) // 2;

    print(
        "degree = " |
        toString d
    );

    print(
        "genus = " |
        toString gC
    );

    print(
        "characteristic = " |
        toString p
    );

    --------------------------------------------------------
    -- Point counts
    --------------------------------------------------------

    N := planeCurvePointCountsFast(F, gC);

    print "Point counts:";
    print N;

    --------------------------------------------------------
    -- Frobenius polynomial
    --------------------------------------------------------

    c := frobeniusCoefficients(N, p, gC);

    print "Frobenius polynomial coefficients:";
    print c;

    --------------------------------------------------------
    -- Points (i,v_p(c_i))
    --------------------------------------------------------

    pts := {};

    for i from 0 to 2*gC do (
        if c#i != 0 then (
            pts =
            append(
                pts,
                {i, vp(c#i, p)}
            );
        );
    );

    --------------------------------------------------------
    -- Newton polygon
    --------------------------------------------------------

    H := lowerHull pts;

    print "Newton polygon vertices:";
    print H;

    --------------------------------------------------------
    -- Slopes
    --------------------------------------------------------

    slopes := newtonSlopes H;

    print "Newton slopes {slope,multiplicity}:";
    print slopes;

    --------------------------------------------------------
    -- p-rank
    --------------------------------------------------------

    fRank := 0;

    scan(
        slopes,
        s -> (
            if s#0 == 0 then
            fRank = fRank + s#1;
        )
    );

    print(
        "p-rank = " |
        toString fRank
    );

    --------------------------------------------------------

    {N, c, H, slopes, fRank}
);

------------------------------------------------------------
------------------------------------------------------------
-- YOUR CURVE
------------------------------------------------------------
------------------------------------------------------------

p = 2;

n = 3;

R = GF(p)[x, y, z];

-- Replace this by your homogeneous polynomial.
F = x^2 * y^3 + y^2 * z^3 + z^2 * x^3;

NP = newtonPolygonPlaneCurve F
