cd "$(dirname "$0")"

git clone https://github.com/travis-ci/travis-images.git || true

cd travis-images/templates

rm -rf ../../vm/templates
mkdir ../../vm/templates

echo '{ "dummy": "",' > travis.json
for t in *.yml; do
    python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' < $t > $t.json

    json=$(jq -e .json < $t.json)
    if [ $? -eq 0 ]; then
        printf '%s' "$json" > ../../vm/templates/$t.json
    fi

    runlist=$(jq -e -r '.recipes | join(",")' < $t.json)
    if [ $? -eq 0 ]; then
        printf '%s' "$runlist" > ../../vm/templates/$t.runlist
    fi

done

echo '}' >> ../../vm/$t.json
