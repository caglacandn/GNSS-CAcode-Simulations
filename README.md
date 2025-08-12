# GNSS Signal Processing and Simulation in MATLAB

This repository contains MATLAB implementations of various simulations and algorithms for **Global Navigation Satellite Systems (GNSS)** signal processing, error analysis, and positioning.  
It is developed as part of a project at **Yıldız Technical University** focusing on GPS L1 C/A code generation, acquisition, tracking, modulation/demodulation, noise analysis, and Differential GPS (DGPS) performance evaluation.

---

## 📌 Features

1. **C/A Code Generation**
   - Function `generateCAcode.m` generates GPS L1 C/A (Coarse/Acquisition) PRN codes using LFSR-based Gold code generation.
   - Supports PRN 1–32.
   - Includes autocorrelation and cross-correlation analysis.
<img width="1097" height="505" alt="image" src="https://github.com/user-attachments/assets/6118c32c-3a3f-40be-a356-6c9d93071409" />

2. **Satellite Signal Detection and Acquisition** (`simulation1.m` & `simulation2.m`)
   - Correlation-based PRN detection.
   - Doppler shift estimation.
   - Peak Ratio and SNR-based detection criteria.
<img width="1676" height="853" alt="image" src="https://github.com/user-attachments/assets/ddc8eff4-8366-4387-a9ec-0c516605ad30" />

3. **Signal Modulation & Demodulation** (`simulation3.m`)
   - BPSK modulation of C/A codes.
   - Doppler effect simulation.
   - Narrowband interference and multipath channel modeling.
   - BER calculation and correlation peak analysis.
<img width="1985" height="834" alt="image" src="https://github.com/user-attachments/assets/b98959f5-aec5-4a9a-b52b-92018358660c" />

4. **Noise Performance Analysis** (`simulation4.m`)
   - Performance metrics: **BER**, **SEPR (Signal-to-Error Power Ratio)**, **PSR (Peak-to-Sidelobe Ratio)**.
   - Monte Carlo simulations under various SNR levels.
<img width="2029" height="587" alt="image" src="https://github.com/user-attachments/assets/95cd4034-fd6b-42be-8f31-fbe919b6dcc8" />


5. **GPS vs DGPS Positioning Simulation** (`simulation5.m`)
   - Comparison of GPS and DGPS positioning accuracy.
   - Error visualization on maps.
   - CDF, histogram, and time-series error plots.
   - Environment modeling: *Urban* and *Open Sky* scenarios.
<img width="1889" height="894" alt="image" src="https://github.com/user-attachments/assets/c94007b6-8dc8-4ebc-800a-7fbfb27c4171" />
<img width="2000" height="901" alt="image" src="https://github.com/user-attachments/assets/9f1b0c6e-176e-4d37-aa06-704b5a0db309" />

