#! /bin/bash
md_path="/home/wl/Downloads/MdDir"

del_no_exist() {
	for i in $(ls $1); do
		flag=0
		for j in $2; do
			if [[ "$i" == "$j" ]]; then
				flag=1
			fi
		done
		if [ $flag -eq 0 ]; then
			rm -rf $1/$i
		fi
	done
}

png_dir=$(grep -rE "*.png" $md_path/*.md | awk -F ":" '{print $2}' | awk -F "/" '{print $3}' | tr -d ")" | uniq)
png_name=$(grep -rE "*.png" $md_path/*.md | awk -F ":" '{print $2}' | awk -F "/" '{print $4}' | tr -d ")" | uniq)
del_no_exist "$md_path/media" "$png_dir"
del_no_exist "$md_path/media/*" "$png_name"
