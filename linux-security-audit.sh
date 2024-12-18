#!/bin/bash

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

aud_system() {
    echo "Starting Linux Security Audit..."

    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root to perform a full audit."
        exit 1
    fi

    echo "Checking for available updates..."
    if command_exists apt; then
        apt update >/dev/null 2>&1
        updates=$(apt list --upgradable 2>/dev/null | grep -c upgradable)
        echo "Updates available: $updates"
    elif command_exists yum; then
        updates=$(yum check-update 2>/dev/null | wc -l)
        echo "Updates available: $updates"
    else
        echo "Package manager not supported. Skipping updates check."
    fi

    echo "Checking firewall status..."
    if command_exists ufw; then
        ufw_status=$(ufw status | grep -i active | wc -l)
        if [ "$ufw_status" -eq 1 ]; then
            echo "Firewall is active."
        else
            echo "Firewall is not active."
        fi
    else
        echo "UFW not found. Skipping firewall check."
    fi

    echo "Checking SSH root login..."
    if [ -f /etc/ssh/sshd_config ]; then
        ssh_root=$(grep -i "^PermitRootLogin" /etc/ssh/sshd_config | awk '{print $2}')
        if [ "$ssh_root" = "yes" ]; then
            echo "Warning: SSH root login is enabled. Consider disabling it."
        else
            echo "SSH root login is disabled."
        fi
    else
        echo "SSH configuration file not found."
    fi

    echo "Checking password policy..."
    if [ -f /etc/login.defs ]; then
        min_len=$(grep -i PASS_MIN_LEN /etc/login.defs | awk '{print $2}')
        echo "Minimum password length: ${min_len:-Not set}"
    else
        echo "Password policy configuration not found."
    fi

    echo "Checking open ports..."
    if command_exists netstat; then
        echo "Open ports:" && netstat -tulpn | grep LISTEN
    elif command_exists ss; then
        echo "Open ports:" && ss -tulpn | grep LISTEN
    else
        echo "Netstat or SS not found. Skipping port check."
    fi

    echo "Audit complete. Please review the above recommendations."
}

if [ "$1" = "audit" ]; then
    aud_system
else
    echo "Usage: $0 audit"
fi
