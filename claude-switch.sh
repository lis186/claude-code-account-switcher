#!/usr/bin/env zsh
# ============================================================
# Claude Code Account Switcher (macOS / zsh)
# ============================================================
# Bind Claude Code accounts to specific directories.
#
# Install: add to ~/.zshrc:
#   source /path/to/claude-switch.sh
#
# Language: auto-detected from LANG, override with CLAUDE_ACC_LANG=en|ru
#
# Usage:
#   claude-acc                     — help
#   claude-acc list                — list accounts
#   claude-acc add <name>          — add account (opens login)
#   claude-acc remove <name>       — remove account
#   claude-acc default [name]      — show/set default account
#   claude-acc link <name>         — link account to current directory
#   claude-acc unlink              — unlink current directory
#   claude-acc status              — show active account
# ============================================================

CLAUDE_SWITCH_DIR="$HOME/.claude-switch"
CLAUDE_SWITCH_ACCOUNTS_DIR="$CLAUDE_SWITCH_DIR/accounts"
CLAUDE_SWITCH_CONFIG="$CLAUDE_SWITCH_DIR/config"
CLAUDE_SWITCH_LINKS="$CLAUDE_SWITCH_DIR/links"

# =============================================================
# Локализация / i18n
# =============================================================

_claude_acc_lang() {
    if [[ -n "$CLAUDE_ACC_LANG" ]]; then
        echo "$CLAUDE_ACC_LANG"
    elif [[ "$LANG" == ru_* ]]; then
        echo "ru"
    else
        echo "en"
    fi
}

typeset -gA _claude_msg_en _claude_msg_ru

_claude_msg_en=(
    help_title          "Claude Code Account Switcher"
    help_commands       "Commands:"
    help_list           "List accounts"
    help_add            "Add account"
    help_login          "Re-login to an account"
    help_remove         "Remove account"
    help_default        "Show/set default account"
    help_reset          "Reset default to ~/.claude/"
    help_link           "Link account to current directory"
    help_unlink         "Unlink current directory"
    help_links          "Show all directory links"
    help_status         "Current account and context"
    help_lock           "Pin current token identity as expected for account"
    help_doctor         "Audit all accounts for identity drift"
    help_help           "Help"
    list_empty          "No accounts. Add one: claude-acc add <name>"
    list_header         "Claude Code accounts:"
    list_default        "(default)"
    add_usage           "Usage: claude-acc add <name>"
    add_example         "Example: claude-acc add personal"
    add_exists          "Account '%s' already exists."
    add_created         "Account '%s' created. Starting login..."
    add_done            "Done. Use:"
    add_hint_default    "  claude-acc default %s   — set as default"
    add_hint_link       "  claude-acc link %s      — link to current directory"
    login_usage         "Usage: claude-acc login <name>"
    login_not_found     "Account '%s' not found."
    login_start         "Logging in to '%s'..."
    login_done          "Done."
    remove_usage        "Usage: claude-acc remove <name>"
    remove_not_found    "Account '%s' not found."
    remove_confirm      "Remove account '%s'? [y/N] "
    remove_cancelled    "Cancelled."
    remove_deleted      "Account '%s' deleted."
    default_current     "Default: %s"
    default_standard    "Default: ~/.claude/"
    default_not_found   "Account '%s' not found. Available:"
    default_set         "Default account: %s"
    reset_done          "Reset to ~/.claude/"
    link_usage          "Usage: claude-acc link <name>"
    link_desc           "Links account to the current directory."
    link_not_found      "Account '%s' not found. Available:"
    link_done           "%s → account '%s'"
    link_done_default   "%s → ~/.claude/ (default)"
    reserved_name       "'%s' is a reserved name."
    unlink_none         "No link for the current directory."
    unlink_done         "Unlinked %s. Default account will be used."
    status_active       "Active account: %s %s"
    status_linked       "(linked to %s)"
    status_default      "(default)"
    status_standard     "Active account: ~/.claude/ (standard)"
    links_empty         "No links. Use: claude-acc link <name>"
    links_header        "Links:"
    links_active        "← active"
)

