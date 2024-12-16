Ubuntu Setup Script:

This script is designed to automate the setup of your Ubuntu system, installing essential applications, configuring Proton VPN, setting up security with UFW, and optimizing the system for both productivity and gaming.

Features
Install Essential Tools: Development libraries, media players, web browsers, gaming platforms (Steam, Wine), and more.
Set up Proton VPN: Secure your internet connection with Proton VPN.
Install Flatpak & Snap Apps: Includes the installation of Shiftey Desktop (Flatpak) and SPT (Snap).
Configure UFW (Uncomplicated Firewall): Enable UFW to protect your system.
Remove Unnecessary Packages: Automatically clean up unneeded dependencies after installation.
System Requirements
Ubuntu 20.04 or later (this script is optimized for recent versions of Ubuntu)
Internet connection for downloading and installing packages
Installation Instructions
Download the Script

Save the script file (e.g., ubuntu-setup.sh) to your system.

Make the Script Executable

Open a terminal and navigate to the directory where the script is saved. Run the following command to make the script executable:

bash
Copy code
chmod +x ubuntu-setup.sh
Run the Script

Execute the script with sudo to allow the installation of packages and system changes:

bash
Copy code
sudo ./ubuntu-setup.sh
The script will automatically:

Update and upgrade your system.
Install apt-fast for faster downloads.
Install essential apps like Git, VLC, Steam, VirtualBox, Nextcloud, and more.
Set up Proton VPN and other tools.
Install Flatpak and Snap apps.
Enable UFW firewall for system security.
Clean up unused packages after installation.
Post-Installation Setup

Once the script completes, you can start Proton VPN by searching for it in the application menu and logging in with your Proton VPN account.

Optional: Access Proton Drive

Proton Drive can be accessed via the web at:
https://drive.protonmail.com

Uninstallation
To remove any installed packages or configurations, you can manually uninstall the apps using apt-get remove, flatpak uninstall, or snap remove as needed. Additionally, if you no longer want Proton VPN, you can remove it with:

bash
Copy code
sudo apt-get purge protonvpn
Notes
The script installs Proton VPN from the stable repository, ensuring you're getting a stable version.
The Shiftey Desktop (Flatpak) and SPT (Snap) are installed automatically as part of the script. If you don't need these apps, you can easily remove them after running the script.
Customizations
Feel free to modify the script according to your needs. You can add or remove specific software packages, change repository configurations, or adjust the firewall rules to suit your preferences.

License
This script is released under the MIT License. Feel free to modify and distribute it as needed.

Contributing
If you have suggestions for improvements or additional tools to include in the script, feel free to fork this repository and submit a pull request. Contributions are always welcome!

Contact
For questions or feedback, feel free to reach out to me
