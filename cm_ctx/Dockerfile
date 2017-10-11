FROM centos
MAINTAINER nagaraju@us.ibm.com
ENV INFORMIXDIR /opt/ibm/informix/
ENV LD_LIBRARY_PATH /lib64
RUN mkdir /opt/ibm/  &&  mkdir /opt/ibm/informix
#VOLUME ["/opt/ibm/informix/", "/opt/ibm/data/"]
#VOLUME ["/opt/ibm/data/"]
RUN yum -y update && yum -y install libaio sysstat libgcc libstdc compat-libstdc++-33 gcc kernel-headers kernel-devel net-tools.x86_64
RUN /usr/sbin/groupadd -g 102 -f informix
RUN ["/usr/sbin/useradd", "-m", "-g 102", "-u 200", "informix"]
RUN /bin/bash -c 'echo "informix:changeme" | /usr/sbin/chpasswd'
ADD clientsdk.4.10.tar /opt/ibm/informix/
#ADD bundle.properties /tmp/bundle.properties
ADD response.txt /tmp/response.txt
RUN /opt/ibm/informix/installclientsdk  -i SILENT -f /tmp/response.txt
#RUN /bin/bash -c 'chown informix:informix /opt/ibm/data/'
#RUN /bin/bash -c '/bin/rm -rf /opt/ibm/informix/ids_install /opt/ibm/informix/IBM_Data_Server_Driver_Package /opt/ibm/informix/CSDK /opt/ibm/informix/ICONNECT /opt/ibm/informix/JDBC /opt/ibm/informix/SDK /opt/ibm/informix/SERVER'

USER informix
ADD cmsm_demo.cfg /opt/ibm/informix/etc/
ADD sla_connect /opt/ibm/
ADD sla_connect.ec /opt/ibm/
ADD clientV1.sh /opt/ibm/
ADD clientV2.sh /opt/ibm/
ADD upd_sla.sh /opt/ibm/

USER root

WORKDIR /opt/ibm
ENTRYPOINT ["/opt/ibm/boot.sh"]
CMD ["--start cm1"]
EXPOSE 50000
EXPOSE 50001
EXPOSE 50002
EXPOSE 50003
EXPOSE 50004
EXPOSE 50005
EXPOSE 50006
EXPOSE 50007
ADD boot.sh /opt/ibm/
