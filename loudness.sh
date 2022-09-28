mkdir louder
for f in *.m4a
do
  ffmpeg -i $f -filter:a "volume=2.5" louder/$f
done