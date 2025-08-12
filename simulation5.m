close all; clear; clc;

%% 1) Simülasyon Ayarları
duration_sec = 60;         % Simülasyon süresi (saniye)
fs = 1;                    % 1 Hz ölçüm frekansı
N = duration_sec * fs;     % Ölçüm sayısı
time = (0:N-1)';           % Zaman ekseni

% Başlangıç konumu (İstanbul Beşiktaş civarı)
start_lat = 41.0438;  
start_lon = 29.0083;

% Hareket hızı (m/s)
v_lat = 0.5;  % Kuzeye doğru 0.5 m/s
v_lon = 0.1;  % Doğuya doğru 0.1 m/s

% Enlem/boylam başına metre dönüşümü (yaklaşık)
deg_per_meter = 1 / 111000;  

% Ortam tipi
environment = "urban"; % "urban" ya da "open"

switch environment
    case "urban"
        gps_std_dev = 10;     % GPS sapma (m)
        dgps_std_dev = 3;     % DGPS sapma (m)
    case "open"
        gps_std_dev = 5;
        dgps_std_dev = 1;
end

%% 2) Gerçek Araç Rotası
true_lat = start_lat + v_lat * time * deg_per_meter;
true_lon = start_lon + v_lon * time * deg_per_meter;

%% 3) GPS Gürültülü Ölçümler
gps_lat_noise = randn(N,1) .* gps_std_dev * deg_per_meter;
gps_lon_noise = randn(N,1) .* gps_std_dev * deg_per_meter;

gps_lat = true_lat + gps_lat_noise;
gps_lon = true_lon + gps_lon_noise;

%% 4) DGPS Simülasyonu
% Baz istasyonun konumu sabit, hataları ise GPS ile aynı şekilde
base_lat_error = randn(N,1) .* gps_std_dev * deg_per_meter;
base_lon_error = randn(N,1) .* gps_std_dev * deg_per_meter;

% Rover GPS ölçümü + kendi DGPS gürültüsü
rov_lat_gps = true_lat + base_lat_error + randn(N,1) * dgps_std_dev * deg_per_meter;
rov_lon_gps = true_lon + base_lon_error + randn(N,1) * dgps_std_dev * deg_per_meter;

% DGPS düzeltmesi: baz hatasını çıkar
dgps_lat = rov_lat_gps - base_lat_error;
dgps_lon = rov_lon_gps - base_lon_error;

%% 5) Harita Üzerinde Görselleştirme
figure('Name', 'Hareketli Araç - GPS vs DGPS');
geoscatter(gps_lat, gps_lon, 20, 'r', 'filled'); hold on;
geoscatter(dgps_lat, dgps_lon, 20, 'g', 'filled');
geoscatter(true_lat, true_lon, 20, 'k', 'filled');
title("GPS vs DGPS Konumları - Hareketli Araç (" + environment + ")");
legend('GPS', 'DGPS', 'Gerçek Rota');
geobasemap streets;

%% 6) Hata Hesaplama
gps_errors = sqrt((gps_lat - true_lat).^2 + (gps_lon - true_lon).^2) * 111000;
dgps_errors = sqrt((dgps_lat - true_lat).^2 + (dgps_lon - true_lon).^2) * 111000;

%% 7) Zaman Bazlı Hata Grafiği
figure('Name', 'Zamana Bağlı Konum Hataları');
plot(time, gps_errors, 'r', 'LineWidth',1.2); hold on;
plot(time, dgps_errors, 'g', 'LineWidth',1.2);
xlabel('Zaman (saniye)'); ylabel('Hata (metre)');
legend('GPS', 'DGPS'); grid on;
title('Zamana Göre GPS ve DGPS Konum Hatası');

%% 8) Hata Dağılım Histogramı
figure('Name', 'Hata Dağılımı');
histogram(gps_errors, 'FaceColor','r', 'FaceAlpha',0.5); hold on;
histogram(dgps_errors, 'FaceColor','g', 'FaceAlpha',0.5);
xlabel('Hata (metre)'); ylabel('Ölçüm Sayısı');
legend('GPS', 'DGPS'); title('GPS ve DGPS Hatalarının Dağılımı');
grid on;

%% 9) CDF Karşılaştırması
figure('Name', 'CDF Karşılaştırması');
cdfplot(gps_errors); hold on;
cdfplot(dgps_errors);
legend('GPS', 'DGPS');
xlabel('Hata (metre)'); ylabel('Kümülatif Olasılık');
title('GPS ve DGPS Hatalarının Kümülatif Dağılımı');
grid on;

%% 10) Sayısal Özet
fprintf('\n--- HAREKETLİ ARAÇ HATA ÖZETİ (%s ortamı) ---\n', environment);
fprintf('GPS  Ortalama Hata     : %.2f m\n', mean(gps_errors));
fprintf('DGPS Ortalama Hata     : %.2f m\n', mean(dgps_errors));
fprintf('GPS Maksimum Hata      : %.2f m\n', max(gps_errors));
fprintf('DGPS Maksimum Hata     : %.2f m\n', max(dgps_errors));
