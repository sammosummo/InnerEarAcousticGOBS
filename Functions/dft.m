function H=dft(h,n)
% Returns the positive n-point fft spectrum H of the time sequence h
%
% H=dft(h,n)

if exist('n')==0
    n=length(h);
end
H=fft(h,n);
H=H(1:length(H)/2,:,:);