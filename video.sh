#!/bin/sh
########################################################################################################################
# Based on and overrides the original video.sh https://github.com/SeleniumHQ/docker-selenium/blob/trunk/Video/video.sh #
########################################################################################################################
# Main loop - keep checking
while true; do
  echo "Entering Main Loop"
  VIDEO_SIZE="${SE_SCREEN_WIDTH}""x""${SE_SCREEN_HEIGHT}"
  DISPLAY_CONTAINER_NAME=${DISPLAY_CONTAINER_NAME}
  DISPLAY_NUM=${DISPLAY_NUM}
  FILE_NAME=${FILE_NAME}
  FRAME_RATE=${FRAME_RATE:-$SE_FRAME_RATE}
  CODEC=${CODEC:-$SE_CODEC}
  PRESET=${PRESET:-$SE_PRESET}
  # Custom tag that is used for a hack to pass custom tags via userDataDir. `selenium` by default
  CUSTOM_TAG_NAME=${CUSTOM_TAG_NAME:-selenium}


  return_code=1
  max_attempts=50
  attempts=0
  echo 'Checking if the display is open...'
  until [ $return_code -eq 0 -o $attempts -eq $max_attempts ]; do
    xset -display ${DISPLAY_CONTAINER_NAME}:${DISPLAY_NUM} b off > /dev/null 2>&1
    return_code=$?
    if [ $return_code -ne 0 ]; then
      echo 'Waiting before next display check...'
      sleep 0.5
    fi
    attempts=$((attempts+1))
  done

  return_code=1
  session=""
  session_id=""
  tags=""
  while [ $return_code -ne 0 ]; do
      session=$(curl -s http://localhost:5555/status | jq -r -e '.value.node.slots | .[] | .session')
      return_code=$?

      if [ $return_code -ne 0 ]; then
        sleep 0.5
        echo "Waiting for Selenium session to start"
      else
        echo "Selenium session found."
        echo "data:${tags}, ${session_id}"
        session_id=$(echo $session | jq -r -e '.sessionId')

        # We use userDataDir parameter to pass custom data to selenium, so we can use it in the automation.
        tags=$(echo $session | jq -r -e '.capabilities.chrome.userDataDir' | sed -r 's/.*selenium\.(.+)/\1/')
      fi
  done



  file_name="${tags}.${session_id}.${FILE_NAME}"
  echo "file_name: ${file_name}"

  echo "Starting ffmpeg in the background. Writing stream to /videos/$file_name"
  echo "executing: ffmpeg -y -f x11grab -video_size ${VIDEO_SIZE} -r ${FRAME_RATE} -i ${DISPLAY_CONTAINER_NAME}:${DISPLAY_NUM} -codec:v ${CODEC} ${PRESET} -pix_fmt yuv420p \"/videos/$file_name\" &"
  ffmpeg -y -f x11grab -video_size ${VIDEO_SIZE} -r ${FRAME_RATE} -i ${DISPLAY_CONTAINER_NAME}:${DISPLAY_NUM} -codec:v ${CODEC} ${PRESET} -pix_fmt yuv420p "/videos/$file_name" &

  # As long as the status of the session is OK don't kill the ffmpeg
  return_code=0
  while [ $return_code -ne 1 ]; do
    sleep 1
    echo "Waiting for Selenium session $session_id to end"
    # TODO: Check for actual session id.
    # TODO: Replace with DISPLAY_CONTAINER_NAME (needs to be tested)
    curl -s http://localhost:5555/status | jq -r -e '.value.node.slots | .[] | .session' > /dev/null
    return_code=$?
  done
  echo "Selenium session $session_id has ended."

  pgrep "ffmpeg"
  if [ $? -ne 1 ]; then
    echo "Found ffmpeg process. Stopping"
    pkill ffmpeg

    echo "Uploading /videos/$file_name to s3://${S3_BUCKET_NAME}/"
    aws s3 cp "/videos/$file_name" s3://${S3_BUCKET_NAME}/
  else
    echo "Couldn't find ffmpeg process."
  fi
done
