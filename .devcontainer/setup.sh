#!/bin/bash

ProjectDir="$(pwd)"
declare -gr ProjectDir
DevContainerDir="${ProjectDir}/.devcontainer"
declare -gr DevContainerDir
declare -gr HistoryDir="${HOME}/.history"

declare -gr PyEnvVersion='2.4.20'


install_completions() {
  echo >> "${HOME}/.bashrc"
  echo "source '/usr/share/bash-completion/completions/git'" >> "${HOME}/.bashrc"
}

install_pyenv() {
  mkdir -p "${HOME}/.python"

  pushd /tmp || exit 1
  if [ ! -d "${HOME}/.python/pyenv" ]; then
    curl --location \
         --remote-name \
         --retry 5 \
         --retry-all-errors \
         --show-error \
         --silent \
         "https://github.com/pyenv/pyenv/archive/refs/tags/v${PyEnvVersion}.tar.gz"
    tar xzf "v${PyEnvVersion}.tar.gz"
    rm v${PyEnvVersion}.tar.gz
    mv "pyenv-${PyEnvVersion}" "${HOME}/.python/pyenv" 
  fi
  popd || exit 1

  echo '# pyenv' >> "${HOME}/.bashrc"
  echo 'export PYENV_ROOT=${HOME}/.python/pyenv' >> "${HOME}/.bashrc"
  echo 'export PATH=${PYENV_ROOT}/bin:${PATH}' >> "${HOME}/.bashrc"
  echo 'eval "$(pyenv init -)"' >> "${HOME}/.bashrc"
}

maybe_install_python() {
  local -r workspace_path="$1"
  local version=''

  if [ -f "${workspace_path}/.python-version" ]; then
    version="$(cat "${workspace_path}/.python-version")"
    PYENV_ROOT="${HOME}/.python/pyenv" PATH="${PYENV_ROOT}/bin:${PATH}" pyenv install --skip-existing "$version"
  fi
}

install_python_libraries() {
  local -r workspace_path="$1"
  local version=''

  if [ -f "${workspace_path}/.python-version" ]; then
    version="$(cat "${workspace_path}/.python-version")"
    PATH="${HOME}/.python/pyenv/versions/${version}/bin:${PATH}" pip install -r "${workspace_path}/requirements.txt"
  else
    pip install -r "${workspace_path}/requirements.txt"
  fi
}

setup_python_environment() {
  local -r workspace_path="$1"

  install_pyenv
  maybe_install_python "$workspace_path"
  install_python_libraries "$workspace_path"
}

after_create() {
  local -r workspace_path="$1"

  install_completions
  setup_python_environment "$workspace_path"
}

workspace_setup() {
  local -r workspace_path="$1"

  git config --global --unset-all safe.directory "$workspace_path" || true
  git config --global --add safe.directory "$workspace_path"
  git config --global --unset-all gpg.program || true
}

history_setup() {
  local -r name="$1"
  local -r history_path="${HistoryDir}/${name}"

  mkdir -p "$HistoryDir"
  touch "$history_path"
  ln -sf "$history_path" "${HOME}/.bash_history"
}

project_name() {
  git -C "$1" remote get-url origin | sed 's|^.*/\([^.]*\).git$|\1|g'
}

after_start() {
  local -r workspace_path="$1"

  workspace_setup "$workspace_path"
  history_setup "$(project_name "$workspace_name")"
}

after_attach() {
  local -r workspace_path="$1"

  ssh -T git@github.com 2>&1 | grep -e "^Hi [-_A-Za-z0-9]*! You've successfully authenticated, but GitHub does not provide shell access.$" -
}

run() {
  local -r stage="$1"

  case "$stage" in
    'CREATE')
      after_create "$ProjectDir"
      ;;
    'START')
      after_start "$ProjectDir"
      ;;
    'ATTACH')
      after_attach "$ProjectDir"
      ;;
  esac
}

main() {
  local output_file
  output_file="${ProjectDir}/log/devcontainer_${1}_$(date +'%Y-%m-%d_%H-%M-%S').txt"
  mkdir -p "${ProjectDir}/log"
  run "$@" 2>&1 | tee -a "$output_file"
}

main "$@"
