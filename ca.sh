#!/bin/bash

#create array from file input
user_names=()
while IFS= read -r line; do
   user_names+=("$line")
done

for user in ${user_names[@]};
do
 echo "Backup of ${user}"
 id "${user}" &> /dev/null
 output=$?
 cur_dir=`pwd`
 #check if users exists in the system
 if [ "${output}" -eq 0 ]; then
 echo "user ${user} exists in the system"
 user_home=$(awk -F ':' -v user="${user}" '$1==user {print $6}' /etc/passwd )
 echo "The path to home directory for user ${user} is ${user_home}"
 dir=$( dirname "${user_home}")
 base=$( basename "${user_home}" )

 #creating file named backup with list of files to be backed up
 echo "Creating .backup file"
 find ${user_home} -user ${user} -ls > ${user_home}/.backup
 to_path=/var

 #check if backup file exists, if it does extract to /tmp/backup
 echo "checking if backup file exists, if it does extract to /tmp/backup. Current directory is ${cur_dir}"
 file="/var/backup.tar.gz"
 backup_dir="/tmp/backup"
 if [ -e "$file" ]; then
 echo "$file exists and will be extracted to /tmp/backup"

 #check if directory /home/user/tmp/backup exists if not creating it
 echo "checking  if directory /home/user/tmp/backup exists if not creating it. Current Current directory is ${cur_dir}"
  if [ -d "/tmp/backup" ]; then
  echo "Directory $backup_dir exists"
  else
  echo "Directory $backup_dir does not exists and will be created in ${current_dir}"
  mkdir /tmp/backup
  fi
 tar -xzvf $file  -C /tmp/backup/ &> /dev/null
 else
 echo "$file do not exits and will be created"
 fi

 #compare files in /home/<user> with those in tmp/backup/<user> and if different file needs to be renamed to file.1 .2 .3 etc.
 dir1=/home/${user}/
 dir2=/tmp/backup/${user}/

 echo "Comparing if files in directory ${dir1} are different then files in directory ${dir2} if yes then they will be renamed."

 for file in $dir1/*; do
    name=${file##*/}
    if [[ -f $dir2/$name ]]; then
        echo "$name exists in both directories"

        if cmp -s "$dir1/$name" "$dir2/$name"; then
        echo "The file "$name" is the same in both directories"
        else
        echo "The file "$name" in directory "$dir2" and will renamed"

        orig=$dir2/$name

                i=0
                while [[ -f $dir2/$name ]];do
                let i++
                mv "$dir2/$name" "$dir2/$name.${i}"
                done
        echo "file "${name}" renamed to "$name.${i}"."
        fi
    fi
 done


 #creating back up
 tar -C ${dir} -Pczf /var/backup.tar.gz ${base}

 echo "Backup completed!"
 else
 echo "User ${user} does not exists in the system."
 fi
 done