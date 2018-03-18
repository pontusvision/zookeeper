#!/bin/bash

DIR="$( cd "$(dirname "$0")" ; pwd -P )"
VERSION=3.4.6
DISTDIR="$DIR/../pontus-dist/opt/pontus/pontus-zookeeper";
TARFILE=$DIR/build/zookeeper-${VERSION}.tar.gz

CURDIR=`pwd`
cd $DIR

echo DIR is $DIR
echo TARFILE is $TARFILE

if [[ ! -f $TARFILE ]]; then
  ant -Dpackage.prefix=/opt/pontus/pontus-zookeeper tar
fi

if [[ ! -d $DISTDIR ]]; then
  mkdir -p $DISTDIR
fi

cd $DISTDIR
rm -rf *
tar xvfz $TARFILE
ln -s zookeeper-$VERSION current
cd current/bin

cat <<'EOF' >> zookeeper.service
[Unit]
Description=Apache Zookeeper
Documentation=http://zookeeper.apache.org/documentation
After=network-online.target zookeeper.service
Wants=network-online.target

[Service]
User=zookeeper
ExecStart=/opt/pontus/pontus-zookeeper/current/bin/zookeeper-server start-foreground
LimitNOFILE=infinity
TimeoutStartSec=0
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s

[Install]
WantedBy=multi-user.target
EOF



cat << 'EOF' >> zookeeper-server
#!/bin/bash

export ZOOPIDFILE=${ZOOPIDFILE:-/var/run/zookeeper/zookeeper_server.pid}
export ZOOKEEPER_HOME=${ZOOKEEPER_HOME:-/opt/pontus/pontus-zookeeper/current}
export ZOOKEEPER_CONF=${ZOOKEEPER_HOME}/conf
export ZOOCFGDIR=${ZOOCFGDIR:-$ZOOKEEPER_CONF}
export CLASSPATH=$CLASSPATH:$ZOOKEEPER_CONF:$ZOOKEEPER_HOME/*:$ZOOKEEPER_HOME/lib/*
export ZOO_LOG_DIR=${ZOO_LOG_DIR:-/var/log/zookeeper}
export ZOO_LOG4J_PROP=${ZOO_LOG4J_PROP:-INFO,ROLLINGFILE}
export JVMFLAGS=${JVMFLAGS:--Dzookeeper.log.threshold=INFO}
export ZOO_DATADIR_AUTOCREATE_DISABLE=${ZOO_DATADIR_AUTOCREATE_DISABLE:-true}
env CLASSPATH=$CLASSPATH ${ZOOKEEPER_HOME}/bin/zkServer.sh "$@"
EOF

chmod 755 zookeeper.service zookeeper-server

cd $CURDIR
