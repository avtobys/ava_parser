#!/usr/bin/env bash


if [ -z "$(find ~/.cache/mozilla/firefox -type f -exec file {} \; | grep -i 'Web/P image')" ]; then
    echo "Web/P image not found"
    exit
fi

while [ -z "${ZIP_NAME}" ]; do
    echo -n 'Enter any zip file name without extension: '
    read ZIP_NAME
done


TEMP_DIR=$(date +'~/images-%d-%m-%Y-%H-%M-%S')
mkdir $TEMP_DIR

trap "rm -rf $TEMP_DIR; exit 1" 1 2 3 15

echo "Create temp dir $TEMP_DIR"
echo "Parse cache..."
i=0
# parse cache
for image in $(find ~/.cache/mozilla/firefox -type f -exec file {} \; | grep -i "Web/P image" | cut -d: -f1 | xargs ls -ltr | awk '{print $NF}') ; do
    ((i++))
    # convert to jpg & resize
    convert $image -resize 100 "$TEMP_DIR/${i}_temp.jpg"
done
echo "Cache parsed!"

echo "Identify images..."
# identify not condition 15% width or height
for image in $TEMP_DIR/*_temp.jpg ; do
    i=$(identify -ping -format '%w %h' $image | awk '$1/$2<0.85||$1/$2>1.15||$2/$1<0.85||$2/$1>1.15{print $1/$2}')
    if [ -n "${i}" ]; then
        rm $image
    fi
done
echo "Identified!"

echo "Save and resize images..."
i=0
for image in $(ls -tr $TEMP_DIR/*) ; do
    ((i++))
    convert $image -resize 100x100! $TEMP_DIR/$i.jpg
    rm $image
done
echo "Resized!"

zip -r -j ~/"$ZIP_NAME".zip $TEMP_DIR/*

rm -r $TEMP_DIR

echo "Removed temp dir $TEMP_DIR"
echo "Complete! Your archive $ZIP_NAME.zip"
