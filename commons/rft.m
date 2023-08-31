function [z] = rft(x, np, nb, df, fc, pri, dv, vel_min, nv, c)

fr = fc + ((0 : nb - 1) - (nb - 1) / 2) * df;
unv = c / fc / pri / 2;

idx_alpha = (0 : np - 1)' + np;
idx_upsilon = (-(np - 1) : (nv - 1))' + np;
idx_gamma = (0 : nv - 1)' + np;

num_fft = 2^nextpow2(np + nv - 1);

ratio = fr / fc;
w_angle = -2 * 1i * pi * dv / unv .* ratio;
a_angle = 2 * 1i * pi * vel_min / unv .* ratio;

omega = exp((((-(np - 1) : max((np - 1), (nv - 1)))'.^2) / 2) * w_angle);
upsilon = fft(conj(omega(idx_upsilon, :)), num_fft);

beta = exp(-(idx_alpha - np) * a_angle) .* omega(idx_alpha, :);
chi = fft(x .* beta, num_fft);
gamma = ifft(chi .* upsilon, num_fft);

phi = exp(-1i * 2 * pi / c * np * pri * ((0 : nv - 1)' * dv + vel_min) * fr);
z = fft(gamma(idx_gamma, :) .* omega(idx_gamma, :) .* phi, nb, 2);

end