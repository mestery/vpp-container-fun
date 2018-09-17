FROM vpp-container-fun/base

COPY startvpp.sh /
COPY startup1.conf /etc/vpp/startup1.conf
COPY startup2.conf /etc/vpp/startup2.conf
COPY config1.txt /etc/vpp/config1.txt
COPY config2.txt /etc/vpp/config2.txt

ENTRYPOINT /startvpp.sh
