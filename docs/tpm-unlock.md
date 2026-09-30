# TPM Root Unlock on Halley2

Before this migration, the root token requires the approved PCR 7 pcrlock
policy. The new enrollment also requires an RSA signed PCR 11 policy at
`enter-initrd`. The `luks-root` policy reference is for root unlock; the
existing `initrd` reference remains for NvPCR setup. The root volume is
`/dev/nvme0n1p2`. Keep the tested disk passphrase and pcrlock recovery PIN
available away from this laptop.

The signing key, pcrlock policy, and LUKS metadata are host state. Do not put
them in this repo. Each kernel update must build and Secure Boot sign a UKI
with both PCR 11 signatures. A signed policy approves older UKIs that use the
same signing key and `luks-root` reference; it does not prevent rollback to
an older approved version.

## Prepare

Run these steps on Halley2, outside aibox. Stop if a check fails. No step in
this section changes the LUKS header.

```sh
pacman -Q systemd systemd-ukify mkinitcpio
sudo cryptsetup open --test-passphrase --key-slot 0 /dev/nvme0n1p2
sudo /usr/lib/systemd/systemd-pcrlock --strict=yes --pcr=7 --location=770 predict
df -h /boot
just apply
sudo mkinitcpio -P
sudo sbctl verify
just tpm-nvpcr-check
```

`systemd` and `systemd-ukify` must have the same version. The normal
`mkinitcpio -P` build replaces all four maintained UKIs. The checker verifies
their Secure Boot signatures, initrd services, and both PCR 11 signatures
against the measured contents of each image. It does not claim that the LUKS
token has changed. Before enrollment, check that the initrd has no separate
root key file or credential that could bypass the TPM test.

Back up the header and old TPM token in the encrypted root file system. These
files must stay root owned and must not go to the ESP or the repo. Check the
current LUKS metadata before using the token and slot numbers below. On this
host the existing TPM token is 0, its keyslot is 1, and the passphrase uses
slot 0. Stop if these facts have changed.

```sh
sudo cryptsetup luksDump --dump-json-metadata /dev/nvme0n1p2 | jq '{keyslots: (.keyslots|keys), tokens: (.tokens|with_entries(.value |= {type, keyslots, "tpm2-pcrs", tpm2_pcrlock, tpm2_pubkey_pcrs, tpm2_pubkey_ref}))}'
sudo install -d -m 0700 /var/lib/dotfiles/tpm-root
sudo cryptsetup luksHeaderBackup /dev/nvme0n1p2 \
  --header-backup-file /var/lib/dotfiles/tpm-root/before.header
sudo install -m 0600 /dev/null /var/lib/dotfiles/tpm-root/old-token.json
sudo cryptsetup token export --token-id 0 \
  --json-file /var/lib/dotfiles/tpm-root/old-token.json /dev/nvme0n1p2
```

## Enroll

Enroll a new keyslot with two required TPM policy shards. Do not request a
direct PCR value or a TPM PIN. Enrollment on the running system cannot test
the `enter-initrd` signature because PCR 11 has changed since that phase.

```sh
sudo systemd-cryptenroll /dev/nvme0n1p2 \
  --unlock-tpm2-device=auto --tpm2-device=auto --tpm2-pcrs= \
  --tpm2-pcrlock=/var/lib/systemd/pcrlock.json \
  --tpm2-public-key=/etc/systemd/tpm2-pcr-public-key.pem \
  --tpm2-public-key-pcrs=11 \
  --tpm2-public-key-policyref=luks-root --tpm2-with-pin=no
sudo cryptsetup luksDump --dump-json-metadata /dev/nvme0n1p2 | jq '{keyslots: (.keyslots|keys), tokens: (.tokens|with_entries(.value |= {type, keyslots, "tpm2-pcrs", "tpm2-pcr-bank", tpm2_pcrlock, tpm2_pubkey_pcrs, tpm2_pubkey_ref}))}'
```

Confirm that the new TPM token has a different token ID and keyslot, and
requires `tpm2_pcrlock`, `tpm2_pubkey_pcrs: [11]`, and
`tpm2_pubkey_ref: "luks-root"`. Keep slot 0. If there is no new token, stop.

