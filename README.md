# Helix-Plugins
A repository for plugins I have created to be used with Helix, a roleplaying script for Garry's Mod. I hope you enjoy my work! Thank you to the Helix developers (and the devs that came before them) for laying the framework for me to build upon. I would not have gotten anywhere starting from scratch.

## 1. Extended Radio

<p align="center">
  <img width="550" height="256" src="https://github.com/fauxzor/Helix-Plugins/blob/master/extended_radio_short.png">
</p>

This plugin extends the functionality of the radio implementation included in the default Helix HL2RP schema. Features include:
- Distance-based radio scrambling, with modifiers for being indoors, using a long range radio, yelling, etc.
- New "radio yell" command, with different chat color & less scrambling
- The ability to set one radio as "Active" & to listen to multiple different radios at a time
- Radio callsigns, which are used instead of the character's name for radio chat and shown in the "You" menu
- Long range radio item, with different chat color & less scrambling
- Radio sound effects/tones for transmitting and receiving messages, modified by distance
- "Silence" command for the radio, which disables your own radio tones
- Near total control of radio ranges, chat colors, callsigns, and other features via the Helix config menu

### *Required content*
I have repackaged the Left 4 Dead radio model included with the Clockwork content, along with the radio sound effects, [into a Workshop addon here.](https://steamcommunity.com/sharedfiles/filedetails/?id=1866763987) To be clear: *I did not create this model!* I believe that it is sufficient for clients to download the addon to see the radio and hear the sound effects; however, I still recommended including this addon in your server's Workshop collection if only so the physics of the radio model will work on your server. If for some reason that isn't working for you, or if you would just like the raw files themselves, they can be found under `plugins\content`.

## 2. Radio Chatbox
This plugin creates a new chatbox above the regular chatbox, for radio chat only. It can be toggled on and off in-game through the Helix config menu. It functions nearly identically to the regular chatbox except with slightly different aesthetics and serves to separate radio chatter from regular speech.
