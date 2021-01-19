#/bin/bash
# Script para recuperação automática do GRUB em distros Debian-like.

if [ "$(id -u)" != "0" ]; then
    exec sudo "$0" "$@"
fi

if [ $# -eq 1 ]; then
    MOUNT=/mnt/$1
    DEVICE=/dev/$1
else
    echo "Como usar este script: ./grub-recovery.sh sda1"
    echo "Entre com o nome da partição do sistema o qual será recuperado o grub"  
    exit 1
fi

echo "Montando a partição $DEVICE em $MOUNT"
sleep 2
mkdir -p $MOUNT
mount $DEVICE $MOUNT
mount /dev/sda1 $MOUNT/boot/efi
mount --bind /dev $MOUNT/dev
mount --bind /dev/pts $MOUNT/dev/pts
mount --bind /proc $MOUNT/proc
mount --bind /sys $MOUNT/sys
mount --bind /run $MOUNT/run
sleep 2
chroot $MOUNT /bin/bash -c "grub-install /dev/sda ; update-grub ; exit"
#chroot $MOUNT /bin/bash -c "grub-install /dev/sda ; grub-mkconfig -o /boot/grub/grub.cfg ; exit"
sleep 2
echo "GRUB instalado com sucesso!"
echo "Desmontando a partição..."
umount -l $MOUNT/run
umount -l $MOUNT/sys
umount -l $MOUNT/proc
umount -l $MOUNT/dev/pts
umount -l $MOUNT/dev
umount $MOUNT/boot/efi
umount $MOUNT
sleep 2
echo "OK!"