FROM vpp-container-fun/base
MAINTAINER mestery@mestery.com

COPY startvpp.sh /
COPY startup1.conf /etc/vpp/startup1.conf
COPY startup2.conf /etc/vpp/startup2.conf

ENTRYPOINT /startvpp.sh
