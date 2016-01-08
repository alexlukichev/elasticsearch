#!/dumb-init /bin/bash

set -x

skydns_key=${ELASTICSEARCH_SKYDNS:-/local/skydns/elasticsearch}
local_address=${LOCAL_ADDRESS:-NOADDR}


hosts=()

while read idx _ value
do 
  v1=$(echo $value|sed 's/.*"host"\s*:\s*"\([^"]*\)".*/\1/')
  if [ $v1 != $local_address ]; then
    hosts+=($v1)
  fi
done < <(curl http://172.17.42.1:4001/v2/keys/skydns${skydns_key}?consistent=true 2>/dev/null | \
  /JSON.sh | \
  egrep '\["node","nodes",([^,]*),"(value)"\]' | \
  sed 's/\["node","nodes",\([^,]*\),"\(key\|value\)"\]\t"\(.*\)"/\1 \2 \3/')

hosts_str=$(IFS=","; echo "${hosts[*]}")
declare -p hosts_str
    
echo "Starting elasticsearch with master hosts: ${hosts_str}"    
    
exec /docker-entrypoint.sh --discovery.zen.ping.unicast.hosts=${hosts_str} $*
