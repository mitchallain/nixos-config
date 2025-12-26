# Testing NixOS Configuration on Ubuntu

This guide shows how to test the NixOS VM configuration on your Ubuntu x86
laptop using virt-manager (QEMU/KVM). This is actually easier and faster than
testing on macOS!

## Why Test on Ubuntu First?

- **Better virtualization**: Native KVM support (faster than UTM on Mac)
- **Same hardware architecture**: x86_64 on both Ubuntu and your laptop
- **No risk**: VM is isolated from your Ubuntu installation
- **Faster iteration**: Quick to rebuild and test changes
- **Free tools**: virt-manager and KVM are open source

## Prerequisites

- Ubuntu system (18.04+)
- At least 8GB RAM (16GB+ recommended so you can give 8GB to the VM)
- 20GB free disk space
- CPU with virtualization support (Intel VT-x or AMD-V)

## Step 1: Verify Virtualization Support

```bash
# Check if your CPU supports virtualization
egrep -c '(vmx|svm)' /proc/cpuinfo
# If this returns a number > 0, you're good!

# Check if KVM is available
lsmod | grep kvm
# Should show kvm_intel or kvm_amd
```

If KVM is not loaded, you may need to enable virtualization in your BIOS/UEFI
settings.

## Step 2: Install Virtualization Tools

```bash
# Install QEMU/KVM and virt-manager
sudo apt update
sudo apt install -y \
  qemu-kvm \
  libvirt-daemon-system \
  libvirt-clients \
  bridge-utils \
  virt-manager \
  ovmf

# Add your user to the libvirt and kvm groups
sudo usermod -aG libvirt $USER
sudo usermod -aG kvm $USER

# Start and enable libvirtd service
sudo systemctl enable --now libvirtd

# Log out and back in for group changes to take effect
# Or run: newgrp libvirt
```

Verify installation:

```bash
virsh list --all
# Should show an empty list of VMs (if this works, you're ready!)
```

## Step 3: Adjust Configuration for x86_64

```bash
cd ~/dotfiles/nixos

# Update flake.nix to use x86_64-linux instead of aarch64-linux
sed -i 's/system = "aarch64-linux"/system = "x86_64-linux"/' flake.nix

# Verify the change
grep "system =" flake.nix
# Should show: system = "x86_64-linux";
```

## Step 4: Download NixOS ISO

```bash
# Create a directory for ISOs
mkdir -p ~/ISOs
cd ~/ISOs

# Download NixOS x86_64 minimal ISO
curl -LO https://channels.nixos.org/nixos-25.11/latest-nixos-minimal-x86_64-linux.iso

# Verify download
ls -lh *.iso
```

## Step 5: Create VM with virt-manager

### GUI Method

1. **Launch virt-manager**:

   ```bash
   virt-manager &
   ```

2. **Create New VM**:

   - Click "Create a new virtual machine"
   - Select "Local install media (ISO image or CDROM)"
   - Click "Forward"

3. **Choose ISO**:

   - Click "Browse..." → "Browse Local"
   - Navigate to `~/ISOs/` and select the NixOS ISO
   - Uncheck "Automatically detect from installation media" if checked
   - Type "Generic Linux" or search for "NixOS"
   - Click "Forward"

4. **Configure Memory and CPU**:

   - Memory: 8192 MB (8 GB)
   - CPUs: 4 cores
   - Click "Forward"

5. **Configure Storage**:

   - Create a disk image: 40 GB (recommended) or 20 GB minimum
   - Click "Forward"

6. **Final Configuration**:

   - Name: "nixos-vm-test"
   - Check "Customize configuration before install"
   - Network selection: "default" is fine
   - Click "Finish"

7. **Customize Hardware** (in the dialog that opens):
   - **Overview** → Firmware: Change to "UEFI x86_64:
     /usr/share/OVMF/OVMF_CODE.fd"
   - **Boot Options**: Enable "Start virtual machine on host boot" (optional)
   - **Video**: Model: "Virtio" (better performance)
   - **Display**: Type: "Spice server" (better performance)
   - Click "Begin Installation" in top left

### CLI Method (Alternative)

