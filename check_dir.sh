#!/bin/bash

root_directory="/mnt/nfs-data/ShadowSocket/NetStatus"
ip_address="0.0.0.0"
function get_ip () {
    curl ip.6655.com/ip.aspx
}
function sh_init () {
    get_ip > /root/ip.txt
    if [ -d "$root_directory" ]; then
	#echo "The root_directory is exist"
	return  0
    else
	echo "The root_directory is not exist"
	#如果目录不存在，则将该目录从nfs服务器挂载到本地
	#mount
	return  0
    fi
    
}
#对数组排序
function shell_sort () {
    sum=${netstatus[0]}
    min=${netstatus[0]}
    max=${netstatus[0]}
    for (( i=1; i<${#netstatus[@]}; i++))
    do
	if [ ${netstatus[$i]}>=$max ]; then
	    max=${netstatus[$i]}
	    sum=$sum+${netstatus[$i]}
	elif [ ${netstatus[$i]}<=$min ]; then
	    min=${netstatus[$i]}
	    sum=$sum+${netstatus[$i]}
	fi
    done
    
    echo $sum
    echo $min
    echo $max
    
}
function check_netstatus () {
    #echo $1
    #echo $2
    netstatus=($(ping -c4 -W1 $1 | awk '
    NR==2,NR==5{
	gsub(/time=/,"",$7);
	package_num++;
	netstatus[package_num]=$7;	
    } END {
        for (i in netstatus)
	print netstatus[i] | "sort -n";
    }'))
    
    min=${netstatus[0]}
    max=${netstatus[3]}
    echo "{
	\"ip\":\"$ip_address\",
	\"packages\":4,
	\"max_network_delay\":\"$max ms\",
	\"min_network_delay\":\"$min ms\",
}" > $2
}
function read_the_dir () {
    ip_address_dirs=($(ls -l  $1 | awk '/^d/ {
	print $NF;
     }'))
    echo "目录数量："${#ip_address_dirs[@]}
    
    for ip_dir in ${ip_address_dirs[*]}
    do
	if [ -f "$root_directory/$ip_dir/$ip_address.json" ]; then
      	    continue
	else
	    filepath="$root_directory/$ip_dir/$ip_address.json"
	    touch $filepath
	    check_netstatus $ip_dir $filepath & 
	fi
    done
    
    #echo ${ip_address_dirs[*]}  
}

#初始化脚本环境
sh_init
#读取主机外网ip地址
if [ -f /root/ip.txt ]; then
    ip_address=$( cat /root/ip.txt )
fi
#echo $ip_address

#读取nfs服务器目录
if [ $? == 0 ]; then
    read_the_dir $root_directory
fi
