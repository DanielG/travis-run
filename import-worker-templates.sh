cd "$(dirname "$0")"

git clone https://github.com/travis-ci/travis-cookbooks.git || true

cd travis-cookbooks/vm_templates/common

rm ../../../vm/templates/*

for t in *.yml; do
    python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' < $t > $t.json

    json=$(jq -e .json < $t.json)
    if [ $? -eq 0 ]; then
        printf '%s' "$json" > ../../../vm/templates/$t.json
    fi

    runlist=$(jq -e -r '.recipes - ["sysctl"] | join(",")' < $t.json)
    if [ $? -eq 0 ]; then
        printf '%s' "$runlist" > ../../../vm/templates/$t.runlist
    fi

done
