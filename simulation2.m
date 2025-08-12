close all; clear; clc;

%% 1) Parametreler
fs               = 5e6;        % Örnekleme frekansı (Hz)
code_rate        = 1.023e6;    % C/A kod hızı (Hz)
chips_per_code   = 1023;
samples_per_chip = round(fs/code_rate);
samples_per_code = chips_per_code * samples_per_chip;
t                = (0:samples_per_code-1)/fs;

% Doppler frekansları (simülasyon ve test için)
simulated_doppler = [1000, -2000];  % Hz (her PRN için bir Doppler)
doppler_test_range = -5000:1000:5000;  % Hz aralığında test

% Gürültü seviyesi
noise_std = 0.5;

%% 2) Simüle edilecek PRN’ler
simulate_prns = [3, 7];  % sinyal içeren PRN’ler

received_signal = zeros(1, samples_per_code);

%% 3) Sinyali oluştur (her PRN için faz + doppler)
for i = 1:length(simulate_prns)
    prn     = simulate_prns(i);
    doppler = simulated_doppler(i);
    delay   = randi([0, samples_per_code-1]);

    ca           = generateCAcode(prn);
    ca_upsampled = repelem(ca, samples_per_chip);
    ca_shifted   = circshift(ca_upsampled, delay);
    ca_doppler   = ca_shifted .* exp(1j*2*pi*doppler*t);

    received_signal = received_signal + real(ca_doppler);
    fprintf('Simüle PRN %2d | Delay = %4d | Doppler = %+5d Hz\n', prn, delay, doppler);
end

%% 4) Gaussian gürültü ekle
received_signal = received_signal + noise_std * randn(size(received_signal));

%% 5) Acquisition Test (PRN 1–32)
figure;
for prn = 1:32
    max_corr = 0;
    best_dopp = 0;
    best_delay = 0;

    for doppler = doppler_test_range
        ca          = generateCAcode(prn);
        ca_upsample = repelem(ca, samples_per_chip);
        ca_shifted  = ca_upsample .* exp(-1j*2*pi*doppler*t);  % conjugate Doppler
        [c, lags]   = xcorr(received_signal, ca_shifted);
        mag         = abs(c);
        [peak, idx] = max(mag);
        
        if peak > max_corr
            max_corr  = peak;
            best_dopp = doppler;
            best_delay = lags(idx);
            best_mag = mag;
            best_lags = lags;
        end
    end

    % Peak Ratio hesapla
    mag_sorted = sort(best_mag, 'descend');
    peak_ratio = mag_sorted(1) / (mag_sorted(2) + eps);
    
    % SNR tahmini
    snr_est = 10 * log10(max_corr / (mean(best_mag)+eps));

    % Raporlama
    status = "yok";
    if ismember(prn, simulate_prns)
        status = "VAR";
    elseif peak_ratio > 1.5 && snr_est > 5  % basit eşik kuralı
        status = "ZAYIF VAR";
    end

    fprintf('PRN %2d | Corr Peak = %.1f | SNR ≈ %.2f dB | Peak Ratio = %.2f | Doppler = %+5d | Durum: %s\n',...
        prn, max_corr, snr_est, peak_ratio, best_dopp, status);

    % Grafik
    subplot(8, 4, prn);
    plot(best_lags, best_mag);
    title(sprintf('PRN %d (%s)', prn, status));
    xlabel('Lag'); ylabel('|Korelasyon|');
    grid on;
end