_claude_msg_ru=(
    help_title          "Claude Code Account Switcher"
    help_commands       "Команды:"
    help_list           "Список аккаунтов"
    help_add            "Добавить аккаунт"
    help_login          "Перелогиниться в аккаунт"
    help_remove         "Удалить аккаунт"
    help_default        "Показать/задать дефолтный аккаунт"
    help_reset          "Сбросить дефолт на ~/.claude/"
    help_link           "Привязать аккаунт к текущей директории"
    help_unlink         "Убрать привязку с текущей директории"
    help_links          "Показать все привязки директорий"
    help_status         "Текущий аккаунт и контекст"
    help_lock           "Зафиксировать текущую личность как ожидаемую"
    help_doctor         "Проверить все аккаунты на дрейф личности"
    help_help           "Справка"
    list_empty          "Нет аккаунтов. Добавьте: claude-acc add <name>"
    list_header         "Аккаунты Claude Code:"
    list_default        "(по умолчанию)"
    add_usage           "Использование: claude-acc add <name>"
    add_example         "Пример:        claude-acc add personal"
    add_exists          "Аккаунт '%s' уже существует."
    add_created         "Аккаунт '%s' создан. Запускаю логин..."
    add_done            "Готово. Используйте:"
    add_hint_default    "  claude-acc default %s   — сделать дефолтным"
    add_hint_link       "  claude-acc link %s      — привязать к текущей директории"
    login_usage         "Использование: claude-acc login <name>"
    login_not_found     "Аккаунт '%s' не найден."
    login_start         "Вхожу в '%s'..."
    login_done          "Готово."
    remove_usage        "Использование: claude-acc remove <name>"
    remove_not_found    "Аккаунт '%s' не найден."
    remove_confirm      "Удалить аккаунт '%s'? [y/N] "
    remove_cancelled    "Отменено."
    remove_deleted      "Аккаунт '%s' удалён."
    default_current     "По умолчанию: %s"
    default_standard    "По умолчанию: ~/.claude/"
    default_not_found   "Аккаунт '%s' не найден. Доступные:"
    default_set         "Аккаунт по умолчанию: %s"
    reset_done          "Сброшено на ~/.claude/"
    link_usage          "Использование: claude-acc link <name>"
    link_desc           "Привязывает аккаунт к текущей директории."
    link_not_found      "Аккаунт '%s' не найден. Доступные:"
    link_done           "%s → аккаунт '%s'"
    link_done_default   "%s → ~/.claude/ (default)"
    reserved_name       "'%s' — зарезервированное имя."
    unlink_none         "Нет привязки для текущей директории."
    unlink_done         "Привязка убрана для %s. Будет использован дефолтный аккаунт."
    status_active       "Активный аккаунт: %s %s"
    status_linked       "(привязан к %s)"
    status_default      "(по умолчанию)"
    status_standard     "Активный аккаунт: ~/.claude/ (стандартный)"
    links_empty         "Нет привязок. Используйте: claude-acc link <name>"
    links_header        "Привязки:"
    links_active        "← активна"
)

