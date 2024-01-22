# Use the official Debian image as the base image
FROM debian:buster-slim as builder

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Update package list
# Install required packages
# Clean APT cache to reduce image size
RUN apt update && \
    apt install -y --no-install-recommends \
        wget \
        openssl \
        ca-certificates \
        git \
        xz-utils && \
    apt clean && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists/*


# Download and unzip noVNC
WORKDIR /root
RUN wget https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz && \
    tar -xvf v1.4.0.tar.gz && \
    mv noVNC-1.4.0 noVNC && \
    rm v1.4.0.tar.gz && \
    ls -alh /root/noVNC  # Add this line to list the contents of the /root/noVNC directory

# Cloning websockify
RUN git clone https://github.com/novnc/websockify /noVNC/utils/websockify

FROM debian:buster-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/user

# Create the /home/user directory
RUN mkdir -p $HOME

# Create .Xauthority
RUN touch $HOME/.Xauthority

# Copy and set permissions on the setup.sh script
COPY setup.sh /setup.sh
RUN chmod +x /setup.sh

# Copy necessary files from builder stage
COPY --from=builder /root/noVNC /noVNC
COPY --from=builder /noVNC/utils/websockify /noVNC/utils/websockify

# Verify the contents of the /noVNC directory
RUN ls -alh /noVNC

# Install required packages
RUN apt update && \
    apt install -y --no-install-recommends \
        python3 \
        wine \
        qemu-kvm \
        ttf-wqy-zenhei \
        dbus-x11 \
        curl \
        firefox-esr \
        gnome-system-monitor \
        mate-system-monitor \
        git \
        xfce4 \
        xfce4-terminal \
        tightvncserver \
        openssl \
        xfonts-base && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# Generate a random password and set it as VNC password
RUN /bin/bash -c "mkdir -p $HOME/.vnc && \
    RAND_PASSWD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c 12) && \
    echo $RAND_PASSWD | vncpasswd -f > $HOME/.vnc/passwd && \
    echo '/bin/env  MOZ_FAKE_NO_SANDBOX=1  dbus-launch xfce4-session'  > $HOME/.vnc/xstartup && \
    chmod 600 $HOME/.vnc/passwd && \
    chmod 755 $HOME/.vnc/xstartup && \
    echo \"VNC Password: $RAND_PASSWD\" > $HOME/.vnc/passwd.log"

#Create startup script
RUN /bin/bash -c "mkdir -p $HOME/.vnc && \
    RAND_PASSWD=$(dd if=/dev/urandom bs=1 count=1000 2>/dev/null | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1) && \
    echo $RAND_PASSWD | vncpasswd -f > $HOME/.vnc/passwd && \
    echo '/bin/env  MOZ_FAKE_NO_SANDBOX=1  dbus-launch xfce4-session'  > $HOME/.vnc/xstartup && \
    chmod 600 $HOME/.vnc/passwd && \
    chmod 755 $HOME/.vnc/xstartup && \
    echo \"VNC Password: $RAND_PASSWD\" > $HOME/.vnc/passwd.log"

# Check passw.log
RUN cat $HOME/.vnc/passwd.log

#Expose port
EXPOSE 8900

# Set the command to run when the container starts
CMD ["/setup.sh"]
