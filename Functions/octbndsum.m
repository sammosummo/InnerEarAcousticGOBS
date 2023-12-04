function Havg=octbndsum(H,freq,centerFreqs)
% Octave-band summation of a frequency response H=dft(h), with frequency
% vector freq, around centerFreqs with equal log spacing.
%
% Havg=octbndsum(H,freq,centerFreqs)

logCenterFreqs=log10(centerFreqs);
for n=1:length(centerFreqs)
    if n==1
        bandSep=10.^(logCenterFreqs(1)+[-diff(logCenterFreqs(1:2))/2 diff(logCenterFreqs(1:2))/2]);
        iBand{n}=find(freq>bandSep(1) & freq<bandSep(2));
    elseif n==length(centerFreqs)
        bandSep=10.^(logCenterFreqs(end)+[-diff(logCenterFreqs(end-1:end))/2 diff(logCenterFreqs(end-1:end))/2]);
        iBand{n}=find(freq>bandSep(1) & freq<bandSep(2));
    else
        bandSep=10.^(logCenterFreqs(n)+[-diff(logCenterFreqs(n-1:n))/2 diff(logCenterFreqs(n:n+1))/2]);
        iBand{n}=find(freq>bandSep(1) & freq<bandSep(2));
    end
    Havg(n)=sqrt(2/(2*length(H))^2*sum(abs(H(iBand{n}).^2)));
end