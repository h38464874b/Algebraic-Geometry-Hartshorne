p = 3; -- choose your prime

A = GF(p)[a300,a210,a201,a120,a111,a102,a030,a021,a012,a003,x,y,z];

f = a300*x^3 + a210*x^2*y + a201*x^2*z + a120*x*y^2 + a111*x*y*z + a102*x*z^2 + a030*y^3 + a021*y^2*z + a012*y*z^2 + a003*z^3;

J = ideal(diff(x,f), diff(y,f), diff(z,f));

Jsat = saturate(J, ideal(x,y,z));

resI = eliminate({x,y,z}, Jsat);

phi = map(A, A, {a300,a210,a201,a120,a111,a102,a030,a021,a012,a003,1_A,1_A,1_A});

g = phi(coefficient(x^(p-1)*y^(p-1)*z^(p-1), f^(p-1)));

-- I = ideal(g);

-- dim singularLocus I

-- J = ideal(
--     g,
--     diff(a300,g),
--     diff(a210,g),
--     diff(a201,g),
--     diff(a120,g),
--     diff(a111,g),
--     diff(a102,g),
--     diff(a030,g),
--     diff(a021,g),
--     diff(a012,g),
--     diff(a003,g)
-- );

-- Jsat = saturate(J, ideal(a300, a210, a201, a120, a111, a102, a030, a021, a012, a003));

-- Jsat == ideal(1_A);
