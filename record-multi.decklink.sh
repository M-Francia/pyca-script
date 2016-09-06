#/bin/bash

######
#   Capture Agent recording script
#
#   This script records TWO inputs of a Axis IP Cam, a blackmagic DeckLink Mini
#   Recorder and one audio input.
#
#   @author   Jan Koppe <jan.koppe@wwu.de>
#   @date     2016-07-03
#   @version  0.5.0
######

######
#   Usage: ./record.sh directory name time cameraip password audiodelay
#
#   where...
#     directory:  where to put the recordings, relative to CWD
#     name:       basename for the files
#     time:       length of the recording in seconds
#     cameraip:   <ip>:554 for the camera to record from
#     password:   password for root user on ip camera
#     audiodelay: delay in ms for audio in reference to camera !STUB!
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
#   Capture Audio from Sound Card (Analog) via ALSA

ffmpeg -loglevel fatal -y -thread_queue_size 512 \
  -t $TIME \
  -f alsa \
  -i hw:0 \
  -c:a libmp3lame \
  "$DIRECTORY/${NAME}_audio.mp3" \
  &

pids+=" $!"
#
######

######
#   Capture RTSP Stream #1 from IP Camera
ffmpeg -loglevel fatal -y -thread_queue_size 512 \
  -t $TIME -i \
  "rtsp://root:$5@$4:554/axis-media/media.amp?camera=1" \
  -c:v copy \
  "$DIRECTORY/${NAME}_presenter.mp4" \
  &             # run in background

pids+=" $!"     # save pid
#
######

######
#   Capture RTSP Stream #2 from IP Camera
ffmpeg -loglevel fatal -y -t $TIME -i \
  "rtsp://root:$5@$4:554/axis-media/media.amp?camera=2" \
  -c:v copy \
  "$DIRECTORY/${NAME}_tracking.mp4" \
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
  -pix_fmt yuv420p \
  -an \
  -c\:v libx264 \
  -profile\:v baseline -level 3.1 \
  -preset slow \
  -tune stillimage \
  "$DIRECTORY/${NAME}_presentation.mp4" \
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
