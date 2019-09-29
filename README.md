# Helix-Plugins
A repository for plugins I have created to be used with Helix, a roleplaying script for Garry's Mod. I hope you enjoy my work! Thank you to the Helix developers (and the devs that came before them) for laying the framework for me to build upon. I would not have gotten anywhere starting from scratch. Please excuse my spaghetti code.

If you have any questions about my plugins, or would just like to get in touch with me, you can find me on Discord `@fauxzor#8368` or [you can add me on Steam here.](https://steamcommunity.com/id/faux55)

---

## 1. Extended Radio

<p align="center">
  <img width="550" height="256" src="https://github.com/fauxzor/Helix-Plugins/blob/master/extended_radio_short.png">
</p>

### Summary

This plugin extends the functionality of the radio implementation included in the default Helix HL2RP schema. In summary, this plugin makes the following changes & additions to the default HL2RP radio implementation:

*New features*
* Local radio messages -- sent by yourself or someone in earshot -- are displayed as IC chat
* Dynamic display of a speaker's frequency and/or channel next to received messages
* Radio messages are scrambled over long distances & by various other modifiers (such as being indoors)
* 4 radio channels for each frequency, with both a GUI and chat commands to quickly & easily customize them
* Multiple radios can be on and listened to at once (although only one can be "Active" and transmitting)
* Toggleable "Broadcast" command for radio items, to transmit on all channels at once
* Toggleable "Listen" command for radio items, to listen to all channels at once (disable transmitting)
* Customizable radio callsigns, which display instead of the speaker's name when receiving radio messages
* Radio tone sound effects for sending & receiving radio messages, toggleable for each radio item

*New chat classes*
* `radio_whisper (\rw)`which displays in a darker & smaller font size if used with the Radio Chatbox plugin; reduces your readability over the radio, but only makes you audible to those within whispering range around you
* `radio_yell (\ry)`, which displays in a brighter & larger font size if used with the Radio Chatbox plugin; makes your message easier to understand, but also easier to eavesdrop on

*New items*
* `sh_walkietalkie`, a short-range radio designed to communicate with other walkie-talkies; does not have the ability to directly set the frequency, only to "Scan" for other walkie-talkie users in the area and tune in to their signal

* `sh_handheld_radio`, a re-write of the original `handheld_radio` item from the HL2RP schema to include new commands such as "Broadcast", "Channel", and "Listen"; the "default" radio item, with full frequency control

* `sh_longrange`, a duplicate of the handheld radio with a longer maximum range and different chat color; by default, this is the only radio type on which you can "Broadcast" on all channels, to further differentiate each type of radio

*New chat commands (with examples)*
* `\setFreq (100.0)`, changes the frequency of your active radio
  
  Frequencies can be any number between `100.1` and `999.9` but must be given in that *exact* format, with three digits, a decimal, and one more digit. Be specific!

* `\setChan (1)`, changes the channel of your active radio
* `\chanRename (1,TACTICAL)`, renames the specified channel of your active radio to the specified name

   Entries must be separated by a comma, and although the name can be anything, you are limited to 16 characters (for reasons).
   
* `\rbc` or `\radioBroadcast`, *toggles* broadcasting on all channels for your active radio
* `setCallsign (Character1 War Pig)`, changes the callsign of the specified player to the specified callsign

   No special handling is needed for spaces in the callsign; anything after the character's name will be the callsign verbatim. In the example, Character1's callsign was set to *War Pig*. To clear a player's callsign and reset it to the default, simply enter the character's name without a callsign.

---

### Features

- **Separation of non-local radio chat from local radio chat**

   In the past, radio scripts have not made a strong distinction between radio chatter and "regular" chatter. Even if someone is standing within earshot of you when they transmit, you will often receive their message as a radio transmission in your chatbox, as will they, even though they were heard far more clearly in the "real world" than on the radio. This sort of feedback encourages players to use the radio even when they don't have to, which clutters up the chatbox and in my opinion subverts the entire point of a roleplaying script, which is to provide an elegant "local chat" solution. 
   
<p align="center">
  <img width="449" height="225" src="https://i.imgur.com/o5PcrtM.png">
</p>
   
   With "Extended Radio", your radio transmissions and any that you receive within earshot of the speaker will be displayed as local chat and shown in the regular chatbox. Any radio transmissions you receive from someone out of earshot will be displayed as a radio message, with all the associated aesthetics & sound effects.
   
- **Customizable radio channels subordinate to each frequency**

   The channel of your active radio can be changed using `\setChan` or by using the "Channel" command on the radio item in your inventory. Each frequency has 4 channels-- 1, 2, 3, and 4. You must be on the same channel as the speaker to receive their message, even if you are also on the same frequency. To reduce chatbox clutter, if you only have one radio enabled, you will only see the speaker's channel next to their name when you receive a radio message; if you have more than one radio enabled (and they're both not on the same frequency), you will also see their frequency, so you know which one to reply on. You should see the name of the channel corresponding to the radio you received the message on (barring special circumstances).
   
   You can rename these channels by using `\chanRename number,name` as one string separated by a comma. This will set the specified channel of your active radio to the specified name. However, it is recommended instead to ues the "Channel" command on the item in the inventory, which opens up a graphical interface to change channels and control channel names. Other people can not see the names of your channels... unless they pick up your radio! Channel names are saved per-radio and persist after being dropped.
   
