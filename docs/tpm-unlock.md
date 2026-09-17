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