_msg() {
    local key="$1"
    shift
    local lang=$(_claude_acc_lang)
    local template

    if [[ "$lang" == "ru" ]]; then
        template="${_claude_msg_ru[$key]}"
    else
        template="${_claude_msg_en[$key]}"
    fi

    if [[ $# -gt 0 ]]; then
        printf "$template\n" "$@"
    else
        echo "$template"
    fi
}

# =============================================================
# Ядро
# =============================================================

# --- Валидация имени аккаунта ---
_claude_validate_name() {
    local name="$1"
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: account name must only contain letters, numbers, hyphens, and underscores."
        return 1
    fi
}

# --- Инициализация ---
_claude_switch_init() {
    mkdir -p "$CLAUDE_SWITCH_ACCOUNTS_DIR"
    [[ -f "$CLAUDE_SWITCH_CONFIG" ]] || echo "default=" > "$CLAUDE_SWITCH_CONFIG"
    [[ -f "$CLAUDE_SWITCH_LINKS" ]]  || touch "$CLAUDE_SWITCH_LINKS"
    # Миграция: переименовать repos → links
    if [[ -f "$CLAUDE_SWITCH_DIR/repos" && ! -s "$CLAUDE_SWITCH_LINKS" ]]; then
        mv "$CLAUDE_SWITCH_DIR/repos" "$CLAUDE_SWITCH_LINKS"
    fi
}
_claude_switch_init

# --- Account identity helpers ---

# Keychain service name is keyed by sha256(CLAUDE_CONFIG_DIR) — must match Claude Code's dV() function
_claude_acc_token() {
    local acc_dir="$1"
    local hash token
    hash=$(printf '%s' "$acc_dir" | shasum -a 256 | cut -c1-8)
    token=$(security find-generic-password -s "Claude Code-credentials-${hash}" -a "$(id -un)" -w 2>/dev/null)
    if [[ -n "$token" ]]; then
        printf '%s' "$token" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null
        return 0
    fi
    jq -r '.claudeAiOauth.accessToken // empty' "$acc_dir/.credentials.json" 2>/dev/null
}

_claude_acc_fetch_info() {
    local acc_dir="$1"
    local access_token
    access_token=$(_claude_acc_token "$acc_dir")
    [[ -z "$access_token" ]] && return 1
    curl -sf --max-time 5 \
        -H "Authorization: Bearer $access_token" \
        -H "anthropic-beta: oauth-2025-04-20" \
        https://api.anthropic.com/api/oauth/profile 2>/dev/null \
        | jq -c 'select(.account.email) | {email:.account.email,name:.account.full_name,org:.organization.name}' \
        > "$acc_dir/.account-info.json.tmp" 2>/dev/null
    if [[ -s "$acc_dir/.account-info.json.tmp" ]]; then
        mv "$acc_dir/.account-info.json.tmp" "$acc_dir/.account-info.json"
    else
        rm -f "$acc_dir/.account-info.json.tmp"
        return 1
    fi
}

_claude_acc_email() {
    jq -r '.email // empty' "$CLAUDE_SWITCH_ACCOUNTS_DIR/$1/.account-info.json" 2>/dev/null
}

# --- Identity lock ---
# Pins the expected Anthropic account UUID to each account dir so that a silent
# re-auth (via /login or OAuth refresh) cannot swap the stored token for one
# belonging to a different identity without being noticed.

_claude_acc_uuid_from_token() {
    local acc_dir="$1"
    local access_token
    access_token=$(_claude_acc_token "$acc_dir")
    [[ -z "$access_token" ]] && return 1
    curl -sf --max-time 5 \
        -H "Authorization: Bearer $access_token" \
        -H "anthropic-beta: oauth-2025-04-20" \
        https://api.anthropic.com/api/oauth/profile 2>/dev/null \
        | jq -r '.account.uuid // empty' 2>/dev/null
}

_claude_acc_write_lock() {
    local acc_dir="$1" uuid="$2"
    [[ -z "$uuid" ]] && return 1
    printf '{"uuid":"%s"}\n' "$uuid" > "$acc_dir/.identity-lock.json"
}

_claude_acc_read_lock() {
    jq -r '.uuid // empty' "$1/.identity-lock.json" 2>/dev/null
}

# 0=match, 1=mismatch, 2=no lock, 3=cannot verify (no token / offline)
_claude_acc_verify_lock() {
    local acc_dir="$1" locked current
    locked=$(_claude_acc_read_lock "$acc_dir")
    [[ -z "$locked" ]] && return 2
    current=$(_claude_acc_uuid_from_token "$acc_dir")
    [[ -z "$current" ]] && return 3
    [[ "$locked" == "$current" ]]
}


# --- Безопасные операции с файлом links ---

# Проверить, есть ли в links точная запись для директории
_claude_links_has_dir() {
    local dir="$1"
    [[ ! -f "$CLAUDE_SWITCH_LINKS" ]] && return 1
    while IFS= read -r line; do
        [[ "$line" == "${dir}="* ]] && return 0
    done < "$CLAUDE_SWITCH_LINKS"
    return 1
}

# Удалить из links все записи для директории (безопасная замена sed)
_claude_links_remove_dir() {
    local dir="$1"
    local tmpfile
    tmpfile=$(mktemp)
    while IFS= read -r line; do
        [[ "$line" == "${dir}="* ]] || printf '%s\n' "$line"
    done < "$CLAUDE_SWITCH_LINKS" > "$tmpfile"
    mv "$tmpfile" "$CLAUDE_SWITCH_LINKS"
}

# --- Прочитать дефолтный аккаунт ---
_claude_default_account() {
    grep '^default=' "$CLAUDE_SWITCH_CONFIG" 2>/dev/null | cut -d= -f2
}

# --- Найти аккаунт для директории (точное совпадение) ---
_claude_dir_account() {
    local dir="$1"
    [[ -z "$dir" ]] && return 1
    [[ ! -f "$CLAUDE_SWITCH_LINKS" ]] && return 1
    while IFS= read -r line; do
        if [[ "$line" == "${dir}="* ]]; then
            echo "${line#*=}"
            return 0
        fi
    done < "$CLAUDE_SWITCH_LINKS"
    return 1
}

# --- Найти аккаунт, поднимаясь по дереву директорий ---
_claude_find_account() {
    local dir="${1:-$PWD}"
    local account

    while [[ "$dir" != "/" && -n "$dir" ]]; do
        account=$(_claude_dir_account "$dir")
        if [[ -n "$account" ]]; then
            echo "$account"
            return 0
        fi
        dir="${dir:h}"
    done

    return 1
}

# --- Найти директорию привязки (для status) ---
_claude_find_linked_dir() {
    local dir="${1:-$PWD}"

    while [[ "$dir" != "/" && -n "$dir" ]]; do
        if _claude_links_has_dir "$dir"; then
            echo "$dir"
            return 0
        fi
        dir="${dir:h}"
    done

    return 1
}

# --- Установить CLAUDE_CONFIG_DIR для текущего контекста ---
_claude_activate() {
    local account
    account=$(_claude_find_account)

    if [[ -z "$account" ]]; then
        account=$(_claude_default_account)
    fi

    if [[ "$account" == "default" ]]; then
        unset CLAUDE_CONFIG_DIR
    elif [[ -n "$account" && -d "$CLAUDE_SWITCH_ACCOUNTS_DIR/$account" ]]; then
        export CLAUDE_CONFIG_DIR="$CLAUDE_SWITCH_ACCOUNTS_DIR/$account"
    else
        unset CLAUDE_CONFIG_DIR
    fi
}

# --- Хук на cd: автоматически переключает аккаунт ---
_claude_chpwd_hook() {
    _claude_activate
}

# Регистрируем хук (zsh вызывает chpwd при каждой смене директории)
autoload -Uz add-zsh-hook
add-zsh-hook chpwd _claude_chpwd_hook

# Активировать сразу для текущей директории
_claude_activate

# =============================================================
# Подкоманды
# =============================================================

_claude_acc_help() {
    _msg help_title
    echo ""
    _msg help_commands
    echo "  claude-acc list              $(_msg help_list)"
    echo "  claude-acc add <name>        $(_msg help_add)"
    echo "  claude-acc login <name>      $(_msg help_login)"
    echo "  claude-acc remove <name>     $(_msg help_remove)"
    echo "  claude-acc default [name]    $(_msg help_default)"
    echo "  claude-acc reset             $(_msg help_reset)"
    echo "  claude-acc link <name>       $(_msg help_link)"
    echo "  claude-acc unlink            $(_msg help_unlink)"
    echo "  claude-acc links             $(_msg help_links)"
    echo "  claude-acc status            $(_msg help_status)"
    echo "  claude-acc lock <name>       $(_msg help_lock)"
    echo "  claude-acc doctor            $(_msg help_doctor)"
}

_claude_acc_list() {
    local default_acc
    default_acc=$(_claude_default_account)

    local accounts=("$CLAUDE_SWITCH_ACCOUNTS_DIR"/*(N:t))
    if [[ ${#accounts} -eq 0 ]]; then
        _msg list_empty
        return
    fi

    _msg list_header
    for acc in "${accounts[@]}"; do
        local email=$(_claude_acc_email "$acc")
        local email_str=""
        [[ -n "$email" ]] && email_str="  ${email}"
        if [[ "$acc" == "$default_acc" ]]; then
            echo "  ★ $acc  $(_msg list_default)${email_str}"
        else
            echo "    $acc${email_str}"
        fi
    done
}

_claude_acc_add() {
    local name="$1"
    if [[ -z "$name" ]]; then
        _msg add_usage
        _msg add_example
        return 1
    fi
    _claude_validate_name "$name" || return 1

    if [[ "$name" == "default" ]]; then
        _msg reserved_name "$name"
        return 1
    fi

    local acc_dir="$CLAUDE_SWITCH_ACCOUNTS_DIR/$name"
    if [[ -d "$acc_dir" ]]; then
        _msg add_exists "$name"
        return 1
    fi

    mkdir -p "$acc_dir"
    _msg add_created "$name"
    CLAUDE_CONFIG_DIR="$acc_dir" command claude auth login
    _claude_acc_fetch_info "$acc_dir"
    local uuid
    uuid=$(_claude_acc_uuid_from_token "$acc_dir")
    if [[ -n "$uuid" ]]; then
        _claude_acc_write_lock "$acc_dir" "$uuid"
    else
        echo "⚠  Could not fetch identity UUID. Run: claude-acc lock $name"
    fi
    echo ""
    _msg add_done
    _msg add_hint_default "$name"
    _msg add_hint_link "$name"
}

_claude_acc_login() {
    local name="$1"
    if [[ -z "$name" ]]; then
        _msg login_usage
        return 1
    fi
    _claude_validate_name "$name" || return 1

    local acc_dir="$CLAUDE_SWITCH_ACCOUNTS_DIR/$name"
    if [[ ! -d "$acc_dir" ]]; then
        _msg login_not_found "$name"
        return 1
    fi

    local kc_service hash locked prev_token
    hash=$(printf '%s' "$acc_dir" | shasum -a 256 | cut -c1-8)
    kc_service="Claude Code-credentials-${hash}"
    locked=$(_claude_acc_read_lock "$acc_dir")
    prev_token=$(security find-generic-password -s "$kc_service" -a "$(id -un)" -w 2>/dev/null)

    _msg login_start "$name"
    CLAUDE_CONFIG_DIR="$acc_dir" command claude auth login

    if [[ -n "$locked" ]]; then
        local new_uuid
        new_uuid=$(_claude_acc_uuid_from_token "$acc_dir")
        if [[ -z "$new_uuid" ]]; then
            echo "⚠  Could not verify identity after login (offline?). Skipping lock check."
        elif [[ "$new_uuid" != "$locked" ]]; then
            echo "❌ Identity mismatch for '$name'."
            echo "   Expected UUID: $locked"
            echo "   Got UUID:      $new_uuid"
            if [[ -n "$prev_token" ]]; then
                echo "   Rolling back to previous credentials."
                security add-generic-password -U \
                    -s "$kc_service" \
                    -a "$(id -un)" \
                    -w "$prev_token" >/dev/null 2>&1
            else
                echo "   Removing mis-logged credentials."
                security delete-generic-password \
                    -s "$kc_service" \
                    -a "$(id -un)" >/dev/null 2>&1
            fi
            return 1
        fi
    fi

    _claude_acc_fetch_info "$acc_dir"
    if [[ -z "$locked" ]]; then
        local uuid
        uuid=$(_claude_acc_uuid_from_token "$acc_dir")
        [[ -n "$uuid" ]] && _claude_acc_write_lock "$acc_dir" "$uuid"
    fi
    _msg login_done
}

_claude_acc_remove() {
    local force=false
    if [[ "$1" == "-f" ]]; then
        force=true
        shift
    fi

    local name="$1"
    if [[ -z "$name" ]]; then
        _msg remove_usage
        return 1
    fi
    _claude_validate_name "$name" || return 1

    if [[ "$name" == "default" ]]; then
        _msg reserved_name "$name"
        return 1
    fi

    local acc_dir="$CLAUDE_SWITCH_ACCOUNTS_DIR/$name"
    if [[ ! -d "$acc_dir" ]]; then
        _msg remove_not_found "$name"
        return 1
    fi

    if [[ "$force" != true ]]; then
        printf "$(_msg remove_confirm "$name")"
        local reply
        read -r reply
        if [[ "$reply" != [yYдД]* ]]; then
            _msg remove_cancelled
            return 1
        fi
    fi

    # Убрать из дефолтного
    local default_acc
    default_acc=$(_claude_default_account)
    if [[ "$default_acc" == "$name" ]]; then
        sed -i '' "s/^default=.*/default=/" "$CLAUDE_SWITCH_CONFIG"
    fi

    # Убрать привязки
    sed -i '' "/=$name$/d" "$CLAUDE_SWITCH_LINKS"

    rm -rf "$acc_dir"
    _msg remove_deleted "$name"
    _claude_activate
}

_claude_acc_default() {
    local name="$1"
    if [[ -z "$name" ]]; then
        local current
        current=$(_claude_default_account)
        if [[ -n "$current" ]]; then
            _msg default_current "$current"
        else
            _msg default_standard
        fi
        return
    fi

    if [[ "$name" != "default" ]]; then
        _claude_validate_name "$name" || return 1
    fi

    if [[ "$name" == "default" ]]; then
        sed -i '' "s/^default=.*/default=/" "$CLAUDE_SWITCH_CONFIG"
        _msg reset_done
        _claude_activate
        return
    fi

    if [[ ! -d "$CLAUDE_SWITCH_ACCOUNTS_DIR/$name" ]]; then
        _msg default_not_found "$name"
        _claude_acc_list
        return 1
    fi

    sed -i '' "s/^default=.*/default=$name/" "$CLAUDE_SWITCH_CONFIG"
    _msg default_set "$name"
    _claude_activate
}

_claude_acc_link() {
    local name="$1"
    if [[ -z "$name" ]]; then
        _msg link_usage
        _msg link_desc
        return 1
    fi

    if [[ "$name" != "default" ]]; then
        _claude_validate_name "$name" || return 1
    fi

    if [[ "$name" != "default" && ! -d "$CLAUDE_SWITCH_ACCOUNTS_DIR/$name" ]]; then
        _msg link_not_found "$name"
        _claude_acc_list
        return 1
    fi

    local dir="$PWD"

    # Убрать старую привязку для этой директории, если есть
    _claude_links_remove_dir "$dir"

    # Добавить новую
    echo "${dir}=${name}" >> "$CLAUDE_SWITCH_LINKS"
    if [[ "$name" == "default" ]]; then
        _msg link_done_default "$(basename "$dir")"
    else
        _msg link_done "$(basename "$dir")" "$name"
    fi
    _claude_activate
}

_claude_acc_unlink() {
    local dir="$PWD"

    if ! _claude_links_has_dir "$dir"; then
        _msg unlink_none
        return 1
    fi

    _claude_links_remove_dir "$dir"
    _msg unlink_done "$(basename "$dir")"
    _claude_activate
}

_claude_acc_links() {
    if [[ ! -s "$CLAUDE_SWITCH_LINKS" ]]; then
        _msg links_empty
        return
    fi

    _msg links_header

    local active_dir
    active_dir=$(_claude_find_linked_dir)

    sort "$CLAUDE_SWITCH_LINKS" | while IFS='=' read -r dir account; do
        [[ -z "$dir" || -z "$account" ]] && continue
        local display_dir="${dir/#$HOME/~}"
        if [[ "$dir" == "$active_dir" ]]; then
            echo "  $display_dir → $account  $(_msg links_active)"
        else
            echo "  $display_dir → $account"
        fi
    done
}

_claude_acc_status() {
    local account source_info linked_dir

    linked_dir=$(_claude_find_linked_dir)
    if [[ -n "$linked_dir" ]]; then
        account=$(_claude_dir_account "$linked_dir")
        source_info=$(_msg status_linked "$(basename "$linked_dir")")
    fi

    if [[ -z "$account" ]]; then
        account=$(_claude_default_account)
        if [[ -n "$account" ]]; then
            source_info=$(_msg status_default)
        fi
    fi

    if [[ -n "$account" ]]; then
        local email=$(_claude_acc_email "$account")
        local label="$account"
        [[ -n "$email" ]] && label="$account <${email}>"
        _msg status_active "$label" "$source_info"
    else
        _msg status_standard
    fi
}

_claude_acc_reset() {
    sed -i '' "s/^default=.*/default=/" "$CLAUDE_SWITCH_CONFIG"
    _msg reset_done
    _claude_activate
}

_claude_acc_lock() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Usage: claude-acc lock <name>"
        echo "Pins the current token identity as the expected identity for this account."
        return 1
    fi
    _claude_validate_name "$name" || return 1

    local acc_dir="$CLAUDE_SWITCH_ACCOUNTS_DIR/$name"
    if [[ ! -d "$acc_dir" ]]; then
        _msg login_not_found "$name"
        return 1
    fi

    local uuid
    uuid=$(_claude_acc_uuid_from_token "$acc_dir")
    if [[ -z "$uuid" ]]; then
        echo "Could not fetch identity. Is '$name' logged in and online?"
        return 1
    fi
    _claude_acc_write_lock "$acc_dir" "$uuid"
    echo "Locked '$name' → UUID $uuid"
}

_claude_acc_doctor() {
    local accounts=("$CLAUDE_SWITCH_ACCOUNTS_DIR"/*(N:t))
    if [[ ${#accounts} -eq 0 ]]; then
        echo "No accounts."
        return
    fi
    local acc acc_dir rc locked current email any_bad=0
    for acc in "${accounts[@]}"; do
        acc_dir="$CLAUDE_SWITCH_ACCOUNTS_DIR/$acc"
        _claude_acc_verify_lock "$acc_dir"
        rc=$?
        locked=$(_claude_acc_read_lock "$acc_dir")
        current=$(_claude_acc_uuid_from_token "$acc_dir")
        email=$(_claude_acc_email "$acc")
        case $rc in
            0) echo "✓ $acc  [${email:-unknown}]  uuid=$current" ;;
            1) echo "✗ $acc  DRIFT  expected=$locked got=${current:-<unknown>}"
               echo "    fix: claude-acc login $acc"
               any_bad=1 ;;
            2) echo "? $acc  no identity lock"
               echo "    fix: claude-acc lock $acc" ;;
            3) echo "? $acc  cannot verify (offline or no token)" ;;
        esac
    done
    return $any_bad
}

# =============================================================
# Единая точка входа
# =============================================================

claude-acc() {
    local cmd="$1"
    shift 2>/dev/null

    case "$cmd" in
        list)    _claude_acc_list "$@" ;;
        add)     _claude_acc_add "$@" ;;
        login)   _claude_acc_login "$@" ;;
        remove)  _claude_acc_remove "$@" ;;
        default) _claude_acc_default "$@" ;;
        reset)   _claude_acc_reset ;;
        link)    _claude_acc_link "$@" ;;
        unlink)  _claude_acc_unlink "$@" ;;
        links)   _claude_acc_links ;;
        status)  _claude_acc_status "$@" ;;
        lock)    _claude_acc_lock "$@" ;;
        doctor)  _claude_acc_doctor ;;
        help)    _claude_acc_help ;;
        *)       _claude_acc_help ;;
    esac
}

# =============================================================
# Автодополнение (zsh)
# =============================================================

_claude_acc_completion() {
    local -a subcmds accounts
    subcmds=(
        "list:$(_msg help_list)"
        "add:$(_msg help_add)"
        "login:$(_msg help_login)"
        "remove:$(_msg help_remove)"
        "default:$(_msg help_default)"
        "reset:$(_msg help_reset)"
        "link:$(_msg help_link)"
        "unlink:$(_msg help_unlink)"
        "links:$(_msg help_links)"
        "status:$(_msg help_status)"
        "lock:$(_msg help_lock)"
        "doctor:$(_msg help_doctor)"
        "help:$(_msg help_help)"
    )

    if (( CURRENT == 2 )); then
        _describe 'command' subcmds
    elif (( CURRENT == 3 )); then
        case "${words[2]}" in
            login|remove|lock)
                accounts=("$CLAUDE_SWITCH_ACCOUNTS_DIR"/*(N:t))
                _describe 'account' accounts
                ;;
            default|link)
                accounts=("default" "$CLAUDE_SWITCH_ACCOUNTS_DIR"/*(N:t))
                _describe 'account' accounts
                ;;
        esac
    fi
}

compdef _claude_acc_completion claude-acc

# =============================================================
# Launch gate: verify token identity matches .identity-lock.json
# before running `claude` in a managed CLAUDE_CONFIG_DIR
# =============================================================

claude() {
    # Pass through meta commands that don't need (or shouldn't be blocked by)
    # an identity check: auth flows (user's only way to recover from drift),
    # help, version.
    case "$1" in
        auth|--help|-h|--version|-v)
            command claude "$@"
            return
            ;;
    esac

    # Only gate when operating inside a switcher-managed account dir.
    if [[ -z "$CLAUDE_CONFIG_DIR" ]] || [[ "$CLAUDE_CONFIG_DIR" != "$CLAUDE_SWITCH_ACCOUNTS_DIR"/* ]]; then
        command claude "$@"
        return
    fi

    local acc_dir="$CLAUDE_CONFIG_DIR"
    local acc_name="${acc_dir##*/}"
    _claude_acc_verify_lock "$acc_dir"
    case $? in
        0) ;;
        1)
            local locked current
            locked=$(_claude_acc_read_lock "$acc_dir")
            current=$(_claude_acc_uuid_from_token "$acc_dir")
            echo "❌ Claude Code identity drift detected for account '$acc_name'" >&2
            echo "   Expected UUID: $locked" >&2
            echo "   Current UUID:  ${current:-<unknown>}" >&2
            echo "   Fix: claude-acc login $acc_name" >&2
            return 1
            ;;
        2)
            echo "⚠  Account '$acc_name' has no identity lock. Run: claude-acc lock $acc_name" >&2
            ;;
        3) ;;  # offline or no token: fail open
    esac
    command claude "$@"
}
