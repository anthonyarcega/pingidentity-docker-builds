#!/usr/bin/env sh
#
# Ping Identity DevOps - Docker Build Hooks
#
${VERBOSE} && set -x

# shellcheck source=../../../../pingcommon/opt/staging/hooks/pingcommon.lib.sh
. "${HOOKS_DIR}/pingcommon.lib.sh"

# shellcheck source=../../../../pingdatacommon/opt/staging/hooks/pingdata.lib.sh
test -f "${HOOKS_DIR}/pingdata.lib.sh" && . "${HOOKS_DIR}/pingdata.lib.sh"

#
# If we are the GENESIS state, then process any templates if they are defined.
#
if test "${PD_STATE}" = "GENESIS" ;
then
    echo "PD_STATE is GENESIS ==> Processing Templates"

    # TODO need to process all ldif subdirectories, not just userRoot
    LDIF_DIR="${PD_PROFILE}/ldif/userRoot"
    TEMPLATE_DIR="${LDIF_DIR}"
    test -z "${MAKELDIF_USERS}" && MAKELDIF_USERS=0

    # FIXME: this will break for file names with whitespaces
    for template in $( find "${TEMPLATE_DIR}" -type f -iname \*.template 2>/dev/null ) ;
    do
            echo "Processing (${template}) template with ${MAKELDIF_USERS} users..."
            GENERATED_LDIF_FILENAME="${template%.*}.ldif"
            "${SERVER_ROOT_DIR}/bin/make-ldif" \
                --templateFile "${template}"  \
                --ldifFile "${GENERATED_LDIF_FILENAME}" \
                --numThreads 3
            
            # Add the generated ldif file to the profile's variables-ignore.txt file, to avoid
            # the potential memory overhead of variable substitution on a large file.
            GENERATED_LDIF_BASENAME=$( basename "${GENERATED_LDIF_FILENAME}" )
            echo "ldif/userRoot/${GENERATED_LDIF_BASENAME}" >> "${PD_PROFILE}/variables-ignore.txt"
    done
else
    echo "PD_STATE is not GENESIS ==> Skipping Templates"
    echo "PD_STATE is not GENESIS ==> Will not process ldif imports"

    # GDO-191 - Following is used by 183-run-setup.sh.  Appended to CONTAINER_ENV, to allow for that
    # hook to pick it up
    _skipImports="--skipImportLdif"

    # next line is for shellcheck disable to ensure $RUN_PLAN is used
    echo "${_skipImports}" >> /dev/null

    export_container_env _skipImports
fi