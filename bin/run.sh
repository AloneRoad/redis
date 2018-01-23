#!/usr/bin/env bash

#$1 - file; $2 - variable; $3 - value; 
Configure() {
    CONFIG_FILE="$1"
    VAR="$2" 
    VAL="$3"

    if [[ "$VAL" != "" ]]; then
        CONFIG_LINE="$VAR $VAL"
        sed -e "s/\(^#*\ *$VAR \(.*\)$\)/$CONFIG_LINE/g" $CONFIG_FILE > /tmp/config.tmp && mv -f /tmp/config.tmp $CONFIG_FILE

        grep "^$CONFIG_LINE" $CONFIG_FILE

        if [ $? -ne 0 ]; then
            echo "$VAR $VAL" >> $CONFIG_FILE
        fi
    fi
}

CONF="/redis/config/config.conf"

if [ -n "$SENTINEL" ]; then
    cp /redis/config/sentinel.conf $CONF

    if [[ "$MASTER_IP" == "" ]]; then
        echo ">>> You need to set redis MASTER_IP for sentinel!"
        exit 1
    fi

    dockerize -wait tcp://$MASTER_IP:$MASTER_PORT

    Configure $CONF 'sentinel monitor' "$MASTER_NAME $MASTER_IP $MASTER_PORT $QUORUM"
    Configure $CONF 'port' "$SENTINEL_PORT"
    Configure $CONF 'sentinel announce-ip' "$ANNOUNCE_IP"
    Configure $CONF 'sentinel announce-port' "$SENTINEL_PORT" 
    Configure $CONF 'sentinel down-after-milliseconds' "$MASTER_NAME 30000"
    Configure $CONF 'sentinel parallel-syncs' "$MASTER_NAME 1"
    Configure $CONF 'sentinel failover-timeout' "$MASTER_NAME 180000"
    CMD='redis-sentinel'
    
else
    cp /redis/config/redis.conf $CONF

    if [[ "$ANNOUNCE_IP" == "" ]]; then
        echo ">>> You need to set ANNOUNCE_IP for redis container"
        exit 1
    fi

    Configure $CONF 'port' "$REDIS_PORT"
    Configure $CONF 'slave-announce-ip' "$ANNOUNCE_IP"
    Configure $CONF 'slave-announce-port' "$REDIS_PORT"
    
    if [ -z "$MASTER" ]; then
        if [[ "$MASTER_ADDRESS" == "" ]]; then
            echo ">>> You need to set MASTER_ADDRESS for slave!"
            exit 1
        fi

        Configure $CONF 'slaveof' "$MASTER_ADDRESS $MASTER_PORT"
    fi
    CMD='redis-server'
fi


echo ">>> Configuring file $CONF"
IFS=';' read -ra CONFIG_PAIRS <<< "$CONFIGS"
for CONFIG_PAIR in "${CONFIG_PAIRS[@]}"
do
    IFS='=' read -ra CONFIG <<< "$CONFIG_PAIR"
    VAR="${CONFIG[0]}"
    VAL="${CONFIG[1]}"
    Configure $CONF "$VAR" "$VAL"
done

if [ -n "$DEBUG" ]; then
    echo ">>> Result config file"
    cat $CONF
fi
$CMD $CONF