Remove only the old token metadata. Its keyslot remains for reversible
rollback until the boot tests pass. The new token is now the only automatic
unlock path. This command assumes the old token is still ID 0.

```sh
sudo cryptsetup token remove --token-id 0 /dev/nvme0n1p2
just tpm-unlock-check --trial
```

## Test

Boot the normal Hardened entry once. Confirm automatic unlock, then run:

```sh
efibootmgr | rg 'BootCurrent|BootOrder'
just tpm-nvpcr-check
just tpm-unlock-check --trial
systemctl --failed --no-pager
```

The image check verifies all four maintained UKIs without booting each one.
The token check verifies header metadata. The main boot proves that the
combined token can unlock the root volume.

For a refusal test, make a copy of the main UKI without the `luks-root`
approval. The helper keeps the `initrd` approval and the measured sections.
Re-sign the modified image for Secure Boot, then check the new signature. The
unsigned intermediate file remains on the encrypted root file system.

```sh
sudo python3 -m scripts.tpm_negative_uki \
  /boot/EFI/Linux/arch-linux-hardened.efi \
  /var/lib/dotfiles/tpm-root/no-root-approval.unsigned.efi
sudo sbsign --key /var/lib/sbctl/keys/db/db.key \
  --cert /var/lib/sbctl/keys/db/db.pem \
  --output /boot/EFI/Linux/arch-linux-hardened-no-root-approval.efi \
  /var/lib/dotfiles/tpm-root/no-root-approval.unsigned.efi
sudo sbverify --cert /var/lib/sbctl/keys/db/db.pem \
  /boot/EFI/Linux/arch-linux-hardened-no-root-approval.efi
sudo efibootmgr --create-only --disk /dev/nvme0n1 --part 1 \
  --label 'Arch Root Policy Refusal Test' \
  --loader '\EFI\Linux\arch-linux-hardened-no-root-approval.efi'
sudo efibootmgr
```

Read the new EFI entry number. Set it for one boot with
`sudo efibootmgr --bootnext NNNN`. The test must request the disk passphrase.
Enter it and check the boot journal for the TPM policy failure. If it unlocks
automatically, stop: another automatic path still exists. The normal boot
order must stay unchanged.

After the refusal test, remove only that test entry and UKI, using its actual
entry number. Boot the normal Hardened entry again if needed. Keep the
passphrase available.

```sh
sudo efibootmgr -b NNNN -B
sudo rm -- /boot/EFI/Linux/arch-linux-hardened-no-root-approval.efi
sudo rm -- /var/lib/dotfiles/tpm-root/no-root-approval.unsigned.efi
just tpm-nvpcr-check
just tpm-unlock-check --trial
```

## Finish

When both tests pass, remove only the old, unbound TPM keyslot. This host used
slot 1. Confirm the slot number again before running the command. Do not use a
type-wide `--wipe-slot=tpm2` operation.

```sh
sudo cryptsetup luksDump /dev/nvme0n1p2
sudo cryptsetup luksKillSlot /dev/nvme0n1p2 1
just tpm-unlock-check
sudo cryptsetup open --test-passphrase --key-slot 0 /dev/nvme0n1p2
sudo cryptsetup luksHeaderBackup /dev/nvme0n1p2 \
  --header-backup-file /var/lib/dotfiles/tpm-root/final.header
sudo mkinitcpio -P
just tpm-nvpcr-check
```

On a later approved reboot, confirm normal automatic unlock. Keep the final
header backup and the passphrase. Remove the pre-migration backup and token
export only after that boot succeeds.

## Recovery

If automatic unlock fails, use the disk passphrase. During the trial, restore
the old token if needed, after checking that token ID 0 is free. This restores
the previous, weaker automatic unlock policy. The old keyslot must still exist.

```sh
sudo cryptsetup token import --token-id 0 \
  --json-file /var/lib/dotfiles/tpm-root/old-token.json /dev/nvme0n1p2
```

If the LUKS header is damaged, use the saved header and passphrase from an
external recovery system. Header restore replaces all current token and
keyslot changes; do not use it for an ordinary policy failure. Do not clear
the TPM or its NV indices.

