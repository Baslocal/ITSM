# ITSM - osTicket Lab Installation Script

This repository contains `os_ticketing.sh`, a script that automates the installation of osTicket with LAMP stack on Ubuntu 22.04 for educational purposes in a lab environment.

## :warning: WARNING: EDUCATIONAL USE ONLY

This script is intended for use in a controlled lab environment only. It uses reduced security measures and should NOT be used in production.

## Features

- Automated installation of osTicket and LAMP stack
- Two installation options: Custom and Default
- Basic logging for troubleshooting
- Cleanup option to reset the lab environment

## Prerequisites

- Ubuntu 22.04 server
- Root or sudo access

## Usage

1. Clone this repository:
   ```
   git clone https://github.com/Baslocal/ITSM.git
   cd ITSM
   ```

2. Make the script executable:
   ```
   chmod +x os_ticketing.sh
   ```

3. Run the script with sudo:
   ```
   sudo ./os_ticketing.sh
   ```

4. Follow the on-screen prompts to complete the installation.

5. To clean up the installation later, run:
   ```
   sudo ./os_ticketing.sh --cleanup
   ```

## Default Credentials

If you choose the default installation option, the following credentials will be used:

- osTicket Database User: osticket
- osTicket Database Password: LabPassword123!
- System User: osticket
- System User Password: LabPassword123!

Make sure to change these passwords in a real-world scenario.

## Logging

The script creates a log file `osticket_install.log` in the same directory, which can be useful for troubleshooting.

## Customization

You can modify the script to add more features or change default settings as needed for your lab environment.
