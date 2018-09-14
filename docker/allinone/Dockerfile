FROM centos

COPY fdio.repo /etc/yum.repos.d/fdio-release.repo
COPY startvpp.sh /
COPY startup1.conf /etc/vpp/startup1.conf
COPY startup2.conf /etc/vpp/startup2.conf
COPY config1.txt /etc/vpp/config1.txt
COPY config2.txt /etc/vpp/config2.txt

RUN yum -y update; yum -y install sudo iproute vpp vpp-plugins vpp-api-python

ENTRYPOINT /startvpp.sh
#CMD /startvpp.sh
