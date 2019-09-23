# Helix-Plugins
A repository for plugins I have created to be used with Helix, a roleplaying script for Garry's Mod. I hope you enjoy my work! Thank you to the Helix developers (and the devs that came before them) for laying the framework for me to build upon. I would not have gotten anywhere starting from scratch. Please excuse my spaghetti code.

If you have any questions about my plugins, or would just like to get in touch with me, [you can find me on Steam here.](https://steamcommunity.com/id/faux55)

---

## 1. Extended Radio

<p align="center">
  <img width="550" height="256" src="https://github.com/fauxzor/Helix-Plugins/blob/master/extended_radio_short.png">
</p>

This plugin extends the functionality of the radio implementation included in the default Helix HL2RP schema. Features include:
- Distance-based radio scrambling, with modifiers for being indoors, using a long range radio, yelling, etc.
- New "radio yell" command, with different chat color & less scrambling
- The ability to set one radio as "Active" & to listen to multiple different radios at a time

   Your active radio is indicated with a green square in your inventory. A radio that you are listening to, but not transmitting on, is marked as yellow. For reasons, changing your radio's frequency by using the "Frequency" command in your inventory will make it your active radio. The `\setFreq` command will only change the frequency of your active radio. If you only have one radio in your inventory, it should become active as soon as you turn it on; however, it is possible to be without an active radio in certain situations. You should receive a notification if this is the case when you try to transmit or `\setFreq` without an active radio (or if you have another problem like having no radios).

- Radio callsigns, which are used instead of the character's name for radio chat and shown in the "You" menu
- Long range radio item, with different chat color & less scrambling
- Radio sound effects/tones for transmitting and receiving messages, modified by distance
- "Silence" command for the radio, which disables your own radio tones

   A silenced radio has a red line through the active/enabled marker. This does not stop you from hearing other people's radio tones if they are nearby-- overall control of whether or not sounds are activated is handled in the Helix config menu.

- Near total control of radio ranges, chat colors, callsigns, and other features via the Helix config menu

### *Required content*
I have repackaged the Left 4 Dead radio model included with the Clockwork content, along with custom radio sound effects, [into a Workshop addon here.](https://steamcommunity.com/sharedfiles/filedetails/?id=1866763987) To be clear: *I did not create this model,* although I did customize the sounds myself. I believe that it is sufficient for clients to download the addon to see the radio and hear the sound effects; however, I still recommended including this addon in your server's Workshop collection if only so the physics of the radio model will work on your server. If for some reason that isn't working for you, or if you would just like the raw files themselves for some other reason, they can be found under `plugins\content`.

## 2. Radio Chatbox
This plugin creates a new chatbox above the regular chatbox, for radio chat only. It can be toggled on and off in-game through the Helix config menu. It functions nearly identically to the regular chatbox except with slightly different aesthetics -- including a larger font size for radio yelling -- and serves to separate radio chatter from regular speech. In theory this is a standalone addon. However, I have not tested it without the "Extended Radio" addon, and without the changes I have made to the chat types & commands, your mileage may vary getting it to work/having it be useful.
