#!/bin/bash

out_dir="icons_out"

if [ $# -lt 2 ]; then
    echo "Usage: $0 input_file.svg output_name\n  provide an svg file with three layers - use the provided Icon_template.svg\n  provide an output name for the icons (without file extension)"
    exit 1
fi

source_image=$1
target_name=$2

mkdir -p "${out_dir}"

# tmp
out_tmp="$(mktemp -d)"

inkscape ${source_image} --actions="unhide-all;select-by-id:layer2;selection-hide;" -C -l -o "${out_tmp}/full.svg"
inkscape ${source_image} --actions="unhide-all;select-by-id:layer2,layer1;selection-hide;" -C -l -o "${out_tmp}/bg.svg"
inkscape ${source_image} --actions="unhide-all;select-by-id:layer2,layer3;selection-hide;" -C -l -o "${out_tmp}/fg.svg"
inkscape ${source_image} --actions="unhide-all;select-by-id:layer1,layer3;selection-hide;" -C -l -o "${out_tmp}/fg_mono.svg"

# svg
inkscape "${out_tmp}/full.svg" -C -l -o "${out_dir}/${target_name}.svg"

# 16x16
inkscape "${out_tmp}/full.svg" -w 16 -h 16 -C --export-png-compression=9 --export-png-antialias=0 --export-type=png -o "${out_dir}/${target_name}_16.png"
# 24x24
inkscape "${out_tmp}/full.svg" -w 24 -h 24 -C --export-png-compression=9 --export-png-antialias=0 --export-type=png -o "${out_dir}/${target_name}_24.png"
# 32x32
inkscape "${out_tmp}/full.svg" -w 32 -h 32 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/${target_name}_32.png"
# 48x48
inkscape "${out_tmp}/full.svg" -w 48 -h 48 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/${target_name}_48.png"
# 64x64
inkscape "${out_tmp}/full.svg" -w 64 -h 64 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/${target_name}_64.png"
# 128x128
inkscape "${out_tmp}/full.svg" -w 128 -h 128 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/${target_name}_128.png"
# 256x256
inkscape "${out_tmp}/full.svg" -w 256 -h 256 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/${target_name}_256.png"
# 512x512
inkscape "${out_tmp}/full.svg" -w 512 -h 512 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/${target_name}_512.png"
# 1024x1024
inkscape "${out_tmp}/full.svg" -w 1024 -h 1024 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/${target_name}_1024.png"

# windows ico
magick "${out_dir}/${target_name}_16.png" "${out_dir}/${target_name}_24.png" "${out_dir}/${target_name}_32.png" "${out_dir}/${target_name}_48.png" "${out_dir}/${target_name}_256.png" "${out_dir}/${target_name}.ico"

# mdpi
mkdir -p "${out_dir}/android/res/mipmap-mdpi"
inkscape "${out_tmp}/full.svg" -w 108 -h 108 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/android/res/mipmap-mdpi/ic_launcher.png"
inkscape "${out_tmp}/bg.svg" -w 108 -h 108 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/android/res/mipmap-mdpi/ic_launcher_background.png"
inkscape "${out_tmp}/fg.svg" -w 108 -h 108 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/android/res/mipmap-mdpi/ic_launcher_foreground.png"
inkscape "${out_tmp}/fg_mono.svg" -w 108 -h 108 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/android/res/mipmap-mdpi/ic_launcher_monochrome.png"

# hdpi
mkdir -p "${out_dir}/android/res/mipmap-hdpi"
inkscape "${out_tmp}/full.svg" -w 162 -h 162 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/android/res/mipmap-hdpi/ic_launcher.png"
inkscape "${out_tmp}/bg.svg" -w 162 -h 162 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/android/res/mipmap-hdpi/ic_launcher_background.png"
inkscape "${out_tmp}/fg.svg" -w 162 -h 162 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/android/res/mipmap-hdpi/ic_launcher_foreground.png"
inkscape "${out_tmp}/fg_mono.svg" -w 162 -h 162 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/android/res/mipmap-hdpi/ic_launcher_monochrome.png"

# xhdpi
mkdir -p "${out_dir}/android/res/mipmap-xhdpi"
inkscape "${out_tmp}/full.svg" -w 216 -h 216 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/android/res/mipmap-xhdpi/ic_launcher.png"
inkscape "${out_tmp}/bg.svg" -w 216 -h 216 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/android/res/mipmap-xhdpi/ic_launcher_background.png"
inkscape "${out_tmp}/fg.svg" -w 216 -h 216 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/android/res/mipmap-xhdpi/ic_launcher_foreground.png"
inkscape "${out_tmp}/fg_mono.svg" -w 216 -h 216 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/android/res/mipmap-xhdpi/ic_launcher_monochrome.png"

# xxhdpi
mkdir -p "${out_dir}/android/res/mipmap-xxhdpi"
inkscape "${out_tmp}/full.svg" -w 324 -h 324 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/android/res/mipmap-xxhdpi/ic_launcher.png"
inkscape "${out_tmp}/bg.svg" -w 324 -h 324 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/android/res/mipmap-xxhdpi/ic_launcher_background.png"
inkscape "${out_tmp}/fg.svg" -w 324 -h 324 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/android/res/mipmap-xxhdpi/ic_launcher_foreground.png"
inkscape "${out_tmp}/fg_mono.svg" -w 324 -h 324 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/android/res/mipmap-xxhdpi/ic_launcher_monochrome.png"

# xxxhdpi
mkdir -p "${out_dir}/android/res/mipmap-xxxhdpi"
inkscape "${out_tmp}/full.svg" -w 432 -h 432 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/android/res/mipmap-xxxhdpi/ic_launcher.png"
inkscape "${out_tmp}/bg.svg" -w 432 -h 432 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/android/res/mipmap-xxxhdpi/ic_launcher_background.png"
inkscape "${out_tmp}/fg.svg" -w 432 -h 432 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/android/res/mipmap-xxxhdpi/ic_launcher_foreground.png"
inkscape "${out_tmp}/fg_mono.svg" -w 432 -h 432 -C --export-png-compression=9 --export-png-antialias=1 --export-type=png -o "${out_dir}/android/res/mipmap-xxxhdpi/ic_launcher_monochrome.png"

# anydpi
mkdir -p "${out_dir}/android/res/mipmap-anydpi-v26"
printf '<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n  <background android:drawable="@mipmap/ic_launcher_background"/>\n  <foreground android:drawable="@mipmap/ic_launcher_foreground"/>\n  <monochrome android:drawable="@mipmap/ic_launcher_monochrome"/>\n</adaptive-icon>' > "${out_dir}/android/res/mipmap-anydpi-v26/ic_launcher.xml"

# icns
# https://en.wikipedia.org/wiki/Apple_Icon_Image_format
# The @2x versions replace the standard ones on retina devices so for example, your 16×16@2x should be a scaled up version of your 16×16 icon rather than the same as your 32×32 icon despite them having the same dimensions.
# inspector: https://relikd.github.io/icnsutil/html/inspector.html
# viewer: https://relikd.github.io/icnsutil/html/viewer.html
icnsutil img "${out_tmp}/16x16.argb" "${out_dir}/${target_name}_16.png"
magick "${out_dir}/${target_name}_16.png" -resize 32x "${out_tmp}/16x16@2x.png" && icnsutil img "${out_tmp}/16x16@2x.argb" "${out_tmp}/16x16@2x.png"

cp "${out_dir}/${target_name}_32.png" "${out_tmp}/32x32.png"
magick "${out_dir}/${target_name}_32.png" -resize 64x "${out_tmp}/32x32@2x.png"

cp "${out_dir}/${target_name}_128.png" "${out_tmp}/128x128.png"
magick "${out_dir}/${target_name}_128.png" -resize 256x "${out_tmp}/128x128@2x.png"

cp "${out_dir}/${target_name}_256.png" "${out_tmp}/256x256.png"
magick "${out_dir}/${target_name}_256.png" -resize 512x "${out_tmp}/256x256@2x.png"

cp "${out_dir}/${target_name}_512.png" "${out_tmp}/512x512.png"
magick "${out_dir}/${target_name}_512.png" -resize 1024x "${out_tmp}/512x512@2x.png"

icnsutil c "${out_dir}/${target_name}.icns" "${out_tmp}/128x128.png" "${out_tmp}/128x128@2x.png" "${out_tmp}/256x256.png" "${out_tmp}/256x256@2x.png" "${out_tmp}/512x512.png" "${out_tmp}/512x512@2x.png" -f --toc
icnsutil u "${out_dir}/${target_name}.icns" -set ic04="${out_tmp}/16x16.argb"
icnsutil u "${out_dir}/${target_name}.icns" -set ic05="${out_tmp}/16x16@2x.argb"
icnsutil u "${out_dir}/${target_name}.icns" -set ic11="${out_tmp}/32x32.png"
icnsutil u "${out_dir}/${target_name}.icns" -set ic12="${out_tmp}/32x32@2x.png"

#icnsutil e "${out_dir}/${target_name}.icns" -o "${out_dir}/"

rm -r -f "${out_tmp}"
