find . -iname \*m4a | while read f
do
    echo ffmpeg -i $f $f.mp3
#    NEW=$(echo "'""${f}""'" | sed -e's/ /-/g')
#    echo mv "'""${f}""'" $NEW
done

