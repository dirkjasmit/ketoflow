# ketoflow
Analyze EMG signals for PPI keto project

MATLAB toolbox for the PPI experiment measured with the ANT Neuro Eego and waveguard cap w/ 4 EOG/EMG leads

* Install MATLAB
* Install EEGLAB (tested with 2023 version)
* Using the Manage EEGLAB extensions install:
  - bva-io
  - ANTeepimport
  to allow importing EEG exoprted files

NOTE export as brain vision analyzer or ANT neuro cnt file
NOTE do not apply the montage when exporting (default is ON, must be OFF)

Start GUI:
- open MATLAB
- run >>addpath(<EEGLAB folder>)
- run >>eeglab
- run >>guide and navigate to the Ketoflow.fig file. This will open the editor
- run the Ketoflow GUI with the green triangle.

<img width="311" alt="image" src="https://github.com/user-attachments/assets/87f3c634-2741-40fd-996c-3a63200c2561">

Follow the buttons (largely) from top to bottom
- Open
- Extract
- Epoch
- (optional filter)
- click Abs: taking Abs is recommended
- Score
Copy the data from the top table for getting dat from each trial
Copy from the bottom table to get summary (peak amplitude avg across trails types 15--19, window 20-120 ms)