<p align="center">
  <img width="404" height="117" src="https://i.imgur.com/bCVnukA.png">
  <img width="116" height="152" src="https://i.imgur.com/SeQ4KhK.png">
</p>
   
- **Listening and broadcasting to multiple channels at once**

   By using the command `\rbc` or (`\radioBroadcast`), you will toggle sending transmissions on your active radio to all channels on your frequency. This can also be controlled by running the "Broadcast" command on the item in your inventory. Again, this is a *toggled* command, so remember to stop broadcasting once you're done! Messages received as a broadcast do not show a channel name, but instead solely the frequency (unless you're receiving it on a walkie talkie, in which case you'll just see your channel name, since you don't have access to the walkie's "frequency"). Broadcasting radios in your inventory are marked with a blue-green pip above the status icon, and display helpful text when you hover over them to remind you that you're broadcasting.
   
<p align="center">
  <img width="382" height="159" src="https://i.imgur.com/zx2QDlw.png">
</p>
   
   Three different levels of control are available in the config menu. Level 1 (default) enables broadcasting for long range radios only. Level 2 enables it for long range and regular radios, and Level 3 enables it for walkie talkies as well. There is also the option to disable broadcasting altogether.
   
   You can also listen to all of the channels on a frequency by using the "Listen" command on the radio item. This will display an orange pip to the left of the status icon. You cannot listen and transmit on your active radio at the same time, unless you are broadcasting; this is to prevent people from just "listening" all of the time.
   
<p align="center">
  <img width="193" height="66" src="https://i.imgur.com/wnqbYLX.png">
</p>

- **Distance-based radio scrambling, with modifiers for being indoors, using a long range radio, yelling, etc.**

   These modifiers remain a work in progress, but the general idea is that:
   
   * Radio transmission "readability" decays non-linearly with distance
   * Yelling makes you easier to understand; whispering makes you harder to understand
   * If the speaker and/or the receiver are inside of a building, the resulting message is more scrambled
   * Maintaining line of sight with the speaker much improves readability
   * Long range radios increase the maximum distance & therefore reduce distance-based scrambling
   * There is a small element of randomness-- transmissions could sometimes be better or worse than you'd expect
   
   Although somewhat cludgy I decided to stick with the "multiplier" system to adjust the maximum radio range. Source units are not very intuitive to most people and different map geometries make them less meaningful than the chat range, which all radio ranges are based off of. You can adjust the maximum radio range by adjusting the radio range multiplier from 1x the chat range to 135x the chat range (approximately the maximum Source map size and then some). Of note is that the "max range" is just the range which results in 100% scrambling; due to the nature of the scrambling code, and in what qualifies as a "readable" message, this may *not* be the actual "maximum range" to hear something useful. I have found that a scrambling fraction of over 50% is pretty much useless, and have adjusted accordingly, but it's something to keep in mind when adjusting them yourself.
   
   In addition to the maximum range, you can also adjust the distance-based model governing the garbling in the config. Each setting corresponds to a different model. Below is a plot of each of the models available, along with some commentary for each. Play around and find settings that work for you!
   
<p align="center">
  <img width="848" height="314" src="https://github.com/fauxzor/Helix-Plugins/blob/master/decay_models_1.PNG">
</p>

<p align="center">
  <img width="577" height="170" src="https://github.com/fauxzor/Helix-Plugins/blob/master/fracs_1.PNG">
</p>

