#!/bin/bash

#Arch Linux install script,
#For the various Dell Optiplex All-in-ones that ECM graciously donated to the Computer Interest Floor in Fall of 2025.
#This script was made by Jacob Greenberg in 2025 : )
# sudo mkarchiso -v -r -w /tmp/archiso-tmp -o /mnt ~/archlive/
#This is Revision 2.1


#Expect the folowing information:
#/dev/sda1 is the EFI partition
#/dev/sda2 is the Swap Partition
#/dev/sda3 is the Root Partition
#/dev/sda4 is the Data/Home Partition

################################
### User Configuration!
### Change this depending on the computer you are installing to!  : )
################################

DISK="/dev/sda"
HOSTNAME="genericcomputer"
USERNAME="CIF"
PASSWORD="IUseArchBTW"
ROOTPASSWORD="IAmRoot"
TIMEZONE="US/Eastern"
LOCALE="en_US.UTF-8"

#Please change the passwords down below!!!

################################
### Start the Installation
### You shouldn't have to change this!
################################

#set -x #echo on
set -eo pipefail
echo -ne "Starting Install"
#exec >/tmp/cif-install.log 2>&1
pacman -Sy archlinux-keyring

#Verify if we are booted into 64 bit UEFI, since our install script expects that.
echo ">>> Verifying UEFI firmware (64-bit)..."
if [ ! -f /sys/firmware/efi/fw_platform_size ]; then
    echo "ERROR: System does not appear to be booted in UEFI mode."
    exit 1
fi
FW_SIZE=$(cat /sys/firmware/efi/fw_platform_size)
if [ "$FW_SIZE" != "64" ]; then
    echo "ERROR: UEFI firmware size is $FW_SIZE-bit, but 64-bit is required."
    exit 1
fi
echo ">>> UEFI verified: 64-bit firmware detected."

echo ">>> Verifying disk size on $DISK ..."

DISK_SIZE_BYTES=$(blockdev --getsize64 "$DISK")
MIN_SIZE_BYTES=$((200 * 1024 * 1024 * 1024))  # 200 GB

if [ "$DISK_SIZE_BYTES" -lt "$MIN_SIZE_BYTES" ]; then
    echo "ERROR: Disk is smaller than 200 GB!"
    echo "Detected size: $((DISK_SIZE_BYTES / 1024 / 1024 / 1024)) GB"
    echo "Minimum required: 200 GB"
    exit 1
fi

echo ">>> Disk size OK: $((DISK_SIZE_BYTES / 1024 / 1024 / 1024)) GB"




#Set time accurately with NTP to make sure that clock is synchronized.
timedatectl

#Partitioning our disk!
echo ">>> Partitioning $DISK"
sgdisk --zap-all "$DISK"
sgdisk -n 1:0:+1G    -t 1:ef00 -c 1:"EFI" "$DISK"
sgdisk -n 2:0:+16G   -t 2:8200 -c 2:"SWAP" "$DISK"
sgdisk -n 3:0:+100G  -t 3:8300 -c 3:"ROOT" "$DISK"
sgdisk -n 4:0:0      -t 4:8302 -c 4:"HOME" "$DISK"

#Determinig partition names for NVMe and SATA, dependent on which one you have.
if [[ "$DISK" == *"nvme"* ]]; then
    EFI_PART="${DISK}p1"
    SWAP_PART="${DISK}p2"
    ROOT_PART="${DISK}p3"
    HOME_PART="${DISK}p4"
else
    EFI_PART="${DISK}1"
    SWAP_PART="${DISK}2"
    ROOT_PART="${DISK}3"
    HOME_PART="${DISK}4"
fi

#Formatting our partitions
echo ">>> Formatting filesystem"

mkfs.fat -F32 "$EFI_PART"
mkswap "$SWAP_PART"
mkfs.ext4 "$ROOT_PART"
mkfs.ext4 "$HOME_PART"

