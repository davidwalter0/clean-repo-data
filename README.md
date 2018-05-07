##### clean-repo-data

*Example secret clean-repo-data*

**Make a backup of any repo you are about to edit**

- References:
  - `https://stackoverflow.com/questions/1338728/delete-commits-from-a-branch-in-git`
  - `https://help.github.com/articles/removing-sensitive-data-from-a-repository/`

Remove a file:

```
    export file=file-to-remove
    echo ${file} >> .gitignore
    git add .gitignore
    git commit -m 'remove file permanently'

    export filepath=path/to/file

    git filter-branch --force --index-filter \
        "git rm --cached --ignore-unmatch ${filepath}" \
            --prune-empty --tag-name-filter cat -- --all

```

Filter and replace with backup ( but then you may end up having to
remove .orig files as sed -i.orig creates a backup )

```
    export filename=src/environments/environment.ts
    export filter=secret-to-replace
    export replace=example2.com
    git filter-branch -f --tree-filter 'test -f ${filename} && sed -i.orig "s,${filter},${replace},g" ${filename}  || echo "skipping file ${filename}"' -- --all
```

Filter and replace without creating a backup file.

```
    export filename=src/environments/environment.ts
    export filter=secret-to-replace
    export replace=example2.com
    git filter-branch -f --tree-filter 'test -f ${filename} && sed -i "s,${filter},${replace},g" ${filename}  || echo "skipping file ${filename}"' -- --all
```

Make multiple replacements using the hash map definition of key,values
- filter: Keys are filters (search text)      `${filter}`
- replace: Values are replacement text entries `${replace}`
- filename: is found by git search for filter `${filter}`

```
#!/bin/bash
function usage
{
    cat <<EOF

Usage ${0##*/} --dry-run 

run with --dry-run to echo the found file information

   ${0} --dry-run

EOF


cat <<EOF
make a backup before running this script
    rsync -rla .git/ .git.backup/

dry run to see the edits that will be made

*Note* 

The sed "s" command ["s,${filter},${replace},g"] used to edit uses
commas "," as the argument separator, so arguments can't include a
comma, but can use "/" path separators.

You can't use a filter (search text) or replace (replacement text)
with a comma

For example the hash map HM text example like would work to replace 

declare -A HM=(
#     key / filter         value / replacement
    ['"user@email.com"']='"user_id@example.com"'
    ['"abc123"']='"password"'
)


     filter "user@email.com" with "user_id@example.com"

However a comma in filter or replacement will break the edit

    ['"abc,123"']='"password"'

EOF

    exit 1
}

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
        if [[ ${filename##*/} == ${0##*/} ]]; then
            printf "\nIgnore this cleanup script ${filename##*/}. Continuing...\n\n"
            continue
        fi
        echo "Found filename ${filename} with text [${filter}] replacing with [${replace}]"
        cat <<EOF
git filter-branch -f --tree-filter "test -f ${filename} && sed -i 's,${filter},${replace},g' ${filename}  || echo 'skipping filename ${filename}'" -- --all
EOF
        ${DO} git filter-branch -f --tree-filter "test -f ${filename} && sed -i 's,${filter},${replace},g' ${filename}  || echo 'skipping filename ${filename}'" -- --all
    done
done


```
