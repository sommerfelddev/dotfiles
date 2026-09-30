# TPM Unlock on Arch

The root volume uses a systemd TPM enrollment with a `pcrlock` policy that
protects PCR 7. Keep a working disk passphrase and the policy recovery PIN in
a secure location accessible without unlocking this laptop.

The policy, enrollment, and generated component files are host state. Do not
copy them into this repo. Deploy this configuration only after policy creation,
enrollment, and an automatic unlock test have succeeded.

## Deploy

Run on the Arch host, outside aibox:

```sh
just apply
sudo systemctl daemon-reload
sudo systemctl enable systemd-pcrlock-make-policy.service
sudo systemctl restart systemd-pcrlock-make-policy.service
sudo journalctl -b -u systemd-pcrlock-make-policy.service --no-pager
```

The journal must show PCR 7 in the protection mask, or report that the policy
has not changed. Check for errors and unmet conditions. A successful command
exit alone does not prove that a conditional service ran.

The service runs after root is unlocked. It updates the existing TPM policy
and boot credential from the approved component files. It selects only PCR 7
and requires the policy files and the mounted EFI System Partition at `/boot`.
On a host without an existing policy, the service skips execution.

Leave `systemd-pcrlock-secureboot-policy.service` and
`systemd-pcrlock-secureboot-authority.service` disabled. These services generate
component files from the current system. This setup retains the approved
components instead of automatically accepting changes to Secure Boot settings.

## Updates

Normal kernel and initramfs updates do not require LUKS re-enrollment. Keep the
existing mkinitcpio and Secure Boot signing hooks. Policy maintenance does not
build or sign UKIs.

After a systemd update, check the prediction before rebooting:

```sh
sudo /usr/lib/systemd/systemd-pcrlock --pcr=7 --location=770 predict
```

If PCR 7 is included and the prediction completes without errors, refresh the
policy and check the journal:

```sh
sudo systemctl restart systemd-pcrlock-make-policy.service
sudo journalctl -b -u systemd-pcrlock-make-policy.service --no-pager
```

Prediction uses the current boot log. It cannot guarantee that changed firmware
or boot software will produce the same measurements on the next boot. Keep the
disk passphrase available. No unattended hook relaxes protection or replaces
LUKS enrollments.

## NvPCR Measurements

This setup initializes the four systemd NvPCRs. It records hardware identity,
the logged-in user, and the LUKS root unlock method and keyslot. It also records
the root volume key in ordinary PCR 15. The verity NvPCR has no event on this
host because it does not use dm-verity. Root unlock still uses only the existing
PCR 7 `pcrlock` policy. The NvPCR indices are separate from that policy's index.

Ukify signs an initrd PCR 11 policy with reference `initrd` and embeds its public
key in each UKI. The `sbctl` mkinitcpio post hook signs the complete UKI for
Secure Boot. Keep the PCR private key outside the repo and EFI System Partition
(ESP). Do not regenerate it during updates.

### First Activation

Run these steps on Halley2. Keep the LUKS passphrase and pcrlock recovery PIN
available without unlocking this laptop. Do not reboot until the requested test
is agreed. Stop if any command fails.

1. Install the declared Arch packages. A full Arch update may rebuild UKIs. If
   it does, verify Secure Boot signing and automatic unlock on a separate,
   approved reboot before taking the recovery copy below.

   ```sh
   sudo pacman -Syu --needed systemd-ukify efibootmgr sbsigntools
   pacman -Q systemd systemd-ukify mkinitcpio
   sudo sbctl verify
   sudo /usr/lib/systemd/systemd-pcrlock --strict=yes --pcr=7 --location=770 predict
   df -h /boot
   ```

   `systemd` and `systemd-ukify` must have the same package version. Check that
   `/boot` can hold one more complete hardened UKI and temporary replacement
   files. Leave enough free space for normal kernel updates.

2. Save the current boot images and affected `/etc` files in a root-only backup.
   Do this once, before `just apply`. Do not overwrite this backup on a retry.

   ```sh
   sudo bash -euo pipefail -c '
     backup=/var/lib/dotfiles/tpm-nvpcr/backup
     test ! -e "$backup"
     install -d -m 0700 "$backup"
     cp -a /boot/EFI/Linux/arch-linux-hardened*.efi \
       /boot/EFI/Linux/arch-linux-lts*.efi "$backup/"
     tar -C / -cpf "$backup/etc.tar" \
       etc/nvpcr/cryptsetup.nvpcr etc/nvpcr/hardware.nvpcr \
       etc/nvpcr/login.nvpcr etc/nvpcr/verity.nvpcr \
       etc/systemd/system/systemd-pcrlogin@.service \
       etc/systemd/system/systemd-pcrproduct.service \
       etc/mkinitcpio.conf.d/60-no-nvpcr.conf \
       etc/mkinitcpio.conf etc/kernel/cmdline \
       etc/kernel/cmdline-linux-hardened
   '
   ```

