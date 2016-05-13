#!/bin/bash
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


######
#   pyca-script
#
#   This bash script demonstrates recording multiple sources for audio & video
#   with a single command. It is intended to be used with the pyca capture
#   agent by Lars Kiesow.
#
#   @author   Jan Koppe <jan.koppe@wwu.de>
#   @date     2016-05-13
#   @version  0.3.0
#
######

######
#
#   Usage: ./record.sh directory name time cameraip password [audiodelay]
#
#   where...
#     directory:  where to put the recordings, relative to CWD
#     name:       basename for the files
#     time:       length of the recording in seconds
#     cameraip:   <ip>:554 for the camera to record from
#     password:   password for root user on ip camera
#     audiodelay: delay in ms for audio in reference to camera (OPTIONAL)
#
######


# ARGS
DIRECTORY=$1
NAME=$2
TIME=$3
CAMERA_IP=$4
CAMERA_PASSWORD=$5
AUDIODELAY=$6

# INTERNAL
pids=""         # pids for capture processes, used to check exit codes
delay_option=""

if [[ -n "$AUDIODELAY" ]]; then
  delay_option="-itsoffset $6"
fi

######
#   Capture RTSP Stream #1 from IP Camera
#   + Audio from ALSA
#   + mux without re-encoding rtsp stream
ffmpeg -loglevel fatal -y -thread_queue_size 512 \
  -t $TIME -i \
  "rtsp://root:$5@$4:554/axis-media/media.amp?camera=1" \
  -thread_queue_size 512 \
  -f alsa \
  $delay_option \
  -t $TIME \
  -i hw:0 \
  -c:v copy \
  -c:a aac \
  -map 0:v \
  -map 1:a \
  "$DIRECTORY/$NAME presenter.mp4" \
  &             # run in background

pids+=" $!"     # save pid
#
######

######
#   Capture RTSP Stream #2 from IP Camera
ffmpeg -loglevel fatal -y -t $TIME -i \
  "rtsp://root:$5@$4:554/axis-media/media.amp?camera=2" \
  "$DIRECTORY/$NAME presenter follow.mp4" \
  -c:v copy \
  &

pids+=" $!"     # save pid
#
######

######
#   Capture DeckLink Input
###
#   Chose the Device Name
#
DECKLINK_DEVICE="DeckLink Mini Recorder"
#
#   Available devices can be listed with
#     ffmpeg -f decklink -list_Devices 1 -i dummy
#
###
#   Chose the input format
#
DECKLINK_FORMAT=13
#
#     Available input formats can be listed with
#       ffmpeg-f deckklink -list_formats 1 -i '$DECKLINK_DEVICE'
#
#     some examples for 'DeckLink Mini Recorder':
#       13: 720p50
#       15: 720p60
#       8:  1080p30
#
ffmpeg -loglevel fatal -y -f decklink -t $TIME \
  -i "$DECKLINK_DEVICE@$DECKLINK_FORMAT" \
  -an \
  -c\:v libx264 \
  -preset slow \
  -tune stillimage \
  "$DIRECTORY/$NAME presentation.mp4" \
  &             # run in background

pids+=" $!"     # save pid
#
######

#   Wait for recordings to finish (running as background processes), then finish
for p in $pids; do
  if wait $p; then
    echo "$p successful"
  else
    exit $?
  fi
done