- **New "radio yell" and "radio whisper" commands, with different chat color & more/less scrambling**

   These can be used with the shorthand `\ry` and `\rw`\. Note that whispering does *not* reduce the volume of your radio tones, to any would-be eavesdroppers, so remember to silence your radio if you want to transmit incognito!

- **The ability to set one radio as "Active" & to listen to multiple different radios at a time**

   Your active radio is indicated with a green square in your inventory. A radio that you are listening to, but not transmitting on, is marked as yellow. For reasons, changing your radio's frequency by using the "Frequency" command in your inventory will make it your active radio. The `\setFreq` command will only change the frequency of your active radio. I tried to keep things common sense, to avoid unnecessary inventory management: for example, if you only have one radio in your inventory, it should become active as soon as you turn it on without any additional fuss. However, it is possible to be without an active radio in certain situations. You should receive a notification if this is the case when you try to transmit or `\setFreq` without an active radio (or if you have another problem like having no radios).
   
   The radio frequency on which you received the message is displayed next to the speaker's name (or callsign), shown in dark gray if your active frequency is not the same as theirs and light gray if it is.

- **Radio callsigns, which are used instead of the character's name for radio chat and shown in the "You" menu**

   Callsigns should be persistent across a restart, although I have had mixed success with this. Two options are available in the config menu to set a "default" callsign: the speaker's character name (as usual), or an "anonymous" option (i.e. "Somebody/Someone/A voice radios in"). If a character has a callsign set, this will always show as their "radio name" even if transmissions are anonymized. A character's callsign can be set with `\setCallsign` and can include spaces and such. If no argument is provided, their callsign is reset to the default config setting.

- **Long range radio item (`"sh_longrange"`), with different chat color & less scrambling**
- **Walkie talkie item (`"sh_walkietalkie"`), with different functionality & more scrambling**

   Walkie talkies operate on the same radio frequencies as everyone else, but with one caveat: you can not directly choose the frequency. Instead, running the "Scan" command on the walkie talkie item in your inventory will search your surroundings for other players using a walkie talkie and gives you a chance to "lock on" to their frequency (and channel, for convenience). If a "strong" signal is not found, a random frequency is assigned to the walkie talkie. You are guaranteed to find a frequency if you are within speaking range of another person with an enabled walkie talkie. Scanning will always change your frequency; that is, you will not stay locked on to the same frequency if you scan twice in a row, even if the person on that frequency is right next to you.
   
   The maximum range of the walkie talkie is controllable via the config menu and scales to the current maximum range of the radio. I called it a "multiplier" but I suppose it's more like a "divisor". The maximum range of the walkie talkie will always be less than that of radio chat & their transmissions will always be more garbled, whether you are sending or receiving.

- **Radio sound effects/tones for transmitting and receiving messages, modified by distance**
- **"Silence" command for the radio, which disables your own radio tones**

   A silenced radio has a red line through the active/enabled marker. This does not stop you from hearing other people's radio tones if they are nearby-- overall control of whether or not sounds are activated is handled in the Helix config menu.

- **Near total control of radio ranges, chat colors, callsigns, and other features via the Helix config menu**

   I did some pretty extensive fiddling with the default settings, but I recommend changing the range multipliers & chat colors & such to suit your own server's needs. What works best on `gm_construct` probably won't work best on `rp_city17`.

### *Required content*
I have repackaged the Left 4 Dead radio model included with the Clockwork content, along with custom radio sound effects, [into a Workshop addon here.](https://steamcommunity.com/sharedfiles/filedetails/?id=1866763987) To be clear: *I did not create this model,* although I did customize the sounds myself. I believe that it is sufficient for clients to download the addon to see the radio and hear the sound effects; however, I still recommended including this addon in your server's Workshop collection if only so the physics of the radio model will work on your server. If for some reason that isn't working for you, or if you would just like the raw files themselves for some other reason, they can be found under `plugins\content`.

## 2. Radio Chatbox
This plugin creates a new chatbox above the regular chatbox, for radio chat only. It can be toggled on and off in-game through the Helix config menu. It functions nearly identically to the regular chatbox except with slightly different aesthetics -- including a larger font size for radio yelling -- and serves to separate radio chatter from regular speech. In theory this is a standalone addon. However, I have not tested it without the "Extended Radio" addon, and without the changes I have made to the chat types & commands, your mileage may vary getting it to work/having it be useful.


<p align="center">
  <img width="772" height="443" src="https://github.com/fauxzor/Helix-Plugins/blob/master/demon1.png">
</p>