3. Copy and check a working recovery UKI. Use `--create-only` so this entry does
   not change the normal EFI boot order. Read its entry number from `efibootmgr -v`.

   ```sh
   sudo cp -a /boot/EFI/Linux/arch-linux-hardened.efi \
     /boot/EFI/Linux/arch-linux-hardened-nvpcr-recovery.efi
   sudo sbverify --cert /var/lib/sbctl/keys/db/db.pem \
     /boot/EFI/Linux/arch-linux-hardened-nvpcr-recovery.efi
   sudo efibootmgr --create-only --disk /dev/nvme0n1 --part 1 \
     --label 'Arch NvPCR Recovery' \
     --loader '\EFI\Linux\arch-linux-hardened-nvpcr-recovery.efi'
   sudo efibootmgr -v
   ```

   On an approved reboot, select this entry once with `efibootmgr --bootnext`
   or the firmware menu. Confirm automatic unlock. Return to the normal entry.
   The recovery copy is outside all mkinitcpio presets.

4. Create a dedicated PCR signing key pair if neither file exists. Ukify refuses
   to replace existing key files. Check permissions and that the keys match.

   ```sh
   sudo ukify --pcr-private-key=/etc/systemd/tpm2-pcr-private-key.pem \
     --pcr-public-key=/etc/systemd/tpm2-pcr-public-key.pem genkey
   sudo stat -c '%U:%G:%a %n' /etc/systemd/tpm2-pcr-private-key.pem
   sudo openssl pkey -in /etc/systemd/tpm2-pcr-private-key.pem -pubout |
     sudo cmp - /etc/systemd/tpm2-pcr-public-key.pem
   ```

   The private file must be `root:root:600`. If either file already exists,
   verify the pair and do not run `genkey` again. Never copy the private key
   into the repo, an initramfs, or the ESP.

5. Apply the repo files and remove only the prior masks. The deployment checks
   the key pair, ukify version, and recovery image before it changes `/etc`.
   Chezmoi does not delete files that were removed from its source directory;
   `tpm-nvpcr-unmask` checks their exact old contents before removing them.

   ```sh
   just apply
   just tpm-nvpcr-unmask
   ```

6. Build and sign all four candidate UKIs on the root filesystem. These
   commands do not replace the active boot images.

   ```sh
   sudo install -d -m 0700 /var/lib/dotfiles/tpm-nvpcr/stage
   sudo mkinitcpio -k /boot/vmlinuz-linux-hardened \
     -U /var/lib/dotfiles/tpm-nvpcr/stage/arch-linux-hardened.efi \
     --cmdline /etc/kernel/cmdline-linux-hardened \
     --ukiconfig /etc/kernel/uki.conf
   sudo mkinitcpio -k /boot/vmlinuz-linux-hardened \
     -U /var/lib/dotfiles/tpm-nvpcr/stage/arch-linux-hardened-fallback.efi \
     --cmdline /etc/kernel/cmdline-linux-hardened \
     --ukiconfig /etc/kernel/uki.conf -S autodetect
   sudo mkinitcpio -k /boot/vmlinuz-linux-lts \
     -U /var/lib/dotfiles/tpm-nvpcr/stage/arch-linux-lts.efi \
     --cmdline /etc/kernel/cmdline --ukiconfig /etc/kernel/uki.conf
   sudo mkinitcpio -k /boot/vmlinuz-linux-lts \
     -U /var/lib/dotfiles/tpm-nvpcr/stage/arch-linux-lts-fallback.efi \
     --cmdline /etc/kernel/cmdline --ukiconfig /etc/kernel/uki.conf \
     -S autodetect
   just tpm-nvpcr-check \
     /var/lib/dotfiles/tpm-nvpcr/stage/arch-linux-hardened.efi \
     /var/lib/dotfiles/tpm-nvpcr/stage/arch-linux-hardened-fallback.efi \
     /var/lib/dotfiles/tpm-nvpcr/stage/arch-linux-lts.efi \
     /var/lib/dotfiles/tpm-nvpcr/stage/arch-linux-lts-fallback.efi
   ```

   The check reads `.pcrpkey`, `.pcrsig`, and `.cmdline` using ukify. It uses
   `lsinitcpio` to check the four required initrd units and verifies each
   Secure Boot signature with the enrolled `sbctl` certificate. Stop on any
   mismatch.

