#!/bin/sh

video_dir=$1
staging=$(mktemp -d -p $video_dir)

for src_file in $video_dir/*; do
    enc=$(ffprobe -v quiet -select_streams v:0 -show_entries stream=codec_name -of default=nokey=1:noprint_wrappers=1 $src_file)
    
    if [[ $enc == "h264" ]]; then
        filename=$(basename "$src_file")
        dst_file="$staging/$filename"
        ffmpeg -hwaccel cuda -i "$src_file" -vcodec hevc_nvenc "$dst_file"
        # mv $dst_file $video_dir
    elif [[ $enc == "hevc" ]]; then
        echo "Already HEVC. Skipping file: $src_file"
    else
        echo "Weird file encoding. Skipping."
        echo "File: $src_file"
        echo "Encoding: $enc"
    fi
done

# rmdir $staging
