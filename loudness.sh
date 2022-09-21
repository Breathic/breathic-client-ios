mkdir louder
for f in *.mp3
do
  ffmpeg -i $f -filter:a "volume=1.5" louder/$f
done