kk = QQ

ringP2 = kk[x, y, z];

d = 5

f = (x^2) - (y^2) + (x^3);

f = homogenize(f, z);

factor f

I = ideal(f)

J = ideal(f, diff(x, f), diff(y, f), diff(z, f))

X = Proj(ringP2 / I)

codim singularLocus I

primaryDecomposition J

# decompose I
