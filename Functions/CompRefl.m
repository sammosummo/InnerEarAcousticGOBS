% Calculate reflectance by estimating characteristic impedance and
% compensating for evanescent modes according to Nørgaard et al. (2017), J.
% Acoust. Soc. Am. 142, 3497–3509. The function operates on column vectors.
%
% [R,Z0,L,Zpw]=CompRefl(Z,freq,freqMax)
%
% Output:
% R                 reflectance
% Z0                characteristic imepdance
% L                 evanescent-modes intertance
% Zpw               plane-wave impedance
%
% Input:
% Z                 measured ear-canal impedance
% freq              frequency vector
% freqMax           maximum analysis frequency
%
% As shown by Nørgaard et al. (2020), J. Acoust. Soc. Am. 147, 2334-2344,
% this method works well in adult ears with freqMax = 8000 Hz.
