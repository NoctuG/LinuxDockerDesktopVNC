#!/bin/bash

# Ensure the VNC password directory exists
mkdir -p $HOME/.vnc

# Set the VNC password
echo $USER_PASSWORD | vncpasswd -f > $HOME/.vnc/passwd

# Start VNC server
vncserver :0 -geometry 1360x768 -depth 24 -localhost no &

# Start noVNC
/noVNC/utils/novnc_proxy  --vnc localhost:2000 --listen 8900