7. Copy each checked image to the ESP under a temporary name, then rename it
   into place before copying the next one. This needs space for only one extra
   image at a time. Do not reboot after a partial copy. Restore from the backup
   if a copy or verification fails.

   ```sh
   sudo bash -euo pipefail -c '
     for name in arch-linux-hardened.efi arch-linux-hardened-fallback.efi \
       arch-linux-lts.efi arch-linux-lts-fallback.efi; do
       install -m 0644 "/var/lib/dotfiles/tpm-nvpcr/stage/$name" \
         "/boot/EFI/Linux/$name.next"
       mv -f "/boot/EFI/Linux/$name.next" "/boot/EFI/Linux/$name"
     done
   '
   sudo sbctl verify
   just tpm-nvpcr-check /boot/EFI/Linux/arch-linux-hardened.efi \
     /boot/EFI/Linux/arch-linux-hardened-fallback.efi \
     /boot/EFI/Linux/arch-linux-lts.efi \
     /boot/EFI/Linux/arch-linux-lts-fallback.efi
   ```

### Boot Checks

After an approved reboot into a new UKI, confirm automatic unlock and run:

```sh
just tpm-nvpcr-check
sudo journalctl -b --no-pager \
  -u systemd-tpm2-setup-early.service \
  -u systemd-pcrnvdone.service \
  -u systemd-pcrproduct.service \
  -u systemd-pcrlogin@1000.service \
  -u systemd-cryptsetup@root.service \
  -u systemd-pcrlock-make-policy.service
systemctl --failed --no-pager
systemd-analyze nvpcrs
```

The early setup and NvPCR separator must succeed. The `hardware`, `login`, and
`cryptsetup` records must appear after their events; `verity` can stay at its
initial value. Check that PCR 7 is still the only disk-unlock policy PCR.
Boot-test hardened and LTS default and fallback UKIs with explicit approval.
Then rebuild with `sudo mkinitcpio -P` and repeat a normal boot test. Keep the
recovery UKI until these checks pass.

### Rollback

If a new image does not boot or automatic unlock fails, select the recovery
entry and use the disk passphrase if needed. On the running host, restore the
saved images and exact `/etc` files. Do not remove any TPM indices or keyslots.

```sh
sudo install -d -m 0700 /var/lib/dotfiles/tpm-nvpcr
sudo touch /var/lib/dotfiles/tpm-nvpcr/rollback
sudo bash -euo pipefail -c '
  cp -a /var/lib/dotfiles/tpm-nvpcr/backup/arch-linux-hardened*.efi \
    /var/lib/dotfiles/tpm-nvpcr/backup/arch-linux-lts*.efi /boot/EFI/Linux/
'
sudo tar -C / -xpf /var/lib/dotfiles/tpm-nvpcr/backup/etc.tar
sudo rm -f /etc/kernel/uki.conf /etc/initcpio/install/nvpcr
sudo systemctl daemon-reload
sudo sbctl verify
```

Revert this task's repo commit before another `just apply`. The rollback marker
blocks redeployment until then. Keep the key pair and recovery UKI for diagnosis.

Sources: [systemd 262 release notes](https://github.com/systemd/systemd/releases/tag/v262),
[ukify](https://github.com/systemd/systemd/blob/v262/man/ukify.xml), and
[systemd TPM measurement guide](https://github.com/systemd/systemd/blob/v262/docs/TPM2_PCR_MEASUREMENTS.md).

## Recovery

If automatic unlock fails, use the disk passphrase. Inspect the boot journal
and `systemd-pcrlock log` before changing policy. Do not clear the TPM, remove
the policy, or remove password slots.

After confirming that a Secure Boot change was intended, regenerate its
component files:

```sh
sudo /usr/lib/systemd/systemd-pcrlock lock-secureboot-policy
sudo /usr/lib/systemd/systemd-pcrlock lock-secureboot-authority
sudo /usr/lib/systemd/systemd-pcrlock --pcr=7 --location=770 predict
```

Proceed only if PCR 7 is included. Update the existing policy with its recovery
PIN when the old policy no longer permits updates:

```sh
sudo /usr/lib/systemd/systemd-pcrlock \
  --pcr=7 --location=770 --recovery-pin=query make-policy
```

Enter the policy recovery PIN, not the disk passphrase. Do not record this
session or share the PIN. Reboot to test automatic unlock. An update to the
existing policy normally needs neither re-enrollment nor a UKI rebuild.

Reference: [systemd-pcrlock manual](https://man.archlinux.org/man/systemd-pcrlock.8.en).
