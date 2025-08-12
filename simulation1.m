close all; clc; clear; 
% PRN 1 için kod üret
ca1 = generateCAcode(1);
% PRN 2 için kod
ca2 = generateCAcode(2);


% 2) Normalize edilmiş otokorelasyon
[Rauto,lags] = xcorr(ca1, ca1, 'coeff');
figure; 
plot(lags, Rauto);
title('PRN1 Otokorelasyonu');
xlabel('Delay (chips)'); ylabel('Corr');

% 3) Normalize edilmiş çapraz-korelasyon
[Rcross,~]  = xcorr(ca1, ca2, 'coeff');
figure;
plot(lags, Rcross);
title('PRN1–PRN2 Çapraz Korelasyonu');
xlabel('Delay (chips)'); ylabel('Corr');