```bash
# Create VM using virt-install
virt-install \
  --name nixos-vm-test \
  --memory 8192 \
  --vcpus 4 \
  --disk size=40 \
  --cdrom ~/ISOs/latest-nixos-minimal-x86_64-linux.iso \
  --os-variant generic \
  --boot uefi \
  --network network=default \
  --graphics spice \
  --video virtio \
  --console pty,target_type=serial

# This will launch the VM automatically
```

## Step 6: Install NixOS

The VM will boot into the NixOS installer. Follow the installation steps from
the main README, starting at "Step 3: Partition and Mount Disks".

Key differences for Ubuntu/virt-manager:

- The disk will likely be `/dev/vda` (same as UTM)
- Network should work out of the box with DHCP
- Display resolution should auto-adjust with SPICE guest tools

### Quick Installation Reference

```bash
# Partition disk
parted /dev/vda -- mklabel gpt
parted /dev/vda -- mkpart ESP fat32 1MiB 512MiB
parted /dev/vda -- set 1 esp on
parted /dev/vda -- mkpart primary 512MiB 100%

# Format partitions
mkfs.fat -F 32 -n boot /dev/vda1
mkfs.ext4 -L nixos /dev/vda2

# Mount
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Clone dotfiles (adjust for your repo)
nix-shell -p git
git clone https://github.com/yourusername/dotfiles /mnt/home/mallain/dotfiles
cd /mnt/home/mallain/dotfiles
git submodule update --init --recursive

# Generate and setup config
nixos-generate-config --root /mnt
rm /mnt/etc/nixos/configuration.nix
cp -r /mnt/home/mallain/dotfiles/nixos/* /mnt/etc/nixos/

# Rename hardware config for VM and save it
mv /mnt/etc/nixos/hardware-configuration.nix /mnt/etc/nixos/hardware-vm.nix
cp /mnt/etc/nixos/hardware-vm.nix /mnt/home/mallain/dotfiles/nixos/

# Verify x86_64 architecture in flake
grep -A 1 "nixos-vm" /mnt/etc/nixos/flake.nix | grep "x86_64-linux"

# Install
nixos-install --flake /mnt/etc/nixos#nixos-vm

# Set passwords
# (root password will be prompted)
nixos-enter --root /mnt -c 'passwd mallain'

# Shutdown
shutdown -h now
```

## Step 7: First Boot

1. **Remove ISO**:

   - In virt-manager, right-click the VM → "Open"
   - Click "Show virtual hardware details" (lightbulb icon)
   - Select "CDROM" or "SATA CDROM 1"
   - Click "Disconnect" or remove the ISO path
   - Click "Apply"

2. **Start VM**:

   - Click "View" → "Console" (monitor icon)
   - Click the power button in virt-manager to start

3. **Login**:

   - Should boot into GNOME
   - Username: `mallain`
   - Password: (what you set)

4. **Test the system**:

   ```bash
   # Verify system
   neofetch

   # Check your dotfiles work
   cd ~/dotfiles
   ./install
   source ~/.bashrc

   # Test a rebuild
   cd ~/dotfiles/nixos
   ./rebuild.sh
   ```

5. **Commit your hardware configuration**:

   After verifying everything works, commit the generated hardware config to git:

   ```bash
   cd ~/dotfiles/nixos

   # See what changed
   git status
   git diff hardware-vm.nix

   # Commit the hardware config
   git add hardware-vm.nix flake.nix
   git commit -m "Add NixOS VM hardware configuration for testing

   - Generated hardware-vm.nix on Ubuntu test VM
   - Set architecture to x86_64-linux
   - Successfully tested installation and rebuild"

   git push
   ```

   **Note**: The hardware config documents your VM's disk layout and should be
   version controlled along with the rest of your NixOS configuration.

## Tips for Testing

### Performance Tuning

If the VM feels slow:

```bash
# Edit VM settings in virt-manager:
# - CPU: Enable "Copy host CPU configuration"
# - Video: Use "Virtio" model
# - Network: Use "virtio" device model
```

### Shared Folders

To share files between Ubuntu and the VM:

1. In virt-manager, add hardware → Filesystem

   - Mode: "Mapped"
   - Source path: `/home/yourusername/shared` (create this on Ubuntu)
   - Target path: `shared` (mount tag)

