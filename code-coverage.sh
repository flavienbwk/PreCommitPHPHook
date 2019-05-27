#!/bin/bash

# Pre-commit PHP checks hook for git repositories,
# using the most known libraries for PHP checks.
# /!\ JUST PUT THIS SCRIPT UNDER .git/hooks/pre-commit (file without extension) /!\

# Constants

log_path_dir=".pre-commit"
log_path_error="$log_path_dir/code_coverage.sh.error.log"
log_path_info="$log_path_dir/code_coverage.sh.info.log"
target_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/../.."
me_path=$(dirname "$me")
me=$(basename "$0")
analysis_results="$log_path_dir/$me.""$RANDOM""$RANDOM.txt"

phplint_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/../../vendor/bin/phplint"
phpcpd_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/../../vendor/bin/phpcpd"
phpcs_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/../../vendor/bin/phpcs"
phpmd_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )/../../vendor/bin/phpmd"

phplint_errors="0"
phplint_warnings="0"
phpcpd_errors="0"
phpcpd_warnings="0"
phpcs_errors="0"
phpcs_warnings="0"
phpmd_errors="0"
phpmd_warnings="0"

phplint_score="0"
phpcpd_score="0"
phpcs_score="0"
phpmd_score="0"

# Colors

RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[1;34m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
NC='\033[0m'

# Log functions

function setSuccessLog() {
    log_content="$(date) : $1"
    echo "$log_content" >> "$log_path_info"
    echo -e "${GREEN}$log_content${NC}"
}

function setWarningLog() {
    log_content="$(date) : $1"
    echo "$log_content" >> "$log_path_info"
    echo -e "${ORANGE}$log_content${NC}"
}

function setErrorLog() {
    log_content="$(date) : $1"
    echo "$log_content" >> "$log_path_error"
    echo -e "${RED}$log_content${NC}"
}

function setLog() {
    log_content="$(date) : $1"
    echo "$log_content" >> "$log_path_info"
    echo -e "${CYAN}$log_content${NC}"
}

# Program functions

compute_score()
{
    maximum="100"
    grade="$maximum"
    for c in "$@"
    do
        if [ "$grade" -gt "0" ]
        then
            if [ "$c" -gt  "$maximum" ]
            then
                grade=0
            else
                grade=$(($grade - $c))
            fi
        fi
    done
    echo "$grade"
}


# ===
# Beginning the program.
# ===


echo -e "${BLUE}Welcome to PreCommitPHPHook.${NC}"

if [ ! -d "$log_path_dir" ]
then
    mkdir "$log_path_dir"
fi

# Checking if this script is in a git repository
if [ "$(basename $(git rev-parse --git-dir))" != ".git" ]
then
    setErrorLog "Not in a git repository"
    exit 1
fi

## Loading dependencies

echo -e "\n${BLUE}Performing dependencies checks...${NC}"

if ! [ -x "$(command -v shellcheck)" ]
then
    setLog "Installing shellcheck..."
    if apt-get install shellcheck -y >> "${log_path_info}" 2> "${log_path_error}"
    then
        setLog "OK."
    else
        setErrorLog "Failed (try using sudo)."
        exit 1
    fi
fi

if ! [ -x "$(command -v composer)" ]
then
    setLog "Installing composer..."
    if apt-get install composer -y >> "${log_path_info}" 2> "${log_path_error}"
    then
        setLog "OK."
    else
        setErrorLog "Failed (try using sudo)."
        exit 1
    fi
fi

if [ ! -f "$phplint_path" ]
then
    setLog "Installing phplint..."
    if composer require overtrue/phplint --dev -vvv >> "${log_path_info}" 2> "${log_path_error}"
    then
        setLog "OK."
    else
        setErrorLog "Failed (try using sudo)."
        exit 1
    fi
fi

if [ ! -f "$phpcpd_path" ]
then
    setLog "Installing phpcpd..."
    if composer require --dev sebastian/phpcpd >> "${log_path_info}" 2> "${log_path_error}"
    then
        setLog "OK."
    else
        setErrorLog "Failed (try using sudo)."
        exit 1
    fi
fi

if [ ! -f "$phpcs_path" ]
then
    setLog "Installing php_codesniffer..."
    if composer require "squizlabs/php_codesniffer=*" >> "${log_path_info}" 2> "${log_path_error}"
    then
        setLog "OK."
    else
        setErrorLog "Failed (try using sudo)."
        exit 1
    fi
fi

if [ ! -f "$phpmd_path" ]
then
    setLog "Installing phpmd..."
    if composer require "phpmd/phpmd" >> "${log_path_info}" 2> "${log_path_error}"
    then
        setLog "OK."
    else
        setErrorLog "Failed (try using sudo)."
        exit 1
    fi
fi

## 2> "${log_path_error}" | tee "${log_path_info}" | visible but not forwarding errors from previous command
## >> "${log_path_info}" 2> "${log_path_error}"    | hidden

## Self checking current bash script
echo -e "\n${BLUE}Self checking this script...${NC}"
echo -e "[SHELLCHECK_START]" >> "${log_path_info}"
if shellcheck ".git/hooks/$me"
then
    echo -e "[SHELLCHECK_END]" >> "${log_path_info}"
    setSuccessLog "Perfect."
else
    echo -e "[SHELLCHECK_FAILED]" >> "${log_path_info}"
    setWarningLog "Some problems have been found."
fi

echo -e "\n${BLUE}PHP Lint checks...${NC}"
echo -e "[PHPLINT_START]" >> "${log_path_info}"
if "$phplint_path" "$target_path" -n --ansi --json="$log_path_dir/$me.phplint.json" --exclude="vendor" --no-configuration --no-cache > "$analysis_results"
then
    echo -e "[PHPLINT_END]" >> "${log_path_info}"
    setSuccessLog "Perfect."
else
    echo -e "[PHPLINT_FAILED]" >> "${log_path_info}"
    setWarningLog "Some problems have been found."
fi
cat "$analysis_results"
phplint_errors=$(grep Files < $analysis_results | sed 's/,/\n/g' | grep Failures | sed 's/:/\n/g' | grep -Eo '[0-9]{1,}' | head -n 1 | awk 'END{print NR?$0:"0"}')
phplint_score=$((phplint_errors))

echo -e "\n${BLUE}PHPCPD checks...${NC}"
echo -e "[PHPCPD_START]" >> "${log_path_info}"
if "$phpcpd_path" --regexps-exclude="#vendor/*#" --fuzzy "$target_path" > "$analysis_results"
then
    echo -e "[PHPCPD_END]" >> "${log_path_info}"
    setSuccessLog "Perfect."
else
    echo -e "[PHPCPD_FAILED]" >> "${log_path_info}"
    setWarningLog "Some problems have been found."
fi
cat "$analysis_results"
phpcpd_errors=$(sed 's/ /\n/g' < $analysis_results | grep % | grep -Eo '[0-9]{1,}' | head -n 1 | awk 'END{print NR?$0:"0"}')
phpcpd_score=$(($phpcpd_errors / 2 + $phpcpd_warnings))

echo -e "\n${BLUE}PHPCS checks...${NC}"
echo -e "[PHPCS_START]" >> "${log_path_info}"
if "$phpcs_path" --ignore="vendor/" "$target_path" > "$analysis_results"
then
    echo -e "[PHPCS_END]" >> "${log_path_info}"
    setSuccessLog "Perfect."
else
    echo -e "[PHPCS_FAILED]" >> "${log_path_info}"
    setWarningLog "Some problems have been found."
fi
cat "$analysis_results"
phpcs_errors=$(grep \| < $analysis_results | grep -c ERROR)
phpcs_warnings=$(grep \| < $analysis_results | grep -c WARNING)
phpcs_score=$((($phpcs_errors) / 2 + ($phpcs_warnings) / 4))

echo -e "\n${BLUE}PHPMD checks...${NC}"
echo -e "[PHPMD_START]" >> "${log_path_info}"
if "$phpmd_path" . text codesize --exclude "vendor/*" > "$analysis_results"
then
    echo -e "[PHPMD_END]" >> "${log_path_info}"
    setSuccessLog "Perfect."
else
    echo -e "[PHPMD_FAILED]" >> "${log_path_info}"
    setWarningLog "Some problems have been found."
fi
cat "$analysis_results"
phpmd_errors=$(wc -l < "$analysis_results")
phpmd_score=$(($phpmd_errors + $phpmd_warnings))

overall_score=$(compute_score "$phplint_score" "$phpcpd_score" "$phpcs_score" "$phpmd_score")

rm "$analysis_results"
echo -e
if [ "$overall_score" -ge "80" ]
then
    setSuccessLog "Your score is $overall_score / 100"
elif [ "$overall_score" -ge "50" ]
then
    setWarningLog "Your score is $overall_score / 100"
    exit 1
else
    setErrorLog "Your score is $overall_score / 100"
    exit 1
fi
