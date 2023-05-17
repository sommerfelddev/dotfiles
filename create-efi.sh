#!/usr/bin/env sh
set -e

lsblk

printf "Boot disk [sda]: " && read -r boot_disk
if [ -z "$boot_disk" ]; then
    boot_disk='sda'
fi

printf "Boot partition number [1]: " && read -r boot_partition_number
if [ -z "$boot_partition_number" ]; then
    boot_partition_number='1'
fi

printf "Root partition [sda2]: " && read -r root_partition
if [ -z "$root_partition" ]; then
    root_partition='sda2'
fi
root_uuid=$(blkid /dev/"$root_partition" | cut -f 2 -d " ")

printf "Kernel name [linux]: " && read -r kernel_name
if [ -z "$kernel_name" ]; then
    kernel_name='linux'
fi

printf "CPU vendor (intel/amd) [intel]: " && read -r cpu_vendor
if [ -z "$cpu_vendor" ]; then
    cpu_vendor='intel'
fi

printf "ESP (boot/efi) [boot]: " && read -r esp
if [ -z "$esp" ]; then
    esp='boot'
fi

printf "extra kernel parameters (e.g. mitigations=off): " && read -r extra_kernel_params

printf "label [archlinux]: " && read -r label
if [ -z "$label" ]; then
    label='archlinux'
fi

rel_path=""
rel_path2=""
if [ "$esp" = "efi" ]; then
    rel_path="\\EFI\\arch"
    rel_path2="/EFI/arch"
fi


unicode_arg="cryptdevice=$root_uuid:root root=/dev/mapper/root rw initrd=$rel_path\\$cpu_vendor-ucode.img initrd=$rel_path\\initramfs-$kernel_name.img quiet $extra_kernel_params"

set -x
pacman -S --needed "$cpu_vendor"-ucode
pacman -S --asdeps --needed efibootmgr
efibootmgr --disk /dev/"$boot_disk" --part "$boot_partition_number" --create --label "$label" --loader "$rel_path2"/vmlinuz-"$kernel_name" --unicode "$unicode_arg"
