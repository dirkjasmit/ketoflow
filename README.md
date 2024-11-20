# ketoflow
Analyze EMG signals for PPI keto project

MATLAB toolbox for the PPI experiment measured with the ANT Neuro Eego and waveguard cap w/ 4 EOG/EMG leads

*** SETUP WITH MATLAB INSTALLED ***

* Install EEGLAB (tested with 2023 version) or unpack the eeglab zip file (light vesion). Make sure the folder is in the same directory as the Ketoflow.m and .fig files. 
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
- Open: select the exported file.
- Extract: extracts the PO5 and Oz channels, which are then subtracted from each other (Oz as ref).
- Epoch: this is done locked to events 15--19. See description file for the meaning of the events. Other events are habituation events and prepulses, but these are not used for epoching. epoching is done from 200 ms prestim (-200 ms) to 300 ms post, with a baseline adjustement from -200 to -120, as -120 is when the prepulse may starts in some trials.
- (optional filter)
- click Abs for taking the absolute value of the responses.
- Score max amplitude from 20 to 120 ms post stimulus:

Copy the data from the top table for getting data from each trial for the file.
Copy from the bottom table to get summary data (peak amplitude avg across trails types 15--19, window 20-120 ms)
