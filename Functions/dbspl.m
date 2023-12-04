function Lp=dbspl(p)
% Returns the sound-pressure level Lp corresponding to the sound pressure p
%
% Lp=dbspl(p)

Lp=20*log10(abs(p)/2e-5);