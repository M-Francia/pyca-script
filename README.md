# pyca-script
A recording script for recording with pyCA.

This script is intended to be used with the [pyCA capture agent]<https://github.com/lkiesow/pyCA> by Lars Kiesow, but can easily be adapted to your needs. It is more of a example, rather than a turn-key solution.

In it's default configuration, it will try to capture 2 separate streams from a
Axis IP Camera, ALSA Audio and Blackmagic HDMI Input. You will probably need to
adapt the input configuration to your needs by editing the .sh file.

# Requirements

This script records the input of a Blackmagic devices capture card with ffmpeg. This requires the `--enable-decklink` configuration flag, which is not enabled by default.

I maintain a Arch Linux AUR Package with this option: [ffmpeg-decklink]<https://aur.archlinux.org/packages/ffmpeg-decklink>

# To do

* detach audio recording from camera stream for improved reliability
* watch and restart crashed processes
* write meaningful logfiles
* auto detect blackmagic device & input resolution
* parallel streaming
* confidence monitoring with preview images

# Contribute

All suggestions and improvements are very welcome. Please open a Issue, PR or send me a email.

# License

This script is licensed under the GPL 3.0, which you will find in the `LICENSE` file.