2. In the NixOS VM:
   ```bash
   sudo mkdir -p /mnt/shared
   sudo mount -t 9p -o trans=virtio shared /mnt/shared
   ```

### SSH Access

Enable SSH to the VM for easier access:

```bash
# On Ubuntu host, find VM IP
virsh net-dhcp-leases default

# SSH from Ubuntu to VM
ssh mallain@<vm-ip>
```

### Snapshot Before Testing

Create a snapshot before making major changes:

```bash
# In virt-manager:
# Right-click VM → Snapshots → Create snapshot
# Or via CLI:
virsh snapshot-create-as nixos-vm-test snapshot1 "Clean install"

# Restore snapshot
virsh snapshot-revert nixos-vm-test snapshot1
```

## Testing Your Configuration Changes

Perfect workflow for iterating on your NixOS config:

1. Edit config files on Ubuntu:

   ```bash
   cd ~/dotfiles/nixos
   vim configuration.nix  # or home.nix, flake.nix, etc.
   ```

2. Copy changes to VM (if not using shared folders):

   ```bash
   # From Ubuntu, copy to VM
   scp configuration.nix mallain@<vm-ip>:~/dotfiles/nixos/
   ```

3. In the VM, rebuild:

   ```bash
   cd ~/dotfiles/nixos
   ./rebuild.sh
   ```

4. If something breaks, rollback:

   ```bash
   sudo nixos-rebuild switch --rollback
   ```

5. Once happy, commit changes:
   ```bash
   cd ~/dotfiles
   git add nixos/
   git commit -m "Update NixOS configuration"
   git push
   ```

## Differences from UTM Setup

| Feature          | virt-manager (Ubuntu) | UTM (Mac)             |
| ---------------- | --------------------- | --------------------- |
| Performance      | Faster (native KVM)   | Good (virtualization) |
| Display          | SPICE + virtio-gpu    | virtio-gpu            |
| Clipboard        | Works via SPICE       | Works via SPICE       |
| Shared folders   | 9p virtio-fs          | VirtFS/9p             |
| Architecture     | x86_64                | aarch64 or x86_64     |
| Setup difficulty | Easier                | Slightly more steps   |

## Cleanup

When done testing:

```bash
# Stop VM
virsh destroy nixos-vm-test

# Delete VM and disk
virsh undefine nixos-vm-test --remove-all-storage

# Or use virt-manager GUI:
# Right-click VM → Delete → Check "Delete associated storage files"
```

## Next Steps

Once you've validated the configuration on Ubuntu:

1. Test your dotfiles work correctly
2. Try migrating some configs to home-manager
3. Verify rebuilds work as expected
4. Test that your development environment works
5. When satisfied, switch back to aarch64 for Mac:
   ```bash
   cd ~/dotfiles/nixos
   sed -i 's/system = "x86_64-linux"/system = "aarch64-linux"/' flake.nix
   ```

Then follow the main README for setting up on your MacBook with UTM!

## Troubleshooting

### "Permission denied" when starting VM

```bash
# Make sure you're in the right groups
groups | grep libvirt
groups | grep kvm

# If not, add yourself and reboot
sudo usermod -aG libvirt,kvm $USER
sudo reboot
```

### "Could not access KVM kernel module"

```bash
# Check if KVM is loaded
lsmod | grep kvm

# If not, load it
sudo modprobe kvm
sudo modprobe kvm_intel  # or kvm_amd for AMD CPUs

# Make it permanent
echo "kvm" | sudo tee -a /etc/modules
echo "kvm_intel" | sudo tee -a /etc/modules  # or kvm_amd
```

### OVMF/UEFI firmware not found

```bash
# Install OVMF package
sudo apt install ovmf

# Find OVMF path
find /usr/share -name "OVMF_CODE*.fd"

# Use that path in virt-manager firmware settings
```

### VM network not working

```bash
# Restart libvirt network
sudo virsh net-start default
sudo virsh net-autostart default

# Check network status
sudo virsh net-list --all
```

## Resources

- [virt-manager documentation](https://virt-manager.org/)
- [libvirt documentation](https://libvirt.org/docs.html)
- [KVM on Ubuntu guide](https://ubuntu.com/server/docs/virtualization-libvirt)
