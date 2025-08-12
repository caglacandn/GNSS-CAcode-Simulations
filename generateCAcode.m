function ca = generateCAcode(prn)
% generateCAcode  GPS C/A kodu üretir (1023 chip)
%   ca = generateCAcode(prn)  verilen uydu PRN numarasına göre 1×1023
%   boyutunda {0,1} değerli C/A kodunu döner.
%
%   G1 geri besleme hk: taps [3 10]
%   G2 geri besleme hk: taps [2 3 6 8 9 10]
%   PRN’e göre G2 çıkışında kullanacağımız iki tap (ICD-GPS-200):
g2taps = [...
    2 6; 3 7; 4 8; 5 9; 1 9; 2 10; 1 8; 2 9; ...
    3 10; 2 3; 3 4; 5 6; 6 7; 7 8; 8 9; 9 10; ...
    1 4; 2 5; 3 6; 4 7; 5 8; 6 9; 1 3; 4 6; ...
    5 7; 6 8; 7 9; 8 10; 1 6; 2 7; 3 8; 4 9];

if prn<1 || prn>32
    error('PRN must be between 1 and 32');
end

% 1) Başlangıç durumu: tüm register’ler “1”
G1 = ones(1,10);
G2 = ones(1,10);

ca = zeros(1,1023);
tap = g2taps(prn,:);

for i = 1:1023
    % 2) G1 çıkışı: son bit
    g1_out = G1(end);
    % G1 geri besleme: XOR(3,10)
    fb1 = xor(G1(3), G1(10));
    
    % 3) G2 çıkışı: PRN’e özel iki tap
    g2_out = xor(G2(tap(1)), G2(tap(2)));
    % G2 geri besleme: XOR(2,3,6,8,9,10)
    fb2 = mod(sum(G2([2 3 6 8 9 10])),2);
    
    % 4) C/A kodu chip’i
    ca(i) = xor(g1_out, g2_out);
    
    % 5) Register’leri kaydır ve yeni bitleri ekle
    G1 = [fb1 G1(1:9)];
    G2 = [fb2 G2(1:9)];
end

% (Opsiyonel) 0/1 yerine ±1’e çevir
ca = 1-2*ca;

end
