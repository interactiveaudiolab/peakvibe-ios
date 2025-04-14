# PeakVibe: A Haptic Interface for Eyes-Free Level Monitoring in Digital Audio Workstations
Hugo Flores García, Annie Chu, Aldo Aguilar, Bryan Pardo

Using audio production tools (e.g. sound file editors, digital audio workstations (DAWs)) 
is essential to producing high-quality music recordings, radio broadcasts, podcasts, and
video. Monitoring the loudness levels of different tracks in an audio production is an 
essential part of the audio production process.  Loudness meters in DAWs convey information 
to the user via visual feedback, by drawing a vertical line that becomes taller as the 
momentary amplitude in the audio track becomes higher.  While sighted users benefit from 
these user interfaces for monitoring loudness, blind and visually impaired users do not 
have an equally accessible solution for monitoring loudness levels in a standard DAW. 
The current approach in the Reaper DAW is to use 
[Peak Watcher](https://reaperaccessibility.com/wiki/Monitoring_levels_when_you_can%27t_see_the_meters)
to read the volume aloud as the audio is played, but this conflicts with listening to the audio.

To fix this, we built PeakVibe, a peak monitoring interface that relies on communicating information 
about an audio signal’s level through haptic feedback instead of auditory feedback. 
PeakVibe relies on a similar principle to previous works, like [HapticWave](https://dl.acm.org/doi/10.1145/2858036.2858304), 
but instead of relying on custom-built hardware (which is prohibitively expensive to manufacture at scale), 
we instead use the haptic motors in the iPhone. Thus, PeakVibe runs on the user’s iPhone, and 
connects to the REAPER Digital  Audio Workstation (DAW). To communicate loudness levels from REAPER to PeakVibe, we built 
[a custom extension for REAPER](https://github.com/interactiveaudiolab/peakvibe-reaper) that broadcasts the 
loudness levels (in dB) over a local  network using OSC. With the user’s iPhone connected to the network, 
PeakVibe captures  the loudness levels being sent by REAPER over the local network and makes the iPhone 
vibrate, mapping each loudness value to a corresponding haptic intensity on the iPhone 
in realtime. Using this setup, the intensity of the loudness waveform is communicated through 
the vibration intensity of the iPhone’s haptic motor, unblocking the user’s auditory channel 
to listen to their audio production, not screen reader announcements.  

## Installing and Building PeakVibe

To install, you will need a Mac with [XCode](https://developer.apple.com/xcode/). 

After installing XCode, open `kiwi.xcodeproj` with XCode, plug in an iPhone X (or newer) to your Mac, select the iPhone as a build target, and build the PeakVibe app. 

If building was successful, a new app (called `kiwi` should show up on your iPhone's screen). 

## Connecting PeakVibe to Reaper

To connect to [PeakVibe-REAPER](https://github.com/interactiveaudiolab/peakvibe-reaper/blob/main/README.md), you must copy your laptop's local IP address and type it into 
PeakVibe's settings menu. Likewise, copy your iPhone's local IP address (which you can see in PeakVibe's settings), and type it into `PeakVibe-REAPER` upon starting up REAPER. 
