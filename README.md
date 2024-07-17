# AcornAssociated helper scripts

## Installation of these scripts
Clone this repository in to `/var/www/` so they can be run with `scripts/acorn-*`.

## Installation of new laptops
There is an Acorn USB flash drive with KUbuntu installation on. Ask for it :)
- Insert the USB flash
- Change your BIOS settings to Boot From Flash drive
- Install KUbuntu:
  - **Set your username to your GitLab username**
  - Set your computer name as you wish
- Open a terminal (with Ctrl+Alt+T)
- `cd /media/\<username\>/\<USB Flash Drive Name\>`
- `bash acorn-setup-laptop-from-usb`
- Enjoy the show

## Server installation
Same as above, except run `acorn-setup-server-from-usb <gitlab website repository, e.g. office/data-entry-satcop>`.
This will then run `acorn-setup-laptop-from-usb` and additionally setup the website.

## Usage
`./acorn-setup-* [parameters]`

For example:
```
cd /var/www/
./acorn-setup-winter justice
```
will create a complete website with a database and domain name, and all our plugins, at http://justice.laptop.

## HOWTOS
More guides can be found in the `howtos` sub-directory.
