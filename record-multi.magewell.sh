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
#   Select Inputs for magewell capture card
mwcap-control --video-input hdmi 0:0
mwcap-control --audio-input line_in 0:0

######
#   Capture Audio from Sound Card (Analog) via ALSA

ffmpeg -loglevel fatal -y -thread_queue_size 512 \
  -t $TIME \
  -f alsa \
  -i hw:0 \
  -c:a aac \
  "$DIRECTORY/${NAME}_audio.aac" \
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
#   Capture magewell Input
###

ffmpeg -loglevel fatal -y -f video4linux2 -t $TIME \
  -i /dev/video0 \
  -an \
  -c\:v libx264 \
  -s 1280x720 \
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