For an intended Secure Boot change, review the PCR 7 prediction before
updating its policy. See [systemd-pcrlock](https://man.archlinux.org/man/systemd-pcrlock.8.en),
[systemd-cryptenroll](https://man.archlinux.org/man/systemd-cryptenroll.1.en),
and [cryptsetup-token](https://man.archlinux.org/man/cryptsetup-token.8.en).

## Add the GPT partition policy

The current root token already requires the pcrlock policy and signed PCR 11.
This change adds PCR 5 to the existing pcrlock policy. PCR 5 covers the disk
partition table. It does not bind file contents, the whole disk, or a kernel
version. Do not enroll a new LUKS token or remove the disk passphrase.

Run this once on Halley2, outside aibox. Keep the disk passphrase and pcrlock
recovery PIN available. Stop if a check fails. Confirm that `/dev/nvme0n1` is
the disk that contains the root volume. Do not reboot during these steps.

```sh
sudo cryptsetup open --test-passphrase --key-slot 0 /dev/nvme0n1p2
sudo /usr/lib/systemd/systemd-pcrlock --strict=yes --pcr=7 --location=770 predict
sudo test ! -e /var/lib/pcrlock.d/600-gpt.pcrlock.d/generated.pcrlock
sudo test ! -e /var/lib/dotfiles/tpm-gpt/pcr7-policy.json
sudo install -d -m 0700 /var/lib/dotfiles/tpm-gpt
sudo cp /var/lib/systemd/pcrlock.json /var/lib/dotfiles/tpm-gpt/pcr7-policy.json
sudo cp /etc/systemd/system/systemd-pcrlock-make-policy.service.d/pcr7.conf \
  /var/lib/dotfiles/tpm-gpt/pcr7.conf
sudo /usr/lib/systemd/systemd-pcrlock lock-gpt /dev/nvme0n1
sudo /usr/lib/systemd/systemd-pcrlock --strict=yes --pcr=5 --pcr=7 \
  --location=770 predict
just apply
sudo /usr/lib/systemd/systemd-pcrlock make-policy \
  --strict=yes --pcr=5 --pcr=7 --location=770
sudo jq -e --slurpfile old /var/lib/dotfiles/tpm-gpt/pcr7-policy.json \
  '.nvIndex == $old[0].nvIndex and .nvHandle == $old[0].nvHandle' \
  /var/lib/systemd/pcrlock.json >/dev/null
just tpm-nvpcr-check
just tpm-unlock-check
```

The GPT command writes
`/var/lib/pcrlock.d/600-gpt.pcrlock.d/generated.pcrlock`. Stop and inspect
that file if it already exists. `just apply` installs the service override.
The `jq` check confirms that the existing TPM NV index is still in use.
The new checker requires both PCRs in the stored policy, a matching EFI boot
credential, and a strict prediction. Keep the backup on encrypted root storage.
The first normal reboot is the test of automatic unlock; do it only when you
are ready to enter the disk passphrase if TPM unlock fails. After that boot,
run both checks again and check `systemctl --failed`.

If a planned partition change makes PCR 5 differ, use the disk passphrase to
boot. Review the new layout before you approve it. Then run `lock-gpt` again,
run the strict PCR 5+7 prediction, and update the policy with `make-policy`.
The pcrlock recovery PIN can authorize the update when the old policy no
longer matches. Do not approve an unexpected partition change.

If the new policy blocks automatic unlock, use the disk passphrase. To return
to the saved PCR 7 policy, restore the old service override and update the
TPM policy. `--force` also rewrites the EFI credential when the prediction
equals an earlier policy. Do not copy the old JSON directly over the active
policy: the TPM NV index must be updated too.

```sh
sudo install -m 0644 /var/lib/dotfiles/tpm-gpt/pcr7.conf \
  /etc/systemd/system/systemd-pcrlock-make-policy.service.d/pcr7.conf
sudo systemctl daemon-reload
sudo /usr/lib/systemd/systemd-pcrlock make-policy --force \
  --recovery-pin=query --strict=yes --pcr=7 --location=770
sudo /usr/lib/systemd/systemd-pcrlock --strict=yes --pcr=7 --location=770 predict
```

The repo checker will then fail until you restore the PCR 5 setup. Do not
delete the saved policy or recovery PIN. The EFI boot test and root token
checks remain necessary because an offline prediction cannot prove unlock.
