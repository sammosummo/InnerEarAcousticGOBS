% Interacoustics WBT calibration according to Nørgaard et al. (2017), J.
% Acoust. Soc. Am. 142, 3013-3024, using 4 calibration waveguides with
% diameter of 4 mm and lengths 12, 14.5, 17.5, and 20 mm. The function
% operates on column vectors.
%
% [Ps,Zs,Zref,Zest,epsilon,rho,c,zeta,L]=CalcWBTcal(fftResponseCal,freq,temperatureCal,pressureCal)
%
% Output:
% Ps                source pressure
% Zs                source impedance
% Zref              reference load impedances
% Zest              estimated load impedances
% epsilon           calibration error
% rho               air density
% c                 speed of sound
% zeta              damping factor
% L                 evanescent-modes inertance
%
% Input:
% fftResponseCal    probe frequency responses
% freq              frequency vector
% temperatureCal    temperature
% pressureCal       atmospheric pressure
