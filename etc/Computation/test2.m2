p = 3;

R = GF(p)[a300, a210, a201, a120, a111, a102, a030, a021, a012];

A = R[x, y, z];

F = a300*x^3 + a210*x^2*y + a201*x^2*z + a120*x*y^2 + a111*x*y*z + a102*x*z^2 + a030*y^3 + a021*y^2*z + a012*y*z^2;

F^(p - 1);

phi = map(R, A, {1_R, 1_R, 1_R});

c111 = coefficient((x * y * z)^(p - 1), F^(p-1));

c111 = phi(c111)