#Mounting everything
echo ">>> Mounting partitions"
mount "$ROOT_PART" /mnt
mkdir -p /mnt/boot
mount "$EFI_PART" /mnt/boot
mkdir -p /mnt/home
mount "$HOME_PART" /mnt/home
swapon "$SWAP_PART"

#Installing our packages and generating fstab.
echo ">>> Installing base system..."
pacstrap /mnt base linux linux-firmware grub efibootmgr nano networkmanager dhcpcd sudo openssh fastfetch base-devel git
echo ">>> Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

#Doing stuff in chroot
echo ">>> Entering chroot to configure installed system..."

echo ">>> Setting root password"
echo "root:$ROOTPASSWORD" | arch-chroot /mnt chpasswd
echo ">>> Creating $USERNAME & Changing Password"
arch-chroot /mnt useradd -m "$USERNAME"
echo "$USERNAME:$PASSWORD" | arch-chroot /mnt chpasswd $USERNAME
arch-chroot /mnt /bin/bash <<EOF


echo ">>> Setting timezone"
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

echo ">>> Configuring locale"
sed -i "s/#$LOCALE UTF-8/$LOCALE UTF-8/" /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf

echo ">>> Setting hostname"
echo "$HOSTNAME" > /etc/hostname


echo ">>> Creating $USERNAME..."
usermod -a -G wheel "$USERNAME"
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo ">>> Enabling NetworkManager"
systemctl enable NetworkManager

echo ">>> Installing GRUB"
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

EOF

echo ">>> Fixing Fastfetch"
#Fun stuff for custom scriptyscript.
cat > /mnt/etc/os-release <<EOF
NAME="CIF OS"
PRETTY_NAME="CIF OS"
ID="cifos"
BUILD_ID=rolling
ANSI_COLOR="38;2;23;147;209"
HOME_URL="https://cif.rochester.edu/"
LOGO="cifos-logo"
EOF

#Stuff for Logo and Fastfetch
mkdir /mnt/cifos
#cp ascii.txt /mnt/cifos

