# Voice Typing App (WIP)

This is a true "build in public" attempt: usually I create private repositories and share stuff publicly if I have something half (or a quarter) working. I'm sharing this one essentially from the first rung of the ladder. 

## Why I'm Working On This

Since about this time last year, I've become an ardent user (and fan) of speech to text (STT).  I'm a reasonably proficient touch typist - in the order of 100 WPM. Exploring voice tech was never high on my always crowded agenda of shiny and cool tech things to try out because: 1) I type reasonably quickly and 2) Linux solutions were, until very recently, pretty bad. The open-sourcing of Whisper and the avalanche of open source projects it stimulated shifted that in very quick order. 

When I first used Whisper - about this time last year - I realised that voice tech was finally worth seriously looking into: it's affordable and it's really good. 

As anybody who knows me outside of the internet will probably quickly attest, when I find something that I like and believe in, I tend to throw myself in head first. Knowing that, I resisted the temptation to instantly pick up a fancy transcription headset. I expected the honeymoon phase to last a month and to then revert to my (still beloved, mechanical) keyboard. To my surprise, after a year, I'm not only still mostly voice-typing, I'm thinking of ways to make it even easier to do so. 

Over the course of the past year, my workflow has become "voice-default" - and I've tried (I think) just about all the major models. I've used it for true real time typing synthesis and to record and transcribe hour long recordings for AI context data. All of these have, in their own way, been incredibly useful.  But oddly I find myself at a strangely familiar juncture in the tech world: there's so much out there. But so little that does precisely what I'm looking for!

## What I'm Looking For 

 A year of voice typing has formed the opinion that speech to text / dictation is best executed and integrated into one's workflow at the OS level. 

 Apps increasingly do offer integrated dictation and the feature is quickly becoming more prevalent. But that still leaves gaps and creates a disjointed experience: I found a great Chrome extension that I love. But I have no way to "voice type" into a plain text notepad, which remains my preferred tool of choice for writing.

 But Whisper! There's a *ton* of local projects that do exactly this, no?

 Yes - if you want to run Whisper locally. I have a recently decent GPU (albeit AMD). I've used local STT inference for a year. But I have no actual desire to do this. Or to be explicit: I would much rather use a cloud API for STT so long as I can afford to do so. 

 Sadly almost all the projects I found fell down on one or the other hurdle that was a blocker for my use case: 

-  Were local only 
 - Wouldn't work on my GPU (AMD + Linux is not the easiest combo) 
-  Transcribed just fine but stubbornly refused to type into text windows (a Wayland problem) 
-  Occasionally worked but local STT was just so much worse than cloud STT that it wasn't worth it  

At the brink of giving up, I decided to try this starter from [Deepgram](https://github.com/deepgram/voice-keyboard-linux). To my enormous suprise, it worked. Live text! Flowing into any window! In Wayland! 

## One Transcription / Dictation App 

Today, I had some time to think it over before finding time, after work, to pick up the project. 

I added one more requirement to the list of features that I'm planning here: Deepgram's real time STT is the best I've seen to date (the on-the-fly puncutation is a thing of beauty!). But for long from STT (say, I record a 10 minute note) ... can the same model/API do both? On reflection, real time and async STT are two very different workloads. But also on reflection:

- I want less but more comprehensive tools 
- I would happily sacrifice some accuracy/WER if it meant I have one consolidated provider / API bill. 

With that in mind, my WIP plans the slow but steady implementation plan that AI coding tools have kind of imbued in me now as philosophy: chunks tasks and iterate in small steps.

Step one will be the live STT app - as it's my immediate need. Step 2 will be building this out into a real GUI with long STT support (and the different approach that entails - specifically in chunking).

## First MVP Feature Objectives 

These are my "STT essentials" that I will work on in order:

1) Hotkey support: I use a HID USB button mapped onto F13. The app will have a hotkey selection dialog. This setting will persist. The user should also be able to configure a standalone stop button (to support two pedal operation). But the default mode of operation will be "tap tap" (tap the key to start, tap the same key to stop). If it's not too hard, I will add "PTT" (hold to type) as an option. 

2) Microphone handling: user should be able to choose a microphone. That selection should persist. Alongside the Deepgram API key these small configuration files should persist in local on device storage. 

3) Model selection: I am not overly familiar with Deepgram's API offering. My "dream" implementation would be a local (OS level) STT app that supported as many cloud API providers as possible (Deepgram, Whisper, Speechmatics, etc). But as each integration would entails more complication I will initially limit to Deepgram. I make note that Replicate also recently added Whisper.

4) GUI: A simple GUI for start / stop, configuring settings. The GUI should dock to the system tray by default but be recallable or closeable from there. 

5) Type wherever the cursor is: this is the hard success/failure criterion. This will not be useful to me unless it can type literally anywhere on the OS!

6) Spend monitoring: this one is really important! I want to be able to see API spend so that: one, I can use this without worrying that I'm overspending and two: I can get a feel for how much it costs. This doesn't need to be continuously updating. Polling the API every hour would be sufficient. This could be built upon with things like daily spend caps, warnings. But to start with just a simple dollar display would be fine. API key should, of course, be client-unique.

## Down The Line

The bells and whistles that I've found helpful during my year of voice typing but can live without for the moment:

1) Mic level: Really easy to accidentally set your levels too low and spend a whole day getting subpar transcriptions before realising that your mic was the problem! Basic UI feature: dB level. Cool and useful feature: alerting - not only for silence, but when the average input isn't reaching a basic threshold (or conversely clipping).

2) Post-processing: exceptionally helpful, although moreso in the async / "note" approach. 

3) Custom dictionary / replacements. 

## Non Features 

Things I won't be working on because they're not things I find helpful or want (for completion of documentation!):

1) VAD / always on 
2) Wake word  - at least initially. 

