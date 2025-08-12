close all; clear; clc;

%% 0) Parametreler
prn       = 5;
fs        = 5e6;
fc        = 1e6;
codeRate  = 1.023e6;
Nchips    = 1023;
samplesPerChip = round(fs / codeRate);
snr_db    = 10;                  
doppler_range = -6000:100:6000;
true_doppler  = 4000;

%% 1) C/A Kodu Üretimi
ca_bits = generateCAcode(prn);  % ±1
ca_sig  = repelem(ca_bits, samplesPerChip);
t       = (0:length(ca_sig)-1)/fs;

%% 2) BPSK Modülasyon (Doppler etkili)
carrier = cos(2*pi*(fc + true_doppler)*t);
tx = ca_sig .* carrier;

%% 3) Gürültü + Parazit + Multipath Ekle
% 3.1 AWGN
rx = awgn(tx, snr_db, 'measured');

% 3.2 Dar Bant Parazit
nb_freq = fc + 2000;        % 2 kHz offset
nb_amp = 0.5;               % parazit genliği
narrowband = nb_amp * cos(2*pi*nb_freq*t);
rx = rx + narrowband;

% 3.3 Multipath (gecikmeli zayıf kopya)
delay_samp = 100;           % 100 örnek gecikme
attenuation = 0.3;
rx = rx + [zeros(1,delay_samp), attenuation*tx(1:end-delay_samp)];

%% 4) Doppler Taraması
best_corr = -Inf;
best_freq = 0;
best_rx_filt = [];
peak_list = zeros(size(doppler_range));

b = fir1(128, 1.2e6/(fs/2));  % LPF filtresi

for i = 1:length(doppler_range)
    doppler = doppler_range(i);
    carrier_local = cos(2*pi*(fc + doppler)*t);
    rx_mix = rx .* (2 * carrier_local);
    rx_filt = filter(b, 1, rx_mix);
    
    delay = round(length(b)/2);
    rx_corr = rx_filt(delay+1:end);
    ca_corr = ca_sig(1:length(rx_corr));
    
    [c, ~] = xcorr(rx_corr, ca_corr);
    peak = max(abs(c));
    peak_list(i) = peak;

    if peak > best_corr
        best_corr = peak;
        best_freq = doppler;
        best_rx_filt = rx_corr;
    end
end

fprintf("En iyi Doppler frekansı: %d Hz (peak: %.2f)\n", best_freq, best_corr);

%% 5) Geri Kazanım ve BER Hesabı
idx0 = round(samplesPerChip / 2);
max_samples = length(best_rx_filt);
target_length = idx0 + (Nchips-1)*samplesPerChip;

if target_length > max_samples
    max_chip_count = floor((max_samples - idx0)/samplesPerChip);
    fprintf('[Uyarı] Yetersiz örnek: %d chip kullanılacak.\n', max_chip_count);
    ca_bits = ca_bits(1:max_chip_count);
    ca_rec = best_rx_filt(idx0 : samplesPerChip : idx0+(max_chip_count-1)*samplesPerChip);
else
    ca_rec = best_rx_filt(idx0 : samplesPerChip : idx0+(Nchips-1)*samplesPerChip);
end

ca_rec = sign(ca_rec);
correct = sum(ca_rec == ca_bits);
ber = sum(ca_rec ~= ca_bits) / length(ca_bits);

fprintf('C/A geri kazanım oranı: %.2f%%\n', (correct/length(ca_bits))*100);
fprintf('Bit Hata Oranı (BER): %.4f\n', ber);

%% 6) Korelasyon Grafiği
[c_final, lags] = xcorr(best_rx_filt, ca_sig(1:length(best_rx_filt)));
figure;
plot(lags, c_final);
xlabel('Lag (örnek)');
ylabel('Korelasyon');
title('Doppler araması sonrası en iyi taşıyıcı ile korelasyon');
grid on;

%% 7) Filtre Çıkışı
figure;
plot(best_rx_filt);
xlabel('Örnek');
ylabel('Genlik');
title('En iyi Doppler frekansı ile filtre çıkışı');
grid on;

%% 8) İlk 100 Chip Karşılaştırması
figure;
stem(ca_bits(1:100), 'b', 'filled'); hold on;
stem(ca_rec(1:100), 'r--'); 
legend('Gerçek', 'Tahmin');
xlabel('Chip No'); ylabel('Değer');
title('İlk 100 Chip için C/A Kodu Karşılaştırması');
grid on;

%% 9) Doppler Frekansa Karşı Korelasyon Peak Grafiği
figure;
plot(doppler_range, peak_list, '-o');
xlabel('Doppler Frekansı (Hz)');
ylabel('Korelasyon Zirvesi');
title('Doppler Aralığına Göre Korelasyon Değeri');
grid on;
