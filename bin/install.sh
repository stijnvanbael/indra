#!/usr/bin/env bash
cd indra || true
cd bin || true

sudo ln indra.sh /usr/local/bin/indra
sudo ln indra-daemon.sh /usr/local/bin/indra-daemon

cd ..
pub get
