function phi=angleDeg(H)
% Calculates and unwraps the phase phi in degrees of the transfer function H
% 
% phi=angleDeg(H)

phi=180/pi*unwrap(angle(H));