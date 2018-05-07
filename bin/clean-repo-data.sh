#!/bin/bash
function usage
{
    cat <<EOF

Usage ${0##*/} --dry-run 

run with --dry-run to echo the found file information

   ${0} --dry-run

EOF
    exit 1
}

cat <<EOF
make a backup before running this script
    rsync -rla .git/ .git.backup/

dry run to see the edits that will be made

*Note* 

The sed command used to edit uses commas "," as the argument separator

You can't use a filter (search text) or replace (replacement text)
with a comma

For example the hash map HM text example like would work to replace 

declare -A HM=(
    ['"user@email.com"']='"user_id@example.com"'
    ['"abc123"']='"password"'
)


     filter "user@email.com" with "user_id@example.com"

However a comma in filter or replacement will break the edit

    ['"abc,123"']='"password"'

EOF
usage

echo Exiting please backup before using and test
exit 1

unset DO


for arg in "${@}"; do
    case "${arg}" in
        --dry-run) DO=echo;;
        --help) usage;;
    esac
done

 
declare -A HM=(
    ['"user@email.com"']='"user_id@example.com"'
    ['"abc123"']='"password"'
)

for filter in "${!HM[@]}"; do
    replace="${HM[${filter}]}"
    printf "Find files with [%-32.32s] replace it with [%-32.32s]\n" "${filter}" "${replace}"
    for filename in $(git find-grep "${filter}" | cut -f 2 -d : | sort -u); do
        echo "Found filename ${filename} with text [${filter}] replacing with [${replace}]"
        cat <<EOF
git filter-branch -f --tree-filter "test -f ${filename} && sed -i 's,${filter},${replace},g' ${filename}  || echo 'skipping filename ${filename}'" -- --all
EOF
        ${DO} git filter-branch -f --tree-filter "test -f ${filename} && sed -i 's,${filter},${replace},g' ${filename}  || echo 'skipping filename ${filename}'" -- --all
    done
done

