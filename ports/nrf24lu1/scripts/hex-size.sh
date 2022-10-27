#!/usr/bin/env bash
# Copyright 2017 jem@seethis.link
# Licensed under the MIT license (http://opensource.org/licenses/MIT)

target_basename=`basename $1`
target_dir=`dirname $1`
old_hex_size_file="$target_dir/.old_hex_size-$target_basename.o"
old_xram_size_file="$target_dir/.old_xram_size-$target_basename.o"

old_hex_size=`cat "$old_hex_size_file"`
hex_size=`size $1 | grep $1 | awk '{ printf $2 }'`
if [[ $hex_size -eq "" ]]; then
    hex_size=0
fi
echo $hex_size > "$old_hex_size_file"
printf -v size_in_hex "%x" "$hex_size"
free_space16=$((0x4000 - $hex_size))
free_space32=$((0x8000 - $hex_size))
echo -e "hex size: $hex_size \t0x$size_in_hex"
echo "hex delta: $((hex_size - old_hex_size))"
echo -e "free f16: $free_space16 (used $((100 * $hex_size / 0x4000))% of $((0x4000)))"
echo -e "free f32: $free_space32 (used $((100 * $hex_size / 0x8000))% of $((0x8000)))"

xram_info=$(grep "EXTERNAL RAM" $2)
xram_used=$(echo $xram_info | awk '{ print $5; }')
xram_total=$(echo $xram_info | awk '{ print $6; }')

old_xram_size=`cat "$old_xram_size_file"`
echo $xram_used > "$old_xram_size_file"
echo -e "xram used: $xram_used ($((100 * $xram_used / $xram_total))% of $xram_total)"
echo "xram delta: $((xram_used - old_xram_size))"
