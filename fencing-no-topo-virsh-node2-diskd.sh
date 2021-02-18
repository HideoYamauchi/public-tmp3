#!/bin/sh
pcs property set priority-fencing-delay=10s
pcs stonith create fence1-virsh fence_virsh \
    pcmk_reboot_action="reboot" pcmk_host_list="rh83-dev01" ip="192.168.122.1" username="root" password="rena1014" power_wait="3" \
    op start timeout=60s on-fail=restart \
    monitor timeout=60s interval=3600s on-fail=restart \
    stop timeout=60s on-fail=ignore

pcs stonith create fence2-virsh fence_virsh \
    pcmk_reboot_action="reboot" pcmk_host_list="rh83-dev02" ip="192.168.122.1" username="root" password="rena1014" power_wait="3" \
    op start timeout=60s on-fail=restart \
    monitor timeout=60s interval=3600s on-fail=restart \
    stop timeout=60s on-fail=ignore


pcs resource create dummy-1 ocf:heartbeat:Dummy \
--group dummy-group \
op start timeout=60s on-fail=restart \
monitor timeout=60s interval=10s on-fail=restart \
stop timeout=60s on-fail=fence

pcs resource create prmdiskd ocf:pacemaker:diskd \
                name="diskcheck_status" \
		device="/dev/vda" \
		options="-e" \
		interval="10" \
		dampen="2" clone \
op start timeout=60s on-fail=restart \
monitor timeout=60s interval=10s on-fail=restart \
stop timeout=60s on-fail=ignore

pcs constraint location fence1-virsh avoids rh83-dev01
pcs constraint location fence2-virsh avoids rh83-dev02
pcs constraint location dummy-group prefers rh83-dev01=200
pcs constraint location dummy-group prefers rh83-dev02=100
pcs constraint location dummy-group rule score=-INFINITY diskcheck_status ne normal or not_defined diskcheck_status

pcs constraint order prmdiskd-clone then dummy-group symmetrical=false

pcs constraint colocation add dummy-group with prmdiskd-clone score=INFINITY

pcs resource defaults migration-threshold=1

pcs resource defaults resource-stickiness=200

pcs resource meta dummy-group priority=10
