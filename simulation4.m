clear; clc; close all;

%% 1) Parametreler
prn            = 5;
fs             = 5e6;
codeRate       = 1.023e6;
chipsPerCode   = 1023;
SNRdB_list     = [0, 5, 10, 15];
samplesPerChip = round(fs / codeRate);
N              = chipsPerCode * samplesPerChip;
num_trials     = 20;  % Monte Carlo deneme sayısı

%% 2) C/A kod üretimi ve oversample
ca_bits      = generateCAcode(prn);            % [0,1]         % [-1,+1]
tx_code      = repelem(ca_bits, samplesPerChip);
signal_clean = tx_code;
corr_clean   = xcorr(signal_clean, signal_clean, 'coeff');
lags         = -(N-1):(N-1);
center_idx   = find(lags == 0);

%% 3) Hazırlıklar
numSNR        = numel(SNRdB_list);
BER_trials    = zeros(num_trials, numSNR);
SEPR_trials   = zeros(num_trials, numSNR);
PSR_trials    = zeros(num_trials, numSNR);
SNR_est_trials= zeros(num_trials, numSNR);

%% 4) Monte Carlo Döngüsü
for t = 1:num_trials
    for k = 1:numSNR
        SNRdB   = SNRdB_list(k);
        SNRlin  = 10^(SNRdB/10);
        Psig    = mean(signal_clean.^2);
        Pnoise  = Psig / SNRlin;
        sigma   = sqrt(Pnoise);

        % Gürültü ekle
        noise        = sigma * randn(1, N);
        signal_noisy = signal_clean + noise;

        % Korelasyon (normalize)
        corr = xcorr(signal_noisy, tx_code, 'coeff');
        cabs = abs(corr);
        main_peak = cabs(center_idx);

        % Ana pikin çevresini bastır
        suppress_range = (center_idx - 2):(center_idx + 2);
        suppress_range = suppress_range(suppress_range >= 1 & suppress_range <= length(cabs));
        cabs(suppress_range) = 0;

        max_sidelobe = max(cabs);
        PSR_dB = 20 * log10(main_peak / max_sidelobe);

        % BER
        M = reshape(signal_noisy, samplesPerChip, chipsPerCode);
        chip_sum = sum(M, 1);
        rx_bipolar = sign(chip_sum);
        rx_bits = (rx_bipolar + 1) / 2;
        BER = sum(rx_bits ~= ca_bits) / chipsPerCode;

        % SEPR
        err = signal_noisy - signal_clean;
        SEPR_dB = 10 * log10(Psig / mean(err.^2));

        % SNR Estimate
        SNR_est = 10 * log10(mean(signal_clean.^2) / mean(noise.^2));

        % Kayıt et
        BER_trials(t, k)      = BER;
        SEPR_trials(t, k)     = SEPR_dB;
        PSR_trials(t, k)      = PSR_dB;
        SNR_est_trials(t, k)  = SNR_est;
    end
end

% Ortalama ve standart sapma
BER_mean     = mean(BER_trials, 1);
SEPR_mean    = mean(SEPR_trials, 1);
PSR_mean     = mean(PSR_trials, 1);
PSR_std      = std(PSR_trials, 0, 1);
SNR_est_mean = mean(SNR_est_trials, 1);

%% 5) Yazdır
fprintf('SNR(dB) | Ölçülen |   BER    |  SEPR(dB) |  PSR(dB)\n');
fprintf('---------------------------------------------------\n');
for k = 1:numSNR
    fprintf('  %2d     |  %6.2f | %8.2e |   %6.2f  |  %6.2f\n', ...
        SNRdB_list(k), SNR_est_mean(k), BER_mean(k), SEPR_mean(k), PSR_mean(k));
end

%% 6) Korelasyon Grafiği
figure('Name','Korelasyon Karşılaştırması','Position',[100 100 900 600]);
subplot(2,1,1); plot(lags, corr_clean); title('Gürültüsüz Korelasyon');
xlabel('Lag'); ylabel('Korelasyon'); grid on;

% Gürültülü bir örnek korelasyon (son denemeden)
subplot(2,1,2); hold on; grid on;
for k = 1:numSNR
    SNRdB   = SNRdB_list(k);
    SNRlin  = 10^(SNRdB/10);
    sigma   = sqrt(mean(signal_clean.^2) / SNRlin);
    noise   = sigma * randn(1, N);
    noisy   = signal_clean + noise;
    c       = xcorr(noisy, tx_code, 'coeff');
    plot(lags, c, 'DisplayName', sprintf('%d dB', SNRdB));
end
legend('show'); title('Gürültülü Korelasyonlar'); xlabel('Lag'); ylabel('Korelasyon');

%% 7) BER ve SEPR Grafikleri
figure('Name','BER & SEPR vs SNR');
subplot(2,1,1);
semilogy(SNRdB_list, BER_mean, '-o'); grid on;
title('BER vs SNR'); xlabel('SNR (dB)'); ylabel('Bit Hata Oranı');

subplot(2,1,2);
plot(SNRdB_list, SEPR_mean, '-o'); grid on;
title('SEPR vs SNR'); xlabel('SNR (dB)'); ylabel('SEPR (dB)');

%% 8) PSR Grafiği (Ortalama ± Standart Sapma)
figure('Name','PSR vs SNR');
errorbar(SNRdB_list, PSR_mean, PSR_std, '-s'); grid on;
title('PSR vs SNR (Ortalama ± Std)'); xlabel('SNR (dB)'); ylabel('PSR (dB)');
