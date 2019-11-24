#!/bin/bash
# Copyright (C) 2019 baalajimaestro
#
# Licensed under the Raphielscape Public License, Version 1.b (the "License");
# you may not use this file except in compliance with the License.
#

GITHUB_TOKEN="06d0e9cc0bdcb7c7607fdcbcc0ea1e8328f8b1a2"
TELEGRAM_TOKEN="923829062:AAHAkKpoL-iAdDm6nmp4GPjKhjfxWkTMLPY"
TELEGRAM_CHAT="-1001158707255"

echo "***BuildBot***"
echo $TELEGRAM_TOKEN >/tmp/tg_token
echo $TELEGRAM_CHAT >/tmp/tg_chat
echo $GITHUB_TOKEN >/tmp/gh_token

sudo echo "ci ALL=(ALL) NOPASSWD: ALL" >>/etc/sudoers
useradd -m -d /home/ci ci
useradd -g ci wheel
sudo cp github-release /usr/bin
sudo cp telegram /usr/bin
sudo -Hu ci bash -c "bash build.sh"