cat > /mnt/cifos/ascii.txt <<'EOF'
[38;2;0;200;0m           `.:/ossyyyysso/:.
[38;2;0;200;0m        .:oyyyyyyyyyyyyyyyyyyo:`
[38;2;0;200;0m      -oyyyyyyyyyyyyyyyyyyysyyyyo-
[38;2;0;200;0m    -syyyyyyyyyyyyyyyyyyyyyyyyyyyys-
[38;2;0;200;0m   oyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyo
[38;2;0;200;0m `oyyyyyo[38;2;255;255;255mk0KKXXXXXXXXXXXXXXXXXXXXXXO[38;2;0;200;0myo`
[38;2;0;200;0m oyyyyy[38;2;255;255;255mkNMMWXKKKKNMMWNXKKXWMMNK0KK0Kk[38;2;0;200;0myo
[38;2;0;200;0m-yyyyl[38;2;255;255;255mXMMXd:,''';OMMKkc''lXMMk[38;2;0;200;0myyyyyyyyy-
[38;2;0;200;0moyyyy[38;2;255;255;255m0MMKc..';c:l0MMKx:..cXMM0lcc[38;2;0;200;0myyyyyyo
[38;2;0;200;0myyyyy[38;2;255;255;255mKMMk'..oXWWWMMMKx:..cXMMMWMNl[38;2;0;200;0myyyyyy
[38;2;0;200;0myyyyy[38;2;255;255;255m0MM0,..;xkkOXMMKx:..cXMMXOkk[38;2;0;200;0myyyyyyy
[38;2;0;200;0moyyyy[38;2;255;255;255moNMWk;.....'kMMKx;..cXMMx[38;2;0;200;0myyyyyyyyyo
[38;2;0;200;0m-yyyyy[38;2;255;255;255moXMWXkdooodKMMNKxookNMMx[38;2;0;200;0myyyyyyyyy-
[38;2;0;200;0m oyyyyy[38;2;255;255;255md0NWMMMMMMMMMMMMMMMMMMx[38;2;0;200;0myyyyyyyyo
[38;2;0;200;0m `oyyyyyy[38;2;255;255;255mcodoooodddddoodooood[38;2;0;200;0myyyyyyyyo
[38;2;0;200;0m   oyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyo
[38;2;0;200;0m    -syyyyyyyyyyyyyyyyyyyyyyyyyyyys-
[38;2;0;200;0m      -oyyyyyyyyyyyyyyyyyyyyyyyyo-
[38;2;0;200;0m        ./oyyyyyyyyyyyyyyyyyyo/.
[38;2;0;200;0m           `.:/oosyyyysso/:.`
[0m
EOF


mkdir -p /mnt/etc/fastfetch
cat > /mnt/etc/fastfetch/config.jsonc <<'EOF'
{
  "logo": {
    "type": "file",
    "source": "/cifos/ascii.txt"
  },
  "modules": [
    "title",     // username@hostname
    "os",
    "host",
    "kernel",
    "uptime",
    "packages",
    "shell",
    "display",
    "cpu",
    "gpu",
    "memory",
    "swap",
    "disk",
    "ip",
    "locale",
    "break",
    "colors"
  ],
  "colors": {
    "title": [255,255,255],
    "os": [255,255,255],
    "host": [255,255,255],
    "kernel": [255,255,255],
    "uptime": [255,255,255],
    "packages": [255,255,255],
    "shell": [255,255,255],
    "display": [255,255,255],
    "cpu": [255,255,255],
    "gpu": [255,255,255],
    "memory": [255,255,255],
    "swap": [255,255,255],
    "disk": [255,255,255],
    "ip": [255,255,255],
    "locale": [255,255,255]
  },
  "display": {
    "separator": " : "
  }
}
EOF

echo ">>> Installing PulseAudio and enabling input-to-output loopback"
arch-chroot /mnt pacman -Sy --noconfirm pulseaudio pulseaudio-alsa alsa-utils

cat > /mnt/cifos/cif-audio.sh <<'EOF'
#!/bin/bash

pactl set-source-port @DEFAULT_SOURCE@ analog-input-headphone-mic
pactl set-sink-port @DEFAULT_SINK@ analog-output-speaker
pactl load-module module-loopback source=$(pactl info | grep "Default Source" | awk "{print \$3}") sink=$(pactl info | grep "Default Sink" | awk "{print \$3}") latency_msec=10 || true
pactl set-sink-volume @DEFAULT_SINK@ 80%
pactl set-source-volume @DEFAULT_SOURCE@ 20%
amixer set 'Master' unmute
amixer set Capture cap 100%
EOF
chmod +x /mnt/cifos/cif-audio.sh


echo ">>> Enabling autologin via GRUB kernel parameters (no systemd modifications)"

# Add autologin parameters to GRUB
sed -i 's|GRUB_CMDLINE_LINUX="|GRUB_CMDLINE_LINUX="systemd.getty_auto=yes systemd.autologin=CIF |' /mnt/etc/default/grub

arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

echo ">>> AutoRun CIF-audio on tty1"

cat > /mnt/home/CIF/.bash_profile <<'EOF'
#!/bin/bash

# Only execute on tty1
if [[ "$(tty)" == "/dev/tty1" ]]; then
    /cifos/cif-audio.sh
fi
pactl set-source-volume @DEFAULT_SOURCE@ 20%
pactl set-source-volume @DEFAULT_SINK@ 80%
EOF

chmod +x /mnt/home/CIF/.bash_profile
#chown CIF:CIF /mnt/home/CIF/.bash_profile

mkdir -p /mnt/etc/systemd/system/getty@tty1.service.d
cat > /mnt/etc/systemd/system/getty@tty1.service.d/autologin.conf <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/agetty --noreset --noclear --autologin CIF - ${TERM}
EOF

arch-chroot /mnt systemctl daemon-reload
arch-chroot /mnt systemctl restart getty@tty1


echo ">>> Autologin configured (DEATH TO SYSTEMD!)"


echo ">>> CIF audio boot service installed and enabled."


echo ">>> Installation complete. You should reboot now.  May CIF live evermore!  (Also, CIF uses arch btw)"
